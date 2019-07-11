import Cocoa

class ConvertOverlay: NSViewController {

    @IBOutlet weak var indicator: NSProgressIndicator!
    @IBOutlet weak var doneLabel: NSTextField!
    @IBOutlet weak var waitingLabel: NSTextField!
    @IBOutlet weak var errorLabel: NSTextField!
    
    let convertQ = DispatchQueue.init(label: "convertQ")
    let exportDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Sketch And Stitch")
    var desktopDir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!.appendingPathComponent("S&S Export")
    
    let fileManager = FileManager.default
    
    var appDel = NSApplication.shared.delegate as! AppDelegate
    
    var isWorking = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        convertCurrentLayer()
    }
    
    func convertCurrentLayer(){
        if(!self.isWorking){
            errorLabel.isHidden = true
            doneLabel.isHidden = true
            waitingLabel.isHidden = true
            indicator.startAnimation(self)
            
            saveLayerCenterlines(self)
        }
    }
    
    func saveLayerCenterlines(_ sender: Any) {
        
        isWorking = true
        exportDir.createDir()
        
        let viewCon = appDel.windowController?.advancedViewController
        
        let selectedLayer = viewCon!.layerView.selectedRow
        let selectedStitch = viewCon!.layerController.layers[selectedLayer].selectedStitch
        
        let image : (NSImage, Int) = (appDel.windowController!.advancedViewController.layerController.layers[selectedLayer].layerImageView.image!, selectedStitch)

        
        convertQ.async {
                
            var suffix = "1"
                
            if(image.1 != -1){
                suffix = String(image.1)
            }
                
            let _ = image.0.saveToFile(as: suffix, fileType: .png, at: self.exportDir)

            DispatchQueue.main.async {
                self.waitingLabel.isHidden = false
            }
            
            var i = 0
            
            var outExists = self.outputExists()
            
            while(!outExists){
                sleep(1)
                i = i+1
                if(i==20){
                    break
                }
                outExists = self.outputExists()
            }
            
            if(outExists){
                self.desktopDir.createDir()
                
                try? self.fileManager.copyItem(at: self.exportDir.appendingPathComponent("Output.ART80"), to: self.desktopDir.appendingPathComponent("Output.ART80"))
                try? self.fileManager.removeItem(at: self.exportDir.appendingPathComponent("Output.ART80"))
                
                DispatchQueue.main.async {
                    self.indicator.stopAnimation(self)
                    self.waitingLabel.isHidden = true
                    self.doneLabel.isHidden = false
                    self.isWorking = false
                    NSSound.init(named: "Tink")?.play()
                }
            } else{
                DispatchQueue.main.async {
                    self.indicator.stopAnimation(self)
                    self.waitingLabel.isHidden = true
                    self.doneLabel.isHidden = true
                    self.errorLabel.isHidden = false
                    self.isWorking = false
                }
            }
            

        }
        
    }
    
    func outputExists() -> Bool{
        let filePath = exportDir.appendingPathComponent("Output.ART80").path
        
        if fileManager.fileExists(atPath: filePath) {
                return true
        } else {
                return false
        }
    }
    
}
