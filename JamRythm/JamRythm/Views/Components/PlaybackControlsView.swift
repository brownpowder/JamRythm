//
//  PlaybackControlsView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI

// MARK: - ポップアップ種別

/*
現在表示中の縦型スライダーポップアップの種類を表す列挙型。
*/
enum ActivePopup {
    case bpm
    case volume
}

// MARK: - プレイヤー固定フッターコントロール

/*
画面最下部に固定配置され、BPM（テンポ）、Play/Stop、Volume（音量）のアイコンボタンを
1列で提供する超スリムなコントロールバー。
アイコンタップで直上に縦型カプセルスライダーがポップアップし、上下ドラッグで直感的に調整できる。
*/
struct PlaybackControlsView: View {
    let isPlaying: Bool
    let bpm: Double
    let volume: Float
    let onTogglePlay: () -> Void
    let onBPMChange: (Double) -> Void
    let onVolumeChange: (Float) -> Void
    let onOpenMixer: () -> Void

    @State private var activePopup: ActivePopup? = nil

    private let minBPM: Double = 60.0
    private let maxBPM: Double = 200.0

    var body: some View {
        HStack(alignment: .center) {
            // 左端: 再生 / 停止 小型丸型アイコンボタン
            playIconButton

            Spacer()

            // 右側: BPM, Volume, Mixer
            HStack(spacing: 14) {
                bpmIconButton
                volumeIconButton
                mixerIconButton
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(
            Color(uiColor: .secondarySystemBackground)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: -3)
        )
        .background(
            // ポップアップ表示時に画面外タップで閉じるための透明レイヤー
            Group {
                if activePopup != nil {
                    Color.black.opacity(0.001)
                        .frame(width: 1000, height: 2000)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                activePopup = nil
                            }
                        }
                }
            }
        )
    }

    // MARK: - サブビュー

    /*
    BPM（テンポ）のメトロノームアイコンボタンを描画する。
    タップで直上に縦型スライダーがポップアップする。

    Arguments:
    なし

    Usage:
    フッター左側に配置され、BPMのポップアップ表示をトグルする。
    */

    private var bpmIconButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                activePopup = (activePopup == .bpm) ? nil : .bpm
            }
        }) {
            Image(systemName: "metronome")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(activePopup == .bpm ? .accentColor : .primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(activePopup == .bpm ? Color.accentColor.opacity(0.15) : Color(uiColor: .tertiarySystemFill))
                )
        }
        .overlay(alignment: .bottom) {
            if activePopup == .bpm {
                let progress = (bpm - minBPM) / (maxBPM - minBPM)
                PopupVerticalSlider(
                    valueText: "\(Int(bpm))",
                    iconName: "metronome",
                    progress: progress,
                    onProgressChange: { newProgress in
                        let newBPM = round(minBPM + newProgress * (maxBPM - minBPM))
                        onBPMChange(newBPM)
                    }
                )
                .offset(y: -48)
                .transition(.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
            }
        }
    }

    /*
    音量（Volume）のスピーカーアイコンボタンを描画する。
    タップで直上に縦型スライダーがポップアップする。

    Arguments:
    なし

    Usage:
    フッター右側に配置され、音量のポップアップ表示をトグルする。
    */

    private var volumeIconButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                activePopup = (activePopup == .volume) ? nil : .volume
            }
        }) {
            Image(systemName: volumeIconName)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(activePopup == .volume ? .accentColor : .primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(activePopup == .volume ? Color.accentColor.opacity(0.15) : Color(uiColor: .tertiarySystemFill))
                )
        }
        .overlay(alignment: .bottom) {
            if activePopup == .volume {
                PopupVerticalSlider(
                    valueText: "\(Int(volume * 100))%",
                    iconName: volumeIconName,
                    progress: Double(volume),
                    onProgressChange: { newProgress in
                        onVolumeChange(Float(newProgress))
                    }
                )
                .offset(y: -48)
                .transition(.scale(scale: 0.8, anchor: .bottom).combined(with: .opacity))
            }
        }
    }

    /*
    リズム隊ミキサー画面を開くアイコンボタンを描画する。

    Arguments:
    なし

    Usage:
    フッター右端（Volumeボタンの隣）に配置される。
    */

    private var mixerIconButton: some View {
        Button(action: onOpenMixer) {
            Image(systemName: "slider.vertical.3")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color(uiColor: .tertiarySystemFill))
                )
        }
    }

    /*
    再生および停止を切り替える小型の丸型アイコンボタンを描画する。

    Arguments:
    なし

    Usage:
    フッター中央に配置され、タップでオーディオ再生のトグルを行う。
    */

    private var playIconButton: some View {
        Button(action: onTogglePlay) {
            ZStack {
                Circle()
                    .fill(isPlaying ? Color.orange : Color.accentColor)
                    .frame(width: 42, height: 42)
                    .shadow(
                        color: (isPlaying ? Color.orange : Color.accentColor).opacity(0.35),
                        radius: 4,
                        x: 0,
                        y: 2
                    )

                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .offset(x: isPlaying ? 0 : 1.5)
            }
        }
    }

    // MARK: - ヘルパー

    /*
    現在の音量値に応じたSF Symbolアイコン名を返す。

    Arguments:
    なし

    Usage:
    volumeIconButtonおよびポップアップスライダーのアイコン切り替えに使用される。
    */

    private var volumeIconName: String {
        if volume <= 0.001 {
            return "speaker.slash.fill"
        } else if volume < 0.5 {
            return "speaker.wave.1.fill"
        } else {
            return "speaker.wave.2.fill"
        }
    }
}

// MARK: - ポップアップ型 縦スライダーコンポーネント

/*
アイコン直上にポップアップ表示される縦型カプセルスライダー。
上下へのドラッグで0.0〜1.0の進捗値を滑らかに変更する。

Arguments:
valueText
  カプセル上部に表示する現在の数値文字列（例: "120" や "80%"）。
  親Viewでフォーマットされた値が渡される。
iconName
  カプセル下部に表示するSF Symbol名（メトロノームやスピーカー）。
  親Viewの状態に応じたアイコン名が渡される。
progress
  現在のゲージの進捗率（0.0〜1.0）。
  親Viewのプロパティから計算されて渡される。
onProgressChange
  ドラッグ操作で値が更新された際に呼ばれるコールバッククロージャ。
  ジェスチャーの計算結果を親Viewに伝達するために使用される。

Usage:
BPMやVolumeのアイコン直上に浮かび上がるスライダーとして再利用される。
*/

struct PopupVerticalSlider: View {
    let valueText: String
    let iconName: String
    let progress: Double
    let onProgressChange: (Double) -> Void

    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            let fillHeight = height * max(0.0, min(1.0, progress))

            ZStack(alignment: .bottom) {
                // 背景カプセル
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color(uiColor: .secondarySystemBackground))

                // 満たされたゲージ（下から上へ上昇）
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.accentColor.opacity(0.35))
                    .frame(height: fillHeight)
                    .frame(maxWidth: .infinity, alignment: .bottom)

                // 数値ラベルとアイコン
                VStack {
                    Text(valueText)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.primary)
                        .padding(.top, 8)

                    Spacer()

                    Image(systemName: iconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .padding(.bottom, 8)
                }
                .allowsHitTesting(false)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.accentColor.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.18), radius: 8, x: 0, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: 18))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        let raw = 1.0 - (gesture.location.y / height)
                        let clamped = min(max(raw, 0.0), 1.0)
                        onProgressChange(clamped)
                    }
            )
        }
        .frame(width: 52, height: 120)
    }
}
