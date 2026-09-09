//
//  PlayEditorView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI

// MARK: - メインプレイエディタ画面

/*
伴奏再生、コード表示、コード候補選択を統合したアプリの中核ビュー。
上部にKeyおよびコード進行選択の固定ヘッダー、
中央にスクロール可能な演奏情報エリア（拍タイムライン、特大コード、譜面、フレーバー候補）、
下部にPlay/Stop、テンポ、音量を集約した固定フッターを配置する。
*/
@MainActor
struct PlayEditorView: View {
    @StateObject private var viewModel: PlayEditorViewModel

    init(viewModel: PlayEditorViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? PlayEditorViewModel())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    // 1. 小節進行 & 拍インジケーター（一時コメントアウト）
                    /*
                    if let measures = viewModel.project.sections.first?.measures {
                        BeatTimelineView(
                            measures: measures,
                            currentMeasureIndex: viewModel.currentMeasureIndex,
                            currentBeat: viewModel.currentBeat
                        )
                    }
                    */

                    // 1. 一体型コード選択カード（CURRENT / NEXT 特大表示 ＋ 4フレーバー候補選択 ＋ 代理コード提案）
                    ChordDisplayView(
                        currentChord: viewModel.currentChord,
                        nextChord: viewModel.nextChord,
                        candidates: viewModel.currentCandidates,
                        substituteCandidates: viewModel.currentSubstituteCandidates,
                        selectedChord: currentSelectedChord,
                        onSelect: { selected in
                            viewModel.selectChord(selected, forMeasureIndex: viewModel.currentMeasureIndex)
                        }
                    )

                    // 2. 譜面エリア（ギターTAB譜 / 五線譜）
                    ScoreSegmentView(
                        voicing: viewModel.currentVoicing,
                        notes: viewModel.currentStaffNotes,
                        chordName: viewModel.currentChord.displayString
                    )
                }
                .padding(.vertical, 14)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 0) {
                    topHeaderView
                    Divider()
                }
                .background(Color(uiColor: .systemBackground))
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    Divider()
                    PlaybackControlsView(
                        isPlaying: viewModel.isPlaying,
                        bpm: viewModel.project.bpm,
                        volume: viewModel.volume,
                        onTogglePlay: { viewModel.togglePlay() },
                        onBPMChange: { viewModel.changeBPM($0) },
                        onVolumeChange: { viewModel.changeVolume($0) },
                        onOpenMixer: { viewModel.isShowingMixer = true }
                    )
                }
                .background(Color(uiColor: .secondarySystemBackground))
            }
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $viewModel.isShowingMixer) {
                MixerView(viewModel: viewModel)
                    .presentationDetents([.fraction(0.55), .medium])
                    .presentationDragIndicator(.visible)
            }
            .alert("エラー", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {
                    viewModel.errorMessage = nil
                }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    // MARK: - 固定ヘッダーサブビュー

    /*
    Key選択ボタンおよびコード進行選択ボタンを左詰めで配置した固定ヘッダーを描画する。
    
    Arguments:
    なし
    
    Usage:
    画面最上部の固定バーとして使用される。
    */
    
    private var topHeaderView: some View {
        HStack(spacing: 10) {
            // Key選択ボタン（Key名 + 下矢印）
            keyMenuButton

            // コード進行選択ボタン（進行名 + 下矢印）
            progressionMenuButton

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }

    /*
    調（Key）を1タップで変更できるコンパクトなドロップダウンメニューを描画する。
    
    Arguments:
    なし
    
    Usage:
    topHeaderViewの左端に配置される。
    */
    
    private var keyMenuButton: some View {
        Menu {
            ForEach(Key.allCases) { key in
                Button(action: { viewModel.changeKey(key) }) {
                    if key == viewModel.project.key {
                        Label(key.rawValue, systemImage: "checkmark")
                    } else {
                        Text(key.rawValue)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(viewModel.project.key.rawValue)
                    .font(.headline.bold())
                    .foregroundColor(.primary)

                Image(systemName: "chevron.down")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(10)
        }
    }

    /*
    コード進行テンプレートを切り替えるドロップダウンメニューを描画する。
    
    Arguments:
    なし
    
    Usage:
    topHeaderViewのKeyメニュー横に配置される。
    */
    
    private var progressionMenuButton: some View {
        Menu {
            ForEach(ProgressionTemplate.allTemplates) { template in
                Button(action: { viewModel.applyTemplate(template) }) {
                    if template.id == viewModel.selectedTemplate.id {
                        Label(template.name, systemImage: "checkmark")
                    } else {
                        Text(template.name)
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(viewModel.selectedTemplate.name)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Image(systemName: "chevron.down")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(Color(uiColor: .secondarySystemBackground))
            .cornerRadius(10)
        }
    }

    // MARK: - 計算プロパティ (ヘルパー)

    /*
    現在再生中の小節のベース音名を返す。
    
    Arguments:
    なし
    
    Usage:
    ChordDisplayViewのベース音表示に使用される。
    */
    
    private var currentMeasureBassNote: String {
        guard let measures = viewModel.project.sections.first?.measures,
              viewModel.currentMeasureIndex < measures.count else {
            return "C"
        }
        return measures[viewModel.currentMeasureIndex].bassNote
    }

    /*
    現在再生中の小節の度数を返す。
    
    Arguments:
    なし
    
    Usage:
    ChordDisplayViewの度数表示に使用される。
    */
    
    private var currentMeasureDegree: Int {
        guard let measures = viewModel.project.sections.first?.measures,
              viewModel.currentMeasureIndex < measures.count else {
            return 1
        }
        return measures[viewModel.currentMeasureIndex].baseDegree
    }

    /*
    現在再生中の小節で選択されているコードを返す。
    
    Arguments:
    なし
    
    Usage:
    CandidateButtonsViewの選択状態ハイライト判定に使用される。
    */
    
    private var currentSelectedChord: Chord? {
        guard let measures = viewModel.project.sections.first?.measures,
              viewModel.currentMeasureIndex < measures.count else {
            return nil
        }
        return measures[viewModel.currentMeasureIndex].selectedChord
    }
}

#Preview {
    PlayEditorView()
}
