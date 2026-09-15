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
    let repeatCount: Int

    init(id: UUID = UUID(), type: SectionType, template: ProgressionTemplate, repeatCount: Int = 1) {
        self.id = id
        self.type = type
        self.template = template
        self.repeatCount = repeatCount
    }
}

// MARK: - 楽曲構成カテゴリ (1コーラス / 1曲丸ごと)

/*
楽曲構成の規模感を表すカテゴリ分類（1コーラス または 1曲丸ごと）。
*/
enum SongStructureCategory: String, CaseIterable, Identifiable {
    case oneChorus = "1コーラス"
    case fullSong = "1曲丸ごと"

    var id: String { rawValue }

    /*
    カテゴリの説明テキストを返す。

    Arguments:
    なし

    Usage:
    楽曲生成シートのカテゴリ切り替え案内表示で使用される。
    */

    var description: String {
        switch self {
        case .oneChorus:
            return "Introからサビまで、アイデアスケッチやループに最適な48小節構成"
        case .fullSong:
            return "Intro〜A/B〜サビ〜間奏〜ラスサビ〜Outroまで展開する24〜48小節構成"
        }
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
    let category: SongStructureCategory
    let recommendedGenre: MusicGenre
    let recommendedBpm: Double
    let sections: [SongStructureSection]

    init(
        id: String,
        name: String,
        description: String,
        iconName: String,
        genreTag: String,
        category: SongStructureCategory = .oneChorus,
        recommendedGenre: MusicGenre,
        recommendedBpm: Double,
        sections: [SongStructureSection]
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.genreTag = genreTag
        self.category = category
        self.recommendedGenre = recommendedGenre
        self.recommendedBpm = recommendedBpm
        self.sections = sections
    }

    /*
    構成全体の小節数の合計を返す。

    Arguments:
    なし

    Usage:
    楽曲構成選択カードの合計小節数バッジ表示で使用される。
    */

    var totalMeasures: Int {
        sections.reduce(0) { $0 + ($1.template.degrees.count * $1.repeatCount) }
    }

    // MARK: - プリセット一覧

    static let jpopOneChorus = SongStructureTemplate(
        id: "jpop_one_chorus",
        name: "J-POP 王道1コーラス",
        description: "Introからサビまで駆け抜ける、日本のポップス・アニソン定番の48小節構成",
        iconName: "crown.fill",
        genreTag: "1コーラス・16小節",
        category: .oneChorus,
        recommendedGenre: .pop,
        recommendedBpm: 128.0,
        sections: [
            SongStructureSection(type: .intro, template: .royalRoad, repeatCount: 1),
            SongStructureSection(type: .verseA, template: .popPunk, repeatCount: 2),
            SongStructureSection(type: .verseB, template: .justTheTwoOfUs, repeatCount: 2),
            SongStructureSection(type: .chorus, template: .fourFiveSix, repeatCount: 2)
        ]
    )

    static let jpopFullSong = SongStructureTemplate(
        id: "jpop_full_song",
        name: "J-POP ドラマチックフル構成",
        description: "Introからラスサビ・Outroまで感情が波のように高まる本格的な28小節の1曲構成",
        iconName: "sparkles",
        genreTag: "フル構成・28小節",
        category: .fullSong,
        recommendedGenre: .pop,
        recommendedBpm: 125.0,
        sections: [
            SongStructureSection(type: .intro, template: .canonShort, repeatCount: 1),
            SongStructureSection(type: .verseA, template: .komuro, repeatCount: 2),
            SongStructureSection(type: .verseB, template: .justTheTwoOfUs, repeatCount: 2),
            SongStructureSection(type: .chorus, template: .royalRoad, repeatCount: 2),
            SongStructureSection(type: .bridge, template: .twoFiveOne, repeatCount: 2),
            SongStructureSection(type: .chorus, template: .fourFiveSix, repeatCount: 2),
            SongStructureSection(type: .outro, template: .canonShort, repeatCount: 1)
        ]
    )

    static let neoSoulGroove = SongStructureTemplate(
        id: "neo_soul_groove",
        name: "Neo-Soul / Lo-Fi ジャム",
        description: "丸サ進行と2-5-1を基軸にした、都会的でおしゃれな16小節のグルーヴィー構成",
        iconName: "moon.stars.fill",
        genreTag: "Lo-Fi・16小節",
        category: .oneChorus,
        recommendedGenre: .lofi,
        recommendedBpm: 84.0,
        sections: [
            SongStructureSection(type: .intro, template: .justTheTwoOfUs, repeatCount: 1),
            SongStructureSection(type: .verseA, template: .justTheTwoOfUs, repeatCount: 2),
            SongStructureSection(type: .bridge, template: .twoFiveOne, repeatCount: 2),
            SongStructureSection(type: .outro, template: .justTheTwoOfUs, repeatCount: 1)
        ]
    )

    static let neoSoulFullSong = SongStructureTemplate(
        id: "neo_soul_full_song",
        name: "Neo-Soul / Lo-Fi フルジャーニー",
        description: "チルなIntroから丸サのA/Bメロ、ジャジーなCメロを経て心地よく展開する48小節構成",
        iconName: "headphones",
        genreTag: "フル構成・28小節",
        category: .fullSong,
        recommendedGenre: .lofi,
        recommendedBpm: 82.0,
        sections: [
            SongStructureSection(type: .intro, template: .justTheTwoOfUs, repeatCount: 1),
            SongStructureSection(type: .verseA, template: .justTheTwoOfUs, repeatCount: 2),
            SongStructureSection(type: .verseB, template: .twoFiveOne, repeatCount: 2),
            SongStructureSection(type: .chorus, template: .justTheTwoOfUs, repeatCount: 2),
            SongStructureSection(type: .bridge, template: .andalusia, repeatCount: 2),
            SongStructureSection(type: .chorus, template: .twoFiveOne, repeatCount: 2),
            SongStructureSection(type: .outro, template: .justTheTwoOfUs, repeatCount: 1)
        ]
    )

    static let rockAnthem = SongStructureTemplate(
        id: "rock_anthem",
        name: "Rock / Pop-Punk アンセム",
        description: "力強い疾走感とサビの爆発力を持つ、ロックやパンクに最適な48小節構成",
        iconName: "flame.fill",
        genreTag: "Rock・16小節",
        category: .oneChorus,
        recommendedGenre: .rock,
        recommendedBpm: 160.0,
        sections: [
            SongStructureSection(type: .intro, template: .popPunk, repeatCount: 1),
            SongStructureSection(type: .verseA, template: .popPunk, repeatCount: 2),
            SongStructureSection(type: .chorus, template: .fourFiveSix, repeatCount: 2),
            SongStructureSection(type: .outro, template: .popPunk, repeatCount: 1)
        ]
    )

    static let rockFullSong = SongStructureTemplate(
        id: "rock_full_song",
        name: "Rock エナジックフル構成",
        description: "激しいIntroから小室Aメロ、疾走サビ、泣きのギターソロCメロへと駆け抜ける48小節構成",
        iconName: "bolt.fill",
        genreTag: "フル構成・28小節",
        category: .fullSong,
        recommendedGenre: .rock,
        recommendedBpm: 155.0,
        sections: [
            SongStructureSection(type: .intro, template: .popPunk, repeatCount: 1),
            SongStructureSection(type: .verseA, template: .komuro, repeatCount: 2),
            SongStructureSection(type: .verseB, template: .fourFiveSix, repeatCount: 2),
            SongStructureSection(type: .chorus, template: .royalRoad, repeatCount: 2),
            SongStructureSection(type: .bridge, template: .popPunk, repeatCount: 2),
            SongStructureSection(type: .chorus, template: .fourFiveSix, repeatCount: 2),
            SongStructureSection(type: .outro, template: .popPunk, repeatCount: 1)
        ]
    )

    static let classicBallad = SongStructureTemplate(
        id: "classic_ballad",
        name: "50s オールディーズ / バラード",
        description: "スタンド・バイ・ミー進行を軸にした、時代を超えて愛されるレトロで心温まる48小節構成",
        iconName: "guitars.fill",
        genreTag: "バラード・16小節",
        category: .oneChorus,
        recommendedGenre: .pop,
        recommendedBpm: 116.0,
        sections: [
            SongStructureSection(type: .verseA, template: .standByMe, repeatCount: 2),
            SongStructureSection(type: .verseB, template: .standByMe, repeatCount: 2),
            SongStructureSection(type: .bridge, template: .royalRoad, repeatCount: 2),
            SongStructureSection(type: .outro, template: .standByMe, repeatCount: 1)
        ]
    )

    static let allStructures: [SongStructureTemplate] = [
        .jpopOneChorus,
        .jpopFullSong,
        .neoSoulGroove,
        .neoSoulFullSong,
        .rockAnthem,
        .rockFullSong,
        .classicBallad
    ]

    // MARK: - ランダム楽曲構成生成 (Smart Random Generator)

    /*
    指定されたカテゴリ（1コーラス または 1曲丸ごと）および基準ジャンルに基づき、
    音楽理論的に調和するコード進行テンプレートをランダムに組み合わせて楽曲構成を自動生成する。

    Arguments:
    category
      生成する規模感（1コーラス: 16小節、または 1曲丸ごと: 28小節）。
    baseGenre
      生成の基準とするジャンル。指定された場合はそのジャンルを尊重する。

    Usage:
    楽曲構成生成シートの「おまかせランダム生成」カードをタップした際に呼び出される。
    */

    static func generateRandom(category: SongStructureCategory, baseGenre: MusicGenre? = nil) -> SongStructureTemplate {
        let genre = baseGenre ?? MusicGenre.allCases.randomElement() ?? .pop
        let bpm = randomBpm(for: genre)

        let sections: [SongStructureSection]
        let totalBars: Int
        let title: String
        let desc: String

        switch category {
        case .oneChorus:
            sections = generateSectionsForOneChorus()
            totalBars = 16
            title = "\(genre.rawValue) ランダム 1コーラス"
            desc = "Introからサビまで、\(genre.rawValue)スタイルに調和するコード進行をランダムに組み立てた16小節"
        case .fullSong:
            sections = generateSectionsForFullSong()
            totalBars = 28
            title = "\(genre.rawValue) ランダム フル構成"
            desc = "A/BメロからCメロ・ラスサビまで、\(genre.rawValue)の起承転結をドラマチックに紡ぐ48小節構成"
        }

        return SongStructureTemplate(
            id: "random_\(UUID().uuidString.prefix(8))",
            name: title,
            description: desc,
            iconName: "dice.fill",
            genreTag: "ランダム・\(totalBars)小節",
            category: category,
            recommendedGenre: genre,
            recommendedBpm: bpm,
            sections: sections
        )
    }

    /*
    1コーラス（16小節）向けのセクション構成を音楽理論プールからランダム生成する。

    Arguments:
    なし

    Usage:
    generateRandom(category: .oneChorus) 内から呼び出される。
    */

    private static func generateSectionsForOneChorus() -> [SongStructureSection] {
        let introPool: [ProgressionTemplate] = [.royalRoad, .canonShort, .popPunk, .justTheTwoOfUs]
        let verseAPool: [ProgressionTemplate] = [.popPunk, .standByMe, .komuro, .canonShort]
        let verseBPool: [ProgressionTemplate] = [.justTheTwoOfUs, .fourFiveSix, .twoFiveOne]
        let chorusPool: [ProgressionTemplate] = [.fourFiveSix, .royalRoad, .komuro]

        let intro = introPool.randomElement() ?? .royalRoad
        let verseA = verseAPool.randomElement() ?? .popPunk
        let verseB = verseBPool.randomElement() ?? .justTheTwoOfUs
        let chorus = chorusPool.randomElement() ?? .fourFiveSix

        return [
            SongStructureSection(type: .intro, template: intro, repeatCount: 1),
            SongStructureSection(type: .verseA, template: verseA, repeatCount: 2),
            SongStructureSection(type: .verseB, template: verseB, repeatCount: 2),
            SongStructureSection(type: .chorus, template: chorus, repeatCount: 2)
        ]
    }

    /*
    1曲丸ごと（28小節）向けのセクション構成を音楽理論プールからランダム生成する。

    Arguments:
    なし

    Usage:
    generateRandom(category: .fullSong) 内から呼び出される。
    */

    private static func generateSectionsForFullSong() -> [SongStructureSection] {
        let introPool: [ProgressionTemplate] = [.canonShort, .royalRoad, .popPunk, .justTheTwoOfUs]
        let verseAPool: [ProgressionTemplate] = [.komuro, .popPunk, .standByMe, .canonShort]
        let verseBPool: [ProgressionTemplate] = [.justTheTwoOfUs, .fourFiveSix, .twoFiveOne]
        let chorusPool: [ProgressionTemplate] = [.royalRoad, .fourFiveSix, .komuro]
        let bridgePool: [ProgressionTemplate] = [.twoFiveOne, .justTheTwoOfUs, .andalusia, .royalRoad]
        let outroPool: [ProgressionTemplate] = [.canonShort, .royalRoad, .popPunk]

        let intro = introPool.randomElement() ?? .canonShort
        let verseA = verseAPool.randomElement() ?? .komuro
        let verseB = verseBPool.randomElement() ?? .justTheTwoOfUs
        let chorus1 = chorusPool.randomElement() ?? .royalRoad
        let bridge = bridgePool.randomElement() ?? .twoFiveOne
        let chorus2 = (chorusPool.filter { $0 != chorus1 }.randomElement()) ?? chorus1
        let outro = outroPool.randomElement() ?? .canonShort

        return [
            SongStructureSection(type: .intro, template: intro, repeatCount: 1),
            SongStructureSection(type: .verseA, template: verseA, repeatCount: 2),
            SongStructureSection(type: .verseB, template: verseB, repeatCount: 2),
            SongStructureSection(type: .chorus, template: chorus1, repeatCount: 2),
            SongStructureSection(type: .bridge, template: bridge, repeatCount: 2), // Cメロ
            SongStructureSection(type: .chorus, template: chorus2, repeatCount: 2),
            SongStructureSection(type: .outro, template: outro, repeatCount: 1)
        ]
    }

    /*
    ジャンルに応じた心地よい推奨BPMをランダムに算出する。

    Arguments:
    genre
      対象の音楽ジャンル。

    Usage:
    generateRandom() 内でBPMを決定する際に使用される。
    */

    private static func randomBpm(for genre: MusicGenre) -> Double {
        switch genre {
        case .pop:
            return Double(Int.random(in: 118...132))
        case .rock:
            return Double(Int.random(in: 145...165))
        case .dance:
            return Double(Int.random(in: 122...128))
        case .lofi:
            return Double(Int.random(in: 78...88))
        case .rAndB:
            return Double(Int.random(in: 88...102))
        }
    }
}
