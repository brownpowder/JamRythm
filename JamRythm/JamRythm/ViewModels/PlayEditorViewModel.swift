//
//  PlayEditorViewModel.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import Combine
import Foundation
import os.log

// MARK: - メインプレイエディタViewModel

/*
メインエディタ画面（Play Editor）の状態管理およびユーザー操作のハンドリングを担うViewModel。
Protocol DIによりAudioServiceとMusicTheoryServiceを注入し、View層とService層の疎結合を保つ。
*/
@MainActor
final class PlayEditorViewModel: ObservableObject {

    private let logger = Logger(subsystem: "com.budou-design.JamRythm", category: "PlayEditorViewModel")

    // MARK: - 依存サービス
    let audioService: AudioServiceProtocol
    let theoryService: MusicTheoryServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - 公開State (Viewが監視・バインドするプロパティ)
    @Published var project: Project
    @Published var isPlaying: Bool = false
    @Published var selectedSectionIndex: Int = 0
    @Published var playbackMode: PlaybackMode = .entireSong
    @Published var currentMeasureIndex: Int = 0
    @Published var currentBeat: Int = 1
    @Published var currentCandidates: [ChordCandidate] = []
    @Published var currentSubstituteCandidates: [SubstituteCandidate] = []
    @Published var selectedTemplate: ProgressionTemplate = .royalRoad
    @Published var bassProgram: UInt8 = BassInstrument.dub.rawValue
    @Published var drumProgram: UInt8 = 0
    @Published var volume: Float = 0.8
    @Published var drumVolume: Float = 0.8
    @Published var bassVolume: Float = 0.8
    @Published var pianoVolume: Float = 0.8
    @Published var isDrumMuted: Bool = false
    @Published var isBassMuted: Bool = false
    @Published var isPianoMuted: Bool = false
    @Published var isDrumSolo: Bool = false
    @Published var isBassSolo: Bool = false
    @Published var isPianoSolo: Bool = false

    @Published var leadVolume: Float = 0.8
    @Published var isLeadMuted: Bool = false
    @Published var isLeadSolo: Bool = false
    @Published var selectedLeadInstrument: LeadInstrument = .guitar
    @Published var selectedPianoInstrument: PianoInstrument = .piano
    @Published var selectedDrumPlayer: DrumPlayer = .rhythmMachine
    @Published var selectedBassPlayer: BassPlayer = .rhythmMachine
    @Published var selectedPianoPlayer: PianoPlayer = .rhythmMachine

    @Published var selectedDrumInstrument: DrumInstrument = .acoustic
    @Published var selectedBassInstrument: BassInstrument = .dub
    @Published var selectedGenre: MusicGenre = .pop
    @Published var isShowingMixer: Bool = false
    @Published var isShowingAddSectionSheet: Bool = false
    @Published var sectionIndexForProgressionChange: Int? = nil
    @Published var isShowingSongStructureSheet: Bool = false
    @Published var isShowingChordCustomizer: Bool = false
    @Published var errorMessage: String?
    @Published var activeChemistry: PlayerChemistry? = nil

    // MARK: - Chemistry

    func updateChemistry() {
        activeChemistry = PlayerChemistry.detectChemistry(drum: selectedDrumPlayer, bass: selectedBassPlayer, piano: selectedPianoPlayer)
    }

    // MARK: - イニシャライザ

    /*
    ViewModelの依存関係を受け取り、初期プロジェクトの生成と再生位置の購読を開始する。
    
    Arguments:
    audioService
      音声再生を制御するサービス。DIコンテナまたはViewの生成元から渡される。
    theoryService
      音楽理論計算を行うサービス。DIコンテナまたはViewの生成元から渡される。
    
    Usage:
    PlayEditorViewの初期化時またはAppルートからインスタンス化される。
    */
    
