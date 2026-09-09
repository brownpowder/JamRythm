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

    /*
    指定されたKeyとベース度数に対して、理論的な代理コード（トニック代理、サブドミナント代理、裏コード等）の候補を算出する。

    Arguments:
    key
      楽曲の基準調（例: Key.C）。
    baseDegree
      土台となる度数（1〜7）。

    Usage:
    小節ごとの代理コード提案で呼び出される。
    */

    func calculateSubstituteCandidates(
        key: Key,
        baseDegree: Int,
        excludingChords: [Chord]
    ) -> [SubstituteCandidate]

    /*
    指定されたコードに対する代表的なギター運指（ボイシング）を取得する。
    
    Arguments:
    chord
      押弦ポジションを算出するChordオブジェクト。
    
    Usage:
    GuitarTabViewで6弦〜1弦のフレット番号を描画するために呼び出される。
    */
    
    func guitarVoicing(for chord: Chord) -> GuitarVoicing

    /*
    指定されたコードの構成音を五線譜上の配置位置（StaffNote配列）として取得する。
    
    Arguments:
    chord
      構成音を算出するChordオブジェクト。
    
    Usage:
    StaffScoreViewでト音記号五線譜上に音符を描画するために呼び出される。
    */
    
    func staffNotes(for chord: Chord) -> [StaffNote]

    /*
    指定されたコードの構成音をMIDIノート番号（UInt8）の配列として取得する。
    
    Arguments:
    chord
      MIDIノートを算出するChordオブジェクト。
    
    Usage:
    ピアノ音源での和音試聴・プレビュー再生に使用される。
    */

    func chordMidiNotes(for chord: Chord) -> [UInt8]
}

// MARK: - プロトコルデフォルト実装

extension MusicTheoryServiceProtocol {
    /*
    excludingChords を省略した場合に空配列を渡すデフォルト実装。
    
    Arguments:
    key
      基準調。
    baseDegree
      土台となる度数（1〜7）。
    
    Usage:
    除外コードを指定しない簡易呼び出しで使用される。
    */
    
    func calculateSubstituteCandidates(key: Key, baseDegree: Int) -> [SubstituteCandidate] {
        return calculateSubstituteCandidates(key: key, baseDegree: baseDegree, excludingChords: [])
    }
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

    /*
    Keyと度数から音楽理論に基づく代理コード候補（2つ）を計算して返す。

    Arguments:
    key
      楽曲の基準キー。
    baseDegree
      土台となる度数（1〜7）。

    Usage:
    小節切り替え時やコード候補更新時に呼び出される。
    */

    /*
    Keyと度数から音楽理論に基づく代理コード候補を計算し、必要に応じて既存コード（フレーバー等）との重複を排除して返す。

    Arguments:
    key
      楽曲の基準キー。
    baseDegree
      土台となる度数（1〜7）。
    excludingChords
      重複を排除したいコードリスト（フレーバー候補等）。呼び出し元から渡される。

    Usage:
    小節切り替え時やコード候補更新時に呼び出される。
    */

    func calculateSubstituteCandidates(
        key: Key,
        baseDegree: Int,
        excludingChords: [Chord] = []
    ) -> [SubstituteCandidate] {
        let normalizedDegree = normalizeDegree(baseDegree)
        let allCandidates = createSubstituteChords(key: key, degree: normalizedDegree)

        guard !excludingChords.isEmpty else {
            return Array(allCandidates.prefix(2))
        }

        let filtered = allCandidates.filter { candidate in
            !excludingChords.contains { excluded in
                excluded == candidate.chord || excluded.displayString == candidate.chord.displayString
            }
        }

        if filtered.count >= 2 {
            return Array(filtered.prefix(2))
        }

        var result = filtered
        for candidate in allCandidates where !result.contains(candidate) && result.count < 2 {
            result.append(candidate)
        }
        return result
    }

    /*
    度数に応じた代理コード候補プールを生成する。
    
    Arguments:
    key
      楽曲のキー。
    degree
      正規化された度数（1〜7）。
    
    Usage:
    calculateSubstituteCandidatesから呼び出される。
    */
    
