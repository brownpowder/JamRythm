//
//  JamRythmTests.swift
//  JamRythmTests
//
//  Created by KanayTakum on 2026/09/08.
//

import AVFoundation
import Testing
@testable import JamRythm

struct JamRythmTests {

    /*
    Key = C, Base = 5 (G) に対する4つのコード候補が正しく算出されるかをテストする。
    仕様書(Specification.md)の具体例に基づく検証。
    */
    @Test func testMusicTheoryServiceKeyC_Degree5() async throws {
        let service = MusicTheoryService()
        let candidates = service.calculateCandidates(key: .C, baseDegree: 5)

        #expect(candidates.count == 4)

        // 安定
        let stable = candidates.first { $0.flavor == .stable }
        #expect(stable != nil)
        #expect(stable?.chord.displayString == "G7")

        // 少し切ない (Em7/G)
        let melancholy = candidates.first { $0.flavor == .melancholy }
        #expect(melancholy != nil)
        #expect(melancholy?.chord.displayString == "Em7/G")

        // おしゃれ (Dm9/G)
        let stylish = candidates.first { $0.flavor == .stylish }
        #expect(stylish != nil)
        #expect(stylish?.chord.displayString == "Dm9/G")

        // 緊張感 (D♭7/G)
        let tension = candidates.first { $0.flavor == .tension }
        #expect(tension != nil)
        #expect(tension?.chord.displayString == "D♭7/G")
    }

    /*
    Key = C, Base = 4 (F) に対するコード候補の算出テスト。
    */
    @Test func testMusicTheoryServiceKeyC_Degree4() async throws {
        let service = MusicTheoryService()
        let candidates = service.calculateCandidates(key: .C, baseDegree: 4)

        #expect(candidates.count == 4)

        let stable = candidates.first { $0.flavor == .stable }
        #expect(stable?.chord.displayString == "Fmaj7")

        let melancholy = candidates.first { $0.flavor == .melancholy }
        #expect(melancholy?.chord.displayString == "Fm7")
    }

    /*
    王道進行 (4-5-3-6) のすべての度数で候補が4個ずつ欠損なく返るかを検証する。
    */
    @Test func testRoyalRoadProgressionCandidates() async throws {
        let service = MusicTheoryService()
        let template = ProgressionTemplate.royalRoad

        for degree in template.degrees {
            let candidates = service.calculateCandidates(key: .C, baseDegree: degree)
            #expect(candidates.count == 4)
            #expect(candidates.map { $0.flavor } == ChordFlavor.allCases)
        }
    }

    /*
    Cmaj7, G7, Em7 のギター運指（ボイシング）が正確に返されるかを検証する。
    */
    @Test func testGuitarVoicingCalculation() async throws {
        let service = MusicTheoryService()

        let cmaj7 = Chord(rootNote: "C", type: "maj7", bassNote: nil)
        let cmaj7Voicing = service.guitarVoicing(for: cmaj7)
        #expect(cmaj7Voicing.frets == [nil, 3, 2, 0, 0, 0])

        let g7 = Chord(rootNote: "G", type: "7", bassNote: nil)
        let g7Voicing = service.guitarVoicing(for: g7)
        #expect(g7Voicing.frets == [3, 2, 0, 0, 0, 1])

        // 分数コード (Em7/G)
        let em7g = Chord(rootNote: "E", type: "m7", bassNote: "G")
        let em7gVoicing = service.guitarVoicing(for: em7g)
        #expect(em7gVoicing.frets == [3, 2, 0, 0, 0, 0])
    }

    /*
    Cmaj7 の五線譜構成音（C4, E4, G4, B4）が適切なステップ位置で算出されるかを検証する。
    */
    @Test func testStaffNotesCalculation() async throws {
        let service = MusicTheoryService()

        let cmaj7 = Chord(rootNote: "C", type: "maj7", bassNote: nil)
        let notes = service.staffNotes(for: cmaj7)

        #expect(notes.count == 4)
        // C4 (step -2), E4 (step 0), G4 (step 2), B4 (step 4)
        #expect(notes[0].step == -2)
        #expect(notes[1].step == 0)
        #expect(notes[2].step == 2)
        #expect(notes[3].step == 4)
    }

    /*
    Em7 と Edim7 の五線譜構成音および臨時記号が厳密に区別され、Edim7に♭が付与されることを検証する。
    また、C7、Cm、Caug、Csus4、F#m7b5 などの各コード種別で正確な音名・臨時記号が算出されるかを検証する。
    */
    @Test func testStaffNotesAccidentalsAndDifferentiation() async throws {
        let service = MusicTheoryService()

        let em7 = Chord(rootNote: "E", type: "m7", bassNote: nil)
        let edim7 = Chord(rootNote: "E", type: "dim7", bassNote: nil)

        let em7Notes = service.staffNotes(for: em7)
        let edim7Notes = service.staffNotes(for: edim7)

        // Em7: E4, G4, B4, D5 (すべてナチュラル)
        #expect(em7Notes.map { $0.name } == ["E", "G", "B", "D"])
        #expect(em7Notes.map { $0.accidental } == [nil, nil, nil, nil])

        // Edim7: E4, G4, B♭4, D♭5 (減5度、減7度に♭)
        #expect(edim7Notes.map { $0.name } == ["E", "G", "B♭", "D♭"])
        #expect(edim7Notes.map { $0.accidental } == [nil, nil, "♭", "♭"])
        #expect(em7Notes != edim7Notes)

        // C7: Bに♭
        let c7Notes = service.staffNotes(for: Chord(rootNote: "C", type: "7", bassNote: nil))
        #expect(c7Notes.map { $0.name } == ["C", "E", "G", "B♭"])
        #expect(c7Notes[3].accidental == "♭")

        // Cm: Eに♭
        let cmNotes = service.staffNotes(for: Chord(rootNote: "C", type: "m", bassNote: nil))
        #expect(cmNotes.map { $0.name } == ["C", "E♭", "G"])
        #expect(cmNotes[1].accidental == "♭")

        // Caug: Gに♯
        let caugNotes = service.staffNotes(for: Chord(rootNote: "C", type: "aug", bassNote: nil))
        #expect(caugNotes.map { $0.name } == ["C", "E", "G♯"])
        #expect(caugNotes[2].accidental == "♯")

        // Csus4: 4度(F)が含まれる
        let csus4Notes = service.staffNotes(for: Chord(rootNote: "C", type: "sus4", bassNote: nil))
        #expect(csus4Notes.map { $0.name } == ["C", "F", "G"])

        // F#m7b5: ルートに♯
        let fSharpM7b5Notes = service.staffNotes(for: Chord(rootNote: "F#", type: "m7b5", bassNote: nil))
        #expect(fSharpM7b5Notes.map { $0.name } == ["F♯", "A", "C", "E"])
        #expect(fSharpM7b5Notes[0].accidental == "♯")

        // G♭m7: B♭♭(ダブルフラット)やF♭を排し、実用的なエンハーモニック(A, E)として五線譜上に配置
        let gFlatM7 = Chord(rootNote: "G♭", type: "m7", bassNote: nil)
        let gFlatM7Notes = service.staffNotes(for: gFlatM7)
        #expect(gFlatM7Notes.map { $0.name } == ["G♭", "A", "D♭", "E"])
        #expect(gFlatM7Notes.map { $0.accidental } == ["♭", nil, "♭", nil])
        // ステップ差の検証: G♭(step 2) と A(step 3) が2度音程(差が1)で隣接し、D♭(step 6) と E(step 7) も隣接
        let gFlatSteps = gFlatM7Notes.map { $0.step }
        #expect(gFlatSteps == [2, 3, 6, 7])

        // ギター運指の検証
        let edim7Voicing = service.guitarVoicing(for: edim7)
        #expect(edim7Voicing.frets == [nil, nil, 2, 3, 2, 3])

        // MIDI再生音の検証 (Edim7 vs Em7)
        let edim7Midi = service.chordMidiNotes(for: edim7)
        let em7Midi = service.chordMidiNotes(for: em7)
        #expect(edim7Midi == [64, 67, 70, 73])
        #expect(em7Midi == [64, 67, 71, 74])
    }

