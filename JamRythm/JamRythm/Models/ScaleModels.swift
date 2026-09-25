//
//  MusicTheoryService.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import Foundation

// MARK: - スケール種別

/*
アドリブやメロディ演奏で使用するスケール種別（ペンタトニックまたはダイアトニック）。
*/
enum ScaleType: String, Codable, CaseIterable, Identifiable {
    case pentatonic = "ペンタトニック"
    case diatonic = "ダイアトニック"
    case harmonicMinor = "ハーモニックマイナー"
    case melodicMinor = "メロディックマイナー"
    case ryukyu = "琉球音階"
    case japanese = "ヨナ抜きマイナー"

    var isLocked: Bool {
        return isPremiumOnly
    }

    var isPremiumOnly: Bool {
        if StoreManager.shared.isUnlocked { return false }
        
        switch self {
        case .harmonicMinor, .ryukyu, .japanese: return true
        default: return false
        }
    }

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .pentatonic: return "Penta (5音)"
        case .diatonic: return "Diatonic (7音)"
        case .harmonicMinor: return "Harmonic Minor"
        case .melodicMinor: return "Melodic Minor"
        case .ryukyu: return "Ryukyu (5音)"
        case .japanese: return "Yonanuki Minor"
        }
    }
}

// MARK: - スケール基準モード

/*
スケール指板で表示するスケールの基準（曲のKey基準、または現在小節のChord基準）。
*/
enum ScaleReferenceMode: String, Codable, CaseIterable, Identifiable {
    case chord = "Chord基準"
    case key = "Key基準"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .chord: return "Chord基準"
        case .key: return "Key基準"
        }
    }
}

// MARK: - 指板楽器モード

/*
指板ダイアグラムで表示する弦の本数（6弦ギターまたは4弦ベース）。
*/
enum ScaleInstrument: String, Codable, CaseIterable, Identifiable {
    case guitar = "6弦 (Guitar)"
    case piano = "鍵盤 (Piano)"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .guitar: return "Guitar"
        case .piano: return "Piano"
        }
    }
}

// MARK: - スケール音の役割

/*
指板上の音が現在のコード進行において果たす音楽的役割。
*/
enum ScaleToneRole: Equatable {
    case root         // 現在のコードの根音（最重要、オレンジ）
    case chordTone     // コードの構成音（3度、5度など、シアン）
    case scaleTone     // スケール内の通過音（白/グレー）
}

// MARK: - 指板上のスケール音ポジション

/*
ギター/ベース指板上の特定の弦・フレットにおけるスケール音の配置情報。
*/
struct ScaleFretPosition: Identifiable, Equatable {
    let id: UUID
    let stringNumber: Int    // ギター基準: 1〜6弦（6弦=低音E, 1弦=高音E）
    let fret: Int            // 0〜5フレット
    let noteName: String     // 音名（例: "C", "G"）
    let role: ScaleToneRole  // 音の役割（ルート、コードトーン、スケール音）

    init(id: UUID = UUID(), stringNumber: Int, fret: Int, noteName: String, role: ScaleToneRole) {
        self.id = id
        self.stringNumber = stringNumber
        self.fret = fret
        self.noteName = noteName
        self.role = role
    }
}

// MARK: - 和声的親和性・スムーズ度 (HarmonicCompatibility)

/*
楽曲のKeyおよび元のコード進行に対して、指定されたコードやルート音がどの程度破綻せずスムーズに調和するかを表す評価指標。
濃淡による視覚的ガイド表示に利用される。
*/
enum NoteNameNotation: String, CaseIterable, Identifiable {
    case english = "CDE"
    case japanese = "ドレミ"

    var id: String { rawValue }
}

extension NoteNameNotation {
    /*
    音名文字列（例: "C", "G♭", "F♯"）を指定された表記法（英語/日本語）に変換する。

    Arguments:
    noteName
      変換元の音名文字列（"C", "G♭", "A" など）。
    notation
      変換先の表記法（.english または .japanese）。

    Usage:
    五線譜、Tab譜、スケール指板の音名バッジ表示で呼び出される。
    */

    static func localizedNoteName(_ noteName: String, notation: NoteNameNotation) -> String {
        guard notation == .japanese else { return noteName }

        let mapping: [Character: String] = [
            "C": "ド",
            "D": "レ",
            "E": "ミ",
            "F": "ファ",
            "G": "ソ",
            "A": "ラ",
            "B": "シ"
        ]

        var result = ""
        for char in noteName {
            if let jp = mapping[char] {
                result += jp
            } else {
                result.append(char)
            }
        }
        return result
    }

    /*
    現在の端末言語設定が日本語であるかを判定する。

    Arguments:
    なし

    Usage:
    音名の「ドレミ」切替タップを日本語環境限定で有効化するために使用される。
    */

    static var isJapaneseLanguage: Bool {
        if let preferred = Locale.preferredLanguages.first {
            return preferred.hasPrefix("ja")
        }
        return Locale.current.language.languageCode?.identifier == "ja"
    }
}

// MARK: - スケール情報モデル

/*
現在のKeyとコードに応じたスケール構成音および指板ポジションの集合体。
*/
struct ScaleInfo: Equatable {
    let keyName: String
    let scaleName: String
    let scaleNotes: [String]
    let positions: [ScaleFretPosition]
}

// MARK: - 音楽理論サービス・プロトコル

/*
Keyと度数（ベース音）に基づき、音楽的なコード候補を算出するインターフェース。
テスタビリティと差し替え容易性を確保するためProtocolで定義する。
*/
