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

extension MusicTheoryService {
    /*
    指定されたコードに対する複数のギター運指（ボイシング候補）を返す。
    ローコード、5弦ルート、6弦ルート等のバリエーションを網羅し、各ボイシングのbaseFretも設定する。

    Arguments:
    chord
      押弦ポジションを算出するChordオブジェクト。

    Usage:
    GuitarTabViewでポジション切り替えを行うために呼び出される。
    */

    func guitarVoicings(for chord: Chord) -> [GuitarVoicing] {
        var results: [GuitarVoicing] = []

        // 1. 特殊オンコードがある場合
        if let onChord = specialOnChordVoicing(for: chord) {
            var v = onChord
            v.positionName = "分数コード"
            v.baseFret = calculateBaseFret(for: v.frets)
            results.append(v)
        }

        let code = "\(chord.rootNote)\(chord.type)"

        // 2. オープンコード（ローコード）がある場合
        if let openForm = extendedOpenVoicingTable[code] {
            var v = openForm
            v.positionName = "ローコード"
            v.baseFret = calculateBaseFret(for: v.frets)
            if !results.contains(where: { $0.frets == v.frets }) {
                results.append(v)
            }
        }

        // 3. 5弦ルートバレーフォーム (Aフォーム系)
        let rSemi = Key.semitone(forNoteName: chord.rootNote)
        let f5 = (rSemi - 9 + 12) % 12
        var v5 = barreVoicingString5(fret: f5, type: chord.type)
        v5.positionName = "5弦ルート (\(f5)f)"
        v5.baseFret = calculateBaseFret(for: v5.frets)
        if !results.contains(where: { $0.frets == v5.frets }) {
            results.append(v5)
        }

        // 4. 6弦ルートバレーフォーム (Eフォーム系)
        let f6 = (rSemi - 4 + 12) % 12
        var v6 = barreVoicingString6(fret: f6, type: chord.type)
        v6.positionName = "6弦ルート (\(f6)f)"
        v6.baseFret = calculateBaseFret(for: v6.frets)
        if !results.contains(where: { $0.frets == v6.frets }) {
            results.append(v6)
        }

        // 何もなければフォールバック
        if results.isEmpty {
            var fb = fallbackVoicing(for: chord.rootNote)
            fb.positionName = "基本"
            fb.baseFret = 1
            results.append(fb)
        }

        return results
    }

    /*
    後方互換用: 先頭の代表的なギター運指（ボイシング）を返す。
    */

    func guitarVoicing(for chord: Chord) -> GuitarVoicing {
        return guitarVoicings(for: chord).first ?? fallbackVoicing(for: chord.rootNote)
    }

    /*
    押弦フレット配列から、ダイアグラム描画時の基準開始フレット（baseFret）を算出する。
    1〜2フレットを含む場合はナット基準（1）、ハイポジションの場合は最小フレット値を返す。
    */

    func calculateBaseFret(for frets: [Int?]) -> Int {
        let nonZeroFrets = frets.compactMap { $0 }.filter { $0 > 0 }
        guard let minFret = nonZeroFrets.min() else { return 1 }
        if minFret <= 2 { return 1 }
        return minFret
    }

    /*
    分数コード（オンコード）に対する代表的ボイシングを判定して返す。
    
    Arguments:
    chord
      対象のコード。
    
    Usage:
    guitarVoicing内で優先判定として使用される。
    */
    
