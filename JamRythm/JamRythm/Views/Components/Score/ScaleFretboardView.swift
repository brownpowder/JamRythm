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
    @ObservedObject var store = StoreManager.shared
    let theoryService: MusicTheoryServiceProtocol
    var audioService: AudioServiceProtocol? = nil

    @State private var instrument: ScaleInstrument = .guitar
    @State private var scaleType: ScaleType = .pentatonic
    @State private var referenceMode: ScaleReferenceMode = .key

    @AppStorage("useJapaneseNoteNames") private var useJapaneseNoteNames: Bool = false

    private var scaleInfo: ScaleInfo {
        theoryService.scaleInfo(for: key, chord: chord, scaleType: scaleType, referenceMode: referenceMode)
    }


    private var availableScaleTypes: [ScaleType] {
        var types: [ScaleType] = [.pentatonic, .diatonic, .japanese, .ryukyu]

        return types
    }

    var body: some View {
        VStack(spacing: 6) {
            topControlBar
            if instrument == .piano {
                keyboardCanvas
            } else {
                fretboardCanvas
            }
        }
        .frame(height: 190)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .tertiarySystemBackground))
        )
        .onChange(of: instrument) { inst in
            if TourManager.shared.isActive && (TourManager.shared.currentStep == .step9_tapInstrumentMenu || TourManager.shared.currentStep == .step10_selectPiano) && inst == .piano {
                TourManager.shared.currentStep = .step11_playPiano
            }
        }
    }
    


    private var keyboardCanvas: some View {
        GeometryReader { geometry in
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    let whiteKeyCount = 43 // C1 to C7 is 6 octaves + 1 note
                    let whiteKeyWidth: CGFloat = 40.0
                    let totalWidth = CGFloat(whiteKeyCount) * whiteKeyWidth
                    
                    ZStack(alignment: .topLeading) {
                        Canvas { context, size in
                let blackKeyWidth = whiteKeyWidth * 0.65
                let blackKeyHeight = size.height * 0.6
                
                // Draw white keys
                for i in 0..<whiteKeyCount {
                    let rect = CGRect(x: CGFloat(i) * whiteKeyWidth, y: 0, width: whiteKeyWidth, height: size.height)
                    context.fill(Path(roundedRect: rect, cornerRadius: 4), with: .color(.white))
                    context.stroke(Path(roundedRect: rect, cornerRadius: 4), with: .color(.gray), lineWidth: 1)
                }
                
                // Draw black keys
                let pattern = [1, 1, 0, 1, 1, 1, 0] // C D E F G A B
                var blackKeyIndices = [Int]()
                for octave in 0..<6 {
                    for (index, hasBlackKey) in pattern.enumerated() {
                        if hasBlackKey == 1 {
                            blackKeyIndices.append(octave * 7 + index)
                        }
                    }
                }
                
                for i in blackKeyIndices {
                    let rect = CGRect(
                        x: CGFloat(i + 1) * whiteKeyWidth - (blackKeyWidth / 2),
                        y: 0,
                        width: blackKeyWidth,
                        height: blackKeyHeight
                    )
                    context.fill(Path(roundedRect: rect, cornerRadius: 3), with: .color(.black))
                }
                
                // Draw markers for scale notes
                let baseMidi: UInt8 = 24 // C1
                for midiNote in baseMidi...96 { // Up to C7
                    let semitone = Int(midiNote) % 12
                    let noteName = Key.noteName(forSemitone: semitone)
                    
                    if scaleInfo.scaleNotes.contains(noteName) {
                        let isRoot = (noteName == chord.rootNote)
                        let color: Color = isRoot ? .orange : .accentColor
                        let noteIndex = Int(midiNote - baseMidi)
                        
                        let octave = noteIndex / 12
                        let semitoneInOctave = noteIndex % 12
                        let whiteIndexMap = [0, 0, 1, 1, 2, 3, 3, 4, 4, 5, 5, 6]
                        let isBlackMap = [false, true, false, true, false, false, true, false, true, false, true, false]
                        
                        let wIndex = octave * 7 + whiteIndexMap[semitoneInOctave]
                        let isBlack = isBlackMap[semitoneInOctave]
                        
                        let center: CGPoint
                        if isBlack {
                            center = CGPoint(
                                x: CGFloat(wIndex) * whiteKeyWidth + (whiteKeyWidth / 2) + (whiteKeyWidth / 2),
                                y: blackKeyHeight - 16
                            )
                        } else {
                            center = CGPoint(
                                x: CGFloat(wIndex) * whiteKeyWidth + (whiteKeyWidth / 2),
                                y: size.height - 20
                            )
                        }
                        
                        context.fill(Path(ellipseIn: CGRect(x: center.x - 10, y: center.y - 10, width: 20, height: 20)), with: .color(color))
                        
                        var text = Text(noteName)
                            .font(.system(size: 10, weight: .bold))
                        if NoteNameNotation.isJapaneseLanguage && useJapaneseNoteNames {
                            text = Text(NoteNameNotation.localizedNoteName(noteName, notation: .japanese))
                                .font(.system(size: 9, weight: .bold))
                        }
                        context.draw(text.foregroundColor(.white), at: center)
                    }
                }
            }
                        .frame(width: totalWidth, height: geometry.size.height)
                        .onTapGesture { location in
                            handlePianoTap(at: location, size: CGSize(width: totalWidth, height: geometry.size.height))
                            // if TourManager.shared.isActive && TourManager.shared.currentStep == .step11_playPiano {
                            //     TourManager.shared.advance()
                            // }
                        }
                        
                        // C3 anchor (C1 is baseMidi=24, C3 is 2 octaves up = 14 white keys)
                        Color.clear
                            .frame(width: 1, height: 1)
                            .position(x: 14 * whiteKeyWidth + (whiteKeyWidth / 2), y: geometry.size.height / 2)
                            .id("C3")
                    }
                    .onAppear {
                        DispatchQueue.main.async {
                            proxy.scrollTo("C3", anchor: .center)
                        }
                    }
                }
            }
        }
    }

    private func handlePianoTap(at location: CGPoint, size: CGSize) {
        guard let audioService = audioService else { return }
        let whiteKeyCount = 43
        let whiteKeyWidth: CGFloat = 40.0
        let blackKeyWidth = whiteKeyWidth * 0.65
        let blackKeyHeight = size.height * 0.6
        
        let pattern = [1, 1, 0, 1, 1, 1, 0]
        var blackKeyIndices = [Int]()
        for octave in 0..<6 {
            for (index, hasBlackKey) in pattern.enumerated() {
                if hasBlackKey == 1 {
                    blackKeyIndices.append(octave * 7 + index)
                }
            }
        }
        
        var tappedMidiNote: UInt8? = nil
        
        // Check black keys first
        for i in blackKeyIndices {
            let rect = CGRect(
                x: CGFloat(i + 1) * whiteKeyWidth - (blackKeyWidth / 2),
                y: 0,
                width: blackKeyWidth,
                height: blackKeyHeight
            )
            if rect.contains(location) {
                // Determine midi note
                let octave = i / 7
                let wIndex = i % 7
                let whiteToBlackMidi = [0: 1, 1: 3, 2: -1, 3: 6, 4: 8, 5: 10, 6: -1]
                tappedMidiNote = 24 + UInt8(octave * 12 + whiteToBlackMidi[wIndex]!)
                break
            }
        }
        
        if tappedMidiNote == nil {
            // Check white keys
            let wIndex = Int(location.x / whiteKeyWidth)
            if wIndex >= 0 && wIndex < whiteKeyCount {
                let octave = wIndex / 7
                let wIndexInOctave = wIndex % 7
                let whiteToMidi = [0, 2, 4, 5, 7, 9, 11]
                tappedMidiNote = 24 + UInt8(octave * 12 + whiteToMidi[wIndexInOctave])
            }
        }
        
        if let midi = tappedMidiNote {
            audioService.playPreviewNote(midi, instrument: .piano)
        }
    }

    // MARK: - 上部コントロールバー（スケール名・Notes・切替スイッチ）

    /*
    スケール名、Scale Notesバッジ一覧、基準切替(Chord/Key)、楽器切替、スケール切替ボタンを描画する。

    Arguments:
    なし

    Usage:
    指板の上部に配置され、演奏ガイドおよびモード切り替えを提供する。
    */

    private var topControlBar: some View {
        VStack(spacing: 5) {
            // 上段: スケール名 & 各種切替ボタン
            HStack(spacing: 6) {
                // スケール名ラベル（タップでスケール種類切替）
                CustomPickerButton(
                    options: availableScaleTypes,
                    selection: $scaleType,
                    sheetTitle: "スケール選択"
                ) {
                    HStack(spacing: 3) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.accentColor)
                        Text(LocalizedStringKey(scaleInfo.scaleName))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(width: 85, alignment: .leading)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(uiColor: .quaternarySystemFill))
                    .cornerRadius(5)
                } optionRow: { type in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(LocalizedStringKey(type.rawValue)).font(.headline)
                            Text(LocalizedStringKey(type.shortName)).font(.caption).foregroundColor(.secondary)
                        }
                        Spacer()
                        if type.isPremiumOnly {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                        }
                    }
                }
                
                Spacer()

                // 基準切替: Chord基準 ⇔ Key基準
                Button(action: {
                    referenceMode = (referenceMode == .chord) ? .key : .chord
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: referenceMode == .chord ? "target" : "globe")
                            .font(.system(size: 8, weight: .bold))
                            .frame(width: 12)
                        Text(LocalizedStringKey(referenceMode.shortName))
                            .font(.system(size: 9, weight: .bold))
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(width: 70, alignment: .leading)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(referenceMode == .chord ? Color.accentColor.opacity(0.18) : Color(uiColor: .quaternarySystemFill))
                    .foregroundColor(referenceMode == .chord ? .accentColor : .secondary)
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)

                // 楽器切替トグルボタン
                Button(action: {
                    instrument = (instrument == .guitar) ? .piano : .guitar
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: instrument == .piano ? "pianokeys" : "guitars")
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 14)
                        Text(LocalizedStringKey(instrument.shortName))
                            .font(.system(size: 10, weight: .bold))
                            .lineLimit(1)
                            .frame(width: 40, alignment: .leading)
                    }
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15))
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .tourSpotlight(.step9_tapInstrumentMenu)
                .onChange(of: instrument) { newValue in
                    if newValue == .piano {
                        audioService?.setLeadInstrument(.piano)
                    } else {
                        audioService?.setLeadInstrument(.guitar)
                    }
                }
            }

            // 下段: スケール構成音バッジ列 & Chord/Key切替
            HStack {
                Button(action: {
                    guard NoteNameNotation.isJapaneseLanguage else { return }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        useJapaneseNoteNames.toggle()
                    }
                }) {
                    HStack(spacing: 4) {
                        HStack(spacing: 2) {
                            Text("Notes:")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            if NoteNameNotation.isJapaneseLanguage {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                        }

                        let notation: NoteNameNotation = (NoteNameNotation.isJapaneseLanguage && useJapaneseNoteNames) ? .japanese : .english
                        ForEach(scaleInfo.scaleNotes, id: \.self) { note in
                            let isRoot = (note == chord.rootNote)
                            Text(NoteNameNotation.localizedNoteName(note, notation: notation))
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(isRoot ? .white : .primary)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(
                                    isRoot ? Color.orange : Color(uiColor: .quaternarySystemFill)
                                )
                                .cornerRadius(3)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(!NoteNameNotation.isJapaneseLanguage)
                

            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 4)
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
        GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
                let nutX: CGFloat = 46.0
                let paddingRight: CGFloat = 16.0
                let paddingTop: CGFloat = 14.0
                let paddingBottom: CGFloat = 8.0
                let numberOfFrets = 15
                let fretWidth: CGFloat = 50.0
                let totalWidth = nutX + (fretWidth * CGFloat(numberOfFrets)) + paddingRight
                
                Canvas { context, size in
                    let usableWidth = totalWidth - nutX - paddingRight
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
                .frame(width: totalWidth, height: geometry.size.height)
                .onTapGesture { location in
                    handleTap(at: location, size: CGSize(width: totalWidth, height: geometry.size.height))
                }
            }
        }
    }
    
    private func handleTap(at location: CGPoint, size: CGSize) {
        guard let audioService = audioService else { return }
        let nutX: CGFloat = 46.0
        let paddingRight: CGFloat = 16.0
        let paddingTop: CGFloat = 14.0
        let paddingBottom: CGFloat = 8.0

        let fretWidth: CGFloat = 50.0
        let usableHeight = size.height - paddingTop - paddingBottom
        let stringCount = (instrument == .guitar) ? 6 : 4
        let stringSpacing = usableHeight / CGFloat(max(1, stringCount - 1))

        var tappedPos: ScaleFretPosition? = nil

        for pos in scaleInfo.positions {
            let rowIndex: Int?
            if instrument == .guitar {
                rowIndex = pos.stringNumber - 1
            } else {
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
            
            let distance = hypot(location.x - x, location.y - y)
            if distance < 16.0 {
                tappedPos = pos
                break
            }
        }
        
        guard let pos = tappedPos else { return }
        
        let baseMidi: UInt8
        switch pos.stringNumber {
        case 6: baseMidi = 40 // E2
        case 5: baseMidi = 45 // A2
        case 4: baseMidi = 50 // D3
        case 3: baseMidi = 55 // G3
        case 2: baseMidi = 59 // B3
        case 1: baseMidi = 64 // E4
        default: baseMidi = 40
        }
        
        let midiNote = baseMidi + UInt8(pos.fret)
        audioService.playPreviewNote(midiNote, instrument: instrument)
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
        for fret in 1...15 {
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
        // 6弦(Guitar: 1E〜6E)
        let labels = ["1E", "2B", "3G", "4D", "5A", "6E"]

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
        for fret in 1...15 {
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

        let labelText = Text(position.noteName)
            .font(font)
            .foregroundColor(textColor)

        context.draw(context.resolve(labelText), at: center)
    }
}
