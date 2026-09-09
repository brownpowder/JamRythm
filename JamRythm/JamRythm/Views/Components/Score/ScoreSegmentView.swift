//
//  ScoreSegmentView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI

// MARK: - 表示モード列挙型

enum ScoreDisplayMode: String, CaseIterable, Identifiable {
    case tab = "🎸 ギターTAB"
    case staff = "🎼 五線譜"

    var id: String { rawValue }
}

// MARK: - スコア表示セグメントラッパービュー

/*
ギターTAB譜と五線譜の表示を切り替えるコンテナビュー。
ユーザーのプレイスタイルや楽器に応じて好みのビューを選択できる。
*/
struct ScoreSegmentView: View {
    let voicing: GuitarVoicing
    let notes: [StaffNote]
    let chordName: String

    @State private var displayMode: ScoreDisplayMode = .tab

    var body: some View {
        VStack(spacing: 10) {
            // 切り替えセグメントコントロール
            Picker("Score Mode", selection: $displayMode) {
                ForEach(ScoreDisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 4)

            // 選択された譜面ビューの表示（高さを130ptに完全固定）
            Group {
                switch displayMode {
                case .tab:
                    GuitarTabView(voicing: voicing, chordName: chordName)
                case .staff:
                    StaffScoreView(notes: notes, chordName: chordName)
                }
            }
            .frame(height: 130)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}
