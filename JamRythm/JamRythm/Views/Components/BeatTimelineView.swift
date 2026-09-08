//
//  BeatTimelineView.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import SwiftUI

// MARK: - ビート & 小節タイムライン表示コンポーネント

/*
現在の再生小節と拍の進行を視覚的に表示するコンポーネント。
演奏者がカラオケのテロップのように直感的に現在位置を把握できるようにする。
*/
struct BeatTimelineView: View {
    let measures: [Measure]
    let currentMeasureIndex: Int
    let currentBeat: Int

    var body: some View {
        VStack(spacing: 12) {
            // 小節タイムライン
            HStack(spacing: 8) {
                ForEach(Array(measures.enumerated()), id: \.element.id) { index, measure in
                    measureCard(index: index, measure: measure)
                }
            }

            // 拍（1〜4拍）インジケーター
            HStack(spacing: 12) {
                ForEach(1...4, id: \.self) { beat in
                    beatIndicator(beat: beat)
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal)
    }

    // MARK: - サブビュー

    /*
    1小節ごとの進行カードを描画する。
    
    Arguments:
    index
      小節のインデックス番号。
    measure
      小節のデータ（度数、コード）。
    
    Usage:
    タイムラインのHStack内で各小節を表示するために呼び出される。
    */
    
    private func measureCard(index: Int, measure: Measure) -> some View {
        let isCurrent = index == currentMeasureIndex
        return VStack(spacing: 4) {
            Text("\(index + 1)")
                .font(.caption2)
                .bold()
                .foregroundColor(isCurrent ? .accentColor : .secondary)

            Text(measure.activeChord.displayString)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(isCurrent ? .white : .primary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text("Base: \(measure.bassNote)")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isCurrent ? Color.accentColor.opacity(0.25) : Color(uiColor: .secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isCurrent ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .animation(.easeInOut(duration: 0.15), value: isCurrent)
    }

    /*
    現在の拍（Beat）を点滅表示するLED風インジケーターを描画する。
    
    Arguments:
    beat
      1〜4の拍番号。
    
    Usage:
    テンポ感と拍頭（1拍目）の強調表示に使用される。
    */
    
    private func beatIndicator(beat: Int) -> some View {
        let isActive = beat == currentBeat
        let isFirstBeat = beat == 1
        return Circle()
            .fill(
                isActive
                    ? (isFirstBeat ? Color.red : Color.accentColor)
                    : Color.gray.opacity(0.3)
            )
            .frame(width: isFirstBeat ? 14 : 10, height: isFirstBeat ? 14 : 10)
            .scaleEffect(isActive ? 1.3 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isActive)
    }
}
