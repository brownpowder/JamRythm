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
    @ObservedObject var store = StoreManager.shared
    @StateObject private var tourManager = TourManager.shared

    @State private var selectedCategory: SongStructureCategory = .fullSong

    private var filteredStructures: [SongStructureTemplate] {
        SongStructureTemplate.allStructures.filter { $0.category == selectedCategory }
    }

    var body: some View {
        ZStack {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    categoryPicker
                    headerDescription
                    randomGenerationCard

                    ForEach(filteredStructures) { structure in
                        structureCard(structure)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("曲を生成")
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
        TourOverlayView(spaceName: "SheetTourSpace")
        }
        .environmentObject(tourManager)
    }

    // MARK: - カテゴリ切り替えセグメント

    /*
    1コーラスと1曲丸ごとの表示カテゴリを切り替えるセグメントピッカー。

    Arguments:
    なし

    Usage:
    シートの最上段に配置され、一覧をフィルタリングする。
    */

    private var categoryPicker: some View {
        Picker("規模", selection: $selectedCategory) {
            ForEach(SongStructureCategory.allCases) { cat in
                Text(LocalizedStringKey(cat.rawValue)).tag(cat)
            }
        }
        .pickerStyle(.segmented)
    }

    // MARK: - ヘッダー説明文

    /*
    シート上部に表示するガイド説明文。選択中カテゴリの解説を表示する。

    Arguments:
    なし

    Usage:
    ScrollView内の上段に配置される。
    */

    private var headerDescription: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundColor(.accentColor)

            Text(LocalizedStringKey(selectedCategory.description))
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08))
        .cornerRadius(10)
    }

    // MARK: - ランダム自動生成カード

    /*
    音楽理論に基づき、セクションとコード進行をランダムに組み合わせて楽曲を一括自動生成するカード。

    Arguments:
    なし

    Usage:
    プリセット一覧の先頭に配置され、ワンタップで新鮮な構成を生成する。
    */

    private var randomGenerationCard: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            viewModel.generateAndApplyRandomSongStructure(category: selectedCategory)
            dismiss()
        }) {
            VStack(alignment: .leading, spacing: 6) {
                Text("おまかせランダム生成")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    Text("🎲 ランダム")
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(6)

                    Text("\(NSLocalizedString(selectedCategory.rawValue, comment: "")) " + NSLocalizedString("のセクションとコード進行を自動生成", comment: ""))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        
                    Spacer()
                    
                    Image(systemName: "wand.and.stars")
                        .font(.caption2.bold())
                        .foregroundColor(.orange)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        LinearGradient(
                            colors: [.orange.opacity(0.6), .pink.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
        }
        .buttonStyle(.plain)
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

                Text(LocalizedStringKey(structure.description))
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
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStringKey(structure.name))
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)

            HStack(spacing: 8) {
                Text(LocalizedStringKey(structure.recommendedGenre.displayName))
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundColor(.accentColor)
                    .cornerRadius(6)

                Text("BPM \(Int(structure.recommendedBpm))")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .cornerRadius(6)

                Text("\(structure.totalMeasures) " + NSLocalizedString("Bars", comment: ""))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(uiColor: .tertiarySystemFill))
                    .cornerRadius(6)
                    
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
                    .foregroundColor(Color(uiColor: .tertiaryLabel))
            }
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
                    Text(LocalizedStringKey(sec.type.displayName))
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
