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
    コード種別に応じた構成音の度数ステップオフセットと半音オフセットのタプル配列を返す。
    
    Arguments:
    chordType
      コードの種別文字列（例: "dim7", "m7", "maj7", "7(b9)" など）。
    
    Usage:
    五線譜の音符配置（staffNotes）およびピアノ音源再生（chordMidiNotes）で共通利用される。
    */

    func chordToneFormulas(for chordType: String) -> [(stepOffset: Int, semitoneOffset: Int)] {
        let type = chordType.lowercased()

        if type.contains("dim7") {
            return [(0, 0), (2, 3), (4, 6), (6, 9)]
        } else if type.contains("dim") {
            return [(0, 0), (2, 3), (4, 6)]
        } else if type.contains("m7b5") {
            return [(0, 0), (2, 3), (4, 6), (6, 10)]
        } else if type.contains("7(#9)") || type.contains("7#9") {
            return [(0, 0), (2, 4), (4, 7), (6, 10), (8, 15)]
        } else if type.contains("7(b9)") || type.contains("7b9") {
            return [(0, 0), (2, 4), (4, 7), (6, 10), (8, 13)]
        } else if type.contains("7(#11)") || type.contains("7#11") {
            return [(0, 0), (2, 4), (4, 7), (6, 10), (10, 18)]
        } else if type.contains("7(b13)") || type.contains("7b13") {
            return [(0, 0), (2, 4), (4, 7), (6, 10), (12, 20)]
        } else if type.contains("maj13") {
            return [(0, 0), (2, 4), (4, 7), (6, 11), (8, 14), (12, 21)]
        } else if type.contains("13") {
            return [(0, 0), (2, 4), (4, 7), (6, 10), (8, 14), (12, 21)]
        } else if type.contains("7sus4") {
            return [(0, 0), (3, 5), (4, 7), (6, 10)]
        } else if type.contains("sus4") {
            return [(0, 0), (3, 5), (4, 7)]
        } else if type.contains("maj9") {
            return [(0, 0), (2, 4), (4, 7), (6, 11), (8, 14)]
        } else if type.contains("m11") {
            return [(0, 0), (2, 3), (4, 7), (6, 10), (10, 17)]
        } else if type.contains("11") {
            return [(0, 0), (2, 4), (4, 7), (6, 10), (8, 14), (10, 17)]
        } else if type.contains("m9") {
            return [(0, 0), (2, 3), (4, 7), (6, 10), (8, 14)]
        } else if type.contains("add9") {
            return [(0, 0), (2, 4), (4, 7), (8, 14)]
        } else if type.contains("mm7") || type.contains("m(maj7)") {
            return [(0, 0), (2, 3), (4, 7), (6, 11)]
        } else if type.contains("maj7") {
            return [(0, 0), (2, 4), (4, 7), (6, 11)]
        } else if type.contains("m7") {
            return [(0, 0), (2, 3), (4, 7), (6, 10)]
        } else if type == "9" || type.contains("9") {
            return [(0, 0), (2, 4), (4, 7), (6, 10), (8, 14)]
        } else if type.contains("7") {
            return [(0, 0), (2, 4), (4, 7), (6, 10)]
        } else if type.contains("m6") {
            return [(0, 0), (2, 3), (4, 7), (5, 9)]
        } else if type.contains("6") {
            return [(0, 0), (2, 4), (4, 7), (5, 9)]
        } else if type.contains("aug") {
            return [(0, 0), (2, 4), (4, 8)]
        } else if type.contains("m") {
            return [(0, 0), (2, 3), (4, 7)]
        } else {
            return [(0, 0), (2, 4), (4, 7)]
        }
    }

    /*
    音名からダイアトニック幹音インデックス（C=0, D=1, E=2, F=3, G=4, A=5, B=6）を取得する。
    
    Arguments:
    noteName
      音名文字列（例: "C", "D♭", "F#", "G"）。
    
    Usage:
    五線譜の基準ステップおよび度数計算に使用される。
    */

    func diatonicIndexForNote(_ noteName: String) -> Int {
        guard let firstChar = noteName.first else { return 0 }
        switch firstChar {
        case "C": return 0
        case "D": return 1
        case "E": return 2
        case "F": return 3
        case "G": return 4
        case "A": return 5
        case "B": return 6
        default: return 0
        }
    }

}