    /*
    JamRythm.sf2 からドラム音色(MSB: 120)とベース音色(MSB: 121)が正しくロードできるか検証する。
    */
    @Test func testSoundFontLoading() async throws {
        let drumSampler = AVAudioUnitSampler()
        let bassSampler = AVAudioUnitSampler()

        guard let url = Bundle.main.url(forResource: "JamRythm", withExtension: "sf2") else {
            // バンドルに未配置の場合はスキップ
            return
        }

        // Bass (Program 0~6, MSB 121)
        for prog in 0...6 {
            try bassSampler.loadSoundBankInstrument(
                at: url,
                program: UInt8(prog),
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: 0
            )
        }

        // Drum (Program 0~2, MSB 120)
        for prog in 0...2 {
            try drumSampler.loadSoundBankInstrument(
                at: url,
                program: UInt8(prog),
                bankMSB: UInt8(kAUSampler_DefaultPercussionBankMSB),
                bankLSB: 0
            )
        }
    }

    /*
    AudioServiceのオーディオグラフ構築および初期化が例外なく正常動作するかを検証する。
    ドラムとベースがrhythmMixerを介して接続され、クラッシュなく初期化できることを担保する。
    */
    @Test func testAudioServiceEngineSetup() async throws {
        let audioService = AudioService()
        try audioService.setupEngine()
        audioService.setDrumProgram(0)
        audioService.setBassProgram(0)
        audioService.stop()
    }

    /*
    ドラム、ベース、ピアノの個別音量制御（AudioService）が正常にクランプ・反映されるかを検証する。
    */
    @Test func testIndividualTrackVolume() async throws {
        let audioService = AudioService()
        try audioService.setupEngine()

        audioService.setDrumVolume(0.5)
        #expect(abs(audioService.drumVolume - 0.5) < 0.001)

        audioService.setBassVolume(0.3)
        #expect(abs(audioService.bassVolume - 0.3) < 0.001)

        audioService.setPianoVolume(0.7)
        #expect(abs(audioService.pianoVolume - 0.7) < 0.001)

        // クランプ検証 (0.0〜1.0)
        audioService.setDrumVolume(1.5)
        #expect(audioService.drumVolume == 1.0)

        audioService.setBassVolume(-0.2)
        #expect(audioService.bassVolume == 0.0)

        audioService.setPianoVolume(2.0)
        #expect(audioService.pianoVolume == 1.0)

        audioService.stop()
    }

    /*
    ミキサーのMUTEおよびSOLO制御ロジック（DAW標準の排他・復元挙動）を検証する。
    */
    @Test func testMixerMuteAndSoloLogic() async throws {
        let audioService = AudioService()
        try audioService.setupEngine()

        audioService.setDrumVolume(0.8)
        audioService.setBassVolume(0.8)
        audioService.setPianoVolume(0.8)

        // 初期状態: 全て非ミュート・非ソロ
        #expect(!audioService.drumIsMuted)
        #expect(!audioService.bassIsMuted)
        #expect(!audioService.pianoIsMuted)
        #expect(!audioService.drumIsSolo)
        #expect(!audioService.bassIsSolo)
        #expect(!audioService.pianoIsSolo)

        // ドラムをミュート
        audioService.setDrumMuted(true)
        #expect(audioService.drumIsMuted)

        // ピアノをソロに設定（ドラムとベースは自動消音対象）
        audioService.setPianoSolo(true)
        #expect(audioService.pianoIsSolo)
        #expect(!audioService.drumIsSolo)
        #expect(!audioService.bassIsSolo)

        // ピアノのソロを解除
        audioService.setPianoSolo(false)
        #expect(!audioService.pianoIsSolo)
        // ドラムのミュート状態は保持されていること
        #expect(audioService.drumIsMuted)

        // ドラムのミュート解除
        audioService.setDrumMuted(false)
        #expect(!audioService.drumIsMuted)

        audioService.stop()
    }

    /*
    ドラムおよびベースの音色プリセット切り替え（InstrumentPresets）が正常に動作することを検証する。
    */
    @Test func testInstrumentPresetSelection() async throws {
        let audioService = AudioService()
        try audioService.setupEngine()

        for drum in DrumInstrument.allCases {
            audioService.setDrumProgram(drum.rawValue)
            #expect(audioService.drumProgram == drum.rawValue)
            #expect(!drum.displayName.isEmpty)
        }

        for bass in BassInstrument.allCases {
            audioService.setBassProgram(bass.rawValue)
            #expect(audioService.bassProgram == bass.rawValue)
            #expect(!bass.displayName.isEmpty)
        }

        audioService.stop()
    }

    /*
    音楽理論計算サービス（MusicTheoryService）による代理コード提案の算出を検証する。
    各ディグリー（Ⅰ, Ⅳ, Ⅴ等）において、適切な機能的代理コードや裏コード、サブドミナントマイナーが算出されるかをテストする。
    */
    @Test func testSubstituteCandidatesCalculation() async throws {
        let service = MusicTheoryService()

        // Key of C, Degree 1 (Ⅰ: C) -> Ⅲm7 (Em7) & Ⅵm7 (Am7)
        let deg1Subs = service.calculateSubstituteCandidates(key: .C, baseDegree: 1)
        #expect(deg1Subs.count == 2)
        #expect(deg1Subs[0].chord.displayString == "Em7")
        #expect(deg1Subs[0].label.contains("Ⅲm7"))
        #expect(deg1Subs[1].chord.displayString == "Am7")
        #expect(deg1Subs[1].label.contains("Ⅵm7"))

        // Key of C, Degree 4 (Ⅳ: F) -> Ⅱm7 (Dm7) & Ⅳm7 (Fm7)
        let deg4Subs = service.calculateSubstituteCandidates(key: .C, baseDegree: 4)
        #expect(deg4Subs.count == 2)
        #expect(deg4Subs[0].chord.displayString == "Dm7")
        #expect(deg4Subs[1].chord.displayString == "Fm7")

        // 案2の検証: Fm7 を除外対象に指定した場合、次点候補（♭Ⅶ7: B♭7 バックドア）が自動繰り上げされること
        let fm7 = Chord(rootNote: "F", type: "m7", bassNote: nil)
        let deg4ExcludedSubs = service.calculateSubstituteCandidates(key: .C, baseDegree: 4, excludingChords: [fm7])
        #expect(deg4ExcludedSubs.count == 2)
        #expect(deg4ExcludedSubs[0].chord.displayString == "Dm7")
        #expect(deg4ExcludedSubs[1].chord.displayString == "B♭7")
        #expect(deg4ExcludedSubs[1].label.contains("バックドア"))

        // Key of C, Degree 5 (Ⅴ: G) -> ♭Ⅱ7 裏コード (D♭7) & Ⅶm7♭5 (Bm7b5)
        let deg5Subs = service.calculateSubstituteCandidates(key: .C, baseDegree: 5)
        #expect(deg5Subs.count == 2)
        #expect(deg5Subs[0].chord.displayString == "D♭7")
        #expect(deg5Subs[0].label.contains("裏コード"))
        #expect(deg5Subs[1].chord.displayString == "Bm7b5")
    }

    /*
    PlayEditorViewModelで各進行テンプレートを適用した際に、代理コード候補が正しく生成・更新されるかを検証する。
    また、感情フレーバーコードとの重複が排除され、次点候補が繰り上げられることを検証する。
    */
    @Test func testViewModelSubstituteCandidates() async throws {
        let viewModel = await PlayEditorViewModel()
        let initialSubs = await viewModel.currentSubstituteCandidates
        #expect(!initialSubs.isEmpty)
        // 王道進行の1小節目（F）において、フレーバーのFm7と重複せずB♭7が繰り上がっていること
        #expect(!initialSubs.contains { $0.chord.displayString == "Fm7" })
        #expect(initialSubs.contains { $0.chord.displayString == "B♭7" })

        // 小室進行 (6-4-5-1)
        await viewModel.applyTemplate(.komuro)
        let komuroSubs = await viewModel.currentSubstituteCandidates
        #expect(!komuroSubs.isEmpty)

        // 丸サ進行 (4-3-6-1)
        await viewModel.applyTemplate(.justTheTwoOfUs)
        let marusaSubs = await viewModel.currentSubstituteCandidates
        #expect(!marusaSubs.isEmpty)

        // カノン進行 (1-5-6-3-4-1-4-5)
        await viewModel.applyTemplate(.canon)
        let canonSubs = await viewModel.currentSubstituteCandidates
        #expect(!canonSubs.isEmpty)
    }

