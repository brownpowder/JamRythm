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
    ドラムおよびベースの個別音量制御（AudioService）が正常にクランプ・反映されるかを検証する。
    */
    @Test func testIndividualTrackVolume() async throws {
        let audioService = AudioService()
        try audioService.setupEngine()

        audioService.setDrumVolume(0.5)
        #expect(abs(audioService.drumVolume - 0.5) < 0.001)

        audioService.setBassVolume(0.3)
        #expect(abs(audioService.bassVolume - 0.3) < 0.001)

        // クランプ検証 (0.0〜1.0)
        audioService.setDrumVolume(1.5)
        #expect(audioService.drumVolume == 1.0)

        audioService.setBassVolume(-0.2)
        #expect(audioService.bassVolume == 0.0)

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
}

