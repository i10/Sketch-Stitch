import Cocoa

class DrawingView: NSImageView {
    
    var magnification = 1
    
    var drawingMode = false
    
    var renderErased = true
    
    var appDel = NSApplication.shared.delegate as! AppDelegate
    
    let eraserCursor = NSCursor.init(image: NSImage.init(named: "EraserCursor")!, hotSpot: NSPoint.init(x: 32, y: 32))
    
    var brushes : [NSBezierPath] = []
    
    var currentCleanRect : NSRect = .zero
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
        self.isEditable = true
        self.imageAlignment = .alignCenter
    }
    
    override func draw(_ dirtyRect: NSRect) {
        
        super.draw(dirtyRect)
        
        if(renderErased){
            NSColor.init(cgColor: CGColor.init(red: 0, green: 0, blue: 0, alpha: 1))?.setFill()
         
            for brush in brushes{
                brush.fill()
            }
            
        }
        
        let rel = CGFloat(Double(self.image!.size.width)/Double(self.image!.size.height))
        
        let drawingRect = NSRect.init(x: bounds.midX-(rel*bounds.height*0.5), y: 0, width: rel*bounds.height, height: bounds.height)
        
        self.image?.bestRepresentation(for: visibleRect, context: NSGraphicsContext.current, hints: .none)?.draw(in: drawingRect, from: .zero, operation: .sourceOut, fraction: 1, respectFlipped: false, hints: .none)
        


    }
    
    override func mouseDown(with event: NSEvent) {
        
        self.isEditable = false
        
        if(drawingMode){
            eraserCursor.set()
            
            let brush = NSBezierPath.init(ovalIn: NSRect.init(x: event.locationInWindow.x-31, y: event.locationInWindow.y-44, width: 60, height: 60))
            
            brushes.append(brush)
            needsDisplay = true
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        
        self.isEditable = false
        
        if(drawingMode){
            let brush = NSBezierPath.init(ovalIn: NSRect.init(x: event.locationInWindow.x-31, y: event.locationInWindow.y-44, width: 60, height: 60))
            
            brushes.append(brush)
            needsDisplay = true
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        
        if(drawingMode){
            let newImage = self.imageRepresentation()
            self.image = newImage.0
            appDel.windowController?.advancedViewController.mainImageView.image = newImage.0
            appDel.windowController?.advancedViewController.backupImage = newImage.0
            appDel.windowController?.advancedViewController.currentCGImage = newImage.1
            
            let selectedLayer = appDel.windowController?.advancedViewController.layerView.selectedRow
            
            if(selectedLayer != -1){
                appDel.windowController?.advancedViewController.layerController.layers[selectedLayer!].layerImageView.image = newImage.0
            }
            
            
        }
        
        brushes.removeAll()
        
        self.isEditable = true
    }
    
    func imageRepresentation() -> (NSImage, CGImage){
        let bir = self.bitmapImageRepForCachingDisplay(in: self.bounds)
        bir?.size = self.bounds.size
        self.cacheDisplay(in: self.bounds, to: bir!)
        let out = NSImage.init(size: bir!.size)
        out.addRepresentation(bir!)

        return (out, bir!.cgImage!)
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.arrow.set()
    }
}
