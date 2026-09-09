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

                    // 1. 一体型コード選択カード（PREV / CURRENT / NEXT 表示 ＋ 4フレーバー候補選択 ＋ 代理コード提案）
                    ChordDisplayView(
                        previousChord: viewModel.previousChord,
                        currentChord: viewModel.currentChord,
                        nextChord: viewModel.nextChord,
                        candidates: viewModel.currentCandidates,
                        substituteCandidates: viewModel.currentSubstituteCandidates,
                        selectedChord: currentSelectedChord,
                        onSelect: { selected in
                            viewModel.selectChord(selected, forMeasureIndex: viewModel.currentMeasureIndex)
                        },
                        onPrevious: {
                            viewModel.moveToPreviousMeasure()
                        },
                        onNext: {
                            viewModel.moveToNextMeasure()
                        },
                        onPlayChord: { chord in
                            viewModel.playChordPreview(chord)
                        }
                    )

                    // 2. 譜面エリア（ギターTAB譜 / 五線譜）
                    ScoreSegmentView(
                        voicing: viewModel.currentVoicing,
                        notes: viewModel.currentStaffNotes,
                        chordName: viewModel.currentChord.displayString
                    )

                    // 3. 進行・セクション＆小節コード一覧（セクション追加・編集・全曲構成）
                    SectionTimelineBarView(viewModel: viewModel)
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
    Key選択ボタンを配置した固定ヘッダーを描画する。
    
    Arguments:
    なし
    
    Usage:
    画面最上部の固定バーとして使用される。
    */
    
    private var topHeaderView: some View {
        HStack(spacing: 10) {
            // Key選択ボタン（Key名 + 下矢印）
            keyMenuButton

            Spacer()

            if viewModel.activeSection != nil {
                Text("Section \(viewModel.selectedSectionIndex + 1)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(uiColor: .tertiarySystemBackground))
                    .cornerRadius(6)
            }
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
                Text("Key: \(viewModel.project.key.rawValue)")
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

    // MARK: - 計算プロパティ (ヘルパー)

    /*
    現在再生中の小節のベース音名を返す。
    
    Arguments:
    なし
    
    Usage:
    ChordDisplayViewのベース音表示に使用される。
    */
    
    private var currentMeasureBassNote: String {
        guard let measures = viewModel.activeSection?.measures,
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
        guard let measures = viewModel.activeSection?.measures,
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
        guard let measures = viewModel.activeSection?.measures,
              viewModel.currentMeasureIndex < measures.count else {
            return nil
        }
        return measures[viewModel.currentMeasureIndex].selectedChord
    }
}

#Preview {
    PlayEditorView()
}
