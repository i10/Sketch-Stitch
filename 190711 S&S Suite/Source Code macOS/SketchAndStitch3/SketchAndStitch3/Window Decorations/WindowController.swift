import Cocoa

class WindowController: NSWindowController {
    
    var appDel = NSApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var toolbar: NSToolbar!
    
    var color = true
    var tempImg: NSImage?
    var mode: Int = 0
    var advancedViewController: AdvancedViewController!
    
    @IBOutlet weak var exportButton: NSToolbarItem!
    @IBOutlet weak var convertButton: NSToolbarItem!
    @IBOutlet weak var compareButton: CustomButton!
    @IBOutlet weak var connectButton: ConnectButton!
    @IBOutlet weak var connectTBItem: NSToolbarItem!
    @IBOutlet weak var openTBItem: NSToolbarItem!
    @IBOutlet weak var eraserButton: EraserButton!
    
    override func windowDidLoad() {
        super.windowDidLoad()
        if(color){
            self.window?.backgroundColor = NSColor.init(red: 14/255, green: 14/255, blue: 14/255, alpha: 1.0)
        }
        
        self.window!.contentView!.wantsLayer = true
        self.window!.contentView!.canDrawSubviewsIntoLayer = true
        
        self.advancedViewController = self.contentViewController as? AdvancedViewController
        
        self.toolbar.selectedItemIdentifier = nil
        
        self.window!.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isEnabled = false
        self.window!.standardWindowButton(NSWindow.ButtonType.zoomButton)!.isHidden = true
        
        self.window!.minSize = NSSize.init(width: 844, height: 750)
        
        //self.window!.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)!.isEnabled = false
        //self.window!.standardWindowButton(NSWindow.ButtonType.miniaturizeButton)!.isHidden = true
    }
    
}
