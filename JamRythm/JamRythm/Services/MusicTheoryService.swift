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
    
    
}
