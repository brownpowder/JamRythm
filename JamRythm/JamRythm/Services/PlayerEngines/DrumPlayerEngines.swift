//
//  DrumPlayerEngines.swift
//  JamRythm
//

import Foundation

class RhythmMachineDrummer: DrumPlayerEngine {
    func evaluate(step: Int, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        return basicGenrePattern(genre: genre, step: step)
    }
}

class StandardDrummer: DrumPlayerEngine {
    func evaluate(step: Int, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        var notes = [NoteEvent]()
        
        if context.sectionType == .intro {
            if context.isLastMeasure && step >= 4 {
                notes.append(NoteEvent(note: 38, velocity: 95))
                if step == 7 { notes.append(NoteEvent(note: 47, velocity: 90)) }
            }
            return notes
        }
        
        if context.isFillTiming && context.sectionType != .chorus && step >= 6 {
            notes.append(NoteEvent(note: 38, velocity: 105))
            return notes
        }
        
        if step == 0 && context.isFirstMeasure && (context.sectionType == .chorus || context.sectionType == .verseA) {
            notes.append(NoteEvent(note: 49, velocity: 110))
            notes.append(NoteEvent(note: 36, velocity: 115))
        }
        
        notes.append(contentsOf: basicGenrePattern(genre: genre, step: step))
        return notes
    }
}

class MarkDrummer: DrumPlayerEngine {
    func evaluate(step: Int, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        var notes = [NoteEvent]()
        
        if context.sectionType == .intro {
            if context.isLastMeasure && step >= 4 {
                notes.append(NoteEvent(note: 38, velocity: UInt8(80 + (step - 4) * 10)))
            }
            return notes
        }

        let isFill = context.isFillTiming
        if isFill && step >= 4 {
            let seed = context.songLoopCount + context.phraseIndex
            let fillType = seed % 3
            if fillType == 0 {
                switch step {
                case 4: notes.append(NoteEvent(note: 48, velocity: 110))
                case 5: notes.append(NoteEvent(note: 47, velocity: 110))
                case 6: notes.append(NoteEvent(note: 45, velocity: 110))
                case 7: notes.append(NoteEvent(note: 43, velocity: 115))
                default: break
                }
            } else if fillType == 1 {
                notes.append(NoteEvent(note: 38, velocity: UInt8(80 + (step - 4) * 10)))
            } else {
                if step == 4 || step == 7 {
                    notes.append(NoteEvent(note: 36, velocity: 115))
                    notes.append(NoteEvent(note: 49, velocity: 110))
                } else if step == 6 {
                    notes.append(NoteEvent(note: 38, velocity: 120))
                }
            }
            return notes
        }
        
        if step == 0 && (context.isFirstMeasure || context.sectionType == .chorus) {
            notes.append(NoteEvent(note: 49, velocity: 120))
            notes.append(NoteEvent(note: 36, velocity: 120))
            return notes
        }
        
        // Groove Variation based on loopCount
        let grooveSeed = context.songLoopCount % 2
        
        let hiHatVelocity: UInt8 = (step % 2 == 0) ? 110 : 90
        let hatNote: UInt8 = context.sectionType == .chorus ? 51 : 42
        
        if grooveSeed == 1 && context.sectionType == .chorus && step == 3 {
            // ブレイク（休符）のバリエーション
            return notes
        }
        
        notes.append(NoteEvent(note: hatNote, velocity: hiHatVelocity))

        switch step {
        case 0, 4:
            notes.append(NoteEvent(note: 36, velocity: 115))
        case 2, 6:
            notes.append(NoteEvent(note: 38, velocity: 120))
        case 3:
            notes.append(NoteEvent(note: 38, velocity: 70))
        default:
            break
        }
        
        return notes
    }
}

class LeoDrummer: DrumPlayerEngine {
    func evaluate(step: Int, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        var notes = [NoteEvent]()
        
        if context.sectionType == .intro {
            if step % 2 == 0 {
                notes.append(NoteEvent(note: 42, velocity: 60))
            }
            if context.isLastMeasure && step >= 6 {
                notes.append(NoteEvent(note: 38, velocity: 95))
            }
            return notes
        }

        let isFill = context.isFillTiming
        if isFill && step >= 6 {
            let seed = context.songLoopCount + context.phraseIndex
            let fillType = seed % 2
            if fillType == 0 {
                let vel: UInt8 = (step == 6) ? 70 : 110
                notes.append(NoteEvent(note: 38, velocity: vel))
            } else {
                if step == 6 {
                    notes.append(NoteEvent(note: 38, velocity: 105))
                } else if step == 7 {
                    notes.append(NoteEvent(note: 46, velocity: 95))
                }
            }
            return notes
        }

        let hiHatVelocity: UInt8 = [95, 60, 105, 50, 95, 60, 105, 50][step]
        notes.append(NoteEvent(note: 42, velocity: hiHatVelocity))

        switch step {
        case 0:
            notes.append(NoteEvent(note: 36, velocity: 110))
        case 2, 6:
            notes.append(NoteEvent(note: 38, velocity: 105))
        case 3:
            notes.append(NoteEvent(note: 36, velocity: 95))
        case 5, 7:
            notes.append(NoteEvent(note: 38, velocity: 65))
        default:
            break
        }
        
        return notes
    }
}

