import Cocoa
@IBDesignable

class OpenButtonCell: NSButtonCell {
    @IBInspectable var buttonTopColor: NSColor = NSColor.init(hex: "#6b6b6b", alpha: 1.0)
    @IBInspectable var buttonBottomColor: NSColor = NSColor.init(hex: "#474747", alpha: 1.0)
    @IBInspectable var shadowColor: NSColor = NSColor.init(red: 0, green: 0, blue: 0, alpha: 0.3)
    @IBInspectable var fontColor: NSColor = NSColor.init(hex: "#000000", alpha: 1.0)
    
    var mouseInFrame: Bool?
    var mouseEv: Int?
    var buttonRect: NSRect?
    var shadowRect: NSRect?
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        if let mutableAttributedTitle = self.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: fontColor, range: NSRange(location: 0, length: mutableAttributedTitle.length))
            self.attributedTitle = mutableAttributedTitle
        }
    }
    
    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {
        
        shadowRect = NSRect.init(x: frame.minX, y: frame.minY+1, width: frame.width, height: frame.height-3)
        buttonRect = NSRect.init(x: frame.minX+1, y: frame.minY+2, width: frame.width-2, height: frame.height-5)
        
        let shadow = NSBezierPath.init(roundedRect: shadowRect!, xRadius: 5, yRadius: 5)
        
        let button = NSBezierPath.init(roundedRect: buttonRect!, xRadius: 4, yRadius: 4)
        
        shadowColor.setFill()
        shadow.fill()
        
        let gradient = NSGradient.init(starting: buttonTopColor, ending: buttonBottomColor)
        gradient?.draw(in: button, angle: 90)
        
        let higlightLine = NSBezierPath.init(roundedRect: NSRect.init(x: buttonRect!.minX+1, y: buttonRect!.minY, width: buttonRect!.width-3, height: 1), xRadius: 2, yRadius: 2)
        NSColor.init(calibratedWhite: 1.0, alpha: 0.1).setFill()
        higlightLine.fill()
    }
    
    override func drawTitle(_ title: NSAttributedString, withFrame frame: NSRect, in controlView: NSView) -> NSRect {
        
        mouseEv = NSEvent.pressedMouseButtons
        
        let mouseLoc = self.controlView?.window?.contentViewController?.view.convert(NSEvent.mouseLocation, to: nil)
        var buttonLoc = NSPoint(x: (self.controlView?.convert(frame, to: nil).midX)!, y: (self.controlView?.convert(frame, to: nil).midY)!)
        
        buttonLoc = (self.controlView?.window?.convertPoint(toScreen: buttonLoc))!
    
        let dstx = abs(buttonLoc.x-mouseLoc!.x)
        let dsty = abs(buttonLoc.y-mouseLoc!.y-3)
        
        if(mouseEv == 1 && (dstx < (buttonRect?.width)!/2 && dsty < (buttonRect?.height)!/2)){
            mouseInFrame = true
        } else{
            mouseInFrame = false
        }
        
        let titleRect = NSRect.init(x: frame.minX, y: frame.minY-1, width: frame.width, height: frame.height)
        let retVal = super.drawTitle(title, withFrame: titleRect, in: controlView)
        
        if(mouseInFrame! && self.isEnabled){
            let highlight = NSBezierPath.init(roundedRect: buttonRect!, xRadius: 4, yRadius: 4)
            NSColor.init(red: 1, green: 1, blue: 1, alpha: 0.15).setFill()
            highlight.fill()
            mouseEv = 0
            mouseInFrame = false
        }
        
        return retVal
    }
}