    init(
        project: Project? = nil,
        audioService: AudioServiceProtocol? = nil,
        theoryService: MusicTheoryServiceProtocol? = nil
    ) {
        print("DEBUG: PlayEditorViewModel init called. Project is \(project == nil ? "nil" : "exists")")
        let audio = audioService ?? AudioService()
        let theory = theoryService ?? MusicTheoryService()
        self.audioService = audio
        self.theoryService = theory

        if let existingProject = project {
            self.project = existingProject
        } else {
            let nextTitle = ProjectRepository.shared.generateNextProjectName()
            var initialProject = Self.createDefaultProject(template: .royalRoad, key: .C, theoryService: theory)
            initialProject.title = nextTitle
            self.project = initialProject
        }
        self.selectedGenre = self.project.genre
        self.volume = audio.volume
        self.drumVolume = audio.drumVolume
        self.bassVolume = audio.bassVolume
        self.pianoVolume = audio.pianoVolume
        self.isDrumMuted = audio.drumIsMuted
        self.isBassMuted = audio.bassIsMuted
        self.isPianoMuted = audio.pianoIsMuted
        self.isDrumSolo = audio.drumIsSolo
        self.isBassSolo = audio.bassIsSolo
        self.isPianoSolo = audio.pianoIsSolo

        self.leadVolume = audio.leadVolume
        self.isLeadMuted = audio.leadIsMuted
        self.isLeadSolo = audio.leadIsSolo

        self.selectedDrumInstrument = DrumInstrument(rawValue: audio.drumProgram) ?? .acoustic
        self.selectedBassInstrument = BassInstrument(rawValue: audio.bassProgram) ?? .dub
        self.selectedPianoInstrument = PianoInstrument(rawValue: audio.pianoProgram) ?? .piano
        self.selectedDrumPlayer = audio.selectedDrumPlayer
        self.selectedBassPlayer = audio.selectedBassPlayer
        self.selectedPianoPlayer = audio.selectedPianoPlayer
        updateChemistry()

        setupAudioEngine()
        bindAudioPosition()
        updateCandidatesForCurrentMeasure()
        
        // オートセーブ（projectが変更されるたびにDebounceして保存）
        $project
            .dropFirst()
            .debounce(for: .seconds(2), scheduler: RunLoop.main)
            .sink { [weak self] updatedProject in
                print("DEBUG: Auto-saving project: \(updatedProject.title)")
                ProjectRepository.shared.save(updatedProject)
            }
            .store(in: &cancellables)
    }
    


    // MARK: - 計算プロパティ (View支援)

    /*
    現在再生中の小節のコードを返す。
    
    Arguments:
    なし
    
    Usage:
    メイン画面の特大コード表示（Current Chord）で使用される。
    */
    
    var currentChord: Chord {
        guard let measures = activeSection?.measures,
              currentMeasureIndex < measures.count else {
            return Chord(rootNote: "C", type: "", bassNote: nil)
        }
        return measures[currentMeasureIndex].activeChord
    }

    /*
    前の小節のコードを返す（曲の先頭ではnil）。
    
    Arguments:
    なし
    
    Usage:
    画面に表示する「PREV」コードの表示に使用される。曲頭ではボタン非表示となる。
    */

    var previousChord: Chord? {
        guard !project.sections.isEmpty else { return nil }
        let secIdx = min(selectedSectionIndex, project.sections.count - 1)
        let measures = project.sections[secIdx].measures
        guard !measures.isEmpty else { return nil }

        // 曲全体の先頭（第1セクションの第1小節）ならPrevなし
        if secIdx == 0 && currentMeasureIndex == 0 {
            return nil
        }

        if currentMeasureIndex > 0 && currentMeasureIndex - 1 < measures.count {
            return measures[currentMeasureIndex - 1].activeChord
        } else if secIdx > 0 {
            let prevSecIdx = secIdx - 1
            let prevMeasures = project.sections[prevSecIdx].measures
            return prevMeasures.last?.activeChord
        }
        return nil
    }

    /*
    次の小節のコードを返す（曲の末尾ではnil）。
    
    Arguments:
    なし
    
    Usage:
    演奏者が次の小節を準備できるように画面に表示する「NEXT」コードで使用される。曲末尾ではボタン非表示となる。
    */
    
    var nextChord: Chord? {
        guard !project.sections.isEmpty else { return nil }
        let secIdx = min(selectedSectionIndex, project.sections.count - 1)
        let measures = project.sections[secIdx].measures
        guard !measures.isEmpty else { return nil }

        // 曲全体の末尾（最終セクションの最終小節）ならNextなし
        let isLastSection = secIdx == project.sections.count - 1
        let isLastMeasure = currentMeasureIndex >= measures.count - 1
        if isLastSection && isLastMeasure {
            return nil
        }

        if currentMeasureIndex + 1 < measures.count {
            return measures[currentMeasureIndex + 1].activeChord
        } else if secIdx + 1 < project.sections.count {
            let nextSecIdx = secIdx + 1
            let nextMeasures = project.sections[nextSecIdx].measures
            return nextMeasures.first?.activeChord
        }
        return nil
    }

    /*
    現在のコードに対するギター運指（ボイシング）を返す。
    
    Arguments:
    なし
    
    Usage:
    GuitarTabViewへの運指データ提供に使用される。
    */
    
    var currentVoicing: GuitarVoicing {
        return theoryService.guitarVoicing(for: currentChord)
    }

    /*
    現在のコードに対する五線譜上の構成音配置を返す。
    
    Arguments:
    なし
    
    Usage:
    StaffScoreViewへの音符データ提供に使用される。
    */
    
