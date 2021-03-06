import Cocoa

class CompareButton: NSButton {
    
    var appDel = NSApplication.shared.delegate as! AppDelegate
    var tempImg: NSImage?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        if(self.image != nil){
            //colorizeImage()
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
        
        if(!self.isEnabled){
            NSColor.init(red: 0, green: 0, blue: 0, alpha: 0.3).setFill()
            let buttonRect = NSRect.init(x: dirtyRect.minX+1, y: dirtyRect.minY+2, width: dirtyRect.width-2, height: dirtyRect.height-5)
            
            NSBezierPath.init(roundedRect: buttonRect, xRadius: 4, yRadius: 4).fill()
        }
        
    }
    
    override func mouseDown(with event: NSEvent) {
        
        if(self.isEnabled){
            tempImg = (appDel.windowController?.contentViewController as! AdvancedViewController).mainImageView.image
            //(appDel.windowController?.contentViewController as! AdvancedViewController).mainImageView.renderErased = false
            (appDel.windowController?.contentViewController as! AdvancedViewController).mainImageView.image = (appDel.windowController?.contentViewController as! AdvancedViewController).backupImage
            (appDel.windowController?.contentViewController as! AdvancedViewController).backupImage = tempImg
            
            super.mouseDown(with: event)
            
            //(appDel.windowController?.contentViewController as! AdvancedViewController).mainImageView.renderErased = true
            tempImg = (appDel.windowController?.contentViewController as! AdvancedViewController).mainImageView.image
            
            (appDel.windowController?.contentViewController as! AdvancedViewController).mainImageView.image = (appDel.windowController?.contentViewController as! AdvancedViewController).backupImage
            (appDel.windowController?.contentViewController as! AdvancedViewController).backupImage = tempImg
            
        }
    }
    
    func colorizeImage(){
        let bitmapRep = NSBitmapImageRep.init(data: (self.image?.tiffRepresentation)!)
        
        let width = Int((bitmapRep?.size.width)!)
        let height = Int((bitmapRep?.size.height)!)
        
        for i in 0...width-1{
            for j in 0...height-1{
                if((bitmapRep?.colorAt(x: i, y: j)?.alphaComponent)! > CGFloat(0.0)){
                    bitmapRep?.setColor(NSColor.init(deviceRed: 0.7, green: 0.7, blue: 0.7, alpha: (bitmapRep?.colorAt(x: i, y: j)?.alphaComponent)!), atX: i, y: j)
                }
            }
        }
        
        let res = NSImage.init(cgImage: (bitmapRep?.cgImage!)!, size: (bitmapRep?.size)!)
        
        self.image = res
    }
    
}
