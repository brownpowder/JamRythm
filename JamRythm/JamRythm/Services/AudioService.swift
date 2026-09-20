//
//  AudioService.swift
//  JamRythm
//
//  Created by KanayTakum on 2026/09/08.
//

import AVFoundation
import Combine
import Foundation
import os.log

// MARK: - 再生位置データ構造

/*
再生モード（セクション単体集中ループ or 楽曲全体通し再生）を表す列挙型。
*/
enum PlaybackMode: String, Codable, CaseIterable, Identifiable {
    case sectionLoop = "セクションループ"
    case entireSong = "曲全体通し"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .sectionLoop:
            return "repeat.1"
        case .entireSong:
            return "repeat"
        }
    }
}

/*
現在の再生進行位置（セクションインデックス、小節インデックス、拍数）を表す構造体。
*/
struct PlaybackPosition: Equatable {
    let sectionIndex: Int
    let measureIndex: Int
    let beat: Int

    init(sectionIndex: Int = 0, measureIndex: Int, beat: Int) {
        self.sectionIndex = sectionIndex
        self.measureIndex = measureIndex
        self.beat = beat
    }
}


// MARK: - プレイヤー文脈データ

/*
セクションや小節の進行状況を各Playerに伝えるためのコンテキスト。
*/
struct PlayerContext {
    let sectionType: SectionType
    let measureIndex: Int
    let totalMeasures: Int
    let isFirstMeasure: Bool
    let isLastMeasure: Bool
    let songLoopCount: Int
    
    var phraseIndex: Int {
        return measureIndex / 4
    }
    
    var isFillTiming: Bool {
        return isLastMeasure || (measureIndex > 0 && (measureIndex + 1) % 4 == 0)
    }
}

// MARK: - オーディオサービス・プロトコル

/*
ドラム＆ベースのリズム隊再生および再生クロック制御を司るインターフェース。
*/
protocol AudioServiceProtocol: AnyObject {
    func setupEngine() throws
    func prepare(project: Project) throws
    func updateProject(_ project: Project)
    func play()
    func pause()
    func stop()
    var bpm: Double { get }
    func setBPM(_ bpm: Double)
    var currentPositionPublisher: AnyPublisher<PlaybackPosition, Never> { get }
    var syncOffsetMs: Double { get set }
    var playbackMode: PlaybackMode { get }
    func setPlaybackMode(_ mode: PlaybackMode)
    func setActiveSectionIndex(_ index: Int)

    /*
    再生位置（セクションおよび小節）を指定位置へセットする。

    Arguments:
    sectionIndex
      対象セクションのインデックス。
    measureIndex
      対象小節のインデックス。

    Usage:
    選択セクション・小節からの再生開始時や位置更新時に呼び出される。
    */

    func setPlaybackPosition(sectionIndex: Int, measureIndex: Int)

    /*
    Bass音源のプログラム番号（0〜6）を変更する。
    
    Arguments:
    program
      Bank 000内のプログラム番号（0〜6）。
    
    Usage:
    音色選択時や初期設定時に呼び出される。
    */
    
    func setBassProgram(_ program: UInt8)

    /*
    Drum音源のプログラム番号（0〜2）を変更する。
    
    Arguments:
    program
      Bank 128内のプログラム番号（0〜2）。
    
    Usage:
    ドラム音色選択時や初期設定時に呼び出される。
    */
    
    func setDrumProgram(_ program: UInt8)

    var bassProgram: UInt8 { get }
    var drumProgram: UInt8 { get }
    var pianoProgram: UInt8 { get }
    var selectedDrumPlayer: DrumPlayer { get set }
    var selectedBassPlayer: BassPlayer { get set }
    var selectedPianoPlayer: PianoPlayer { get set }
    func setPianoProgram(_ program: UInt8)

    /*
    マスター出力音量（0.0〜1.0）を設定する。
    
    Arguments:
    volume
      音量値（0.0: 無音 〜 1.0: 最大）。
    
    Usage:
    UIのボリュームスライダー操作時に呼び出される。
    */
    
    func setVolume(_ volume: Float)
    var volume: Float { get }

    /*
    ドラムトラックの個別音量（0.0〜1.0）を設定する。

    Arguments:
    volume
      音量値（0.0: ミュート 〜 1.0: 最大）。

    Usage:
    ミキサーのドラム音量操作時に呼び出される。
    */

    func setDrumVolume(_ volume: Float)
    var drumVolume: Float { get }

    /*
    ベーストラックの個別音量（0.0〜1.0）を設定する。

    Arguments:
    volume
      音量値（0.0: ミュート 〜 1.0: 最大）。

    Usage:
    ミキサーのベース音量操作時に呼び出される。
    */

    func setBassVolume(_ volume: Float)
    var bassVolume: Float { get }

    /*
    ピアノトラックの個別音量（0.0〜1.0）を設定する。

    Arguments:
    volume
      音量値（0.0: ミュート 〜 1.0: 最大）。

    Usage:
    ミキサーのピアノ音量操作時に呼び出される。
    */

    func setPianoVolume(_ volume: Float)
    var pianoVolume: Float { get }

    var drumIsMuted: Bool { get }
    var bassIsMuted: Bool { get }
    var pianoIsMuted: Bool { get }

    var drumIsSolo: Bool { get }
    var bassIsSolo: Bool { get }
    var pianoIsSolo: Bool { get }

    func setDrumMuted(_ isMuted: Bool)
    func setBassMuted(_ isMuted: Bool)
    func setPianoMuted(_ isMuted: Bool)

    func setDrumSolo(_ isSolo: Bool)
    func setBassSolo(_ isSolo: Bool)
    func setPianoSolo(_ isSolo: Bool)

    /*
    現在の伴奏ジャンル（ドラム＆ベースパターンを決定）を取得する。
    */
    var genre: MusicGenre { get }

