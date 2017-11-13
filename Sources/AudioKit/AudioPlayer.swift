import Foundation
import AVFoundation

public class AudioPlayer: AudioPlaying {
    private let engine: AVAudioEngine
    private let playerNode: AVAudioPlayerNode
    private let mixer: AVAudioMixerNode
    private var audio: AVAudioFile?
    public var elapsedTime: ((String) -> Void)?
    public var totalLength: ((String) -> Void)?
    public var progress: ((_ elapsedTime: Double, _ totalLength: Double) -> Void)?
    public var playerReady: (() -> Void)?
    public var isPlaying: Bool {
        return playerNode.isPlaying
    }

    /*
     A formatter for individual date components used to provide an appropriate
     value for the `startTimeLabel` and `durationLabel`.
     */
    public let timeRemainingFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.zeroFormattingBehavior = .pad
        formatter.allowedUnits = [.minute, .second]

        return formatter
    }()

    init() {
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        mixer = engine.mainMixerNode
    }

    deinit {
        audio = nil
        playerNode.stop()
        engine.inputNode.removeTap(onBus: 0)
        engine.disconnectNodeInput(playerNode)
        engine.detach(playerNode)
        engine.stop()
        cleanUpAudioSession()
    }

    public func configure(url: URL, completion: ((PlayerResult) -> Void)?) {
        DispatchQueue.global().async { [weak self] in
            guard let playerNode = self?.playerNode,
                  let mixer = self?.mixer else { return }
            self?.engine.attach(playerNode)
            self?.engine.connect(playerNode, to: mixer, format: nil)
            self?.engine.inputNode.installTap(onBus: 0,
                                         bufferSize: 1024,
                                         format: mixer.inputFormat(forBus: 0),
                                         block: { [weak self] (_, _) in
                                            if let closure = self?.elapsedTime,
                                                let currentTime = self?.currentTime(),
                                                self?.totalTime() != nil,
                                                let isPlaying = self?.playerNode.isPlaying,
                                                isPlaying {
                                                DispatchQueue.main.async {
                                                    closure(currentTime)
                                                    if let progress = self?.progress {
                                                        //no progress it passed along...
                                                        progress(1, 1)
                                                    }
                                                }
                                            }
            })
            do {
                try self?.engine.start()
                DispatchQueue.main.async {
                    if let f = completion {
                        f(.success)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    if let f = completion {
                        f(.failure)
                    }
                }
            }
        }
    }

    public func play() {
        playerNode.play()
        if let closure = totalLength {
            closure(totalTime())
        }
    }

    public func pause() {
        playerNode.pause()
    }

    public func prepare(audioFilePath path: URL, completion: ((PlayerResult) -> Void)?, stopped: (() -> Void)?) {
        DispatchQueue.global().async { [weak self] in
            self?.playerNode.reset()
            self?.playerNode.stop()
            guard let audio = try? AVAudioFile(forReading: path) else { return }
            self?.audio = audio
            self?.prepareAudioSession()
            self?.playerNode.scheduleFile(audio, at: nil) {
                DispatchQueue.main.async {
                    if let f = stopped {
                        f()
                    }
                }
            }
            self?.playerNode.prepare(withFrameCount: 1)
            DispatchQueue.main.async {
                if let f = completion {
                    f(.success)
                }
            }
        }
    }

    private func totalTime() -> String {
        if let nodeTime: AVAudioTime = playerNode.lastRenderTime,
            let playerTime: AVAudioTime = playerNode.playerTime(forNodeTime: nodeTime),
            let audio = self.audio {
            return createTimeString(time: Float(Double(audio.length) / playerTime.sampleRate))
        }
        return "0:00"
    }

    private func currentTime() -> String {
        if let nodeTime: AVAudioTime = playerNode.lastRenderTime,
            let playerTime: AVAudioTime = playerNode.playerTime(forNodeTime: nodeTime) {
            return createTimeString(time: Float(Double(playerTime.sampleTime) / playerTime.sampleRate))
        }
        return "0:00"
    }

    private func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))

        return timeRemainingFormatter.string(from: components as DateComponents)!
    }

    @discardableResult private func prepareAudioSession() -> Bool {
        let avs = AVAudioSession.sharedInstance()
        do {
            try avs.setCategory(AVAudioSessionCategoryPlayback, with: .defaultToSpeaker)
            try avs.setActive(true)
        } catch {
            return false
        }
        return true
    }

    @discardableResult private func cleanUpAudioSession() -> Bool {
        let avs = AVAudioSession.sharedInstance()
        do {
            try avs.setActive(false)
        } catch {
            return false
        }
        return true
    }
}
