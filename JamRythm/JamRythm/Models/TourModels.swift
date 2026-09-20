import SwiftUI
import Combine

enum TourStep: Int, CaseIterable, Equatable {
    case step1_createNewProject = 1
    case step2_scrollAndTapGenerateMenu
    case step3_tapRandomGenerate
    case step4_viewGeneratedSong
    case step5_tapScaleFretboard
    case step6_playGuitar
    case step7_tapPlayButton
    case step8_playWhilePlaying
    case step9_tapInstrumentMenu
    case step10_selectPiano
    case step11_playPiano
    case step12_changeKey
    case step13_changeGenreDance
    case step14_changeGenreLofi
    case step15_changeMixer
}

class TourManager: ObservableObject {
    static let shared = TourManager()
    
    @Published var isActive: Bool = false
    @Published var currentStep: TourStep = .step1_createNewProject
    
    @Published var registeredFrames: [String: CGRect] = [:]
    
    func startTour() {
        currentStep = .step1_createNewProject
        registeredFrames.removeAll()
        isActive = true
    }
    
    func advance() {
        print("🚀 [TourManager] advance() called. Current: \(currentStep)")
        if let next = TourStep(rawValue: currentStep.rawValue + 1) {
            print("🚀 [TourManager] Transitioning to: \(next)")
            currentStep = next
        } else {
            print("🚀 [TourManager] Ending tour.")
            endTour()
        }
    }
    
    func endTour() {
        isActive = false
    }
    
    func notifyKeyChanged() {
        if isActive && currentStep == .step12_changeKey {
            advance()
        }
    }
    
    func notifyGenreChanged(to genre: MusicGenre) {
        if isActive {
            if currentStep == .step13_changeGenreDance && genre == .dance {
                advance()
            } else if currentStep == .step14_changeGenreLofi && genre == .lofi {
                advance()
            }
        }
    }
}

struct TourFramePreferenceKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { current, _ in current }
    }
}

struct TourSpotlightModifier: ViewModifier {
    let step: TourStep
    let spaceName: String
    @EnvironmentObject var tourManager: TourManager
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: TourFramePreferenceKey.self, value: ["\\(step.rawValue)_\\(spaceName)": geo.frame(in: spaceName == "global" ? .global : .named(spaceName))])
                }
            )
    }
}

extension View {
    func tourSpotlight(_ step: TourStep, space: String = "TourSpace") -> some View {
        self.modifier(TourSpotlightModifier(step: step, spaceName: space))
    }
}

struct CutoutShape: Shape {
    let holeRect: CGRect
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path(rect)
        path.addRoundedRect(in: holeRect, cornerSize: CGSize(width: cornerRadius, height: cornerRadius))
        return path
    }
}
