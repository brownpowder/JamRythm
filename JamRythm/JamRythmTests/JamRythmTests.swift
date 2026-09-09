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

        // 初期値はPop
        #expect(viewModel.selectedGenre == .pop)
        #expect(viewModel.project.genre == .pop)
        #expect(audioService.genre == .pop)

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

        // Popへ変更（ドラム: Acoustic, ベース: Acoustic）
        viewModel.changeGenre(.pop)
        #expect(viewModel.selectedGenre == .pop)
        #expect(viewModel.project.genre == .pop)
        #expect(audioService.genre == .pop)
        #expect(viewModel.selectedDrumInstrument == .acoustic)
        #expect(viewModel.selectedBassInstrument == .acoustic)
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
    楽曲構成テンプレート（1コーラス・フル構成など）の一括自動生成とViewModelへの適用を検証する。
    */
    @Test @MainActor func testSongStructureTemplatesAndApplication() async throws {
        #expect(SongStructureTemplate.allStructures.count == 5)

        // 小節数計算の検証
        #expect(SongStructureTemplate.jpopOneChorus.totalMeasures == 16)
        #expect(SongStructureTemplate.jpopFullSong.totalMeasures == 28)
        #expect(SongStructureTemplate.neoSoulGroove.totalMeasures == 16)
        #expect(SongStructureTemplate.rockAnthem.totalMeasures == 16)
        #expect(SongStructureTemplate.classicBallad.totalMeasures == 16)

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
}




