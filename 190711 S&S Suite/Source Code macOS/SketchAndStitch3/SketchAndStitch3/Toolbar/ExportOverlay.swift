import Cocoa

class ExportOverlay: NSViewController {
    
    var viewController: AdvancedViewController?
    var appDel = NSApplication.shared.delegate as! AppDelegate
    let exportQ = DispatchQueue.init(label: "exportQ", qos: .userInteractive)
    var exportDir = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!.appendingPathComponent("S&S Export")
    
    var exportInProgress = 0
    
    @IBOutlet weak var exportIndicator: NSProgressIndicator!
    
    @IBOutlet weak var everythingButton: NSButton!
    @IBOutlet weak var filteredImagesButton: NSButton!
    @IBOutlet weak var centerlinesButton: NSButton!
    @IBOutlet weak var outlinesButton: NSButton!
    
    @IBAction func exportEverything(_ sender: Any) {
        
        everythingButton.isEnabled = false
        
        saveImageFiles(self)
        saveLayerOutlines(self)
        saveLayerCenterlines(self)
        
        everythingButton.isEnabled = true
        
    }
    
    @IBAction func saveImageFiles(_ sender: Any) {
        
        exportInProgress += 1
        exportIndicator.startAnimation(self)
        filteredImagesButton.isEnabled = false
        
        exportDir.createDir()
        
        appDel.windowController?.advancedViewController.drawMainImage(self)
 
        let layerArray = viewController!.layerController.layers
        
        var layerImages : [String: (NSImage,Int)] = [:]
        
        if((viewController?.layerController.layers.count)! > 1){
            layerImages["Combined Image"] = (self.viewController!.combinedImage!, 0)
        }
        
        for layer in layerArray!{
            layerImages[layer.layerTitle.stringValue] = (layer.layerImageView.image!, layer.selectedStitch)
        }
        
        exportQ.async {
    
            for image in layerImages{
                
                var stitchType = ""
                
                switch image.value.1 {
                case 1:
                    stitchType = " (Single)"
                case 2:
                    stitchType = " (ZigZag)"
                case 3:
                    stitchType = " (Tripple)"
                case 4:
                    stitchType = " (Satin)"
                default:
                    stitchType = ""
                }
                
                let _ = image.value.0.saveToFile(as: image.key + stitchType, fileType: .png, at: self.exportDir)
                //print(succ)
            }
            
            self.exportInProgress += -1
            
            DispatchQueue.main.async {
                if(self.exportInProgress == 0){
                    self.exportIndicator.stopAnimation(self)
                }
                self.filteredImagesButton.isEnabled = true
                NSSound.init(named: "Tink")?.play()
            }
        }
        
    }
    
    @IBAction func saveLayerOutlines(_ sender: Any) {
        exportIndicator.startAnimation(self)
        
        exportInProgress += 1
        outlinesButton.isEnabled = false
        exportDir.createDir()
        
        let layerArray = viewController!.layerController.layers
        
        var layerImages : [String: (NSImage, Int)] = [:]
        
        for layer in layerArray!{
            layerImages[layer.layerTitle.stringValue] = (layer.layerImageView.image!, layer.selectedStitch)
        }
        
        
        exportQ.async {

            for image in layerImages{
                let outlineV = image.value.0.getOutlineVert()
                let outlineH = image.value.0.getOutlineHor()
                
                let outline = outlineH.combineWithImage(refimage: outlineV)
                
                var stitchType = ""
                
                switch image.value.1 {
                case 1:
                    stitchType = " (Single)"
                case 2:
                    stitchType = " (ZigZag)"
                case 3:
                    stitchType = " (Tripple)"
                case 4:
                    stitchType = " (Satin)"
                default:
                    stitchType = ""
                }
            
                _ = outline.saveToFile(as: "Outline " + image.key + stitchType, fileType: .png, at: self.exportDir)
                //_ = outlineV.saveToFile(as: "OutlineV " + image.key, fileType: .png, at: self.exportDir)
                //_ = outlineH.saveToFile(as: "OutlineH " + image.key, fileType: .png, at: self.exportDir)
                
                //print(succ)
            }
            
            self.exportInProgress += -1
            
            DispatchQueue.main.async {
                if(self.exportInProgress == 0){
                    self.exportIndicator.stopAnimation(self)
                }
                self.outlinesButton.isEnabled = true
                NSSound.init(named: "Tink")?.play()
            }
        }
        
    }
    
    
    @IBAction func saveLayerCenterlines(_ sender: Any) {
        
        exportIndicator.startAnimation(self)
        
        exportInProgress += 1
        
        centerlinesButton.isEnabled = false
        exportDir.createDir()
        
        let layerArray = viewController!.layerController.layers
        
        var layerImages : [String: (NSImage, Int)] = [:]
        
        for layer in layerArray!{
            layerImages[layer.layerTitle.stringValue] = (layer.layerImageView.image!,layer.selectedStitch)
        }
        
        
        exportQ.async {
            
            for image in layerImages{
                
                var skelet1 = self.appDel.getSkeletonHOR(image: image.value.0)
                var skelet2 = self.appDel.getSkeletonVERT(image: image.value.0)
                
                skelet1 = self.appDel.optimizeSkeleton(image: skelet1)
                skelet2 = self.appDel.optimizeSkeleton(image: skelet2)
                
                let skelet1Filt = self.appDel.getFilteredComponents(img: skelet1)
                let skelet2Filt = self.appDel.getFilteredComponents(img: skelet2)
                
                let skeletOpt = skelet1Filt.combineWithImage(refimage: skelet2Filt)
                
                var suffix = ""
                
                if(image.value.1 != -1){
                    suffix = "_" + String(image.value.1)
                }
                
                let _ = skeletOpt.saveToFile(as: "Centerline " + image.key + suffix, fileType: .png, at: self.exportDir)
                //print(succ)
            }
            
            self.exportInProgress += -1
            
            DispatchQueue.main.async {
                if(self.exportInProgress == 0){
                    self.exportIndicator.stopAnimation(self)
                }
                self.centerlinesButton.isEnabled = true
                NSSound.init(named: "Tink")?.play()
            }
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        viewController = appDel.windowController?.contentViewController as? AdvancedViewController
        // Do view setup here.
    }
    
}