    var currentStaffNotes: [StaffNote] {
        return theoryService.staffNotes(for: currentChord)
    }

    /*
    現在編集・再生の対象となっているセクションを返す。
    
    Arguments:
    なし
    
    Usage:
    小節リストの取得や更新時に内部で使用される。
    */
    
    var activeSection: Section? {
        guard !project.sections.isEmpty else { return nil }
        let index = min(selectedSectionIndex, project.sections.count - 1)
        return project.sections[index]
    }

    // MARK: - ユーザーインテント (Viewからの操作イベント)

    /*
    再生と一時停止を切り替える。
    
    Arguments:
    なし
    
    Usage:
    画面上の「Play / Pause」ボタン押下時に呼び出される。
    */
    
    func togglePlay() {
        if isPlaying {
            audioService.pause()
        } else {
            audioService.updateProject(project)
            audioService.setPlaybackPosition(sectionIndex: selectedSectionIndex, measureIndex: currentMeasureIndex)
            audioService.play()
        }
        isPlaying.toggle()
    }

    /*
    指定した小節にユーザーが選んだコードを適用する。
    
    Arguments:
    chord
      選択されたChordオブジェクト。CandidateButtonsViewのボタン押下で渡される。
    index
      コードを適用する小節インデックス。
    
    Usage:
    ユーザーが候補ボタンをタップした際に呼び出され、進行データへ反映する。
    */
    
    func selectChord(_ chord: Chord, forMeasureIndex index: Int) {
        let sectionIdx = min(selectedSectionIndex, project.sections.count - 1)
        guard sectionIdx >= 0,
              index < project.sections[sectionIdx].measures.count else {
            return
        }
        project.sections[sectionIdx].measures[index].selectedChord = chord
        audioService.updateProject(project)
        playChordPreview(chord)
    }

    /*
    ユーザーがカスタム作成したコードを現在選択中の小節に適用する。

    Arguments:
    chord
      カスタム編集されたChordオブジェクト。ChordCustomizerSheetViewから渡される。

    Usage:
    コードカスタム編集シートで「適用」ボタンを押した際に呼び出される。
    */

    func setCustomChord(_ chord: Chord) {
        selectChord(chord, forMeasureIndex: currentMeasureIndex)
    }

    /*
    指定されたセクション・小節を選択し、コードカスタム編集シートを開く。

    Arguments:
    sectionIndex
      対象セクションのインデックス番号。進行セクションUIから渡される。
    measureIndex
      対象小節のインデックス番号。進行セクションUIから渡される。

    Usage:
    進行セクションの小節カードタップ（再タップ・鉛筆タップ・長押しメニュー）時に呼び出される。
    */

    func openChordCustomizer(forSection sectionIndex: Int, measureIndex: Int) {
        selectMeasure(inSection: sectionIndex, measureIndex: measureIndex)
        isShowingChordCustomizer = true
    }

    /*
    現在カスタム編集対象となっているセクション・小節の表示用タイトルを返す。

    Arguments:
    なし

    Usage:
    ChordCustomizerSheetViewのヘッダーやナビゲーションタイトルに表示される。
    */

    var editingMeasureTitle: String {
        let sectionNum = selectedSectionIndex + 1
        let measureNum = currentMeasureIndex + 1
        return String(format: NSLocalizedString("Section %d - Measure %d", comment: ""), sectionNum, measureNum)
    }

    /*
    現在編集対象となっている小節の元のコード（編集前）を返す。

    Arguments:
    なし

    Usage:
    ChordCustomizerSheetViewで親和性判定の基準コードとして使用される。
    */

    var editingOriginalChord: Chord? {
        guard let measures = activeSection?.measures,
              currentMeasureIndex < measures.count else { return nil }
        return measures[currentMeasureIndex].activeChord
    }

    /*
    現在編集対象となっている小節の土台度数（baseDegree）を返す。

    Arguments:
    なし

    Usage:
    ChordCustomizerSheetViewで和声的親和性を判定する際に使用される。
    */

    var editingBaseDegree: Int {
        guard let measures = activeSection?.measures,
              currentMeasureIndex < measures.count else { return 1 }
        return measures[currentMeasureIndex].baseDegree
    }

    /*
    現在編集対象となっている小節の次の小節のコードを返す。
    末尾小節の場合はループ先である先頭小節のコードを返す。

    Arguments:
    なし

    Usage:
    ChordCustomizerSheetViewでセカンダリードミナント等の解決先判定に使用される。
    */

    var editingNextChord: Chord? {
        guard let measures = activeSection?.measures, !measures.isEmpty else { return nil }
        let nextIndex = (currentMeasureIndex + 1) % measures.count
        return measures[nextIndex].activeChord
    }

