//
//  Genre.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/09.
//

import Foundation

// MARK: - 音楽ジャンル定義

/*
伴奏スタイルを決定する音楽ジャンルを表す列挙型。
各ジャンルごとにドラムパターンとベースラインの自動演奏スタイルを規定する。
*/
enum MusicGenre: String, CaseIterable, Identifiable, Codable, PremiumLockable {
    case pop = "Pop"
    case rock = "Rock"
    case dance = "Dance"
    case lofi = "Lo-Fi"
    case rAndB = "R&B"

    var id: String { rawValue }
    var isLocked: Bool {
        print("DEBUG Genre.isLocked evaluated for \(self). isPremiumOnly=\(isPremiumOnly)")
        return isPremiumOnly
    }

    var isPremiumOnly: Bool {
        if StoreManager.shared.isUnlocked { return false }
        
        switch self {
        case .lofi, .rAndB: return true
        default: return false
        }
    }

    /*
    ユーザー向けに表示するジャンル名を返す。

    Arguments:
    なし

    Usage:
    ヘッダーのジャンル選択メニューや設定表示で使用される。
    */

    var displayName: String {
        switch self {
        case .pop:
            return NSLocalizedString("Pop (8-Beat)", comment: "")
        case .rock:
            return NSLocalizedString("Rock (Drive)", comment: "")
        case .dance:
            return NSLocalizedString("Dance (4-Floor)", comment: "")
        case .lofi:
            return NSLocalizedString("Lo-Fi (Chill)", comment: "")
        case .rAndB:
            return NSLocalizedString("R&B (Groove)", comment: "")
        }
    }

    /*
    ヘッダーやボタン用の短縮表示名を返す。

    Arguments:
    なし

    Usage:
    ヘッダーのコンパクトなボタントップ表示で使用される。
    */

    var shortName: String {
        return rawValue
    }

    /*
    ジャンルを表すSF Symbolアイコン名を返す。

    Arguments:
    なし

    Usage:
    ジャンル選択メニューの各項目に添えるアイコンとして使用される。
    */

    var iconName: String {
        switch self {
        case .pop:
            return NSLocalizedString("music.note", comment: "")
        case .rock:
            return NSLocalizedString("bolt.horizontal.fill", comment: "")
        case .dance:
            return NSLocalizedString("sparkles", comment: "")
        case .lofi:
            return NSLocalizedString("moon.stars.fill", comment: "")
        case .rAndB:
            return NSLocalizedString("waveform", comment: "")
        }
    }

    /*
    ジャンルの音楽的特徴を説明する簡潔なテキストを返す。

    Arguments:
    なし

    Usage:
    将来的なツールチップや詳細ガイドで使用される。
    */

    var styleDescription: String {
        switch self {
        case .pop:
            return NSLocalizedString("定番の8ビートと安定感のあるベースライン", comment: "")
        case .rock:
            return NSLocalizedString("パワフルなドラムと疾走感ある8分音符ルート連打ベース", comment: "")
        case .dance:
            return NSLocalizedString("四つ打ちキックと裏拍オープンハット、オクターブベース", comment: "")
        case .lofi:
            return NSLocalizedString("レイドバックしたハーフタイムビートと落ち着いた重低音ベース", comment: "")
        case .rAndB:
            return NSLocalizedString("シンコペーションを効かせた都会的でファンキーなグルーヴ", comment: "")
        }
    }

    /*
    ジャンルに最適化されたデフォルトのドラム音色プリセットを返す。

    Arguments:
    なし

    Usage:
    ジャンル切り替え時にドラム音色を自動設定するために使用される。
    */

    var defaultDrumInstrument: DrumInstrument {
        switch self {
        case .pop, .rock:
            return .acoustic
        case .dance, .rAndB:
            return .electronic
        case .lofi:
            return .dub
        }
    }

    /*
    ジャンルに最適化されたデフォルトのベース音色プリセットを返す。

    Arguments:
    なし

    Usage:
    ジャンル切り替え時にベース音色を自動設定するために使用される。
    */

    var defaultBassInstrument: BassInstrument {
        switch self {
        case .pop, .lofi:
            return .dub
        case .rock:
            return .acoustic
        case .dance:
            return .synthSaw
        case .rAndB:
            return .synthSine
        }
    }
    
    // MARK: - 推奨プレイヤー
    
    var recommendedDrumPlayer: DrumPlayer {
        switch self {
        case .pop, .dance: return .standard
        case .rock: return .mark
        case .lofi: return .sara
        case .rAndB: return .leo
        }
    }
    
    var recommendedBassPlayer: BassPlayer {
        switch self {
        case .pop, .dance: return .standard
        case .rock: return .kr
        case .lofi, .rAndB: return .akiko
        }
    }
    
    var recommendedPianoPlayer: PianoPlayer {
        switch self {
        case .pop, .rock, .dance: return .emi
        case .lofi, .rAndB: return .jazzCat
        }
    }
    

    var defaultPianoInstrument: PianoInstrument {
        switch self {
        case .pop: return .piano
        case .rock: return .piano
        case .dance: return .ePiano1
        case .lofi: return .ePiano2
        case .rAndB: return .ePiano1
        }
    }

    var defaultTempo: Double {
        switch self {
        case .pop: return 120.0
        case .rock: return 140.0
        case .dance: return 128.0
        case .lofi: return 85.0
        case .rAndB: return 95.0
        }
    }
}
