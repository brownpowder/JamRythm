import Foundation
import Combine

// MARK: - Protocols

protocol JamPlayer: Identifiable, CaseIterable, Equatable {
    var id: String { get }
    var displayName: String { get }
    var iconName: String { get }
    var imageName: String { get } // 今後の画像表示用アセット名
    var description: String { get }
    var isPremium: Bool { get }
    var isUnlocked: Bool { get set }
    
    // 個性を引き出すパラメータ
    var timingOffsetMs: Double { get } // タイミングのズレ (正=遅い/モタる, 負=早い/突っ込む)
    var velocityHumanizeRange: Int { get } // ベロシティのブレ幅
}

// MARK: - Drum Player

enum DrumPlayer: String, JamPlayer, PremiumLockable {
    var isLocked: Bool {
        print("DEBUG DrumPlayer.isLocked evaluated for \(self). isUnlocked=\(isUnlocked)")
        return !isUnlocked
    }
    case rhythmMachine
    case standard
    case mark
    case leo
    case sara
    case chad

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rhythmMachine: return NSLocalizedString("Rhythm Machine", comment: "")
        case .standard: return NSLocalizedString("Standard", comment: "")
        case .mark: return NSLocalizedString("Mark (Rock)", comment: "")
        case .leo: return NSLocalizedString("Leo (Funk)", comment: "")
        case .sara: return NSLocalizedString("Sara (Chill)", comment: "")
        case .chad: return NSLocalizedString("Chad (Metal)", comment: "")
        }
    }

    var iconName: String {
        switch self {
        case .rhythmMachine: return NSLocalizedString("metronome", comment: "")
        case .standard: return NSLocalizedString("person", comment: "")
        case .mark: return NSLocalizedString("person.fill", comment: "")
        case .leo: return NSLocalizedString("person.fill.turn.right", comment: "")
        case .sara: return NSLocalizedString("person.fill.turn.down", comment: "")
        case .chad: return NSLocalizedString("person.wave.2.fill", comment: "")
        }
    }

    var imageName: String {
        switch self {
        case .rhythmMachine: return "Maschine"
        case .standard: return NSLocalizedString("system:person.fill", comment: "")
        case .mark: return NSLocalizedString("Dr3", comment: "")
        case .leo: return NSLocalizedString("Dr4", comment: "")
        case .sara: return NSLocalizedString("Dr2", comment: "")
        case .chad: return NSLocalizedString("Dr1", comment: "")
        }
    }

    var description: String {
        switch self {
        case .rhythmMachine: return NSLocalizedString("従来の正確でシンプルな定型ビート。ループ練習に最適。", comment: "")
        case .standard: return NSLocalizedString("オーソドックスな8ビート・16ビートドラマー。セクション展開に合わせたシンプルな変化のみ。", comment: "")
        case .mark: return NSLocalizedString("パワフル・ロックドラマー。力強いビートと多彩なフィルイン。サビ前でのド派手なタム回しが特徴。", comment: "")
        case .leo: return NSLocalizedString("ファンク＆ネオソウル・ドラマー。跳ねる16分ゴーストスネアと細かいハットワーク、シンコペーションによるノリ。", comment: "")
        case .sara: return NSLocalizedString("Lo-Fi ＆ Chill。少しモタったスネアと、心地よい揺らぎを感じるレイドバックしたグルーヴが特徴。", comment: "")
        case .chad: return NSLocalizedString("メタル・ハードロックドラマー。パワフルなツーバスと派手なシンバルワークで激しくアグレッシブに叩きまくる。", comment: "")
        }
    }

    var isPremium: Bool {
        switch self {
        case .rhythmMachine, .standard: return false
        case .mark, .leo, .sara, .chad: return true
        }
    }

    var timingOffsetMs: Double {
        switch self {
        case .rhythmMachine: return 0.0
        case .standard: return 0.0
        case .mark: return 2.0
        case .leo: return 4.0
        case .sara: return 8.0  // レイドバック
        case .chad: return -4.0 // 前ノリ
        }
    }

    var velocityHumanizeRange: Int {
        switch self {
        case .rhythmMachine: return 0
        case .standard: return 5
        case .mark: return 12
        case .leo: return 15
        case .sara: return 8
        case .chad: return 20
        }
    }
    
    var isUnlocked: Bool {
        get {
            if !isPremium { return true }
            #if DEBUG
            if UserDefaults.standard.object(forKey: "debugPremiumUnlocked") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "debugPremiumUnlocked")
            #else
            return StoreManager.shared.isUnlocked
            #endif
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "unlocked_drum_\(self.rawValue)")
        }
    }
}

// MARK: - Bass Player