    /*
    指定されたコードの構成音をピアノ音源（piano1: 007）でプレビュー再生する。

    Arguments:
    chord
      再生するChordオブジェクト。

    Usage:
    コード選択時や小節・カードタップ時に呼び出される。
    */

    func playChordPreview(_ chord: Chord) {
        let midiNotes = theoryService.chordMidiNotes(for: chord)
        audioService.playChordNotes(midiNotes)
    }

    /*
    BPMを変更し、オーディオ再生サービスに反映する。
    
    Arguments:
    bpm
      新しいBPM値。スライダーやステッパーから渡される。
    
    Usage:
    テンポ調整UIの操作時に呼び出される。
    */
    
    func changeBPM(_ bpm: Double) {
        project.bpm = bpm
        audioService.setBPM(bpm)
    }

    /*
    マスター出力音量を変更し、AudioServiceへ反映する。
    
    Arguments:
    newVolume
      変更後の音量値（0.0〜1.0）。
      Footerの音量スライダーから渡される。
    
    Usage:
    ボリューム操作時に呼び出され、全体の出力音量を調整する。
    */
    
    func changeVolume(_ newVolume: Float) {
        let clamped = max(0.0, min(1.0, newVolume))
        self.volume = clamped
        audioService.setVolume(clamped)
    }

    /*
    調（Key）を変更し、小節のベース音およびコード候補を再計算する。
    
    Arguments:
    key
      新しく選択されたKey。Pickerから渡される。
    
    Usage:
    Key選択Pickerの操作時に呼び出される。
    */
    
    func changeKey(_ key: Key) {
        project.key = key
        recalculateAllMeasures(for: key)
        updateCandidatesForCurrentMeasure()
    }

    /*
    対象セクションを編集・再生フォーカスとして選択する。
    
    Arguments:
    index
      選択するセクションインデックス。
    
    Usage:
    SectionTimelineBarViewのタブタップ時に呼び出される。
    */
    
    func selectSection(at index: Int) {
        guard index >= 0, index < project.sections.count else { return }
        self.selectedSectionIndex = index
        self.currentMeasureIndex = 0
        audioService.setActiveSectionIndex(index)
        updateCandidatesForCurrentMeasure()
    }

    /*
    指定したセクションの特定小節を選択し、コード候補や表示を更新するとともにプレビュー音を再生する。

    Arguments:
    sectionIndex
      選択するセクションのインデックス。
    measureIndex
      選択する小節のインデックス。

    Usage:
    タイムライン上の小節カードタップ時に呼び出される。
    */

    func selectMeasure(inSection sectionIndex: Int, measureIndex: Int) {
        guard sectionIndex >= 0, sectionIndex < project.sections.count else { return }
        self.selectedSectionIndex = sectionIndex
        let measureCount = project.sections[sectionIndex].measures.count
        guard measureIndex >= 0, measureIndex < measureCount else { return }
        self.currentMeasureIndex = measureIndex
        audioService.setPlaybackPosition(sectionIndex: sectionIndex, measureIndex: measureIndex)
        updateCandidatesForCurrentMeasure()
        let activeChord = project.sections[sectionIndex].measures[measureIndex].activeChord
        playChordPreview(activeChord)
    }

    /*
    次の小節へ選択を進める（NEXTタップ時）。曲の末尾では進まない。

    Arguments:
    なし

    Usage:
    ChordDisplayViewのNEXTタップ時に呼び出される。
    */

    func moveToNextMeasure() {
        guard !project.sections.isEmpty else { return }
        let secIdx = min(selectedSectionIndex, project.sections.count - 1)
        let measures = project.sections[secIdx].measures
        guard !measures.isEmpty else { return }

        if currentMeasureIndex + 1 < measures.count {
            selectMeasure(inSection: secIdx, measureIndex: currentMeasureIndex + 1)
        } else if secIdx + 1 < project.sections.count {
            selectMeasure(inSection: secIdx + 1, measureIndex: 0)
        }
    }

    /*
    前の小節へ選択を戻す（PREVタップ時）。曲の先頭では戻らない。

    Arguments:
    なし

    Usage:
    ChordDisplayViewのPREVタップ時に呼び出される。
    */

    func moveToPreviousMeasure() {
        guard !project.sections.isEmpty else { return }
        let secIdx = min(selectedSectionIndex, project.sections.count - 1)
        let measures = project.sections[secIdx].measures
        guard !measures.isEmpty else { return }

        if currentMeasureIndex > 0 {
            selectMeasure(inSection: secIdx, measureIndex: currentMeasureIndex - 1)
        } else if secIdx > 0 {
            let prevSecIdx = secIdx - 1
            let prevMeasures = project.sections[prevSecIdx].measures
            let targetMeasure = max(0, prevMeasures.count - 1)
            selectMeasure(inSection: prevSecIdx, measureIndex: targetMeasure)
        }
    }

