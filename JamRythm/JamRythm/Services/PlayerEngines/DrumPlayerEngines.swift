//
//  DrumPlayerEngines.swift
//  JamRythm
//

import Foundation

// MARK: - Base Engine

class BaseDrumPlayerEngine: DrumPlayerEngine {
    
    // 各キャラクター固有のベロシティのブレ幅（サブクラスで上書き可能）
    var velocityHumanizeRange: Int { return 2 }
    
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

class MarkDrummer: BaseDrumPlayerEngine {
    override var velocityHumanizeRange: Int { return 4 }
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        
        // Mark (Standard Rock/Pop)
        switch genre {
        case .rock:
            if variation == 0 {
                if step % 2 == 0 { events.append(NoteEvent(note: 42, velocity: 90)) } // 8th hat
                if step == 0 || step == 4 { events.append(NoteEvent(note: 36, velocity: 100)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 110)) }
            } else if variation == 1 {
                if step % 2 == 0 { events.append(NoteEvent(note: 42, velocity: 90)) }
                if step == 0 || step == 3 || step == 4 { events.append(NoteEvent(note: 36, velocity: 100)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 110)) }
            } else {
                if step % 4 == 0 { events.append(NoteEvent(note: 51, velocity: 95)) } // Ride
                if step == 0 || step == 5 { events.append(NoteEvent(note: 36, velocity: 100)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, velocity: 110)) }
            }
        default:
            // 他のジャンルでも比較的パワフルに叩く
            if variation == 0 {
                if step % 2 == 0 { events.append(NoteEvent(note: 42, velocity: 85)) }
                if step == 0 { events.append(NoteEvent(note: 36, velocity: 95)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 105)) }
            } else {
                if step % 2 == 0 { events.append(NoteEvent(note: 42, velocity: 85)) }
                if step == 0 || step == 3 { events.append(NoteEvent(note: 36, velocity: 95)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 105)) }
            }
        }
        return events
    }
    
    override func signatureFill(genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent]? {
        var events = [NoteEvent]()
        if step == 4 { events.append(NoteEvent(note: 38, velocity: 110)) }
        if step == 5 { events.append(NoteEvent(note: 38, velocity: 100)) }
        if step == 6 { events.append(NoteEvent(note: 47, velocity: 105)) }
        if step == 7 { events.append(NoteEvent(note: 43, velocity: 110)) }
        return events
    }
}

class LeoDrummer: BaseDrumPlayerEngine {
    override var velocityHumanizeRange: Int { return 3 } // ゴーストノート多めのためブレ幅大
    
    override func pattern(for genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent] {
        var events = [NoteEvent]()
        
        switch genre {
        case .dance, .pop:
            // ファンク/R&BドラマーのLeoは、裏拍やゴーストノートを多用する
            if variation == 0 {
                events.append(NoteEvent(note: 42, velocity: step % 2 == 0 ? 95 : 60)) // 16th feel
                if step == 0 { events.append(NoteEvent(note: 36, velocity: 100)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 110)) }
                if step == 3 || step == 7 { events.append(NoteEvent(note: 36, velocity: 70)) }
            } else if variation == 1 {
                events.append(NoteEvent(note: 42, velocity: step % 2 == 0 ? 95 : 60))
                if step == 0 || step == 3 { events.append(NoteEvent(note: 36, velocity: 100)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 110)) }
                if step == 6 { events.append(NoteEvent(note: 38, velocity: 65)) } // ゴーストスネア
            } else {
                if step % 4 == 0 { events.append(NoteEvent(note: 46, velocity: 85)) } // オープンハット
                if step == 0 || step == 5 { events.append(NoteEvent(note: 36, velocity: 100)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 110)) }
            }
        default:
            if variation == 0 {
                events.append(NoteEvent(note: 42, velocity: 85))
                if step == 0 { events.append(NoteEvent(note: 36, velocity: 90)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 100)) }
                if step == 5 || step == 7 { events.append(NoteEvent(note: 38, velocity: 50)) } // スネアゴースト
            } else {
                events.append(NoteEvent(note: 42, velocity: 85))
                if step == 0 || step == 3 { events.append(NoteEvent(note: 36, velocity: 90)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 100)) }
            }
        }
        return events
    }
    
    override func signatureFill(genre: MusicGenre, variation: Int, step: Int, context: PlayerContext) -> [NoteEvent]? {
        var events = [NoteEvent]()
        if step == 4 || step == 5 { events.append(NoteEvent(note: 38, velocity: 95)) }
        if step == 6 { events.append(NoteEvent(note: 36, velocity: 100)) } // キックを混ぜるフィル
        if step == 7 { events.append(NoteEvent(note: 46, velocity: 90)) } // オープンハット
        return events
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
    override var velocityHumanizeRange: Int { return 4 }
    
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
            // Saraの本領発揮。隙間の多いチルビート＆J Dilla的ヨレ感
            // ハイハットを細かく入れつつ、ベロシティでグルーヴを作る
            let hatVel: UInt8 = step % 2 == 0 ? 75 : 50
            if genre == .lofi { events.append(NoteEvent(note: 42, velocity: hatVel)) }
            else if step % 2 == 0 { events.append(NoteEvent(note: 42, velocity: hatVel)) }

            if variation == 0 {
                if step == 0 { events.append(NoteEvent(note: 36, velocity: 85)) }
                if step == 5 { events.append(NoteEvent(note: 36, velocity: 60)) } // 裏キック
                if step == 4 { events.append(NoteEvent(note: 37, velocity: 85)) } // リムショット(37)
            } else if variation == 1 {
                if step == 0 || step == 3 { events.append(NoteEvent(note: 36, velocity: 85)) }
                if step == 4 { events.append(NoteEvent(note: 38, velocity: 80)) } // スネア
                if step == 7 { events.append(NoteEvent(note: 38, velocity: 40)) } // ゴーストスネア
            } else {
                if step == 0 { events.append(NoteEvent(note: 36, velocity: 80)) }
                if step == 2 { events.append(NoteEvent(note: 36, velocity: 60)) }
                if step == 4 { events.append(NoteEvent(note: 37, velocity: 85)) }
                if step == 7 { events.append(NoteEvent(note: 36, velocity: 70)) }
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
    override var velocityHumanizeRange: Int { return 3 } // ベロシティのブレが激しい
    
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