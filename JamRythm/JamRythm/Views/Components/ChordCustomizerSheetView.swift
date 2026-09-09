//
//  ChordCustomizerSheetView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/09.
//

import SwiftUI

// MARK: - カスタムコード編集シート

/*
ユーザーがルート音、コードタイプ（基本三和音、セブンス、sus、dim、テンション〜13）、
およびベース音（オンコード・分数コード）を自由に組み上げて小節に適用できるモーダルシート。
*/
struct ChordCustomizerSheetView: View {
    @ObservedObject var viewModel: PlayEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var selectedRoot: String
    @State private var selectedType: String
    @State private var selectedBass: String

    // MARK: - 定義プリセット一覧

    private let rootNotes = ["C", "D♭", "D", "E♭", "E", "F", "G♭", "G", "A♭", "A", "B♭", "B"]

    private let basicTypes: [(label: String, type: String)] = [
        ("Major", ""),
        ("Minor (m)", "m"),
        ("sus4", "sus4"),
        ("aug", "aug"),
        ("dim", "dim")
    ]

    private let seventhTypes: [(label: String, type: String)] = [
        ("7", "7"),
        ("maj7", "maj7"),
        ("m7", "m7"),
        ("mM7", "mM7"),
        ("7sus4", "7sus4"),
        ("m7b5", "m7b5"),
        ("dim7", "dim7"),
        ("6", "6"),
        ("m6", "m6")
    ]

    private let tensionTypes: [(label: String, type: String)] = [
        ("add9", "add9"),
        ("9", "9"),
        ("maj9", "maj9"),
        ("m9", "m9"),
        ("11", "11"),
        ("m11", "m11"),
        ("13", "13"),
        ("maj13", "maj13"),
        ("7(b9)", "7(b9)"),
        ("7(#9)", "7(#9)"),
        ("7(#11)", "7(#11)"),
        ("7(b13)", "7(b13)")
    ]

    init(viewModel: PlayEditorViewModel) {
        self.viewModel = viewModel
        let current = viewModel.currentChord
        _selectedRoot = State(initialValue: current.rootNote)
        _selectedType = State(initialValue: current.type)
        _selectedBass = State(initialValue: current.bassNote ?? "")
    }

    // MARK: - 組み立てコード

