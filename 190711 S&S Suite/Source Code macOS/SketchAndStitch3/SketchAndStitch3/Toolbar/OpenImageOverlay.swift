import Cocoa

class OpenImageOverlay: NSViewController, NSControlTextEditingDelegate, NSTextFieldDelegate {
    
    var filepath: String?
    var viewController: AdvancedViewController?
    var url: NSURL?
    var appDel = NSApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var mainBox: NSBox!
    @IBOutlet weak var downloadBox: NSBox!
    @IBOutlet weak var URLfield: NSTextField!
    @IBOutlet weak var downloadButton: NSButton!
    
    @IBAction func openfromFile(_ sender: Any) {
        appDel.windowController?.contentViewController?.dismiss(self)
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Select an image file.";
        dialog.showsResizeIndicator    = false;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = false;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["png","jpg","jpeg"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url
            
            if (result != nil) {
                let path = result!.path
                filepath = path
                let importedImage = NSImage.init(byReferencing: result!)
                
                viewController!.loadImage(image: importedImage)
            }
        } else {
            return
        }
    }
    
    @IBAction func openfromWeb(_ sender: Any) {
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.2
            mainBox.animator().alphaValue = 0
            mainBox.animator().isHidden = true
            downloadBox.animator().isHidden = false
        })
    }
    
    @IBAction func urlGotPasted(_ sender: Any) {
        let pastedString = URLfield.stringValue
        if(pastedString.isValidUrl()){
            downloadButton.isEnabled = true
            url = NSURL.init(string: pastedString)
        } else {
            downloadButton.isEnabled = false
        }
    }
    
    @IBAction func abortDownload(_ sender: Any) {
        NSAnimationContext.runAnimationGroup({ (context) in
            context.duration = 0.2
            mainBox.animator().alphaValue = 1
            mainBox.animator().isHidden = false
            downloadBox.animator().isHidden = true
        })
    }
    @IBAction func downloadImage(_ sender: Any) {
        
        let downloadedImg = NSImage.init(byReferencing: ((url!.absoluteURL))!)
        
        if(downloadedImg.size != NSSize(width: 0, height: 0)){
            viewController?.loadImage(image: downloadedImg)
            appDel.windowController?.contentViewController?.dismiss(self)
        } else{
            print("No image behind parsed URL.")
        }

        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        mainBox.wantsLayer = true
        downloadBox.wantsLayer = true
        URLfield.delegate = self
        viewController = appDel.windowController?.contentViewController as? AdvancedViewController
        // Do view setup here.
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if (obj.object as? NSTextField) != nil {
            let pastedString = URLfield.stringValue
            if(pastedString.isValidUrl() && (pastedString.hasSuffix(".png") || pastedString.hasSuffix(".jpg") || pastedString.hasSuffix(".jpeg"))){
                downloadButton.isEnabled = true
                url = NSURL.init(string: pastedString)
            } else {
                downloadButton.isEnabled = false
            }
        }
    }
}