    /*
    再生モード（セクションループ ⇔ 全曲通し）を切り替える。
    
    Arguments:
    なし
    
    Usage:
    セクションバーのループ切り替えボタンから呼び出される。
    */
    
    func togglePlaybackMode() {
        playbackMode = (playbackMode == .sectionLoop) ? .entireSong : .sectionLoop
        audioService.setPlaybackMode(playbackMode)
    }

    /*
    新しいセクションを追加し、選択状態にする。
    
    Arguments:
    type
      追加するセクション種別（省略時は .verseA）。
    template
      適用する進行テンプレート（省略時は王道進行）。
    
    Usage:
    セクション追加メニューから呼び出される。
    */
    
    func addSection(type: SectionType = .verseA, template: ProgressionTemplate? = nil) {
        let appliedTemplate = template ?? .royalRoad
        let measures = Self.createMeasures(for: appliedTemplate, key: project.key, theoryService: theoryService)
        let newSection = Section(type: type, measures: measures)
        project.sections.append(newSection)
        try? audioService.prepare(project: project)
        selectSection(at: project.sections.count - 1)
    }

    /*
    指定したコード進行テンプレートで新しいセクションを追加する。

    Arguments:
    template
      適用する進行テンプレート。

    Usage:
    進行選択によるセクション追加ボタンから呼び出される。
    */

    func addSection(template: ProgressionTemplate) {
        addSection(type: .verseA, template: template)
    }

    /*
    指定したセクションを複製して直後に挿入する。
    
    Arguments:
    index
      複製元セクションのインデックス。
    
    Usage:
    セクションメニューの「複製」から呼び出される。
    */
    
    func duplicateSection(at index: Int) {
        guard index >= 0, index < project.sections.count else { return }
        let source = project.sections[index]
        let duplicatedMeasures = source.measures.map { measure in
            Measure(
                baseDegree: measure.baseDegree,
                bassNote: measure.bassNote,
                chordCandidates: measure.chordCandidates,
                substituteCandidates: measure.substituteCandidates,
                selectedChord: measure.selectedChord
            )
        }
        let newSection = Section(type: source.type, measures: duplicatedMeasures)
        project.sections.insert(newSection, at: index + 1)
        try? audioService.prepare(project: project)
        selectSection(at: index + 1)
    }

    /*
    指定したセクションを削除する（最低1セクションは保持）。
    
    Arguments:
    index
      削除対象セクションのインデックス。
    
    Usage:
    セクションメニューの「削除」から呼び出される。
    */
    
    func removeSection(at index: Int) {
        guard project.sections.count > 1, index >= 0, index < project.sections.count else { return }
        project.sections.remove(at: index)
        let nextIndex = min(index, project.sections.count - 1)
        try? audioService.prepare(project: project)
        selectSection(at: nextIndex)
    }

    /*
    指定したセクションの区分（Intro, Aメロ等）を変更する。
    
    Arguments:
    index
      対象セクションのインデックス。
    newType
      新しく設定するSectionType。
    
    Usage:
    セクションメニューの名前変更から呼び出される。
    */
    
    func changeSectionType(at index: Int, to newType: SectionType) {
        guard index >= 0, index < project.sections.count else { return }
        project.sections[index].type = newType
    }

    /*
    選択中（または指定）のセクションに進行テンプレートを適用する。
    
    Arguments:
    template
      適用する王道進行テンプレート。
    sectionIndex
      適用対象セクションインデックス（省略時は選択中のセクション）。
    
    Usage:
    進行テンプレート選択時に呼び出される。
    */
    
    func applyTemplate(_ template: ProgressionTemplate, toSectionIndex index: Int? = nil) {
        let targetIndex = index ?? selectedSectionIndex
        guard targetIndex >= 0, targetIndex < project.sections.count else { return }
        self.selectedTemplate = template
        let measures = Self.createMeasures(for: template, key: project.key, theoryService: theoryService)
        project.sections[targetIndex].measures = measures
        self.currentMeasureIndex = 0
        self.currentBeat = 1
        try? audioService.prepare(project: self.project)
        updateCandidatesForCurrentMeasure()
    }

    /*
    楽曲構成テンプレート（1コーラスまたは1曲分）を一括適用し、セクション一覧を再構築する。

    Arguments:
    structure
      適用する楽曲構成テンプレート（SongStructureTemplate）。
      SongStructureSheetViewから渡される。

    Usage:
    楽曲構成自動生成シートでプリセットを選択した際に呼び出される。
    */

