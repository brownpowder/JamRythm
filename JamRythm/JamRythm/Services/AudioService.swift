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
現在の再生進行位置（小節インデックスと小節内の拍数）を表す構造体。
*/
struct PlaybackPosition: Equatable {
    let measureIndex: Int
    let beat: Int
}

// MARK: - オーディオサービス・プロトコル

/*
ドラム＆ベースのリズム隊再生および再生クロック制御を司るインターフェース。
*/
protocol AudioServiceProtocol: AnyObject {
    func setupEngine() throws
    func prepare(project: Project) throws
    func play()
    func pause()
    func stop()
    func setBPM(_ bpm: Double)
    var currentPositionPublisher: AnyPublisher<PlaybackPosition, Never> { get }
    var syncOffsetMs: Double { get set }

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
    private let drumMixer = AVAudioMixerNode()
    private let bassMixer = AVAudioMixerNode()
    private let rhythmMixer = AVAudioMixerNode()
    private let equalizer = AVAudioUnitEQ(numberOfBands: 2)

    // MARK: - 再生ステート & 音色プログラム
    private var project: Project?
    private var bpm: Double = 120.0
    private var timer: Timer?
    private var currentMeasure: Int = 0
    private var currentStepIndex: Int = 0
    private var currentBeatIndex: Int = 1
    private let stepsPerMeasure: Int = 8
    private let beatsPerMeasure: Int = 4

    private(set) var bassProgram: UInt8 = 0
    private(set) var drumProgram: UInt8 = 0
    private(set) var volume: Float = 0.8
    private(set) var drumVolume: Float = 0.8
    private(set) var bassVolume: Float = 0.8
    private var activeBassNote: UInt8?

    // MARK: - Combine Publisher
    private let positionSubject = CurrentValueSubject<PlaybackPosition, Never>(PlaybackPosition(measureIndex: 0, beat: 1))
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
    EQおよびメインミキサーへ送出する。
    
    Arguments:
    なし
    
    Usage:
    初期化時に呼び出され、ドラム・ベースの個別音量制御と輪郭強調を行う。
    */
    
    private func configureAudioNodes() {
        audioEngine.attach(drumSampler)
        audioEngine.attach(bassSampler)
        audioEngine.attach(drumMixer)
        audioEngine.attach(bassMixer)
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
        drumMixer.outputVolume = drumVolume
        bassMixer.outputVolume = bassVolume

        audioEngine.connect(drumSampler, to: drumMixer, format: nil)
        audioEngine.connect(bassSampler, to: bassMixer, format: nil)
        audioEngine.connect(drumMixer, to: rhythmMixer, format: nil)
        audioEngine.connect(bassMixer, to: rhythmMixer, format: nil)
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
        self.bassProgram = min(6, program)
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
        self.drumProgram = min(2, program)
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
        drumMixer.outputVolume = clamped
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
        bassMixer.outputVolume = clamped
        logger.debug("Bass volume set to: \(clamped)")
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
        resetPosition()
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
        let totalMeasures = project?.sections.first?.measures.count ?? 4

        if currentStepIndex < stepsPerMeasure - 1 {
            currentStepIndex += 1
        } else {
            currentStepIndex = 0
            currentMeasure = (currentMeasure + 1) % max(1, totalMeasures)
        }

        currentBeatIndex = (currentStepIndex / 2) + 1

        playSoundsForCurrentStep()

        // 拍頭（表拍: step 0, 2, 4, 6）のときのみUIへ位置通知を送信
        if currentStepIndex % 2 == 0 {
            let newPosition = PlaybackPosition(measureIndex: currentMeasure, beat: currentBeatIndex)
            positionSubject.send(newPosition)
        }
    }

    /*
    再生位置を1小節目1拍目（step 0）に初期化する。
    
    Arguments:
    なし
    
    Usage:
    stop()や曲初期化時に内部で実行される。
    */
    
    private func resetPosition() {
        currentMeasure = 0
        currentStepIndex = 0
        currentBeatIndex = 1
        positionSubject.send(PlaybackPosition(measureIndex: 0, beat: 1))
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
    }

    /*
    指定ステップ（8分音符単位: 0〜7）に対応する王道8ビートのドラムサウンドを発音する。
    
    Arguments:
    step
      現在の8分音符ステップ（0〜7）。
      タイマー進行時にadvanceStepまたはplay()から渡される。
    
    Usage:
    playSoundsForCurrentStepから呼び出され、全8分音符ハイハット＋2/4拍スネア＋1/3拍キック（3拍裏推進キック付）を発音する。
    */
    
    private func playDrumStep(step: Int) {
        logger.debug("Playing drum step: \(step), program: \(self.drumProgram)")

        // 8分音符ハイハット（表拍は強め、裏拍は軽めでグルーヴを形成）
        let hiHatVelocity: UInt8 = (step % 2 == 0) ? 90 : 65
        drumSampler.startNote(42, withVelocity: hiHatVelocity, onChannel: 0)

        // キックとスネアの王道8ビートパターン
        switch step {
        case 0: // 1拍目: キック
            drumSampler.startNote(36, withVelocity: 110, onChannel: 0)
        case 2: // 2拍目: スネア
            drumSampler.startNote(38, withVelocity: 105, onChannel: 0)
        case 4: // 3拍目: キック
            drumSampler.startNote(36, withVelocity: 100, onChannel: 0)
        case 5: // 3拍裏: 推進力を生む軽めのキック（8ビートの定番フィール）
            drumSampler.startNote(36, withVelocity: 85, onChannel: 0)
        case 6: // 4拍目: スネア
            drumSampler.startNote(38, withVelocity: 105, onChannel: 0)
        default:
            break
        }
    }

    /*
    指定ステップのベース音を発音する（1拍目と3拍目の頭: step 0, 4でトリガー）。
    
    Arguments:
    measureIndex
      対象小節のインデックス。
      projectの小節リストから渡される。
    step
      現在の8分音符ステップ（0〜7）。
      advanceStepから渡される。
    
    Usage:
    playSoundsForCurrentStepから呼び出され、2分音符のベース音を発音する。
    */
    
    private func playBassStep(measureIndex: Int, step: Int) {
        guard let measures = project?.sections.first?.measures,
              measureIndex < measures.count else { return }

        // 1拍目（step 0）と3拍目（step 4）の頭でベース音を鳴らす（2分音符のグルーヴ）
        if step == 0 || step == 4 {
            let bassNoteName = measures[measureIndex].bassNote
            let midiNote = midiNoteForBass(bassNoteName)

            if let active = activeBassNote {
                bassSampler.stopNote(active, onChannel: 0)
            }
            bassSampler.startNote(midiNote, withVelocity: 105, onChannel: 0)
            activeBassNote = midiNote
        }
    }

    /*
    発音中のベースノートを強制停止する。
    
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
