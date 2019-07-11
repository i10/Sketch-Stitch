import UIKit

class ShutterButton: UIButton {
    
    var buttonRect : CGRect?
    var isToggled = false
    let generator = UINotificationFeedbackGenerator()

    
    override func draw(_ rect: CGRect) {
        let button = UIBezierPath.init(ovalIn: rect)
        buttonRect = rect
        let middleRingRect = CGRect.init(x: rect.minX+6, y: rect.minY+6, width: rect.width-12
            , height: rect.height-12)
        
        let middleRing = UIBezierPath.init(ovalIn: middleRingRect)
        
        let innerRingRect = CGRect.init(x: middleRingRect.minX+2, y: middleRingRect.minY+2, width: middleRingRect.width-4
            , height: middleRingRect.height-4)
        let innerRing = UIBezierPath.init(ovalIn: innerRingRect)
        
        UIColor.white.setFill()
        button.fill()
        UIColor.black.setFill()
        middleRing.fill()
        UIColor.white.setFill()
        innerRing.fill()
        
        if(isToggled){
            UIColor.black.withAlphaComponent(0.2).setFill()
            button.fill()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        isToggled = true
        super.setNeedsDisplay()
        generator.notificationOccurred(.success)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        isToggled = false
        super.setNeedsDisplay()
    }
    
}
