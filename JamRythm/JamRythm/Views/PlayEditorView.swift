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
ViewModelを監視し、譜面台に置いた演奏時の使い勝手と視認性を最大化する。
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
                VStack(spacing: 20) {
                    // 1. 小節進行 & 拍インジケーター
                    if let measures = viewModel.project.sections.first?.measures {
                        BeatTimelineView(
                            measures: measures,
                            currentMeasureIndex: viewModel.currentMeasureIndex,
                            currentBeat: viewModel.currentBeat
                        )
                    }

                    // 2. 特大コード表示
                    ChordDisplayView(
                        currentChord: viewModel.currentChord,
                        nextChord: viewModel.nextChord,
                        bassNote: currentMeasureBassNote,
                        baseDegree: currentMeasureDegree
                    )

                    // 3. コード候補選択ボタングリッド
                    CandidateButtonsView(
                        candidates: viewModel.currentCandidates,
                        selectedChord: currentSelectedChord,
                        onSelect: { selected in
                            viewModel.selectChord(selected, forMeasureIndex: viewModel.currentMeasureIndex)
                        }
                    )

                    // 4. 再生コントロール & 設定
                    PlaybackControlsView(
                        isPlaying: viewModel.isPlaying,
                        bpm: viewModel.project.bpm,
                        currentKey: viewModel.project.key,
                        currentTemplate: viewModel.selectedTemplate,
                        onTogglePlay: { viewModel.togglePlay() },
                        onBPMChange: { viewModel.changeBPM($0) },
                        onKeyChange: { viewModel.changeKey($0) },
                        onTemplateChange: { viewModel.applyTemplate($0) }
                    )
                }
                .padding(.vertical)
            }
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("Jam-Rythm")
            .navigationBarTitleDisplayMode(.inline)
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
