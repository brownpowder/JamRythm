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
    let presetChordTypes: [String]?
    let iconName: String
    let genreTag: String

    init(
        id: String,
        name: String,
        description: String,
        degrees: [Int],
        presetChordTypes: [String]? = nil,
        iconName: String = "music.note",
        genreTag: String = "定番"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.degrees = degrees
        self.presetChordTypes = presetChordTypes
        self.iconName = iconName
        self.genreTag = genreTag
    }

    /*
    度数配列をローマ数字（I, IV, V等）の配列に変換して返す。

    Arguments:
    なし

    Usage:
    進行選択カードのディグリータグ表示で使用される。
    */

    var romanDegrees: [String] {
        degrees.map { deg in
            switch deg {
            case 1: return "I"
            case 2: return "II"
            case 3: return "III"
            case 4: return "IV"
            case 5: return "V"
            case 6: return "VI"
            case 7: return "VII"
            default: return "\(deg)"
            }
        }
    }

    // MARK: - プリセットテンプレート一覧

    static let royalRoad = ProgressionTemplate(
        id: "royal_road",
        name: "王道進行 (4-5-3-6)",
        description: "J-POPやアニソンで最も親しまれている感動的で疾走感のある進行",
        degrees: [4, 5, 3, 6],
        iconName: "crown.fill",
        genreTag: "J-POP定番"
    )

    static let komuro = ProgressionTemplate(
        id: "komuro",
        name: "小室進行 (6-4-5-1)",
        description: "切なさとドラマチックな高揚感を生み出す定番進行",
        degrees: [6, 4, 5, 1],
        iconName: "sparkles",
        genreTag: "ドラマチック"
    )

    static let justTheTwoOfUs = ProgressionTemplate(
        id: "marusa_jttou",
        name: "丸サ進行 (4-3-6-1)",
        description: "洗練された都会的なグルーヴ感とおしゃれな響きを持つ進行",
        degrees: [4, 3, 6, 1],
        iconName: "moon.stars.fill",
        genreTag: "都会的・グルーヴ"
    )

    static let canon = ProgressionTemplate(
        id: "canon_8",
        name: "カノン進行 (1-5-6-3-4-1-4-5)",
        description: "美しく流れるようなクラシカルかつ普遍的な8小節進行",
        degrees: [1, 5, 6, 3, 4, 1, 4, 5],
        iconName: "infinity",
        genreTag: "普遍の8小節"
    )

    static let popPunk = ProgressionTemplate(
        id: "pop_punk",
        name: "ポップパンク進行 (1-5-6-4)",
        description: "世界中の大ヒット曲や洋楽ポップスで愛用される前向きで力強い進行",
        degrees: [1, 5, 6, 4],
        iconName: "flame.fill",
        genreTag: "洋楽・アンセム"
    )

    static let twoFiveOne = ProgressionTemplate(
        id: "two_five_one",
        name: "2-5-1進行 (2-5-1-6)",
        description: "ジャズやネオソウルの心臓部。スムーズな解決感とお洒落なハーモニー",
        degrees: [2, 5, 1, 6],
        iconName: "pianokeys",
        genreTag: "Jazz / R&B"
    )

    static let fourFiveSix = ProgressionTemplate(
        id: "four_five_six",
        name: "4-5-6進行 (4-5-6-6)",
        description: "サビで感情が一気に突き抜ける、近年J-POP最前線のエモーショナル進行",
        degrees: [4, 5, 6, 6],
        iconName: "heart.fill",
        genreTag: "エモーショナル"
    )

    static let standByMe = ProgressionTemplate(
        id: "stand_by_me",
        name: "スタンド・バイ・ミー進行 (1-6-4-5)",
        description: "洋楽黄金期から愛され続けるオールディーズ＆ドゥーワップの普遍的進行",
        degrees: [1, 6, 4, 5],
        iconName: "guitars.fill",
        genreTag: "50s定番"
    )

    static let andalusia = ProgressionTemplate(
        id: "andalusia",
        name: "アンダルシア進行 (6-5-4-3)",
        description: "切ないマイナーコード下降が胸に迫る、情熱的で哀愁漂うドラマチック進行",
        degrees: [6, 5, 4, 3],
        iconName: "flame",
        genreTag: "哀愁・マイナー"
    )

    static let canonShort = ProgressionTemplate(
        id: "canon_short",
        name: "カノン進行・4小節 (1-5-6-3)",
        description: "カノン進行の美しい前半部を凝縮した、穏やかで歌いやすい4小節構成",
        degrees: [1, 5, 6, 3],
        iconName: "leaf.fill",
        genreTag: "穏やか・Aメロ"
    )

    static let cliche = ProgressionTemplate(
        id: "cliche",
        name: "クリシェ進行",
        description: "半音ずつ下がるベースラインが美しくドラマチックな名曲進行",
        degrees: [1, 1, 1, 6, 2, 2, 2, 1],
        presetChordTypes: ["", "M7", "7", "7", "m", "m7", "m6", ""],
        iconName: "music.mic",
        genreTag: "クリシェ"
    )

    static let allTemplates: [ProgressionTemplate] = [
        .cliche,
        .royalRoad,
        .komuro,
        .justTheTwoOfUs,
        .popPunk,
        .fourFiveSix,
        .twoFiveOne,
        .standByMe,
        .andalusia,
        .canonShort,
        .canon
    ]
}
