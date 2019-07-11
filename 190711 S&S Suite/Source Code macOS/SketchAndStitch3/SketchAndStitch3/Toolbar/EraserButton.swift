import Cocoa

class EraserButton: NSButton {
    
    var appDel = NSApplication.shared.delegate as! AppDelegate
    var tempImg: NSImage?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if(self.image != nil){
            //colorizeImage()
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        
        if(self.integerValue == 1){
            (self.cell as! ToolbarIconButtonCell).buttonTopColor = NSColor.init(hex: "#d10000", alpha: 1.0)
            (self.cell as! ToolbarIconButtonCell).buttonBottomColor = NSColor.init(hex: "#800033", alpha: 1.0)
            appDel.windowController?.advancedViewController.mainScrollView.eraseMode = true
            //appDel.windowController?.advancedViewController.mainImageView.drawingMode = true
            appDel.windowController?.advancedViewController.mainImageView.mouseUp(with: NSEvent.init())
            appDel.windowController?.advancedViewController.mainScrollView.eraserCursor.set()
            appDel.windowController?.advancedViewController.mainScrollView.magnification = 1
        } else{
            (self.cell as! ToolbarIconButtonCell).buttonTopColor = NSColor.init(hex: "#6b6b6b", alpha: 1.0)
            (self.cell as! ToolbarIconButtonCell).buttonBottomColor = NSColor.init(hex: "#474747", alpha: 1.0)
            appDel.windowController?.advancedViewController.mainScrollView.eraseMode = false
            //appDel.windowController?.advancedViewController.mainImageView.drawingMode = false
            NSCursor.arrow.set()
        }
        
        super.draw(dirtyRect)
        // Drawing code here.
        
        if(!self.isEnabled){
            NSColor.init(red: 0, green: 0, blue: 0, alpha: 0.3).setFill()
            let buttonRect = NSRect.init(x: dirtyRect.minX+1, y: dirtyRect.minY+2, width: dirtyRect.width-2, height: dirtyRect.height-5)
            
            NSBezierPath.init(roundedRect: buttonRect, xRadius: 4, yRadius: 4).fill()
        }
        
        
        
    }
    
    override func mouseDown(with event: NSEvent) {
        
        super.mouseDown(with: event)
    }
    
}
