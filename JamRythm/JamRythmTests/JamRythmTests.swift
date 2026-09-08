//
//  JamRythmTests.swift
//  JamRythmTests
//
//  Created by KanayTakum on 2026/09/08.
//

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
}
