import Foundation
import AVFoundation
import UIKit

public class PlayerController: NSObject, AudioPlaying {
    public var elapsedTime: ((String) -> Void)?
    public var totalLength: ((String) -> Void)?
    public var progress: ((Double, Double) -> Void)?
    public var playerReady: (() -> Void)?
    public var isPlaying: Bool = false

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

    private var playerKVOContext = 0
    @objc private let player = AVPlayer()

    private var currentTime: Double {
        get {
            return CMTimeGetSeconds(player.currentTime())
        }
        set {
            let newTime = CMTimeMakeWithSeconds(newValue, preferredTimescale: 1)
            player.seek(to: newTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }

    private var duration: Double {
        guard let currentItem = player.currentItem else { return 0.0 }

        return CMTimeGetSeconds(currentItem.duration)
    }

    private var rate: Float {
        get {
            return player.rate
        }

        set {
            player.rate = newValue
        }
    }

    private var asset: AVURLAsset? {
        didSet {
            guard let newAsset = asset else { return }

            asynchronouslyLoadURLAsset(newAsset)
        }
    }

    // Attempt load and test these asset keys before playing.
    public static let assetKeysRequiredToPlay = [
        "playable",
        "hasProtectedContent"
    ]

    /*
     A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
     method.
     */
    private var timeObserverToken: Any?

    private var playerItem: AVPlayerItem? = nil {
        didSet {
            /*
             If needed, configure player item here before associating it with a player.
             (example: adding outputs, setting text style rules, selecting media options)
             */
            player.replaceCurrentItem(with: self.playerItem)
        }
    }

    deinit {
        if let timeObserverToken = timeObserverToken {
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }

        pause()

        removeObserver(self, forKeyPath: #keyPath(PlayerController.player.currentItem.duration),
                       context: &playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(PlayerController.player.rate), context: &playerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(PlayerController.player.currentItem.status),
                       context: &playerKVOContext)

        cleanUpAudioSession()
    }

    public func play() {
        isPlaying = true
        player.play()
    }

    public func pause() {
        isPlaying = false
        player.pause()
    }

    public func configure(url: URL, completion: ((PlayerResult) -> Void)?) {
        prepareAudioSession()

        addObserver(self, forKeyPath: #keyPath(PlayerController.player.currentItem.duration),
                    options: [.new], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(PlayerController.player.rate),
                    options: [.new], context: &playerKVOContext)
        addObserver(self, forKeyPath: #keyPath(PlayerController.player.currentItem.status),
                    options: [.new], context: &playerKVOContext)

        asset = AVURLAsset(url: url)

        // Make sure we don't have a strong reference cycle by only capturing self as weak.
        let interval = CMTimeMake(value: 1, timescale: 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval,
                                                           queue: DispatchQueue.main) { [unowned self] time in
                let timeElapsed = CMTimeGetSeconds(time)
                if let f = self.elapsedTime {
                    f(self.createTimeString(time: Float(timeElapsed)))
                }
                if let f = self.progress {
                    let duration = self.playerItem?.duration.seconds ?? 0.0
                    f(Double(timeElapsed), duration)
                }
        }
    }

    public func prepare(audioFilePath path: URL, completion: ((PlayerResult) -> Void)?, stopped:   (() -> Void)?) {
        asset = AVURLAsset(url: path)
    }

    // MARK: - KVO Observation

    // Update our UI when player or `player.currentItem` changes.
    override public func observeValue(forKeyPath keyPath: String?,
                                      of object: Any?,
                                      change: [NSKeyValueChangeKey: Any]?,
                                      context: UnsafeMutableRawPointer?) {
        // Make sure the this KVO callback was intended for this view controller.
        guard context == &playerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

        if keyPath == #keyPath(PlayerController.player.currentItem.duration) {
            // Update timeSlider and enable/disable controls when duration > 0.0

            /*
             Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
             `player.currentItem` is nil.
             */
            let newDuration: CMTime
            if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                newDuration = newDurationAsValue.timeValue
            } else {
                newDuration = CMTime.zero
            }

            let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
            let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0

            if let f = totalLength {
                f(createTimeString(time: Float(newDurationSeconds)))
            }
        } else if keyPath == #keyPath(PlayerController.player.rate) {
            // let newRate = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).doubleValue
        } else if keyPath == #keyPath(PlayerController.player.currentItem.status) {
            // Display an error if status becomes `.Failed`.
            let newStatus: AVPlayerItem.Status

            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
                if let f = playerReady,
                    AVPlayerItem.Status.readyToPlay == newStatus {
                    f()
                }
            } else {
                newStatus = .unknown
            }

            if newStatus == .failed {
                //error:player.currentItem?.error)
            }
        }
    }

    // MARK: - Asset Loading

    public func asynchronouslyLoadURLAsset(_ newAsset: AVURLAsset) {
        /*
         Using AVAsset now runs the risk of blocking the current thread (the
         main UI thread) whilst I/O happens to populate the properties. It's
         prudent to defer our work until the properties we need have been loaded.
         */
        newAsset.loadValuesAsynchronously(forKeys: PlayerController.assetKeysRequiredToPlay) {
            /*
             The asset invokes its completion handler on an arbitrary queue.
             To avoid multiple threads using our internal state at the same time
             we'll elect to use the main thread at all times, let's dispatch
             our handler to the main queue.
             */
            DispatchQueue.main.async {
                /*
                 `self.asset` has already changed! No point continuing because
                 another `newAsset` will come along in a moment.
                 */
                guard newAsset == self.asset else { return }

                /*
                 Test whether the values of each of the keys we need have been
                 successfully loaded.
                 */
                for key in PlayerController.assetKeysRequiredToPlay {
                    var error: NSError?

                    if newAsset.statusOfValue(forKey: key, error: &error) == .failed {
                        return
                    }
                }

                // We can't play this asset.
                if !newAsset.isPlayable || newAsset.hasProtectedContent {
                    return
                }

                /*
                 We can play this asset. Create a new `AVPlayerItem` and make
                 it our player's current item.
                 */
                self.playerItem = AVPlayerItem(asset: newAsset)
            }
        }
    }

    // Trigger KVO for anyone observing our properties affected by player and player.currentItem
    override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration": [#keyPath(player.currentItem.duration)],
            "rate": [#keyPath(player.rate)]
        ]

        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
    }

    private func createTimeString(time: Float) -> String {
        let components = NSDateComponents()
        components.second = Int(max(0.0, time))

        return timeRemainingFormatter.string(from: components as DateComponents)!
    }

    @discardableResult private func prepareAudioSession() -> Bool {
        let avs = AVAudioSession.sharedInstance()
        do {
            try avs.setCategory(.playback)
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