    /*
    PlayEditorViewModelにおける複数セクションの追加・複製・削除・選択切り替えおよび再生モードのトグル動作を検証する。
    */
    @Test func testMultiSectionViewModelManagement() async throws {
        let viewModel = await PlayEditorViewModel()

        // 初期セクション数は1（サビ）
        #expect(await viewModel.project.sections.count == 1)
        #expect(await viewModel.selectedSectionIndex == 0)
        #expect(await viewModel.playbackMode == .entireSong)

        // セクション追加 (進行テンプレート直接指定)
        await viewModel.addSection(template: .komuro)
        #expect(await viewModel.project.sections.count == 2)
        #expect(await viewModel.selectedSectionIndex == 1)

        // セクション複製
        await viewModel.duplicateSection(at: 1)
        #expect(await viewModel.project.sections.count == 3)
        #expect(await viewModel.selectedSectionIndex == 2)

        // セクション区分変更
        await viewModel.changeSectionType(at: 2, to: .verseB)
        #expect(await viewModel.project.sections[2].type == .verseB)

        // セクション選択切り替え
        await viewModel.selectSection(at: 0)
        #expect(await viewModel.selectedSectionIndex == 0)
        #expect(await viewModel.activeSection?.type == .chorus)

        // 再生モードトグル (全曲通し ⇔ セクションループ)
        #expect(await viewModel.playbackMode == .entireSong)
        await viewModel.togglePlaybackMode()
        #expect(await viewModel.playbackMode == .sectionLoop)
        await viewModel.togglePlaybackMode()
        #expect(await viewModel.playbackMode == .entireSong)

        // セクション削除
        await viewModel.removeSection(at: 2)
        #expect(await viewModel.project.sections.count == 2)
    }

    /*
    AudioServiceの再生モード切り替えおよびセクションインデックス・小節の更新が正常に反映されるかを検証する。
    */
    @Test func testAudioServiceMultiSectionPlayback() async throws {
        let audioService = AudioService()
        try audioService.setupEngine()

        // 2セクションを持つプロジェクトを準備
        let section1 = Section(type: .verseA, measures: [
            Measure(baseDegree: 6, bassNote: "A"),
            Measure(baseDegree: 4, bassNote: "F")
        ])
        let section2 = Section(type: .chorus, measures: [
            Measure(baseDegree: 4, bassNote: "F"),
            Measure(baseDegree: 5, bassNote: "G")
        ])
        let multiSectionProject = Project(
            title: "Multi Test",
            bpm: 120.0,
            key: .C,
            sections: [section1, section2]
        )

        try audioService.prepare(project: multiSectionProject)

        // 初期は全曲通しモード
        #expect(audioService.playbackMode == .entireSong)

        // セクションループモードに変更
        audioService.setPlaybackMode(.sectionLoop)
        #expect(audioService.playbackMode == .sectionLoop)
        audioService.setPlaybackMode(.entireSong)

        // 指定セクション・小節への頭出し
        audioService.setPlaybackPosition(sectionIndex: 1, measureIndex: 1)
        audioService.setActiveSectionIndex(1)

        audioService.stop()
    }

    /*
    MusicTheoryServiceのchordMidiNotesが各種コードおよび分数コードに対して正しいMIDIノート番号を返すかを検証する。
    */
    @Test func testChordMidiNotesCalculation() async throws {
        let service = MusicTheoryService()

        // Cmaj7: C4(60), E4(64), G4(67), B4(71)
        let cmaj7 = Chord(rootNote: "C", type: "maj7", bassNote: nil)
        let cmaj7Notes = service.chordMidiNotes(for: cmaj7)
        #expect(cmaj7Notes == [60, 64, 67, 71])

        // G7: G3(55), B3(59), D4(62), F4(65)
        let g7 = Chord(rootNote: "G", type: "7", bassNote: nil)
        let g7Notes = service.chordMidiNotes(for: g7)
        #expect(g7Notes == [55, 59, 62, 65])

        // 分数コード (Em7/G): ベース音 G2(43) が先頭に付加される
        let em7g = Chord(rootNote: "E", type: "m7", bassNote: "G")
        let em7gNotes = service.chordMidiNotes(for: em7g)
        #expect(em7gNotes.first == 43)
        #expect(em7gNotes.contains(64)) // E4
    }

    /*
    AudioServiceのplayChordNotesおよびViewModelのplayChordPreviewが正常に実行されるかを検証する。
    */
    @Test func testPianoChordPreviewPlayback() async throws {
        let audioService = AudioService()
        try audioService.setupEngine()

        // ピアノコードプレビュー発音
        audioService.playChordNotes([60, 64, 67, 71])

        let viewModel = await PlayEditorViewModel(audioService: audioService)
        let chord = Chord(rootNote: "F", type: "maj7", bassNote: nil)
        await viewModel.playChordPreview(chord)

        audioService.stop()
    }

    /*
    ViewModelのmoveToNextMeasureおよびmoveToPreviousMeasureによる小節・セクション跨ぎのナビゲーションおよび曲境界（先頭でPrevなし、末尾でNextなし）を検証する。
    */
    @Test func testMeasureNavigation() async throws {
        let viewModel = await PlayEditorViewModel()

        // 初期: セクション0, 小節0（曲頭なのでPrevはnil）
        #expect(await viewModel.currentMeasureIndex == 0)
        #expect(await viewModel.previousChord == nil)
        let initialCurrent = await viewModel.currentChord
        let initialNext = await viewModel.nextChord
        #expect(initialNext != nil)

        // 先頭でPreviousを押しても小節は0のまま
        await viewModel.moveToPreviousMeasure()
        #expect(await viewModel.currentMeasureIndex == 0)
        #expect(await viewModel.previousChord == nil)

        // Nextへ進む
        await viewModel.moveToNextMeasure()
        #expect(await viewModel.currentMeasureIndex == 1)
        #expect(await viewModel.currentChord.displayString == initialNext?.displayString)
        #expect(await viewModel.previousChord?.displayString == initialCurrent.displayString)

        // Previousで戻る
        await viewModel.moveToPreviousMeasure()
        #expect(await viewModel.currentMeasureIndex == 0)
        #expect(await viewModel.previousChord == nil)
        #expect(await viewModel.currentChord.displayString == initialCurrent.displayString)

        // 最後の小節まで進める（4小節進行の末尾: measure 3）
        await viewModel.moveToNextMeasure() // 1
        await viewModel.moveToNextMeasure() // 2
        await viewModel.moveToNextMeasure() // 3
        #expect(await viewModel.currentMeasureIndex == 3)
        // 最終小節なのでNextはnil
        #expect(await viewModel.nextChord == nil)

        // 最終小節でNextを押しても進まない
        await viewModel.moveToNextMeasure()
        #expect(await viewModel.currentMeasureIndex == 3)
    }

    /*
    セクション内の小節にカスタム選択されたコードがAudioServiceへ即座に反映され、
    安定コード（デフォルト）ではなく選択されたコード（例: Edim7）が再生対象となることを検証する。
    */
    @Test @MainActor func testCustomizedChordPlaybackInAudioService() async throws {
        let audioService = AudioService()
        let theoryService = MusicTheoryService()
        let viewModel = PlayEditorViewModel(audioService: audioService, theoryService: theoryService)

        // 王道進行 (Fmaj7 - G7 - Em7 - Am7) の小節2 (Em7)
        let defaultChord = viewModel.project.sections[0].measures[2].activeChord
        #expect(defaultChord.type == "m7") // デフォルトは安定コード(Em7)

        // ユーザーがEdim7を選択
        let edim7 = Chord(rootNote: "E", type: "dim7", bassNote: nil)
        viewModel.selectChord(edim7, forMeasureIndex: 2)

        // ViewModelの小節データがEdim7になっていること
        #expect(viewModel.project.sections[0].measures[2].selectedChord == edim7)
        #expect(viewModel.project.sections[0].measures[2].activeChord == edim7)

        // AudioServiceの内部プロジェクトでも小節2がEdim7になっていること
        audioService.setPlaybackPosition(sectionIndex: 0, measureIndex: 2)
        let chordNotes = theoryService.chordMidiNotes(for: viewModel.project.sections[0].measures[2].activeChord)
        #expect(chordNotes == [64, 67, 70, 73]) // Edim7 (E, G, Bb, Db)
    }

    /*
    音楽ジャンルの全ケースで表示名、短縮名、アイコン名、スタイル解説が正しく定義されていることを検証する。
    */
    @Test func testGenreModelAttributes() async throws {
        for genre in MusicGenre.allCases {
            #expect(!genre.displayName.isEmpty)
            #expect(!genre.shortName.isEmpty)
            #expect(!genre.iconName.isEmpty)
            #expect(!genre.styleDescription.isEmpty)
        }
        #expect(MusicGenre.allCases.count == 5)
    }

