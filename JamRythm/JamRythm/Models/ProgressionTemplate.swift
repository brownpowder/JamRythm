//
//  ProgressionTemplate.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import Foundation

/*
王道コード進行のマスターデータテンプレート。
キーに依存しない度数（ディグリーネーム）の配列で保持する。
*/
struct ProgressionTemplate: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let degrees: [Int]

    // MARK: - プリセットテンプレート一覧

    static let royalRoad = ProgressionTemplate(
        id: "royal_road",
        name: "王道進行 (4-5-3-6)",
        description: "J-POPやアニソンで最も親しまれている感動的で疾走感のある進行",
        degrees: [4, 5, 3, 6]
    )

    static let komuro = ProgressionTemplate(
        id: "komuro",
        name: "小室進行 (6-4-5-1)",
        description: "切なさとドラマチックな高揚感を生み出す定番進行",
        degrees: [6, 4, 5, 1]
    )

    static let justTheTwoOfUs = ProgressionTemplate(
        id: "marusa_jttou",
        name: "丸サ進行 (4-3-6-1)",
        description: "洗練された都会的なグルーヴ感とおしゃれな響きを持つ進行",
        degrees: [4, 3, 6, 1]
    )

    static let canon = ProgressionTemplate(
        id: "canon_8",
        name: "カノン進行 (1-5-6-3-4-1-4-5)",
        description: "美しく流れるようなクラシカルかつ普遍的な8小節進行",
        degrees: [1, 5, 6, 3, 4, 1, 4, 5]
    )

    static let allTemplates: [ProgressionTemplate] = [
        .royalRoad,
        .komuro,
        .justTheTwoOfUs,
        .canon
    ]
}
