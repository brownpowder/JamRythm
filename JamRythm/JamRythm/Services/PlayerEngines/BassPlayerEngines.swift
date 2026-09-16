//
//  BassPlayerEngines.swift
//  JamRythm
//

import Foundation

class BaseBassPlayerEngine: BassPlayerEngine {
    var velocityHumanizeRange: Int { return 2 }
    
    func evaluate(step: Int, rootNote: UInt8?, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        guard let root = rootNote else { return [] }
        let variation = (context.songLoopCount + context.phraseIndex) % 3
        
        // フィルイン
        if context.isFillTiming && step >= 4 {
            if let fill = signatureFill(root: root, genre: genre, variation: variation, step: step, context: context) {
                return applyHumanize(events: fill)
            }
        }
        
        let baseEvents = pattern(for: genre, variation: variation, step: step, root: root, context: context)
        return applyHumanize(events: baseEvents)
    }
    
    func pattern(for genre: MusicGenre, variation: Int, step: Int, root: UInt8, context: PlayerContext) -> [NoteEvent] {
        return basicBassPattern(genre: genre, step: step, root: root)
    }
    
    func signatureFill(root: UInt8, genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent]? {
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


class RhythmMachineBassist: BassPlayerEngine {
    func evaluate(step: Int, rootNote: UInt8?, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        return basicBassPattern(genre: genre, step: step, root: rootNote)
    }
}

class StandardBassist: BassPlayerEngine {
    func evaluate(step: Int, rootNote: UInt8?, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        guard let root = rootNote else { return [] }
        var notes = [NoteEvent]()
        
        switch context.sectionType {
        case .intro:
            if step == 0 { notes.append(NoteEvent(note: root, velocity: 80)) }
            return notes
        case .verseA:
            if step == 0 { notes.append(NoteEvent(note: root, velocity: 90)) }
            return notes
        default:
            break
        }
        
        return basicBassPattern(genre: genre, step: step, root: root)
    }
}

class KRBassist: BaseBassPlayerEngine {
    override var velocityHumanizeRange: Int { return 4 }
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, root: UInt8, context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        switch genre {
        case .rock, .pop:
            // ルート弾き主体のパンクスタイル
            if variation == 0 {
                events.append(NoteEvent(note: root, velocity: 110)) // 全ステップ弾く
            } else if variation == 1 {
                events.append(NoteEvent(note: root, velocity: step % 2 == 0 ? 115 : 90))
            } else {
                if step % 2 == 0 { events.append(NoteEvent(note: root, velocity: 115)) }
                if step == 3 || step == 7 { events.append(NoteEvent(note: root + 12, velocity: 100)) } // オクターブ上
            }
        default:
            if variation == 0 {
                if step % 2 == 0 { events.append(NoteEvent(note: root, velocity: 105)) }
            } else {
                events.append(NoteEvent(note: root, velocity: step % 2 == 0 ? 110 : 85))
            }
        }
        return events
    }
    
    override func signatureFill(root: UInt8, genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent]? {
        // グリスダウンや激しいアプローチ
        if step == 4 { return [NoteEvent(note: root + 12, velocity: 120)] }
        if step == 5 { return [NoteEvent(note: root + 10, velocity: 110)] }
        if step == 6 { return [NoteEvent(note: root + 7, velocity: 110)] }
        if step == 7 { return [NoteEvent(note: root + 5, velocity: 110)] }
        return nil
    }
}

class AkikoBassist: BaseBassPlayerEngine {
    override var velocityHumanizeRange: Int { return 4 }
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, root: UInt8, context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        switch genre {
        case .lofi, .rAndB:
            // ネオソウル的なアプローチ
            if variation == 0 {
                if step == 0 { events.append(NoteEvent(note: root, velocity: 95)) }
                if step == 6 { events.append(NoteEvent(note: root + 7, velocity: 85)) } // 5度
            } else if variation == 1 {
                if step == 0 { events.append(NoteEvent(note: root, velocity: 95)) }
                if step == 3 { events.append(NoteEvent(note: root + 10, velocity: 80)) } // m7
                if step == 5 { events.append(NoteEvent(note: root + 7, velocity: 85)) }
            } else {
                if step == 0 { events.append(NoteEvent(note: root, velocity: 90)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: root + 12, velocity: 75)) } // オクターブ上
            }
        default:
            if variation == 0 {
                if step == 0 { events.append(NoteEvent(note: root, velocity: 95)) }
                if step == 4 { events.append(NoteEvent(note: root + 7, velocity: 85)) }
            } else {
                if step == 0 || step == 3 { events.append(NoteEvent(note: root, velocity: 95)) }
                if step == 6 { events.append(NoteEvent(note: root + 5, velocity: 85)) }
            }
        }
        return events
    }
    
    override func signatureFill(root: UInt8, genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent]? {
        // メロディアスなフィル
        if step == 6 { return [NoteEvent(note: root + 10, velocity: 90)] }
        if step == 7 { return [NoteEvent(note: root + 14, velocity: 90)] } // 9th
        return []
    }
}