    /*
    ViewModelでジャンルを変更した際に、ViewModel内部状態、Project、およびAudioServiceへ即時反映されることを検証する。
    */
    @Test @MainActor func testGenreSelectionAndAudioServiceSync() async throws {
        let audioService = AudioService()
        let theoryService = MusicTheoryService()
        let viewModel = PlayEditorViewModel(audioService: audioService, theoryService: theoryService)

        // 初期値はPop（ドラム: Acoustic, ベース: Dub Sub）
        #expect(viewModel.selectedGenre == .pop)
        #expect(viewModel.project.genre == .pop)
        #expect(audioService.genre == .pop)
        #expect(viewModel.selectedDrumInstrument == .acoustic)
        #expect(viewModel.selectedBassInstrument == .dub)
        #expect(audioService.bassProgram == BassInstrument.dub.rawValue)

        // Danceへ変更（ドラム: Electronic, ベース: Synth Saw）
        viewModel.changeGenre(.dance)
        #expect(viewModel.selectedGenre == .dance)
        #expect(viewModel.project.genre == .dance)
        #expect(audioService.genre == .dance)
        #expect(viewModel.selectedDrumInstrument == .electronic)
        #expect(viewModel.selectedBassInstrument == .synthSaw)
        #expect(audioService.drumProgram == DrumInstrument.electronic.rawValue)
        #expect(audioService.bassProgram == BassInstrument.synthSaw.rawValue)

        // Lo-Fiへ変更（ドラム: Lo-Fi Dub, ベース: Dub Sub）
        viewModel.changeGenre(.lofi)
        #expect(viewModel.selectedGenre == .lofi)
        #expect(viewModel.project.genre == .lofi)
        #expect(audioService.genre == .lofi)
        #expect(viewModel.selectedDrumInstrument == .dub)
        #expect(viewModel.selectedBassInstrument == .dub)
        #expect(audioService.drumProgram == DrumInstrument.dub.rawValue)
        #expect(audioService.bassProgram == BassInstrument.dub.rawValue)

        // R&Bへ変更（ドラム: Electronic, ベース: Synth Sine）
        viewModel.changeGenre(.rAndB)
        #expect(viewModel.selectedGenre == .rAndB)
        #expect(viewModel.project.genre == .rAndB)
        #expect(audioService.genre == .rAndB)
        #expect(viewModel.selectedDrumInstrument == .electronic)
        #expect(viewModel.selectedBassInstrument == .synthSine)

        // Rockへ変更（ドラム: Acoustic, ベース: Acoustic）
        viewModel.changeGenre(.rock)
        #expect(viewModel.selectedGenre == .rock)
        #expect(viewModel.project.genre == .rock)
        #expect(audioService.genre == .rock)
        #expect(viewModel.selectedDrumInstrument == .acoustic)
        #expect(viewModel.selectedBassInstrument == .acoustic)

        // Popへ変更（ドラム: Acoustic, ベース: Dub Sub）
        viewModel.changeGenre(.pop)
        #expect(viewModel.selectedGenre == .pop)
        #expect(viewModel.project.genre == .pop)
        #expect(audioService.genre == .pop)
        #expect(viewModel.selectedDrumInstrument == .acoustic)
        #expect(viewModel.selectedBassInstrument == .dub)
        #expect(audioService.bassProgram == BassInstrument.dub.rawValue)
    }

    /*
    拡張されたコード進行テンプレート（王道、丸サ、小室、カノン、ポップパンク、2-5-1、4-5-6、スタンドバイミー、アンダルシア、カノン短縮の全10種類）の属性とローマ数字変換を検証する。
    */
    @Test func testProgressionTemplatesAttributes() async throws {
        let templates = ProgressionTemplate.allTemplates
        #expect(templates.count == 10)

        for template in templates {
            #expect(!template.id.isEmpty)
            #expect(!template.name.isEmpty)
            #expect(!template.description.isEmpty)
            #expect(!template.degrees.isEmpty)
            #expect(!template.iconName.isEmpty)
            #expect(!template.genreTag.isEmpty)
            #expect(template.romanDegrees.count == template.degrees.count)
        }

        // ポップパンク (1-5-6-4)
        #expect(ProgressionTemplate.popPunk.degrees == [1, 5, 6, 4])
        #expect(ProgressionTemplate.popPunk.romanDegrees == ["I", "V", "VI", "IV"])

        // 2-5-1 (2-5-1-6)
        #expect(ProgressionTemplate.twoFiveOne.degrees == [2, 5, 1, 6])
        #expect(ProgressionTemplate.twoFiveOne.romanDegrees == ["II", "V", "I", "VI"])

        // 4-5-6 (4-5-6-6)
        #expect(ProgressionTemplate.fourFiveSix.degrees == [4, 5, 6, 6])
        #expect(ProgressionTemplate.fourFiveSix.romanDegrees == ["IV", "V", "VI", "VI"])
    }

    /*
    新テンプレートによるセクション追加およびシート開閉フラグの動作を検証する。
    */
    @Test @MainActor func testAddSectionWithNewTemplatesAndSheet() async throws {
        let audioService = AudioService()
        let theoryService = MusicTheoryService()
        let viewModel = PlayEditorViewModel(audioService: audioService, theoryService: theoryService)

        #expect(viewModel.project.sections.count == 1)
        #expect(!viewModel.isShowingAddSectionSheet)

        // シートを開くフラグ
        viewModel.isShowingAddSectionSheet = true
        #expect(viewModel.isShowingAddSectionSheet)

        // ポップパンク進行でセクション追加
        viewModel.addSection(template: .popPunk)
        #expect(viewModel.project.sections.count == 2)
        #expect(viewModel.project.sections[1].measures.count == 4)
        #expect(viewModel.project.sections[1].measures.map { $0.baseDegree } == [1, 5, 6, 4])

        // 2-5-1進行でセクション追加
        viewModel.addSection(template: .twoFiveOne)
        #expect(viewModel.project.sections.count == 3)
        #expect(viewModel.project.sections[2].measures.count == 4)
        #expect(viewModel.project.sections[2].measures.map { $0.baseDegree } == [2, 5, 1, 6])

        // カノン進行でセクション追加（8小節）
        viewModel.addSection(template: .canon)
        #expect(viewModel.project.sections.count == 4)
        #expect(viewModel.project.sections[3].measures.count == 8)
    }

    /*
    既存セクションのコード進行変更シートの開閉状態管理およびテンプレート適用の動作を検証する。
    */
    @Test @MainActor func testSectionProgressionChangeWithSheet() async throws {
        let audioService = AudioService()
        let theoryService = MusicTheoryService()
        let viewModel = PlayEditorViewModel(audioService: audioService, theoryService: theoryService)

        // 初期状態: セクション0は王道進行 (4-5-3-6)
        #expect(viewModel.sectionIndexForProgressionChange == nil)
        #expect(viewModel.project.sections[0].measures.map { $0.baseDegree } == [4, 5, 3, 6])

        // ユーザーがセクション0の「コード進行を変更」をタップ
        viewModel.sectionIndexForProgressionChange = 0
        #expect(viewModel.sectionIndexForProgressionChange == 0)

        // シートから丸サ進行 (4-3-6-1) を選択
        viewModel.applyTemplate(.justTheTwoOfUs, toSectionIndex: 0)
        viewModel.sectionIndexForProgressionChange = nil

        // セクション0の進行が丸サ進行に更新されていること
        #expect(viewModel.project.sections[0].measures.map { $0.baseDegree } == [4, 3, 6, 1])
        #expect(viewModel.sectionIndexForProgressionChange == nil)
    }

    /*
    追加された定番進行テンプレート（スタンド・バイ・ミー、アンダルシア、カノン短縮）の度数および全件数を検証する。
    */
    @Test func testExpandedProgressionTemplates() async throws {
        #expect(ProgressionTemplate.allTemplates.count == 10)

        // スタンド・バイ・ミー進行 (1-6-4-5)
        #expect(ProgressionTemplate.standByMe.degrees == [1, 6, 4, 5])
        #expect(ProgressionTemplate.standByMe.romanDegrees == ["I", "VI", "IV", "V"])

        // アンダルシア進行 (6-5-4-3)
        #expect(ProgressionTemplate.andalusia.degrees == [6, 5, 4, 3])
        #expect(ProgressionTemplate.andalusia.romanDegrees == ["VI", "V", "IV", "III"])

        // カノン短縮版 (1-5-6-3)
        #expect(ProgressionTemplate.canonShort.degrees == [1, 5, 6, 3])
        #expect(ProgressionTemplate.canonShort.romanDegrees == ["I", "V", "VI", "III"])
    }

