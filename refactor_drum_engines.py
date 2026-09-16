import re

with open('/Volumes/WD512/Projects/Ikatomape/Jam-Rythm/JamRythm/JamRythm/Services/PlayerEngines/DrumPlayerEngines.swift', 'r') as f:
    content = f.read()

base_class_code = """import Foundation

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
"""

content = re.sub(r'import Foundation', base_class_code, content, count=1)

sara_code = """class SaraDrummer: BaseDrumPlayerEngine {
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
}"""
content = re.sub(r'class SaraDrummer.*?^}', sara_code, content, flags=re.DOTALL|re.MULTILINE)

chad_code = """class ChadDrummer: BaseDrumPlayerEngine {
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
                if step % 4 == 0 { events.append(NoteEvent(note: 36, kickVel)) }
                if step == 4 { events.append(NoteEvent(note: 38, snareVel)) }
                if step % 2 == 0 { events.append(NoteEvent(note: 42, 100)) } // ハットは常に8分
            } else if variation == 1 {
                if step == 0 || step == 3 { events.append(NoteEvent(note: 36, kickVel)) }
                if step == 4 { events.append(NoteEvent(note: 38, snareVel)) }
                events.append(NoteEvent(note: 42, 100)) // 全ステップでハット（16分刻み風）
            } else {
                if step == 0 || step == 4 { events.append(NoteEvent(note: 36, kickVel)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, snareVel)) }
                if step == 0 { events.append(NoteEvent(note: 49, 110)) } // クラッシュ
            }
            
        case .rock, .dance:
            // Chadのホームグラウンド。全力でメタルアプローチ
            if variation == 0 {
                events.append(NoteEvent(note: 36, kickVel)) // ずっとツーバス
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, snareVel)) }
                if step % 2 == 0 { events.append(NoteEvent(note: 51, 115)) } // ライドシンバル
            } else if variation == 1 {
                if step == 0 || step == 2 || step == 3 || step == 4 || step == 6 { events.append(NoteEvent(note: 36, kickVel)) }
                if step == 2 || step == 6 { events.append(NoteEvent(note: 38, snareVel)) }
                events.append(NoteEvent(note: 42, 110))
            } else {
                // ブラストビート風
                events.append(NoteEvent(note: 36, kickVel))
                if step % 2 == 1 { events.append(NoteEvent(note: 38, snareVel)) }
                events.append(NoteEvent(note: 49, 115)) // ずっとクラッシュ
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
}"""
content = re.sub(r'class ChadDrummer.*?^}', chad_code, content, flags=re.DOTALL|re.MULTILINE)


with open('/Volumes/WD512/Projects/Ikatomape/Jam-Rythm/JamRythm/JamRythm/Services/PlayerEngines/DrumPlayerEngines.swift', 'w') as f:
    f.write(content)
