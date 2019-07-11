import Cocoa

class VerticalLine: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.wantsLayer = true
        self.layer!.backgroundColor = CGColor.init(red: 0/255, green: 0/255, blue: 0/255, alpha: 1.0)
        
        // Drawing code here.
    }
    
}
