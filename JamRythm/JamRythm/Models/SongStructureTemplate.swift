//
//  SongStructureTemplate.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/09.
//

import Foundation

// MARK: - 楽曲構成セクション定義

/*
楽曲構成テンプレート内の1セクション（セクション区分と適用コード進行）を表す構造体。
*/
struct SongStructureSection: Identifiable, Equatable {
    let id: UUID
    let type: SectionType
    let template: ProgressionTemplate

    init(id: UUID = UUID(), type: SectionType, template: ProgressionTemplate) {
        self.id = id
        self.type = type
        self.template = template
    }
}

// MARK: - 楽曲構成テンプレート (Song Form)

/*
1コーラスまたは1曲分のセクション構成（Intro, Aメロ, サビ等）を事前定義したマスターテンプレート。
ワンタップで本格的な楽曲全体のコード進行とセクションを一括生成するために使用される。
*/
struct SongStructureTemplate: Identifiable, Equatable {
    let id: String
    let name: String
    let description: String
    let iconName: String
    let genreTag: String
    let recommendedGenre: MusicGenre
    let sections: [SongStructureSection]

    /*
    構成全体の小節数の合計を返す。

    Arguments:
    なし

    Usage:
    楽曲構成選択カードの合計小節数バッジ表示で使用される。
    */

    var totalMeasures: Int {
        sections.reduce(0) { $0 + $1.template.degrees.count }
    }

    // MARK: - プリセット一覧

    static let jpopOneChorus = SongStructureTemplate(
        id: "jpop_one_chorus",
        name: "J-POP 王道1コーラス",
        description: "Introからサビまで駆け抜ける、日本のポップス・アニソン定番の16小節構成",
        iconName: "crown.fill",
        genreTag: "1コーラス・16小節",
        recommendedGenre: .pop,
        sections: [
            SongStructureSection(type: .intro, template: .royalRoad),
            SongStructureSection(type: .verseA, template: .popPunk),
            SongStructureSection(type: .verseB, template: .justTheTwoOfUs),
            SongStructureSection(type: .chorus, template: .fourFiveSix)
        ]
    )

    static let jpopFullSong = SongStructureTemplate(
        id: "jpop_full_song",
        name: "J-POP ドラマチックフル構成",
        description: "Introからラスサビ・Outroまで感情が波のように高まる本格的な28小節の1曲構成",
        iconName: "sparkles",
        genreTag: "フル構成・28小節",
        recommendedGenre: .pop,
        sections: [
            SongStructureSection(type: .intro, template: .canonShort),
            SongStructureSection(type: .verseA, template: .komuro),
            SongStructureSection(type: .verseB, template: .justTheTwoOfUs),
            SongStructureSection(type: .chorus, template: .royalRoad),
            SongStructureSection(type: .bridge, template: .twoFiveOne),
            SongStructureSection(type: .chorus, template: .fourFiveSix),
            SongStructureSection(type: .outro, template: .canonShort)
        ]
    )

    static let neoSoulGroove = SongStructureTemplate(
        id: "neo_soul_groove",
        name: "Neo-Soul / Lo-Fi ジャム",
        description: "丸サ進行と2-5-1を基軸にした、都会的でおしゃれな16小節のグルーヴィー構成",
        iconName: "moon.stars.fill",
        genreTag: "Lo-Fi・16小節",
        recommendedGenre: .lofi,
        sections: [
            SongStructureSection(type: .intro, template: .justTheTwoOfUs),
            SongStructureSection(type: .verseA, template: .justTheTwoOfUs),
            SongStructureSection(type: .bridge, template: .twoFiveOne),
            SongStructureSection(type: .outro, template: .justTheTwoOfUs)
        ]
    )

    static let rockAnthem = SongStructureTemplate(
        id: "rock_anthem",
        name: "Rock / Pop-Punk アンセム",
        description: "力強い疾走感とサビの爆発力を持つ、ロックやパンクに最適な16小節構成",
        iconName: "flame.fill",
        genreTag: "Rock・16小節",
        recommendedGenre: .rock,
        sections: [
            SongStructureSection(type: .intro, template: .popPunk),
            SongStructureSection(type: .verseA, template: .popPunk),
            SongStructureSection(type: .chorus, template: .fourFiveSix),
            SongStructureSection(type: .outro, template: .popPunk)
        ]
    )

    static let classicBallad = SongStructureTemplate(
        id: "classic_ballad",
        name: "50s オールディーズ / バラード",
        description: "スタンド・バイ・ミー進行を軸にした、時代を超えて愛されるレトロで心温まる16小節構成",
        iconName: "guitars.fill",
        genreTag: "バラード・16小節",
        recommendedGenre: .pop,
        sections: [
            SongStructureSection(type: .verseA, template: .standByMe),
            SongStructureSection(type: .verseB, template: .standByMe),
            SongStructureSection(type: .bridge, template: .royalRoad),
            SongStructureSection(type: .outro, template: .standByMe)
        ]
    )

    static let allStructures: [SongStructureTemplate] = [
        .jpopOneChorus,
        .jpopFullSong,
        .neoSoulGroove,
        .rockAnthem,
        .classicBallad
    ]
}
