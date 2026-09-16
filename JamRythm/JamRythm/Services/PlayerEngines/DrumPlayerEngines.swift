//
//  DrumPlayerEngines.swift
//  JamRythm
//

import Foundation

// MARK: - Base Engine

class BaseDrumPlayerEngine: DrumPlayerEngine {
    
    // 各キャラクター固有のベロシティのブレ幅（サブクラスで上書き可能）
    var velocityHumanizeRange: Int { return 5 }
    
    func evaluate(step: Int, context: PlayerContext, genre: MusicGenre) -> [NoteEvent] {
        let variation = (context.songLoopCount + context.phraseIndex) % 3
        
        // 1. フィルインのタイミングなら、シグネチャーフィルを優先
        if context.isFillTiming && step >= 4 {
            if let fill = signatureFill(genre: genre, variation: variation, step: step, context: context) {
                return applyHumanize(events: fill)
            }
        }
        
        // 2. ジャンルとバリエーションに応じた基本パターンを取得
        let baseEvents = pattern(for: genre, variation: variation, step: step, context: context)
        
        // 3. プレイヤー固有の手癖（装飾音やミュート）を適用
        let interpretedEvents = interpret(events: baseEvents, genre: genre, step: step, context: context)
        
        // 4. ベロシティのヒューマナイズ（強弱の揺らぎ）を適用して返す
        return applyHumanize(events: interpretedEvents)
    }
    
    // サブクラスで実装するメソッド群
    func pattern(for genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent] {
        return basicGenrePattern(genre: genre, step: step) // デフォルトは共通パターン
    }
    
    func signatureFill(genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent]? {
        return nil
    }
    
    func interpret(events: [NoteEvent], genre: MusicGenre, step: Int, context: PlayerContext) -> [NoteEvent] {
        return events
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


class SaraDrummer: BaseDrumPlayerEngine {
    override var velocityHumanizeRange: Int { return 8 }
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        
        switch genre {
        case .pop, .dance:
            // Pop/DanceでもSaraは少しレイドバックしたシンプルなビートを好む
            if variation == 0 {
                if step % 4 == 0 { events.append(NoteEvent(note: 42, velocity: 65)) }
                if step == 0 { events.append(NoteEvent(note: 36, velocity: 80)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 85)) } // スネアを少し減らす
            } else if variation == 1 {
                if step % 2 == 0 { events.append(NoteEvent(note: 42, velocity: 60)) }
                if step == 0 || step == 5 { events.append(NoteEvent(note: 36, velocity: 80)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 85)) }
            } else {
                // 16分音符のハイハットを少し混ぜる
                if step % 2 == 0 || step == 3 || step == 7 { events.append(NoteEvent(note: 42, velocity: 55)) }
                if step == 0 { events.append(NoteEvent(note: 36, velocity: 80)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 85)) }
            }
            
        case .lofi, .rAndB:
            // Saraの本領発揮。隙間の多いチルビート
            if variation == 0 {
                if step == 0 { events.append(NoteEvent(note: 36, velocity: 85)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 90)) }
                if step % 4 == 0 { events.append(NoteEvent(note: 42, velocity: 65)) }
            } else if variation == 1 {
                if step == 0 || step == 3 { events.append(NoteEvent(note: 36, velocity: 85)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 90)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: 42, velocity: 65)) } // 裏拍ハット
            } else {
                if step == 0 { events.append(NoteEvent(note: 36, velocity: 80)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 90)) }
                if step == 7 { events.append(NoteEvent(note: 36, velocity: 70)) } // 次の小節へのゴーストキック
            }
            
        case .rock:
            // Rockでも激しすぎず、インディーロック風のアプローチ
            if variation == 0 {
                if step % 2 == 0 { events.append(NoteEvent(note: 42, velocity: 80)) }
                if step == 0 || step == 3 { events.append(NoteEvent(note: 36, velocity: 90)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 95)) }
            } else if variation == 1 {
                if step % 2 == 0 { events.append(NoteEvent(note: 42, velocity: 80)) }
                if step == 0 || step == 4 { events.append(NoteEvent(note: 36, velocity: 90)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 95)) }
            } else {
                if step % 4 == 0 { events.append(NoteEvent(note: 42, velocity: 80)) }
                if step == 0 { events.append(NoteEvent(note: 36, velocity: 90)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 95)) }
                if step == 5 { events.append(NoteEvent(note: 36, velocity: 80)) }
            }
        }
        
        return events
    }
    
    override func signatureFill(genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent]? {
        // フィルインでも激しく叩かず、少し抜いたフレーズにする
        var events = [NoteEvent]()
        if step == 4 { events.append(NoteEvent(note: 38, velocity: 80)) }
        if step == 6 { events.append(NoteEvent(note: 38, velocity: 85)) }
        if step == 7 { events.append(NoteEvent(note: 42, velocity: 60)) } // オープンハット風
        return events
    }
}

class ChadDrummer: BaseDrumPlayerEngine {
    override var velocityHumanizeRange: Int { return 15 } // ベロシティのブレが激しい
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        
        // Chadは何のジャンルでもツーバスやクラッシュを多用する
        let kickVel: UInt8 = 120
        let snareVel: UInt8 = 127
        
        switch genre {
        case .pop, .lofi, .rAndB:
            // 大人しいジャンルでも手数を減らしきれないChad
            if variation == 0 {
                if step % 4 == 0 { events.append(NoteEvent(note: 36, velocity: kickVel)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: snareVel)) }
                if step % 2 == 0 { events.append(NoteEvent(note: 42, velocity: 100)) } // ハットは常に8分
            } else if variation == 1 {
                if step == 0 || step == 3 { events.append(NoteEvent(note: 36, velocity: kickVel)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: snareVel)) }
                events.append(NoteEvent(note: 42, velocity: 100)) // 全ステップでハット（16分刻み風）
            } else {
                if step == 0 || step == 4 { events.append(NoteEvent(note: 36, velocity: kickVel)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: snareVel)) }
                if step == 0 { events.append(NoteEvent(note: 49, velocity: 110)) } // クラッシュ
            }
            
        case .rock, .dance:
            // Chadのホームグラウンド。全力でメタルアプローチ
            if variation == 0 {
                events.append(NoteEvent(note: 36, velocity: kickVel)) // ずっとツーバス
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: snareVel)) }
                if step % 2 == 0 { events.append(NoteEvent(note: 51, velocity: 115)) } // ライドシンバル
            } else if variation == 1 {
                if step == 0 || step == 2 || step == 3 || step == 4 || step == 6 { events.append(NoteEvent(note: 36, velocity: kickVel)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: snareVel)) }
                events.append(NoteEvent(note: 42, velocity: 110))
            } else {
                // ブラストビート風
                events.append(NoteEvent(note: 36, velocity: kickVel))
                if step % 2 == 1 { events.append(NoteEvent(note: 38, velocity: snareVel)) }
                events.append(NoteEvent(note: 49, velocity: 115)) // ずっとクラッシュ
            }
        }
        
        return events
    }
    
    override func signatureFill(genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent]? {
        // 超強烈なフィルイン
        var events = [NoteEvent]()
        events.append(NoteEvent(note: 36, velocity: 127)) // 足はずっと踏んでる
        if step == 4 || step == 5 { events.append(NoteEvent(note: 38, velocity: 127)) } // スネア連打
        if step == 6 { events.append(NoteEvent(note: 47, velocity: 120)) } // ミッドタム
        if step == 7 { events.append(NoteEvent(note: 43, velocity: 120)) } // フロアタム
        return events
    }
}