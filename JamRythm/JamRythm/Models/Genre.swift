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
enum MusicGenre: String, CaseIterable, Identifiable, Codable {
    case pop = "Pop"
    case rock = "Rock"
    case dance = "Dance"
    case lofi = "Lo-Fi"
    case rAndB = "R&B"

    var id: String { rawValue }
    var isPremiumOnly: Bool {
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
            return "Pop (8-Beat)"
        case .rock:
            return "Rock (Drive)"
        case .dance:
            return "Dance (4-Floor)"
        case .lofi:
            return "Lo-Fi (Chill)"
        case .rAndB:
            return "R&B (Groove)"
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
            return "music.note"
        case .rock:
            return "bolt.horizontal.fill"
        case .dance:
            return "sparkles"
        case .lofi:
            return "moon.stars.fill"
        case .rAndB:
            return "waveform"
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
            return "定番の8ビートと安定感のあるベースライン"
        case .rock:
            return "パワフルなドラムと疾走感ある8分音符ルート連打ベース"
        case .dance:
            return "四つ打ちキックと裏拍オープンハット、オクターブベース"
        case .lofi:
            return "レイドバックしたハーフタイムビートと落ち着いた重低音ベース"
        case .rAndB:
            return "シンコペーションを効かせた都会的でファンキーなグルーヴ"
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
        case .lofi, .rAndB: return .leo
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
