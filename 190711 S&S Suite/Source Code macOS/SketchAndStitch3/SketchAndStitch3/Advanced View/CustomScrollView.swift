import Cocoa

class CustomScrollView: NSScrollView {
    
    var initFrame: NSPoint?
    var eraseMode = false
    let eraserCursor = NSCursor.init(image: NSImage.init(named: "EraserCursor")!, hotSpot: NSPoint.init(x: 32, y: 32))
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.backgroundColor = NSColor.init(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
    override func scrollWheel(with event: NSEvent) {
        if(!eraseMode){
            if(event.subtype == NSEvent.EventSubtype.mouseEvent){
                if(event.deltaX == 0){
                    if(event.deltaY < 0){
                        self.magnification = self.magnification*1.1
                    }
                    
                    if(event.deltaY > 0){
                        self.magnification = self.magnification/1.1
                    }
                }
            } else{
                let invMag = (1/self.magnification)*8
                let newpoint = NSPoint.init(x: (documentView?.frame.minX)!+invMag*event.deltaX, y: (documentView?.frame.minY)!-invMag*event.deltaY)
                self.documentView?.setFrameOrigin(newpoint)
                self.documentView?.setFrameSize((documentView?.frame.size)!)
            }
        }
        
        
    }
    
    override func mouseDragged(with event: NSEvent) {
        
        if(!eraseMode){
            let invMag = (1/self.magnification)
            let newpoint = NSPoint.init(x: (documentView?.frame.minX)!+invMag*event.deltaX, y: (documentView?.frame.minY)!-invMag*event.deltaY)
            self.documentView?.setFrameOrigin(newpoint)
            self.documentView?.setFrameSize((documentView?.frame.size)!)
        } else{
            eraserCursor.set()
        }
    }
    
    override func mouseEntered(with event: NSEvent) {
        
        if(eraseMode){
            eraserCursor.set()
        }
        
        super.mouseEntered(with: event)
        
    }
    
    override func mouseExited(with event: NSEvent) {
        
        if(eraseMode){
            NSCursor.arrow.set()
        }
        
        super.mouseExited(with: event)
    
    }
    
    
    override func magnify(with event: NSEvent) {
        if(!eraseMode){
            super.magnify(with: event)
            //self.documentView?.bounds = self.bounds
        }
    }

}
