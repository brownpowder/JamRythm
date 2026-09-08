//
//  MusicTheoryService.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import Foundation

// MARK: - 音楽理論サービス・プロトコル

/*
Keyと度数（ベース音）に基づき、音楽的なコード候補を算出するインターフェース。
テスタビリティと差し替え容易性を確保するためProtocolで定義する。
*/
protocol MusicTheoryServiceProtocol {
    /*
    指定されたKeyとベース度数に対して、4つの感情ラベル（安定、少し切ない、おしゃれ、緊張感）に応じたコード候補を算出する。
    
    Arguments:
    key
      楽曲の基準調（例: Key.C）。プロジェクトデータまたはViewModelから渡される。
    baseDegree
      土台となる度数（1〜7）。王道進行テンプレート等から渡される。
    
    Usage:
    小節ごとの候補提示ロジックで呼び出され、ユーザーが選択可能な選択肢配列を生成する。
    */
    
    func calculateCandidates(key: Key, baseDegree: Int) -> [ChordCandidate]
}

// MARK: - 音楽理論サービス・実装クラス

/*
ルールベースで感情ラベルに対応するコード候補を導出するサービス実装。
完全オフラインで動作し、各度数におけるダイアトニック、テンション、代理コードを算出する。
*/
final class MusicTheoryService: MusicTheoryServiceProtocol {

    /*
    Keyと度数から4つの感情候補（安定、切ない、おしゃれ、緊張感）を計算して返す。
    
    Arguments:
    key
      楽曲の基準キー。ViewModelから渡される。
    baseDegree
      現在の小節の度数（1〜7）。Measureモデルから渡される。
    
    Usage:
    PlayEditorViewModelで小節切り替え時や曲生成時に実行される。
    */
    
    func calculateCandidates(key: Key, baseDegree: Int) -> [ChordCandidate] {
        let normalizedDegree = normalizeDegree(baseDegree)
        let bassNote = calculateBassNote(key: key, degree: normalizedDegree)

        let stableChord = createStableChord(degree: normalizedDegree, bassNote: bassNote)
        let melancholyChord = createMelancholyChord(key: key, degree: normalizedDegree, bassNote: bassNote)
        let stylishChord = createStylishChord(key: key, degree: normalizedDegree, bassNote: bassNote)
        let tensionChord = createTensionChord(key: key, degree: normalizedDegree, bassNote: bassNote)

        return [
            ChordCandidate(flavor: .stable, chord: stableChord),
            ChordCandidate(flavor: .melancholy, chord: melancholyChord),
            ChordCandidate(flavor: .stylish, chord: stylishChord),
            ChordCandidate(flavor: .tension, chord: tensionChord)
        ]
    }

    // MARK: - 内部計算ヘルパーメソッド

    /*
    度数を1〜7の範囲に正規化する。
    
    Arguments:
    degree
      入力された任意の整数度数。
    
    Usage:
    配列インデックスの範囲外アクセスを防ぐために内部で使用される。
    */
    
    private func normalizeDegree(_ degree: Int) -> Int {
        let positive = (degree - 1) % 7
        return (positive >= 0 ? positive : positive + 7) + 1
    }

    /*
    Keyと度数から実際のベース音名を計算する。
    
    Arguments:
    key
      楽曲の基準キー。
    degree
      1〜7に正規化された度数。
    
    Usage:
    ベースのルート音および分数コードのベース音として使用される。
    */
    
    private func calculateBassNote(key: Key, degree: Int) -> String {
        let semitone = key.semitoneOffset + Key.semitonesForMajorDegree(degree)
        return Key.noteName(forSemitone: semitone)
    }

    /*
    安定（基本のダイアトニック和音）コードを生成する。
    
    Arguments:
    degree
      正規化された度数。
    bassNote
      計算済みのベース音名。
    
    Usage:
    王道のコード進行を支える最も安定した和音候補を構築する。
    */
    
