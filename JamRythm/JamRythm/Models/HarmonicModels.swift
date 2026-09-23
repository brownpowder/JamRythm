//
//  MusicTheoryService.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import Foundation

// MARK: - スケール種別

/*
アドリブやメロディ演奏で使用するスケール種別（ペンタトニックまたはダイアトニック）。
*/
enum HarmonicCompatibility: Int, Comparable, CaseIterable, Identifiable {
    case verySmooth = 3   // 最も濃い: ダイアトニック、完全解決ドミナント（超自然・破綻ゼロ）
    case dramatic = 2     // 中濃: ドラマチック (エモい借用・サブドミナントマイナー・進行のフック)
    case flavorful = 1    // 淡い: スパイス (未解決ドミナント、裏コード、オルタード)
    case abstract = 0     // 通常無色: 挑戦的 (アブストラクト・不協和音)

    var id: Int { rawValue }

    // 既存コード互換エイリアス
    static var smooth: HarmonicCompatibility { .dramatic }
    static var dissonant: HarmonicCompatibility { .abstract }

    static func < (lhs: HarmonicCompatibility, rhs: HarmonicCompatibility) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var badgeText: String {
        switch self {
        case .verySmooth: return "✨ スムーズ (超自然)"
        case .dramatic: return "💜 ドラマチック (エモい)"
        case .flavorful: return "🔥 スパイス (個性派)"
        case .abstract: return "挑戦的 (アブストラクト)"
        }
    }

    var badgeIcon: String {
        switch self {
        case .verySmooth: return "sparkles"
        case .dramatic: return "heart.fill"
        case .flavorful: return "flame.fill"
        case .abstract: return "questionmark"
        }
    }

    var colorOpacity: Double {
        switch self {
        case .verySmooth: return 0.38
        case .dramatic: return 0.20
        case .flavorful: return 0.08
        case .abstract: return 0.0
        }
    }

    var strokeOpacity: Double {
        switch self {
        case .verySmooth: return 0.70
        case .dramatic: return 0.40
        case .flavorful: return 0.20
        case .abstract: return 0.0
        }
    }
}

// MARK: - 音名表記モード（英語 CDE ⇔ 日本語 ドレミ）

/*
譜面やバッジ等で音名を表示する際の表記体系。
英語圏では C, D, E が標準であり、日本語環境でのみ親しみやすい「ド, レ, ミ」への切替をサポートする。
*/
