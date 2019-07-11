import Cocoa

class IntroView: NSViewController {

    var appDel = NSApplication.shared.delegate as! AppDelegate
    
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.progressIndicator.startAnimation(1)
        
        
    }
    
}
