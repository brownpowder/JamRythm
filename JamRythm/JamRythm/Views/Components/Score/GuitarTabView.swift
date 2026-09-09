//
//  GuitarTabView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI

// MARK: - 横軸フレット式ギターTAB / 指板ダイアグラムビュー

/*
ギタリストが直感的に押弦位置を認識できるよう、
横軸をフレット（開放弦〜5フレット）、縦軸を6弦〜1弦としたグリッド形式のネイティブ描画ビュー。
*/
struct GuitarTabView: View {
    let voicing: GuitarVoicing
    let chordName: String

    var body: some View {
        fretboardCanvas
            .frame(height: 130)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .tertiarySystemBackground))
            )
    }

    // MARK: - キャンバス描画

    /*
    Canvasを用いて横軸フレット（ナット、1〜5フレット）、縦軸弦（1〜6弦）、押弦マーカーを描画する。
    
    Arguments:
    なし
    
    Usage:
    GuitarTabViewの本体描画として使用される。
    */
    
    private var fretboardCanvas: some View {
        Canvas { context, size in
            let paddingLeft: CGFloat = 36.0
            let nutX: CGFloat = 62.0
            let paddingRight: CGFloat = 20.0
            let paddingTop: CGFloat = 24.0
            let paddingBottom: CGFloat = 16.0

            let usableWidth = size.width - nutX - paddingRight
            let fretWidth = usableWidth / 5.0
            let usableHeight = size.height - paddingTop - paddingBottom
            let stringSpacing = usableHeight / 5.0

            // 1. フレット番号ラベル（上部）
            drawFretNumbers(context: context, nutX: nutX, fretWidth: fretWidth, paddingTop: paddingTop)

            // 2. 6本の弦（横線）と弦名ラベルを描画
            drawStringsAndLabels(
                context: context,
                paddingLeft: paddingLeft,
                nutX: nutX,
                width: size.width - paddingRight,
                paddingTop: paddingTop,
                stringSpacing: stringSpacing
            )

            // 3. ナットおよびフレット線（縦線）を描画
            drawFretBars(
                context: context,
                nutX: nutX,
                fretWidth: fretWidth,
                paddingTop: paddingTop,
                height: usableHeight
            )

            // 4. 各弦のマーカー（開放○、ミュート×、押弦フレット●）を描画
            drawFretMarkers(
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
    上部にフレット番号（1〜5）を描画する。
    
    Arguments:
    context
      描画コンテキスト。
    nutX
      ナットのX座標。
    fretWidth
      1フレットあたりの横幅。
    paddingTop
      上部パディング。
    
    Usage:
    fretboardCanvas内でフレット番号の描画に使用される。
    */
    
    private func drawFretNumbers(context: GraphicsContext, nutX: CGFloat, fretWidth: CGFloat, paddingTop: CGFloat) {
        for fret in 1...5 {
            let x = nutX + (CGFloat(fret) - 0.5) * fretWidth
            let text = Text("\(fret)f")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
            context.draw(context.resolve(text), at: CGPoint(x: x, y: paddingTop - 12))
        }
    }

    /*
    6本の弦（横線）と左端の弦番号・音名ラベルを描画する。
    
    Arguments:
    context
      描画コンテキスト。
    paddingLeft, nutX, width, paddingTop, stringSpacing
      各座標・間隔パラメータ。
    
    Usage:
    fretboardCanvas内で弦の描画に使用される。
    */
    
    private func drawStringsAndLabels(
        context: GraphicsContext,
        paddingLeft: CGFloat,
        nutX: CGFloat,
        width: CGFloat,
        paddingTop: CGFloat,
        stringSpacing: CGFloat
    ) {
        let stringNames = ["1E", "2B", "3G", "4D", "5A", "6E"]

        for i in 0..<6 {
            let y = paddingTop + CGFloat(i) * stringSpacing

            // 弦番号ラベル (例: "1E")
            let labelText = Text(stringNames[i])
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.secondary)
            context.draw(context.resolve(labelText), at: CGPoint(x: paddingLeft - 14, y: y))

            // 弦の横線
            let linePath = Path { p in
                p.move(to: CGPoint(x: nutX, y: y))
                p.addLine(to: CGPoint(x: width, y: y))
            }
            context.stroke(linePath, with: .color(Color.secondary.opacity(0.4)), lineWidth: 1.2)
        }
    }

    /*
    ナット（太い境界線）および1〜5フレットの縦線を描画する。
    
    Arguments:
    context
      描画コンテキスト。
    nutX, fretWidth, paddingTop, height
      座標・寸法パラメータ。
    
    Usage:
    fretboardCanvas内で指板のフレット枠の描画に使用される。
    */
    
    private func drawFretBars(
        context: GraphicsContext,
        nutX: CGFloat,
        fretWidth: CGFloat,
        paddingTop: CGFloat,
        height: CGFloat
    ) {
        // ナット（太い線）
        let nutPath = Path { p in
            p.move(to: CGPoint(x: nutX, y: paddingTop))
            p.addLine(to: CGPoint(x: nutX, y: paddingTop + height))
        }
        context.stroke(nutPath, with: .color(Color.primary.opacity(0.8)), lineWidth: 3.5)

        // 1〜5フレットの縦線
        for fret in 1...5 {
            let x = nutX + CGFloat(fret) * fretWidth
            let barPath = Path { p in
                p.move(to: CGPoint(x: x, y: paddingTop))
                p.addLine(to: CGPoint(x: x, y: paddingTop + height))
            }
            context.stroke(barPath, with: .color(Color.secondary.opacity(0.35)), lineWidth: 1.0)
        }
    }

    /*
    各弦の押弦マーカー（開放弦○、ミュート×、押弦●）を適切なフレットマスに描画する。
    
    Arguments:
    context, nutX, fretWidth, paddingTop, stringSpacing
      座標・寸法パラメータ。
    
    Usage:
    fretboardCanvas内で各弦の押弦ポイントを描画するために呼び出される。
    */
    
    private func drawFretMarkers(
        context: GraphicsContext,
        nutX: CGFloat,
        fretWidth: CGFloat,
        paddingTop: CGFloat,
        stringSpacing: CGFloat
    ) {
        for stringNum in 1...6 {
            let stringIndex = stringNum - 1
            let y = paddingTop + CGFloat(stringIndex) * stringSpacing
            let fretValue = voicing.fret(forString: stringNum)

            if fretValue == nil {
                // ミュート (×): ナットのすぐ左に表示
                let text = Text("×")
                    .font(.system(size: 13, weight: .heavy))
                    .foregroundColor(.red.opacity(0.85))
                context.draw(context.resolve(text), at: CGPoint(x: nutX - 14, y: y))
            } else if fretValue == 0 {
                // 開放弦 (○): ナットのすぐ左に表示
                let text = Text("○")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.accentColor)
                context.draw(context.resolve(text), at: CGPoint(x: nutX - 14, y: y))
            } else if let fret = fretValue, fret >= 1 && fret <= 5 {
                // 押弦フレット: 該当フレットマスの中心にシンプルな丸ドットマーカーを描画
                let x = nutX + (CGFloat(fret) - 0.5) * fretWidth
                let markerRect = CGRect(x: x - 7, y: y - 7, width: 14, height: 14)
                context.fill(Path(ellipseIn: markerRect), with: .color(Color.accentColor))
            }
        }
    }
}
