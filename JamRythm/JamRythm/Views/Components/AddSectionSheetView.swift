//
//  AddSectionSheetView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/09.
//

import SwiftUI

// MARK: - セクション追加シート

/*
コード進行テンプレートを選択して新規セクションを追加する専用のモーダルシート。
各進行の度数・小節数・音楽的特徴をカード形式でリッチに一覧表示する。
*/
struct AddSectionSheetView: View {
    @ObservedObject var viewModel: PlayEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(ProgressionTemplate.allTemplates) { template in
                        templateCard(template)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("進行を選んでセクション追加")
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

    // MARK: - テンプレート選択カード

    /*
    コード進行テンプレート1件分のカードビューを描画する。

    Arguments:
    template
      描画対象のProgressionTemplate。allTemplatesから渡される。

    Usage:
    シート内のScrollViewのForEach内で各カードとして描画される。
    */

    private func templateCard(_ template: ProgressionTemplate) -> some View {
        Button(action: {
            viewModel.addSection(template: template)
            dismiss()
        }) {
            VStack(alignment: .leading, spacing: 10) {
                // 上段: アイコン + 進行名 + ジャンルタグ + 小節数
                cardHeader(for: template)

                // 中段: ディグリーネーム一覧バッジ
                degreesBadgeRow(for: template)

                // 下段: 音楽的解説文
                Text(template.description)
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
    テンプレートカードの上段ヘッダー（アイコン、名前、タグ、小節数）を描画する。

    Arguments:
    template
      対象のProgressionTemplate。

    Usage:
    templateCardの上部に配置される。
    */

    private func cardHeader(for template: ProgressionTemplate) -> some View {
        HStack(spacing: 10) {
            // アイコンバッジ
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.12))
                    .frame(width: 34, height: 34)

                Image(systemName: template.iconName)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(template.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)

                    Text(template.genreTag)
                        .font(.system(size: 10, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.12))
                        .foregroundColor(.accentColor)
                        .cornerRadius(6)
                }
            }

            Spacer()

            // 小節数バッジ
            Text("\(template.degrees.count)小節")
                .font(.caption2.bold())
                .foregroundColor(.secondary)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Color(uiColor: .tertiarySystemFill))
                .cornerRadius(6)

            Image(systemName: "chevron.right")
                .font(.caption2.bold())
                .foregroundColor(Color(uiColor: .tertiaryLabel))
        }
    }

    /*
    度数のローマ数字バッジ列（IV, V, III, VI等）を描画する。

    Arguments:
    template
      対象のProgressionTemplate。

    Usage:
    templateCardの中央列に配置される。
    */

    private func degreesBadgeRow(for template: ProgressionTemplate) -> some View {
        HStack(spacing: 6) {
            ForEach(Array(template.romanDegrees.enumerated()), id: \.offset) { index, roman in
                Text(roman)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .cornerRadius(5)

                if index < template.romanDegrees.count - 1 {
                    Text("→")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
        }
    }
}