    private func createSubstituteChords(key: Key, degree: Int) -> [SubstituteCandidate] {
        switch degree {
        case 1...3:
            return tonicSubstitutePool(key: key, degree: degree)
        case 4...7:
            return subdominantAndDominantPool(key: key, degree: degree)
        default:
            return []
        }
    }

    /*
    トニック系度数（1, 2, 3度）の代理コード候補プールを生成する。
    
    Arguments:
    key
      楽曲のキー。
    degree
      度数（1〜3）。
    
    Usage:
    createSubstituteChordsから呼び出される。
    */
    
    private func tonicSubstitutePool(key: Key, degree: Int) -> [SubstituteCandidate] {
        let bSevenNote = Key.noteName(forSemitone: key.semitoneOffset + 10)
        switch degree {
        case 1:
            let threeNote = calculateBassNote(key: key, degree: 3)
            let sixNote = calculateBassNote(key: key, degree: 6)
            return [
                SubstituteCandidate(label: "Ⅲm7 代理", chord: Chord(rootNote: threeNote, type: "m7", bassNote: nil)),
                SubstituteCandidate(label: "Ⅵm7 代理", chord: Chord(rootNote: sixNote, type: "m7", bassNote: nil)),
                SubstituteCandidate(label: "♭Ⅶ7 バックドア", chord: Chord(rootNote: bSevenNote, type: "7", bassNote: nil))
            ]
        case 2:
            let fourNote = calculateBassNote(key: key, degree: 4)
            let sixNote = calculateBassNote(key: key, degree: 6)
            return [
                SubstituteCandidate(label: "Ⅳmaj7 代理", chord: Chord(rootNote: fourNote, type: "maj7", bassNote: nil)),
                SubstituteCandidate(label: "♭Ⅶ7 バックドア", chord: Chord(rootNote: bSevenNote, type: "7", bassNote: nil)),
                SubstituteCandidate(label: "Ⅵm7 代理", chord: Chord(rootNote: sixNote, type: "m7", bassNote: nil))
            ]
        case 3:
            let oneNote = calculateBassNote(key: key, degree: 1)
            let sixNote = calculateBassNote(key: key, degree: 6)
            let fiveNote = calculateBassNote(key: key, degree: 5)
            return [
                SubstituteCandidate(label: "Ⅰmaj7 代理", chord: Chord(rootNote: oneNote, type: "maj7", bassNote: nil)),
                SubstituteCandidate(label: "Ⅵm7 代理", chord: Chord(rootNote: sixNote, type: "m7", bassNote: nil)),
                SubstituteCandidate(label: "Ⅴ7 代理", chord: Chord(rootNote: fiveNote, type: "7", bassNote: nil))
            ]
        default:
            return []
        }
    }

    /*
    サブドミナント・ドミナント系度数（4, 5, 6, 7度）の代理コード候補プールを生成する。
    
    Arguments:
    key
      楽曲のキー。
    degree
      度数（4〜7）。
    
    Usage:
    createSubstituteChordsから呼び出される。
    */
    