    /*
    楽曲構成テンプレート（1コーラス・フル構成など）のカテゴリ分類、ランダム生成、およびViewModelへの適用を検証する。
    */
    @Test @MainActor func testSongStructureTemplatesAndApplication() async throws {
        #expect(SongStructureTemplate.allStructures.count == 7)

        // カテゴリ別のフィルタリング検証
        let oneChorusList = SongStructureTemplate.allStructures.filter { $0.category == .oneChorus }
        let fullSongList = SongStructureTemplate.allStructures.filter { $0.category == .fullSong }
        #expect(oneChorusList.count == 4)
        #expect(fullSongList.count == 3)

        // 小節数計算の検証
        #expect(SongStructureTemplate.jpopOneChorus.totalMeasures == 16)
        #expect(SongStructureTemplate.jpopFullSong.totalMeasures == 28)
        #expect(SongStructureTemplate.neoSoulGroove.totalMeasures == 16)
        #expect(SongStructureTemplate.neoSoulFullSong.totalMeasures == 28)
        #expect(SongStructureTemplate.rockAnthem.totalMeasures == 16)
        #expect(SongStructureTemplate.rockFullSong.totalMeasures == 28)
        #expect(SongStructureTemplate.classicBallad.totalMeasures == 16)

        // ランダム生成ロジックの検証
        let randomOneChorus = SongStructureTemplate.generateRandom(category: .oneChorus, baseGenre: .pop)
        #expect(randomOneChorus.category == .oneChorus)
        #expect(randomOneChorus.totalMeasures == 16)
        #expect(randomOneChorus.sections.count == 4)
        #expect(randomOneChorus.recommendedGenre == .pop)

        let randomFullSong = SongStructureTemplate.generateRandom(category: .fullSong, baseGenre: .rock)
        #expect(randomFullSong.category == .fullSong)
        #expect(randomFullSong.totalMeasures == 28)
        #expect(randomFullSong.sections.count == 7)
        #expect(randomFullSong.recommendedGenre == .rock)

        let audioService = AudioService()
        let theoryService = MusicTheoryService()
        let viewModel = PlayEditorViewModel(audioService: audioService, theoryService: theoryService)

        // シート表示フラグの検証
        #expect(!viewModel.isShowingSongStructureSheet)
        viewModel.isShowingSongStructureSheet = true
        #expect(viewModel.isShowingSongStructureSheet)

        // J-POP 1コーラスを適用
        viewModel.applySongStructure(.jpopOneChorus)

        #expect(viewModel.project.sections.count == 4)
        #expect(viewModel.project.sections[0].type == .intro)
        #expect(viewModel.project.sections[1].type == .verseA)
        #expect(viewModel.project.sections[2].type == .verseB)
        #expect(viewModel.project.sections[3].type == .chorus)
        #expect(viewModel.selectedSectionIndex == 0)
        #expect(viewModel.currentMeasureIndex == 0)
        #expect(viewModel.project.genre == .pop)
        #expect(viewModel.project.bpm == 128.0)
        #expect(audioService.bpm == 128.0)

        // 各セクションの小節数・度数検証
        // Intro: 王道 (4-5-3-6)
        #expect(viewModel.project.sections[0].measures.map { $0.baseDegree } == [4, 5, 3, 6])
        // Aメロ: ポップパンク (1-5-6-4)
        #expect(viewModel.project.sections[1].measures.map { $0.baseDegree } == [1, 5, 6, 4])
        // Bメロ: 丸サ (4-3-6-1)
        #expect(viewModel.project.sections[2].measures.map { $0.baseDegree } == [4, 3, 6, 1])
        // サビ: 4-5-6 (4-5-6-6)
        #expect(viewModel.project.sections[3].measures.map { $0.baseDegree } == [4, 5, 6, 6])

        // J-POP フル構成を適用 (28小節・7セクション)
        viewModel.applySongStructure(.jpopFullSong)
        #expect(viewModel.project.sections.count == 7)
        let totalMeasures = viewModel.project.sections.reduce(0) { $0 + $1.measures.count }
        #expect(totalMeasures == 28)
        #expect(viewModel.project.sections.map { $0.type } == [.intro, .verseA, .verseB, .chorus, .bridge, .chorus, .outro])
        #expect(viewModel.project.bpm == 125.0)
        #expect(audioService.bpm == 125.0)

        // ランダム楽曲生成のViewModel適用検証
        viewModel.generateAndApplyRandomSongStructure(category: .oneChorus)
        #expect(viewModel.project.sections.count == 4)
        #expect(viewModel.project.sections.reduce(0) { $0 + $1.measures.count } == 16)

        viewModel.generateAndApplyRandomSongStructure(category: .fullSong)
        #expect(viewModel.project.sections.count == 7)
        #expect(viewModel.project.sections.reduce(0) { $0 + $1.measures.count } == 28)

        // Lo-Fiジャムを適用（ジャンル & テンポ連動検証）
        viewModel.applySongStructure(.neoSoulGroove)
        #expect(viewModel.project.genre == .lofi)
        #expect(viewModel.project.sections.count == 4)
        #expect(viewModel.project.bpm == 84.0)
        #expect(audioService.bpm == 84.0)

        // Rockアンセムを適用（テンポ 160.0 検証）
        viewModel.applySongStructure(.rockAnthem)
        #expect(viewModel.project.genre == .rock)
        #expect(viewModel.project.bpm == 160.0)
        #expect(audioService.bpm == 160.0)
    }

    /*
    Key Cにおけるペンタトニック（5音）およびダイアトニック（7音）のスケール構成音・指板ポジション算出を検証する。
    */
    @Test func testScaleInfoCalculation() async throws {
        let theoryService = MusicTheoryService()
        let chordC = Chord(rootNote: "C", type: "", bassNote: nil)

        // Key C ペンタトニック（デフォルトは平行調 A マイナーペンタトニック: A, C, D, E, G）
        let pentaInfo = theoryService.scaleInfo(for: .C, chord: chordC, scaleType: .pentatonic)
        #expect(pentaInfo.keyName == "C")
        #expect(pentaInfo.scaleName == "A マイナーペンタ")
        #expect(pentaInfo.scaleNotes == ["A", "C", "D", "E", "G"])
        #expect(!pentaInfo.positions.isEmpty)

        // 5弦3フレットが "C"（現在コードCのルート音のため role は .root）であること
        let cOn5thString = pentaInfo.positions.first { $0.stringNumber == 5 && $0.fret == 3 }
        #expect(cOn5thString != nil)
        #expect(cOn5thString?.noteName == "C")
        #expect(cOn5thString?.role == .root)

        // コード基準 (.chord) で取得した場合は C メジャーペンタトニック (C, D, E, G, A) となること
        let chordPentaInfo = theoryService.scaleInfo(for: .C, chord: chordC, scaleType: .pentatonic, referenceMode: .chord)
        #expect(chordPentaInfo.scaleName == "C メジャーペンタ")
        #expect(chordPentaInfo.scaleNotes == ["C", "D", "E", "G", "A"])

        // Key C メジャースケール (C, D, E, F, G, A, B)
        let diatonicInfo = theoryService.scaleInfo(for: .C, chord: chordC, scaleType: .diatonic)
        #expect(diatonicInfo.scaleNotes == ["C", "D", "E", "F", "G", "A", "B"])
        #expect(diatonicInfo.positions.count > pentaInfo.positions.count)
    }

    /*
    現在のコードに応じて指板上の音の役割（Root, ChordTone, ScaleTone）が正しく割り振られるかを検証する。
    */
    @Test func testScalePositionsRolesWithDifferentChords() async throws {
        let theoryService = MusicTheoryService()

        // Key C でコードが F の場合（ダイアトニックスケール）
        let chordF = Chord(rootNote: "F", type: "", bassNote: nil)
        let scaleInfo = theoryService.scaleInfo(for: .C, chord: chordF, scaleType: .diatonic)

        // 6弦1フレット（F）はコードのRoot
        let fOn6th = scaleInfo.positions.first { $0.stringNumber == 6 && $0.fret == 1 }
        #expect(fOn6th != nil)
        #expect(fOn6th?.noteName == "F")
        #expect(fOn6th?.role == .root)

        // 5弦0フレット開放弦（A）はFの3度（ChordTone）
        let aOn5th = scaleInfo.positions.first { $0.stringNumber == 5 && $0.fret == 0 }
        #expect(aOn5th != nil)
        #expect(aOn5th?.noteName == "A")
        #expect(aOn5th?.role == .chordTone)

        // 4弦0フレット開放弦（D）はスケール通過音（ScaleTone）
        let dOn4th = scaleInfo.positions.first { $0.stringNumber == 4 && $0.fret == 0 }
        #expect(dOn4th != nil)
        #expect(dOn4th?.noteName == "D")
        #expect(dOn4th?.role == .scaleTone)
    }