enum BassPlayer: String, JamPlayer, PremiumLockable {
    var isLocked: Bool {
        print("DEBUG BassPlayer.isLocked evaluated for \(self). isUnlocked=\(isUnlocked)")
        return !isUnlocked
    }
    case rhythmMachine
    case standard
    case kr
    case akiko
    case marcus
    case haruto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rhythmMachine: return NSLocalizedString("Rhythm Machine", comment: "")
        case .standard: return NSLocalizedString("Standard", comment: "")
        case .kr: return NSLocalizedString("KR (Punk)", comment: "")
        case .akiko: return NSLocalizedString("Akiko (Groove)", comment: "")
        case .marcus: return NSLocalizedString("Marcus (Funk)", comment: "")
        case .haruto: return NSLocalizedString("Haruto (Pop)", comment: "")
        }
    }

    var iconName: String {
        switch self {
        case .rhythmMachine: return NSLocalizedString("metronome", comment: "")
        case .standard: return NSLocalizedString("person", comment: "")
        case .kr: return NSLocalizedString("person.fill.bolt", comment: "")
        case .akiko: return NSLocalizedString("person.fill.viewfinder", comment: "")
        case .marcus: return NSLocalizedString("person.fill.turn.down", comment: "")
        case .haruto: return NSLocalizedString("person.wave.2.fill", comment: "")
        }
    }

    var imageName: String {
        switch self {
        case .rhythmMachine: return "Maschine"
        case .standard: return NSLocalizedString("system:person.fill", comment: "")
        case .kr: return NSLocalizedString("Ba4", comment: "")
        case .akiko: return NSLocalizedString("Ba2", comment: "")
        case .marcus: return NSLocalizedString("Ba1", comment: "")
        case .haruto: return NSLocalizedString("Ba3", comment: "")
        }
    }

    var description: String {
        switch self {
        case .rhythmMachine: return NSLocalizedString("従来のルート音中心の定型パターン。", comment: "")
        case .standard: return NSLocalizedString("オーソドックスなルート＆5度の安定したベース。", comment: "")
        case .kr: return NSLocalizedString("パンク＆ロック・ドライヴ。8分音符でルート＆オクターブをゴリゴリ刻みまくる疾走感。サビ前でスライドを多用。", comment: "")
        case .akiko: return NSLocalizedString("グルーヴィ・ウォーキング。スケール音や経過音（クロマチック）を縦横無尽に使い、次コードのルートへ滑らかにアプローチ。", comment: "")
        case .marcus: return NSLocalizedString("ヘヴィ・ファンクベーシスト。スラップ奏法やゴーストノートを駆使し、タイトでノリの良いベースラインを刻む。", comment: "")
        case .haruto: return NSLocalizedString("王道ポップ・ベーシスト。コード進行に寄り添うメロディアスで美しいベースライン。安定感抜群。", comment: "")
        }
    }

    var isPremium: Bool {
        switch self {
        case .rhythmMachine, .standard: return false
        case .kr, .akiko, .marcus, .haruto: return true
        }
    }

    var timingOffsetMs: Double {
        switch self {
        case .rhythmMachine: return 0.0
        case .standard: return 0.0
        case .kr: return -3.0    // ドライブ感（前ノリ）
        case .akiko: return 2.0
        case .marcus: return 0.0
        case .haruto: return 0.0
        }
    }

    var velocityHumanizeRange: Int {
        switch self {
        case .rhythmMachine: return 0
        case .standard: return 5
        case .kr: return 15
        case .akiko: return 12
        case .marcus: return 20
        case .haruto: return 5
        }
    }
    
    var isUnlocked: Bool {
        get {
            if !isPremium { return true }
            #if DEBUG
            if UserDefaults.standard.object(forKey: "debugPremiumUnlocked") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "debugPremiumUnlocked")
            #else
            return StoreManager.shared.isUnlocked
            #endif
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "unlocked_bass_\(self.rawValue)")
        }
    }
}

// MARK: - Piano Player

