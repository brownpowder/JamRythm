//
//  StaffScoreView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI

// MARK: - 五線譜ネイティブ描画ビュー

/*
SwiftUIのCanvasを利用して、現在のコードの構成音をト音記号の五線譜上に描画するビュー。
加線や臨時記号、構成音名のバッジも同時に表示する。
*/
struct StaffScoreView: View {
    let notes: [StaffNote]
    let chordName: String

    var body: some View {
        staffCanvas
            .frame(height: 130)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(uiColor: .tertiarySystemBackground))
            )
    }

    // MARK: - サブビュー

    /*
    五線譜（5線、ト音記号、音符、上下加線）を描画するCanvas。
    
    Arguments:
    なし
    
    Usage:
    StaffScoreViewのメインコンテンツとして描画される。
    */
    
    private var staffCanvas: some View {
        Canvas { context, size in
            let paddingLeft: CGFloat = 52.0
            let paddingRight: CGFloat = 20.0
            // 1ステップ（線と間の距離）を8.5ptに設定。五線譜の線間隔は2ステップ＝17pt
            let stepSpacing: CGFloat = 8.5
            let lineDistance = stepSpacing * 2.0

            // 五線譜の上下中央を第3線（B4, step 4）に合わせる
            let staffCenterY: CGFloat = size.height * 0.5
            let b4Y = staffCenterY
            // 第1線（E4, step 0）のY座標
            let e4Y = b4Y + (lineDistance * 2.0)
            let noteX: CGFloat = size.width * 0.56

            // 1. ト音記号描画
            let clefText = Text("𝄞")
                .font(.system(size: 52))
                .foregroundColor(.primary)
            context.draw(context.resolve(clefText), at: CGPoint(x: 30, y: staffCenterY + 2))

            // 2. 5本の線（第1線E4 〜 第5線F5）
            for lineIndex in 0..<5 {
                let y = e4Y - (CGFloat(lineIndex) * lineDistance)
                let path = Path { p in
                    p.move(to: CGPoint(x: paddingLeft, y: y))
                    p.addLine(to: CGPoint(x: size.width - paddingRight, y: y))
                }
                context.stroke(path, with: .color(Color.secondary.opacity(0.45)), lineWidth: 1.5)
            }

            // 3. 各構成音符（全音符風楕円）と加線の描画
            let sortedNotes = notes.sorted { $0.step < $1.step }
            var previousStep: Int?
            var previousXOffset: CGFloat = 0

            for note in sortedNotes {
                let y = e4Y - (CGFloat(note.step) * stepSpacing)

                // 2度音程（隣接音）の重なり防止オフセット
                var currentXOffset: CGFloat = 0
                if let prev = previousStep, abs(note.step - prev) <= 1 && previousXOffset == 0 {
                    currentXOffset = 13.0
                }
                previousStep = note.step
                previousXOffset = currentXOffset

                let actualX = noteX + currentXOffset
                drawNoteHead(context: context, note: note, x: actualX, y: y, e4Y: e4Y, stepSpacing: stepSpacing)
            }
        }
    }

    /*
    構成音の音名リストをバッジとして水平表示する。
    
    Arguments:
    なし
    
    Usage:
    五線譜の下部に音名ガイドとして表示される。
    */
    
    private var noteNamesRow: some View {
        HStack(spacing: 6) {
            Text("Notes:")
                .font(.caption2.bold())
                .foregroundColor(.secondary)
            ForEach(notes) { note in
                Text(note.name)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15))
                    .foregroundColor(.accentColor)
                    .cornerRadius(4)
            }
        }
    }

    // MARK: - 描画ヘルパー

    /*
    音符の符頭および必要な上下加線、臨時記号を描画する。
    
    Arguments:
    context
      グラフィックスコンテキスト。Canvasから渡される。
    note
      描画対象のStaffNoteデータ。
    x, y
      描画位置の座標。
    e4Y
      第1線（E4）のY座標。
    stepSpacing
      1音高ステップ（半線間）の間隔。
    
    Usage:
    staffCanvas内で各音符の加線および符頭描画に使用される。
    */
    
    private func drawNoteHead(
        context: GraphicsContext,
        note: StaffNote,
        x: CGFloat,
        y: CGFloat,
        e4Y: CGFloat,
        stepSpacing: CGFloat
    ) {
        // 下加線（C4以下の音符: step <= -2）
        if note.step <= -2 {
            var ledgerStep = -2
            while ledgerStep >= note.step {
                let ledgerY = e4Y - (CGFloat(ledgerStep) * stepSpacing)
                let ledger = Path { p in
                    p.move(to: CGPoint(x: x - 12, y: ledgerY))
                    p.addLine(to: CGPoint(x: x + 12, y: ledgerY))
                }
                context.stroke(ledger, with: .color(Color.secondary.opacity(0.65)), lineWidth: 1.5)
                ledgerStep -= 2
            }
        }

        // 上加線（A5以上の音符: step >= 10）
        if note.step >= 10 {
            var ledgerStep = 10
            while ledgerStep <= note.step {
                let ledgerY = e4Y - (CGFloat(ledgerStep) * stepSpacing)
                let ledger = Path { p in
                    p.move(to: CGPoint(x: x - 12, y: ledgerY))
                    p.addLine(to: CGPoint(x: x + 12, y: ledgerY))
                }
                context.stroke(ledger, with: .color(Color.secondary.opacity(0.65)), lineWidth: 1.5)
                ledgerStep += 2
            }
        }

        // 臨時記号（# や ♭）の描画
        if let accidental = note.accidental, !accidental.isEmpty {
            let accText = Text(accidental)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primary)
            context.draw(context.resolve(accText), at: CGPoint(x: x - 14, y: y))
        }

        // 符頭（全音符風の楕円）
        let noteRect = CGRect(x: x - 7.5, y: y - 5.5, width: 15, height: 11)
        let notePath = Path(ellipseIn: noteRect)
        context.fill(notePath, with: .color(Color.primary))
        context.stroke(notePath, with: .color(Color.accentColor), lineWidth: 1.2)
    }
}
