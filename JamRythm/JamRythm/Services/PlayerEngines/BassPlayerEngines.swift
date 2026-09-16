//
//  BassPlayerEngines.swift
//  JamRythm
//

import Foundation

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

class KRBassist: BassPlayerEngine {
    func evaluate(step: Int, rootNote: UInt8?, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        guard let root = rootNote else { return [] }
        var notes = [NoteEvent]()
        
        if context.sectionType == .intro {
            if context.isLastMeasure && step == 7 {
                notes.append(NoteEvent(note: root + 12, velocity: 110))
            }
            return notes
        }

        if context.isFillTiming && step >= 4 {
            let seed = context.songLoopCount + context.phraseIndex
            let fillType = seed % 2
            if fillType == 0 {
                let slideOffset: UInt8 = (step == 7) ? 12 : 0
                notes.append(NoteEvent(note: root + slideOffset, velocity: 110))
            } else {
                let offset: UInt8 = UInt8(step - 4)
                notes.append(NoteEvent(note: root + offset, velocity: 110))
            }
            return notes
        }
        
        // Phrase Variation
        if step >= 6 && (context.measureIndex + 1) % 2 == 0 {
            let seed = context.songLoopCount + context.phraseIndex
            let variationType = seed % 3
            if variationType == 0 && step == 7 {
                notes.append(NoteEvent(note: root + 7, velocity: 100))
                return notes
            } else if variationType == 1 && step == 6 {
                notes.append(NoteEvent(note: root + 12, velocity: 105))
                return notes
            } else if variationType == 2 && step == 7 {
                notes.append(NoteEvent(note: root + 4, velocity: 95))
                return notes
            }
        }
        
        // Syncopation Groove Variation based on LoopCount
        let grooveSeed = context.songLoopCount % 2
        if grooveSeed == 1 && context.sectionType == .chorus {
            // シンコペーションバリエーション
            if step == 3 || step == 6 {
                notes.append(NoteEvent(note: root, velocity: 115))
                return notes
            } else if step == 0 || step == 4 {
                notes.append(NoteEvent(note: root, velocity: 110))
                return notes
            } else {
                return notes // 休符
            }
        }
        
        let vel: UInt8 = (step % 2 == 0) ? 110 : 95
        notes.append(NoteEvent(note: root, velocity: vel))
        return notes
    }
}

class AkikoBassist: BassPlayerEngine {
    func evaluate(step: Int, rootNote: UInt8?, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        guard let root = rootNote else { return [] }
        var notes = [NoteEvent]()
        
        let seed = context.songLoopCount + context.phraseIndex
        let variation = seed % 4
        
        // イントロやAメロは少し大人しめに
        if context.sectionType == .verseA || context.sectionType == .intro {
            let verseVariation = seed % 3
            if step == 0 {
                notes.append(NoteEvent(note: root, velocity: 100))
            } else if verseVariation == 0 && step == 4 {
                notes.append(NoteEvent(note: root + 7, velocity: 90)) // 5th
            } else if verseVariation == 1 && step == 5 {
                // シンコペーション（裏拍）
                notes.append(NoteEvent(note: root + 12, velocity: 90)) // Octave
            } else if verseVariation == 2 && step == 6 {
                notes.append(NoteEvent(note: root, velocity: 90))
            }
            return notes
        }
        
        // それ以外（Bメロ、サビなど）のアクティブなベースライン
        
        // 1拍目は基本ルート
        if step == 0 {
            notes.append(NoteEvent(note: root, velocity: 105))
            return notes
        }
        
        switch variation {
        case 0:
            // ルートとオクターブ、5度を交えた王道ライン
            if step == 3 { notes.append(NoteEvent(note: root, velocity: 80)) }
            if step == 4 { notes.append(NoteEvent(note: root + 12, velocity: 95)) }
            if step == 6 { notes.append(NoteEvent(note: root + 7, velocity: 90)) } // 5度
        case 1:
            // シンコペーション（裏拍アクセント）を強調
            if step == 2 { notes.append(NoteEvent(note: root, velocity: 90)) }
            if step == 5 { notes.append(NoteEvent(note: root + 12, velocity: 100)) } // 裏拍
            if step == 7 { notes.append(NoteEvent(note: root + 7, velocity: 95)) } // 5度
        case 2:
            // 休符を活かしたファンキーなアプローチ
            if step == 4 { notes.append(NoteEvent(note: root + 7, velocity: 95)) }
            if step == 5 { notes.append(NoteEvent(note: root + 12, velocity: 100)) }
        case 3:
            // 5度とオクターブのオルタネイトな動き
            if step == 2 { notes.append(NoteEvent(note: root + 7, velocity: 90)) }
            if step == 4 { notes.append(NoteEvent(note: root, velocity: 95)) }
            if step == 6 { notes.append(NoteEvent(note: root + 12, velocity: 100)) }
        default:
            break
        }
        
        return notes
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


class MarcusBassist: BassPlayerEngine {
    func evaluate(step: Int, rootNote: UInt8?, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        guard let r = rootNote else { return [] }
        var events = [NoteEvent]()
        if step % 16 == 0 { events.append(NoteEvent(note: r, velocity: 120)) } // Slap
        if step % 16 == 12 { events.append(NoteEvent(note: r + 12, velocity: 110)) } // Pop
        return events
    }
}

class HarutoBassist: BassPlayerEngine {
    func evaluate(step: Int, rootNote: UInt8?, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        guard let r = rootNote else { return [] }
        var events = [NoteEvent]()
        if step % 16 == 0 { events.append(NoteEvent(note: r, velocity: 95)) }
        if step % 16 == 8 { events.append(NoteEvent(note: r + 7, velocity: 85)) } // 5th
        return events
    }
}
