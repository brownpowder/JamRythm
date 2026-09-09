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
    let previousChord: Chord?
    let currentChord: Chord
    let nextChord: Chord?
    let candidates: [ChordCandidate]
    let substituteCandidates: [SubstituteCandidate]
    let selectedChord: Chord?
    let onSelect: (Chord) -> Void
    var onPrevious: (() -> Void)? = nil
    var onNext: (() -> Void)? = nil
    var onPlayChord: ((Chord) -> Void)? = nil

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        VStack(spacing: 12) {
            // 上段: PREV・CURRENT・NEXT コード表示
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
    前のコード（PREV）、現在のコード（CURRENT・特大中央）、次のコード（NEXT）を横並びで表示する上段ヘッダー。
    PREVタップで1小節戻り、NEXTタップで1小節進み、CURRENTタップでコードの試聴音を再生する。曲頭ではPREVが、曲末尾ではNEXTが非表示になる。
    
    Arguments:
    なし
    
    Usage:
    カード上部に配置され、現在の演奏進行を特大フォントで明示するとともに素早いナビゲーションを提供する。
    */
    
    private var chordHeaderRow: some View {
        HStack(alignment: .center, spacing: 8) {
            // 前のコード（PREV / PRE）
            if let prev = previousChord {
                Button(action: {
                    onPrevious?()
                }) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 3) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 8, weight: .bold))
                            Text("PREV")
                                .font(.caption2.bold())
                        }
                        .foregroundColor(.secondary)

                        Text(prev.displayString)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(width: 75, height: 56, alignment: .leading)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear
                    .frame(width: 75, height: 56)
            }

            Spacer(minLength: 0)

            // 現在のコード（CURRENT）特大中央表示
            Button(action: {
                onPlayChord?(currentChord)
            }) {
                VStack(alignment: .center, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("CURRENT")
                            .font(.caption2.bold())
                            .foregroundColor(.accentColor)
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.accentColor.opacity(0.7))
                    }

                    Text(currentChord.displayString)
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .frame(height: 56)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)

            // 次のコード（NEXT）
            if let next = nextChord {
                Button(action: {
                    onNext?()
                }) {
                    VStack(alignment: .trailing, spacing: 2) {
                        HStack(spacing: 3) {
                            Text("NEXT")
                                .font(.caption2.bold())
                            Image(systemName: "chevron.right")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(.secondary)

                        Text(next.displayString)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .frame(width: 75, height: 56, alignment: .trailing)
                }
                .buttonStyle(.plain)
            } else {
                Color.clear
                    .frame(width: 75, height: 56)
            }
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