    private func subdominantAndDominantPool(key: Key, degree: Int) -> [SubstituteCandidate] {
        let bTwoNote = Key.noteName(forSemitone: key.semitoneOffset + 1)
        let twoNote = calculateBassNote(key: key, degree: 2)
        let fourNote = calculateBassNote(key: key, degree: 4)

        switch degree {
        case 4:
            let bSevenNote = Key.noteName(forSemitone: key.semitoneOffset + 10)
            return [
                SubstituteCandidate(label: "Ⅱm7 代理", chord: Chord(rootNote: twoNote, type: "m7", bassNote: nil)),
                SubstituteCandidate(label: "Ⅳm7 サブドミマイナー", chord: Chord(rootNote: fourNote, type: "m7", bassNote: nil)),
                SubstituteCandidate(label: "♭Ⅶ7 バックドア", chord: Chord(rootNote: bSevenNote, type: "7", bassNote: nil))
            ]
        case 5:
            let sevenNote = calculateBassNote(key: key, degree: 7)
            return [
                SubstituteCandidate(label: "♭Ⅱ7 裏コード", chord: Chord(rootNote: bTwoNote, type: "7", bassNote: nil)),
                SubstituteCandidate(label: "Ⅶm7♭5 代理", chord: Chord(rootNote: sevenNote, type: "m7b5", bassNote: nil)),
                SubstituteCandidate(label: "Ⅳmaj7 代理", chord: Chord(rootNote: fourNote, type: "maj7", bassNote: nil))
            ]
        case 6:
            let oneNote = calculateBassNote(key: key, degree: 1)
            return [
                SubstituteCandidate(label: "Ⅰmaj7 代理", chord: Chord(rootNote: oneNote, type: "maj7", bassNote: nil)),
                SubstituteCandidate(label: "Ⅳmaj7 代理", chord: Chord(rootNote: fourNote, type: "maj7", bassNote: nil)),
                SubstituteCandidate(label: "Ⅱm7 代理", chord: Chord(rootNote: twoNote, type: "m7", bassNote: nil))
            ]
        case 7:
            let fiveNote = calculateBassNote(key: key, degree: 5)
            return [
                SubstituteCandidate(label: "Ⅴ7 代理", chord: Chord(rootNote: fiveNote, type: "7", bassNote: nil)),
                SubstituteCandidate(label: "♭Ⅱ7 裏コード", chord: Chord(rootNote: bTwoNote, type: "7", bassNote: nil)),
                SubstituteCandidate(label: "Ⅱm7 代理", chord: Chord(rootNote: twoNote, type: "m7", bassNote: nil))
            ]
        default:
            return []
        }
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

    // MARK: - ギターボイシング提供

    /*
    指定されたコードに対する代表的なギター運指（ボイシング）を返す。
    
    Arguments:
    chord
      押弦ポジションを算出するChordオブジェクト。
    
    Usage:
    GuitarTabViewで6弦〜1弦のフレット番号を描画するために呼び出される。
    */
    
    func guitarVoicing(for chord: Chord) -> GuitarVoicing {
        if let special = specialVoicing(for: chord) {
            return special
        }
        let code = "\(chord.rootNote)\(chord.type)"
        if let standard = standardVoicingTable[code] {
            return standard
        }
        return fallbackVoicing(for: chord.rootNote)
    }

    /*
    分数コード等の特殊ボイシングを判定して返す。
    
    Arguments:
    chord
      対象のコード。
    
    Usage:
    guitarVoicing内で優先判定として使用される。
    */
    
    private func specialVoicing(for chord: Chord) -> GuitarVoicing? {
        if chord.bassNote == "G" && chord.rootNote == "E" && chord.type == "m7" {
            return GuitarVoicing(frets: [3, 2, 0, 0, 0, 0]) // Em7/G
        }
        if chord.bassNote == "G" && chord.rootNote == "D" && chord.type.contains("9") {
            return GuitarVoicing(frets: [3, nil, 0, 2, 1, 0]) // Dm9/G
        }
        if chord.bassNote == "G" && chord.rootNote == "D♭" && chord.type == "7" {
            return GuitarVoicing(frets: [3, 4, 3, 4, 2, nil]) // D♭7/G
        }
        return nil
    }

    /*
    代表的な標準コードフォームのテーブル。
    ディミニッシュ、サスフォー、オーギュメント、ハーフディミニッシュ等も網羅。
    */
    private var standardVoicingTable: [String: GuitarVoicing] {
        [
            "Cmaj7": GuitarVoicing(frets: [nil, 3, 2, 0, 0, 0]),
            "C7": GuitarVoicing(frets: [nil, 3, 2, 3, 1, 0]),
            "C6": GuitarVoicing(frets: [nil, 3, 2, 2, 1, 0]),
            "Cadd9": GuitarVoicing(frets: [nil, 3, 2, 0, 3, 0]),
            "Cm7": GuitarVoicing(frets: [nil, 3, 5, 3, 4, 3]),
            "Cm": GuitarVoicing(frets: [nil, 3, 5, 5, 4, 3]),
            "Csus4": GuitarVoicing(frets: [nil, 3, 3, 0, 1, 1]),
            "Caug": GuitarVoicing(frets: [nil, 3, 2, 1, 1, 0]),
            "D7": GuitarVoicing(frets: [nil, nil, 0, 2, 1, 2]),
            "Dm7": GuitarVoicing(frets: [nil, nil, 0, 2, 1, 1]),
            "Dm": GuitarVoicing(frets: [nil, nil, 0, 2, 3, 1]),
            "D♭7": GuitarVoicing(frets: [nil, 4, 3, 4, 2, nil]),
            "E7": GuitarVoicing(frets: [0, 2, 0, 1, 0, 0]),
            "Em7": GuitarVoicing(frets: [0, 2, 0, 0, 0, 0]),
            "Em": GuitarVoicing(frets: [0, 2, 2, 0, 0, 0]),
            "Edim7": GuitarVoicing(frets: [nil, nil, 2, 3, 2, 3]),
            "Fmaj7": GuitarVoicing(frets: [nil, nil, 3, 2, 1, 0]),
            "Fm7": GuitarVoicing(frets: [1, 3, 1, 1, 1, 1]),
            "Fm": GuitarVoicing(frets: [1, 3, 3, 1, 1, 1]),
            "Fmaj9": GuitarVoicing(frets: [nil, nil, 3, 0, 1, 0]),
            "F#m7b5": GuitarVoicing(frets: [2, nil, 2, 2, 1, nil]),
            "G": GuitarVoicing(frets: [3, 2, 0, 0, 0, 3]),
            "G7": GuitarVoicing(frets: [3, 2, 0, 0, 0, 1]),
            "Gmaj7": GuitarVoicing(frets: [3, nil, 0, 0, 0, 2]),
            "Gsus4": GuitarVoicing(frets: [3, 3, 0, 0, 1, 3]),
            "G7sus4": GuitarVoicing(frets: [3, 3, 0, 0, 1, 1]),
            "G13": GuitarVoicing(frets: [3, nil, 3, 4, 5, nil]),
            "Gm": GuitarVoicing(frets: [3, 5, 5, 3, 3, 3]),
            "Am7": GuitarVoicing(frets: [nil, 0, 2, 0, 1, 0]),
            "Am9": GuitarVoicing(frets: [nil, 0, 2, 4, 1, 0]),
            "Am": GuitarVoicing(frets: [nil, 0, 2, 2, 1, 0]),
            "Adim7": GuitarVoicing(frets: [nil, 0, 1, 2, 1, 2]),
            "Bm7b5": GuitarVoicing(frets: [nil, 2, 3, 2, 3, nil]),
            "Bdim7": GuitarVoicing(frets: [nil, 2, 3, 1, 3, nil]),
            "B7": GuitarVoicing(frets: [nil, 2, 1, 2, 0, 2]),
            "B♭7": GuitarVoicing(frets: [nil, 1, 3, 1, 3, 1]),
            "Bm": GuitarVoicing(frets: [nil, 2, 4, 4, 3, 2])
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
    
    private func fallbackVoicing(for root: String) -> GuitarVoicing {
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

    // MARK: - コードトーン定義と五線譜・音源共通計算

    /*
    コード種別に応じた構成音の度数ステップオフセットと半音オフセットのタプル配列を返す。
    
    Arguments:
    chordType
      コードの種別文字列（例: "dim7", "m7", "maj7", "7(b9)" など）。
    
    Usage:
    五線譜の音符配置（staffNotes）およびピアノ音源再生（chordMidiNotes）で共通利用される。
    */

    private func chordToneFormulas(for chordType: String) -> [(stepOffset: Int, semitoneOffset: Int)] {
        let type = chordType.lowercased()

        if type.contains("dim7") {
            return [(0, 0), (2, 3), (4, 6), (6, 9)]
        } else if type.contains("dim") {
            return [(0, 0), (2, 3), (4, 6)]
        } else if type.contains("m7b5") {
            return [(0, 0), (2, 3), (4, 6), (6, 10)]
        } else if type.contains("7(b9)") || type.contains("7b9") {
            return [(0, 0), (2, 4), (4, 7), (6, 10), (8, 13)]
        } else if type.contains("7sus4") {
            return [(0, 0), (3, 5), (4, 7), (6, 10)]
        } else if type.contains("sus4") {
            return [(0, 0), (3, 5), (4, 7)]
        } else if type.contains("maj9") {
            return [(0, 0), (2, 4), (4, 7), (6, 11), (8, 14)]
        } else if type.contains("m9") {
            return [(0, 0), (2, 3), (4, 7), (6, 10), (8, 14)]
        } else if type.contains("m11") {
            return [(0, 0), (2, 3), (4, 7), (6, 10), (10, 17)]
        } else if type.contains("add9") {
            return [(0, 0), (2, 4), (4, 7), (8, 14)]
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

    private func diatonicIndexForNote(_ noteName: String) -> Int {
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

    // MARK: - 五線譜音符提供

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

        return formulas.map { formula in
            let calculatedStep = rootBaseStep + formula.stepOffset
            let targetDIndex = ((rootDIndex + formula.stepOffset) % 7 + 7) % 7
            let letterName = diatonicLetters[targetDIndex]
            let naturalSemitone = diatonicNaturalSemitones[targetDIndex]
            let actualSemitone = ((rootSemitone + formula.semitoneOffset) % 12 + 12) % 12

            let diff = ((actualSemitone - naturalSemitone) % 12 + 12) % 12
            let accidental: String?
            let noteName: String

            switch diff {
            case 0:
                accidental = nil
                noteName = letterName
            case 1:
                accidental = "♯"
                noteName = "\(letterName)♯"
            case 2:
                accidental = "𝄪"
                noteName = "\(letterName)𝄪"
            case 11:
                accidental = "♭"
                noteName = "\(letterName)♭"
            case 10:
                accidental = "♭♭"
                noteName = "\(letterName)♭♭"
            default:
                accidental = nil
                noteName = letterName
            }

            return StaffNote(name: noteName, accidental: accidental, step: calculatedStep)
        }
    }

    /*
    音名から五線譜の基準ステップ（E4 = 0）を計算する。
    
    Arguments:
    noteName
      音名文字列（例: "C", "D", "G"）。
    
    Usage:
    外部や互換性のために保持されるルートステップ算出関数。
    */
    
    private func stepForNote(_ noteName: String) -> Int {
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
    
    private func labelForStep(_ step: Int) -> String {
        let noteOrder = ["E", "F", "G", "A", "B", "C", "D"]
        let index = ((step % 7) + 7) % 7
        return noteOrder[index]
    }

    /*
    指定されたコードの構成音をMIDIノート番号（UInt8）の配列として取得する。
    
    Arguments:
    chord
      MIDIノートを算出するChordオブジェクト。
    
    Usage:
    ピアノ音源での和音試聴・プレビュー再生に使用される。
    */

    func chordMidiNotes(for chord: Chord) -> [UInt8] {
        let rootSemitone = Key.semitone(forNoteName: chord.rootNote)
        let baseMidi: Int = (rootSemitone >= 7) ? (48 + rootSemitone) : (60 + rootSemitone)
        let formulas = chordToneFormulas(for: chord.type)
        let intervals = formulas.map { $0.semitoneOffset }

        var notes = intervals.compactMap { interval -> UInt8? in
            let noteVal = baseMidi + interval
            return (noteVal >= 0 && noteVal <= 127) ? UInt8(noteVal) : nil
        }

        if let bass = chord.bassNote, !bass.isEmpty {
            let bassSemitone = Key.semitone(forNoteName: bass)
            let bassMidi = 36 + bassSemitone
            if bassMidi >= 0 && bassMidi <= 127 {
                let uBass = UInt8(bassMidi)
                if !notes.contains(uBass) {
                    notes.insert(uBass, at: 0)
                }
            }
        }

        return notes
    }
}
