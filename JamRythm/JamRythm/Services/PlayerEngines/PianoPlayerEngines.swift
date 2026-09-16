//
//  PianoPlayerEngines.swift
//  JamRythm
//

import Foundation

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

class EmiPianist: PianoPlayerEngine {
    func evaluate(step: Int, chordNotes: [UInt8], context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        var notes = [NoteEvent]()
        
        if context.sectionType == .intro {
            if step == 0 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 75) } }
            return notes
        }
        
        let seed = context.songLoopCount + context.phraseIndex
        let variation = seed % 2

        switch context.sectionType {
        case .verseA:
            if step == 0 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 80) } }
        case .verseB:
            if variation == 0 {
                if step == 2 || step == 6 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 85, isShortRelease: true) } }
            } else {
                if step == 3 || step == 6 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 85, isShortRelease: true) } }
            }
        case .chorus:
            if variation == 0 {
                if step == 0 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 100) } }
                if step == 3 || step == 6 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 90, isShortRelease: true) } }
            } else {
                if step == 0 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 100) } }
                if step == 4 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 95) } }
                if step == 7 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 85, isShortRelease: true) } }
            }
        default:
            if step == 0 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 85) } }
        }
        return notes
    }
}

class JazzCatPianist: PianoPlayerEngine {
    func evaluate(step: Int, chordNotes: [UInt8], context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        var notes = [NoteEvent]()
        
        if context.sectionType == .intro {
            if step == 0 { notes = chordNotes.map { NoteEvent(note: $0, velocity: 70) } }
            return notes
        }

        let seed = context.songLoopCount + context.phraseIndex
        let syncopation = seed % 3
        
        if step == 0 {
            if syncopation != 0 {
                notes = chordNotes.map { NoteEvent(note: $0, velocity: 85) }
            }
        } else if step == 3 {
            if syncopation == 0 {
                notes = chordNotes.map { NoteEvent(note: $0, velocity: 90, isShortRelease: true) }
            }
        } else if step == 5 {
            notes = chordNotes.map { NoteEvent(note: $0, velocity: 80, isShortRelease: true) }
        } else if step == 7 {
            if context.isLastMeasure {
                notes = chordNotes.map { NoteEvent(note: $0, velocity: 95) }
            }
        }
        
        return notes
    }
}


class RayPianist: PianoPlayerEngine {
    func evaluate(step: Int, chordNotes: [UInt8], context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        var events = [NoteEvent]()
        let variation = (context.songLoopCount + context.phraseIndex) % 2
        
        if variation == 0 {
            if step == 2 || step == 6 { // Offbeats (Reggae chop)
                for note in chordNotes {
                    events.append(NoteEvent(note: note, velocity: 90))
                }
            }
        } else {
            if step == 2 {
                for note in chordNotes { events.append(NoteEvent(note: note, velocity: 90)) }
            } else if step == 5 || step == 6 {
                // syncopated
                for note in chordNotes { events.append(NoteEvent(note: note, velocity: 85)) }
            }
        }
        return events
    }
}

class ClaraPianist: PianoPlayerEngine {
    func evaluate(step: Int, chordNotes: [UInt8], context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        var events = [NoteEvent]()
        guard !chordNotes.isEmpty else { return [] }
        let variation = (context.songLoopCount + context.phraseIndex) % 3
        
        if variation == 0 {
            // Ascending arpeggio
            let idx = step % chordNotes.count
            events.append(NoteEvent(note: chordNotes[idx], velocity: 85))
        } else if variation == 1 {
            // Descending arpeggio
            let idx = (chordNotes.count - 1) - (step % chordNotes.count)
            events.append(NoteEvent(note: chordNotes[max(0, idx)], velocity: 85))
        } else {
            // Alberti-like
            let pattern = [0, 2, 1, 2, 0, 2, 1, 2]
            let nIdx = pattern[step % 8] % chordNotes.count
            events.append(NoteEvent(note: chordNotes[nIdx], velocity: 80))
        }
        
        return events
    }
}