    private var builtChord: Chord {
        let bass = selectedBass.isEmpty || selectedBass == selectedRoot ? nil : selectedBass
        return Chord(rootNote: selectedRoot, type: selectedType, bassNote: bass)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    chordPreviewHeader

                    rootSelectorSection

                    chordTypeSection

                    bassSelectorSection
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("コードをカスタマイズ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("適用") {
                        viewModel.setCustomChord(builtChord)
                        dismiss()
                    }
                    .bold()
                }
            }
            .safeAreaInset(edge: .bottom) {
                applyActionButton
            }
        }
    }

    // MARK: - コードプレビューヘッダー

    /*
    現在組み上げ中のコード名（特大）と試聴ボタンを描画する。
    */

    private var chordPreviewHeader: some View {
        let comp = viewModel.theoryService.chordCompatibility(
            chord: builtChord,
            key: viewModel.project.key,
            baseDegree: viewModel.editingBaseDegree,
            originalChord: viewModel.editingOriginalChord
        )

        return VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(viewModel.editingMeasureTitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.12))
                    .cornerRadius(6)

                // スムーズ度バッジ
                HStack(spacing: 4) {
                    Image(systemName: comp.badgeIcon)
                        .font(.system(size: 10, weight: .bold))
                    Text(comp.badgeText)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(compatibilityColor(comp))
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(compatibilityColor(comp).opacity(0.14))
                .cornerRadius(6)
            }

            HStack(spacing: 12) {
                Text(builtChord.displayString)
                    .font(.system(size: 38, weight: .black, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)

                Button(action: {
                    viewModel.playChordPreview(builtChord)
                }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .padding(10)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(Circle())
                }
            }

            // 案内凡例バナー
            HStack(spacing: 6) {
                Image(systemName: "circle.circle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.accentColor)
                Text("濃い色ほど、現在の進行（Key: \(viewModel.project.key.rawValue)）に破綻せずスムーズに調和します")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: - ① ルート音選択セクション

    /*
    12の半音からコードのRoot音を選択するグリッドを描画する。
    Keyおよび小節度数との親和性（スムーズ度）に応じてボタンの濃淡が変化する。
    */

    private var rootSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("1. ルート音 (Root)", subtitle: "コードの基準となる土台の音（濃い色ほどスムーズに調和）")

            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(rootNotes, id: \.self) { note in
                    let isSelected = (selectedRoot == note)
                    let comp = viewModel.theoryService.rootCompatibility(
                        root: note,
                        key: viewModel.project.key,
                        baseDegree: viewModel.editingBaseDegree
                    )

                    Button(action: {
                        selectedRoot = note
                        viewModel.playChordPreview(builtChord)
                    }) {
                        Text(note)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(isSelected ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(rootButtonFill(comp: comp, isSelected: isSelected))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(rootButtonStroke(comp: comp, isSelected: isSelected), lineWidth: isSelected ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - ② コードタイプ選択セクション

    /*
    三和音、セブンス、テンション系コードタイプを選択するエリアを描画する。
    */

    private var chordTypeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("2. コードの響き (Quality & Tension)", subtitle: "選択中のRootに対して破綻しない響きほど濃い色で表示")

            VStack(alignment: .leading, spacing: 6) {
                Text("基本三和音 / サス")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)

                typeButtonGrid(items: basicTypes, columnsCount: 5)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("セブンス / ディミニッシュ")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)

                typeButtonGrid(items: seventhTypes, columnsCount: 4)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("テンション (〜13th / オルタード)")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)

                typeButtonGrid(items: tensionTypes, columnsCount: 4)
            }
        }
    }

    /*
    コードタイプボタンのグリッドを生成するヘルパー。
    選択中のルート音と組み合わせた親和性（スムーズ度）に応じてボタンの濃淡が変化する。
    */

    private func typeButtonGrid(items: [(label: String, type: String)], columnsCount: Int) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: columnsCount)
        return LazyVGrid(columns: columns, spacing: 6) {
            ForEach(items, id: \.type) { item in
                let isSelected = (selectedType == item.type)
                let testChord = Chord(rootNote: selectedRoot, type: item.type, bassNote: nil)
                let comp = viewModel.theoryService.chordCompatibility(
                    chord: testChord,
                    key: viewModel.project.key,
                    baseDegree: viewModel.editingBaseDegree,
                    originalChord: viewModel.editingOriginalChord
                )

                Button(action: {
                    selectedType = item.type
                    viewModel.playChordPreview(builtChord)
                }) {
                    Text(item.label)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(typeButtonFill(comp: comp, isSelected: isSelected))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(typeButtonStroke(comp: comp, isSelected: isSelected), lineWidth: isSelected ? 2 : 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - ③ ベース音（オンコード）選択セクション

    /*
    分数コード用のベース音を選択するエリアを描画する。
    */

    private var bassSelectorSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                sectionTitle("3. ベース音 (On-Chord / 分数コード)", subtitle: "ルートと異なるベース音で浮遊感やクリシェを演出")
                Spacer()
                if !selectedBass.isEmpty {
                    Button("リセット") {
                        selectedBass = ""
                        viewModel.playChordPreview(builtChord)
                    }
                    .font(.caption.bold())
                    .foregroundColor(.accentColor)
                }
            }

            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 6)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(rootNotes, id: \.self) { note in
                    let isSelected = (selectedBass == note)
                    Button(action: {
                        selectedBass = (selectedBass == note) ? "" : note
                        viewModel.playChordPreview(builtChord)
                    }) {
                        Text("/\(note)")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(isSelected ? .white : .primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelected ? Color.purple : Color(uiColor: .secondarySystemGroupedBackground))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - 下部適用ボタン

    /*
    シート最下部に固定表示する適用アクションボタンを描画する。
    */

    private var applyActionButton: some View {
        Button(action: {
            viewModel.setCustomChord(builtChord)
            dismiss()
        }) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.subheadline.bold())
                Text("このコードを小節に適用: \(builtChord.displayString)")
                    .font(.subheadline.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 13)
            .background(Color.accentColor)
            .cornerRadius(12)
            .shadow(color: Color.accentColor.opacity(0.3), radius: 6, y: 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(uiColor: .systemGroupedBackground).opacity(0.95))
    }

    /*
    セクション見出しタイトルとサブタイトルを描画するヘルパー。
    */

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.primary)
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - 親和性カラーヘルパー

    /*
    親和性レベルに応じたテーマカラーを返す。

    Arguments:
    comp
      和声的親和性（HarmonicCompatibility）。

    Usage:
    プレビューバッジやボタン背景の濃淡生成に使用される。
    */

    private func compatibilityColor(_ comp: HarmonicCompatibility) -> Color {
        switch comp {
        case .verySmooth: return .green
        case .smooth: return .purple
        case .flavorful: return .orange
        case .dissonant: return .secondary
        }
    }

    /*
    ルート音選択ボタンの背景色（選択状態または親和性の濃淡）を算出する。

    Arguments:
    comp
      ルート音の親和性。
    isSelected
      現在選択中かどうか。

    Usage:
    rootSelectorSectionの各ボタン背景描画で使用される。
    */

    private func rootButtonFill(comp: HarmonicCompatibility, isSelected: Bool) -> Color {
        if isSelected {
            return .accentColor
        }
        switch comp {
        case .verySmooth: return Color.accentColor.opacity(0.35)
        case .smooth: return Color.accentColor.opacity(0.18)
        case .flavorful: return Color.accentColor.opacity(0.08)
        case .dissonant: return Color(uiColor: .secondarySystemGroupedBackground)
        }
    }

    /*
    ルート音選択ボタンの枠線色を算出する。

    Arguments:
    comp
      ルート音の親和性。
    isSelected
      現在選択中かどうか。

    Usage:
    rootSelectorSectionの各ボタン枠線描画で使用される。
    */

    private func rootButtonStroke(comp: HarmonicCompatibility, isSelected: Bool) -> Color {
        if isSelected {
            return .accentColor
        }
        switch comp {
        case .verySmooth: return Color.accentColor.opacity(0.70)
        case .smooth: return Color.accentColor.opacity(0.40)
        case .flavorful: return Color.accentColor.opacity(0.20)
        case .dissonant: return Color.secondary.opacity(0.12)
        }
    }

    /*
    コードタイプボタンの背景色（選択状態または親和性の濃淡）を算出する。
    ルート音選択と同様に、アクセントカラーの濃淡（濃いほどスムーズ）で統一する。

    Arguments:
    comp
      コードタイプの親和性。
    isSelected
      現在選択中かどうか。

    Usage:
    typeButtonGridの各ボタン背景描画で使用される。
    */

    private func typeButtonFill(comp: HarmonicCompatibility, isSelected: Bool) -> Color {
        if isSelected {
            return .orange
        }
        switch comp {
        case .verySmooth: return Color.accentColor.opacity(0.35)
        case .smooth: return Color.accentColor.opacity(0.18)
        case .flavorful: return Color.accentColor.opacity(0.08)
        case .dissonant: return Color(uiColor: .secondarySystemGroupedBackground)
        }
    }

    /*
    コードタイプボタンの枠線色を算出する。
    ルート音選択と同様に、アクセントカラーの濃淡で統一する。

    Arguments:
    comp
      コードタイプの親和性。
    isSelected
      現在選択中かどうか。

    Usage:
    typeButtonGridの各ボタン枠線描画で使用される。
    */

    private func typeButtonStroke(comp: HarmonicCompatibility, isSelected: Bool) -> Color {
        if isSelected {
            return .orange
        }
        switch comp {
        case .verySmooth: return Color.accentColor.opacity(0.70)
        case .smooth: return Color.accentColor.opacity(0.40)
        case .flavorful: return Color.accentColor.opacity(0.20)
        case .dissonant: return Color.secondary.opacity(0.12)
        }
    }
}

