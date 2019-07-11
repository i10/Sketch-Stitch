import Cocoa

class CustomSegmentedControl: NSSegmentedControl {

    var shadowColor: NSColor = NSColor.init(red: 0, green: 0, blue: 0, alpha: 0.3)
    var buttonTopColor: NSColor = NSColor.init(hex: "#6b6b6b", alpha: 1.0)
    var buttonBottomColor: NSColor = NSColor.init(hex: "#474747", alpha: 1.0)
    var segmentRect: NSRect?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
    }
    
    override func draw(_ dirtyRect: NSRect) {

        let shadowRect = NSRect.init(x: dirtyRect.minX, y: dirtyRect.minY, width: dirtyRect.width-1, height: dirtyRect.height-1)
        let shadow = NSBezierPath.init(roundedRect: shadowRect, xRadius: 5, yRadius: 5)
        
        segmentRect = NSRect.init(x: dirtyRect.minX+1, y: dirtyRect.minY+1, width: dirtyRect.width-3, height: dirtyRect.height-3)
        let segment = NSBezierPath.init(roundedRect: segmentRect!, xRadius: 4, yRadius: 4)
        
        shadowColor.setFill()
        shadow.fill()
        
        let gradient = NSGradient.init(starting: buttonTopColor, ending: buttonBottomColor)
        gradient?.draw(in: segment, angle: 90)
        
        let higlightLine = NSBezierPath.init(roundedRect: NSRect.init(x: segmentRect!.minX+1, y: segmentRect!.minY, width: segmentRect!.width-3, height: 1), xRadius: 2, yRadius: 2)
        NSColor.init(calibratedWhite: 1.0, alpha: 0.1).setFill()
        higlightLine.fill()
        
        let interiorRect = NSRect.init(x: dirtyRect.minX, y: dirtyRect.minY-1, width: dirtyRect.width, height: dirtyRect.height)
        selectedCell()?.draw(withFrame: interiorRect, in: self)
        
    }
}