private func basicBassPattern(genre: MusicGenre, step: Int, root: UInt8?) -> [NoteEvent] {
    guard let root = root else { return [] }
    var notes = [NoteEvent]()
    
    switch genre {
    case .pop:
        if step == 0 || step == 4 { notes.append(NoteEvent(note: root, velocity: 105)) }
    case .rock:
        let vel: UInt8 = (step % 2 == 0) ? 105 : 90
        notes.append(NoteEvent(note: root, velocity: vel))
    case .dance:
        if step % 2 == 0 { notes.append(NoteEvent(note: root, velocity: 105)) }
        else { notes.append(NoteEvent(note: root + 12, velocity: 95)) }
    case .lofi:
        if step == 0 { notes.append(NoteEvent(note: root, velocity: 95)) }
    case .rAndB:
        if step == 0 { notes.append(NoteEvent(note: root, velocity: 105)) }
        else if step == 3 { notes.append(NoteEvent(note: root + 12, velocity: 95)) }
        else if step == 6 { notes.append(NoteEvent(note: root, velocity: 100)) }
    }
    return notes
}


class MarcusBassist: BaseBassPlayerEngine {
    override var velocityHumanizeRange: Int { return 3 }
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, root: UInt8, context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        switch genre {
        case .dance, .pop:
            // スラップ全開
            if variation == 0 {
                if step == 0 || step == 4 { events.append(NoteEvent(note: root, velocity: 120)) } // Slap
                if step == 3 || step == 7 { events.append(NoteEvent(note: root + 12, velocity: 115)) } // Pop
            } else if variation == 1 {
                if step == 0 { events.append(NoteEvent(note: root, velocity: 120)) }
                if step == 2 { events.append(NoteEvent(note: root, velocity: 60)) } // Ghost
                if step == 3 { events.append(NoteEvent(note: root + 12, velocity: 115)) }
                if step == 5 { events.append(NoteEvent(note: root, velocity: 60)) }
                if step == 6 { events.append(NoteEvent(note: root + 10, velocity: 100)) } // b7
            } else {
                if step == 0 { events.append(NoteEvent(note: root, velocity: 120)) }
                if step == 2 || step == 4 { events.append(NoteEvent(note: root + 12, velocity: 115)) }
                if step == 6 { events.append(NoteEvent(note: root + 7, velocity: 100)) }
            }
        default:
            if variation == 0 {
                if step == 0 || step == 3 { events.append(NoteEvent(note: root, velocity: 115)) }
                if step == 6 { events.append(NoteEvent(note: root + 12, velocity: 110)) }
            } else {
                if step == 0 || step == 4 { events.append(NoteEvent(note: root, velocity: 115)) }
                if step == 7 { events.append(NoteEvent(note: root + 12, velocity: 110)) }
            }
        }
        return events
    }
}

class HarutoBassist: BaseBassPlayerEngine {
    override var velocityHumanizeRange: Int { return 2 } // 正確なプレイ
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, root: UInt8, context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        // 正確でメロディックなルート弾き
        if variation == 0 {
            if step == 0 { events.append(NoteEvent(note: root, velocity: 95)) }
            if step == 4 { events.append(NoteEvent(note: root + 7, velocity: 85)) } // 5th
        } else if variation == 1 {
            if step == 0 || step == 3 { events.append(NoteEvent(note: root, velocity: 95)) }
            if step == 6 { events.append(NoteEvent(note: root, velocity: 80)) }
        } else {
            if step == 0 { events.append(NoteEvent(note: root, velocity: 95)) }
            if step == 2 { events.append(NoteEvent(note: root, velocity: 85)) }
            if step == 4 { events.append(NoteEvent(note: root + 7, velocity: 90)) }
            if step == 6 { events.append(NoteEvent(note: root + 5, velocity: 85)) } // 4th
        }
        return events
    }
}