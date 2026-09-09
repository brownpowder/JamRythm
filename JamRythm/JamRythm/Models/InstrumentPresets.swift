//
//  InstrumentPresets.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/09.
//

import Foundation

// MARK: - ドラム音色プリセット

/*
JamRythm.sf2（Bank 128）に収録されているドラム音色プリセットを表す列挙型。
プログラム番号に対応し、表示名を提供する。
*/
enum DrumInstrument: UInt8, CaseIterable, Identifiable {
    case acoustic = 0
    case electronic = 1
    case dub = 2

    var id: UInt8 { rawValue }

    /*
    ユーザー向けに表示する音色プリセット名を返す。

    Arguments:
    なし

    Usage:
    ミキサー画面の音色選択Picker等で使用される。
    */

    var displayName: String {
        switch self {
        case .acoustic:
            return "Acoustic"
        case .electronic:
            return "Electronic"
        case .dub:
            return "Lo-Fi Dub"
        }
    }

    /*
    音色を表すSF Symbolアイコン名を返す。

    Arguments:
    なし

    Usage:
    トラックヘッダーやボタンに添えるアイコンとして使用される。
    */

    var iconName: String {
        switch self {
        case .acoustic:
            return "music.note"
        case .electronic:
            return "bolt.fill"
        case .dub:
            return "waveform"
        }
    }
}

// MARK: - ベース音色プリセット

/*
JamRythm.sf2（Bank 000）に収録されているベース音色プリセットを表す列挙型。
プログラム番号に対応し、表示名を提供する。
*/
enum BassInstrument: UInt8, CaseIterable, Identifiable {
    case acoustic = 0
    case dub = 1
    case synthSaw = 2
    case synthSine = 3
    case synthSquare = 4
    case synthTriangle = 5
    case pizzicato = 6

    var id: UInt8 { rawValue }

    /*
    ユーザー向けに表示する音色プリセット名を返す。

    Arguments:
    なし

    Usage:
    ミキサー画面の音色選択Picker等で使用される。
    */

    var displayName: String {
        switch self {
        case .acoustic:
            return "Acoustic"
        case .dub:
            return "Dub Sub"
        case .synthSaw:
            return "Synth Saw"
        case .synthSine:
            return "Synth Sine"
        case .synthSquare:
            return "Synth Square"
        case .synthTriangle:
            return "Synth Triangle"
        case .pizzicato:
            return "Pizzicato"
        }
    }

    /*
    音色を表すSF Symbolアイコン名を返す。

    Arguments:
    なし

    Usage:
    トラックヘッダーやボタンに添えるアイコンとして使用される。
    */

    var iconName: String {
        switch self {
        case .acoustic, .pizzicato:
            return "guitars.fill"
        case .dub, .synthSaw, .synthSine, .synthSquare, .synthTriangle:
            return "waveform.path"
        }
    }
}
