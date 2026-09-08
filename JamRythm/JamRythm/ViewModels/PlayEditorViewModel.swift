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
    @Published var currentMeasureIndex: Int = 0
    @Published var currentBeat: Int = 1
    @Published var currentCandidates: [ChordCandidate] = []
    @Published var selectedTemplate: ProgressionTemplate = .royalRoad
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
    次の小節のコードを返す（ループ末尾の場合は1小節目）。
    
    Arguments:
    なし
    
    Usage:
    演奏者が次の小節を準備できるように画面に表示する「Next Chord」で使用される。
    */
    
    var nextChord: Chord {
        guard let measures = activeSection?.measures, !measures.isEmpty else {
            return Chord(rootNote: "C", type: "", bassNote: nil)
        }
        let nextIndex = (currentMeasureIndex + 1) % measures.count
        return measures[nextIndex].activeChord
    }

    /*
    現在編集・再生の対象となっているセクションを返す。
    
    Arguments:
    なし
    
    Usage:
    小節リストの取得や更新時に内部で使用される。
    */
    
    private var activeSection: Section? {
        return project.sections.first
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
        guard var section = project.sections.first,
              index < section.measures.count else {
            return
        }
        section.measures[index].selectedChord = chord
        project.sections[0] = section
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
    王道進行テンプレートを切り替え、小節構成を再生成する。
    
    Arguments:
    template
      適用する王道進行テンプレート。テンプレート選択UIから渡される。
    
    Usage:
    進行テンプレート選択時に呼び出される。
    */
    
    func applyTemplate(_ template: ProgressionTemplate) {
        self.selectedTemplate = template
        self.project = Self.createDefaultProject(template: template, key: project.key, theoryService: theoryService)
        self.currentMeasureIndex = 0
        self.currentBeat = 1
        try? audioService.prepare(project: self.project)
        updateCandidatesForCurrentMeasure()
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
        guard var section = project.sections.first else { return }

        for index in 0..<section.measures.count {
            let degree = section.measures[index].baseDegree
            let semitone = key.semitoneOffset + Key.semitonesForMajorDegree(degree)
            let bassNote = Key.noteName(forSemitone: semitone)
            let candidates = theoryService.calculateCandidates(key: key, baseDegree: degree)

            section.measures[index] = Measure(
                id: section.measures[index].id,
                baseDegree: degree,
                bassNote: bassNote,
                chordCandidates: candidates,
                selectedChord: nil
            )
        }

        project.sections[0] = section
    }

    // MARK: - ファクトリメソッド

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
        let measures = template.degrees.map { degree -> Measure in
            let semitone = key.semitoneOffset + Key.semitonesForMajorDegree(degree)
            let bassNote = Key.noteName(forSemitone: semitone)
            let candidates = theoryService.calculateCandidates(key: key, baseDegree: degree)
            return Measure(
                baseDegree: degree,
                bassNote: bassNote,
                chordCandidates: candidates,
                selectedChord: nil
            )
        }

        let section = Section(type: .chorus, measures: measures)
        return Project(
            title: template.name,
            bpm: 120.0,
            key: key,
            sections: [section]
        )
    }
}