    func applySongStructure(_ structure: SongStructureTemplate) {
        var newSections: [Section] = []

        for sec in structure.sections {
            let measures = Self.createMeasures(
                for: sec.template,
                key: project.key,
                theoryService: theoryService
            )
            let section = Section(type: sec.type, measures: measures)
            newSections.append(section)
        }

        self.project.sections = newSections
        self.selectedSectionIndex = 0
        self.currentMeasureIndex = 0
        self.currentBeat = 1

        // 構成に最適化された推奨ジャンルへ自動設定
        changeGenre(structure.recommendedGenre)

        // 構成に最適化された推奨テンポ（BPM）へ自動設定
        changeBPM(structure.recommendedBpm)

        try? audioService.prepare(project: self.project)
        audioService.setPlaybackPosition(sectionIndex: 0, measureIndex: 0)
        updateCandidatesForCurrentMeasure()

        logger.info("Applied song structure: \(structure.name) with \(newSections.count) sections at BPM \(structure.recommendedBpm)")
    }

    /*
    指定されたカテゴリ（1コーラス または 1曲丸ごと）に基づいてランダムな楽曲構成を生成し、プロジェクトに適用する。

    Arguments:
    category
      生成する構成カテゴリ（.oneChorus または .fullSong）。
      楽曲構成生成シートのランダム生成カードから渡される。

    Usage:
    楽曲構成生成シートで「おまかせランダム生成」をタップした際に呼び出される。
    */

    func generateAndApplyRandomSongStructure(category: SongStructureCategory) {
        let randomStructure = SongStructureTemplate.generateRandom(
            category: category,
            baseGenre: selectedGenre
        )
        applySongStructure(randomStructure)
    }

    /*
    伴奏ジャンルを変更し、再生エンジンおよびプロジェクトに反映する。

    Arguments:
    genre
      新しい音楽ジャンル（Pop, Rock, Dance, Lo-Fi, R&B）。
      ヘッダーのジャンル選択メニューから渡される。

    Usage:
    ユーザーがジャンルメニューから別のスタイルを選んだ際に呼び出され、ドラム・ベースパターンを即時切り替える。
    */

    func changeGenre(_ genre: MusicGenre) {
        self.selectedGenre = genre
        self.project.genre = genre
        self.audioService.setGenre(genre)

        // ジャンルに応じた推奨音色に自動連動
        selectDrumInstrument(genre.defaultDrumInstrument)
        selectBassInstrument(genre.defaultBassInstrument)
        selectPianoInstrument(genre.defaultPianoInstrument)
        
        // ジャンルに応じた推奨プレイヤーを自動選択（アンロック済みの場合のみ）
        if !genre.recommendedDrumPlayer.isLocked { selectDrumPlayer(genre.recommendedDrumPlayer) }
        if !genre.recommendedBassPlayer.isLocked { selectBassPlayer(genre.recommendedBassPlayer) }
        if !genre.recommendedPianoPlayer.isLocked { selectPianoPlayer(genre.recommendedPianoPlayer) }

        self.audioService.updateProject(self.project)
        logger.info("Genre changed to: \(genre.rawValue)")
    }

    /*
    Bass音色プログラム（0〜6）を変更する。
    
    Arguments:
    program
      Bank 000内のプログラム番号（0〜6）。
    
    Usage:
    音色選択メニューから呼び出される。
    */
    
    func changeBassProgram(_ program: UInt8) {
        self.bassProgram = program
        self.selectedBassInstrument = BassInstrument(rawValue: program) ?? .acoustic
        audioService.setBassProgram(program)
    }

    /*
    Drum音色プログラム（0〜2）を変更する。
    
    Arguments:
    program
      Bank 128内のプログラム番号（0〜2）。
    
    Usage:
    音色選択メニューから呼び出される。
    */
    
    func changeDrumProgram(_ program: UInt8) {
        self.drumProgram = program
        self.selectedDrumInstrument = DrumInstrument(rawValue: program) ?? .acoustic
        audioService.setDrumProgram(program)
    }

    /*
    ドラムトラックの音量を変更し、AudioServiceへ反映する。

    Arguments:
    newVolume
      変更後の音量値（0.0〜1.0）。ミキサー画面のスライダーから渡される。

    Usage:
    ミキサーのドラム音量操作時に呼び出される。
    */

    func changeDrumVolume(_ newVolume: Float) {
        let clamped = max(0.0, min(1.0, newVolume))
        self.drumVolume = clamped
        audioService.setDrumVolume(clamped)
    }

    /*
    ベーストラックの音量を変更し、AudioServiceへ反映する。

    Arguments:
    newVolume
      変更後の音量値（0.0〜1.0）。ミキサー画面のスライダーから渡される。

    Usage:
    ミキサーのベース音量操作時に呼び出される。
    */

    func changeBassVolume(_ newVolume: Float) {
        let clamped = max(0.0, min(1.0, newVolume))
        self.bassVolume = clamped
        audioService.setBassVolume(clamped)
    }

