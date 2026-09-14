//
//  ScoreSegmentView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI

// MARK: - 表示モード列挙型

enum ScoreDisplayMode: String, CaseIterable, Identifiable {
    case tab = "TAB"
    case scale = "スケール"
    case staff = "五線譜"

    var id: String { rawValue }
}

// MARK: - スコア表示セグメントラッパービュー

/*
コードTAB譜、スケール指板（6弦/4弦切替）、五線譜の表示を切り替えるコンテナビュー。
ユーザーのプレイスタイルや楽器（ギター、ベース、鍵盤ソロ等）に応じて好みのビューを選択できる。
*/
struct ScoreSegmentView: View {
    let voicing: GuitarVoicing
    let notes: [StaffNote]
    let chordName: String
    var key: Key = .C
    var chord: Chord = Chord(rootNote: "C", type: "", bassNote: nil)
    var theoryService: MusicTheoryServiceProtocol = MusicTheoryService()

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

            // 選択された譜面ビューの表示（高さを190ptに完全固定）
            Group {
                switch displayMode {
                case .tab:
                    GuitarTabView(voicing: voicing, chordName: chordName)
                case .scale:
                    ScaleFretboardView(key: key, chord: chord, theoryService: theoryService)
                case .staff:
                    StaffScoreView(notes: notes, chordName: chordName)
                }
            }
            .frame(height: 190)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .padding(.horizontal)
    }
}