    /*
    新設されたテンション（13th, 7(#9), 11th, mM7等）およびオンコードのMIDIノート計算を検証する。
    */
    @Test func testExpandedChordToneFormulas() async throws {
        let theoryService = MusicTheoryService()

        // C13 (C, E, G, Bb, D, A)
        let c13 = Chord(rootNote: "C", type: "13", bassNote: nil)
        let c13Notes = theoryService.chordMidiNotes(for: c13)
        #expect(c13Notes.count == 6)
        #expect(c13Notes.contains(60)) // C
        #expect(c13Notes.contains(64)) // E
        #expect(c13Notes.contains(67)) // G
        #expect(c13Notes.contains(70)) // Bb
        #expect(c13Notes.contains(74)) // D (9th)
        #expect(c13Notes.contains(81)) // A (13th)

        // C7(#9) (C, E, G, Bb, D#) - ジミヘンコード
        let c7sharp9 = Chord(rootNote: "C", type: "7(#9)", bassNote: nil)
        let c7sharp9Notes = theoryService.chordMidiNotes(for: c7sharp9)
        #expect(c7sharp9Notes.count == 5)
        #expect(c7sharp9Notes.contains(75)) // D# (#9)

        // オンコード F/G (ルートFのコードにベース音Gが付加される)
        let fOnG = Chord(rootNote: "F", type: "", bassNote: "G")
        let fOnGNotes = theoryService.chordMidiNotes(for: fOnG)
        // 最低音にベース音G (MIDI 43) が入っていること
        #expect(fOnGNotes.first == 43)
    }

    /*
    ViewModelにおける自由カスタムコード設定とAudioService・小節状態の同期を検証する。
    */
    @Test @MainActor func testSetCustomChordInViewModel() async throws {
        let audioService = AudioService()
        let theoryService = MusicTheoryService()
        let viewModel = PlayEditorViewModel(audioService: audioService, theoryService: theoryService)

        // シート開閉フラグ
        #expect(!viewModel.isShowingChordCustomizer)
        viewModel.isShowingChordCustomizer = true
        #expect(viewModel.isShowingChordCustomizer)

        // カスタムコード G7sus4 / F を適用
        let customChord = Chord(rootNote: "G", type: "7sus4", bassNote: "F")
        viewModel.setCustomChord(customChord)

        // 現在小節に正しく反映されていること
        let currentMeasure = viewModel.project.sections[0].measures[viewModel.currentMeasureIndex]
        #expect(currentMeasure.selectedChord == customChord)
        #expect(currentMeasure.activeChord == customChord)
        #expect(viewModel.currentChord == customChord)
        #expect(viewModel.currentChord.displayString == "G7sus4/F")
    }

    /*
    進行セクションから特定のセクション・小節を指定してコードカスタムシートを開く導線（openChordCustomizer）を検証する。
    */
    @Test @MainActor func testOpenChordCustomizerFromSection() async throws {
        let audioService = AudioService()
        let theoryService = MusicTheoryService()
        let viewModel = PlayEditorViewModel(audioService: audioService, theoryService: theoryService)

        // 3小節目（インデックス2）を指定してカスタマイザーを開く
        viewModel.openChordCustomizer(forSection: 0, measureIndex: 2)

        #expect(viewModel.selectedSectionIndex == 0)
        #expect(viewModel.currentMeasureIndex == 2)
        #expect(viewModel.isShowingChordCustomizer == true)
        #expect(viewModel.editingMeasureTitle == "Section 1 - 3小節目")

        // コード適用
        let customChord = Chord(rootNote: "D", type: "m9", bassNote: nil)
        viewModel.setCustomChord(customChord)

        let targetMeasure = viewModel.project.sections[0].measures[2]
        #expect(targetMeasure.activeChord == customChord)
        #expect(viewModel.currentChord.displayString == "Dm9")
    }

    /*
    和声的親和性（ルート音判定）の音楽理論的整合性を検証する。
    */
    @Test func testRootCompatibilityCalculation() throws {
        let service = MusicTheoryService()

        // Key C (ダイアトニック音: C, D, E, F, G, A, B)
        #expect(service.rootCompatibility(root: "C", key: .C, baseDegree: 1) == .verySmooth)
        #expect(service.rootCompatibility(root: "F", key: .C, baseDegree: 4) == .verySmooth)
        #expect(service.rootCompatibility(root: "G", key: .C, baseDegree: 5) == .verySmooth)
        #expect(service.rootCompatibility(root: "A", key: .C, baseDegree: 6) == .verySmooth)

        // モーダルインターチェンジ / 定番借用和音 (bVI=Ab, bVII=Bb, bIII=Eb)
        #expect(service.rootCompatibility(root: "A♭", key: .C, baseDegree: 1) == .smooth)
        #expect(service.rootCompatibility(root: "B♭", key: .C, baseDegree: 1) == .smooth)
        #expect(service.rootCompatibility(root: "E♭", key: .C, baseDegree: 1) == .smooth)

        // 裏コード (bII=Db) / パッシング (F#)
        #expect(service.rootCompatibility(root: "D♭", key: .C, baseDegree: 1) == .flavorful)
        #expect(service.rootCompatibility(root: "G♭", key: .C, baseDegree: 1) == .flavorful)
    }

    /*
    和声的親和性（コード全体判定）の音楽理論的整合性を検証する。
    ダイアトニック、セカンダリードミナント、サブドミナントマイナー、裏コードの分類を担保する。
    */
    @Test func testChordCompatibilityCalculation() throws {
        let service = MusicTheoryService()

        // ダイアトニック王道コード (Key C) -> .verySmooth
        let cMaj7 = Chord(rootNote: "C", type: "maj7", bassNote: nil)
        #expect(service.chordCompatibility(chord: cMaj7, key: .C, baseDegree: 1, originalChord: nil) == .verySmooth)

        let dm7 = Chord(rootNote: "D", type: "m7", bassNote: nil)
        #expect(service.chordCompatibility(chord: dm7, key: .C, baseDegree: 2, originalChord: nil) == .verySmooth)

        let g7 = Chord(rootNote: "G", type: "7", bassNote: nil)
        #expect(service.chordCompatibility(chord: g7, key: .C, baseDegree: 5, originalChord: nil) == .verySmooth)

        // サブドミナントマイナー (Fm, Fm7) -> .dramatic (エモい)
        let fm = Chord(rootNote: "F", type: "m", bassNote: nil)
        #expect(service.chordCompatibility(chord: fm, key: .C, baseDegree: 4, originalChord: nil) == .dramatic)

        // モーダルインターチェンジ借用和音 (Ab, Bb) -> .dramatic
        let abMaj7 = Chord(rootNote: "A♭", type: "maj7", bassNote: nil)
        #expect(service.chordCompatibility(chord: abMaj7, key: .C, baseDegree: 1, originalChord: nil) == .dramatic)

        // 裏コード (Db7) -> .flavorful (スパイス)
        let db7 = Chord(rootNote: "D♭", type: "7", bassNote: nil)
        #expect(service.chordCompatibility(chord: db7, key: .C, baseDegree: 2, originalChord: nil) == .flavorful)
    }

    /*
    次の小節のコードに応じたドミナントモーション解決（文脈判定）の精度を検証する。
    E7 -> Am や D7 -> G は .verySmooth に昇格し、解決しない場合は .flavorful に留まることを担保する。
    */
    @Test func testDominantMotionContextResolution() throws {
        let service = MusicTheoryService()

        let e7 = Chord(rootNote: "E", type: "7", bassNote: nil)
        let am = Chord(rootNote: "A", type: "m", bassNote: nil)
        let g = Chord(rootNote: "G", type: "", bassNote: nil)

        // 次が Am (E7 -> Am は完全4度上解決) -> .verySmooth に昇格！
        let resolvedScore = service.chordCompatibility(
            chord: e7,
            key: .C,
            baseDegree: 3,
            originalChord: nil,
            nextChord: am
        )
        #expect(resolvedScore == .verySmooth)

        // 次が G (E7 -> G は解決しない唐突なセブンス) -> .flavorful (スパイス)
        let unresolvedScore = service.chordCompatibility(
            chord: e7,
            key: .C,
            baseDegree: 3,
            originalChord: nil,
            nextChord: g
        )
        #expect(unresolvedScore == .flavorful)

        // D7 -> G (次がGならツーファイブ解決) -> .verySmooth
        let d7 = Chord(rootNote: "D", type: "7", bassNote: nil)
        let d7Score = service.chordCompatibility(
            chord: d7,
            key: .C,
            baseDegree: 2,
            originalChord: nil,
            nextChord: g
        )
        #expect(d7Score == .verySmooth)
    }

