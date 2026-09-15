//
//  MixerView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/09.
//

import SwiftUI

// MARK: - リズム隊＆コードミキサー画面（ハーフシート）

/*
ドラム、ベース、ピアノの個別音量調整、MUTE・SOLO切り替え、音色プリセット選択を提供する
DAWコンソールスタイルのミキサーView。
ハーフシートとして表示され、Jam演奏を止めずにリアルタイムにサウンドを微調整できる。
*/
struct MixerView: View {
    @ObservedObject var viewModel: PlayEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // 3チャンネル・ストリップ（ドラム / ベース / ピアノ）
                HStack(spacing: 6) {
                    drumChannelStrip
                    bassChannelStrip
                    pianoChannelStrip
                    leadChannelStrip
                }
                .padding(.horizontal, 8)
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
    ドラム専用のチャンネルストリップ（音色選択、縦フェーダー、MUTE/SOLO）を描画する。

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

            // MUTE & SOLO ボタン
            muteAndSoloButtons(
                isMuted: viewModel.isDrumMuted,
                isSolo: viewModel.isDrumSolo,
                onToggleMute: { viewModel.toggleDrumMute() },
                onToggleSolo: { viewModel.toggleDrumSolo() }
            )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: - ベースチャンネル・ストリップ

    /*
    ベース専用のチャンネルストリップ（音色選択、縦フェーダー、MUTE/SOLO）を描画する。

    Arguments:
    なし

    Usage:
    ミキサー画面の中央列に配置される。
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

            // MUTE & SOLO ボタン
            muteAndSoloButtons(
                isMuted: viewModel.isBassMuted,
                isSolo: viewModel.isBassSolo,
                onToggleMute: { viewModel.toggleBassMute() },
                onToggleSolo: { viewModel.toggleBassSolo() }
            )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: - ピアノチャンネル・ストリップ

    /*
    ピアノ専用のチャンネルストリップ（音色表示、縦フェーダー、MUTE/SOLO）を描画する。

    Arguments:
    なし

    Usage:
    ミキサー画面の右列に配置される。
    */

    private var pianoChannelStrip: some View {
        VStack(spacing: 12) {
            // トラックヘッダー
            HStack(spacing: 6) {
                Image(systemName: "pianokeys")
                    .font(.headline)
                    .foregroundColor(.teal)

                Text("CHORD")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
            }

            // 音色バッジ表示
            pianoInstrumentBadge

            // 縦フェーダー
            MixerFaderView(
                valueText: "\(Int(viewModel.pianoVolume * 100))%",
                progress: Double(viewModel.pianoVolume),
                onProgressChange: { newProgress in
                    viewModel.changePianoVolume(Float(newProgress))
                }
            )

            // MUTE & SOLO ボタン
            muteAndSoloButtons(
                isMuted: viewModel.isPianoMuted,
                isSolo: viewModel.isPianoSolo,
                onToggleMute: { viewModel.togglePianoMute() },
                onToggleSolo: { viewModel.togglePianoSolo() }
            )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: - 音色選択メニュー & バッジ

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
            .padding(.horizontal, 6)
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
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .tertiarySystemFill))
            .cornerRadius(8)
        }
    }

    /*
    ピアノ音色バッジを描画する。

    Arguments:
    なし

    Usage:
    ピアノチャンネルのトラックヘッダー直下に配置される。
    */

    private var pianoInstrumentBadge: some View {
        HStack(spacing: 4) {
            Text("Piano 1")
                .font(.caption.bold())
                .lineLimit(1)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color(uiColor: .tertiarySystemFill))
        .cornerRadius(8)
    }

    // MARK: - リードチャンネル・ストリップ
    private var leadChannelStrip: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.headline)
                    .foregroundColor(.orange)
                Text("LEAD")
                    .font(.headline.bold())
                    .foregroundColor(.primary)
            }
            .padding(.bottom, 36)

            HStack(spacing: 4) {
                Text(viewModel.selectedLeadInstrument.displayName)
                    .font(.caption.bold())
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .background(Color(uiColor: .tertiarySystemFill))
            .cornerRadius(8)

            MixerFaderView(
                valueText: "\(Int(viewModel.leadVolume * 100))%",
                progress: Double(viewModel.leadVolume),
                onProgressChange: { newProgress in
                    viewModel.changeLeadVolume(Float(newProgress))
                }
            )

            muteAndSoloButtons(
                isMuted: viewModel.isLeadMuted,
                isSolo: viewModel.isLeadSolo,
                onToggleMute: { viewModel.toggleLeadMute() },
                onToggleSolo: { viewModel.toggleLeadSolo() }
            )
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }

    // MARK: - MUTE & SOLO ボタン

    /*
    DAWコンソールスタイルのMUTE [M] および SOLO [S] ボタンを描画する。

    Arguments:
    isMuted
      現在ミュートされているかどうか。
    isSolo
      現在ソロ状態かどうか。
    onToggleMute
      MUTEトグルタップ時のコールバック。
    onToggleSolo
      SOLOトグルタップ時のコールバック。

    Usage:
    各チャンネルストリップの最下部に配置される。
    */

    private func muteAndSoloButtons(
        isMuted: Bool,
        isSolo: Bool,
        onToggleMute: @escaping () -> Void,
        onToggleSolo: @escaping () -> Void
    ) -> some View {
        HStack(spacing: 6) {
            Button(action: onToggleMute) {
                Text("M")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(isMuted ? Color.red : Color(uiColor: .tertiarySystemFill))
                    .foregroundColor(isMuted ? .white : .secondary)
                    .cornerRadius(8)
            }

            Button(action: onToggleSolo) {
                Text("S")
                    .font(.caption.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(isSolo ? Color.yellow : Color(uiColor: .tertiarySystemFill))
                    .foregroundColor(isSolo ? .black : .secondary)
                    .cornerRadius(8)
            }
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
