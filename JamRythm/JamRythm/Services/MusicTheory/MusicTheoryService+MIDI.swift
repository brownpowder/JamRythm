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

    func formatVoicedNotes(bass: UInt8, upper: [UInt8]) -> [UInt8] {
        var result = [bass]
        for n in upper where n != bass {
            result.append(n)
        }
        return result
    }

    func centerUpperNotes(_ notes: [Int]) -> [UInt8] {
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

    func generateVoicingCandidates(from baseNotes: [Int]) -> [[UInt8]] {
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

    func selectBestVoicingCandidate(candidates: [[UInt8]], previousUpper: [UInt8]) -> [UInt8] {
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

}
