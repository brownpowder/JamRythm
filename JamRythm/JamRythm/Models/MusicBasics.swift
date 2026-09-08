//
//  MusicBasics.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import Foundation

// MARK: - 調 (Key) 定義

/*
楽曲の基準となる調（Key）を表す列挙型。
メジャーキーの12音を網羅し、半音単位での計算をサポートする。
*/
enum Key: String, Codable, CaseIterable, Identifiable {
    case C = "C"
    case Db = "D♭"
    case D = "D"
    case Eb = "E♭"
    case E = "E"
    case F = "F"
    case Gb = "G♭"
    case G = "G"
    case Ab = "A♭"
    case A = "A"
    case Bb = "B♭"
    case B = "B"

    var id: String { rawValue }

    /*
    Keyに対応する半音インデックス（Cを0とする0〜11）を返す。
    
    Arguments:
    なし
    
    Usage:
    度数計算やMIDIノート番号のオフセット算出に利用される。
    */
    
    var semitoneOffset: Int {
        switch self {
        case .C: return 0
        case .Db: return 1
        case .D: return 2
        case .Eb: return 3
        case .E: return 4
        case .F: return 5
        case .Gb: return 6
        case .G: return 7
        case .Ab: return 8
        case .A: return 9
        case .Bb: return 10
        case .B: return 11
        }
    }

    /*
    メジャーダイアトニックスケールの各度数（1〜7）における半音オフセットを返す。
    
    Arguments:
    degree
      1〜7の度数（ディグリー）。王道進行テンプレート等から渡される。
    
    Usage:
    Keyの基準音にこのオフセットを加算することで、指定度数のベース音やコードルートを特定する。
    */
    
    static func semitonesForMajorDegree(_ degree: Int) -> Int {
        let diatonicSemitones = [0, 2, 4, 5, 7, 9, 11]
        let normalizedIndex = (degree - 1) % diatonicSemitones.count
        return diatonicSemitones[normalizedIndex >= 0 ? normalizedIndex : 0]
    }

    /*
    半音インデックス（0〜11）から対応する音名文字列（フラット表記）を返す。
    
    Arguments:
    semitone
      0〜11の半音番号。計算結果から渡される。
    
    Usage:
    ベース音の音名やコードのルート音名を生成する際に使用される。
    */
    
    static func noteName(forSemitone semitone: Int) -> String {
        let noteNames = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]
        let normalized = ((semitone % 12) + 12) % 12
        return noteNames[normalized]
    }
}

// MARK: - 感情・役割ラベル (ChordFlavor)

/*
コードの持つ音楽的な役割や感情のニュアンスを表す列挙型。
ユーザーが直感的にコード進行を選べるよう、音楽理論用語ではなく感覚的なラベルを提供する。
*/
enum ChordFlavor: String, Codable, CaseIterable, Identifiable {
    case stable = "安定"
    case melancholy = "少し切ない"
    case stylish = "おしゃれ"
    case tension = "緊張感"

    var id: String { rawValue }

    var englishDescription: String {
        switch self {
        case .stable: return "Stable"
        case .melancholy: return "Melancholy"
        case .stylish: return "Stylish"
        case .tension: return "Tension"
        }
    }
}

// MARK: - コード構造体 (Chord)

/*
コード（和音）の情報を保持する構造体。
ルート音、コード種別、分数コード用のベース音を保持し、表示用文字列を生成する。
*/
struct Chord: Codable, Equatable, Hashable {
    let rootNote: String
    let type: String
    let bassNote: String?

    /*
    画面表示用のフォーマット済みコード文字列（例: "G", "Em7/G", "D♭7"）を返す。
    
    Arguments:
    なし
    
    Usage:
    UIの特大コード表示や候補ボタンのラベルとして直接描画される。
    */
    
    var displayString: String {
        if let bass = bassNote, !bass.isEmpty, bass != rootNote {
            return "\(rootNote)\(type)/\(bass)"
        }
        return "\(rootNote)\(type)"
    }
}