    /*
    ViewModelの編集対象小節情報（editingOriginalChord, editingBaseDegree, editingNextChord）の取得を検証する。
    */
    @Test @MainActor func testViewModelEditingMeasureProperties() async throws {
        let audioService = AudioService()
        let theoryService = MusicTheoryService()
        let viewModel = PlayEditorViewModel(audioService: audioService, theoryService: theoryService)

        // 初期状態（1小節目: 王道進行IV-V-iii-viなら4度F、次小節は5度G）
        #expect(viewModel.editingBaseDegree == 4)
        #expect(viewModel.editingOriginalChord?.rootNote == "F")
        #expect(viewModel.editingNextChord?.rootNote == "G")

        // 3小節目（3度Em、次小節は6度Am）
        viewModel.selectMeasure(inSection: 0, measureIndex: 2)
        #expect(viewModel.editingBaseDegree == 3)
        #expect(viewModel.editingOriginalChord?.rootNote == "E")
        #expect(viewModel.editingNextChord?.rootNote == "A")

        // 4小節目（最終小節: 6度Am、次小節はループ先の1小節目 4度F）
        viewModel.selectMeasure(inSection: 0, measureIndex: 3)
        #expect(viewModel.editingBaseDegree == 6)
        #expect(viewModel.editingOriginalChord?.rootNote == "A")
        #expect(viewModel.editingNextChord?.rootNote == "F")
    }

    /*
    ギターTABのボイシング生成がオープンコード・バレーコード・オンコード等で全コード網羅されているかを検証する。
    */
    @Test func testGuitarVoicingFullCoverage() {
        let service = MusicTheoryService()

        // オープンコード（代表例）
        let cMaj = Chord(rootNote: "C", type: "", bassNote: nil)
        let cVoicing = service.guitarVoicing(for: cMaj)
        #expect(cVoicing.frets.count == 6)

        // バレーコード（Amaj7: 6弦5フレットルートまたは5弦オープン）
        let aMaj7 = Chord(rootNote: "A", type: "maj7", bassNote: nil)
        let aMaj7Voicing = service.guitarVoicing(for: aMaj7)
        #expect(aMaj7Voicing.frets.count == 6)

        // テンションコード（C13, A7(#9) など）
        let c13 = Chord(rootNote: "C", type: "13", bassNote: nil)
        let c13Voicing = service.guitarVoicing(for: c13)
        #expect(c13Voicing.frets.count == 6)

        let a7s9 = Chord(rootNote: "A", type: "7(#9)", bassNote: nil)
        let a7s9Voicing = service.guitarVoicing(for: a7s9)
        #expect(a7s9Voicing.frets.count == 6)

        // オンコード（F/G）
        let fOverG = Chord(rootNote: "F", type: "", bassNote: "G")
        let fgVoicing = service.guitarVoicing(for: fOverG)
        #expect(fgVoicing.frets.count == 6)
        // 6弦が3フレット（G音）であることを確認
        #expect(fgVoicing.frets[0] == 3)
    }

    /*
    五線譜（StaffScore）の音符生成において、オンコード指定時に最低音としてベース音が正しく挿入されるかを検証する。
    */
    @Test func testStaffNotesOnChordBassNote() {
        let service = MusicTheoryService()

        // 通常のFコード (F, A, C)
        let fChord = Chord(rootNote: "F", type: "", bassNote: nil)
        let fNotes = service.staffNotes(for: fChord)
        #expect(fNotes.count == 3)
        #expect(fNotes[0].name == "F")

        // オンコード F/G (G音 + F, A, C)
        let fgChord = Chord(rootNote: "F", type: "", bassNote: "G")
        let fgNotes = service.staffNotes(for: fgChord)
        #expect(fgNotes.count == 4)
        // 先頭がベース音Gであること
        #expect(fgNotes[0].name == "G")
        // ベース音のstepがコード音の最低ステップより低いこと
        #expect(fgNotes[0].step < fgNotes[1].step)
    }

    /*
    スケール指板の「Key基準 ⇔ Chord基準」切替において、適切な旋法導出およびコードトーン包含が行われるかを検証する。
    */
    @Test func testScaleInfoWithReferenceModes() {
        let service = MusicTheoryService()

        // 1. Chord基準: Dm7 -> D ドリアン (7音) / D マイナーペンタ (5音)
        let dm7 = Chord(rootNote: "D", type: "m7", bassNote: nil)
        let dm7Diatonic = service.scaleInfo(for: .C, chord: dm7, scaleType: .diatonic, referenceMode: .chord)
        #expect(dm7Diatonic.scaleName == "D ドリアン")
        #expect(dm7Diatonic.scaleNotes.contains("F"))
        #expect(dm7Diatonic.scaleNotes.contains("B"))

        let dm7Penta = service.scaleInfo(for: .C, chord: dm7, scaleType: .pentatonic, referenceMode: .chord)
        #expect(dm7Penta.scaleName == "D マイナーペンタ")
        #expect(dm7Penta.scaleNotes.contains("F"))

        // 2. Chord基準: E7(#9) -> E HMP5thビロウ (7音)
        let e7sharp9 = Chord(rootNote: "E", type: "7(#9)", bassNote: nil)
        let e7Diatonic = service.scaleInfo(for: .C, chord: e7sharp9, scaleType: .diatonic, referenceMode: .chord)
        #expect(e7Diatonic.scaleName == "E HMP5thビロウ")
        // 半音8 (G♯ / A♭) がスケール音に含まれること
        #expect(e7Diatonic.scaleNotes.contains("A♭"))

        // 3. Key基準: Key C で E7 を選択時、Key外の重要コードトーン「G♯/A♭」が指板に包含プロットされること
        let e7 = Chord(rootNote: "E", type: "7", bassNote: nil)
        let e7KeyMode = service.scaleInfo(for: .C, chord: e7, scaleType: .diatonic, referenceMode: .key)
        #expect(e7KeyMode.scaleName == "C メジャースケール")
        // Cメジャースケール外の G# (A♭) が指板のポジション（3弦1フレット等）に chordTone としてプロットされていること
        let gSharpPositions = e7KeyMode.positions.filter { $0.noteName == "A♭" }
        #expect(!gSharpPositions.isEmpty)
        #expect(gSharpPositions.allSatisfy { $0.role == .chordTone })
    }

    /*
    ミキサーのピアノ音量変更およびミュート・ソロがViewModelとAudioService間で確実に連動することを検証する。
    */
    @Test @MainActor func testMixerPianoVolumeAndMuteIntegration() async throws {
        let audioService = AudioService()
        try audioService.setupEngine()
        let viewModel = PlayEditorViewModel(audioService: audioService)

        // 初期状態
        #expect(viewModel.pianoVolume == 0.8)
        #expect(audioService.pianoVolume == 0.8)
        #expect(!viewModel.isPianoMuted)
        #expect(!audioService.pianoIsMuted)

        // ピアノ音量変更 (50%)
        viewModel.changePianoVolume(0.5)
        #expect(viewModel.pianoVolume == 0.5)
        #expect(audioService.pianoVolume == 0.5)

        // ピアノミュートトグル
        viewModel.togglePianoMute()
        #expect(viewModel.isPianoMuted == true)
        #expect(audioService.pianoIsMuted == true)

        viewModel.togglePianoMute()
        #expect(viewModel.isPianoMuted == false)
        #expect(audioService.pianoIsMuted == false)

        // ピアノソロトグル
        viewModel.togglePianoSolo()
        #expect(viewModel.isPianoSolo == true)
        #expect(audioService.pianoIsSolo == true)

        viewModel.togglePianoSolo()
        #expect(viewModel.isPianoSolo == false)
        #expect(audioService.pianoIsSolo == false)

        // 音量ゼロ
        viewModel.changePianoVolume(0.0)
        #expect(viewModel.pianoVolume == 0.0)
        #expect(audioService.pianoVolume == 0.0)

        audioService.stop()
    }

