//
//  ChordDisplayView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI

// MARK: - 一体型コード表示＆選択コンポーネント

/*
現在演奏中の「Current Chord」と次に備える「Next Chord」の特大表示に加え、
小節の4つのフレーバーコード候補（安定、切ない、おしゃれ、緊張感）を1枚のカードに統合したビュー。
選択肢をタップすると直上のCurrent Chordがリアルタイムに切り替わる。
*/
struct ChordDisplayView: View {
    let currentChord: Chord
    let nextChord: Chord
    let candidates: [ChordCandidate]
    let substituteCandidates: [SubstituteCandidate]
    let selectedChord: Chord?
    let onSelect: (Chord) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 12) {
            // 上段: CURRENT & NEXT 特大コード表示
            chordHeaderRow

            Divider()
                .padding(.horizontal, 4)

            // 下段: 4つのフレーバーコード候補グリッド
            choicesSection

            if !substituteCandidates.isEmpty {
                Divider()
                    .padding(.horizontal, 4)

                substitutesSection
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    // MARK: - サブビュー

    /*
    現在のコードと次のコードを横並びで表示する上段ヘッダー。
    
    Arguments:
    なし
    
    Usage:
    カード上部に配置され、現在の演奏進行を特大フォントで明示する。
    */
    
    private var chordHeaderRow: some View {
        HStack(alignment: .center, spacing: 16) {
            // 現在のコード（Current）
            VStack(alignment: .leading, spacing: 2) {
                Text("CURRENT")
                    .font(.caption2.bold())
                    .foregroundColor(.accentColor)
                Text(currentChord.displayString)
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(height: 56)
            .frame(maxWidth: .infinity, alignment: .leading)

            // 次のコード（Next）
            VStack(alignment: .trailing, spacing: 2) {
                Text("NEXT")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                Text(nextChord.displayString)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 100, height: 56, alignment: .trailing)
        }
        .padding(.horizontal, 4)
    }

    /*
    4つのフレーバー（安定、切ない、おしゃれ、緊張感）コード候補ボタン群を描画する。
    
    Arguments:
    なし
    
    Usage:
    カード下部に配置され、ユーザーがタップしてコードを変更できる。
    */
    
    private var choicesSection: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(candidates) { candidate in
                candidateButton(for: candidate)
            }
        }
    }

    /*
    個別のコード候補ボタンを描画する。
    
    Arguments:
    candidate
      感情ラベルとコード情報を持つChordCandidate。
      choicesSectionのForEachから渡される。
    
    Usage:
    候補グリッド内で各ボタンを描画し、選択状態に応じてハイライト表示する。
    */
    
    private func candidateButton(for candidate: ChordCandidate) -> some View {
        let isSelected = selectedChord == candidate.chord
        let flavorColor = colorForFlavor(candidate.flavor)

        return Button(action: {
            onSelect(candidate.chord)
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(candidate.flavor.rawValue)
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(flavorColor.opacity(0.18))
                        .foregroundColor(flavorColor)
                        .cornerRadius(4)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(flavorColor)
                            .font(.caption2)
                    }
                }

                Text(candidate.chord.displayString)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? flavorColor.opacity(0.15) : Color(uiColor: .tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? flavorColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    /*
    代理コード（機能的代理・裏コード・サブドミナントマイナー等）の候補ボタン群を描画する。
    
    Arguments:
    なし
    
    Usage:
    フレーバー候補の下に配置され、別の進行バリエーションを提案する。
    */
    
    private var substitutesSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.swap")
                    .font(.caption2.bold())
                    .foregroundColor(.teal)
                Text("代理コード提案")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 2)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(substituteCandidates) { candidate in
                    substituteButton(for: candidate)
                }
            }
        }
    }

    /*
    個別の代理コード候補ボタンを描画する。
    
    Arguments:
    candidate
      代理コードのラベルとコード情報を持つSubstituteCandidate。
      substitutesSectionのForEachから渡される。
    
    Usage:
    代理コードグリッド内で各ボタンを描画し、選択状態に応じてハイライト表示する。
    */
    
    private func substituteButton(for candidate: SubstituteCandidate) -> some View {
        let isSelected = selectedChord == candidate.chord
        let accentColor = Color.teal

        return Button(action: {
            onSelect(candidate.chord)
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(candidate.label)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(accentColor.opacity(0.18))
                        .foregroundColor(accentColor)
                        .cornerRadius(4)
                        .lineLimit(1)

                    Spacer()

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(accentColor)
                            .font(.caption2)
                    }
                }

                Text(candidate.chord.displayString)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? accentColor.opacity(0.15) : Color(uiColor: .tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - ヘルパー

    /*
    感情ラベルに応じたテーマカラーを返す。
    
    Arguments:
    flavor
      ChordFlavor列挙値。
    
    Usage:
    ボタンのラベル、背景、選択ボーダーの色付けに使用される。
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
