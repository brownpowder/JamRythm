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
    case blues = "ブルース"
    case harmonicMinor = "ハーモニックマイナー"
    case melodicMinor = "メロディックマイナー"
    case kumoi = "雲井音階"
    case ryukyu = "琉球音階"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .pentatonic: return "Penta (5音)"
        case .diatonic: return "Diatonic (7音)"
        case .blues: return "Blues (6音)"
        case .harmonicMinor: return "Harmonic Minor"
        case .melodicMinor: return "Melodic Minor"
        case .kumoi: return "Kumoi (5音)"
        case .ryukyu: return "Ryukyu (5音)"
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
    case bass = "4弦 (Bass)"
    case piano = "鍵盤 (Piano)"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .guitar: return "6弦 Guitar"
        case .bass: return "4弦 Bass"
        case .piano: return "鍵盤 Piano"
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
enum HarmonicCompatibility: Int, Comparable, CaseIterable, Identifiable {
    case verySmooth = 3   // 最も濃い: ダイアトニック、完全解決ドミナント（超自然・破綻ゼロ）
    case dramatic = 2     // 中濃: ドラマチック (エモい借用・サブドミナントマイナー・進行のフック)
    case flavorful = 1    // 淡い: スパイス (未解決ドミナント、裏コード、オルタード)
    case abstract = 0     // 通常無色: 挑戦的 (アブストラクト・不協和音)

    var id: Int { rawValue }

    // 既存コード互換エイリアス
    static var smooth: HarmonicCompatibility { .dramatic }
    static var dissonant: HarmonicCompatibility { .abstract }

    static func < (lhs: HarmonicCompatibility, rhs: HarmonicCompatibility) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var badgeText: String {
        switch self {
        case .verySmooth: return "✨ スムーズ (超自然)"
        case .dramatic: return "💜 ドラマチック (エモい)"
        case .flavorful: return "🔥 スパイス (個性派)"
        case .abstract: return "挑戦的 (アブストラクト)"
        }
    }

    var badgeIcon: String {
        switch self {
        case .verySmooth: return "sparkles"
        case .dramatic: return "heart.fill"
        case .flavorful: return "flame.fill"
        case .abstract: return "questionmark"
        }
    }

    var colorOpacity: Double {
        switch self {
        case .verySmooth: return 0.38
        case .dramatic: return 0.20
        case .flavorful: return 0.08
        case .abstract: return 0.0
        }
    }

    var strokeOpacity: Double {
        switch self {
        case .verySmooth: return 0.70
        case .dramatic: return 0.40
        case .flavorful: return 0.20
        case .abstract: return 0.0
        }
    }
}

// MARK: - 音名表記モード（英語 CDE ⇔ 日本語 ドレミ）

