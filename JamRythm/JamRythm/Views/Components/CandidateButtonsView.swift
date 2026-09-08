//
//  CandidateButtonsView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI

// MARK: - コード候補選択ボタングリッド

/*
小節ごとに提示される4つの感情ラベル（安定、少し切ない、おしゃれ、緊張感）付きコード候補ボタン。
ユーザーがタップすることで、即座に進行に反映される。
*/
struct CandidateButtonsView: View {
    let candidates: [ChordCandidate]
    let selectedChord: Chord?
    let onSelect: (Chord) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CHORD CHOICES")
                .font(.caption.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal)

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(candidates) { candidate in
                    candidateButton(for: candidate)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - サブビュー

    /*
    個々の候補ボタンを描画する。
    
    Arguments:
    candidate
      感情ラベルとコード情報を持つChordCandidate。
    
    Usage:
    グリッド内で各候補ボタンを生成する際に呼び出される。
    */
    
    private func candidateButton(for candidate: ChordCandidate) -> some View {
        let isSelected = selectedChord == candidate.chord
        let flavorColor = colorForFlavor(candidate.flavor)

        return Button(action: {
            onSelect(candidate.chord)
        }) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(candidate.flavor.rawValue)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(flavorColor.opacity(0.2))
                        .foregroundColor(flavorColor)
                        .cornerRadius(4)
                    Spacer()
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(flavorColor)
                            .font(.caption)
                    }
                }

                Text(candidate.chord.displayString)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? flavorColor.opacity(0.15) : Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? flavorColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    /*
    感情ラベルに応じたテーマカラーを返す。
    
    Arguments:
    flavor
      ChordFlavor列挙値。
    
    Usage:
    ボタンの背景・ボーダー・バッジのカラーリングに使用される。
    */
    
    private func colorForFlavor(_ flavor: ChordFlavor) -> Color {
        switch flavor {
        case .stable:
            return Color.blue
        case .melancholy:
            return Color.purple
        case .stylish:
            return Color.orange
        case .tension:
            return Color.red
        }
    }
}
