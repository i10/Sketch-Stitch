import Cocoa

class ColorCollectionItem: NSCollectionViewItem {
    
    var color : CGColor?
    var appDel = NSApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        self.view.layer!.borderColor = CGColor.init(red: 40.0/255, green: 40.0/255, blue: 40.0/255, alpha: 1.0)
        self.view.alphaValue = 0.2
        // Do view setup here.
    }
    
    override func mouseDown(with event: NSEvent) {
        
        if((self.appDel.windowController?.advancedViewController.colorCollection.isEnabled)!){
            if(!isSelected){
                
                collectionView?.deselectAll(self)
                
                self.view.alphaValue = 1
                
                let indexPath = (collectionView?.indexPath(for: self))!
                
                collectionView?.selectItems(at: [indexPath], scrollPosition: .centeredHorizontally)
                
                self.view.layer?.borderColor = CGColor.white
                
            } else{
                
                collectionView?.deselectAll(self)
                
                self.view.layer?.borderColor = CGColor.init(red: 40.0/255, green: 40.0/255, blue: 40.0/255, alpha: 1.0)
                
            }
            
            DispatchQueue.main.async {
                self.appDel.windowController?.advancedViewController.coloringChanged()
            }
        }
        
    }
    
}