    /*
    ピアノトラックの音量を変更し、AudioServiceへ反映する。

    Arguments:
    newVolume
      変更後の音量値（0.0〜1.0）。ミキサー画面のスライダーから渡される。

    Usage:
    ミキサーのピアノ音量操作時に呼び出される。
    */

    func changePianoVolume(_ newVolume: Float) {
        let clamped = max(0.0, min(1.0, newVolume))
        self.pianoVolume = clamped
        audioService.setPianoVolume(clamped)
    }

    func toggleDrumMute() {
        let next = !isDrumMuted
        self.isDrumMuted = next
        audioService.setDrumMuted(next)
    }

    func toggleBassMute() {
        let next = !isBassMuted
        self.isBassMuted = next
        audioService.setBassMuted(next)
    }

    func togglePianoMute() {
        let next = !isPianoMuted
        self.isPianoMuted = next
        audioService.setPianoMuted(next)
    }

    func toggleDrumSolo() {
        let next = !isDrumSolo
        self.isDrumSolo = next
        audioService.setDrumSolo(next)
    }

    func toggleBassSolo() {
        let next = !isBassSolo
        self.isBassSolo = next
        audioService.setBassSolo(next)
    }

    func togglePianoSolo() {
        let next = !isPianoSolo
        self.isPianoSolo = next
        audioService.setPianoSolo(next)
    }

    /*
    ドラム音色プリセットを選択し、AudioServiceへ反映する。

    Arguments:
    instrument
      選択されたドラムプリセット（DrumInstrument）。Pickerから渡される。

    Usage:
    ミキサーのドラム音色Picker操作時に呼び出される。
    */

    
    func selectDrumPlayer(_ player: DrumPlayer) {
        self.selectedDrumPlayer = player
        audioService.selectedDrumPlayer = player
        updateChemistry()
        updateChemistry()
    }

    func selectBassPlayer(_ player: BassPlayer) {
        self.selectedBassPlayer = player
        audioService.selectedBassPlayer = player
        updateChemistry()
        updateChemistry()
    }

    func selectPianoPlayer(_ player: PianoPlayer) {
        self.selectedPianoPlayer = player
        audioService.selectedPianoPlayer = player
        updateChemistry()
        updateChemistry()
    }

    func selectDrumInstrument(_ instrument: DrumInstrument) {
        self.selectedDrumInstrument = instrument
        self.drumProgram = instrument.rawValue
        audioService.setDrumProgram(instrument.rawValue)
    }

    /*
    ベース音色プリセットを選択し、AudioServiceへ反映する。

    Arguments:
    instrument
      選択されたベースプリセット（BassInstrument）。Pickerから渡される。

    Usage:
    ミキサーのベース音色Picker操作時に呼び出される。
    */

    func selectBassInstrument(_ instrument: BassInstrument) {
        self.selectedBassInstrument = instrument
        self.bassProgram = instrument.rawValue
        audioService.setBassProgram(instrument.rawValue)
    }

    // MARK: - 内部処理 & バインディング

    /*
    AudioServiceの初期化とプロジェクト準備を行う。
    
    Arguments:
    なし
    
    Usage:
    init時に実行され、エラー発生時はログ出力とエラーメッセージ設定を行う。
    */
    
    private func setupAudioEngine() {
        do {
            try audioService.setupEngine()
            try audioService.prepare(project: project)
        } catch {
            logger.error("AudioEngine setup failed: \(error.localizedDescription)")
            self.errorMessage = String(format: NSLocalizedString("オーディオエンジンの初期化に失敗しました: %@", comment: ""), error.localizedDescription)
        }
    }

    /*
    AudioServiceからの再生位置通知を購読し、UIステートを同期する。
    
    Arguments:
    なし
    
    Usage:
    init時に呼び出され、Combineパイプラインを確立する。
    */
    
