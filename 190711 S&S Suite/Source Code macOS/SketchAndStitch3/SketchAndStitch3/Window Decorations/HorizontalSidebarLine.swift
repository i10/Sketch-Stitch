import Cocoa

class HorizontalSidebarLine: NSView {
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.wantsLayer = true
        self.layer!.backgroundColor = NSColor.darkGray.cgColor
        
        // Drawing code here.
    }
    
}
