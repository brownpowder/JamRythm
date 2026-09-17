//
//  PianoPlayerEngines.swift
//  JamRythm
//

import Foundation

class BasePianoPlayerEngine: PianoPlayerEngine {
    var velocityHumanizeRange: Int { return 2 }
    
    func evaluate(step: Int, chordNotes: [UInt8], context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        guard !chordNotes.isEmpty else { return [] }
        let variation = (context.songLoopCount + context.phraseIndex) % 3
        
        // フィルイン
        if context.isFillTiming && step >= 6 {
            if let fill = signatureFill(chordNotes: chordNotes, genre: genre, variation: variation, step: step, context: context) {
                return applyHumanize(events: fill)
            }
        }
        
        let baseEvents = pattern(for: genre, variation: variation, step: step, chordNotes: chordNotes, context: context)
        return applyHumanize(events: baseEvents)
    }
    
    func pattern(for genre: MusicGenre, variation: Int, step: Int, chordNotes: [UInt8], context: PlayerContext) -> [NoteEvent] {
        // デフォルトパターン（スタンダードピアノと同じ）
        var notes = [NoteEvent]()
        if step == 0 {
            for note in chordNotes { notes.append(NoteEvent(note: note, velocity: 85)) }
        }
        return notes
    }
    
    func signatureFill(chordNotes: [UInt8], genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent]? {
        return nil
    }
    
    private func applyHumanize(events: [NoteEvent]) -> [NoteEvent] {
        guard velocityHumanizeRange > 0 else { return events }
        return events.map { event in
            let drift = Int.random(in: -velocityHumanizeRange...velocityHumanizeRange)
            let newVel = UInt8(max(1, min(127, Int(event.velocity) + drift)))
            return NoteEvent(note: event.note, velocity: newVel)
        }
    }
}


class RhythmMachinePianist: PianoPlayerEngine {
    func evaluate(step: Int, chordNotes: [UInt8], context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        if step == 0 {
            return chordNotes.map { NoteEvent(note: $0, velocity: 80) }
        }
        return []
    }
}

class StandardPianist: PianoPlayerEngine {
    func evaluate(step: Int, chordNotes: [UInt8], context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        var notes = [NoteEvent]()
        switch context.sectionType {
        case .intro:
            if step == 0 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 70) } }
        case .verseA:
            if step == 0 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 75) } }
        case .verseB, .bridge:
            if step == 0 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 85) } }
        case .chorus, .outro:
            if step == 0 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 95) } }
            if step == 6 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 85, isShortRelease: true) } }
        }
        return notes
    }
}

class EmiPianist: BasePianoPlayerEngine {
    override var velocityHumanizeRange: Int { return 3 }
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, chordNotes: [UInt8], context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        switch genre {
        case .pop, .dance:
            if variation == 0 {
                if step % 4 == 0 {
                    for note in chordNotes { events.append(NoteEvent(note: note, velocity: 85)) }
                }
            } else if variation == 1 {
                if step == 0 || step == 3 {
                    for note in chordNotes { events.append(NoteEvent(note: note, velocity: 85)) }
                }
            } else {
                if step == 2 || step == 6 {
                    for note in chordNotes { events.append(NoteEvent(note: note, velocity: 80)) } // 裏打ち
                }
            }
        default:
            if variation == 0 {
                if step % 4 == 0 {
                    for note in chordNotes { events.append(NoteEvent(note: note, velocity: 80)) }
                }
            } else {
                if step == 0 {
                    for note in chordNotes { events.append(NoteEvent(note: note, velocity: 85)) }
                }
            }
        }
        return events
    }
}

class JazzCatPianist: BasePianoPlayerEngine {
    override var velocityHumanizeRange: Int { return 3 } // ジャズ特有の強弱
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, chordNotes: [UInt8], context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        // コンピング（シンコペーション）主体
        if variation == 0 {
            if step == 3 || step == 6 {
                for note in chordNotes { events.append(NoteEvent(note: note, velocity: 85)) }
            }
        } else if variation == 1 {
            if step == 2 || step == 5 {
                for note in chordNotes { events.append(NoteEvent(note: note, velocity: 80)) }
            }
        } else {
            if step == 0 {
                for note in chordNotes { events.append(NoteEvent(note: note, velocity: 90)) }
            }
            if step == 4 {
                for note in chordNotes { events.append(NoteEvent(note: note, velocity: 70)) }
            }
        }
        return events
    }
}


class RayPianist: BasePianoPlayerEngine {
    override var velocityHumanizeRange: Int { return 4 }
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, chordNotes: [UInt8], context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        switch genre {
        case .lofi, .rAndB:
            if variation == 0 {
                if step == 2 || step == 6 { // 裏打ちチョップ
                    for note in chordNotes { events.append(NoteEvent(note: note, velocity: 90)) }
                }
            } else if variation == 1 {
                if step == 2 {
                    for note in chordNotes { events.append(NoteEvent(note: note, velocity: 90)) }
                } else if step == 5 || step == 6 {
                    for note in chordNotes { events.append(NoteEvent(note: note, velocity: 85)) }
                }
            } else {
                if step == 0 || step == 3 {
                    for note in chordNotes { events.append(NoteEvent(note: note, velocity: 85)) }
                }
            }
        default:
            if variation == 0 {
                if step == 2 || step == 6 {
                    for note in chordNotes { events.append(NoteEvent(note: note, velocity: 90)) }
                }
            } else {
                if step % 4 == 0 {
                    for note in chordNotes { events.append(NoteEvent(note: note, velocity: 80)) }
                }
            }
        }
        return events
    }
}

class ClaraPianist: BasePianoPlayerEngine {
    override var velocityHumanizeRange: Int { return 3 }
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, chordNotes: [UInt8], context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        guard chordNotes.count > 1 else { return [] }
        
        let bassNote = chordNotes[0]
        let upperNotes = Array(chordNotes.dropFirst())
        
        // ステップ0ではベース音を鳴らす（重厚感を出すため）
        if step == 0 {
            events.append(NoteEvent(note: bassNote, velocity: 90))
        }
        
        // クラシック的な分散和音（アルペジオ）は上声部（右手）のみで行う
        if variation == 0 {
            let idx = step % upperNotes.count
            events.append(NoteEvent(note: upperNotes[idx], velocity: 85))
        } else if variation == 1 {
            let idx = (upperNotes.count - 1) - (step % upperNotes.count)
            events.append(NoteEvent(note: upperNotes[max(0, idx)], velocity: 85))
        } else {
            let pattern = [0, 2, 1, 2, 0, 2, 1, 2]
            let nIdx = pattern[step % 8] % upperNotes.count
            events.append(NoteEvent(note: upperNotes[nIdx], velocity: 80))
        }
        return events
    }
}