    func specialOnChordVoicing(for chord: Chord) -> GuitarVoicing? {
        guard let bass = chord.bassNote, !bass.isEmpty && bass != chord.rootNote else {
            return nil
        }

        // 定番分数コードの優先パターン
        if chord.rootNote == "F" && bass == "G" {
            return GuitarVoicing(frets: [3, nil, 3, 2, 1, nil]) // F/G
        }
        if chord.rootNote == "C" && bass == "E" {
            return GuitarVoicing(frets: [0, 3, 2, 0, 1, 0]) // C/E
        }
        if chord.rootNote == "C" && bass == "G" {
            return GuitarVoicing(frets: [3, 3, 2, 0, 1, 0]) // C/G
        }
        if chord.rootNote == "G" && bass == "B" {
            return GuitarVoicing(frets: [nil, 2, 0, 0, 0, 3]) // G/B
        }
        if chord.rootNote == "D" && (bass == "F#" || bass == "G♭") {
            return GuitarVoicing(frets: [2, 0, 0, 2, 3, 2]) // D/F#
        }
        if chord.rootNote == "A" && chord.type == "m" && bass == "G" {
            return GuitarVoicing(frets: [3, 0, 2, 2, 1, 0]) // Am/G
        }
        if chord.rootNote == "D" && chord.type == "m" && bass == "C" {
            return GuitarVoicing(frets: [nil, 3, 0, 2, 3, 1]) // Dm/C
        }
        if chord.rootNote == "E" && chord.type == "m7" && bass == "G" {
            return GuitarVoicing(frets: [3, 2, 0, 0, 0, 0]) // Em7/G
        }
        if chord.rootNote == "D" && chord.type.contains("9") && bass == "G" {
            return GuitarVoicing(frets: [3, nil, 0, 2, 1, 0]) // Dm9/G
        }
        if (chord.rootNote == "D♭" || chord.rootNote == "C#") && chord.type == "7" && bass == "G" {
            return GuitarVoicing(frets: [3, 4, 3, 4, 2, nil]) // D♭7/G
        }

        // 一般オンコード: ベース音が6弦または5弦で押さえられるよう合成
        let bSemi = Key.semitone(forNoteName: bass)
        let f6 = (bSemi - 4 + 12) % 12
        if f6 <= 5 {
            return GuitarVoicing(frets: [f6, nil, nil, nil, nil, nil])
        }
        let f5 = (bSemi - 9 + 12) % 12
        return GuitarVoicing(frets: [nil, f5, nil, nil, nil, nil])
    }

    /*
    CAGEDバレーコードシステムに基づき、1〜8フレットの押さえやすい可変フォームを動的生成する。
    5弦ルート（Aフォーム系）と6弦ルート（Eフォーム系）を最適なフレット位置で選択する。

    Arguments:
    chord
      対象のコード。

    Usage:
    オープンコード辞書にないコードのボイシング生成に使用される。
    */

    func barreVoicing(for chord: Chord) -> GuitarVoicing? {
        let rSemi = Key.semitone(forNoteName: chord.rootNote)
        let f5 = (rSemi - 9 + 12) % 12 // 5弦ルートフレット
        let f6 = (rSemi - 4 + 12) % 12 // 6弦ルートフレット

        // C, C#, D, D#, E系（f5 <= 7）は5弦ルートフォームを優先
        let prefer5 = (f5 >= 1 && f5 <= 7) && (f6 > 7 || f5 <= f6)
        if prefer5 {
            return barreVoicingString5(fret: f5, type: chord.type)
        } else {
            return barreVoicingString6(fret: f6, type: chord.type)
        }
    }

    /*
    5弦ルート（Aフォーム系）のバレーコードボイシングを生成する。

    Arguments:
    fret
      5弦のルートフレット（1〜11）。
    type
      コード種別文字列。

    Usage:
    barreVoicing内部で使用される。
    */

