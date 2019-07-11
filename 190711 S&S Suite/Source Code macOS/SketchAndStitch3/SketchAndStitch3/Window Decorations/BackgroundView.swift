import Cocoa

class BackgroundView: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.wantsLayer = true
        self.layer!.backgroundColor = CGColor.init(red: 30/255, green: 30/255, blue: 30/255, alpha: 1.0)
        
        // Drawing code here.
    }
    
}
