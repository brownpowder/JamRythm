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
                                // 4チャンネル・ストリップ
                HStack(spacing: 6) {
                    channelStrip(
                        title: "DRUM", iconName: "music.note", iconColor: .accentColor,
                        volume: viewModel.drumVolume, isMuted: viewModel.isDrumMuted, isSolo: viewModel.isDrumSolo,
                        onVolumeChange: { v in viewModel.changeDrumVolume(v) },
                        onToggleMute: viewModel.toggleDrumMute,
                        onToggleSolo: viewModel.toggleDrumSolo,
                        instrumentMenu: { drumInstrumentMenu },
                        playerMenu: { drumPlayerMenu }
                    )
                    channelStrip(
                        title: "BASS", iconName: "guitars", iconColor: .purple,
                        volume: viewModel.bassVolume, isMuted: viewModel.isBassMuted, isSolo: viewModel.isBassSolo,
                        onVolumeChange: { v in viewModel.changeBassVolume(v) },
                        onToggleMute: viewModel.toggleBassMute,
                        onToggleSolo: viewModel.toggleBassSolo,
                        instrumentMenu: { bassInstrumentMenu },
                        playerMenu: { bassPlayerMenu }
                    )
                    channelStrip(
                        title: "CHORD", iconName: "pianokeys", iconColor: .teal,
                        volume: viewModel.pianoVolume, isMuted: viewModel.isPianoMuted, isSolo: viewModel.isPianoSolo,
                        onVolumeChange: { v in viewModel.changePianoVolume(v) },
                        onToggleMute: viewModel.togglePianoMute,
                        onToggleSolo: viewModel.togglePianoSolo,
                        instrumentMenu: { pianoInstrumentMenu },
                        playerMenu: { pianoPlayerMenu }
                    )
                    channelStrip(
                        title: "LEAD", iconName: "music.note", iconColor: .orange,
                        volume: viewModel.leadVolume, isMuted: viewModel.isLeadMuted, isSolo: viewModel.isLeadSolo,
                        onVolumeChange: { v in viewModel.changeLeadVolume(v) },
                        onToggleMute: viewModel.toggleLeadMute,
                        onToggleSolo: viewModel.toggleLeadSolo,
                        instrumentMenu: { 
                            Text("A")
                                .font(.caption.bold())
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity)
                                .hidden()
                        },
                        playerMenu: { 
                            Color.clear.frame(height: 44) 
                        }
                    )
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

    
    private func channelStrip<InstrumentMenu: View, PlayerMenu: View>(
        title: String,
        iconName: String,
        iconColor: Color,
        volume: Float,
        isMuted: Bool,
        isSolo: Bool,
        onVolumeChange: @escaping (Float) -> Void,
        onToggleMute: @escaping () -> Void,
        onToggleSolo: @escaping () -> Void,
        @ViewBuilder instrumentMenu: () -> InstrumentMenu,
        @ViewBuilder playerMenu: () -> PlayerMenu
    ) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
            
            instrumentMenu()
            playerMenu()
            
            MixerFaderView(
                valueText: "\(Int(volume * 100))%",
                progress: Double(volume),
                onProgressChange: { newProgress in onVolumeChange(Float(newProgress)) }
            )
            
            muteAndSoloButtons(
                isMuted: isMuted,
                isSolo: isSolo,
                onToggleMute: onToggleMute,
                onToggleSolo: onToggleSolo
            )
        }
        .frame(maxHeight: .infinity)
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }


    // MARK: - 音色選択メニュー & バッジ

    @ViewBuilder
    private func playerAvatar(imageName: String) -> some View {
        if imageName.hasPrefix("system:") {
            Image(systemName: String(imageName.dropFirst(7)))
                .resizable()
                .scaledToFit()
                .padding(10)
                .frame(width: 44, height: 44)
                .background(Color(uiColor: .systemGray4))
                .foregroundColor(.white)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(uiColor: .tertiarySystemFill), lineWidth: 2))
                .shadow(radius: 1)
        } else {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color(uiColor: .tertiarySystemFill), lineWidth: 2))
                .shadow(radius: 1)
        }
    }


    private var drumPlayerMenu: some View {
        CustomPickerButton(
            options: Array(DrumPlayer.allCases),
            selection: Binding(
                get: { viewModel.selectedDrumPlayer },
                set: { viewModel.selectDrumPlayer($0) }
            ),
            sheetTitle: "Drum Player"
        ) {
            playerAvatar(imageName: viewModel.selectedDrumPlayer.imageName)
        } optionRow: { player in
            HStack(spacing: 16) {
                playerAvatar(imageName: player.imageName)
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.displayName)
                        .font(.headline)
                    Text(player.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private var bassPlayerMenu: some View {
        CustomPickerButton(
            options: Array(BassPlayer.allCases),
            selection: Binding(
                get: { viewModel.selectedBassPlayer },
                set: { viewModel.selectBassPlayer($0) }
            ),
            sheetTitle: "Bass Player"
        ) {
            playerAvatar(imageName: viewModel.selectedBassPlayer.imageName)
        } optionRow: { player in
            HStack(spacing: 16) {
                playerAvatar(imageName: player.imageName)
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.displayName)
                        .font(.headline)
                    Text(player.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }

    private var pianoPlayerMenu: some View {
        CustomPickerButton(
            options: Array(PianoPlayer.allCases),
            selection: Binding(
                get: { viewModel.selectedPianoPlayer },
                set: { viewModel.selectPianoPlayer($0) }
            ),
            sheetTitle: "Chord Player"
        ) {
            playerAvatar(imageName: viewModel.selectedPianoPlayer.imageName)
        } optionRow: { player in
            HStack(spacing: 16) {
                playerAvatar(imageName: player.imageName)
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.displayName)
                        .font(.headline)
                    Text(player.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
    }


    private var pianoInstrumentMenu: some View {
        CustomPickerButton(
            options: Array(PianoInstrument.allCases),
            selection: Binding(
                get: { viewModel.selectedPianoInstrument },
                set: { viewModel.selectPianoInstrument($0) }
            ),
            sheetTitle: "Chord Sound"
        ) {
            HStack(spacing: 4) {
                Text(viewModel.selectedPianoInstrument.displayName)
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
        } optionRow: { instrument in
            HStack(spacing: 16) {
                Image(systemName: instrument.iconName)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)
                Text(instrument.displayName)
                    .font(.headline)
            }
        }
    }

    /*
    ドラム音色プリセットを選択するドロップダウンメニューを描画する。

    Arguments:
    なし

    Usage:
    ドラムチャンネルのトラックヘッダー直下に配置される。
    */

    private var drumInstrumentMenu: some View {
        CustomPickerButton(
            options: Array(DrumInstrument.allCases),
            selection: Binding(
                get: { viewModel.selectedDrumInstrument },
                set: { viewModel.selectDrumInstrument($0) }
            ),
            sheetTitle: "Drum Sound"
        ) {
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
        } optionRow: { instrument in
            HStack(spacing: 16) {
                Image(systemName: instrument.iconName)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)
                Text(instrument.displayName)
                    .font(.headline)
            }
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
        CustomPickerButton(
            options: Array(BassInstrument.allCases),
            selection: Binding(
                get: { viewModel.selectedBassInstrument },
                set: { viewModel.selectBassInstrument($0) }
            ),
            sheetTitle: "Bass Sound"
        ) {
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
        } optionRow: { instrument in
            HStack(spacing: 16) {
                Image(systemName: instrument.iconName)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)
                Text(instrument.displayName)
                    .font(.headline)
            }
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
