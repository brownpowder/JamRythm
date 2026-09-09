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

// MARK: - 代理コード候補モデル (SubstituteCandidate)

/*
楽曲理論に基づく代理コード（トニック代理、サブドミナント代理、裏コード等）の候補を表す構造体。
理論的な役割ラベルと具体的なコード情報を保持する。
*/
struct SubstituteCandidate: Codable, Identifiable, Equatable {
    let id: UUID
    let label: String
    let chord: Chord

    init(id: UUID = UUID(), label: String, chord: Chord) {
        self.id = id
        self.label = label
        self.chord = chord
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

// MARK: - ギター運指モデル (GuitarVoicing)

/*
ギターの押弦位置（ボイシング）を表す構造体。
6弦から1弦までのフレット番号を保持する。
nilはミュート（弾かない）、0は開放弦、1以上はフレット番号を表す。
*/
struct GuitarVoicing: Equatable, Hashable {
    /// 6弦, 5弦, 4弦, 3弦, 2弦, 1弦の順のフレット指定
    let frets: [Int?]

    /*
    指定された弦（6〜1弦）のフレット情報を取得する。
    
    Arguments:
    stringNumber
      1〜6の弦番号（1弦が最高音、6弦が最低音）。
    
    Usage:
    TAB譜の描画ループ内で各弦のフレット値を取得するために呼び出される。
    */
    
    func fret(forString stringNumber: Int) -> Int? {
        guard stringNumber >= 1 && stringNumber <= 6 else { return nil }
        let index = 6 - stringNumber
        guard index < frets.count else { return nil }
        return frets[index]
    }
}

// MARK: - 五線譜音符モデル (StaffNote)

/*
五線譜上に配置される音符情報を表す構造体。
ト音記号の第1線（E4）を0基準とする相対ステップ値と、表示用音名を保持する。
*/
struct StaffNote: Identifiable, Equatable, Hashable {
    let id: UUID
    let name: String
    let accidental: String?
    let step: Int

    init(id: UUID = UUID(), name: String, accidental: String? = nil, step: Int) {
        self.id = id
        self.name = name
        self.accidental = accidental
        self.step = step
    }
}