    func barreVoicingString5(fret f: Int, type: String) -> GuitarVoicing {
        let t = type.lowercased()
        if t.contains("7(#9)") || t.contains("7#9") {
            return GuitarVoicing(frets: [nil, f, max(0, f - 1), f, f + 1, nil]) // ジミヘンコード
        } else if t.contains("7(b9)") || t.contains("7b9") {
            return GuitarVoicing(frets: [nil, f, max(0, f - 1), f, max(0, f - 1), nil])
        } else if t.contains("7(#11)") || t.contains("7#11") {
            return GuitarVoicing(frets: [nil, f, max(0, f - 1), f, f + 2, nil])
        } else if t.contains("maj9") {
            return GuitarVoicing(frets: [nil, f, max(0, f - 1), f + 1, f, nil])
        } else if t.contains("m9") {
            return GuitarVoicing(frets: [nil, f, max(0, f - 1), f, max(0, f - 2), nil])
        } else if t.contains("9") {
            return GuitarVoicing(frets: [nil, f, max(0, f - 1), f, f, nil]) // ファンク9th
        } else if t.contains("13") {
            return GuitarVoicing(frets: [nil, f, f, f + 2, f + 2, nil])
        } else if t.contains("11") {
            return GuitarVoicing(frets: [nil, f, f, f, f, f])
        } else if t.contains("maj7") {
            return GuitarVoicing(frets: [nil, f, f + 2, f + 1, f + 2, f])
        } else if t.contains("m7b5") || t.contains("dim7") || t.contains("dim") {
            return GuitarVoicing(frets: [nil, f, f + 1, max(0, f - 1), f + 1, nil])
        } else if t.contains("7sus4") {
            return GuitarVoicing(frets: [nil, f, f + 2, f, f + 3, f])
        } else if t.contains("sus4") {
            return GuitarVoicing(frets: [nil, f, f + 2, f + 2, f + 3, f])
        } else if t.contains("m7") {
            return GuitarVoicing(frets: [nil, f, f + 2, f, f + 1, f])
        } else if t.contains("7") {
            return GuitarVoicing(frets: [nil, f, f + 2, f, f + 2, f])
        } else if t.contains("add9") {
            return GuitarVoicing(frets: [nil, f, f + 2, f + 2, f, f + 2])
        } else if t.contains("m6") || t.contains("mm7") {
            return GuitarVoicing(frets: [nil, f, f + 2, f + 1, f + 1, f])
        } else if t.contains("6") {
            return GuitarVoicing(frets: [nil, f, f + 2, f + 2, f + 2, f + 2])
        } else if t.contains("aug") {
            return GuitarVoicing(frets: [nil, f, f + 2, f + 2, f + 2, nil])
        } else if t.contains("m") {
            return GuitarVoicing(frets: [nil, f, f + 2, f + 2, f + 1, f])
        } else {
            return GuitarVoicing(frets: [nil, f, f + 2, f + 2, f + 2, f]) // Major
        }
    }

    /*
    6弦ルート（Eフォーム系）のバレーコードボイシングを生成する。

    Arguments:
    fret
      6弦のルートフレット（1〜11）。
    type
      コード種別文字列。

    Usage:
    barreVoicing内部で使用される。
    */

    func barreVoicingString6(fret f: Int, type: String) -> GuitarVoicing {
        let t = type.lowercased()
        if t.contains("13") {
            return GuitarVoicing(frets: [f, nil, f, f + 1, f + 2, nil]) // ジャズ13th
        } else if t.contains("7(#9)") || t.contains("7#9") {
            return GuitarVoicing(frets: [f, max(0, f - 1), f, f, nil, nil])
        } else if t.contains("maj7") {
            return GuitarVoicing(frets: [f, f + 2, f + 1, f + 1, f, f])
        } else if t.contains("m7b5") || t.contains("dim7") || t.contains("dim") {
            return GuitarVoicing(frets: [f, nil, max(0, f - 1), f, max(0, f - 1), nil])
        } else if t.contains("7sus4") {
            return GuitarVoicing(frets: [f, f + 2, f, f + 2, f, f])
        } else if t.contains("sus4") {
            return GuitarVoicing(frets: [f, f + 2, f + 2, f + 2, f, f])
        } else if t.contains("m7") {
            return GuitarVoicing(frets: [f, f + 2, f, f, f, f])
        } else if t.contains("7") {
            return GuitarVoicing(frets: [f, f + 2, f, f + 1, f, f])
        } else if t.contains("m") {
            return GuitarVoicing(frets: [f, f + 2, f + 2, f, f, f])
        } else {
            return GuitarVoicing(frets: [f, f + 2, f + 2, f + 1, f, f]) // Major
        }
    }

