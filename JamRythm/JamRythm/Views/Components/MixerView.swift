//
//  MixerView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/09.
//

import SwiftUI

// MARK: - リズム隊ミキサー画面（ハーフシート）

/*
ドラムおよびベースの個別音量調整、ミュート切り替え、音色プリセット選択を提供する
DAWコンソールスタイルのミキサーView。
ハーフシートとして表示され、Jam演奏を止めずにリアルタイムにサウンドを微調整できる。
*/
struct MixerView: View {
    @ObservedObject var viewModel: PlayEditorViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var previousDrumVolume: Float = 0.8
    @State private var previousBassVolume: Float = 0.8

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // 2チャンネル・ストリップ（ドラム / ベース）
                HStack(spacing: 16) {
                    drumChannelStrip
                    bassChannelStrip
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer(minLength: 8)
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("MIXER")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        dismiss()
                    }
                    .font(.subheadline.bold())
                }
            }
        }
    }

    // MARK: - ドラムチャンネル・ストリップ

    /*
    ドラム専用のチャンネルストリップ（音色選択、縦フェーダー、ミュート）を描画する。

    Arguments:
    なし

    Usage:
    ミキサー画面の左列に配置される。
    */

    private var drumChannelStrip: some View {
        VStack(spacing: 12) {
            // トラックヘッダー
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.headline)
                    .foregroundColor(.accentColor)

                Text("DRUM")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
            }

            // 音色プリセット選択メニュー
            drumInstrumentMenu

            // 縦フェーダー
            MixerFaderView(
                valueText: "\(Int(viewModel.drumVolume * 100))%",
                progress: Double(viewModel.drumVolume),
                onProgressChange: { newProgress in
                    viewModel.changeDrumVolume(Float(newProgress))
                }
            )

            // ミュートボタン
            muteButton(
                isMuted: viewModel.drumVolume <= 0.001,
                onToggle: toggleDrumMute
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: - ベースチャンネル・ストリップ

    /*
    ベース専用のチャンネルストリップ（音色選択、縦フェーダー、ミュート）を描画する。

    Arguments:
    なし

    Usage:
    ミキサー画面の右列に配置される。
    */

    private var bassChannelStrip: some View {
        VStack(spacing: 12) {
            // トラックヘッダー
            HStack(spacing: 6) {
                Image(systemName: "guitars.fill")
                    .font(.headline)
                    .foregroundColor(.orange)

                Text("BASS")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
            }

            // 音色プリセット選択メニュー
            bassInstrumentMenu

            // 縦フェーダー
            MixerFaderView(
                valueText: "\(Int(viewModel.bassVolume * 100))%",
                progress: Double(viewModel.bassVolume),
                onProgressChange: { newProgress in
                    viewModel.changeBassVolume(Float(newProgress))
                }
            )

            // ミュートボタン
            muteButton(
                isMuted: viewModel.bassVolume <= 0.001,
                onToggle: toggleBassMute
            )
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: - 音色選択メニュー

    /*
    ドラム音色プリセットを選択するドロップダウンメニューを描画する。

    Arguments:
    なし

    Usage:
    ドラムチャンネルのトラックヘッダー直下に配置される。
    */

    private var drumInstrumentMenu: some View {
        Menu {
            ForEach(DrumInstrument.allCases) { instrument in
                Button(action: { viewModel.selectDrumInstrument(instrument) }) {
                    if instrument == viewModel.selectedDrumInstrument {
                        Label(instrument.displayName, systemImage: "checkmark")
                    } else {
                        Text(instrument.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.selectedDrumInstrument.displayName)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Image(systemName: "chevron.down")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .tertiarySystemFill))
            .cornerRadius(8)
        }
    }

    /*
    ベース音色プリセットを選択するドロップダウンメニューを描画する。

    Arguments:
    なし

    Usage:
    ベースチャンネルのトラックヘッダー直下に配置される。
    */

    private var bassInstrumentMenu: some View {
        Menu {
            ForEach(BassInstrument.allCases) { instrument in
                Button(action: { viewModel.selectBassInstrument(instrument) }) {
                    if instrument == viewModel.selectedBassInstrument {
                        Label(instrument.displayName, systemImage: "checkmark")
                    } else {
                        Text(instrument.displayName)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.selectedBassInstrument.displayName)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .foregroundColor(.primary)

                Image(systemName: "chevron.down")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .tertiarySystemFill))
            .cornerRadius(8)
        }
    }

    // MARK: - ミュートボタン & ロジック

    /*
    MUTE切り替えボタンを描画する。

    Arguments:
    isMuted
      現在ミュート中かどうか。チャンネル音量から判定される。
    onToggle
      ボタンタップ時に実行されるトグル処理。

    Usage:
    各チャンネルストリップの最下段に配置される。
    */

    private func muteButton(isMuted: Bool, onToggle: @escaping () -> Void) -> some View {
        Button(action: onToggle) {
            Text("MUTE")
                .font(.caption.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(isMuted ? Color.red : Color(uiColor: .tertiarySystemFill))
                .foregroundColor(isMuted ? .white : .secondary)
                .cornerRadius(8)
        }
    }

    /*
    ドラムのミュート状態をトグルする。
    音量が0なら前回音量へ復帰し、音量があれば前回値を記録して0にする。

    Arguments:
    なし

    Usage:
    ドラムのMUTEボタンタップ時に呼び出される。
    */

    private func toggleDrumMute() {
        if viewModel.drumVolume <= 0.001 {
            let restore = previousDrumVolume > 0.05 ? previousDrumVolume : 0.8
            viewModel.changeDrumVolume(restore)
        } else {
            previousDrumVolume = viewModel.drumVolume
            viewModel.changeDrumVolume(0.0)
        }
    }

    /*
    ベースのミュート状態をトグルする。
    音量が0なら前回音量へ復帰し、音量があれば前回値を記録して0にする。

    Arguments:
    なし

    Usage:
    ベースのMUTEボタンタップ時に呼び出される。
    */

    private func toggleBassMute() {
        if viewModel.bassVolume <= 0.001 {
            let restore = previousBassVolume > 0.05 ? previousBassVolume : 0.8
            viewModel.changeBassVolume(restore)
        } else {
            previousBassVolume = viewModel.bassVolume
            viewModel.changeBassVolume(0.0)
        }
    }
}

// MARK: - ミキサー用 縦フェーダーコンポーネント

/*
ミキサー画面で使用する縦型フェーダースライダー。
上下のドラッグ操作で滑らかに進捗率（0.0〜1.0）を変更する。

Arguments:
valueText
  フェーダー中央または上部に表示する数値文字列（例: "80%"）。
progress
  現在の音量進捗率（0.0〜1.0）。
onProgressChange
  ドラッグで値が変動した際に呼ばれるコールバック。

Usage:
MixerView内の各チャンネルストリップで利用される。
*/

struct MixerFaderView: View {
    let valueText: String
    let progress: Double
    let onProgressChange: (Double) -> Void

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let fillHeight = height * max(0.0, min(1.0, progress))

            ZStack(alignment: .bottom) {
                // 背景レール
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(uiColor: .tertiarySystemFill))

                // 満たされたボリュームゲージ
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.accentColor.opacity(0.35))
                    .frame(height: fillHeight)
                    .frame(maxWidth: .infinity, alignment: .bottom)

                // 数値表示
                VStack {
                    Text(valueText)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(.top, 10)

                    Spacer()
                }
                .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.accentColor.opacity(0.2), lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let raw = 1.0 - (gesture.location.y / height)
                        let clamped = min(max(raw, 0.0), 1.0)
                        onProgressChange(clamped)
                    }
            )
        }
        .frame(height: 140)
    }
}
