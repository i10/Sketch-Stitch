import Cocoa

class ToolbarIconButtonCell: NSButtonCell {
    
    var buttonTopColor: NSColor = NSColor.init(hex: "#6b6b6b", alpha: 1.0)
    var buttonBottomColor: NSColor = NSColor.init(hex: "#474747", alpha: 1.0)
    var shadowColor: NSColor = NSColor.init(red: 0, green: 0, blue: 0, alpha: 0.3)
    var fontColor: NSColor = NSColor.init(hex: "#cccccc", alpha: 1.0)
    var imageColor: NSColor = NSColor.init(hex: "#cccccc", alpha: 1.0)
    var mouseInFrame: Bool?
    var mouseEv: Int?
    var buttonRect: NSRect?
    var shadowRect: NSRect?
    var imageRect: NSRect?
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        if let mutableAttributedTitle = self.attributedTitle.mutableCopy() as? NSMutableAttributedString {
            mutableAttributedTitle.addAttribute(.foregroundColor, value: fontColor, range: NSRange(location: 0, length: mutableAttributedTitle.length))
            self.attributedTitle = mutableAttributedTitle
        }
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        drawBezel(withFrame: cellFrame, in: controlView)
        
        if(self.image != nil){
            drawImage(self.image!, withFrame: cellFrame, in: controlView)
        }
        _ = drawTitle(self.attributedTitle, withFrame: cellFrame, in: controlView)
        
        
    }
    
    override func drawImage(_ image: NSImage, withFrame frame: NSRect, in controlView: NSView) {
        
        var adjustedFrame = self.drawingRect(forBounds: frame)
        
        adjustedFrame = NSRect.init(x: adjustedFrame.midX-(adjustedFrame.height-3)/2, y: adjustedFrame.minY, width: adjustedFrame.height-3, height: adjustedFrame.height-2)
        
        let desiredDim = adjustedFrame.height
        
        var newheight: CGFloat
        var newwidth: CGFloat
        
        if(image.size.height > desiredDim || image.size.width > desiredDim){
            if(image.size.width != image.size.height){
                let maxSide = max(image.size.width, image.size.height)
                
                if(maxSide == image.size.width){
                    newwidth = desiredDim
                    newheight = (image.size.height / maxSide) * desiredDim
                } else{
                    newheight = desiredDim
                    newwidth = (image.size.width / maxSide) * desiredDim
                }
            } else{
                newheight = desiredDim
                newwidth = desiredDim
            }
        } else{
            newheight = image.size.height
            newwidth = image.size.width
        }
        
        let finalImageRect: NSRect
        
        if(Int(newwidth) % 2 != 0){
            if(Int(newheight) % 2 != 0){
                finalImageRect = NSRect.init(x: (adjustedFrame.midX-newwidth/2)-0.5, y: adjustedFrame.midY-newheight/2-0.5, width: newwidth, height: newheight)
            } else{
                finalImageRect = NSRect.init(x: (adjustedFrame.midX-newwidth/2)-0.5, y: adjustedFrame.midY-newheight/2, width: newwidth, height: newheight)
            }
        } else{
            if(Int(newheight) % 2 != 0){
                finalImageRect = NSRect.init(x: (adjustedFrame.midX-newwidth/2), y: adjustedFrame.midY-newheight/2-0.5, width: newwidth, height: newheight)
            } else{
                finalImageRect = NSRect.init(x: (adjustedFrame.midX-newwidth/2), y: adjustedFrame.midY-newheight/2, width: newwidth, height: newheight)
            }
        }
        
        if(self.isEnabled){
            self.image!.draw(in: finalImageRect)
        } else{
            self.image!.draw(in: finalImageRect)
        }
        
    }
    
    override func drawBezel(withFrame frame: NSRect, in controlView: NSView) {
        
        shadowRect = NSRect.init(x: frame.minX, y: frame.minY+1, width: frame.width, height: frame.height-4)
        buttonRect = NSRect.init(x: frame.minX+1, y: frame.minY+2, width: frame.width-2, height: frame.height-6)
        
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
        
        if(mouseInFrame!){
            let highlight = NSBezierPath.init(roundedRect: buttonRect!, xRadius: 4, yRadius: 4)
            NSColor.init(red: 1, green: 1, blue: 1, alpha: 0.15).setFill()
            highlight.fill()
            mouseEv = 0
            mouseInFrame = false
        }
        
        return retVal
    }
}
