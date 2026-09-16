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
    case acoustic = 33
    case pizzicato = 34
    case dub = 35
    case synthSaw = 36
    case synthSine = 37
    case synthSquare = 38
    case synthTriangle = 39
    

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


// MARK: - ピアノ・バッキング音色プリセット

enum PianoInstrument: UInt8, CaseIterable, Identifiable {
    case piano = 0
    case ePiano1 = 1
    case ePiano2 = 2
    
    var id: UInt8 { rawValue }

    var displayName: String {
        switch self {
        case .piano: return "Grand Piano"
        case .ePiano1: return "E-Piano 1"
        case .ePiano2: return "E-Piano 2"
                }
    }

    var iconName: String {
        switch self {
        case .piano, .ePiano1, .ePiano2: return "pianokeys"
                }
    }
}

// MARK: - Lead音色プリセット

enum LeadInstrument: UInt8, CaseIterable, Identifiable {
    case guitar = 25
    case piano = 0
    
    var id: UInt8 { rawValue }

    var displayName: String {
        switch self {
        case .guitar: return "Guitar"
        case .piano: return "Grand Piano"
            }
    }

    var iconName: String {
        switch self {
        case .guitar: return "guitars.fill"
        case .piano: return "pianokeys"
        }
    }
}
