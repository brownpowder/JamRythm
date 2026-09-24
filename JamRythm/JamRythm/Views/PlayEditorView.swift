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
    @State private var isShowingSettings = false
    @ObservedObject var store = StoreManager.shared

    init(project: Project? = nil) {
        _viewModel = StateObject(wrappedValue: PlayEditorViewModel(project: project))
    }

    var body: some View {
        Group {
            ScrollViewReader { proxy in
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

                    // 2. 譜面エリア（コードTAB譜 / スケール指板 / 五線譜）
                    ScoreSegmentView(
                        voicing: viewModel.currentVoicing,
                        notes: viewModel.currentStaffNotes,
                        chordName: viewModel.currentChord.displayString,
                        key: viewModel.project.key,
                        chord: viewModel.currentChord,
                        theoryService: viewModel.theoryService,
                        audioService: viewModel.audioService
                    )
                    .id("scoreSegment")

                    // 3. 進行・セクション＆小節コード一覧（セクション追加・編集・全曲構成）
                    SectionTimelineBarView(viewModel: viewModel)
                        .id("sectionTimeline")
                }
                .padding(.vertical, 14)
            }
            .onChange(of: TourManager.shared.currentStep) { step in
                print("📜 [PlayEditorView] ScrollView onChange step: \(step)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation {
                        if step == .step2_scrollAndTapGenerateMenu || step == .step4_viewGeneratedSong {
                            print("📜 [PlayEditorView] Scrolling to sectionTimeline")
                            proxy.scrollTo("sectionTimeline", anchor: .bottom)
                        } else if step == .step5_tapScaleFretboard || step == .step6_playGuitar || step == .step8_playWhilePlaying || step == .step9_tapInstrumentMenu || step == .step11_playPiano {
                            print("📜 [PlayEditorView] Scrolling to scoreSegment")
                            proxy.scrollTo("scoreSegment", anchor: .center)
                        }
                    }
                }
            }
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
                    .id("playbackControls")
                }
                .background(Color(uiColor: .secondarySystemBackground))
            }
            .background(Color(uiColor: .systemBackground))
            
            .sheet(isPresented: $viewModel.isShowingMixer) {
                MixerView(viewModel: viewModel)
                    .presentationDetents([.fraction(0.55), .medium])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $viewModel.isShowingAddSectionSheet) {
                ProgressionSelectionSheetView(title: "進行を追加") { template in
                    viewModel.addSection(template: template)
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: Binding(
                get: { viewModel.sectionIndexForProgressionChange != nil },
                set: { if !$0 { viewModel.sectionIndexForProgressionChange = nil } }
            )) {
                if let targetIndex = viewModel.sectionIndexForProgressionChange {
                    ProgressionSelectionSheetView(title: "Section \(targetIndex + 1) の進行を変更") { template in
                        viewModel.applyTemplate(template, toSectionIndex: targetIndex)
                    }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $viewModel.isShowingSongStructureSheet) {
                SongStructureSheetView(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $viewModel.isShowingChordCustomizer) {
                ChordCustomizerSheetView(viewModel: viewModel)
                    .presentationDetents([.large])
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
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                TextField("Project Title", text: $viewModel.project.title)
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isShowingSettings = true
                } label: {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .onAppear {
            print("🎬 [PlayEditorView] onAppear")
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
                .tourSpotlight(.step12_changeKey)

            Spacer()

            // ジャンル選択ボタン（Genre名 + アイコン + 下矢印）
            genreMenuButton
                .tourSpotlight(.step13_changeGenreDance)
                .tourSpotlight(.step14_changeGenreLofi)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(uiColor: .systemBackground))
    }

    /*
    音楽ジャンル（Pop, Rock, Dance, Lo-Fi, R&B）を1タップで切り替えられるドロップダウンメニューを描画する。
    
    Arguments:
    なし
    
    Usage:
    topHeaderViewの右端に配置され、ドラム＆ベースパターンの自動切り替えをトリガーする。
    */
    
    private var genreMenuButton: some View {
        CustomPickerButton(
            options: Array(MusicGenre.allCases),
            selection: Binding(
                get: { viewModel.selectedGenre },
                set: { viewModel.changeGenre($0) }
            ),
            sheetTitle: "Genre"
        ) {
            HStack(spacing: 5) {
                Image(systemName: viewModel.selectedGenre.iconName)
                    .font(.caption.bold())
                    .foregroundColor(.accentColor)

                Text("Genre: \(viewModel.selectedGenre.shortName)")
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
        } optionRow: { genre in
            HStack(spacing: 16) {
                Image(systemName: genre.iconName)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(genre.displayName))
                        .font(.headline)
                    Text(LocalizedStringKey(genre.styleDescription))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                if genre.isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
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
                        Text(LocalizedStringKey(key.rawValue))
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
