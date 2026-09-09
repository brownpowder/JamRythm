//
//  SongStructureSheetView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/09.
//

import SwiftUI

// MARK: - 楽曲構成自動生成シート

/*
1コーラスまたは1曲分の楽曲構成テンプレート一覧をカード形式で表示し、
タップで一括適用するモーダルシートコンポーネント。
*/
struct SongStructureSheetView: View {
    @ObservedObject var viewModel: PlayEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    headerDescription

                    ForEach(SongStructureTemplate.allStructures) { structure in
                        structureCard(structure)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("楽曲構成を自動生成")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - ヘッダー説明文

    /*
    シート最上部に表示するガイド説明文。

    Arguments:
    なし

    Usage:
    ScrollView内の最上段に配置される。
    */

    private var headerDescription: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundColor(.accentColor)

            Text("プリセットを選ぶと、イントロからサビ・アウトロまでのセクションとコード進行が一括で生成されます。")
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08))
        .cornerRadius(10)
    }

    // MARK: - 楽曲構成カード

    /*
    楽曲構成テンプレート1件分のカードビューを描画する。

    Arguments:
    structure
      描画対象のSongStructureTemplate。

    Usage:
    ForEach内で各プリセットの選択ボタンとして描画される。
    */

    private func structureCard(_ structure: SongStructureTemplate) -> some View {
        Button(action: {
            viewModel.applySongStructure(structure)
            dismiss()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                cardHeader(for: structure)
                sectionFlowRow(for: structure)

                Text(structure.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.secondary.opacity(0.12), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    /*
    構成カードの上段ヘッダー（アイコン、構成名、小節タグ、推奨ジャンル）を描画する。

    Arguments:
    structure
      描画対象のSongStructureTemplate。

    Usage:
    structureCardの上部に配置される。
    */

    private func cardHeader(for structure: SongStructureTemplate) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 36, height: 36)

                Image(systemName: structure.iconName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(structure.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    Text(structure.recommendedGenre.displayName)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)
                }
            }

            Spacer()

            HStack(spacing: 5) {
                Text("BPM \(Int(structure.recommendedBpm))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .cornerRadius(6)

                Text("\(structure.totalMeasures)小節")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .cornerRadius(6)
            }

            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
    }

    /*
    楽曲構成に含まれるセクションフローバッジ列（Intro → Aメロ → Bメロ → サビ 等）を描画する。

    Arguments:
    structure
      描画対象のSongStructureTemplate。

    Usage:
    structureCardの中央に配置される。
    */

    private func sectionFlowRow(for structure: SongStructureTemplate) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                ForEach(Array(structure.sections.enumerated()), id: \.offset) { index, sec in
                    Text(sec.type.displayName)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(sec.type.displayColor.opacity(0.2))
                        .cornerRadius(5)

                    if index < structure.sections.count - 1 {
                        Text("→")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.6))
                    }
                }
            }
        }
    }
}