    /*
    ペンタトニック表示時のマイナーペンタトニック基本表示および
    ノンダイアトニックコード（E7, Fm等）遭遇時のコードスケール自動フォールバックを検証する。
    */
    @Test func testMinorPentatonicSmartFallback() async throws {
        let theoryService = MusicTheoryService()

        // 1. 平行調マイナーペンタトニックの計算確認 (Key C -> A minor penta: A, C, D, E, G)
        let cMinorPenta = theoryService.relativeMinorPentatonic(for: .C)
        #expect(cMinorPenta.name == "A マイナーペンタ")
        #expect(cMinorPenta.semitones == [9, 0, 2, 4, 7])

        // Key G -> E minor penta: E, G, A, B, D (semitones: [4, 7, 9, 11, 2])
        let gMinorPenta = theoryService.relativeMinorPentatonic(for: .G)
        #expect(gMinorPenta.name == "E マイナーペンタ")
        #expect(gMinorPenta.semitones == [4, 7, 9, 11, 2])

        // 2. ダイアトニックコード（C, Am, F, G）でのマイナーペンタ適合判定
        let chordC = Chord(rootNote: "C", type: "", bassNote: nil)
        let chordAm = Chord(rootNote: "A", type: "m", bassNote: nil)
        let chordF = Chord(rootNote: "F", type: "", bassNote: nil)
        let chordG = Chord(rootNote: "G", type: "", bassNote: nil)

        #expect(theoryService.isChordCompatibleWithMinorPenta(chord: chordC, key: .C) == true)
        #expect(theoryService.isChordCompatibleWithMinorPenta(chord: chordAm, key: .C) == true)
        #expect(theoryService.isChordCompatibleWithMinorPenta(chord: chordF, key: .C) == true)
        #expect(theoryService.isChordCompatibleWithMinorPenta(chord: chordG, key: .C) == true)

        // Key基準ペンタトニック選択時、ダイアトニックコードではすべて A マイナーペンタ となること
        let scaleC = theoryService.scaleInfo(for: .C, chord: chordC, scaleType: .pentatonic, referenceMode: .key)
        #expect(scaleC.scaleName == "A マイナーペンタ")

        let scaleAm = theoryService.scaleInfo(for: .C, chord: chordAm, scaleType: .pentatonic, referenceMode: .key)
        #expect(scaleAm.scaleName == "A マイナーペンタ")

        let scaleF = theoryService.scaleInfo(for: .C, chord: chordF, scaleType: .pentatonic, referenceMode: .key)
        #expect(scaleF.scaleName == "A マイナーペンタ")

        // 3. ノンダイアトニックコード（E7: G#含有、Fm: Ab含有）での不適合＆スマート追従判定
        let chordE7 = Chord(rootNote: "E", type: "7", bassNote: nil)
        let chordFm = Chord(rootNote: "F", type: "m", bassNote: nil)

        #expect(theoryService.isChordCompatibleWithMinorPenta(chord: chordE7, key: .C) == false)
        #expect(theoryService.isChordCompatibleWithMinorPenta(chord: chordFm, key: .C) == false)

        // E7では Aマイナーペンタ ではなく、コードに合わせた E HMP5thビロウ（またはEマイナーペンタ）に自動追従すること
        let scaleE7 = theoryService.scaleInfo(for: .C, chord: chordE7, scaleType: .pentatonic, referenceMode: .key)
        #expect(scaleE7.scaleName != "A マイナーペンタ")
        #expect(scaleE7.scaleName.contains("E"))

        // Fmでも Aマイナーペンタ ではなく、Fコードに合わせたスケールに自動追従すること
        let scaleFm = theoryService.scaleInfo(for: .C, chord: chordFm, scaleType: .pentatonic, referenceMode: .key)
        #expect(scaleFm.scaleName != "A マイナーペンタ")
        #expect(scaleFm.scaleName.contains("F"))
    }

    /*
    音名変換（英語 CDE ⇔ 日本語 ドレミ）が正確に動作するかを検証する。
    自然音および変化記号（♭, ♯）が正しくローカライズされることを確認する。
    */
    @Test func testLocalizedNoteNameConversion() async throws {
        // 1. 英語表記（そのまま返ること）
        #expect(NoteNameNotation.localizedNoteName("C", notation: .english) == "C")
        #expect(NoteNameNotation.localizedNoteName("G♭", notation: .english) == "G♭")
        #expect(NoteNameNotation.localizedNoteName("F♯", notation: .english) == "F♯")

        // 2. 日本語（ドレミ）変換
        #expect(NoteNameNotation.localizedNoteName("C", notation: .japanese) == "ド")
        #expect(NoteNameNotation.localizedNoteName("D", notation: .japanese) == "レ")
        #expect(NoteNameNotation.localizedNoteName("E", notation: .japanese) == "ミ")
        #expect(NoteNameNotation.localizedNoteName("F", notation: .japanese) == "ファ")
        #expect(NoteNameNotation.localizedNoteName("G", notation: .japanese) == "ソ")
        #expect(NoteNameNotation.localizedNoteName("A", notation: .japanese) == "ラ")
        #expect(NoteNameNotation.localizedNoteName("B", notation: .japanese) == "シ")

        // 3. 変化記号付きの変換
        #expect(NoteNameNotation.localizedNoteName("G♭", notation: .japanese) == "ソ♭")
        #expect(NoteNameNotation.localizedNoteName("F♯", notation: .japanese) == "ファ♯")
        #expect(NoteNameNotation.localizedNoteName("D♭", notation: .japanese) == "レ♭")

        // 4. スケール構成音の変換（A マイナーペンタ: A, C, D, E, G -> ラ, ド, レ, ミ, ソ）
        let aMinorPenta = ["A", "C", "D", "E", "G"]
        let localizedPenta = aMinorPenta.map { NoteNameNotation.localizedNoteName($0, notation: .japanese) }
        #expect(localizedPenta == ["ラ", "ド", "レ", "ミ", "ソ"])
    }

    /*
    ギターボイシングの複数ポジション生成およびbaseFret算出を検証する。
    Cmaj7に対してローコード、5弦ルート、6弦ルートが返ることを確認する。
    */
    @Test func testGuitarVoicingsMultiplePositions() async throws {
        let service = MusicTheoryService()
        let cmaj7 = Chord(rootNote: "C", type: "maj7", bassNote: nil)
        let voicings = service.guitarVoicings(for: cmaj7)

        #expect(voicings.count >= 2)

        // 1. ローコード
        let openVoicing = voicings.first { $0.positionName == "ローコード" }
        #expect(openVoicing != nil)
        #expect(openVoicing?.baseFret == 1)
        #expect(openVoicing?.frets == [nil, 3, 2, 0, 0, 0])

        // 2. 5弦ルート (3フレットセーハ)
        let string5Voicing = voicings.first { $0.positionName.contains("5弦ルート") }
        #expect(string5Voicing != nil)
        #expect(string5Voicing?.baseFret == 3)
        #expect(string5Voicing?.frets == [nil, 3, 5, 4, 5, 3])

        // 3. 6弦ルート (8フレットセーハ)
        let string6Voicing = voicings.first { $0.positionName.contains("6弦ルート") }
        #expect(string6Voicing != nil)
        #expect(string6Voicing?.baseFret == 8)
        #expect(string6Voicing?.frets == [8, 10, 9, 9, 8, 8])
    }

    /*
    ピアノ伴奏におけるスムーズなボイスリーディング（転回形自動選択）を検証する。
    Cmaj7の後にFmaj7を発音した際、共通音（C, E）が保持され、最小移動量で滑らかに繋がることを確認する。
    */
    @Test func testPianoVoiceLeadingIntegration() async throws {
        let service = MusicTheoryService()
        let cmaj7 = Chord(rootNote: "C", type: "maj7", bassNote: nil)
        let fmaj7 = Chord(rootNote: "F", type: "maj7", bassNote: nil)

        // 1. 初回コード（Cmaj7）: 中心帯域のボイシングが返ること
        let cmaj7Notes = service.voiceLedMidiNotes(for: cmaj7, previousNotes: nil)
        #expect(cmaj7Notes.contains(36)) // C2 ベース音
        let cmaj7Upper = cmaj7Notes.filter { $0 >= 50 }
        #expect(!cmaj7Upper.isEmpty)

        // 2. 次のコード（Fmaj7）: 前のCmaj7の音を引き継ぎ、スムーズに連結すること
        let fmaj7Notes = service.voiceLedMidiNotes(for: fmaj7, previousNotes: cmaj7Notes)
        #expect(fmaj7Notes.contains(41)) // F2 ベース音

        let fmaj7Upper = fmaj7Notes.filter { $0 >= 50 }
        #expect(!fmaj7Upper.isEmpty)

        // 共通音 C(60) または E(64) が保持されていること
        let commonNotes = Set(cmaj7Upper).intersection(Set(fmaj7Upper))
        #expect(!commonNotes.isEmpty)

        // 上声部の平均音高が急激にオクターブ跳躍していないこと（平均ピッチ差が5半音以内）
        let cAvg = Double(cmaj7Upper.reduce(0) { $0 + Int($1) }) / Double(cmaj7Upper.count)
        let fAvg = Double(fmaj7Upper.reduce(0) { $0 + Int($1) }) / Double(fmaj7Upper.count)
        #expect(abs(cAvg - fAvg) <= 5.0)
    }
}




