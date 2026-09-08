# Jam-Rythm 詳細システム設計書 (Detailed Architecture & Technical Spec)

本ドキュメントは、コーダーが本仕様に基づき迷いなく実装を行えるレベルまで具体化した詳細設計書である。

## 1. アプリケーション・アーキテクチャ詳細
**MVVM (Model-View-ViewModel)** に加え、テスタビリティと拡張性を担保するため **ProtocolベースのDependency Injection (DI)** を採用する。

- **UI (SwiftUI)**: `@StateObject` や `@ObservedObject` を通じてViewModelを監視。ロジックを持たず、ViewModelの関数を呼ぶだけ。
  - **コンポーネント化とDRY原則**: コード表示枠、各種ボタン、タイムライン等のUI要素は徹底的に細分化（SubView化）し、コードの重複を防ぐ（DRY原則）。
- **ViewModel**: `ObservableObject` に準拠。Serviceは直接インスタンス化せず、`init` でProtocolとして注入(DI)する。
- **Service**: `Protocol` でインターフェースを定義し、具象クラスで実装する。これにより、テスト時にモックと差し替え可能にする。

---

## 2. ドメインモデル (Models) 詳細定義
データ構造は `Struct` を基本とし、保存可能なものは `Codable` に準拠する。

```swift
import Foundation

// MARK: - 音楽の基本要素
enum Key: String, Codable {
    case C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B
}

enum ChordFlavor: String, Codable {
    case stable = "安定"
    case melancholy = "少し切ない"
    case stylish = "おしゃれ"
    case tension = "緊張感"
}

struct Chord: Codable, Equatable {
    let rootNote: String      // 例: "G"
    let type: String          // 例: "maj7", "m7b5"
    let bassNote: String?     // 分数コードの場合 例: "B"
    
    var displayString: String {
        return bassNote != nil ? "\(rootNote)\(type)/\(bassNote!)" : "\(rootNote)\(type)"
    }
}

// MARK: - プロジェクト構造
struct Project: Codable, Identifiable {
    let id: UUID
    var title: String
    var bpm: Double
    var key: Key
    var sections: [Section]
}

struct Section: Codable, Identifiable {
    let id: UUID
    var type: SectionType     // Aメロ, Bメロ, サビ等
    var measures: [Measure]
}

struct Measure: Codable, Identifiable {
    let id: UUID
    let baseDegree: Int                   // 王道進行テンプレートからの度数 (例: 4)
    let bassNote: String                  // 実際のベースルート (例: "F")
    var chordCandidates: [ChordCandidate] // 提示される4つの候補
    var selectedChord: Chord?             // ユーザーが選んだコード
}

struct ChordCandidate: Codable, Identifiable {
    let id: UUID
    let flavor: ChordFlavor
    let chord: Chord
}
```

---

## 3. サービス層 (Services) インターフェース定義
コーダーは以下の `Protocol` に従って具象クラスを実装すること。

### 3.1. AudioService
SF2音源を読み込み、`AVAudioEngine` でDrum/BassのMIDIシーケンスを鳴らす。

```swift
import Combine
import Foundation

struct PlaybackPosition {
    let measureIndex: Int
    let beat: Int
}

protocol AudioServiceProtocol {
    /// SF2音源などの初期化
    func setupEngine() throws
    
    /// プロジェクトデータを元にMIDIシーケンスを生成・準備する
    func prepare(project: Project) throws
    
    func play()
    func pause()
    func stop()
    
    /// BPMの動的変更
    func setBPM(_ bpm: Double)
    
    /// 現在の再生位置をUIに通知するPublisher
    var currentPositionPublisher: AnyPublisher<PlaybackPosition, Never> { get }
    
    /// Bluetooth等の遅延補正用オフセット (ミリ秒)
    var syncOffsetMs: Double { get set }
}
```
**実装時の注意 (オーディオ処理)**
- スマホスピーカー対策として、`AVAudioEngine` の `mainMixerNode` に `AVAudioUnitDynamicsProcessor` (コンプレッサー/リミッター) と `AVAudioUnitEQ` をインサートし、ベース帯域の倍音と全体の音圧を稼ぐこと。

### 3.2. MusicTheoryService
度数とKeyからコード候補を計算するロジック。完全オフライン動作。

```swift
protocol MusicTheoryServiceProtocol {
    /// 該当の小節に対する4つのコード候補を算出する
    /// - Parameters:
    ///   - key: 現在のキー (例: C)
    ///   - baseDegree: ベースの度数 (例: 4 = F)
    /// - Returns: "安定", "切ない", "おしゃれ", "緊張感" の4ラベルを含む候補リスト
    func calculateCandidates(key: Key, baseDegree: Int) -> [ChordCandidate]
}
```

### 3.3. StorageService
```swift
protocol StorageServiceProtocol {
    func save(project: Project) throws
    func loadProjects() throws -> [Project]
}
```

---

## 4. ViewModel (状態管理) 設計
メインエディタ画面（Play Editor）を制御するViewModelの設計。

```swift
import Combine
import Foundation

@MainActor
class PlayEditorViewModel: ObservableObject {
    // MARK: - 依存関係
    private let audioService: AudioServiceProtocol
    private let theoryService: MusicTheoryServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - 公開State (Viewがバインドする)
    @Published var project: Project
    @Published var isPlaying: Bool = false
    @Published var currentMeasureIndex: Int = 0
    @Published var currentBeat: Int = 1
    
    // 現在の小節のコード候補
    @Published var currentCandidates: [ChordCandidate] = []
    
    init(project: Project, audioService: AudioServiceProtocol, theoryService: MusicTheoryServiceProtocol) {
        self.project = project
        self.audioService = audioService
        self.theoryService = theoryService
        
        bindAudioPosition()
    }
    
    // MARK: - インテント (Viewからの操作)
    func togglePlay() {
        isPlaying ? audioService.pause() : audioService.play()
        isPlaying.toggle()
    }
    
    func selectChord(_ chord: Chord, forMeasureIndex index: Int) {
        project.sections[0].measures[index].selectedChord = chord
        // 必要に応じてAudioServiceのシーケンスを更新
    }
    
    // MARK: - 内部処理
    private func bindAudioPosition() {
        audioService.currentPositionPublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] position in
                self?.currentMeasureIndex = position.measureIndex
                self?.currentBeat = position.beat
                self?.updateCandidatesForCurrentMeasure()
            }
            .store(in: &cancellables)
    }
    
    private func updateCandidatesForCurrentMeasure() {
        let measure = project.sections[0].measures[currentMeasureIndex]
        self.currentCandidates = theoryService.calculateCandidates(key: project.key, baseDegree: measure.baseDegree)
    }
}
```

---

## 5. エラーハンドリングとロギング
- **AVAudioEngine初期化エラー**: 音源ファイル(SF2)が見つからない、またはフォーマットエラーの場合はUIに致命的なエラーダイアログを表示し、フェイルセーフモード(無音だがUIは動く)へ移行するか、強制停止する。
- **エラー通知**: `try-catch` で捕捉したエラーは、サイレントにせず必ず `Logger` (OSLog等) に出力し、必要に応じてViewModel層の `@Published var errorMessage: String?` を更新してUIにフィードバックすること。
