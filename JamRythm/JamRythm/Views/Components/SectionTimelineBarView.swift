//
//  SectionTimelineBarView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/09.
//

import SwiftUI

// MARK: - ソングセクション & コード進行ビュー

/*
楽曲全体の構成（Intro, Aメロ, サビ等）と各小節のコード進行を一覧表示・操作するコンポーネント。
タブ譜（ScoreSegmentView）の下部に配置され、セクションごとの小節コードの可視化、
小節の選択、セクションの追加（進行テンプレートと同時に指定）、複製、削除、
および再生モード（セクションループ ⇔ 全曲通し）の切り替えを提供する。
*/
struct SectionTimelineBarView: View {
    @ObservedObject var viewModel: PlayEditorViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerRow

            VStack(spacing: 12) {
                ForEach(Array(viewModel.project.sections.enumerated()), id: \.element.id) { sIndex, section in
                    sectionCard(section: section, sectionIndex: sIndex)
                }
            }

            addSectionButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - サブビュー

    /*
    セクションエリア上部のヘッダー行を描画する。
    
    Arguments:
    なし
    
    Usage:
    タイトルおよび再生モード切り替えボタンの配置に使用される。
    */

    private var headerRow: some View {
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "music.note.list")
                    .font(.subheadline.bold())
                    .foregroundColor(.accentColor)

                Text("進行・セクション")
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)

                Text("(\(viewModel.project.sections.count))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            playbackModeButton
        }
    }

    /*
    再生モード（セクションループ ⇔ 全曲通し）の切り替えボタンを描画する。
    
    Arguments:
    なし
    
    Usage:
    ヘッダー行の右端に配置され、現在の再生方針を制御・明示する。
    */

    private var playbackModeButton: some View {
        Button(action: {
            viewModel.togglePlaybackMode()
        }) {
            HStack(spacing: 4) {
                Image(systemName: viewModel.playbackMode.iconName)
                    .font(.system(size: 12, weight: .bold))
                Text(viewModel.playbackMode == .sectionLoop ? "セクションループ" : "全曲通し")
                    .font(.system(size: 11, weight: .bold))
            }
            .foregroundColor(viewModel.playbackMode == .entireSong ? .orange : .accentColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.playbackMode == .entireSong ? Color.orange.opacity(0.12) : Color.accentColor.opacity(0.12))
            )
        }
        .buttonStyle(.plain)
    }

    /*
    単一セクションのカード（ヘッダーと小節コードのグリッド）を描画する。
    
    Arguments:
    section
      表示対象のSectionデータ。
    sectionIndex
      セクションのインデックス番号。
    
    Usage:
    セクションリストの各行として配置される。
    */

    private func sectionCard(section: Section, sectionIndex: Int) -> some View {
        let isSelected = viewModel.selectedSectionIndex == sectionIndex

        return VStack(alignment: .leading, spacing: 10) {
            sectionHeader(section: section, sectionIndex: sectionIndex, isSelected: isSelected)

            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: min(4, max(1, section.measures.count)))
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(Array(section.measures.enumerated()), id: \.element.id) { mIndex, measure in
                    measureChordCard(measure: measure, sectionIndex: sectionIndex, measureIndex: mIndex)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color(uiColor: .secondarySystemBackground) : Color(uiColor: .tertiarySystemBackground).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.accentColor.opacity(0.6) : Color.secondary.opacity(0.15), lineWidth: isSelected ? 1.5 : 1)
        )
    }

    /*
    セクションカード内の上部ヘッダー（名前バッジ、小節数、メニュー）を描画する。
    
    Arguments:
    section
      セクションのデータ。
    sectionIndex
      セクションインデックス。
    isSelected
      現在フォーカスされているかどうか。
    
    Usage:
    sectionCardの上部に配置される。
    */

    private func sectionHeader(section: Section, sectionIndex: Int, isSelected: Bool) -> some View {
        let isPlayingThis = viewModel.isPlaying && viewModel.selectedSectionIndex == sectionIndex

        return HStack(spacing: 8) {
            Button(action: {
                viewModel.selectSection(at: sectionIndex)
            }) {
                HStack(spacing: 6) {
                    if isPlayingThis {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }

                    Text("Section \(sectionIndex + 1)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .accentColor : .primary)

                    Text("\(section.measures.count)小節")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            sectionActionMenu(section: section, sectionIndex: sectionIndex)
        }
    }

    /*
    セクションの編集・操作メニューを描画する。
    
    Arguments:
    section
      セクションデータ。
    sectionIndex
      セクションインデックス。
    
    Usage:
    セクションヘッダーの右端に配置される。
    */

    private func sectionActionMenu(section: Section, sectionIndex: Int) -> some View {
        Menu {
            Menu("コード進行を変更") {
                ForEach(ProgressionTemplate.allTemplates) { template in
                    Button(template.name) {
                        viewModel.applyTemplate(template, toSectionIndex: sectionIndex)
                    }
                }
            }

            Divider()

            Button(action: {
                viewModel.duplicateSection(at: sectionIndex)
            }) {
                Label("このセクションを複製", systemImage: "plus.square.on.square")
            }

            if viewModel.project.sections.count > 1 {
                Button(role: .destructive, action: {
                    viewModel.removeSection(at: sectionIndex)
                }) {
                    Label("セクションを削除", systemImage: "trash")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .padding(4)
        }
    }

    /*
    小節ごとのコードカードを描画する。
    
    Arguments:
    measure
      小節のデータ。
    sectionIndex
      小節が所属するセクション番号。
    measureIndex
      小節のインデックス番号。
    
    Usage:
    セクションカード内のグリッドで各小節を表示する。
    */

    private func measureChordCard(measure: Measure, sectionIndex: Int, measureIndex: Int) -> some View {
        let isFocused = viewModel.selectedSectionIndex == sectionIndex && viewModel.currentMeasureIndex == measureIndex
        let isPlayingThisMeasure = viewModel.isPlaying && viewModel.selectedSectionIndex == sectionIndex && viewModel.currentMeasureIndex == measureIndex

        return Button(action: {
            viewModel.selectMeasure(inSection: sectionIndex, measureIndex: measureIndex)
        }) {
            VStack(spacing: 3) {
                HStack(spacing: 2) {
                    Text("\(measureIndex + 1)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isFocused ? .accentColor : .secondary)

                    if isPlayingThisMeasure {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5, height: 5)
                    }
                }

                Text(measure.activeChord.displayString)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(isFocused ? .primary : .primary.opacity(0.85))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text("Base: \(measure.bassNote)")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isPlayingThisMeasure ? Color.green.opacity(0.15) : (isFocused ? Color.accentColor.opacity(0.15) : Color(uiColor: .systemBackground)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isPlayingThisMeasure ? Color.green : (isFocused ? Color.accentColor : Color.secondary.opacity(0.15)),
                        lineWidth: (isPlayingThisMeasure || isFocused) ? 1.5 : 1
                    )
            )
        }
        .buttonStyle(.plain)
    }

    /*
    セクション種別とコード進行を同時に選択して追加するボタンを描画する。
    
    Arguments:
    なし
    
    Usage:
    セクション一覧の下部に配置され、新しいセクションの追加を行う。
    */

    private var addSectionButton: some View {
        Menu {
            ForEach(ProgressionTemplate.allTemplates) { template in
                Button("\(template.name) で追加") {
                    viewModel.addSection(template: template)
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 14, weight: .bold))
                Text("セクションを追加（進行を選択）")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
            )
        }
    }
}