enum PianoPlayer: String, JamPlayer, PremiumLockable {
    var isLocked: Bool {
        print("DEBUG PianoPlayer.isLocked evaluated for \(self). isUnlocked=\(isUnlocked)")
        return !isUnlocked
    }
    case rhythmMachine
    case standard
    case emi
    case jazzCat
    case ray
    case clara

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rhythmMachine: return NSLocalizedString("Rhythm Machine", comment: "")
        case .standard: return NSLocalizedString("Standard", comment: "")
        case .emi: return NSLocalizedString("Emi (Pop)", comment: "")
        case .jazzCat: return NSLocalizedString("JazzCat (Jazz)", comment: "")
        case .ray: return NSLocalizedString("Ray (R&B)", comment: "")
        case .clara: return NSLocalizedString("Clara (Classical)", comment: "")
        }
    }

    var iconName: String {
        switch self {
        case .rhythmMachine: return NSLocalizedString("metronome", comment: "")
        case .standard: return NSLocalizedString("person", comment: "")
        case .emi: return NSLocalizedString("person.fill.star", comment: "")
        case .jazzCat: return NSLocalizedString("person.fill.eyeglasses", comment: "")
        case .ray: return NSLocalizedString("person.fill.turn.down", comment: "")
        case .clara: return NSLocalizedString("person.wave.2.fill", comment: "")
        }
    }

    var imageName: String {
        switch self {
        case .rhythmMachine: return "Maschine"
        case .standard: return NSLocalizedString("system:person.fill", comment: "")
        case .emi: return NSLocalizedString("Key2", comment: "")
        case .jazzCat: return NSLocalizedString("Key1", comment: "")
        case .ray: return NSLocalizedString("Key3", comment: "")
        case .clara: return NSLocalizedString("Key4", comment: "")
        }
    }

    var description: String {
        switch self {
        case .rhythmMachine: return NSLocalizedString("小節頭の全音符（白玉）のみ。", comment: "")
        case .standard: return NSLocalizedString("オーソドックスなコード弾き。", comment: "")
        case .emi: return NSLocalizedString("ポップ・コンピング。Bメロからのリズミカルなコンピングやサビでの力強いプッシュ。", comment: "")
        case .jazzCat: return NSLocalizedString("テンションコードとシンコペーションを多用するオシャレなジャズピアニスト。", comment: "")
        case .ray: return NSLocalizedString("R&B / レゲエ・キーボーディスト。裏打ちのバッキングや、ブルージーな装飾音符を得意とし、時折ロックなアプローチも見せる。", comment: "")
        case .clara: return NSLocalizedString("クラシック出身のピアニスト。流麗なアルペジオを自在に操り、コード進行を優雅かつ壮大に彩るプレイが魅力。", comment: "")
        }
    }

    var isPremium: Bool {
        switch self {
        case .rhythmMachine, .standard: return false
        case .emi, .jazzCat, .ray, .clara: return true
        }
    }

    var timingOffsetMs: Double {
        switch self {
        case .rhythmMachine: return 0.0
        case .standard: return 0.0
        case .emi: return 1.0
        case .jazzCat: return 4.0 // 少しタメる
        case .ray: return 6.0     // レイドバック
        case .clara: return 0.0
        }
    }

    var velocityHumanizeRange: Int {
        switch self {
        case .rhythmMachine: return 0
        case .standard: return 5
        case .emi: return 8
        case .jazzCat: return 18
        case .ray: return 15
        case .clara: return 10
        }
    }
    
    var isUnlocked: Bool {
        get {
            if !isPremium { return true }
            #if DEBUG
            if UserDefaults.standard.object(forKey: "debugPremiumUnlocked") == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: "debugPremiumUnlocked")
            #else
            return StoreManager.shared.isUnlocked
            #endif
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "unlocked_piano_\(self.rawValue)")
        }
    }
}




// MARK: - セッション・ケミストリー (相性)

struct PlayerChemistry: Identifiable, Equatable {
    let id: String
    let displayName: String
    let description: String
    let iconName: String
    let themeColorName: String // Color(themeColorName) などで使う場合用 (省略可能)
    
    static let allChemistries: [PlayerChemistry] = [
        PlayerChemistry(id: "funk_masters", displayName: "Funk Masters", description: "最高にグルーヴィーで跳ねるファンクセッション！", iconName: "flame.fill", themeColorName: "orange"),
        PlayerChemistry(id: "heavy_drive", displayName: "Heavy Drive", description: "爆発的な疾走感！アグレッシブなハードロック。", iconName: "bolt.fill", themeColorName: "red"),
        PlayerChemistry(id: "chill_vibes", displayName: "Chill Vibes", description: "心地よくレイドバックしたLo-Fi空間。", iconName: "moon.stars.fill", themeColorName: "indigo"),
        PlayerChemistry(id: "jazz_lounge", displayName: "Jazz Lounge", description: "大人でオシャレなジャズラウンジの雰囲気。", iconName: "wineglass.fill", themeColorName: "purple"),
        PlayerChemistry(id: "royal_pop", displayName: "Royal Pop", description: "超安定感！誰もが聴きやすい王道ポップス。", iconName: "star.fill", themeColorName: "yellow")
    ]
    
    /*
    現在のプレイヤー編成から発動しているケミストリーを判定する。
    */
    static func detectChemistry(drum: DrumPlayer, bass: BassPlayer, piano: PianoPlayer) -> PlayerChemistry? {
        if drum == .leo && bass == .marcus {
            return allChemistries.first(where: { $0.id == "funk_masters" })
        }
        if drum == .chad && bass == .kr {
            return allChemistries.first(where: { $0.id == "heavy_drive" })
        }
        if drum == .sara && (piano == .ray || piano == .emi) {
            return allChemistries.first(where: { $0.id == "chill_vibes" })
        }
        if bass == .akiko && piano == .jazzCat {
            return allChemistries.first(where: { $0.id == "jazz_lounge" })
        }
        if bass == .haruto && drum == .standard && piano == .emi {
            return allChemistries.first(where: { $0.id == "royal_pop" })
        }
        return nil
    }
}

import SwiftUI

