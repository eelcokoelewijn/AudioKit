import Foundation

public enum PlayerResult {
    case success
    case failure
}

public protocol AudioPlaying {
    var elapsedTime: ((String) -> ())? { get set }
    var totalLength: ((String) -> ())? { get set }
    var progress: ((_ elapsedTime: Double, _ totalLength: Double) -> ())? { get set }
    var playerReady: (() -> ())? { get set }
    var isPlaying: Bool { get }
    
    func configure(url: URL, completion: ((PlayerResult) -> ())?)
    func play()
    func pause()
    func prepare(audioFilePath path: URL, completion: ((PlayerResult) -> ())?, stopped: (() -> ())?)
}
