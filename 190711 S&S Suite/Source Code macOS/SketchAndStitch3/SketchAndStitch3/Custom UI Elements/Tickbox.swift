import Cocoa

class Tickbox: NSButtonCell {
    
    var animlayer = CAShapeLayer.init()
    
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        let innerBoxRect = NSRect.init(x: cellFrame.midX-6, y: cellFrame.midY-6, width: 12, height: 12)
        let outerBoxRect = NSRect.init(x: cellFrame.midX-7, y: cellFrame.midY-7, width: 14, height: 14)
        let selectRect = NSRect.init(x: cellFrame.midX-5, y: cellFrame.midY-5, width: 10, height: 10)
        
        if(self.integerValue == 1){
            let color = NSColor.init(deviceWhite: 0.3, alpha: 1)
            color.setFill()
            let ovalOut = NSBezierPath.init(ovalIn: outerBoxRect)
            ovalOut.fill()
            NSColor.init(deviceWhite: 0, alpha: 0.6).setFill()
            let ovalIn = NSBezierPath.init(ovalIn: innerBoxRect)
            ovalIn.fill()
            NSColor.white.withAlphaComponent(0.8).setFill()
            let ovalSelect = NSBezierPath.init(ovalIn: selectRect)
            ovalSelect.fill()
            
        
        } else {
            let color = NSColor.init(deviceWhite: 0.3, alpha: 1)
            color.setFill()
            let ovalOut = NSBezierPath.init(ovalIn: outerBoxRect)
            ovalOut.fill()
            NSColor.init(deviceWhite: 0, alpha: 0.6).setFill()
            let ovalIn = NSBezierPath.init(ovalIn: innerBoxRect)
            ovalIn.fill()
        }
        
    }
    
    override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
        
    }
    
    override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
        return frame
    }

}
