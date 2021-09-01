import UIKit
import GameController
import TvOSSlider

class ViewController: UIViewController {

    override var preferredFocusEnvironments: [UIFocusEnvironment] {
        return [hintView]
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        slider.isUserInteractionEnabled = false
        setUpControllerObserver()
    }
    
    // MARK: - Private
    
    @IBOutlet private weak var slider: TvOSSlider!
    @IBOutlet private weak var hintView: UIView!
    @IBOutlet private weak var directionLabel: UILabel!
    
    private var currentRadians: Float = 0
    
    private func setUpControllerObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(controllerConnected(note:)), name: .GCControllerDidConnect, object: nil)
    }
        
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Clean everything up when the user releases the finger from the digitizer
        directionLabel.text = "⏺"
        hintView.alpha = 0
    }
    
    @objc
    private func controllerConnected(note: NSNotification) {
        
        // Only considering a single controller for simplicity
        guard let controller = GCController.controllers().first else { return }
        
        guard let micro = controller.microGamepad else { return }
        micro.reportsAbsoluteDpadValues = true
        micro.dpad.valueChangedHandler = {
            [weak self] (pad, x, y) in
            guard let self = self else { return }
            
            // Get the distance from the center of the digitizer to the gesture location
            let radius = sqrt(x*x + y*y)

            // Discard gestures out of the ring area of Siri Remote
            guard radius > 0.5 else {
                self.directionLabel.text = "⏺"
                self.hintView.alpha = 0
                return
            }
            
            // Show the hint view making more visual the current location of the gesture
            UIView.animate(withDuration: 0.1) {
                self.hintView.alpha = 1
            }
        
            UIView.animate(withDuration: 0.1) {
                
                // Rotate hintView to the appropriate radians
                let cos = x / radius
                let sin = y / radius
                let radians = atan2(sin, cos)
                
                self.hintView.transform = CGAffineTransform(rotationAngle: CGFloat(-radians))
                                    
                // Get and log rotation direction
                let normalizedRadians = (radians + (2 * .pi)).truncatingRemainder(dividingBy: 2 * .pi)
                
                let radiansOffset = normalizedRadians - self.currentRadians
                let normalizedRadiansOffset = (radiansOffset + (2 * .pi)).truncatingRemainder(dividingBy: 2 * .pi)
                
                if normalizedRadiansOffset > .pi {
                    self.directionLabel.text = "➡️"
                    self.slider.value = min(1, self.slider.value + 0.001)
                }
                else {
                    self.directionLabel.text = "⬅️"
                    self.slider.value = max(0, self.slider.value - 0.001)
                }
                
                self.currentRadians = normalizedRadians
            }
        }
    }
}
