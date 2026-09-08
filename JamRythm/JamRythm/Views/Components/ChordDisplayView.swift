//
//  ChordDisplayView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI

// MARK: - 特大コード表示コンポーネント

/*
譜面台（距離60cm〜80cm）からでもハッキリ見える、視認性最優先の特大コード表示ビュー。
現在演奏すべき「Current Chord」と、次に備える「Next Chord」を表示する。
*/
struct ChordDisplayView: View {
    let currentChord: Chord
    let nextChord: Chord
    let bassNote: String
    let baseDegree: Int

    var body: some View {
        VStack(spacing: 8) {
            // ベース土台情報（控えめに表示）
            HStack(spacing: 8) {
                Label("Rhythm Section (Bass)", systemImage: "waveform")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(bassNote) (Degree \(baseDegree))")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.15))
                    .cornerRadius(6)
            }

            // メインの特大コード表示
            HStack(alignment: .lastTextBaseline, spacing: 24) {
                // 現在のコード
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT")
                        .font(.caption.bold())
                        .foregroundColor(.accentColor)
                    Text(currentChord.displayString)
                        .font(.system(size: 68, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                Spacer()

                // 次のコード（少し小さめ）
                VStack(alignment: .trailing, spacing: 2) {
                    Text("NEXT")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Text(nextChord.displayString)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.horizontal)
    }
}
