
import SwiftUI

extension CGRect {
    static var currentScreenBounds: CGRect {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds ?? CGRect(x: 0, y: 0, width: 393, height: 852)
    }
}


struct TourOverlayView: View {
    let spaceName: String
    @EnvironmentObject var manager: TourManager
    
    var body: some View {
        ZStack {
            if manager.isActive {
                let frameKey = "\\(manager.currentStep.rawValue)_\\(spaceName)"
                
                // Fallback for step 1 if ToolbarItem GeometryReader fails
                let targetFrame: CGRect? = {
                    if let f = manager.registeredFrames[frameKey], f != .zero {
                        return f
                    } else if manager.currentStep == .step1_createNewProject && spaceName == "TourSpace" {
                        // Approximate top right + button frame
                        return CGRect(x: CGRect.currentScreenBounds.width - 50, y: 50, width: 44, height: 44)
                    }
                    return nil
                }()
                
                if let frame = targetFrame {
                    // 1. Cutout Background (blocks taps outside)
                    CutoutShape(holeRect: frame.insetBy(dx: -4, dy: -4), cornerRadius: 8)
                        .fill(Color.black.opacity(0.7), style: FillStyle(eoFill: true))
                        .ignoresSafeArea()
                        .allowsHitTesting(true) // Solid parts block taps, hole passes taps
                    
                    // 2. Tooltip UI
                    TourTooltipView(step: manager.currentStep, frame: frame)
                } else if isStepInThisSpace(manager.currentStep) {
                    // Dimming while waiting for frame
                    Color.black.opacity(0.7)
                        .ignoresSafeArea()
                        .allowsHitTesting(true)
                }
            }
        }
    }
    
    func isStepInThisSpace(_ step: TourStep) -> Bool {
        if spaceName == "SheetTourSpace" {
            return [.step3_tapRandomGenerate].contains(step)
        } else if spaceName == "PickerTourSpace" {
            return [.step10_selectPiano].contains(step)
        } else {
            return ![.step3_tapRandomGenerate, .step10_selectPiano].contains(step)
        }
    }
}

struct TourTooltipView: View {
    let step: TourStep
    let frame: CGRect
    @EnvironmentObject var manager: TourManager
    
    var body: some View {
        VStack(spacing: 12) {
            Text(titleForStep)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            if showNextButton {
                Button(action: {
                    manager.advance()
                }) {
                    Text("次へ")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                }
            }
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .shadow(radius: 10)
        // Position intelligently above or below the frame
        .position(
            x: CGRect.currentScreenBounds.midX,
            y: min(max(frame.minY > 200 ? frame.minY - 80 : frame.maxY + 80, 100), CGRect.currentScreenBounds.height - 100)
        )
    }
    
    var titleForStep: String {
        switch step {
        case .step1_createNewProject: return "まずは新規プロジェクトを作成しよう！\n右上の「＋」ボタンをタップしてね"
        case .step2_scrollAndTapGenerateMenu: return "曲を自動生成してみましょう！\n「曲を生成」ボタンをタップ！"
        case .step3_tapRandomGenerate: return "「おまかせランダム生成」をタップすると\n一瞬で曲の構成が完成します"
        case .step4_viewGeneratedSong: return "曲が生成されました！\nこのようにセクションが並びます"
        case .step5_tapScaleFretboard: return "次はスケール指板を見てみましょう\nハイライトされた部分をタップしてね"
        case .step6_playGuitar: return "アプリ内でギターの演奏ができます！\n適当にいくつかタップして音を鳴らしてみてね"
        case .step7_tapPlayButton: return "次は再生ボタンをタップして\n伴奏を流してみましょう"
        case .step8_playWhilePlaying: return "伴奏に合わせて自由に演奏してみましょう！\n弾き終わったら「次へ」を押してね"
        case .step9_tapInstrumentMenu: return "他の楽器も演奏できます\n「6弦Guitar」の部分をタップしてね"
        case .step10_selectPiano: return "メニューから「鍵盤Piano」を選んでみましょう"
        case .step11_playPiano: return "アプリ内でピアノの演奏ができます！\n適当にいくつか鍵盤をタップして音を鳴らしてね"
        case .step12_changeKey: return "画面上のKeyメニューをタップして\n好きなKeyに変更してみましょう"
        case .step13_changeGenreDance: return "次はGenreメニューから\n「Dance」を選択してみましょう"
        case .step14_changeGenreLofi: return "他にも色々なジャンルがあります\n「Lo-Fi」を選択してみましょう"
        case .step15_changeMixer: return "ミキサーから楽器の音色や音量を変更できます\nこれでツアーは完了です！"
        }
    }
    
    var showNextButton: Bool {
        return [.step4_viewGeneratedSong, .step6_playGuitar, .step8_playWhilePlaying, .step11_playPiano].contains(step)
    }
}