    /*
    伴奏ジャンルを変更し、再生中のドラム・ベースパターンを即時切り替える。

    Arguments:
    genre
      新しい音楽ジャンル（Pop, Rock, Dance, Lo-Fi, R&B）。

    Usage:
    ヘッダーのジャンル選択メニュー操作時に呼び出される。
    */
    func setGenre(_ genre: MusicGenre)

    /*
    指定されたMIDIノート配列をコード（和音）としてピアノ音源（piano1: 007）でプレビュー再生する。

    Arguments:
    notes
      同時に発音するMIDIノート番号（UInt8）の配列。

    Usage:
    ユーザーがコードカードや候補をタップした際の試聴再生で使用される。
    */

    func playChordNotes(_ notes: [UInt8])

    func setLeadInstrument(_ instrument: LeadInstrument)
    var leadVolume: Float { get }
    func setLeadVolume(_ volume: Float)
    var leadIsMuted: Bool { get }
    func setLeadMuted(_ isMuted: Bool)
    var leadIsSolo: Bool { get }
    func setLeadSolo(_ isSolo: Bool)
    func playPreviewNote(_ midiNote: UInt8, instrument: ScaleInstrument)
}

// MARK: - オーディオサービス・実装クラス

/*
AVAudioEngineを用いてドラム＆ベースのシーケンスを管理・再生する具象クラス。
SF2音源が存在しない環境でも、タイマークロックにより小節・拍情報を配信するフェイルセーフ機構を持つ。
*/
final class AudioService: AudioServiceProtocol {

    private let logger = Logger(subsystem: "com.budou-design.JamRythm", category: "AudioService")

    // MARK: - オーディオエンジン構成要素
    private let audioEngine = AVAudioEngine()
    private let drumSampler = AVAudioUnitSampler()
    private let bassSampler = AVAudioUnitSampler()
    private let pianoSampler = AVAudioUnitSampler()
    private let drumMixer = AVAudioMixerNode()
    private let bassMixer = AVAudioMixerNode()
    private let pianoMixer = AVAudioMixerNode()
    private let rhythmMixer = AVAudioMixerNode()
    private let equalizer = AVAudioUnitEQ(numberOfBands: 2)

    // MARK: - 再生ステート & 音色プログラム
    private var project: Project?
    private(set) var bpm: Double = 120.0
    private var timer: Timer?

    private let drumEngines: [DrumPlayer: DrumPlayerEngine] = [
        .rhythmMachine: RhythmMachineDrummer(),
        .standard: StandardDrummer(),
        .mark: MarkDrummer(),
        .leo: LeoDrummer(),
        .sara: SaraDrummer(),
        .chad: ChadDrummer()
    ]
    private let bassEngines: [BassPlayer: BassPlayerEngine] = [
        .rhythmMachine: RhythmMachineBassist(),
        .standard: StandardBassist(),
        .kr: KRBassist(),
        .akiko: AkikoBassist(),
        .marcus: MarcusBassist(),
        .haruto: HarutoBassist()
    ]
    private let pianoEngines: [PianoPlayer: PianoPlayerEngine] = [
        .rhythmMachine: RhythmMachinePianist(),
        .standard: StandardPianist(),
        .emi: EmiPianist(),
        .jazzCat: JazzCatPianist(),
        .ray: RayPianist(),
        .clara: ClaraPianist()
    ]
    private var currentSectionIndex: Int = 0
    private var currentMeasure: Int = 0
    private var currentStepIndex: Int = 0
    private var currentBeatIndex: Int = 1
    private let stepsPerMeasure: Int = 8
    private let beatsPerMeasure: Int = 4

    private let theoryService: MusicTheoryServiceProtocol = MusicTheoryService()

    private(set) var playbackMode: PlaybackMode = .entireSong
    private(set) var bassProgram: UInt8 = BassInstrument.dub.rawValue
    private(set) var drumProgram: UInt8 = 0
    private(set) var volume: Float = 0.8
    private(set) var drumVolume: Float = 0.8
    private(set) var bassVolume: Float = 0.8
    private(set) var pianoVolume: Float = 0.8
    private(set) var drumIsMuted: Bool = false
    private(set) var bassIsMuted: Bool = false
    private(set) var pianoIsMuted: Bool = false
    private(set) var drumIsSolo: Bool = false
    private(set) var bassIsSolo: Bool = false
    private(set) var pianoIsSolo: Bool = false

    private let leadSampler = AVAudioUnitSampler()
    private let leadMixer = AVAudioMixerNode()
    private(set) var leadProgram: UInt8 = 25
    private(set) var leadVolume: Float = 0.8
    private(set) var leadIsMuted: Bool = false
    private(set) var leadIsSolo: Bool = false

    private(set) var genre: MusicGenre = .pop

    private var activeBassNote: UInt8?
    private var activePianoNotes: [UInt8] = []
    private var activePlaybackPianoNotes: [UInt8] = []
    private var pianoReleaseTask: Task<Void, Never>?

    // MARK: - Combine Publisher
    private let positionSubject = CurrentValueSubject<PlaybackPosition, Never>(PlaybackPosition(sectionIndex: 0, measureIndex: 0, beat: 1))
    var currentPositionPublisher: AnyPublisher<PlaybackPosition, Never> {
        positionSubject.eraseToAnyPublisher()
    }

    var syncOffsetMs: Double = 0.0

    init() {
        configureAudioNodes()
    }

    deinit {
        stop()
    }

    // MARK: - 初期設定

    /*
    AVAudioEngineのノード接続およびEQ（スマホスピーカー向け倍音・中域強調）の初期設定を行う。
    ドラムとベースをそれぞれ独立したミキサー（drumMixer, bassMixer）経由でrhythmMixerにまとめ、
    EQおよびメインミキサーへ送出する。ピアノ音源（pianoSampler）は直接メインミキサーへ接続する。
    
    Arguments:
    なし
    
    Usage:
    初期化時に呼び出され、ドラム・ベース・ピアノの個別音量制御と輪郭強調を行う。
    */
    
