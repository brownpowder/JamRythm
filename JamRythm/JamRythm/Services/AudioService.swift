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
    private let equalizer = AVAudioUnitEQ(numberOfBands: 2)

    // MARK: - 再生ステート
    private var project: Project?
    private var bpm: Double = 120.0
    private var timer: Timer?
    private var currentMeasure: Int = 0
    private var currentBeatIndex: Int = 1
    private let beatsPerMeasure: Int = 4

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
    
    Arguments:
    なし
    
    Usage:
    初期化時に呼び出され、ベースの輪郭と全体の視認性を確保する。
    */
    
    private func configureAudioNodes() {
        audioEngine.attach(drumSampler)
        audioEngine.attach(bassSampler)
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
        audioEngine.connect(drumSampler, to: equalizer, format: nil)
        audioEngine.connect(bassSampler, to: equalizer, format: nil)
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

    /*
    アプリバンドル内にSF2ファイルが存在する場合はサンプラーへロードする。
    
    Arguments:
    なし
    
    Usage:
    実音源が存在すれば読み込み、無ければフェイルセーフ（クロック再生のみ）を維持する。
    */
    
    private func loadSoundFontIfAvailable() {
        if let sf2Url = Bundle.main.url(forResource: "JamRythmInstruments", withExtension: "sf2") {
            do {
                try drumSampler.loadSoundBankInstrument(at: sf2Url, program: 0, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0)
                try bassSampler.loadSoundBankInstrument(at: sf2Url, program: 32, bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB), bankLSB: 0)
                logger.info("SF2 soundfont loaded successfully.")
            } catch {
                logger.warning("SF2 file found but failed to load: \(error.localizedDescription)")
            }
        } else {
            logger.notice("SF2 soundfont not bundled. Running in clock-only fallback mode.")
        }
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
        startTimer()
        logger.info("Playback started at BPM: \(self.bpm)")
    }

    /*
    再生を一時停止する。
    
    Arguments:
    なし
    
    Usage:
    UIの一時停止ボタン押下時に呼び出される。
    */
    
    func pause() {
        stopTimer()
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
        resetPosition()
        logger.info("Playback stopped and reset to start.")
    }

    // MARK: - タイマー & 再生位置制御

    /*
    BPMに基づき1拍ごとのタイマーを開始する。
    
    Arguments:
    なし
    
    Usage:
    play()またはsetBPM()でテンポ更新時に内部で実行される。
    */
    
    private func startTimer() {
        stopTimer()
        let interval = 60.0 / bpm
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.advanceBeat()
        }
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
    1拍進め、小節の終端に達した場合は小節インデックスを進める。
    
    Arguments:
    なし
    
    Usage:
    タイマーの各tickで呼び出され、PlaybackPositionを発行する。
    */
    
    private func advanceBeat() {
        let totalMeasures = project?.sections.first?.measures.count ?? 4

        if currentBeatIndex < beatsPerMeasure {
            currentBeatIndex += 1
        } else {
            currentBeatIndex = 1
            currentMeasure = (currentMeasure + 1) % max(1, totalMeasures)
        }

        let newPosition = PlaybackPosition(measureIndex: currentMeasure, beat: currentBeatIndex)
        positionSubject.send(newPosition)
    }

    /*
    再生位置を1小節目1拍目に初期化する。
    
    Arguments:
    なし
    
    Usage:
    stop()や曲初期化時に内部で実行される。
    */
    
    private func resetPosition() {
        currentMeasure = 0
        currentBeatIndex = 1
        positionSubject.send(PlaybackPosition(measureIndex: 0, beat: 1))
    }
}
