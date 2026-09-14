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
    var voicings: [GuitarVoicing] = []
    let chordName: String
    var notes: [StaffNote] = []

    // 単一ボイシング渡しの後方互換イニシャライザ
    init(voicing: GuitarVoicing, chordName: String, notes: [StaffNote] = []) {
        self.voicings = [voicing]
        self.chordName = chordName
        self.notes = notes
    }

    init(voicings: [GuitarVoicing], chordName: String, notes: [StaffNote] = []) {
        self.voicings = voicings
        self.chordName = chordName
        self.notes = notes
    }

    @State private var selectedVoicingIndex: Int = 0
    @AppStorage("useJapaneseNoteNames") private var useJapaneseNoteNames: Bool = false

    private var currentVoicing: GuitarVoicing {
        guard !voicings.isEmpty else {
            return GuitarVoicing(frets: [nil, nil, nil, nil, nil, nil])
        }
        let safeIndex = max(0, min(selectedVoicingIndex, voicings.count - 1))
        return voicings[safeIndex]
    }

    var body: some View {
        VStack(spacing: 2) {
            positionSelectorBar
                .padding(.top, 4)

            fretboardCanvas

            if !notes.isEmpty {
                noteNamesRow
                    .padding(.bottom, 6)
            }
        }
        .frame(height: 190)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .tertiarySystemBackground))
        )
        .onChange(of: chordName) { _, _ in
            selectedVoicingIndex = 0
        }
    }

    // MARK: - ポジション切り替えセレクター

    private var positionSelectorBar: some View {
        HStack(spacing: 12) {
            if voicings.count > 1 {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedVoicingIndex = (selectedVoicingIndex - 1 + voicings.count) % voicings.count
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(uiColor: .quaternarySystemFill))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)

                Text("\(selectedVoicingIndex + 1)/\(voicings.count): \(currentVoicing.positionName)")
                    .font(.caption2.bold())
                    .foregroundColor(.primary)

                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.15)) {
                        selectedVoicingIndex = (selectedVoicingIndex + 1) % voicings.count
                    }
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(uiColor: .quaternarySystemFill))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            } else {
                Text(currentVoicing.positionName)
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 音名行

    private var noteNamesRow: some View {
        Button(action: {
            guard NoteNameNotation.isJapaneseLanguage else { return }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.easeInOut(duration: 0.2)) {
                useJapaneseNoteNames.toggle()
            }
        }) {
            HStack(spacing: 6) {
                HStack(spacing: 3) {
                    Text("Notes:")
                        .font(.caption2.bold())
                        .foregroundColor(.secondary)
                    if NoteNameNotation.isJapaneseLanguage {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                }

                let notation: NoteNameNotation = (NoteNameNotation.isJapaneseLanguage && useJapaneseNoteNames) ? .japanese : .english
                ForEach(notes) { note in
                    Text(NoteNameNotation.localizedNoteName(note.name, notation: notation))
                        .font(.caption2.bold())
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundColor(.accentColor)
                        .cornerRadius(4)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!NoteNameNotation.isJapaneseLanguage)
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
            let paddingTop: CGFloat = 28.0
            let paddingBottom: CGFloat = 20.0

            let usableWidth = size.width - nutX - paddingRight
            let fretWidth = usableWidth / 5.0
            let usableHeight = size.height - paddingTop - paddingBottom
            let stringSpacing = usableHeight / 5.0
            let baseFret = currentVoicing.baseFret

            // 1. フレット番号ラベル（上部）
            drawFretNumbers(context: context, nutX: nutX, fretWidth: fretWidth, paddingTop: paddingTop, baseFret: baseFret)

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
                height: usableHeight,
                baseFret: baseFret
            )

            // 4. 各弦のマーカー（開放○、ミュート×、押弦フレット●）を描画
            drawFretMarkers(
                context: context,
                nutX: nutX,
                fretWidth: fretWidth,
                paddingTop: paddingTop,
                stringSpacing: stringSpacing,
                baseFret: baseFret
            )
        }
    }

    // MARK: - 描画ヘルパーメソッド

    /*
    上部にフレット番号（baseFret〜baseFret+4）を描画する。
    
    Arguments:
    context: 描画コンテキスト。
    nutX: ナットのX座標。
    fretWidth: 1フレットあたりの横幅。
    paddingTop: 上部パディング。
    baseFret: 基準開始フレット番号。
    
    Usage:
    fretboardCanvas内でフレット番号の描画に使用される。
    */
    
    private func drawFretNumbers(context: GraphicsContext, nutX: CGFloat, fretWidth: CGFloat, paddingTop: CGFloat, baseFret: Int) {
        for i in 0..<5 {
            let fret = baseFret + i
            let x = nutX + (CGFloat(i) + 0.5) * fretWidth
            let text = Text("\(fret)f")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.secondary)
            context.draw(context.resolve(text), at: CGPoint(x: x, y: paddingTop - 12))
        }
    }

    /*
    6本の弦（横線）と左端の弦番号・音名ラベルを描画する。
    
    Arguments:
    context: 描画コンテキスト。
    paddingLeft, nutX, width, paddingTop, stringSpacing: 座標・寸法パラメータ。
    
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
    ナット（開放時は太線、ハイポジション時は通常線＋開始フレット文字）およびフレット縦線を描画する。
    
    Arguments:
    context: 描画コンテキスト。
    nutX, fretWidth, paddingTop, height: 座標・寸法パラメータ。
    baseFret: 基準開始フレット。
    
    Usage:
    fretboardCanvas内で指板のフレット枠の描画に使用される。
    */
    
    private func drawFretBars(
        context: GraphicsContext,
        nutX: CGFloat,
        fretWidth: CGFloat,
        paddingTop: CGFloat,
        height: CGFloat,
        baseFret: Int
    ) {
        // 左端境界線（ナットまたは開始フレット境界）
        let nutPath = Path { p in
            p.move(to: CGPoint(x: nutX, y: paddingTop))
            p.addLine(to: CGPoint(x: nutX, y: paddingTop + height))
        }

        if baseFret == 1 {
            // 通常ナット（太い線）
            context.stroke(nutPath, with: .color(Color.primary.opacity(0.8)), lineWidth: 3.5)
        } else {
            // ハイポジション境界線（通常線）
            context.stroke(nutPath, with: .color(Color.secondary.opacity(0.5)), lineWidth: 1.5)
            // 左端に開始フレット表示 (例: "5fr")
            let posText = Text("\(baseFret)fr")
                .font(.system(size: 9, weight: .heavy, design: .rounded))
                .foregroundColor(.orange)
            context.draw(context.resolve(posText), at: CGPoint(x: nutX - 16, y: paddingTop + height / 2.0))
        }

        // 1〜5フレットの縦線
        for i in 1...5 {
            let x = nutX + CGFloat(i) * fretWidth
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
    context, nutX, fretWidth, paddingTop, stringSpacing: 座標・寸法パラメータ。
    baseFret: 基準開始フレット。
    
    Usage:
    fretboardCanvas内で各弦の押弦ポイントを描画するために呼び出される。
    */
    
    private func drawFretMarkers(
        context: GraphicsContext,
        nutX: CGFloat,
        fretWidth: CGFloat,
        paddingTop: CGFloat,
        stringSpacing: CGFloat,
        baseFret: Int
    ) {
        for stringNum in 1...6 {
            let stringIndex = stringNum - 1
            let y = paddingTop + CGFloat(stringIndex) * stringSpacing
            let fretValue = currentVoicing.fret(forString: stringNum)

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
            } else if let fret = fretValue {
                let offset = fret - baseFret
                if offset >= 0 && offset < 5 {
                    // 該当フレットマスの中心に丸ドットマーカーを描画
                    let x = nutX + (CGFloat(offset) + 0.5) * fretWidth
                    let markerRect = CGRect(x: x - 7, y: y - 7, width: 14, height: 14)
                    context.fill(Path(ellipseIn: markerRect), with: .color(Color.accentColor))
                }
            }
        }
    }
}
