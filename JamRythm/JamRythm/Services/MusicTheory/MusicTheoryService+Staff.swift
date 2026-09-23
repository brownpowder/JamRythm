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
    指定されたコードの構成音を五線譜の音高ステップ（E4=0基準）および臨時記号・音名付きで返す。
    
    Arguments:
    chord
      構成音を導出するChordオブジェクト。
    
    Usage:
    StaffScoreViewでト音記号五線譜上に音符を描画するために呼び出される。
    */
    
    func staffNotes(for chord: Chord) -> [StaffNote] {
        let rootDIndex = diatonicIndexForNote(chord.rootNote)
        let rootBaseStep = rootDIndex - 2
        let rootSemitone = Key.semitone(forNoteName: chord.rootNote)
        let formulas = chordToneFormulas(for: chord.type)

        let diatonicLetters = ["C", "D", "E", "F", "G", "A", "B"]
        let diatonicNaturalSemitones = [0, 2, 4, 5, 7, 9, 11]

        var notes = formulas.map { formula in
            var calculatedStep = rootBaseStep + formula.stepOffset
            var targetDIndex = ((rootDIndex + formula.stepOffset) % 7 + 7) % 7
            var letterName = diatonicLetters[targetDIndex]
            var naturalSemitone = diatonicNaturalSemitones[targetDIndex]
            let actualSemitone = ((rootSemitone + formula.semitoneOffset) % 12 + 12) % 12

            var diff = ((actualSemitone - naturalSemitone) % 12 + 12) % 12

            // 読譜性向上のためのエンハーモニック（異名同音）簡略化
            // 1. ダブルフラット (diff == 10) を解消し、1音下のナチュラル音に置換（例: B♭♭ -> A）
            if diff == 10 {
                targetDIndex = ((targetDIndex - 1) % 7 + 7) % 7
                calculatedStep -= 1
                letterName = diatonicLetters[targetDIndex]
                naturalSemitone = diatonicNaturalSemitones[targetDIndex]
                diff = ((actualSemitone - naturalSemitone) % 12 + 12) % 12
            }
            // 2. ダブルシャープ (diff == 2) を解消し、1音上のナチュラル音に置換（例: F𝄪 -> G）
            else if diff == 2 {
                targetDIndex = (targetDIndex + 1) % 7
                calculatedStep += 1
                letterName = diatonicLetters[targetDIndex]
                naturalSemitone = diatonicNaturalSemitones[targetDIndex]
                diff = ((actualSemitone - naturalSemitone) % 12 + 12) % 12
            }
            // 3. 視認性の悪い F♭ (実音E) や C♭ (実音B) を白鍵ナチュラルに置換
            else if letterName == "F" && actualSemitone == 4 {
                targetDIndex = 2
                calculatedStep -= 1
                letterName = "E"
                diff = 0
            } else if letterName == "C" && actualSemitone == 11 {
                targetDIndex = 6
                calculatedStep -= 1
                letterName = "B"
                diff = 0
            } else if letterName == "B" && actualSemitone == 0 {
                targetDIndex = 0
                calculatedStep += 1
                letterName = "C"
                diff = 0
            } else if letterName == "E" && actualSemitone == 5 {
                targetDIndex = 3
                calculatedStep += 1
                letterName = "F"
                diff = 0
            }

            let accidental: String?
            let noteName: String

            switch diff {
            case 0:
                accidental = nil
                noteName = letterName
            case 1:
                accidental = "♯"
                noteName = "\(letterName)♯"
            case 11:
                accidental = "♭"
                noteName = "\(letterName)♭"
            default:
                accidental = nil
                noteName = letterName
            }

            return StaffNote(name: noteName, accidental: accidental, step: calculatedStep)
        }

        if let bass = chord.bassNote, !bass.isEmpty, bass != chord.rootNote {
            let lowest = notes.map(\.step).min() ?? rootBaseStep
            let bassStaffNote = createBassStaffNote(bassNote: bass, lowestChordStep: lowest)
            notes.insert(bassStaffNote, at: 0)
        }

        return notes
    }

    /*
    オンコードの指定ベース音に対応するStaffNoteを生成する。
    
    Arguments:
    bassNote
      指定された低音の音名（例: "G", "F♯"）。
      ChordオブジェクトのbassNoteから渡される。
    lowestChordStep
      上声部コードの最低ステップ値。
      このステップより必ず低くなるようオクターブ調整するために使用される。
    
    Usage:
    オンコード（分母コード）のベース音を五線譜の最下音として描画するために呼び出される。
    */
    
    func createBassStaffNote(bassNote: String, lowestChordStep: Int) -> StaffNote {
        let bassDIndex = diatonicIndexForNote(bassNote)
        var bassStep = bassDIndex - 2
        while bassStep >= lowestChordStep {
            bassStep -= 7
        }

        let diatonicLetters = ["C", "D", "E", "F", "G", "A", "B"]
        let diatonicNaturalSemitones = [0, 2, 4, 5, 7, 9, 11]
        let bassSemitone = Key.semitone(forNoteName: bassNote)
        let naturalSemitone = diatonicNaturalSemitones[bassDIndex]
        let diff = ((bassSemitone - naturalSemitone) % 12 + 12) % 12

        let accidental: String?
        let letter = diatonicLetters[bassDIndex]
        let noteName: String

        switch diff {
        case 1:
            accidental = "♯"
            noteName = "\(letter)♯"
        case 2:
            accidental = "𝄪"
            noteName = "\(letter)𝄪"
        case 11:
            accidental = "♭"
            noteName = "\(letter)♭"
        case 10:
            accidental = "♭♭"
            noteName = "\(letter)♭♭"
        default:
            accidental = nil
            noteName = letter
        }

        return StaffNote(name: noteName, accidental: accidental, step: bassStep)
    }

    /*
    音名から五線譜の基準ステップ（E4 = 0）を計算する。
    
    Arguments:
    noteName
      音名文字列（例: "C", "D", "G"）。
    
    Usage:
    外部や互換性のために保持されるルートステップ算出関数。
    */
    
    func stepForNote(_ noteName: String) -> Int {
        return diatonicIndexForNote(noteName) - 2
    }

    /*
    五線譜ステップ値から音名ラベル（C4〜A5など）を簡易生成する。
    
    Arguments:
    step
      E4=0基準のステップ数。
    
    Usage:
    ステップ値から幹音名を簡易取得する。
    */
    
    func labelForStep(_ step: Int) -> String {
        let noteOrder = ["E", "F", "G", "A", "B", "C", "D"]
        let index = ((step % 7) + 7) % 7
        return noteOrder[index]
    }

}
