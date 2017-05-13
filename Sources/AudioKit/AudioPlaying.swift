import Foundation

public enum PlayerResult {
    case success
    case failure
}

public protocol AudioPlaying {
    var elapsedTime: ((String) -> Void)? { get set }
    var totalLength: ((String) -> Void)? { get set }
    var progress: ((_ elapsedTime: Double, _ totalLength: Double) -> Void)? { get set }
    var playerReady: (() -> Void)? { get set }
    var isPlaying: Bool { get }

    func configure(url: URL, completion: ((PlayerResult) -> Void)?)
    func play()
    func pause()
    func prepare(audioFilePath path: URL, completion: ((PlayerResult) -> Void)?, stopped: (() -> Void)?)
}
