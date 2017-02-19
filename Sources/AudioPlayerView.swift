import UIKit

public protocol AudioPlayerDelegate: class {
    func controlPressed(player: AudioPlayerView)
}

public class AudioPlayerView: UIView {
    public lazy var itemTitle: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = UIFont.regular(withSize: 14)
        return l
    }()
    
    public lazy var totalTime: UILabel = {
        let l = UILabel()
        l.font = UIFont.light(withSize: 14)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = String(format: "%02d:%02d", 0, 0)
        return l
    }()
    
    public lazy var elapsedTime: UILabel = {
        let l = UILabel()
        l.font = UIFont.light(withSize: 14)
        l.translatesAutoresizingMaskIntoConstraints = false
        l.text = String(format: "%02d:%02d", 0, 0)
        return l
    }()
    
    public lazy var controlButton: UIButton = {
        let b = UIButton(type: .custom)
        b.translatesAutoresizingMaskIntoConstraints = false
        b.addTarget(self, action: #selector(controlButtonTapped(sender:)), for: .touchUpInside)
        b.titleLabel?.font = UIFont.regular(withSize: 14)
        b.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
        b.setTitleColor(.white, for: .normal)
        b.setTitleColor(.buttonDisabled, for: .highlighted)
        b.backgroundColor = .treamentButtonBackground
        b.layer.cornerRadius = 3
        b.setTitle("Afspelen", for: .normal)
        return b
    }()
    
    public weak var delegate: AudioPlayerDelegate?
    
    private lazy var wrapperView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private lazy var progressIndicator: UIProgressView = {
        let p = UIProgressView(progressViewStyle: .bar)
        p.translatesAutoresizingMaskIntoConstraints = false
        p.trackTintColor = UIColor.buttonDisabled
        p.progressTintColor = .baseGreen
        return p
    }()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        applyViewConstraints()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func reset() {
        elapsedTime.text = String(format: "%0d:%02d", 0, 0)
        totalTime.text = String(format: "%0d:%02d", 0, 0)
        progressIndicator.setProgress(0, animated: false)
        controlButton.setTitle("Afspelen", for: .normal)
    }
    
    public func progress(totalTime: Double, elapsedTime: Double) {
        progressIndicator.setProgress(1.0 / Float(totalTime / elapsedTime), animated: true)
    }
    
    @objc private func controlButtonTapped(sender: UIButton) {
        delegate?.controlPressed(player: self)
    }
    
    private func setupViews() {
        addSubview(wrapperView)
        wrapperView.addSubview(itemTitle)
        wrapperView.addSubview(elapsedTime)
        wrapperView.addSubview(totalTime)
        wrapperView.addSubview(controlButton)
        wrapperView.addSubview(progressIndicator)
    }
    
    // swiftlint:disable function_body_length
    private func applyViewConstraints() {
        let views = ["wrapperView": wrapperView]
        
        var constraints: [NSLayoutConstraint] = []
        constraints.append(NSLayoutConstraint(item: itemTitle,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: wrapperView,
                                              attribute: .top,
                                              multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: itemTitle,
                                              attribute: .left,
                                              relatedBy: .equal,
                                              toItem: wrapperView,
                                              attribute: .left,
                                              multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: itemTitle,
                                              attribute: .right,
                                              relatedBy: .equal,
                                              toItem: wrapperView,
                                              attribute: .right,
                                              multiplier: 1, constant: 0))
        
        constraints.append(NSLayoutConstraint(item: elapsedTime,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: itemTitle,
                                              attribute: .bottom,
                                              multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: elapsedTime,
                                              attribute: .left,
                                              relatedBy: .equal,
                                              toItem: itemTitle,
                                              attribute: .left,
                                              multiplier: 1, constant: 0))
        
        constraints.append(NSLayoutConstraint(item: totalTime,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: itemTitle,
                                              attribute: .bottom,
                                              multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: totalTime,
                                              attribute: .right,
                                              relatedBy: .equal,
                                              toItem: itemTitle,
                                              attribute: .right,
                                              multiplier: 1, constant: 0))
        
        constraints.append(NSLayoutConstraint(item: controlButton,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: elapsedTime,
                                              attribute: .bottom,
                                              multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: controlButton,
                                              attribute: .left,
                                              relatedBy: .equal,
                                              toItem: elapsedTime,
                                              attribute: .left,
                                              multiplier: 1, constant: 0))
        
        constraints.append(NSLayoutConstraint(item: progressIndicator,
                                              attribute: .top,
                                              relatedBy: .equal,
                                              toItem: controlButton,
                                              attribute: .bottom,
                                              multiplier: 1, constant: 10))
        constraints.append(NSLayoutConstraint(item: progressIndicator,
                                              attribute: .left,
                                              relatedBy: .equal,
                                              toItem: controlButton,
                                              attribute: .left,
                                              multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: progressIndicator,
                                              attribute: .right,
                                              relatedBy: .equal,
                                              toItem: wrapperView,
                                              attribute: .right,
                                              multiplier: 1, constant: 0))
        constraints.append(NSLayoutConstraint(item: progressIndicator,
                                              attribute: .bottom,
                                              relatedBy: .equal,
                                              toItem: wrapperView,
                                              attribute: .bottom,
                                              multiplier: 1, constant: 0))
        
        NSLayoutConstraint.activate(constraints)
        
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[wrapperView]|",
                                                      options: NSLayoutFormatOptions(rawValue: 0),
                                                      metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[wrapperView]|",
                                                      options: NSLayoutFormatOptions(rawValue: 0),
                                                      metrics: nil, views: views))
    }
    // swiftlint:enable function_body_length
}