    private func configureAudioNodes() {
        audioEngine.attach(drumSampler)
        audioEngine.attach(bassSampler)
        audioEngine.attach(pianoSampler)
        audioEngine.attach(leadSampler)
        audioEngine.attach(drumMixer)
        audioEngine.attach(bassMixer)
        audioEngine.attach(pianoMixer)
        audioEngine.attach(leadMixer)
        audioEngine.attach(rhythmMixer)
        audioEngine.attach(equalizer)

        // スマホスピーカー向けにベース倍音（800Hz付近）をブースト
        let midHarmonicsBand = equalizer.bands[0]
        midHarmonicsBand.filterType = .parametric
        midHarmonicsBand.frequency = 800.0
        midHarmonicsBand.bandwidth = 1.0
        midHarmonicsBand.gain = 4.0
        midHarmonicsBand.bypass = false

        // 高域の抜けを確保
        let highBand = equalizer.bands[1]
        highBand.filterType = .highShelf
        highBand.frequency = 5000.0
        highBand.gain = 2.0
        highBand.bypass = false

        let mainMixer = audioEngine.mainMixerNode
        mainMixer.outputVolume = volume
        updateEffectiveVolumes()

        audioEngine.connect(drumSampler, to: drumMixer, format: nil)
        audioEngine.connect(bassSampler, to: bassMixer, format: nil)
        audioEngine.connect(pianoSampler, to: pianoMixer, format: nil)
        audioEngine.connect(leadSampler, to: leadMixer, format: nil)
        audioEngine.connect(drumMixer, to: rhythmMixer, format: nil)
        audioEngine.connect(bassMixer, to: rhythmMixer, format: nil)
        audioEngine.connect(pianoMixer, to: mainMixer, format: nil)
        audioEngine.connect(leadMixer, to: mainMixer, format: nil)
        audioEngine.connect(rhythmMixer, to: equalizer, format: nil)
        audioEngine.connect(equalizer, to: mainMixer, format: nil)
    }

    /*
    オーディオエンジンの起動およびSF2音源のロードを試行する。
    
    Arguments:
    なし
    
    Usage:
    ViewModelまたはApp起動時に初期化シーケンスとして実行される。
    */
    
    func setupEngine() throws {
        loadSoundFontIfAvailable()

        do {
            if !audioEngine.isRunning {
                try audioEngine.start()
                logger.info("AVAudioEngine successfully started.")
            }
        } catch {
            logger.error("Failed to start AVAudioEngine: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - 音色・SF2ロード処理

    private var soundFontURL: URL? {
        Bundle.main.url(forResource: "JamRythm", withExtension: "sf2")
            ?? Bundle.main.url(forResource: "JamRythmInstruments", withExtension: "sf2")
    }

    /*
    アプリバンドル内のJamRythm.sf2からベースとドラムの音色をロードする。
    
    Arguments:
    なし
    
    Usage:
    エンジンセットアップ時および音色切り替え時に呼び出される。
    */
    
    private func loadSoundFontIfAvailable() {
        guard let sf2Url = soundFontURL else {
            logger.notice("JamRythm.sf2 not found in bundle. Running in fallback mode.")
            return
        }
        loadBassInstrument(sf2Url: sf2Url)
        loadDrumInstrument(sf2Url: sf2Url)
        loadPianoInstrument(sf2Url: sf2Url)
            loadLeadInstrument(sf2Url: sf2Url)
    }

    /*
    Piano音源（Bank 000, Program 007 piano1）をサンプラーへロードする。

    Arguments:
    sf2Url
      SoundFontファイルのURL。

    Usage:
    loadSoundFontIfAvailableから呼び出される。
    */


    private func loadLeadInstrument(sf2Url: URL) {
        do {
            try leadSampler.loadSoundBankInstrument(
                at: sf2Url,
                program: leadProgram,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: 0
            )
        } catch {}
    }

    private(set) var pianoProgram: UInt8 = 0
    var selectedDrumPlayer: DrumPlayer = .rhythmMachine
    var selectedBassPlayer: BassPlayer = .rhythmMachine
    var selectedPianoPlayer: PianoPlayer = .rhythmMachine

    func setPianoProgram(_ program: UInt8) {
        self.pianoProgram = min(127, program)
        if let sf2Url = soundFontURL {
            loadPianoInstrument(sf2Url: sf2Url)
        }
    }

    private func loadPianoInstrument(sf2Url: URL) {
        do {
            try pianoSampler.loadSoundBankInstrument(
                at: sf2Url,
                program: pianoProgram,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: 0
            )
            logger.info("Successfully loaded Piano: Program 007 (piano1)")
        } catch {
            logger.error("Failed to load Piano instrument: \(error.localizedDescription)")
        }
    }

    /*
    Bass音源（Bank 000, Program 000〜006）をサンプラーへロードする。
    
    Arguments:
    sf2Url
      SoundFontファイルのURL。
    
    Usage:
    loadSoundFontIfAvailableおよびsetBassProgramから呼び出される。
    */
    
    private func loadBassInstrument(sf2Url: URL) {
        do {
            try bassSampler.loadSoundBankInstrument(
                at: sf2Url,
                program: bassProgram,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: 0
            )
            logger.info("Successfully loaded Bass: Program \(self.bassProgram)")
        } catch {
            logger.error("Failed to load Bass instrument: \(error.localizedDescription)")
        }
    }

    /*
    Drum音源（Bank 128, Program 000〜002）をサンプラーへロードする。
    CoreAudioのAUSampler仕様に基づき、Bank 128パーカッションバンクは
    kAUSampler_DefaultPercussionBankMSB (0x78 = 120) を指定する。
    
    Arguments:
    sf2Url
      SoundFontファイルのURL。
    
    Usage:
    loadSoundFontIfAvailableおよびsetDrumProgramから呼び出される。
    */
    
    private func loadDrumInstrument(sf2Url: URL) {
        do {
            try drumSampler.loadSoundBankInstrument(
                at: sf2Url,
                program: drumProgram,
                bankMSB: UInt8(kAUSampler_DefaultPercussionBankMSB),
                bankLSB: 0
            )
            logger.info("Successfully loaded Drum: Program \(self.drumProgram)")
        } catch {
            logger.error("Failed to load Drum instrument: \(error.localizedDescription)")
        }
    }

    /*
    Bassプログラム番号（0〜6）を設定して再ロードする。
    
    Arguments:
    program
      設定するプログラム番号。
    
    Usage:
    音色変更時に呼び出される。
    */
    
    func setBassProgram(_ program: UInt8) {
        self.bassProgram = program
        if let sf2Url = soundFontURL {
            loadBassInstrument(sf2Url: sf2Url)
        }
    }

    /*
    Drumプログラム番号（0〜2）を設定して再ロードする。
    
    Arguments:
    program
      設定するプログラム番号。
    
    Usage:
    音色変更時に呼び出される。
    */
    
    func setDrumProgram(_ program: UInt8) {
        self.drumProgram = program
        if let sf2Url = soundFontURL {
            loadDrumInstrument(sf2Url: sf2Url)
        }
    }

    /*
    マスター出力音量（0.0〜1.0）を設定する。
    
    Arguments:
    volume
      音量値（0.0: 無音 〜 1.0: 最大）。
      UIのボリュームスライダーから渡される。
    
    Usage:
    audioEngineのmainMixerNodeの音量を動的に更新する。
    */
    
    func setVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        self.volume = clamped
        audioEngine.mainMixerNode.outputVolume = clamped
        logger.debug("Master volume set to: \(clamped)")
    }

    /*
    ドラムトラックの個別音量（0.0〜1.0）を設定する。

    Arguments:
    volume
      音量値（0.0: ミュート 〜 1.0: 最大）。
      UIのミキサーフェーダーから渡される。

    Usage:
    drumMixerのoutputVolumeを動的に更新する。
    */

    func setDrumVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        self.drumVolume = clamped
        updateEffectiveVolumes()
        logger.debug("Drum volume set to: \(clamped)")
    }

    /*
    ベーストラックの個別音量（0.0〜1.0）を設定する。

    Arguments:
    volume
      音量値（0.0: ミュート 〜 1.0: 最大）。
      UIのミキサーフェーダーから渡される。

    Usage:
    bassMixerのoutputVolumeを動的に更新する。
    */

    func setBassVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        self.bassVolume = clamped
        updateEffectiveVolumes()
        logger.debug("Bass volume set to: \(clamped)")
    }