    private func createStableChord(degree: Int, bassNote: String) -> Chord {
        switch degree {
        case 1:
            return Chord(rootNote: bassNote, type: "maj7", bassNote: nil)
        case 2:
            return Chord(rootNote: bassNote, type: "m7", bassNote: nil)
        case 3:
            return Chord(rootNote: bassNote, type: "m7", bassNote: nil)
        case 4:
            return Chord(rootNote: bassNote, type: "maj7", bassNote: nil)
        case 5:
            return Chord(rootNote: bassNote, type: "7", bassNote: nil)
        case 6:
            return Chord(rootNote: bassNote, type: "m7", bassNote: nil)
        case 7:
            return Chord(rootNote: bassNote, type: "m7b5", bassNote: nil)
        default:
            return Chord(rootNote: bassNote, type: "", bassNote: nil)
        }
    }

    /*
    少し切ない（哀愁や陰りのある響き）コードを生成する。
    
    Arguments:
    key
      楽曲のキー。
    degree
      正規化された度数。
    bassNote
      計算済みのベース音名。
    
    Usage:
    サブドミナントマイナーや平行調マイナーの借用により陰りを演出する。
    */
    
    private func createMelancholyChord(key: Key, degree: Int, bassNote: String) -> Chord {
        switch degree {
        case 1:
            return Chord(rootNote: bassNote, type: "6", bassNote: nil)
        case 4:
            // サブドミナントマイナー (Fm7)
            return Chord(rootNote: bassNote, type: "m7", bassNote: nil)
        case 5:
            // 3度上のマイナーを乗せた分数コード (Em7/G)
            let threeDegreeNote = calculateBassNote(key: key, degree: 3)
            return Chord(rootNote: threeDegreeNote, type: "m7", bassNote: bassNote)
        case 6:
            return Chord(rootNote: bassNote, type: "m9", bassNote: nil)
        default:
            return Chord(rootNote: bassNote, type: "m7", bassNote: nil)
        }
    }

    /*
    おしゃれ（テンションや色彩感）コードを生成する。
    
    Arguments:
    key
      楽曲のキー。
    degree
      正規化された度数。
    bassNote
      計算済みのベース音名。
    
    Usage:
    9th, 11th, 13thや分数コードを付与してジャズ・シティポップ感を出す。
    */
    
    private func createStylishChord(key: Key, degree: Int, bassNote: String) -> Chord {
        switch degree {
        case 1:
            return Chord(rootNote: bassNote, type: "add9", bassNote: nil)
        case 4:
            return Chord(rootNote: bassNote, type: "maj9", bassNote: nil)
        case 5:
            // 2度マイナーを上に乗せたオンコード (Dm9/G) または 13th
            let twoDegreeNote = calculateBassNote(key: key, degree: 2)
            return Chord(rootNote: twoDegreeNote, type: "m9", bassNote: bassNote)
        case 6:
            return Chord(rootNote: bassNote, type: "m11", bassNote: nil)
        default:
            return Chord(rootNote: bassNote, type: "9", bassNote: nil)
        }
    }

    /*
    緊張感（裏コード・代理コード・減七）コードを生成する。
    
    Arguments:
    key
      楽曲のキー。
    degree
      正規化された度数。
    bassNote
      計算済みのベース音名。
    
    Usage:
    裏コードやディミニッシュを用いてドミナントモーションの解決感を強める。
    */
    
    private func createTensionChord(key: Key, degree: Int, bassNote: String) -> Chord {
        switch degree {
        case 5:
            // ドミナント5度に対する裏コード（増4度上の7th: D♭7/G）
            let tritoneSemitone = key.semitoneOffset + Key.semitonesForMajorDegree(degree) + 6
            let tritoneNote = Key.noteName(forSemitone: tritoneSemitone)
            return Chord(rootNote: tritoneNote, type: "7", bassNote: bassNote)
        case 4:
            return Chord(rootNote: bassNote, type: "m7b5", bassNote: nil)
        case 1:
            return Chord(rootNote: bassNote, type: "aug", bassNote: nil)
        case 2:
            return Chord(rootNote: bassNote, type: "7(b9)", bassNote: nil)
        default:
            return Chord(rootNote: bassNote, type: "dim7", bassNote: nil)
        }
    }
}
