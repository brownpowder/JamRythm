//
//  ScaleFretboardView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/09.
//

import SwiftUI

// MARK: - スケール指板ダイアグラムビュー

/*
Keyと現在コードに基づき、スケール構成音（外れない音）を指板上に可視化するコンポーネント。
ギター（6弦）とベース（4弦：1・2弦非表示）の切り替えに対応し、
上部にはピアノやソロ演奏で直接使えるスケール音一覧（Scale Notes）を表示する。
*/
struct ScaleFretboardView: View {
    let key: Key
    let chord: Chord
    let theoryService: MusicTheoryServiceProtocol

    @State private var instrument: FretboardInstrument = .guitar
    @State private var scaleType: ScaleType = .pentatonic

    private var scaleInfo: ScaleInfo {
        theoryService.scaleInfo(for: key, chord: chord, scaleType: scaleType)
    }

    var body: some View {
        VStack(spacing: 8) {
            topControlBar
            fretboardCanvas
        }
        .frame(height: 130)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .tertiarySystemBackground))
        )
    }

    // MARK: - 上部コントロールバー（スケール名・Notes・切替スイッチ）

    /*
    スケール名、Scale Notesバッジ一覧、楽器切替、スケール切替ボタンを描画する。

    Arguments:
    なし

    Usage:
    指板の上部に配置され、演奏ガイドおよびモード切り替えを提供する。
    */

    private var topControlBar: some View {
        HStack(spacing: 8) {
            // スケール構成音バッジ列
            HStack(spacing: 4) {
                Text("Notes:")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)

                ForEach(scaleInfo.scaleNotes, id: \.self) { note in
                    let isRoot = (note == chord.rootNote)
                    Text(note)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isRoot ? .white : .primary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(
                            isRoot ? Color.orange : Color(uiColor: .quaternarySystemFill)
                        )
                        .cornerRadius(4)
                }
            }

            Spacer()

            // 6弦(Guitar) ⇔ 4弦(Bass) 切替ピッカー
            Button(action: {
                instrument = (instrument == .guitar) ? .bass : .guitar
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "guitars")
                        .font(.system(size: 9, weight: .bold))
                    Text(instrument == .guitar ? "6弦" : "4弦(Bass)")
                        .font(.system(size: 9, weight: .bold))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.accentColor.opacity(0.12))
                .foregroundColor(.accentColor)
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            // ペンタ ⇔ 7音スケール切替ピッカー
            Button(action: {
                scaleType = (scaleType == .pentatonic) ? .diatonic : .pentatonic
            }) {
                Text(scaleType == .pentatonic ? "5音(Penta)" : "7音")
                    .font(.system(size: 9, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(uiColor: .quaternarySystemFill))
                    .foregroundColor(.secondary)
                    .cornerRadius(6)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
    }

    // MARK: - 指板キャンバス描画

    /*
    Canvasを用いて横軸フレット（ナット、1〜5フレット）、縦軸弦（6弦or4弦）、スケールマーカーを描画する。

    Arguments:
    なし

    Usage:
    ScaleFretboardViewのメインダイアグラム描画として使用される。
    */

    private var fretboardCanvas: some View {
        Canvas { context, size in
            let nutX: CGFloat = 46.0
            let paddingRight: CGFloat = 16.0
            let paddingTop: CGFloat = 14.0
            let paddingBottom: CGFloat = 8.0

            let usableWidth = size.width - nutX - paddingRight
            let fretWidth = usableWidth / 5.0
            let usableHeight = size.height - paddingTop - paddingBottom

            let stringCount = (instrument == .guitar) ? 6 : 4
            let stringSpacing = usableHeight / CGFloat(max(1, stringCount - 1))

            // 1. フレット番号描画
            drawFretNumbers(context: context, nutX: nutX, fretWidth: fretWidth, paddingTop: paddingTop)

            // 2. 弦（横線）と弦名ラベル描画
            drawStringsAndLabels(
                context: context,
                nutX: nutX,
                width: size.width - paddingRight,
                paddingTop: paddingTop,
                stringSpacing: stringSpacing
            )

            // 3. ナットおよびフレット線（縦線）描画
            drawFretBars(
                context: context,
                nutX: nutX,
                fretWidth: fretWidth,
                paddingTop: paddingTop,
                height: usableHeight
            )

            // 4. スケールマーカー描画
            drawScaleMarkers(
                context: context,
                nutX: nutX,
                fretWidth: fretWidth,
                paddingTop: paddingTop,
                stringSpacing: stringSpacing
            )
        }
    }

    // MARK: - 描画ヘルパーメソッド

    /*
    フレット番号（1〜5）を指板上部に描画する。

    Arguments:
    context: 描画コンテキスト
    nutX: ナットのX座標
    fretWidth: 1フレットあたりの幅
    paddingTop: 上部余白
    */

    private func drawFretNumbers(context: GraphicsContext, nutX: CGFloat, fretWidth: CGFloat, paddingTop: CGFloat) {
        for fret in 1...5 {
            let x = nutX + CGFloat(fret - 1) * fretWidth + (fretWidth / 2.0)
            let text = Text("\(fret)")
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundColor(.secondary.opacity(0.7))
            context.draw(context.resolve(text), at: CGPoint(x: x, y: paddingTop - 7))
        }
    }

    /*
    弦（横線）および左端の弦番号ラベルを描画する。

    Arguments:
    context: 描画コンテキスト
    nutX: ナットX座標
    width: 描画可能幅
    paddingTop, stringSpacing: 垂直配置パラメータ
    */

    private func drawStringsAndLabels(
        context: GraphicsContext,
        nutX: CGFloat,
        width: CGFloat,
        paddingTop: CGFloat,
        stringSpacing: CGFloat
    ) {
        // 6弦(Guitar: 1E〜6E) または 4弦(Bass: 1G〜4E)
        let labels = (instrument == .guitar)
            ? ["1E", "2B", "3G", "4D", "5A", "6E"]
            : ["1G", "2D", "3A", "4E"]

        for (i, label) in labels.enumerated() {
            let y = paddingTop + CGFloat(i) * stringSpacing

            let text = Text(label)
                .font(.system(size: 8, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
            context.draw(context.resolve(text), at: CGPoint(x: 20, y: y))

            var stringPath = Path()
            stringPath.move(to: CGPoint(x: nutX, y: y))
            stringPath.addLine(to: CGPoint(x: width, y: y))

            let lineWidth: CGFloat = 0.8 + CGFloat(i) * 0.3
            context.stroke(stringPath, with: .color(.secondary.opacity(0.35)), lineWidth: lineWidth)
        }
    }

    /*
    ナット（太線）および各フレットの仕切り縦線を描画する。

    Arguments:
    context: 描画コンテキスト
    nutX, fretWidth, paddingTop, height: ジオメトリパラメータ
    */

    private func drawFretBars(context: GraphicsContext, nutX: CGFloat, fretWidth: CGFloat, paddingTop: CGFloat, height: CGFloat) {
        // ナット (0フレットの境界)
        var nutPath = Path()
        nutPath.move(to: CGPoint(x: nutX, y: paddingTop))
        nutPath.addLine(to: CGPoint(x: nutX, y: paddingTop + height))
        context.stroke(nutPath, with: .color(.primary.opacity(0.6)), lineWidth: 3.5)

        // 1〜5フレット線
        for fret in 1...5 {
            let x = nutX + CGFloat(fret) * fretWidth
            var fretPath = Path()
            fretPath.move(to: CGPoint(x: x, y: paddingTop))
            fretPath.addLine(to: CGPoint(x: x, y: paddingTop + height))
            context.stroke(fretPath, with: .color(.secondary.opacity(0.25)), lineWidth: 1.0)
        }
    }

    /*
    スケール音のポジションマーカー（丸バッジ＋音名）を描画する。

    Arguments:
    context: 描画コンテキスト
    nutX, fretWidth, paddingTop, stringSpacing: ジオメトリパラメータ
    */

    private func drawScaleMarkers(
        context: GraphicsContext,
        nutX: CGFloat,
        fretWidth: CGFloat,
        paddingTop: CGFloat,
        stringSpacing: CGFloat
    ) {
        // 表示対象の弦インデックス
        // 6弦モード: 1〜6弦 (stringNumber: 1...6)
        // 4弦モード: 3〜6弦 (stringNumber: 3...6 -> 描画行 0...3)
        for pos in scaleInfo.positions {
            let rowIndex: Int?
            if instrument == .guitar {
                rowIndex = pos.stringNumber - 1
            } else {
                // 4弦ベース: 3弦G->行0, 4弦D->行1, 5弦A->行2, 6弦E->行3
                if pos.stringNumber >= 3 {
                    rowIndex = pos.stringNumber - 3
                } else {
                    rowIndex = nil
                }
            }

            guard let row = rowIndex, row >= 0 else { continue }

            let y = paddingTop + CGFloat(row) * stringSpacing
            let x: CGFloat = (pos.fret == 0)
                ? (nutX - 12.0)
                : (nutX + CGFloat(pos.fret - 1) * fretWidth + (fretWidth / 2.0))

            drawMarkerBadge(context: context, center: CGPoint(x: x, y: y), position: pos)
        }
    }

    /*
    単一マーカーの丸バッジと音名テキストを描画する。

    Arguments:
    context: 描画コンテキスト
    center: マーカーの中心座標
    position: スケール音ポジション情報
    */

    private func drawMarkerBadge(context: GraphicsContext, center: CGPoint, position: ScaleFretPosition) {
        let radius: CGFloat
        let fillColor: Color
        let textColor: Color

        switch position.role {
        case .root:
            radius = 8.5
            fillColor = .orange
            textColor = .white
        case .chordTone:
            radius = 7.5
            fillColor = .teal
            textColor = .white
        case .scaleTone:
            radius = 6.5
            fillColor = Color(uiColor: .tertiarySystemFill)
            textColor = .primary
        }

        let circleRect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: radius * 2,
            height: radius * 2
        )

        context.fill(Path(ellipseIn: circleRect), with: .color(fillColor))

        // ルート音には白い境界線を追加して際立たせる
        if position.role == .root {
            context.stroke(Path(ellipseIn: circleRect), with: .color(.white), lineWidth: 1.2)
        }

        let font: Font = (position.role == .root)
            ? .system(size: 8, weight: .heavy, design: .rounded)
            : .system(size: 7, weight: .bold, design: .rounded)

        let labelText = Text(position.role == .root ? "R" : position.noteName)
            .font(font)
            .foregroundColor(textColor)

        context.draw(context.resolve(labelText), at: center)
    }
}