// MARK: - Generic Patterns

private func basicGenrePattern(genre: MusicGenre, step: Int) -> [NoteEvent] {
    var notes = [NoteEvent]()
    switch genre {
    case .pop:
        notes.append(NoteEvent(note: 42, velocity: (step % 2 == 0) ? 100 : 80))
        if step == 0 || step == 4 { notes.append(NoteEvent(note: 36, velocity: 110)) }
        if step == 2 || step == 6 { notes.append(NoteEvent(note: 38, velocity: 110)) }
    case .rock:
        notes.append(NoteEvent(note: 42, velocity: 110))
        if step == 0 || step == 3 || step == 4 { notes.append(NoteEvent(note: 36, velocity: 115)) }
        if step == 2 || step == 6 { notes.append(NoteEvent(note: 38, velocity: 115)) }
    case .dance:
        if step == 2 { notes.append(NoteEvent(note: 46, velocity: 100)) } else { notes.append(NoteEvent(note: 42, velocity: 90)) }
        if step % 2 == 0 { notes.append(NoteEvent(note: 36, velocity: 120)) }
        if step == 2 || step == 6 { notes.append(NoteEvent(note: 39, velocity: 110)) }
    case .lofi:
        if step % 4 == 0 { notes.append(NoteEvent(note: 42, velocity: 70)) }
        if step == 0 || step == 5 { notes.append(NoteEvent(note: 36, velocity: 90)) }
        if step == 2 || step == 6 { notes.append(NoteEvent(note: 38, velocity: 90)) }
    case .rAndB:
        notes.append(NoteEvent(note: 42, velocity: (step % 2 == 0) ? 95 : 75))
        if step == 0 || step == 3 { notes.append(NoteEvent(note: 36, velocity: 105)) }
        if step == 2 || step == 6 { notes.append(NoteEvent(note: 38, velocity: 110)) }
    }
    return notes
}


class SaraDrummer: DrumPlayerEngine {
    func evaluate(step: Int, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        var events = [NoteEvent]()
        let variation = (context.songLoopCount + context.phraseIndex) % 3
        
        if context.isFillTiming && step >= 6 {
            events.append(NoteEvent(note: 38, velocity: 85))
            if step == 7 { events.append(NoteEvent(note: 42, velocity: 70)) }
            return events
        }
        
        // Hi-hat
        if variation == 2 && (step == 3 || step == 7) {
            events.append(NoteEvent(note: 42, velocity: 50)) // 16th feel
        } else if step % 4 == 0 {
            events.append(NoteEvent(note: 42, velocity: 65))
        }

        // Kick & Snare
        if variation == 0 {
            if step == 0 || step == 4 { events.append(NoteEvent(note: 36, velocity: 85)) }
            if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 90)) }
        } else if variation == 1 {
            if step == 0 || step == 3 || step == 4 { events.append(NoteEvent(note: 36, velocity: 85)) } // Syncopated kick
            if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 90)) }
        } else {
            if step == 0 { events.append(NoteEvent(note: 36, velocity: 85)) }
            if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 90)) }
            if step == 5 { events.append(NoteEvent(note: 36, velocity: 75)) } // Ghost kick
        }
        
        return events
    }
}

class ChadDrummer: DrumPlayerEngine {
    func evaluate(step: Int, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        var events = [NoteEvent]()
        let variation = (context.songLoopCount + context.phraseIndex) % 3
        
        if context.isFillTiming && step >= 4 {
            events.append(NoteEvent(note: 38, velocity: 127)) // Snare roll
            events.append(NoteEvent(note: 36, velocity: 127)) // Kick match
            if step == 7 { events.append(NoteEvent(note: 47, velocity: 120)) } // Tom
            return events
        }
        
        // Ride/Hihat
        if variation == 2 {
            events.append(NoteEvent(note: 51, velocity: 110)) // Ride
        } else {
            events.append(NoteEvent(note: 42, velocity: 100)) // Hihat
        }

        if step == 0 { events.append(NoteEvent(note: 49, velocity: 110)) } // Crash on 1

        if variation == 0 {
            if step % 2 == 0 { events.append(NoteEvent(note: 36, velocity: 120)) } // Double kick
            if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 127)) } // Snare
        } else if variation == 1 {
            if step == 0 || step == 3 || step == 4 { events.append(NoteEvent(note: 36, velocity: 127)) } 
            if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 127)) }
        } else {
            // Blast-like or heavy tom
            events.append(NoteEvent(note: 36, velocity: 127)) // kick every step
            if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 127)) }
        }
        
        return events
    }
}