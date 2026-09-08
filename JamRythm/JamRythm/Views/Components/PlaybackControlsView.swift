//
//  PlaybackControlsView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI

// MARK: - プレイヤーコントロール・コンポーネント

/*
再生/一時停止、BPM調整、Key選択、進行テンプレート選択を行う操作パネル。
楽器演奏中でも片手ですぐに触れるサイズ感とレイアウトを確保する。
*/
struct PlaybackControlsView: View {
    let isPlaying: Bool
    let bpm: Double
    let currentKey: Key
    let currentTemplate: ProgressionTemplate
    let onTogglePlay: () -> Void
    let onBPMChange: (Double) -> Void
    let onKeyChange: (Key) -> Void
    let onTemplateChange: (ProgressionTemplate) -> Void

    var body: some View {
        VStack(spacing: 14) {
            // 上段: Key & テンプレート選択
            HStack(spacing: 12) {
                keyPickerMenu()
                templatePickerMenu()
            }

            // 中段: BPM調整
            bpmControlRow()

            // 下段: 再生/停止メインボタン
            playButton()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(uiColor: .secondarySystemBackground))
        )
        .padding(.horizontal)
    }

    // MARK: - サブビュー

    /*
    Key選択メニューを描画する。
    
    Arguments:
    なし
    
    Usage:
    上段のKey切り替えボタンとして使用される。
    */
    
    private func keyPickerMenu() -> some View {
        Menu {
            ForEach(Key.allCases) { key in
                Button(action: { onKeyChange(key) }) {
                    if key == currentKey {
                        Label(key.rawValue, systemImage: "checkmark")
                    } else {
                        Text(key.rawValue)
                    }
                }
            }
        } label: {
            HStack {
                Label("Key", systemImage: "music.note")
                Spacer()
                Text(currentKey.rawValue)
                    .bold()
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
        }
    }

    /*
    王道進行テンプレート選択メニューを描画する。
    
    Arguments:
    なし
    
    Usage:
    上段の進行切り替えボタンとして使用される。
    */
    
    private func templatePickerMenu() -> some View {
        Menu {
            ForEach(ProgressionTemplate.allTemplates) { template in
                Button(action: { onTemplateChange(template) }) {
                    if template.id == currentTemplate.id {
                        Label(template.name, systemImage: "checkmark")
                    } else {
                        Text(template.name)
                    }
                }
            }
        } label: {
            HStack {
                Label("Pattern", systemImage: "slider.horizontal.3")
                Spacer()
                Text(currentTemplate.name)
                    .bold()
                    .lineLimit(1)
            }
            .font(.subheadline)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(uiColor: .tertiarySystemBackground))
            .cornerRadius(8)
        }
    }

    /*
    BPMスライダーと加減ボタンを描画する。
    
    Arguments:
    なし
    
    Usage:
    中段のテンポコントロールとして使用される。
    */
    
    private func bpmControlRow() -> some View {
        HStack(spacing: 12) {
            Text("BPM")
                .font(.caption.bold())
                .foregroundColor(.secondary)

            Text("\(Int(bpm))")
                .font(.system(size: 20, weight: .bold, design: .monospaced))
                .frame(width: 44, alignment: .leading)

            Button(action: { onBPMChange(max(40, bpm - 5)) }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title3)
            }

            Slider(
                value: Binding(
                    get: { bpm },
                    set: { onBPMChange($0) }
                ),
                in: 60...200,
                step: 1
            )

            Button(action: { onBPMChange(min(240, bpm + 5)) }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
            }
        }
    }

    /*
    再生/一時停止の特大ボタンを描画する。
    
    Arguments:
    なし
    
    Usage:
    下段のメインアクションボタンとして使用される。
    */
    
    private func playButton() -> some View {
        Button(action: onTogglePlay) {
            HStack {
                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                    .font(.title2)
                Text(isPlaying ? "PAUSE" : "START JAM")
                    .font(.headline.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isPlaying ? Color.orange : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
    }
}