    /*
    ピアノトラックの個別音量（0.0〜1.0）を設定する。

    Arguments:
    volume
      音量値（0.0: ミュート 〜 1.0: 最大）。
      UIのミキサーフェーダーから渡される。

    Usage:
    pianoMixerのoutputVolumeを動的に更新する。
    */

    func setPianoVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        self.pianoVolume = clamped
        updateEffectiveVolumes()
        logger.debug("Piano volume set to: \(clamped)")
    }

    /*
    MuteおよびSolo状態に基づき、ドラム・ベース・ピアノ各ミキサーノードの実効出力音量を更新する。

    Arguments:
    なし

    Usage:
    音量フェーダー変更時やMute/Solo切り替え時に内部から呼び出される。
    */

    private func updateEffectiveVolumes() {
        let hasAnySolo = drumIsSolo || bassIsSolo || pianoIsSolo || leadIsSolo

        let drumAudible = hasAnySolo ? (drumIsSolo && !drumIsMuted) : !drumIsMuted
        let bassAudible = hasAnySolo ? (bassIsSolo && !bassIsMuted) : !bassIsMuted
        let pianoAudible = hasAnySolo ? (pianoIsSolo && !pianoIsMuted) : !pianoIsMuted
        let leadAudible = hasAnySolo ? (leadIsSolo && !leadIsMuted) : !leadIsMuted

        let effDrumVol = drumAudible ? drumVolume : 0.0
        let effBassVol = bassAudible ? bassVolume : 0.0
        let effPianoVol = pianoAudible ? pianoVolume : 0.0
        let effLeadVol = leadAudible ? leadVolume : 0.0

        drumMixer.outputVolume = effDrumVol
        bassMixer.outputVolume = effBassVol
        pianoMixer.outputVolume = effPianoVol
        leadMixer.outputVolume = effLeadVol

        // サンプラーノード自体のボリュームも直接同期
        drumSampler.volume = effDrumVol
        bassSampler.volume = effBassVol
        pianoSampler.volume = effPianoVol
        leadSampler.volume = effLeadVol

        // MIDI CC 7 (Volume) も送信してSoundFont音源内部ゲインを確実に反映
        let drumMidiVol = UInt8(max(0, min(127, Int(effDrumVol * 127))))
        let bassMidiVol = UInt8(max(0, min(127, Int(effBassVol * 127))))
        let pianoMidiVol = UInt8(max(0, min(127, Int(effPianoVol * 127))))
        let leadMidiVol = UInt8(max(0, min(127, Int(effLeadVol * 127))))

        drumSampler.sendController(7, withValue: drumMidiVol, onChannel: 0)
        bassSampler.sendController(7, withValue: bassMidiVol, onChannel: 0)
        pianoSampler.sendController(7, withValue: pianoMidiVol, onChannel: 0)
        leadSampler.sendController(7, withValue: leadMidiVol, onChannel: 0)

        // ピアノが非可聴または音量ゼロの場合、発音中のピアノ音を即時消音
        if effPianoVol < 0.01 {
            stopActivePlaybackPianoNotes()
            for note in activePianoNotes {
                pianoSampler.stopNote(note, onChannel: 0)
                leadSampler.stopNote(note, onChannel: 0)
            }
            activePianoNotes.removeAll()
            pianoReleaseTask?.cancel()
        }
    }

    func setDrumMuted(_ isMuted: Bool) {
        self.drumIsMuted = isMuted
        updateEffectiveVolumes()
        logger.debug("Drum mute set to: \(isMuted)")
    }

    func setBassMuted(_ isMuted: Bool) {
        self.bassIsMuted = isMuted
        updateEffectiveVolumes()
        logger.debug("Bass mute set to: \(isMuted)")
    }

    func setPianoMuted(_ isMuted: Bool) {
        self.pianoIsMuted = isMuted
        updateEffectiveVolumes()
        logger.debug("Piano mute set to: \(isMuted)")
    }

    func setDrumSolo(_ isSolo: Bool) {
        self.drumIsSolo = isSolo
        updateEffectiveVolumes()
        logger.debug("Drum solo set to: \(isSolo)")
    }

    func setBassSolo(_ isSolo: Bool) {
        self.bassIsSolo = isSolo
        updateEffectiveVolumes()
        logger.debug("Bass solo set to: \(isSolo)")
    }

    func setPianoSolo(_ isSolo: Bool) {
        self.pianoIsSolo = isSolo
        updateEffectiveVolumes()
        logger.debug("Piano solo set to: \(isSolo)")
    }

    /*
    再生モード（セクションループ or 全曲通し）を切り替える。
    
    Arguments:
    mode
      新しいPlaybackMode（.sectionLoop または .entireSong）。
    
    Usage:
    UIのループモード切り替えボタンから呼び出される。
    */
    
    func setPlaybackMode(_ mode: PlaybackMode) {
        self.playbackMode = mode
        logger.info("Playback mode changed to: \(mode.rawValue)")
    }

    /*
    再生および編集対象のアクティブセクションインデックスを変更し、小節の先頭に頭出しする。
    
    Arguments:
    index
      対象のセクションインデックス。
    
    Usage:
    ユーザーがセクションタブを選択した際に呼び出される。
    */
    
    func setActiveSectionIndex(_ index: Int) {
        setPlaybackPosition(sectionIndex: index, measureIndex: 0)
    }

    /*
    再生位置（セクションおよび小節）を指定位置へセットする。

    Arguments:
    sectionIndex
      対象セクションのインデックス。
    measureIndex
      対象小節のインデックス。

    Usage:
    選択セクション・小節からの再生開始時や位置更新時に呼び出される。
    */

    func setPlaybackPosition(sectionIndex: Int, measureIndex: Int) {
        guard let sections = project?.sections, !sections.isEmpty else { return }
        let validSection = max(0, min(sectionIndex, sections.count - 1))
        let measures = sections[validSection].measures
        let validMeasure = max(0, min(measureIndex, max(0, measures.count - 1)))

        self.currentSectionIndex = validSection
        self.currentMeasure = validMeasure
        self.currentStepIndex = 0
        self.currentBeatIndex = 1
        positionSubject.send(PlaybackPosition(sectionIndex: validSection, measureIndex: validMeasure, beat: 1))
        logger.info("Playback position set to section: \(validSection), measure: \(validMeasure)")
    }

    // MARK: - 再生制御

    /*
    プロジェクトデータを準備し、BPMを設定する。
    
    Arguments:
    project
      再生対象となるProjectオブジェクト。ViewModelから渡される。
    
    Usage:
    曲のロード時やKey/構成変更時に呼び出される。
    */
    
    func prepare(project: Project) throws {
        self.project = project
        self.bpm = project.bpm
        self.genre = project.genre
        resetPosition()
    }

    /*
    再生位置（currentMeasure等）をリセットすることなく、最新のプロジェクトデータ（選択コードやジャンル等）を反映する。

    Arguments:
    project
      最新のProjectデータ。

    Usage:
    ユーザーがコードを変更した際や進行・ジャンルを編集した際に呼び出される。
    */

    func updateProject(_ project: Project) {
        self.project = project
        self.bpm = project.bpm
        self.genre = project.genre
    }

    /*
    伴奏ジャンルを変更し、再生中のドラム・ベースパターンを即時切り替える。

    Arguments:
    genre
      新しい音楽ジャンル（Pop, Rock, Dance, Lo-Fi, R&B）。

    Usage:
    UIのジャンル選択メニュー操作時に呼び出される。
    */

    func setGenre(_ genre: MusicGenre) {
        self.genre = genre
        logger.info("Genre changed to: \(genre.rawValue)")
    }

    /*
    BPMを動的に変更し、再生中であればタイマー間隔を更新する。
    
    Arguments:
    bpm
      新しいテンポ値（40〜240想定）。UIのスライダー等から渡される。
    
    Usage:
    曲の再生中または停止中にBPMを変更する際に使用される。
    */
    
    func setBPM(_ bpm: Double) {
        guard bpm > 0 else { return }
        self.bpm = bpm
        if timer != nil {
            startTimer()
        }
    }

    /*
    リズム隊およびクロックの再生を開始する。
    
    Arguments:
    なし
    
    Usage:
    UIの再生ボタン押下時に呼び出される。
    */
    
    func play() {
        if !audioEngine.isRunning {
            try? audioEngine.start()
        }
        playSoundsForCurrentStep()
        startTimer()
        logger.info("Playback started at BPM: \(self.bpm)")
    }

    /*
    再生を一時停止し、持続中の発音を止める。
    
    Arguments:
    なし
    
    Usage:
    UIの一時停止ボタン押下時に呼び出される。
    */
    
    func pause() {
        stopTimer()
        stopAllNotes()
        logger.info("Playback paused at measure: \(self.currentMeasure), beat: \(self.currentBeatIndex)")
    }

    /*
    再生を停止し、位置を先頭（1小節目1拍目）へ巻き戻す。
    
    Arguments:
    なし
    
    Usage:
    停止ボタン押下時や曲切り替え時に呼び出される。
    */
    
    func stop() {
        stopTimer()
        stopAllNotes()
        resetPosition()
        logger.info("Playback stopped and reset to start.")
    }

    // MARK: - タイマー & 再生位置制御

    /*
    BPMに基づき8分音符ごとのタイマーを開始する（1拍の半分の間隔）。
    
    Arguments:
    なし
    
    Usage:
    play()またはsetBPM()でテンポ更新時に内部で実行される。
    */
    
    private func startTimer() {
        stopTimer()
        let interval = (60.0 / bpm) / 2.0
        let t = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            self?.advanceStep()
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    /*
    動作中のタイマーを破棄する。
    
    Arguments:
    なし
    
    Usage:
    pause(), stop(), deinit時に内部で使用される。
    */
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    /*
    8分音符を1ステップ進め、小節の終端に達した場合は小節インデックスを進め、音声を再生する。
    
    Arguments:
    なし
    
    Usage:
    タイマーの各tickで呼び出され、拍頭（表拍）でPlaybackPositionを発行する。
    */
    
    private func advanceStep() {
        guard let sections = project?.sections, !sections.isEmpty else { return }
        let validSectionIndex = min(currentSectionIndex, sections.count - 1)
        let currentSectionMeasures = sections[validSectionIndex].measures
        let totalMeasures = max(1, currentSectionMeasures.count)

        if currentStepIndex < stepsPerMeasure - 1 {
            currentStepIndex += 1
        } else {
            currentStepIndex = 0
            switch playbackMode {
            case .sectionLoop:
                currentMeasure = (currentMeasure + 1) % totalMeasures
            case .entireSong:
                if currentMeasure + 1 < totalMeasures {
                    currentMeasure += 1
                } else {
                    currentMeasure = 0
                    currentSectionIndex = (validSectionIndex + 1) % sections.count
                }
            }
        }

        currentBeatIndex = (currentStepIndex / 2) + 1

        playSoundsForCurrentStep()

        // 拍頭（表拍: step 0, 2, 4, 6）のときのみUIへ位置通知を送信
        if currentStepIndex % 2 == 0 {
            let newPosition = PlaybackPosition(
                sectionIndex: currentSectionIndex,
                measureIndex: currentMeasure,
                beat: currentBeatIndex
            )
            positionSubject.send(newPosition)
        }
    }

    /*
    再生位置を現在セクションの1小節目1拍目（step 0）に初期化する。
    
    Arguments:
    なし
    
    Usage:
    stop()や曲初期化時に内部で実行される。
    */
    
    private func resetPosition() {
        currentMeasure = 0
        currentStepIndex = 0
        currentBeatIndex = 1
        positionSubject.send(PlaybackPosition(sectionIndex: currentSectionIndex, measureIndex: 0, beat: 1))
    }

    // MARK: - MIDIノート発音処理

    /*
    現在ステップに応じたドラムとベースのノートを発音する。
    
    Arguments:
    なし
    
    Usage:
    advanceStepおよびplay()頭出し時に呼び出される。
    */
    
    private func playSoundsForCurrentStep() {
        playDrumStep(step: currentStepIndex)
        playBassStep(measureIndex: currentMeasure, step: currentStepIndex)
        playPianoStep(measureIndex: currentMeasure, step: currentStepIndex)
    }

    /*
    指定ステップ（8分音符単位: 0〜7）に対応するドラムサウンドをジャンル別パターンで発音する。
    
    Arguments:
    step
      現在の8分音符ステップ（0〜7）。
      タイマー進行時にadvanceStepまたはplay()から渡される。
    
    Usage:
    playSoundsForCurrentStepから呼び出され、選択中ジャンル固有のリズムを発音する。
    */
    
    private func playDrumStep(step: Int) {
        guard let proj = project, currentSectionIndex < proj.sections.count else { return }
        let measures = proj.sections[currentSectionIndex].measures
        let measureCount = measures.isEmpty ? 1 : measures.count
        
        let engine = drumEngines[selectedDrumPlayer] ?? RhythmMachineDrummer()
        let context = PlayerContext(
            sectionType: proj.sections[currentSectionIndex].type,
            measureIndex: currentMeasure,
            totalMeasures: measureCount,
            isFirstMeasure: currentMeasure == 0,
            isLastMeasure: currentMeasure == measureCount - 1,
            songLoopCount: 0
        )
        
        let events = engine.evaluate(step: step, context: context, genre: genre)
        let offset = selectedDrumPlayer.timingOffsetMs / 1000.0
        
        for event in events {
            if offset > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + offset) {
                    self.drumSampler.startNote(event.note, withVelocity: event.velocity, onChannel: 0)
                }
            } else {
                self.drumSampler.startNote(event.note, withVelocity: event.velocity, onChannel: 0)
            }
        }
    }
    private func playPopDrum(step: Int) {
        let hiHatVelocity: UInt8 = (step % 2 == 0) ? 90 : 65
        drumSampler.startNote(42, withVelocity: hiHatVelocity, onChannel: 0)

        switch step {
        case 0:
            drumSampler.startNote(36, withVelocity: 110, onChannel: 0)
        case 2:
            drumSampler.startNote(38, withVelocity: 105, onChannel: 0)
        case 4:
            drumSampler.startNote(36, withVelocity: 100, onChannel: 0)
        case 5:
            drumSampler.startNote(36, withVelocity: 85, onChannel: 0)
        case 6:
            drumSampler.startNote(38, withVelocity: 105, onChannel: 0)
        default:
            break
        }
    }

    private func playRockDrum(step: Int) {
        let hiHatVelocity: UInt8 = (step % 2 == 0) ? 105 : 85
        drumSampler.startNote(42, withVelocity: hiHatVelocity, onChannel: 0)

        switch step {
        case 0:
            drumSampler.startNote(36, withVelocity: 115, onChannel: 0)
        case 2:
            drumSampler.startNote(38, withVelocity: 115, onChannel: 0)
        case 3:
            drumSampler.startNote(36, withVelocity: 95, onChannel: 0)
        case 4:
            drumSampler.startNote(36, withVelocity: 105, onChannel: 0)
        case 6:
            drumSampler.startNote(38, withVelocity: 115, onChannel: 0)
        default:
            break
        }
    }

    private func playDanceDrum(step: Int) {
        switch step {
        case 0, 4:
            drumSampler.startNote(36, withVelocity: 115, onChannel: 0)
            drumSampler.startNote(42, withVelocity: 60, onChannel: 0)
        case 2, 6:
            drumSampler.startNote(36, withVelocity: 115, onChannel: 0)
            drumSampler.startNote(38, withVelocity: 100, onChannel: 0)
            drumSampler.startNote(42, withVelocity: 60, onChannel: 0)
        case 1, 3, 5, 7:
            drumSampler.startNote(46, withVelocity: 105, onChannel: 0)
        default:
            break
        }
    }

    private func playLoFiDrum(step: Int) {
        // ハットの刻みを半分（4分音符刻み: step 0, 2, 4, 6）にしてレイドバックしたチル感を演出
        if step % 2 == 0 {
            drumSampler.startNote(42, withVelocity: 60, onChannel: 0)
        }

        switch step {
        case 0:
            drumSampler.startNote(36, withVelocity: 95, onChannel: 0)
        case 4:
            drumSampler.startNote(38, withVelocity: 95, onChannel: 0)
        case 5:
            drumSampler.startNote(36, withVelocity: 75, onChannel: 0)
        default:
            break
        }
    }

    private func playRAndBDrum(step: Int) {
        let hiHatVelocities: [UInt8] = [95, 50, 80, 50, 90, 50, 80, 60]
        drumSampler.startNote(42, withVelocity: hiHatVelocities[step % 8], onChannel: 0)

        switch step {
        case 0:
            drumSampler.startNote(36, withVelocity: 110, onChannel: 0)
        case 2:
            drumSampler.startNote(38, withVelocity: 105, onChannel: 0)
        case 3:
            drumSampler.startNote(36, withVelocity: 90, onChannel: 0)
        case 4:
            drumSampler.startNote(36, withVelocity: 95, onChannel: 0)
        case 6:
            drumSampler.startNote(38, withVelocity: 105, onChannel: 0)
        case 7:
            drumSampler.startNote(36, withVelocity: 80, onChannel: 0)
        default:
            break
        }
    }

    /*
    指定小節のベース音MIDIノート番号を取得する。
    
    Arguments:
    measureIndex
      対象小節のインデックス。
    
    Usage:
    playBassStep内の各ジャンル演奏ロジックで使用される。
    */

    private func bassRootNote(for measureIndex: Int) -> UInt8? {
        guard let sections = project?.sections,
              currentSectionIndex < sections.count else { return nil }
        let measures = sections[currentSectionIndex].measures
        guard measureIndex < measures.count else { return nil }

        let chord = measures[measureIndex].activeChord
        let bassNoteName = (chord.bassNote?.isEmpty == false) ? chord.bassNote! : measures[measureIndex].bassNote
        return midiNoteForBass(bassNoteName)
    }

    /*
    アクティブなベース音を停止し、新しいMIDIノートを指定音量で発音する。
    
    Arguments:
    note
      発音するMIDIノート番号。
    velocity
      打鍵の強さ（0〜127）。
    
    Usage:
    playBassStepの各ジャンル演奏処理から呼び出される。
    */

    private func triggerBassNote(_ note: UInt8, velocity: UInt8 = 105) {
        if let active = activeBassNote {
            bassSampler.stopNote(active, onChannel: 0)
        }
        bassSampler.startNote(note, withVelocity: velocity, onChannel: 0)
        activeBassNote = note
    }

    /*
    指定ステップのベース音をジャンル別パターンで発音する。
    
    Arguments:
    measureIndex
      対象小節のインデックス。
    step
      現在の8分音符ステップ（0〜7）。
    
    Usage:
    playSoundsForCurrentStepから呼び出され、ジャンルに応じたベースフレーズを演奏する。
    */
    
    private func playBassStep(measureIndex: Int, step: Int) {
        guard let proj = project, currentSectionIndex < proj.sections.count else { return }
        let measures = proj.sections[currentSectionIndex].measures
        let measureCount = measures.isEmpty ? 1 : measures.count

        let engine = bassEngines[selectedBassPlayer] ?? RhythmMachineBassist()
        let context = PlayerContext(
            sectionType: proj.sections[currentSectionIndex].type,
            measureIndex: currentMeasure,
            totalMeasures: measureCount,
            isFirstMeasure: currentMeasure == 0,
            isLastMeasure: currentMeasure == measureCount - 1,
            songLoopCount: 0
        )
        
        let rootNote = bassRootNote(for: measureIndex)
        let events = engine.evaluate(step: step, rootNote: rootNote, context: context, genre: genre)
        let offset = selectedBassPlayer.timingOffsetMs / 1000.0
        
        for event in events {
            if offset > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + offset) {
                    self.triggerBassNote(event.note, velocity: event.velocity)
                }
            } else {
                self.triggerBassNote(event.note, velocity: event.velocity)
            }
        }
    }
    private func playPianoStep(measureIndex: Int, step: Int) {
        guard let proj = project, currentSectionIndex < proj.sections.count else { return }
        let measures = proj.sections[currentSectionIndex].measures
        guard measureIndex < measures.count else { return }

        let engine = pianoEngines[selectedPianoPlayer] ?? RhythmMachinePianist()
        let context = PlayerContext(
            sectionType: proj.sections[currentSectionIndex].type,
            measureIndex: currentMeasure,
            totalMeasures: measures.count,
            isFirstMeasure: currentMeasure == 0,
            isLastMeasure: currentMeasure == measures.count - 1,
            songLoopCount: 0
        )
        
        let chord = measures[measureIndex].activeChord
        let previousNotes = activePlaybackPianoNotes.isEmpty ? nil : activePlaybackPianoNotes
        let chordNotes = theoryService.voiceLedMidiNotes(for: chord, previousNotes: previousNotes)
        
        let events = engine.evaluate(step: step, chordNotes: chordNotes, context: context, genre: genre)
        let offset = selectedPianoPlayer.timingOffsetMs / 1000.0
        
        if step == 0 { stopActivePlaybackPianoNotes() }
        
        for event in events {
            if offset > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + offset) {
                    self.pianoSampler.startNote(event.note, withVelocity: event.velocity, onChannel: 0)
                    self.activePlaybackPianoNotes.append(event.note)
                }
            } else {
                self.pianoSampler.startNote(event.note, withVelocity: event.velocity, onChannel: 0)
                self.activePlaybackPianoNotes.append(event.note)
            }
        }
    }
    private func stopActivePlaybackPianoNotes() {
        for note in activePlaybackPianoNotes {
            pianoSampler.stopNote(note, onChannel: 0)
                leadSampler.stopNote(note, onChannel: 0)
        }
        activePlaybackPianoNotes.removeAll()
    }

    /*
    発音中のベースノートおよびピアノノートを強制停止する。
    
    Arguments:
    なし
    
    Usage:
    pause, stop, 曲停止時に呼び出される。
    */
    
    private func stopAllNotes() {
        if let active = activeBassNote {
            bassSampler.stopNote(active, onChannel: 0)
            activeBassNote = nil
        }
        stopActivePlaybackPianoNotes()
        pianoReleaseTask?.cancel()
        for note in activePianoNotes {
            pianoSampler.stopNote(note, onChannel: 0)
                leadSampler.stopNote(note, onChannel: 0)
        }
        activePianoNotes.removeAll()
    }

    /*
    指定されたMIDIノート配列をコード（和音）としてピアノ音源（piano1: 007）でプレビュー再生する。

    Arguments:
    notes
      同時に発音するMIDIノート番号（UInt8）の配列。

    Usage:
    ユーザーがコードカードや候補をタップした際の試聴再生で使用される。
    */


    func setLeadInstrument(_ instrument: LeadInstrument) {
        self.leadProgram = instrument.rawValue
        if let sf2Url = soundFontURL { loadLeadInstrument(sf2Url: sf2Url) }
    }
    
    func setLeadVolume(_ volume: Float) {
        let clamped = max(0.0, min(1.0, volume))
        self.leadVolume = clamped
        updateEffectiveVolumes()
    }
    
    func setLeadMuted(_ isMuted: Bool) {
        self.leadIsMuted = isMuted
        updateEffectiveVolumes()
    }
    
    func setLeadSolo(_ isSolo: Bool) {
        self.leadIsSolo = isSolo
        updateEffectiveVolumes()
    }
    
    func playPreviewNote(_ midiNote: UInt8, instrument: ScaleInstrument) {
        if !audioEngine.isRunning { try? audioEngine.start() }
        let sampler = instrument == .piano ? pianoSampler : leadSampler
        sampler.startNote(midiNote, withVelocity: 105, onChannel: 0)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak sampler] in
            sampler?.stopNote(midiNote, onChannel: 0)
        }
    }

    func playChordNotes(_ notes: [UInt8]) {
        pianoReleaseTask?.cancel()
        for note in activePianoNotes {
            pianoSampler.stopNote(note, onChannel: 0)
                leadSampler.stopNote(note, onChannel: 0)
        }
        activePianoNotes = notes

        guard !notes.isEmpty else { return }

        let hasAnySolo = drumIsSolo || bassIsSolo || pianoIsSolo || leadIsSolo
        let pianoAudible = hasAnySolo ? (pianoIsSolo && !pianoIsMuted) : !pianoIsMuted
        let leadAudible = hasAnySolo ? (leadIsSolo && !leadIsMuted) : !leadIsMuted
        guard pianoAudible && pianoVolume > 0.01 else { return }

        if !audioEngine.isRunning {
            try? audioEngine.start()
        }

        let baseVelocity: Float = 90.0
        let velocity = UInt8(max(1, min(127, Int(baseVelocity * pianoVolume))))

        for note in notes {
            pianoSampler.startNote(note, withVelocity: velocity, onChannel: 0)
        }

        let currentNotes = notes
        pianoReleaseTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            guard let self = self, !Task.isCancelled else { return }
            for note in currentNotes {
                self.pianoSampler.stopNote(note, onChannel: 0)
                leadSampler.stopNote(note, onChannel: 0)
            }
            if self.activePianoNotes == currentNotes {
                self.activePianoNotes.removeAll()
            }
        }
    }

    /*
    ベース音名（例: "C", "F", "D♭"）から適切なMIDIノート番号（C2=36基準）を算出する。
    
    Arguments:
    noteName
      音名文字列。
    
    Usage:
    playBassBeatでサンプラーへのMIDIノート番号決定に使用される。
    */
    
    private func midiNoteForBass(_ noteName: String) -> UInt8 {
        let baseMidiC2: UInt8 = 36
        let semitones: [String: UInt8] = [
            "C": 0, "C#": 1, "D♭": 1, "Db": 1,
            "D": 2, "D#": 3, "E♭": 3, "Eb": 3,
            "E": 4, "F": 5, "F#": 6, "G♭": 6, "Gb": 6,
            "G": 7, "G#": 8, "A♭": 8, "Ab": 8,
            "A": 9, "A#": 10, "B♭": 10, "Bb": 10,
            "B": 11
        ]
        let offset = semitones[noteName] ?? 0
        return baseMidiC2 + offset
    }
}
