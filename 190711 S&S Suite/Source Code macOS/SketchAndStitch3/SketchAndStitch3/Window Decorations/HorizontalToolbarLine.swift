import Cocoa

class HorizontalToolbarLine: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.wantsLayer = true
        self.layer!.backgroundColor = CGColor.init(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)
        
        // Drawing code here.
    }
    
}
