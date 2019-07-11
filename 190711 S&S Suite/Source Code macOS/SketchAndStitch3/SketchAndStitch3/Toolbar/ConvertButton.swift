import Cocoa

class ConvertButton: NSButton {
    
    var appDel = NSApplication.shared.delegate as! AppDelegate
    var presenting = false
    let convertView = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "Convert") as! ConvertOverlay
    
    override func draw(_ dirtyRect: NSRect) {
        if(self.wantsLayer != true){
            self.wantsLayer = true
        }
        super.draw(dirtyRect)
        
        if(!self.isEnabled){
            NSColor.init(red: 0, green: 0, blue: 0, alpha: 0.2).setFill()
            let buttonRect = NSRect.init(x: dirtyRect.minX+1, y: dirtyRect.minY+2, width: dirtyRect.width-2, height: dirtyRect.height-5)
            
            NSBezierPath.init(roundedRect: buttonRect, xRadius: 4, yRadius: 4).fill()
        }
        
        // Drawing code here.
    }
    
    override func mouseDown(with event: NSEvent) {
        
        if(self.isEnabled){
            self.setNeedsDisplay()
        }
        
        if(self.isEnabled){
            
            let xCord = (appDel.windowController?.convertButton.view!.superview!.frame)!
            
            if(!((appDel.windowController?.contentViewController?.presentedViewControllers?.contains(convertView))!)){
                sound?.play()
                appDel.windowController?.contentViewController?.present(convertView, asPopoverRelativeTo: NSRect.init(x: xCord.midX, y: (window?.contentView!.frame.maxY)!-32, width: 1, height: 1), of: (appDel.windowController?.contentViewController?.view)!, preferredEdge: NSRectEdge.minY, behavior: NSPopover.Behavior.semitransient)
                presenting = true
                
            } else{
                presenting = false
            }
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        if(self.isEnabled){
            self.setNeedsDisplay()
        }
    }
}
