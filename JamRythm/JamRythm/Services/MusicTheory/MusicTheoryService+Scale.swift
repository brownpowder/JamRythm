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
    指定されたKey、コード、スケール種別に基づき、スケール構成音および指板ポジション一覧を取得する。

    Arguments:
    key
      基準調（Key.C等）。
    chord
      現在選択中の小節コード。
    scaleType
      ペンタトニックまたはダイアトニック。

    Usage:
    ScaleFretboardViewでスケールノートバッジおよび指板マーカーを描画するために呼び出される。
    */

    /*
    Key、小節コード、スケール種別、および基準モード（Chord基準/Key基準）から指板表示用スケール情報を算出する。

    Arguments:
    key
      基準調。
    chord
      現在選択中の小節コード。
    scaleType
      ペンタトニックまたはダイアトニック。
    referenceMode
      Chord基準（コードスケール追従）またはKey基準（曲のキースケール）。

    Usage:
    ScaleFretboardViewでスケールノートバッジおよび指板マーカーを描画するために呼び出される。
    */

    func scaleInfo(
        for key: Key,
        chord: Chord,
        scaleType: ScaleType,
        referenceMode: ScaleReferenceMode
    ) -> ScaleInfo {
        let semitones: [Int]
        let scaleName: String

        switch referenceMode {
        case .chord:
            let result = calculateChordScaleSemitonesAndName(key: key, chord: chord, scaleType: scaleType)
            semitones = result.semitones
            scaleName = result.name
        case .key:
            if scaleType == .pentatonic {
                if isChordCompatibleWithMinorPenta(chord: chord, key: key) {
                    let minorPenta = relativeMinorPentatonic(for: key)
                    semitones = minorPenta.semitones
                    scaleName = minorPenta.name
                } else {
                    let result = calculateChordScaleSemitonesAndName(key: key, chord: chord, scaleType: .diatonic)
                    semitones = result.semitones
                    scaleName = result.name
                }
            } else {
                let result = calculateKeyScaleSemitonesAndName(key: key, scaleType: scaleType)
                semitones = result.semitones
                scaleName = result.name
            }
        }

        let scaleNotes = semitones.map { Key.noteName(forSemitone: $0) }
        let positions = calculateScalePositions(
            scaleSemitones: semitones,
            chord: chord,
            alwaysIncludeChordTones: (referenceMode == .key)
        )

        return ScaleInfo(
            keyName: key.rawValue,
            scaleName: scaleName,
            scaleNotes: scaleNotes,
            positions: positions
        )
    }

    /*
    Keyに対応する平行調（Relative Minor）のマイナーペンタトニック半音配列と名称を算出する。

    Arguments:
    key
      曲の基準調（Key.CならAマイナーペンタ、Key.GならEマイナーペンタ）。

    Usage:
    ペンタトニック演奏時の基本スケールとして使用される。
    */

    func relativeMinorPentatonic(for key: Key) -> (semitones: [Int], name: String) {
        let minorRootSemitone = (key.semitoneOffset + 9) % 12
        let minorRootName = Key.noteName(forSemitone: minorRootSemitone)
        let pentaOffsets = [0, 3, 5, 7, 10]
        let semitones = pentaOffsets.map { (minorRootSemitone + $0) % 12 }
        return (semitones, "\(minorRootName) " + NSLocalizedString("マイナーペンタ", comment: ""))
    }

    /*
    現在のコードがKeyのマイナーペンタトニック（およびダイアトニック調性）と調和するかを判定する。

    Arguments:
    chord
      小節のコード。
    key
      曲の基準調。

    Usage:
    マイナーペンタのままで通せるか、コードスケールへ切り替えるかの分岐判定に使用される。
    */

    func isChordCompatibleWithMinorPenta(chord: Chord, key: Key) -> Bool {
        let diatonicOffsets = [0, 2, 4, 5, 7, 9, 11]
        let diatonicSemitones = diatonicOffsets.map { (key.semitoneOffset + $0) % 12 }

        let chordRootSemi = Key.semitone(forNoteName: chord.rootNote)
        let formulas = chordToneFormulas(for: chord.type)
        let chordToneSemitones = formulas.map { (chordRootSemi + $0.semitoneOffset) % 12 }

        // コードトーンの中にダイアトニック音階に含まれない音（例: E7のG#、FmのAb等）がある場合は不適合
        for ct in chordToneSemitones {
            if !diatonicSemitones.contains(ct) {
                return false
            }
        }
        return true
    }

    /*
    Key基準のスケール半音インデックス配列と表示名称を算出する。

    Arguments:
    key
      基準調。
    scaleType
      スケール種別。

    Usage:
    scaleInfoでKey基準が選択された場合に使用される。
    */

    func calculateKeyScaleSemitonesAndName(
        key: Key,
        scaleType: ScaleType
    ) -> (semitones: [Int], name: String) {
        let offsets: [Int]
        let typeName: String

        switch scaleType {
        case .pentatonic:
            offsets = [0, 2, 4, 7, 9]
            typeName = "メジャーペンタ"
        case .diatonic:
            offsets = [0, 2, 4, 5, 7, 9, 11]
            typeName = "メジャースケール"
        case .harmonicMinor:
            offsets = [0, 2, 3, 5, 7, 8, 11]
            typeName = "ハーモニックマイナー"
        case .melodicMinor:
            offsets = [0, 2, 3, 5, 7, 9, 11]
            typeName = "メロディックマイナー"
        case .ryukyu:
            offsets = [0, 4, 5, 7, 11]
            typeName = "琉球音階"
        case .japanese:
            // ユーザーのメンタルモデル（Keyの平行調のマイナー）に合わせて相対的なオフセットを使用
            // Cメジャーキーの時、Aヨナ抜き短音階（A, B, C, E, F）の構成音になるように [0, 4, 5, 9, 11] (C, E, F, A, B) を返す
            offsets = [0, 4, 5, 9, 11]
            typeName = "Japanese"
        }

        let semitones = offsets.map { (key.semitoneOffset + $0) % 12 }
        return (semitones, "\(key.rawValue) " + NSLocalizedString(typeName, comment: ""))
    }

    /*
    Chord基準のコードスケール半音インデックス配列と表示名称を算出する。

    Arguments:
    chord
      小節のコード。
    scaleType
      スケール種別。

    Usage:
    scaleInfoでChord基準が選択された場合にコード追従モードとして使用される。
    */

    func calculateChordScaleSemitonesAndName(
        key: Key,
        chord: Chord,
        scaleType: ScaleType
    ) -> (semitones: [Int], name: String) {
        let rootSemitone = Key.semitone(forNoteName: chord.rootNote)
        
        switch scaleType {
        case .harmonicMinor:
            let offsets = [0, 2, 3, 5, 7, 8, 11]
            let semitones = offsets.map { (rootSemitone + $0) % 12 }
            return (semitones, "\(chord.rootNote) " + NSLocalizedString("ハーモニックマイナー", comment: ""))
        case .melodicMinor:
            let offsets = [0, 2, 3, 5, 7, 9, 11]
            let semitones = offsets.map { (rootSemitone + $0) % 12 }
            return (semitones, "\(chord.rootNote) " + NSLocalizedString("メロディックマイナー", comment: ""))
        case .ryukyu:
            let offsets = [0, 4, 5, 7, 11]
            let semitones = offsets.map { (rootSemitone + $0) % 12 }
            return (semitones, "\(chord.rootNote) " + NSLocalizedString("琉球音階", comment: ""))
        case .japanese:
            let offsets = [0, 2, 3, 7, 8]
            let semitones = offsets.map { (rootSemitone + $0) % 12 }
            return (semitones, "\(chord.rootNote) " + NSLocalizedString("Japanese", comment: ""))
        default:
            let mode = calculateKeyAwareChordScaleMode(chord: chord, key: key) ?? chordScaleMode(for: chord.type)
            let offsets = (scaleType == .pentatonic) ? mode.pentaOffsets : mode.diatonicOffsets
            let modeName = (scaleType == .pentatonic) ? mode.pentaName : mode.diatonicName
            let semitones = offsets.map { (rootSemitone + $0) % 12 }
            return (semitones, "\(chord.rootNote) " + NSLocalizedString(modeName, comment: ""))
        }
    }

    /*
    コードタイプからChord基準で使用するモード（旋法）情報構造体を導出する。

    Arguments:
    chordType
      コードタイプ文字列（例: "m7", "7", "7(#9)", "dim", "sus4"）。

    Usage:
    calculateChordScaleSemitonesAndName内でモード名と半音オフセットを導出する。
    */

    func calculateKeyAwareChordScaleMode(
        chord: Chord, key: Key
    ) -> (diatonicName: String, diatonicOffsets: [Int], pentaName: String, pentaOffsets: [Int])? {
        let rootSemitone = Key.semitone(forNoteName: chord.rootNote)
        let keySemitone = key.semitoneOffset
        let diff = (rootSemitone - keySemitone + 12) % 12
        let type = chord.type.trimmingCharacters(in: .whitespaces)

        // I (Ionian)
        if diff == 0 && (!type.hasPrefix("m") || type.hasPrefix("maj")) {
            return ("イオニアン", [0, 2, 4, 5, 7, 9, 11], "メジャーペンタ", [0, 2, 4, 7, 9])
        }
        // II (Dorian)
        if diff == 2 && type.hasPrefix("m") && !type.hasPrefix("maj") {
            return ("ドリアン", [0, 2, 3, 5, 7, 9, 10], "マイナーペンタ", [0, 3, 5, 7, 10])
        }
        // III (Phrygian)
        if diff == 4 && type.hasPrefix("m") && !type.hasPrefix("maj") {
            return ("フリジアン", [0, 1, 3, 5, 7, 8, 10], "マイナーペンタ", [0, 3, 5, 7, 10])
        }
        // IV (Lydian)
        if diff == 5 && (!type.hasPrefix("m") || type.hasPrefix("maj")) {
            return ("リディアン", [0, 2, 4, 6, 7, 9, 11], "メジャーペンタ", [0, 2, 4, 7, 9])
        }
        // V (Mixolydian)
        if diff == 7 && (!type.hasPrefix("m") || type.hasPrefix("maj")) {
            return ("ミクソリディアン", [0, 2, 4, 5, 7, 9, 10], "メジャーペンタ", [0, 2, 4, 7, 9])
        }
        // VI (Aeolian)
        if diff == 9 && type.hasPrefix("m") && !type.hasPrefix("maj") {
            return ("エオリアン", [0, 2, 3, 5, 7, 8, 10], "マイナーペンタ", [0, 3, 5, 7, 10])
        }
        // VII (Locrian)
        if diff == 11 && (type.contains("dim") || type.contains("m7b5") || type.contains("m7(♭5)")) {
            return ("ロクリアン", [0, 1, 3, 5, 6, 8, 10], "マイナーペンタ♭5", [0, 3, 5, 6, 10])
        }
        
        return nil
    }

    func chordScaleMode(
        for chordType: String
    ) -> (diatonicName: String, diatonicOffsets: [Int], pentaName: String, pentaOffsets: [Int]) {
        let type = chordType.trimmingCharacters(in: .whitespaces)

        if type.contains("dim") {
            return ("ディミニッシュ", [0, 2, 3, 5, 6, 8, 9, 11], "ディミニッシュ", [0, 3, 6, 9])
        }
        if type.contains("m7(♭5)") || type.contains("m7b5") {
            return ("ロクリアン", [0, 1, 3, 5, 6, 8, 10], "マイナーペンタ♭5", [0, 3, 5, 6, 10])
        }
        if type.contains("7(♭9)") || type.contains("7(♯9)") || type.contains("7(#9)") || type.contains("7(b9)") {
            return ("HMP5thビロウ", [0, 1, 4, 5, 7, 8, 10], "マイナーペンタ", [0, 3, 5, 7, 10])
        }
        if type == "sus4" || type.contains("7sus4") {
            return ("ミクソリディアンsus4", [0, 2, 5, 7, 9, 10], "ペンタトニック", [0, 2, 5, 7, 9])
        }
        if type.hasPrefix("m") && !type.hasPrefix("maj") {
            return ("ドリアン", [0, 2, 3, 5, 7, 9, 10], "マイナーペンタ", [0, 3, 5, 7, 10])
        }
        if type.contains("7") || type.contains("9") || type.contains("13") {
            return ("ミクソリディアン", [0, 2, 4, 5, 7, 9, 10], "メジャーペンタ", [0, 2, 4, 7, 9])
        }
        return ("イオニアン", [0, 2, 4, 5, 7, 9, 11], "メジャーペンタ", [0, 2, 4, 7, 9])
    }

    /*
    ギター6弦の0〜5フレットを走査し、スケールに含まれるフレットポジションおよび役割を導出する。

    Arguments:
    scaleSemitones
      スケール構成音の半音番号一覧。
    chord
      現在のコード（ルートおよびコードトーン判定用）。
    alwaysIncludeChordTones
      trueの場合、スケール外であってもコード構成音を指板上に必ずプロットする（Key基準向け）。

    Usage:
    scaleInfo内で指板上のマーカー配列（ScaleFretPosition）を生成する際に使用される。
    */

    func calculateScalePositions(
        scaleSemitones: [Int],
        chord: Chord,
        alwaysIncludeChordTones: Bool = false
    ) -> [ScaleFretPosition] {
        let chordRootSemitone = Key.semitone(forNoteName: chord.rootNote)
        let formulas = chordToneFormulas(for: chord.type)
        let chordToneSemitones = formulas.map { (chordRootSemitone + $0.semitoneOffset) % 12 }

        // ギター6弦の開放弦半音値（6弦E=4, 5弦A=9, 4弦D=2, 3弦G=7, 2弦B=11, 1弦E=4）
        let openStrings: [(stringNumber: Int, openSemitone: Int)] = [
            (6, 4), (5, 9), (4, 2), (3, 7), (2, 11), (1, 4)
        ]

        var result: [ScaleFretPosition] = []

        for (stringNum, openSemi) in openStrings {
            for fret in 0...15 {
                let fretSemitone = (openSemi + fret) % 12
                let isChordTone = chordToneSemitones.contains(fretSemitone)
                let isRoot = (fretSemitone == chordRootSemitone)

                // スケールに含まれるか、またはコードトーン強制包含が有効な場合のコードトーン
                guard scaleSemitones.contains(fretSemitone) || (alwaysIncludeChordTones && (isChordTone || isRoot)) else {
                    continue
                }

                let noteName = Key.noteName(forSemitone: fretSemitone)
                let role: ScaleToneRole

                if isRoot {
                    role = .root
                } else if isChordTone {
                    role = .chordTone
                } else {
                    role = .scaleTone
                }

                result.append(ScaleFretPosition(
                    stringNumber: stringNum,
                    fret: fret,
                    noteName: noteName,
                    role: role
                ))
            }
        }

        return result
    }

}
