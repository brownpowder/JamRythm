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
    private let audioService: AudioServiceProtocol
    private let theoryService: MusicTheoryServiceProtocol
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
    @Published var bassProgram: UInt8 = 0
    @Published var drumProgram: UInt8 = 0
    @Published var volume: Float = 0.8
    @Published var drumVolume: Float = 0.8
    @Published var bassVolume: Float = 0.8
    @Published var selectedDrumInstrument: DrumInstrument = .acoustic
    @Published var selectedBassInstrument: BassInstrument = .acoustic
    @Published var isShowingMixer: Bool = false
    @Published var errorMessage: String?

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
        audioService: AudioServiceProtocol? = nil,
        theoryService: MusicTheoryServiceProtocol? = nil
    ) {
        let audio = audioService ?? AudioService()
        let theory = theoryService ?? MusicTheoryService()
        self.audioService = audio
        self.theoryService = theory

        let initialProject = Self.createDefaultProject(template: .royalRoad, key: .C, theoryService: theory)
        self.project = initialProject
        self.volume = audio.volume
        self.drumVolume = audio.drumVolume
        self.bassVolume = audio.bassVolume
        self.selectedDrumInstrument = DrumInstrument(rawValue: audio.drumProgram) ?? .acoustic
        self.selectedBassInstrument = BassInstrument(rawValue: audio.bassProgram) ?? .acoustic

        setupAudioEngine()
        bindAudioPosition()
        updateCandidatesForCurrentMeasure()
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
        playChordPreview(chord)
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
    ドラム音色プリセットを選択し、AudioServiceへ反映する。

    Arguments:
    instrument
      選択されたドラムプリセット（DrumInstrument）。Pickerから渡される。

    Usage:
    ミキサーのドラム音色Picker操作時に呼び出される。
    */

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
            self.errorMessage = "オーディオエンジンの初期化に失敗しました: \(error.localizedDescription)"
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
        return template.degrees.map { degree -> Measure in
            let semitone = key.semitoneOffset + Key.semitonesForMajorDegree(degree)
            let bassNote = Key.noteName(forSemitone: semitone)
            let candidates = theoryService.calculateCandidates(key: key, baseDegree: degree)
            let candidateChords = candidates.map { $0.chord }
            let substitutes = theoryService.calculateSubstituteCandidates(
                key: key,
                baseDegree: degree,
                excludingChords: candidateChords
            )
            return Measure(
                baseDegree: degree,
                bassNote: bassNote,
                chordCandidates: candidates,
                substituteCandidates: substitutes,
                selectedChord: nil
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
}