    private func bindAudioPosition() {
        audioService.currentPositionPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] position in
                guard let self = self else { return }
                if self.isPlaying && self.playbackMode == .entireSong && self.selectedSectionIndex != position.sectionIndex {
                    self.selectedSectionIndex = position.sectionIndex
                }
                self.currentMeasureIndex = position.measureIndex
                self.currentBeat = position.beat
                self.updateCandidatesForCurrentMeasure()
            }
            .store(in: &cancellables)
    }

    /*
    現在再生中の小節に対応するコード候補リストを更新する。
    
    Arguments:
    なし
    
    Usage:
    小節進行時およびKey切り替え時に呼び出される。
    */
    
    private func updateCandidatesForCurrentMeasure() {
        guard let measures = activeSection?.measures,
              currentMeasureIndex < measures.count else {
            return
        }
        let currentMeasure = measures[currentMeasureIndex]
        self.currentCandidates = currentMeasure.chordCandidates
        self.currentSubstituteCandidates = currentMeasure.substituteCandidates
    }

    /*
    Key変更時に全小節のベース音とコード候補を再計算して反映する。
    
    Arguments:
    key
      新しく設定されたKey。
    
    Usage:
    changeKey() から呼び出される。
    */
    
    private func recalculateAllMeasures(for key: Key) {
        for sIndex in 0..<project.sections.count {
            for mIndex in 0..<project.sections[sIndex].measures.count {
                let degree = project.sections[sIndex].measures[mIndex].baseDegree
                let semitone = key.semitoneOffset + Key.semitonesForMajorDegree(degree)
                let bassNote = Key.noteName(forSemitone: semitone)
                let candidates = theoryService.calculateCandidates(key: key, baseDegree: degree)
                let candidateChords = candidates.map { $0.chord }
                let substitutes = theoryService.calculateSubstituteCandidates(
                    key: key,
                    baseDegree: degree,
                    excludingChords: candidateChords
                )

                project.sections[sIndex].measures[mIndex] = Measure(
                    id: project.sections[sIndex].measures[mIndex].id,
                    baseDegree: degree,
                    bassNote: bassNote,
                    chordCandidates: candidates,
                    substituteCandidates: substitutes,
                    selectedChord: nil
                )
            }
        }
        audioService.updateProject(project)
    }

    // MARK: - ファクトリメソッド

    /*
    テンプレートとKeyから小節配列を生成する。
    
    Arguments:
    template
      進行テンプレート。
    key
      基準調。
    theoryService
      コード候補算出サービス。
    
    Usage:
    セクション追加時、テンプレート変更時、プロジェクト初期化時に呼び出される。
    */
    
    static func createMeasures(
        for template: ProgressionTemplate,
        key: Key,
        theoryService: MusicTheoryServiceProtocol
    ) -> [Measure] {
        return template.degrees.enumerated().map { index, degree -> Measure in
            let semitone = key.semitoneOffset + Key.semitonesForMajorDegree(degree)
            let bassNote = Key.noteName(forSemitone: semitone)
            let candidates = theoryService.calculateCandidates(key: key, baseDegree: degree)
            let candidateChords = candidates.map { $0.chord }
            let substitutes = theoryService.calculateSubstituteCandidates(
                key: key,
                baseDegree: degree,
                excludingChords: candidateChords
            )
            var presetChord: Chord? = nil
            if template.presetChordTypes != nil && index < template.presetChordTypes!.count {
                var slashBass: String? = nil
                if let offsets = template.presetBassOffsets, index < offsets.count {
                    let slashSemi = (key.semitoneOffset + offsets[index]) % 12
                    slashBass = Key.noteName(forSemitone: slashSemi)
                }
                presetChord = Chord(rootNote: bassNote, type: template.presetChordTypes![index], bassNote: slashBass)
            }
            return Measure(
                baseDegree: degree,
                bassNote: bassNote,
                chordCandidates: candidates,
                substituteCandidates: substitutes,
                selectedChord: presetChord
            )
        }
    }

    /*
    テンプレートとKeyから初期プロジェクトデータを生成する。
    
    Arguments:
    template
      王道進行テンプレート。
    key
      基準調。
    theoryService
      コード候補算出サービス。
    
    Usage:
    初期化時および進行テンプレート切り替え時に呼び出される。
    */
    
    private static func createDefaultProject(
        template: ProgressionTemplate,
        key: Key,
        theoryService: MusicTheoryServiceProtocol
    ) -> Project {
        let measures = createMeasures(for: template, key: key, theoryService: theoryService)
        let section = Section(type: .chorus, measures: measures)
        return Project(
            title: template.name,
            bpm: 120.0,
            key: key,
            sections: [section]
        )
    }

    func changeLeadVolume(_ newVolume: Float) {
        let clamped = max(0.0, min(1.0, newVolume))
        self.leadVolume = clamped
        audioService.setLeadVolume(clamped)
    }

    func toggleLeadMute() {
        let next = !isLeadMuted
        self.isLeadMuted = next
        audioService.setLeadMuted(next)
    }

    func toggleLeadSolo() {
        let next = !isLeadSolo
        self.isLeadSolo = next
        audioService.setLeadSolo(next)
    }

    
    func selectPianoInstrument(_ instrument: PianoInstrument) {
        self.selectedPianoInstrument = instrument
        audioService.setPianoProgram(instrument.rawValue)
    }

    func selectLeadInstrument(_ instrument: LeadInstrument) {
        self.selectedLeadInstrument = instrument
        audioService.setLeadInstrument(instrument)
    }

}