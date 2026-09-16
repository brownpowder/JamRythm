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

enum DrumPlayer: String, JamPlayer {
    case rhythmMachine
    case standard
    case mark
    case leo
    case sara
    case chad

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rhythmMachine: return "Rhythm Machine"
        case .standard: return "Standard"
        case .mark: return "Mark (Rock)"
        case .leo: return "Leo (Funk)"
        case .sara: return "Sara (Chill)"
        case .chad: return "Chad (Metal)"
        }
    }

    var iconName: String {
        switch self {
        case .rhythmMachine: return "metronome"
        case .standard: return "person"
        case .mark: return "person.fill"
        case .leo: return "person.fill.turn.right"
        case .sara: return "person.fill.turn.down"
        case .chad: return "person.wave.2.fill"
        }
    }

    var imageName: String {
        switch self {
        case .rhythmMachine: return "system:metronome"
        case .standard: return "system:person.fill"
        case .mark: return "Dr3"
        case .leo: return "Dr4"
        case .sara: return "Dr2"
        case .chad: return "Dr1"
        }
    }

    var description: String {
        switch self {
        case .rhythmMachine: return "従来の正確でシンプルな定型ビート。ループ練習に最適。"
        case .standard: return "オーソドックスな8ビート・16ビートドラマー。セクション展開に合わせたシンプルな変化のみ。"
        case .mark: return "パワフル・ロックドラマー。力強いビートと多彩なフィルイン。サビ前でのド派手なタム回しが特徴。"
        case .leo: return "ファンク＆ネオソウル・ドラマー。跳ねる16分ゴーストスネアと細かいハットワーク、シンコペーションによるノリ。"
        case .sara: return "Lo-Fi ＆ Chill。少しモタったスネアと、心地よい揺らぎを感じるレイドバックしたグルーヴが特徴。"
        case .chad: return "メタル・ハードロックドラマー。パワフルなツーバスと派手なシンバルワークで激しくアグレッシブに叩きまくる。"
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
        case .mark: return 5.0
        case .leo: return 8.0
        case .sara: return 20.0  // レイドバック
        case .chad: return -10.0 // 前ノリ
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
            return true
            #else
            // Stub: 実際には UserDefaults や Keychain からリストアするか、StoreKit を参照します。
            return UserDefaults.standard.bool(forKey: "unlocked_drum_\(self.rawValue)")
            #endif
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "unlocked_drum_\(self.rawValue)")
        }
    }
}

// MARK: - Bass Player

enum BassPlayer: String, JamPlayer {
    case rhythmMachine
    case standard
    case kr
    case akiko
    case marcus
    case haruto

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rhythmMachine: return "Rhythm Machine"
        case .standard: return "Standard"
        case .kr: return "KR (Punk)"
        case .akiko: return "Akiko (Groove)"
        case .marcus: return "Marcus (Funk)"
        case .haruto: return "Haruto (Pop)"
        }
    }

    var iconName: String {
        switch self {
        case .rhythmMachine: return "metronome"
        case .standard: return "person"
        case .kr: return "person.fill.bolt"
        case .akiko: return "person.fill.viewfinder"
        case .marcus: return "person.fill.turn.down"
        case .haruto: return "person.wave.2.fill"
        }
    }

    var imageName: String {
        switch self {
        case .rhythmMachine: return "system:metronome"
        case .standard: return "system:person.fill"
        case .kr: return "Ba4"
        case .akiko: return "Ba2"
        case .marcus: return "Ba1"
        case .haruto: return "Ba3"
        }
    }

    var description: String {
        switch self {
        case .rhythmMachine: return "従来のルート音中心の定型パターン。"
        case .standard: return "オーソドックスなルート＆5度の安定したベース。"
        case .kr: return "パンク＆ロック・ドライヴ。8分音符でルート＆オクターブをゴリゴリ刻みまくる疾走感。サビ前でスライドを多用。"
        case .akiko: return "グルーヴィ・ウォーキング。スケール音や経過音（クロマチック）を縦横無尽に使い、次コードのルートへ滑らかにアプローチ。"
        case .marcus: return "ヘヴィ・ファンクベーシスト。スラップ奏法やゴーストノートを駆使し、タイトでノリの良いベースラインを刻む。"
        case .haruto: return "王道ポップ・ベーシスト。コード進行に寄り添うメロディアスで美しいベースライン。安定感抜群。"
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
        case .kr: return -8.0    // ドライブ感（前ノリ）
        case .akiko: return 5.0
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
            return true
            #else
            // Stub: 実際には UserDefaults や Keychain からリストアするか、StoreKit を参照します。
            return UserDefaults.standard.bool(forKey: "unlocked_bass_\(self.rawValue)")
            #endif
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "unlocked_bass_\(self.rawValue)")
        }
    }
}

// MARK: - Piano Player

enum PianoPlayer: String, JamPlayer {
    case rhythmMachine
    case standard
    case emi
    case jazzCat
    case ray
    case clara

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .rhythmMachine: return "Rhythm Machine"
        case .standard: return "Standard"
        case .emi: return "Emi (Pop)"
        case .jazzCat: return "JazzCat (Jazz)"
        case .ray: return "Ray (R&B)"
        case .clara: return "Clara (Classical)"
        }
    }

    var iconName: String {
        switch self {
        case .rhythmMachine: return "metronome"
        case .standard: return "person"
        case .emi: return "person.fill.star"
        case .jazzCat: return "person.fill.eyeglasses"
        case .ray: return "person.fill.turn.down"
        case .clara: return "person.wave.2.fill"
        }
    }

    var imageName: String {
        switch self {
        case .rhythmMachine: return "system:metronome"
        case .standard: return "system:person.fill"
        case .emi: return "Key2"
        case .jazzCat: return "Key1"
        case .ray: return "Key3"
        case .clara: return "Key4"
        }
    }

    var description: String {
        switch self {
        case .rhythmMachine: return "小節頭の全音符（白玉）のみ。"
        case .standard: return "オーソドックスなコード弾き。"
        case .emi: return "ポップ・コンピング。Bメロからのリズミカルなコンピングやサビでの力強いプッシュ。"
        case .jazzCat: return "テンションコードとシンコペーションを多用するオシャレなジャズピアニスト。"
        case .ray: return "R&B / レゲエ・キーボーディスト。裏打ちのバッキングや、ブルージーな装飾音符を得意とし、時折ロックなアプローチも見せる。"
        case .clara: return "クラシック出身のピアニスト。流麗なアルペジオを自在に操り、コード進行を優雅かつ壮大に彩るプレイが魅力。"
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
        case .emi: return 2.0
        case .jazzCat: return 10.0 // 少しタメる
        case .ray: return 15.0     // レイドバック
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
            return true
            #else
            // Stub: 実際には UserDefaults や Keychain からリストアするか、StoreKit を参照します。
            return UserDefaults.standard.bool(forKey: "unlocked_piano_\(self.rawValue)")
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

class StoreManager: ObservableObject {
    @Published var isPremium: Bool = false
    
    // シミュレーターでのテスト用にトグルするためのメソッド
    func togglePremium() {
        isPremium.toggle()
    }
    
    // 将来的にStoreKitを実装する想定
    func purchasePremium() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isPremium = true
        }
    }
}
