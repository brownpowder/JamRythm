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
    
    func createSubstituteChords(key: Key, degree: Int) -> [SubstituteCandidate] {
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
    
    func tonicSubstitutePool(key: Key, degree: Int) -> [SubstituteCandidate] {
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
    
    func subdominantAndDominantPool(key: Key, degree: Int) -> [SubstituteCandidate] {
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

    /*
    度数を1〜7の範囲に正規化する。
    
    Arguments:
    degree
      入力された任意の整数度数。
    
    Usage:
    配列インデックスの範囲外アクセスを防ぐために内部で使用される。
    */
    
    func normalizeDegree(_ degree: Int) -> Int {
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
    
    func calculateBassNote(key: Key, degree: Int) -> String {
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
    
    func createStableChord(degree: Int, bassNote: String) -> Chord {
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
    
    func createMelancholyChord(key: Key, degree: Int, bassNote: String) -> Chord {
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
    
    func createStylishChord(key: Key, degree: Int, bassNote: String) -> Chord {
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
    
    func createTensionChord(key: Key, degree: Int, bassNote: String) -> Chord {
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

    /*
    Keyおよび度数に対して、指定ルート音が和声的にどれだけスムーズに調和するかを判定する。

    Arguments:
    root
      判定対象のルート音名（"C", "D", 等）。
    key
      楽曲の基準調。
    baseDegree
      現在の小節の度数（1〜7）。

    Usage:
    ChordCustomizerSheetViewのルート音選択ボタンの背景濃淡表示に利用される。
    */

    func rootCompatibility(root: String, key: Key, baseDegree: Int) -> HarmonicCompatibility {
        let rSemi = Key.semitone(forNoteName: root)
        let relSemi = ((rSemi - key.semitoneOffset) % 12 + 12) % 12

        // ダイアトニック音階の相対半音 [0, 2, 4, 5, 7, 9, 11]
        let diatonicRelSemitones = [0, 2, 4, 5, 7, 9, 11]
        if diatonicRelSemitones.contains(relSemi) {
            return .verySmooth
        }

        // モーダルインターチェンジ / 定番借用和音の根音 (bVI=8, bVII=10, bIII=3)
        if [8, 10, 3].contains(relSemi) {
            return .smooth
        }

        // 裏コード / パッシングディミニッシュ根音 (bII=1, #IV=6)
        if [1, 6].contains(relSemi) {
            return .flavorful
        }

        return .dissonant
    }

    /*
    Key、度数、元のコードに対して、指定コードが和声的にどれだけスムーズに調和するかを判定する。

    Arguments:
    chord
      判定対象のChordオブジェクト。
    key
      楽曲の基準調。
    baseDegree
      現在の小節の度数（1〜7）。
    originalChord
      編集前の元の小節コード。

    Usage:
    ChordCustomizerSheetViewのコードタイプ選択ボタンの濃淡表示やプレビューバッジ表示に利用される。
    */

    /*
    Key、度数、元のコード、次のコードに対して、指定コードが和声的にどれだけスムーズに調和するかを判定する。
    次の小節のコードへのドミナントモーション解決（完全4度上への進行）を考慮する。

    Arguments:
    chord
      判定対象のChordオブジェクト。
    key
      楽曲の基準調。
    baseDegree
      現在の小節の度数（1〜7）。
    originalChord
      編集前の元の小節コード。
    nextChord
      次の小節のコード（セカンダリードミナント等の解決先判定用）。

    Usage:
    ChordCustomizerSheetViewのコードタイプ選択ボタンの濃淡表示やプレビューバッジ表示に利用される。
    */

    func chordCompatibility(
        chord: Chord,
        key: Key,
        baseDegree: Int,
        originalChord: Chord?,
        nextChord: Chord?
    ) -> HarmonicCompatibility {
        if let original = originalChord, chord.rootNote == original.rootNote && chord.type == original.type {
            return .verySmooth
        }

        let rSemi = Key.semitone(forNoteName: chord.rootNote)
        let relSemi = ((rSemi - key.semitoneOffset) % 12 + 12) % 12
        let diatonicRelSemitones = [0, 2, 4, 5, 7, 9, 11]

        var baseScore: HarmonicCompatibility
        if diatonicRelSemitones.contains(relSemi) {
            baseScore = diatonicChordCompatibility(relSemi: relSemi, type: chord.type)
        } else {
            baseScore = borrowedChordCompatibility(relSemi: relSemi, type: chord.type)
        }

        // 次の小節へのドミナントモーション解決判定（完全4度上 = 半音+5）
        baseScore = evaluateDominantResolution(
            chord: chord,
            rootSemi: rSemi,
            currentScore: baseScore,
            nextChord: nextChord
        )

        // オンコード（分数コード）指定時のベース音親和性評価
        if let bass = chord.bassNote, !bass.isEmpty {
            let bSemi = Key.semitone(forNoteName: bass)
            let bRelSemi = ((bSemi - key.semitoneOffset) % 12 + 12) % 12
            if !diatonicRelSemitones.contains(bRelSemi) && baseScore == .verySmooth {
                baseScore = .dramatic
            }
        }

        return baseScore
    }

    /*
    次の小節に対するドミナントモーション解決の成否を評価し、親和性スコアを調整する。

    Arguments:
    chord
      判定対象コード。
    rootSemi
      コード根音の半音番号。
    currentScore
      現在の暫定スコア。
    nextChord
      次の小節のコード。

    Usage:
    chordCompatibility内部でセカンダリードミナントの解決評価に使用される。
    */

    func evaluateDominantResolution(
        chord: Chord,
        rootSemi: Int,
        currentScore: HarmonicCompatibility,
        nextChord: Chord?
    ) -> HarmonicCompatibility {
        guard let next = nextChord else { return currentScore }
        let isDominantType = ["7", "9", "13", "7(b9)", "7(#9)", "7sus4"].contains(chord.type)
        guard isDominantType else { return currentScore }

        let nextRootSemi = Key.semitone(forNoteName: next.rootNote)
        let isDominantResolution = ((rootSemi + 5) % 12 == nextRootSemi)

        if isDominantResolution {
            // 次のコードに綺麗にドミナント解決する場合: 文句なしに最上位の「スムーズ」へ昇格！
            return .verySmooth
        } else if currentScore == .dramatic {
            // ドミナントセブンスなのに解決先がない場合: 唐突さがあるためスパイスに分類
            return .flavorful
        }

        return currentScore
    }

    /*
    ダイアトニック度数上のルート音に対するコードタイプの適合性を判定する。

    Arguments:
    relSemi
      Keyからの相対半音（0, 2, 4, 5, 7, 9, 11）。
    type
      判定対象のコードタイプ名（"", "m", "7", "maj7", 等）。

    Usage:
    chordCompatibility内部でダイアトニック根音のタイプ適合性評価に使用される。
    */

    func diatonicChordCompatibility(relSemi: Int, type: String) -> HarmonicCompatibility {
        switch relSemi {
        case 0: // I (C)
            if ["", "maj7", "6", "add9", "maj9", "sus4", "sus2"].contains(type) { return .verySmooth }
            if ["7", "9", "13", "m", "m7"].contains(type) { return .dramatic }
            return .flavorful

        case 2: // ii (Dm)
            if ["m", "m7", "m9", "m11", "7sus4", "sus4"].contains(type) { return .verySmooth }
            if ["7", "9", "7(#9)", "add9"].contains(type) { return .dramatic }
            return .flavorful

        case 4: // iii (Em)
            if ["m", "m7", "m9", "7sus4"].contains(type) { return .verySmooth }
            if ["7", "7(b9)", "7(#9)"].contains(type) { return .dramatic }
            return .flavorful

        case 5: // IV (F)
            if ["", "maj7", "6", "add9", "maj9", "7(#11)", "sus2"].contains(type) { return .verySmooth }
            if ["m", "m7", "m6"].contains(type) { return .dramatic }
            return .flavorful

        case 7: // V (G)
            if ["", "7", "9", "13", "7sus4", "sus4", "7(b9)", "add9"].contains(type) { return .verySmooth }
            if ["m", "m7"].contains(type) { return .dramatic }
            return .flavorful

        case 9: // vi (Am)
            if ["m", "m7", "m9", "11", "m11", "7sus4", "m6"].contains(type) { return .verySmooth }
            if ["7", "7(b9)", "7(#9)"].contains(type) { return .dramatic }
            return .flavorful

        case 11: // vii° (Bm7b5)
            if ["m7b5", "dim", "dim7"].contains(type) { return .verySmooth }
            if ["7", "7(b9)"].contains(type) { return .dramatic }
            return .flavorful

        default:
            return .flavorful
        }
    }

    /*
    ノンダイアトニック（借用和音・裏コード）上のルート音に対するコードタイプの適合性を判定する。

    Arguments:
    relSemi
      Keyからの相対半音。
    type
      判定対象のコードタイプ名。

    Usage:
    chordCompatibility内部でノンダイアトニック根音のタイプ適合性評価に使用される。
    */

    func borrowedChordCompatibility(relSemi: Int, type: String) -> HarmonicCompatibility {
        switch relSemi {
        case 8: // bVI (Ab)
            if ["", "maj7", "7", "add9", "9"].contains(type) { return .dramatic }
            return .flavorful

        case 10: // bVII (Bb)
            if ["", "7", "9", "add9", "maj7"].contains(type) { return .dramatic }
            return .flavorful

        case 3: // bIII (Eb)
            if ["", "maj7", "add9"].contains(type) { return .dramatic }
            return .flavorful

        case 1: // bII (Db: 裏コード)
            if ["7", "9", "7(#11)"].contains(type) { return .flavorful }
            return .abstract

        case 6: // #IV (F#: パッシング)
            if ["dim", "dim7", "m7b5"].contains(type) { return .flavorful }
            return .abstract

        default:
            return .abstract
        }
    }

}