    /*
    代表的な標準オープンコード（ローコード）フォームのテーブル。
    開放弦の響きを活かした美しく押さえやすい運指を網羅する。
    */
    private var extendedOpenVoicingTable: [String: GuitarVoicing] {
        [
            // C系
            "C": GuitarVoicing(frets: [nil, 3, 2, 0, 1, 0]),
            "Cmaj7": GuitarVoicing(frets: [nil, 3, 2, 0, 0, 0]),
            "C7": GuitarVoicing(frets: [nil, 3, 2, 3, 1, 0]),
            "Cadd9": GuitarVoicing(frets: [nil, 3, 2, 0, 3, 0]),
            "Csus4": GuitarVoicing(frets: [nil, 3, 3, 0, 1, 1]),
            "C6": GuitarVoicing(frets: [nil, 3, 2, 2, 1, 0]),
            "Cm7": GuitarVoicing(frets: [nil, 3, 5, 3, 4, 3]),
            "Cm": GuitarVoicing(frets: [nil, 3, 5, 5, 4, 3]),
            "Caug": GuitarVoicing(frets: [nil, 3, 2, 1, 1, 0]),

            // D系
            "D": GuitarVoicing(frets: [nil, nil, 0, 2, 3, 2]),
            "Dm": GuitarVoicing(frets: [nil, nil, 0, 2, 3, 1]),
            "D7": GuitarVoicing(frets: [nil, nil, 0, 2, 1, 2]),
            "Dmaj7": GuitarVoicing(frets: [nil, nil, 0, 2, 2, 2]),
            "Dm7": GuitarVoicing(frets: [nil, nil, 0, 2, 1, 1]),
            "Dsus4": GuitarVoicing(frets: [nil, nil, 0, 2, 3, 3]),
            "D7sus4": GuitarVoicing(frets: [nil, nil, 0, 2, 1, 3]),
            "Dadd9": GuitarVoicing(frets: [nil, nil, 0, 2, 3, 0]),
            "Dm9": GuitarVoicing(frets: [nil, 5, 3, 5, 5, nil]),

            // E系
            "E": GuitarVoicing(frets: [0, 2, 2, 1, 0, 0]),
            "Em": GuitarVoicing(frets: [0, 2, 2, 0, 0, 0]),
            "E7": GuitarVoicing(frets: [0, 2, 0, 1, 0, 0]),
            "Emaj7": GuitarVoicing(frets: [0, 2, 1, 1, 0, 0]),
            "Em7": GuitarVoicing(frets: [0, 2, 0, 0, 0, 0]),
            "Esus4": GuitarVoicing(frets: [0, 2, 2, 2, 0, 0]),
            "E7sus4": GuitarVoicing(frets: [0, 2, 0, 2, 0, 0]),
            "E7(#9)": GuitarVoicing(frets: [nil, 7, 6, 7, 8, nil]),
            "Edim7": GuitarVoicing(frets: [nil, nil, 2, 3, 2, 3]),

            // F系
            "F": GuitarVoicing(frets: [1, 3, 3, 2, 1, 1]),
            "Fm": GuitarVoicing(frets: [1, 3, 3, 1, 1, 1]),
            "Fmaj7": GuitarVoicing(frets: [nil, nil, 3, 2, 1, 0]),
            "Fm7": GuitarVoicing(frets: [1, 3, 1, 1, 1, 1]),
            "F7": GuitarVoicing(frets: [1, 3, 1, 2, 1, 1]),
            "Fmaj9": GuitarVoicing(frets: [nil, nil, 3, 0, 1, 0]),
            "F#m7b5": GuitarVoicing(frets: [2, nil, 2, 2, 1, nil]),

            // G系
            "G": GuitarVoicing(frets: [3, 2, 0, 0, 0, 3]),
            "Gm": GuitarVoicing(frets: [3, 5, 5, 3, 3, 3]),
            "G7": GuitarVoicing(frets: [3, 2, 0, 0, 0, 1]),
            "Gmaj7": GuitarVoicing(frets: [3, nil, 0, 0, 0, 2]),
            "Gsus4": GuitarVoicing(frets: [3, 3, 0, 0, 1, 3]),
            "G7sus4": GuitarVoicing(frets: [3, 3, 0, 0, 1, 1]),
            "G6": GuitarVoicing(frets: [3, 2, 0, 0, 0, 0]),
            "G13": GuitarVoicing(frets: [3, nil, 3, 4, 5, nil]),
            "Gadd9": GuitarVoicing(frets: [3, 2, 0, 2, 0, 3]),

            // A系
            "A": GuitarVoicing(frets: [nil, 0, 2, 2, 2, 0]),
            "Am": GuitarVoicing(frets: [nil, 0, 2, 2, 1, 0]),
            "A7": GuitarVoicing(frets: [nil, 0, 2, 0, 2, 0]),
            "Amaj7": GuitarVoicing(frets: [nil, 0, 2, 1, 2, 0]),
            "Am7": GuitarVoicing(frets: [nil, 0, 2, 0, 1, 0]),
            "Asus4": GuitarVoicing(frets: [nil, 0, 2, 2, 3, 0]),
            "A7sus4": GuitarVoicing(frets: [nil, 0, 2, 0, 3, 0]),
            "Aadd9": GuitarVoicing(frets: [nil, 0, 2, 4, 2, 0]),
            "Am9": GuitarVoicing(frets: [nil, 0, 2, 4, 1, 0]),
            "A6": GuitarVoicing(frets: [nil, 0, 2, 2, 2, 2]),
            "Adim7": GuitarVoicing(frets: [nil, 0, 1, 2, 1, 2]),

            // B系
            "B": GuitarVoicing(frets: [nil, 2, 4, 4, 4, 2]),
            "Bm": GuitarVoicing(frets: [nil, 2, 4, 4, 3, 2]),
            "B7": GuitarVoicing(frets: [nil, 2, 1, 2, 0, 2]),
            "Bmaj7": GuitarVoicing(frets: [nil, 2, 4, 3, 4, 2]),
            "Bm7": GuitarVoicing(frets: [nil, 2, 4, 2, 3, 2]),
            "Bm7b5": GuitarVoicing(frets: [nil, 2, 3, 2, 3, nil]),
            "Bdim7": GuitarVoicing(frets: [nil, 2, 3, 1, 3, nil]),
            "B♭": GuitarVoicing(frets: [nil, 1, 3, 3, 3, 1]),
            "B♭7": GuitarVoicing(frets: [nil, 1, 3, 1, 3, 1]),
            "B♭maj7": GuitarVoicing(frets: [nil, 1, 3, 2, 3, 1]),
            "D♭7": GuitarVoicing(frets: [nil, 4, 3, 4, 2, nil])
        ]
    }

    /*
    テーブルに存在しないコードに対する安全なフォールバックボイシングを返す。
    
    Arguments:
    root
      コードのルート音名。
    
    Usage:
    未定義コードにおける安全な運指表示に使用される。
    */
    
    func fallbackVoicing(for root: String) -> GuitarVoicing {
        switch root {
        case "C": return GuitarVoicing(frets: [nil, 3, 2, 0, 1, 0])
        case "D", "D♭": return GuitarVoicing(frets: [nil, nil, 0, 2, 3, 2])
        case "E", "E♭": return GuitarVoicing(frets: [0, 2, 2, 1, 0, 0])
        case "F": return GuitarVoicing(frets: [1, 3, 3, 2, 1, 1])
        case "G", "G♭": return GuitarVoicing(frets: [3, 2, 0, 0, 0, 3])
        case "A", "A♭": return GuitarVoicing(frets: [nil, 0, 2, 2, 2, 0])
        case "B", "B♭": return GuitarVoicing(frets: [nil, 2, 4, 4, 4, 2])
        default: return GuitarVoicing(frets: [nil, 3, 2, 0, 1, 0])
        }
    }

}