/*
譜面やバッジ等で音名を表示する際の表記体系。
英語圏では C, D, E が標準であり、日本語環境でのみ親しみやすい「ド, レ, ミ」への切替をサポートする。
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
protocol MusicTheoryServiceProtocol {
    /*
    指定されたKeyとベース度数に対して、指定ルート音が和声的にどれだけスムーズに調和するかを判定する。
    
    Arguments:
    root
      判定対象のルート音名（"C", "D", 等）。
    key
      基準調。
    baseDegree
      現在の小節の度数（1〜7）。
    
    Usage:
    ChordCustomizerSheetViewのルート音グリッドの濃淡表示に利用される。
    */
    func rootCompatibility(root: String, key: Key, baseDegree: Int) -> HarmonicCompatibility

    /*
    指定されたKey、ベース度数、元のコード、次の小節コードに対して、指定コードが和声的にどれだけスムーズに調和するかを判定する。
    
    Arguments:
    chord
      判定対象のChordオブジェクト。
    key
      基準調。
    baseDegree
      現在の小節の度数（1〜7）。
    originalChord
      編集前の元の小節コード。
    nextChord
      次の小節のコード（セカンダリードミナント等の解決先判定用）。
    
    Usage:
    ChordCustomizerSheetViewのコードタイプボタンの濃淡表示やプレビューバッジ表示に利用される。
    */
    func chordCompatibility(
        chord: Chord,
        key: Key,
        baseDegree: Int,
        originalChord: Chord?,
        nextChord: Chord?
    ) -> HarmonicCompatibility

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
    指定されたコードに対して、複数のギターボイシング（ローコード、5弦ルート、6弦ルート等）の候補配列を取得する。

    Arguments:
    chord
      対象のChordオブジェクト。

    Usage:
    GuitarTabViewで複数の押さえ方を切り替えて表示するために呼び出される。
    */

    func guitarVoicings(for chord: Chord) -> [GuitarVoicing]

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

    /*
    直前のコード構成音（previousNotes）を踏まえ、声部移動量を最小化するスムーズな転回形ボイシングを算出して返す。

    Arguments:
    chord
      発音対象のChordオブジェクト。
    previousNotes
      直前に発音されていたMIDIノート配列（初回またはリセット時はnil）。

    Usage:
    AudioServiceの自動伴奏ループ再生でピアノ伴奏を滑らかに連結するために呼び出される。
    */

    func voiceLedMidiNotes(for chord: Chord, previousNotes: [UInt8]?) -> [UInt8]

    /*
    Key、小節コード、スケール種別、および基準モード（Chord基準/Key基準）から指板表示用スケール情報を算出する。

    Arguments:
    key
      基準調（Key.C等）。プロジェクト設定から渡される。
    chord
      現在選択中の小節コード。ルート音やコードトーン判定に使用される。
    scaleType
      ペンタトニックまたはダイアトニック。Picker選択値から渡される。
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
    ) -> ScaleInfo
}

// MARK: - プロトコルデフォルト実装

extension MusicTheoryServiceProtocol {
    /*
    referenceModeを省略した場合にKey基準（マイナーペンタ基本＋不適合時コード追従）を渡す互換デフォルト実装。
    */
    func scaleInfo(for key: Key, chord: Chord, scaleType: ScaleType) -> ScaleInfo {
        return scaleInfo(for: key, chord: chord, scaleType: scaleType, referenceMode: .key)
    }
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

    /*
    nextChordを省略した場合にnilを渡す互換デフォルト実装。

    Arguments:
    chord
      Chordオブジェクト。
    key
      基準調。
    baseDegree
      現在の小節の度数。
    originalChord
      編集前の元の小節コード。

    Usage:
    次の小節を参照しない簡易呼び出しで使用される。
    */

    func chordCompatibility(
        chord: Chord,
        key: Key,
        baseDegree: Int,
        originalChord: Chord?
    ) -> HarmonicCompatibility {
        return chordCompatibility(
            chord: chord,
            key: key,
            baseDegree: baseDegree,
            originalChord: originalChord,
            nextChord: nil
        )
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

    private func calculateBaseFret(for frets: [Int?]) -> Int {
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
    
    private func specialOnChordVoicing(for chord: Chord) -> GuitarVoicing? {
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

    private func barreVoicing(for chord: Chord) -> GuitarVoicing? {
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

    private func barreVoicingString5(fret f: Int, type: String) -> GuitarVoicing {
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

    private func barreVoicingString6(fret f: Int, type: String) -> GuitarVoicing {
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
    
    private func createBassStaffNote(bassNote: String, lowestChordStep: Int) -> StaffNote {
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

    // MARK: - ピアノ・ボイスリーディング

    /*
    直前のコード構成音（previousNotes）を踏まえ、声部移動量を最小化するスムーズな転回形ボイシングを算出して返す。
    コード進行が変わる際に共通音を保持し、音の跳躍を防いで洗練された伴奏演奏を実現する。

    Arguments:
    chord
      発音対象のChordオブジェクト。
    previousNotes
      直前に発音されていたMIDIノート配列（初回またはリセット時はnil）。

    Usage:
    AudioServiceの自動伴奏ループ再生でピアノ伴奏を滑らかに連結するために呼び出される。
    */

    func voiceLedMidiNotes(for chord: Chord, previousNotes: [UInt8]?) -> [UInt8] {
        let rootSemitone = Key.semitone(forNoteName: chord.rootNote)
        let formulas = chordToneFormulas(for: chord.type)
        let chordToneOffsets = formulas.map { $0.semitoneOffset }

        // 1. 低音ベースノート（MIDI 36〜47 / C2〜B2）
        let bassSemitone = (chord.bassNote?.isEmpty == false) ? Key.semitone(forNoteName: chord.bassNote!) : rootSemitone
        let bassMidi = UInt8(36 + bassSemitone)

        // 2. 右手コード音（C4オクターブ: 60基準）
        let baseRootMidi = 60 + rootSemitone
        let rawUpperNotes = chordToneOffsets.map { baseRootMidi + $0 }

        // 前の音がない場合: 中心（MIDI 60〜76）に収まるよう調整した基本ボイシング
        guard let prev = previousNotes, !prev.isEmpty else {
            return formatVoicedNotes(bass: bassMidi, upper: centerUpperNotes(rawUpperNotes))
        }

        // 前の音の上声部（右手パート: 50以上）を抽出
        let prevUpper = prev.filter { $0 >= 50 }
        guard !prevUpper.isEmpty else {
            return formatVoicedNotes(bass: bassMidi, upper: centerUpperNotes(rawUpperNotes))
        }

        // 3. 転回形候補の中から、前音との移動コストが最も小さいものを選択
        let candidates = generateVoicingCandidates(from: rawUpperNotes)
        let bestUpper = selectBestVoicingCandidate(candidates: candidates, previousUpper: prevUpper)

        return formatVoicedNotes(bass: bassMidi, upper: bestUpper)
    }

    private func formatVoicedNotes(bass: UInt8, upper: [UInt8]) -> [UInt8] {
        var result = [bass]
        for n in upper where n != bass {
            result.append(n)
        }
        return result
    }

    private func centerUpperNotes(_ notes: [Int]) -> [UInt8] {
        var current = notes
        let avg = current.reduce(0, +) / max(1, current.count)
        if avg < 60 {
            current = current.map { $0 + 12 }
        } else if avg > 76 {
            current = current.map { $0 - 12 }
        }
        return current.compactMap { (n: Int) -> UInt8? in
            (n >= 0 && n <= 127) ? UInt8(n) : nil
        }
    }

    private func generateVoicingCandidates(from baseNotes: [Int]) -> [[UInt8]] {
        var results: [[UInt8]] = []
        let n = baseNotes.count
        guard n > 0 else { return results }

        // 各種転回形（Inversions）× オクターブシフト (-12, 0, +12)
        for octaveShift in [-12, 0, 12] {
            let shifted = baseNotes.map { $0 + octaveShift }
            for inv in 0..<n {
                var candidate: [Int] = []
                for i in 0..<n {
                    candidate.append(i < inv ? shifted[i] + 12 : shifted[i])
                }
                candidate.sort()
                let uNotes = candidate.compactMap { ($0 >= 48 && $0 <= 88) ? UInt8($0) : nil }
                if uNotes.count == n {
                    results.append(uNotes)
                }
            }
        }
        return results.isEmpty ? [baseNotes.map { UInt8(clamping: $0) }] : results
    }

    private func selectBestVoicingCandidate(candidates: [[UInt8]], previousUpper: [UInt8]) -> [UInt8] {
        var bestCandidate = candidates.first ?? []
        var bestScore = Double.infinity

        for cand in candidates {
            // 声部移動コスト（前の音との最短距離の合計）
            var movementCost: Double = 0.0
            for c in cand {
                let minDistance = previousUpper.map { abs(Int(c) - Int($0)) }.min() ?? 12
                movementCost += Double(minDistance)
                if minDistance == 0 {
                    movementCost -= 2.5 // 共通音キープのボーナス
                }
            }

            // 音域ペナルティ（MIDI 56〜78 / G#3〜F#5 の範囲から外れるとペナルティ）
            let avgPitch = Double(cand.reduce(0) { $0 + Int($1) }) / Double(max(1, cand.count))
            let idealPitch = 66.0
            let rangePenalty = abs(avgPitch - idealPitch) * 0.8

            let totalScore = movementCost + rangePenalty
            if totalScore < bestScore {
                bestScore = totalScore
                bestCandidate = cand
            }
        }

        return bestCandidate
    }

    // MARK: - スケール情報算出

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
            let result = calculateChordScaleSemitonesAndName(chord: chord, scaleType: scaleType)
            semitones = result.semitones
            scaleName = result.name
        case .key:
            if scaleType == .pentatonic {
                if isChordCompatibleWithMinorPenta(chord: chord, key: key) {
                    let minorPenta = relativeMinorPentatonic(for: key)
                    semitones = minorPenta.semitones
                    scaleName = minorPenta.name
                } else {
                    let result = calculateChordScaleSemitonesAndName(chord: chord, scaleType: .diatonic)
                    semitones = result.semitones
                    scaleName = result.name
                }
            } else if scaleType == .blues {
                if isChordCompatibleWithMinorPenta(chord: chord, key: key) {
                    // Keyのマイナーブルース
                    let relMinor = relativeMinorPentatonic(for: key)
                    let rootSemitone = relMinor.semitones[0]
                    semitones = [0, 3, 5, 6, 7, 10].map { (rootSemitone + $0) % 12 }
                    scaleName = "\(Key.noteName(forSemitone: rootSemitone)) マイナーブルース"
                } else {
                    let result = calculateChordScaleSemitonesAndName(chord: chord, scaleType: .blues)
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
        return (semitones, "\(minorRootName) マイナーペンタ")
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

    private func calculateKeyScaleSemitonesAndName(
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
        case .blues:
            offsets = [0, 3, 4, 7, 9, 10]
            typeName = "メジャーブルース"
        case .harmonicMinor:
            offsets = [0, 2, 3, 5, 7, 8, 11]
            typeName = "ハーモニックマイナー"
        case .melodicMinor:
            offsets = [0, 2, 3, 5, 7, 9, 11]
            typeName = "メロディックマイナー"
        case .kumoi:
            offsets = [0, 1, 5, 7, 8]
            typeName = "雲井音階"
        case .ryukyu:
            offsets = [0, 4, 5, 7, 11]
            typeName = "琉球音階"
        }

        let semitones = offsets.map { (key.semitoneOffset + $0) % 12 }
        return (semitones, "\(key.rawValue) \(typeName)")
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

    private func calculateChordScaleSemitonesAndName(
        chord: Chord,
        scaleType: ScaleType
    ) -> (semitones: [Int], name: String) {
        let rootSemitone = Key.semitone(forNoteName: chord.rootNote)
        
        switch scaleType {
        case .blues:
            let isMinor = chord.type.hasPrefix("m") && !chord.type.hasPrefix("maj")
            let offsets = isMinor ? [0, 3, 5, 6, 7, 10] : [0, 3, 4, 7, 9, 10]
            let modeName = isMinor ? "マイナーブルース" : "メジャーブルース"
            let semitones = offsets.map { (rootSemitone + $0) % 12 }
            return (semitones, "\(chord.rootNote) \(modeName)")
        case .harmonicMinor:
            let offsets = [0, 2, 3, 5, 7, 8, 11]
            let semitones = offsets.map { (rootSemitone + $0) % 12 }
            return (semitones, "\(chord.rootNote) ハーモニックマイナー")
        case .melodicMinor:
            let offsets = [0, 2, 3, 5, 7, 9, 11]
            let semitones = offsets.map { (rootSemitone + $0) % 12 }
            return (semitones, "\(chord.rootNote) メロディックマイナー")
        case .kumoi:
            let offsets = [0, 1, 5, 7, 8]
            let semitones = offsets.map { (rootSemitone + $0) % 12 }
            return (semitones, "\(chord.rootNote) 雲井音階")
        case .ryukyu:
            let offsets = [0, 4, 5, 7, 11]
            let semitones = offsets.map { (rootSemitone + $0) % 12 }
            return (semitones, "\(chord.rootNote) 琉球音階")
        default:
            let mode = chordScaleMode(for: chord.type)
            let offsets = (scaleType == .pentatonic) ? mode.pentaOffsets : mode.diatonicOffsets
            let modeName = (scaleType == .pentatonic) ? mode.pentaName : mode.diatonicName
            let semitones = offsets.map { (rootSemitone + $0) % 12 }
            return (semitones, "\(chord.rootNote) \(modeName)")
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

    private func chordScaleMode(
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

    private func calculateScalePositions(
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

    // MARK: - 和声的親和性（スムーズ度）判定

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

    private func evaluateDominantResolution(
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

    private func diatonicChordCompatibility(relSemi: Int, type: String) -> HarmonicCompatibility {
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

    private func borrowedChordCompatibility(relSemi: Int, type: String) -> HarmonicCompatibility {
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

