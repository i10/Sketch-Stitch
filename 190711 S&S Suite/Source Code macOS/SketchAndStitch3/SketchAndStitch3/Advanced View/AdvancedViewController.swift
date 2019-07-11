import Cocoa

class AdvancedViewController: NSViewController {
    
    var appDel = NSApplication.shared.delegate as! AppDelegate
    
    var redRange: Range = Range(start: 0,end: 255)
    var greenRange: Range = Range(start: 0,end: 255)
    var blueRange: Range = Range(start: 0,end: 255)
    var backupImage: NSImage?
    var unrotatedImage: NSImage?
    var configuration: filterConfig?
    var filterQ: DispatchQueue?
    var rotateQ = DispatchQueue.init(label: "rotateQ")
    let qrQ = DispatchQueue.init(label: "qrQ")
    var mode = "BGR"
    var filtered: NSImage?
    var unSmoothedBackup: NSImage?
    var smoothed: Bool = false
    var placeholderLoaded: Bool = true
    var layerCount: Int = 0
    var presetCount: Int = 0
    var rotationDeg: Int = 0
    let layerController = LayerTableController.init()
    let presetController = PresetTableController.init()
    var combinedImage : NSImage?
    
    @IBOutlet weak var initialImageView: NSImageView!
    @IBOutlet weak var initialImageBorder: NSTextField!
    @IBOutlet weak var initialimageText: NSTextField!
    
    
    var importedPresets : [PresetCell] = []
    
    let maximumLen: CGFloat = 1000
    
    @IBOutlet weak var addPresetButton: NSButton!
    @IBOutlet weak var addLayerButton: NSButton!
    
    var processor : Processor?
    var colProcessor: ColorProcessor?
    var params: FilterParameters = FilterParameters.init(minR: 0, minG: 0, minB: 0, maxR: 1, maxG: 1, maxB: 1)
    var colparams: ColorParameters = ColorParameters.init(R: 1, G: 1, B: 1)
    let memorySize = MemoryLayout<UInt8>.stride
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let renderingIntent = CGColorRenderingIntent.perceptual
    var currentCGImage: CGImage?
    
    @IBOutlet weak var gaussianBlurrMode: NSButton!
    @IBOutlet weak var medianBlurrMode: NSButton!
    @IBOutlet weak var noiseReductionMode: NSButton!
    
    private var filterWork: DispatchWorkItem!
    private let waitQ = DispatchQueue.init(label: "waitQ", qos: .userInteractive)
    
    @IBOutlet weak var mainScrollView: CustomScrollView!
    @IBOutlet weak var mainImageView: NSImageView!
    
    @IBOutlet weak var Slider1: Slider!
    @IBOutlet weak var Slider1Cell: SliderCell!
    
    @IBOutlet weak var Slider2: Slider!
    @IBOutlet weak var Slider2Cell: SliderCell!
    
    @IBOutlet weak var Slider3: Slider!
    @IBOutlet weak var Slider3Cell: SliderCell!
    
    @IBOutlet weak var metricsFooter: NSTextField!
    
    @IBOutlet weak var busyIndicator: NSProgressIndicator!
    
    @IBOutlet var layerView: NSTableView!
    @IBOutlet var presetView: NSTableView!
    @IBOutlet var presetScroll: NSScrollView!
    @IBOutlet var colorCollection: ColorCollection!
    
    
    @IBAction func ImageDragged(_ sender: Any) {
        if(mainImageView.image != nil){
            
            mainImageView.image!.size = NSSize.init(width: mainImageView.image!.representations[0].pixelsWide, height: mainImageView.image!.representations[0].pixelsHigh)
            
            unrotatedImage = mainImageView.image!
            loadImage(image: mainImageView.image!)
        }
        
    }
    
    func createMask(image: NSImage, top: CIQRCodeFeature, bot: CIQRCodeFeature) -> NSImage{
        
        let cgc = CGContext.init(data: nil, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB() , bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        let dist = abs(Int((top.bounds.midY))-Int(bot.bounds.midY))
        
        let rad : CGFloat = CGFloat(dist)/4
        
        let topOvalRect = NSRect.init(x: (top.bounds.midX)-rad, y: (top.bounds.midY)-2.25*rad, width: 2*rad, height: 2*rad)
        
        let botOvalRect = NSRect.init(x: (top.bounds.midX)-rad, y: (bot.bounds.midY)+rad/4, width: 2*rad, height: 2*rad)
        
        let distTopBot = abs(topOvalRect.minY-botOvalRect.minY)
        
        let midRect = NSRect.init(x: botOvalRect.minX, y: botOvalRect.midY, width: 2*rad, height: distTopBot)
        
        cgc?.setFillColor(NSColor.black.cgColor)
        cgc?.fillEllipse(in: topOvalRect)
        cgc?.fillEllipse(in: botOvalRect)
        cgc?.fill(midRect)
        
        let out = cgc!.makeImage()!
        
        let nsOut = NSImage.init(cgImage: out, size: image.size)
        
        return nsOut
        
    }
    
    func applyMask(image: NSImage, mask: NSImage) -> CGImage{
        
        let ciImage = CIImage.init(data: image.tiffRepresentation!)
        let ciMask = CIImage.init(data: mask.tiffRepresentation!)
        
        let context = CIContext(options: nil)
        
        if let currentFilter = CIFilter(name: "CISourceAtopCompositing") {
            currentFilter.setValue(ciImage, forKey: kCIInputImageKey)
            currentFilter.setValue(ciMask, forKey: kCIInputBackgroundImageKey)
            
            if let output = currentFilter.outputImage {
                if let cgimg = context.createCGImage(output, from: output.extent) {
                    return cgimg
                }
            }
        }
        
        return (NSBitmapImageRep.init(data: image.tiffRepresentation!)?.cgImage!)!
        
    }
    
    func crop(cgimg:CGImage, top: CIQRCodeFeature, bot: CIQRCodeFeature) -> NSImage{
        
        let cropRect = CGRect.init(x: CGFloat(0), y: bot.bounds.midY, width: CGFloat(cgimg.width), height: CGFloat(abs(top.bounds.midY-bot.bounds.midY)))
        
        let croppedImg = cgimg.cropping(to: cropRect)
        
        return NSImage.init(cgImage: croppedImg! , size: NSSize.init(width: croppedImg!.width, height: croppedImg!.height))
    }
    
    @IBAction func smoothingChanged(_ sender: Any) {
        if(!placeholderLoaded){
            if(gaussianBlurrMode.integerValue+medianBlurrMode.integerValue+noiseReductionMode.integerValue == 1){
                layerController.layers[layerView.selectedRow].configuration!.Smoothing = (gaussianBlurrMode.integerValue, medianBlurrMode.integerValue, noiseReductionMode.integerValue)
                applyFiltering()
            } else{
                gaussianBlurrMode.integerValue = 0
                medianBlurrMode.integerValue = 0
                noiseReductionMode.integerValue = 0
                layerController.layers[layerView.selectedRow].configuration!.Smoothing = (gaussianBlurrMode.integerValue, medianBlurrMode.integerValue, noiseReductionMode.integerValue)
                smoothed = false
                applyFiltering()
            }
        }
    }
    
    @IBAction func userAddedColor(_ sender: Any) {
        addPreset()
    }
    
    @IBAction func layersChanged(_ sender: Any) {
        
        if(layerController.layers.count > 0){
            
            for layer in layerController.layers{
                layer.selectedMarker.isHidden = true
                
                if(layerCount > 1){
                    layer.deleteButton.isEnabled = true
                    layer.visibleButton.isEnabled = true
                } else{
                    layer.deleteButton.isEnabled = false
                    layer.visibleButton.isEnabled = false
                }
                
            }
            
            mainImageView.image = layerController.layers[layerView.selectedRow].layerImageView.image
            layerController.layers[layerView.selectedRow].selectedMarker.isHidden = false
            
            Slider1.selection.start  = Double(layerController.layers[layerView.selectedRow].configuration!.filterRange1.start)
            Slider2.selection.start  = Double(layerController.layers[layerView.selectedRow].configuration!.filterRange2.start)
            Slider3.selection.start  = Double(layerController.layers[layerView.selectedRow].configuration!.filterRange3.start)
            
            Slider1.selection.end  = Double(layerController.layers[layerView.selectedRow].configuration!.filterRange1.end)
            Slider2.selection.end  = Double(layerController.layers[layerView.selectedRow].configuration!.filterRange2.end)
            Slider3.selection.end  = Double(layerController.layers[layerView.selectedRow].configuration!.filterRange3.end)
            
            gaussianBlurrMode.integerValue = layerController.layers[layerView.selectedRow].configuration!.Smoothing.0
            medianBlurrMode.integerValue = layerController.layers[layerView.selectedRow].configuration!.Smoothing.1
            noiseReductionMode.integerValue = layerController.layers[layerView.selectedRow].configuration!.Smoothing.2
            
            Slider1Cell.doubleValue = Slider1.selection.start
            Slider1Cell.secondKnobValue = Slider1.selection.end
            
            Slider2Cell.doubleValue = Slider2.selection.start
            Slider2Cell.secondKnobValue = Slider2.selection.end
            
            Slider3Cell.doubleValue = Slider3.selection.start
            Slider3Cell.secondKnobValue = Slider3.selection.end
            
            colorCollection.deselectAll(self)
            
            if(layerController.layers[layerView.selectedRow].coloringNumber != -1){
                let index = IndexPath.init(item: layerController.layers[layerView.selectedRow].coloringNumber, section: 0)
                colorCollection.selectItems(at: [index], scrollPosition: .centeredVertically)
                
            }
            
            Slider1.setNeedsDisplay()
            Slider2.setNeedsDisplay()
            Slider3.setNeedsDisplay()
            
            movedSlider(self)
        }
    }
    
    @IBAction func presetsChanged(_ sender: Any) {
        if(presetController.presets.count > 0){
            
            Slider1.selection.start = Double(presetController.presets[presetView.selectedRow].filterConfig!.filterRange1.start)
            Slider1.selection.end = Double(presetController.presets[presetView.selectedRow].filterConfig!.filterRange1.end)
            
            Slider2.selection.start = Double(presetController.presets[presetView.selectedRow].filterConfig!.filterRange2.start)
            Slider2.selection.end = Double(presetController.presets[presetView.selectedRow].filterConfig!.filterRange2.end)
            
            Slider3.selection.start = Double(presetController.presets[presetView.selectedRow].filterConfig!.filterRange3.start)
            Slider3.selection.end = Double(presetController.presets[presetView.selectedRow].filterConfig!.filterRange3.end)
            
            gaussianBlurrMode.integerValue = presetController.presets[presetView.selectedRow].filterConfig!.Smoothing.0
            medianBlurrMode.integerValue = presetController.presets[presetView.selectedRow].filterConfig!.Smoothing.1
            noiseReductionMode.integerValue = presetController.presets[presetView.selectedRow].filterConfig!.Smoothing.2
            
            Slider1Cell.doubleValue = Slider1.selection.start
            Slider1Cell.secondKnobValue = Slider1.selection.end
            
            Slider2Cell.doubleValue = Slider2.selection.start
            Slider2Cell.secondKnobValue = Slider2.selection.end
            
            Slider3Cell.doubleValue = Slider3.selection.start
            Slider3Cell.secondKnobValue = Slider3.selection.end
            
            let newColor = presetController.presets[presetView.selectedRow].selectionMarker.backgroundColor!
            layerController.layers[layerView.selectedRow].selectedMarker.backgroundColor = newColor
            
            Slider1.setNeedsDisplay()
            Slider2.setNeedsDisplay()
            Slider3.setNeedsDisplay()
            
            movedSlider(self)
        }
    }
    
    @IBAction func removeFilters(_ sender: Any) {
       
        if(!placeholderLoaded){
            let smth = self.layerController.layers[self.layerView.selectedRow].configuration!.Smoothing
            
            self.layerController.layers[self.layerView.selectedRow].configuration = filterConfig.init(filterRange1: Range.init(start: 0, end: 255), filterRange2: Range.init(start: 0, end: 255), filterRange3: Range.init(start: 0, end: 255), Smoothing: smth)
            
            Slider1Cell.doubleValue = Slider1.minValue
            Slider1Cell.secondKnobValue = Slider1.maxValue
            Slider1.selection.start = Slider1.minValue
            Slider1.selection.end = Slider1.maxValue
            
            Slider2Cell.doubleValue = Slider2.minValue
            Slider2Cell.secondKnobValue = Slider2.maxValue
            Slider2.selection.start = Slider2.minValue
            Slider2.selection.end = Slider2.maxValue
            
            Slider3Cell.doubleValue = Slider3.minValue
            Slider3Cell.secondKnobValue = Slider3.maxValue
            Slider3.selection.start = Slider3.minValue
            Slider3.selection.end = Slider3.maxValue
            
            Slider3Cell.refBlue = Slider1.getRef()
            Slider3Cell.refGreen = Slider2.getRef()
            
            Slider2Cell.refRed = Slider3.getRef()
            Slider2Cell.refBlue = Slider1.getRef()
            
            Slider1Cell.refGreen = Slider2.getRef()
            Slider1Cell.refRed = Slider3.getRef()
            
            presetView.selectRowIndexes(IndexSet.init(integer: (presetController.presets.count-1)), byExtendingSelection: false)
            applyFiltering()
            
        
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        presetScroll.backgroundColor = NSColor.black.withAlphaComponent(0.2)
        initSliders(colorArr: appDel.colorArray)
        initImageView()
        initQ()
        self.view.becomeFirstResponder()
        layerView.delegate = layerController
        layerView.dataSource = layerController
        presetView.delegate = presetController
        presetView.dataSource = presetController
        self.colorCollection.dataSource = colorCollection
        self.colorCollection.reloadData()
        self.processor = try! Processor.init()
        self.colProcessor = try! ColorProcessor.init()
        colorCollection.isEnabled = false
        initPresetTable()
        
        let importDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Sketch And Stitch")
        
        if(FileManager.default.fileExists(atPath: importDir.appendingPathComponent("PresetData").path)){
            loadPresets()
            
            for loadedPreset in importedPresets{
                presetController.presets!.append(loadedPreset)
            }
            
            presetCount += importedPresets.count
            
            presetView.reloadData()
            
        }
        
        for entry in presetController.presets!{
            print(entry.presetName.stringValue)
        }
        
        loadImage(image: NSImage.init(named: "Placeholder")!)
        
    }
    
    func loadPresets(){
        let importDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Sketch And Stitch")
        
        var importedData :Data = Data.init()
        
        importedData = try! Data.init(contentsOf: importDir.appendingPathComponent("PresetData"))
        
        if(!importedData.isEmpty){
            let loadedPresets = (NSKeyedUnarchiver.unarchiveObject(with: importedData)) as? [PresetData]
            
            for loadedPreset in loadedPresets!{
                
                let newPreset = presetView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "presetCell"), owner: presetController) as! PresetCell
                
                newPreset.presetName.stringValue = loadedPreset.name
                
                let color = NSColor.init(calibratedRed: CGFloat(loadedPreset.low3+loadedPreset.high3)/510, green: CGFloat(loadedPreset.low2+loadedPreset.high2)/510, blue: CGFloat(loadedPreset.low1+loadedPreset.high1)/510, alpha: 1)
                
                newPreset.selectionMarker.backgroundColor = color
                
                let range1 = Range.init(start: loadedPreset.low1, end: loadedPreset.high1)
                let range2 = Range.init(start: loadedPreset.low2, end: loadedPreset.high2)
                let range3 = Range.init(start: loadedPreset.low3, end: loadedPreset.high3)
                
                let currentConfig = filterConfig.init(filterRange1:range1 , filterRange2: range2, filterRange3: range3, Smoothing: (loadedPreset.gaus, loadedPreset.median, loadedPreset.noise))
                
                newPreset.filterConfig = currentConfig
                
                importedPresets.append(newPreset)
                
            }
        }
    }
    
    @IBAction func addLayer(_ sender: Any) {
        if(!placeholderLoaded){
            
            addLayerButton.isEnabled = false
            
            layerView.beginUpdates()
            
            let newLayer = layerView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "layerCell"), owner: layerView) as! LayerCell
            
            colorCollection.deselectAll(self)
            
            layerCount = layerCount+1
            
            newLayer.layerTitle.stringValue = "Layer " + String(layerCount)
            newLayer.layerImageView.image = backupImage
            
            let range1 = Range.init(start: 0, end: Int(Slider1!.maxValue))
            let range2 = Range.init(start: 0, end: Int(Slider2!.maxValue))
            let range3 = Range.init(start: 0, end: Int(Slider3!.maxValue))
            
            
            let baseConfig = filterConfig.init(filterRange1:range1 , filterRange2: range2, filterRange3: range3, Smoothing: (0, 0, 0))
            
            newLayer.configuration = baseConfig
            configuration = baseConfig
            
            layerView.deselectAll(self)
            layerView.selectRowIndexes(IndexSet.init(integer: 0), byExtendingSelection: false)
            
            layerController.layers!.insert(newLayer, at: 0)
            layerView.endUpdates()
            layerView.reloadData()
            layersChanged(self)
            
            addLayerButton.isEnabled = true
            
        }
    }
    
    func addPreset(){
        
        if(!placeholderLoaded){
            
            addPresetButton.isEnabled = false
            
            presetView.beginUpdates()
            
            let newPreset = presetView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "presetCell"), owner: presetController) as! PresetCell
            
            presetCount = presetCount+1
            
            newPreset.presetName.stringValue = "Color Filter " + String(presetCount-1)
            
            let color = NSColor.init(calibratedRed: CGFloat(Slider3.getRef())/255, green: CGFloat(Slider2.getRef())/255, blue: CGFloat(Slider1.getRef())/255, alpha: 1)
            
            newPreset.selectionMarker.backgroundColor = color
            
            let range1 = Range.init(start: Int(Slider1.selection.start), end: Int(Slider1.selection.end))
            let range2 = Range.init(start: Int(Slider2.selection.start), end: Int(Slider2.selection.end))
            let range3 = Range.init(start: Int(Slider3.selection.start), end: Int(Slider3.selection.end))
            
            let currentConfig = filterConfig.init(filterRange1:range1 , filterRange2: range2, filterRange3: range3, Smoothing: (0, 0, 0))
            
            newPreset.filterConfig = currentConfig
            
            newPreset.filterConfig!.Smoothing.0 = gaussianBlurrMode.integerValue
            newPreset.filterConfig!.Smoothing.1 = medianBlurrMode.integerValue
            newPreset.filterConfig!.Smoothing.2 = noiseReductionMode.integerValue
            
            presetController.presets!.append(newPreset)
            
            presetView.deselectAll(self)
            presetView.selectRowIndexes(IndexSet.init(integer: (presetController.presets.count-1)), byExtendingSelection: false)
            
            presetView.endUpdates()
            presetView.reloadData()
            presetsChanged(self)
            
            addPresetButton.isEnabled = true
            
        }
    }
    
    @IBAction func deselectColoring(_ sender: Any) {
        if(colorCollection.isEnabled){
            colorCollection.deselectAll(sender)
            layerController.layers[layerView.selectedRow].coloringNumber = -1
            applyFiltering()
        }
        
    }
    
    
    func coloringChanged(){
        
        if(!placeholderLoaded){
            let coloringStatus = colorCollection.selectionIndexes.last
            
            if(coloringStatus != nil){
                let coloringNumber = abs((coloringStatus?.distance(to: 0))!)
                layerController.layers[layerView.selectedRow].coloringNumber = coloringNumber
            } else{
                layerController.layers[layerView.selectedRow].coloringNumber = -1
            }
            
            applyFiltering()
        }
    }
    
    
    @IBAction func drawMainImage(_ sender: Any){
        
        if(layerCount > 0){
            if(layerCount > 1){
                let currentLayers = layerController.layers
                
                let c = currentLayers!.count-1
                
                var tempimage: CIImage?
                var atLeastVisible = false
                
                for i in 0...c{
                    if(currentLayers![c-i].visible){
                        
                        tempimage = CIImage.init(data: currentLayers![c-i].layerImageView.image!.tiffRepresentation!)!
                        
                        var currentFilter: CIFilter?
                        
                        if((currentLayers![c-i].configuration?.Smoothing.0)! > 0){
                            currentFilter = CIFilter(name: "CIGaussianBlur")!
                            currentFilter!.setValue(tempimage, forKey: kCIInputImageKey)
                            currentFilter!.setValue(0.5, forKey: kCIInputRadiusKey)
                            tempimage = currentFilter!.outputImage
                        }
                        
                        if((currentLayers![c-i].configuration?.Smoothing.1)! > 0){
                            currentFilter = CIFilter(name: "CIMedianFilter")!
                            currentFilter!.setValue(tempimage, forKey: kCIInputImageKey)
                            tempimage = currentFilter!.outputImage
                        }
                        
                        if((currentLayers![c-i].configuration?.Smoothing.2)! > 0){
                            currentFilter = CIFilter(name: "CINoiseReduction")!
                            currentFilter!.setValue(tempimage, forKey: kCIInputImageKey)
                            tempimage = currentFilter!.outputImage
                        }
                        
                        
                        atLeastVisible = true
                        break
                    }
                }
                
                if(atLeastVisible){
                    let filter = CIFilter(name: "CISourceOverCompositing")!
                    filter.setDefaults()
                    
                    for i in 1...c{
                        if(currentLayers![c-i].visible){
                            
                            var currImage = CIImage.init(data: currentLayers![c-i].layerImageView.image!.tiffRepresentation!)
                            
                            var currentFilter: CIFilter?
                            
                            if((currentLayers![c-i].configuration?.Smoothing.0)! > 0){
                                currentFilter = CIFilter(name: "CIGaussianBlur")!
                                currentFilter!.setValue(currImage, forKey: kCIInputImageKey)
                                currentFilter!.setValue(0.5, forKey: kCIInputRadiusKey)
                                currImage = currentFilter!.outputImage
                            }
                            
                            if((currentLayers![c-i].configuration?.Smoothing.1)! > 0){
                                currentFilter = CIFilter(name: "CIMedianFilter")!
                                currentFilter!.setValue(currImage, forKey: kCIInputImageKey)
                                currImage = currentFilter!.outputImage
                            }
                            
                            if((currentLayers![c-i].configuration?.Smoothing.2)! > 0){
                                currentFilter = CIFilter(name: "CINoiseReduction")!
                                currentFilter!.setValue(currImage, forKey: kCIInputImageKey)
                                currImage = currentFilter!.outputImage
                            }
                            
                            
                            filter.setValue(currImage, forKey: "inputImage")
                            filter.setValue(tempimage, forKey: "inputBackgroundImage")
                            tempimage = filter.outputImage!
                        }
                    }
                    
                    let context = CIContext(options: nil)
                    let cgImage = context.createCGImage(tempimage!, from: tempimage!.extent)
                    let combinedImage = NSImage.init(cgImage: cgImage!, size: currentLayers![0].layerImageView.image!.size)
                    self.combinedImage = combinedImage

                } else{
                    self.combinedImage = NSImage.init(named: "Placeholder")
                }
                
            }else{
                self.combinedImage = NSImage.init(named: "Placeholder")
            }
        }
    }
    
    func adjustSize(image :NSImage)->NSImage{
        
        let maximumLen: CGFloat = 1000
        var res :NSImage = image.copy() as! NSImage
        
        if(Int(res.size.width) > Int(maximumLen) || Int(res.size.height) > Int(maximumLen)){
            
            let largestSide = max(Int(res.size.width), Int(res.size.height))
            
            if(Int(res.size.width) == largestSide){
                let factor = Double(maximumLen/res.size.width)
                let newHeight = Int((factor*Double(res.size.height)).rounded())
                
                res = res.resize(img: res, w: Int(maximumLen), h: newHeight)
                
            } else{
                let factor = Double(maximumLen/res.size.height)
                let newWidth = Int((factor*Double(res.size.width)).rounded())
                
                res = res.resize(img: res, w: newWidth, h: Int(maximumLen))
                
            }
        }
        
        return res
    }
    
    @IBAction func rotateImageLeft(_ sender: Any) {
        rotateImage(image: self.unrotatedImage!, degree: -90, auto: false)
    }
    
    @IBAction func rotateImageLeftSmall(_ sender: Any) {
        rotateImage(image: self.unrotatedImage!, degree: -5, auto: false)
    }
    
    @IBAction func rotateImageRight(_ sender: Any) {
        rotateImage(image: self.unrotatedImage!, degree: 90, auto: false)
    }
    
    @IBAction func rotateRightSmall(_ sender: Any) {
        rotateImage(image: self.unrotatedImage!, degree: 5, auto: false)
    }
    
    
    @IBAction func autoOrientation(_ sender: Any) {
        var fixDegree = 0
        rotateQ.async {
            fixDegree = self.appDel.fixRotation(image: self.unrotatedImage!)
        }
        //print(fixDegree)
        self.rotationDeg = 0
        rotateImage(image: self.unrotatedImage!, degree: fixDegree, auto: true)
        
        let markers = appDel.detectQR(image: self.unrotatedImage!)
        var top :CIQRCodeFeature?
        var bot :CIQRCodeFeature?
        
        if(markers.count == 2){
            
            for marker in markers{
                if((marker.messageString?.contains("1"))!){
                    top = marker
                } else{
                    bot = marker
                }
            }
            
            let workImage = self.unrotatedImage!
            
            qrQ.async {
                let mask = self.createMask(image: workImage, top: top!, bot: bot!)
                
                let maskedHoop = self.applyMask(image: workImage, mask: mask)
                
                let cropped = self.crop(cgimg: maskedHoop, top: top!, bot: bot!)
                
                DispatchQueue.main.async {
                    self.initImageView()
                    self.loadImage(image: cropped)
                }
            }
        }
    }
    
    func rotateImage(image:NSImage, degree: Int, auto: Bool){
        busyIndicator.startAnimation(self)
        rotateQ.async{
            if(!self.placeholderLoaded){
                self.rotationDeg += degree
                
                if(abs(self.rotationDeg) >= 360){
                    if(self.rotationDeg > 0){
                        self.rotationDeg += -360
                    }
                    if(self.rotationDeg < 0){
                        self.rotationDeg += 360
                    }
                }
                
                let rotated = self.appDel.rotateByDegrees(image: self.unrotatedImage!, degree: self.rotationDeg)
                DispatchQueue.main.async {
                    
                    if(auto){
                        self.unrotatedImage = rotated
                        self.rotationDeg = 0
                    }
                    
                    self.loadRotatedImage(image: rotated)
                    self.busyIndicator.stopAnimation(self)
                    self.movedSlider(self)
                }
            }
        }
    }
    
    func applyFiltering() {
        
        if(!placeholderLoaded){
            
            self.filterWork?.cancel()
            
            busyIndicator.startAnimation(1)
            
            let layerConfig = self.layerController.layers[self.layerView.selectedRow].configuration
            let smoothState = self.gaussianBlurrMode.integerValue + self.medianBlurrMode.integerValue + self.noiseReductionMode.integerValue
            let selectedRow = self.layerView.selectedRow
            
            let coloringNumber = self.layerController.layers[self.layerView.selectedRow].coloringNumber
            
            if(coloringNumber != -1){
                let nsC = NSColor.init(cgColor: (colorCollection.colors[coloringNumber]).color!)!
                self.colparams.B = Float(nsC.blueComponent)
                self.colparams.G = Float(nsC.greenComponent)
                self.colparams.R = Float(nsC.redComponent)
            }
            
            filterWork = DispatchWorkItem{
                
                //let start = CGFloat(DispatchTime.now().uptimeNanoseconds)
                self.params = FilterParameters.init(minR: Float((layerConfig?.filterRange3.start)!)/255, minG: Float((layerConfig?.filterRange2.start)!)/255, minB: Float((layerConfig?.filterRange1.start)!)/255, maxR: Float((layerConfig?.filterRange3.end)!)/255, maxG: Float((layerConfig?.filterRange2.end)!)/255, maxB: Float((layerConfig?.filterRange1.end)!)/255)
                
                self.filtered =  self.applyGPUFiltering(image: self.currentCGImage!)
                
                //let end = CGFloat(DispatchTime.now().uptimeNanoseconds)
                //print((end-start)/1000000000)
                
                self.waitQ.async {
                    self.unSmoothedBackup = self.filtered
                    self.smoothed = false
                    
                    if( smoothState == 1){
                        self.filtered = self.applySmoothing(image: self.unSmoothedBackup!)
                        self.smoothed = true
                    }
                    
                    if(coloringNumber != -1){
                        
                        let currCGI = NSBitmapImageRep.init(data: self.filtered!.tiffRepresentation!)?.cgImage
                        
                        self.filtered = self.applyGPUColoring(image: currCGI!)
                    }
                    
                    DispatchQueue.main.async {
                        
                        self.busyIndicator.stopAnimation(1)
                        self.filterWork?.cancel()
                        
                        self.mainImageView.image = self.filtered
                        self.layerController.layers[selectedRow].layerImageView.image = self.mainImageView.image
                        self.mainImageView.mouseUp(with: NSEvent.init())
                    }
                }
            }
            
            filterQ!.async(execute: filterWork)
            
            
            
        }
        
    }
    
    func applyGPUFiltering(image: CGImage) -> NSImage{
        
        let outtexture = try! processor!.run(input: image, parameters: params)
        
        let pixelFormat = PixelFormat.init(pixelFormat: outtexture.pixelFormat)
        let region = MTLRegionMake2D(0, 0, outtexture.width, outtexture.height)
        
        let capacity = outtexture.width * outtexture.height * pixelFormat.bitsPerPixel / memorySize
        
        let bytesPerRow = pixelFormat.bitsPerPixel / memorySize * outtexture.width
        var imageBytes = Array<UInt8>(repeating: 0, count: capacity)
        
        outtexture.getBytes(&imageBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let provider = CGDataProvider(data: NSData(bytes: &imageBytes, length: imageBytes.count * memorySize))
        
        let bitmap = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        
        let imageReference = CGImage(
            width: outtexture.width,
            height: outtexture.height,
            bitsPerComponent: pixelFormat.bitsPerComponent,
            bitsPerPixel: pixelFormat.bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmap,
            provider: provider!,
            decode: nil,
            shouldInterpolate: false,
            intent: renderingIntent
        )
        
        return NSImage.init(cgImage: imageReference!, size: NSSize.init(width: outtexture.width, height: outtexture.height))
        
    }
    
    func applyGPUColoring(image: CGImage) -> NSImage{
        
        let outtexture = try! colProcessor!.run(input: image, parameters: colparams)
        
        let pixelFormat = PixelFormat.init(pixelFormat: outtexture.pixelFormat)
        let region = MTLRegionMake2D(0, 0, outtexture.width, outtexture.height)
        
        let capacity = outtexture.width * outtexture.height * pixelFormat.bitsPerPixel / memorySize
        
        let bytesPerRow = pixelFormat.bitsPerPixel / memorySize * outtexture.width
        var imageBytes = Array<UInt8>(repeating: 0, count: capacity)
        
        outtexture.getBytes(&imageBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let provider = CGDataProvider(data: NSData(bytes: &imageBytes, length: imageBytes.count * memorySize))
        
        let bitmap = CGBitmapInfo(rawValue: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue)
        
        let imageReference = CGImage(
            width: outtexture.width,
            height: outtexture.height,
            bitsPerComponent: pixelFormat.bitsPerComponent,
            bitsPerPixel: pixelFormat.bitsPerPixel,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmap,
            provider: provider!,
            decode: nil,
            shouldInterpolate: false,
            intent: renderingIntent
        )
        
        return NSImage.init(cgImage: imageReference!, size: NSSize.init(width: outtexture.width, height: outtexture.height))
        
    }
    
    func applySmoothing(image: NSImage) -> NSImage{
        
        var gaus = 0
        var median = 0
        var noise = 0
        
        DispatchQueue.main.async {
            if(self.gaussianBlurrMode.integerValue+self.medianBlurrMode.integerValue+self.noiseReductionMode.integerValue == 1){
                self.smoothed = false
                gaus = self.gaussianBlurrMode.integerValue
                median = self.medianBlurrMode.integerValue
                noise = self.noiseReductionMode.integerValue
            }
        }
        
        if(!placeholderLoaded){
            if(!smoothed){
                
                smoothed = true
                
                let context = CIContext(options: nil)
                let beginImage = CIImage.init(cgImage: NSBitmapImageRep.init(data: image.tiffRepresentation!)!.cgImage! )
                
                var currentFilter: CIFilter?
                
                if(gaus > 0){
                    currentFilter = CIFilter(name: "CIGaussianBlur")!
                    currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
                    currentFilter!.setValue(0.5, forKey: kCIInputRadiusKey)
                }
                
                if(median > 0){
                    currentFilter = CIFilter(name: "CIMedianFilter")!
                    currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
                }
                
                if(noise > 0){
                    currentFilter = CIFilter(name: "CINoiseReduction")!
                    currentFilter!.setValue(beginImage, forKey: kCIInputImageKey)
                }
                
                var processedImage :NSImage?
                
                if(gaus+median+noise == 1){
                    if let output = currentFilter!.outputImage {
                        if let cgimg = context.createCGImage(output, from: output.extent) {
                            processedImage = NSImage(cgImage: cgimg, size: (image.size))
                        }
                    }
                } else{
                    processedImage = image
                }
                
                return processedImage!
                
            } else{
                smoothed = false
                DispatchQueue.main.async {
                    self.gaussianBlurrMode.integerValue = 0
                    self.medianBlurrMode.integerValue = 0
                    self.noiseReductionMode.integerValue = 0
                }
                return unSmoothedBackup!
            }
        }
        
        return image
        
    }
    
    @IBAction func movedSlider(_ sender: Any) {
        
        if(!placeholderLoaded){
            
            //presetView.selectRowIndexes(IndexSet.init(integer: 0), byExtendingSelection: false)
            
            let color = NSColor.init(calibratedRed: CGFloat(Slider3.getRef())/255, green: CGFloat(Slider2.getRef())/255, blue: CGFloat(Slider1.getRef())/255, alpha: 1)
            
            presetController.presets[presetView.selectedRow].selectionMarker.backgroundColor = color
            
            presetView.reloadData()
            
            Slider3Cell.refBlue = Slider1.getRef()
            Slider3Cell.refGreen = Slider2.getRef()
            
            Slider2Cell.refRed = Slider3.getRef()
            Slider2Cell.refBlue = Slider1.getRef()
            
            Slider1Cell.refGreen = Slider2.getRef()
            Slider1Cell.refRed = Slider3.getRef()
            
            blueRange.start = Int(Slider1.selection.start)
            blueRange.end = Int(Slider1.selection.end)
            
            greenRange.start = Int(Slider2.selection.start)
            greenRange.end = Int(Slider2.selection.end)
            
            redRange.start = Int(Slider3.selection.start)
            redRange.end = Int(Slider3.selection.end)
            
            layerController.layers[layerView.selectedRow].configuration = filterConfig.init(filterRange1:blueRange , filterRange2: greenRange, filterRange3: redRange, Smoothing: (gaussianBlurrMode.integerValue, medianBlurrMode.integerValue, noiseReductionMode.integerValue))
            
            configuration = layerController.layers[layerView.selectedRow].configuration
            
            let event = self.view.window?.currentEvent
            
            if(event!.type.rawValue == 2){
                applyFiltering()
            }
        }
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    func initSliders(colorArr: ContiguousArray<ContiguousArray<ContiguousArray<NSColor>>> = []){
        
        Slider1Cell.gradient = colorArr
        Slider2Cell.gradient = colorArr
        Slider3Cell.gradient = colorArr
        
        Slider1Cell.cellType = "Blue"
        
        Slider1.maxValue = 255
        Slider1Cell.secondKnobValue = Slider1.maxValue
        
        Slider1.selection.start = Slider1.minValue
        Slider1.selection.end = Slider1.maxValue
        
        Slider2Cell.cellType = "Green"
        
        Slider2.maxValue = 255
        Slider2Cell.secondKnobValue = Slider2.maxValue
        
        Slider2.selection.start = Slider2.minValue
        Slider2.selection.end = Slider2.maxValue
        
        Slider3Cell.cellType = "Red"
        Slider3.maxValue = 255
        Slider3Cell.secondKnobValue = Slider3.maxValue
        
        Slider3.selection.start = Slider3.minValue
        Slider3.selection.end = Slider3.maxValue
        
        Slider1.refSlider1 = Slider2
        Slider1.refSlider2 = Slider3
        
        Slider2.refSlider1 = Slider1
        Slider2.refSlider2 = Slider3
        
        Slider3.refSlider1 = Slider1
        Slider3.refSlider2 = Slider2
        
        blueRange.start = Int(Slider1.selection.start)
        blueRange.end = Int(Slider1.selection.end)
        
        greenRange.start = Int(Slider2.selection.start)
        greenRange.end = Int(Slider2.selection.end)
        
        redRange.start = Int(Slider3.selection.start)
        redRange.end = Int(Slider3.selection.end)
        
        configuration = filterConfig.init(filterRange1:blueRange , filterRange2: greenRange, filterRange3: redRange, Smoothing: (gaussianBlurrMode.integerValue, medianBlurrMode.integerValue, noiseReductionMode.integerValue))
        
    }
    
    func initImageView(){
        
        mainImageView.wantsLayer = true
        
        let imageRect = NSMakeRect(0.0, 0.0, mainScrollView.bounds.width, mainScrollView.bounds.height)
        
        mainImageView.setFrameSize(CGSize(width: imageRect.width, height: imageRect.height))
        
        mainImageView.layer!.magnificationFilter = CALayerContentsFilter.nearest
        mainImageView.layer!.minificationFilter = CALayerContentsFilter.nearest
        mainImageView.layer!.shouldRasterize = false
        
        mainImageView.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
        mainScrollView.magnification = 1.0
        mainScrollView.documentView = mainImageView
        mainScrollView.hasVerticalScroller = false
        mainScrollView.hasHorizontalScroller = false
        
        mainImageView.isEditable = true
        
    }
    
    func initQ(){
        self.filterQ = DispatchQueue.init(label: "filterQ", qos: .userInteractive)
    }
    
    func initPresetTable(){
        
        presetCount = 1
        presetController.presets!.append(presetView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "presetCell"), owner: presetController) as! PresetCell)
        
        presetController.presets[0].presetName.stringValue = "New Color Filter"
        presetController.presets[0].presetName.isEditable = false
        presetController.presets[0].presetName.isSelectable = false
        presetController.presets[0].deleteButton.isEnabled = false
        presetController.presets[0].deleteButton.isHidden = true
        presetController.presets[0].selectionMarker.isHidden = false
        presetController.presets[0].spectrumView.isHidden = false
        
        let color = NSColor.init(calibratedRed: CGFloat(Slider3.getRef())/255, green: CGFloat(Slider2.getRef())/255, blue: CGFloat(Slider1.getRef())/255, alpha: 1)
        
        presetController.presets[0].selectionMarker.backgroundColor = color
        
        presetView.selectRowIndexes(IndexSet.init(integer: 0), byExtendingSelection: false)
        
        let range1 = Range.init(start: Int(Slider1.selection.start), end: Int(Slider1.selection.end))
        let range2 = Range.init(start: Int(Slider2.selection.start), end: Int(Slider2.selection.end))
        let range3 = Range.init(start: Int(Slider3.selection.start), end: Int(Slider3.selection.end))
        
        
        let currentConfig = filterConfig.init(filterRange1:range1 , filterRange2: range2, filterRange3: range3, Smoothing: (0, 0, 0))
        
        presetController.presets![0].filterConfig = currentConfig
        
        presetView.reloadData()
    }
    
    func loadImage(image: NSImage){
        
        if(image.tiffRepresentation != nil){
            
            //mainImageView.brushes.removeAll()
            unrotatedImage = image
            
            self.initialImageView.image = image
            
            rotationDeg = 0
            Slider1.selection.start = Slider1.minValue
            Slider1.selection.end = Slider1.maxValue
            
            Slider2.selection.start = Slider2.minValue
            Slider2.selection.end = Slider2.maxValue
            
            Slider3.selection.start = Slider3.minValue
            Slider3.selection.end = Slider3.maxValue
            
            blueRange.start = Int(Slider1.selection.start)
            blueRange.end = Int(Slider1.selection.end)
            
            greenRange.start = Int(Slider2.selection.start)
            greenRange.end = Int(Slider2.selection.end)
            
            redRange.start = Int(Slider3.selection.start)
            redRange.end = Int(Slider3.selection.end)
            
            Slider3Cell.refBlue = Slider1.getRef()
            Slider3Cell.refGreen = Slider2.getRef()
            
            Slider2Cell.refRed = Slider3.getRef()
            Slider2Cell.refBlue = Slider1.getRef()
            
            Slider1Cell.refGreen = Slider2.getRef()
            Slider1Cell.refRed = Slider3.getRef()
            
            Slider1Cell.doubleValue = 0
            Slider1Cell.secondKnobValue = Slider1.maxValue
            
            Slider2Cell.doubleValue = 0
            Slider2Cell.secondKnobValue = Slider2.maxValue
            
            Slider3Cell.doubleValue = 0
            Slider3Cell.secondKnobValue = Slider3.maxValue
            
            smoothed = false
            gaussianBlurrMode.integerValue = 0
            medianBlurrMode.integerValue = 0
            noiseReductionMode.integerValue = 0
            
            configuration = filterConfig.init(filterRange1:blueRange , filterRange2: greenRange, filterRange3: redRange, Smoothing: (gaussianBlurrMode.integerValue, medianBlurrMode.integerValue, noiseReductionMode.integerValue))
            
            Slider1.setNeedsDisplay()
            Slider2.setNeedsDisplay()
            Slider3.setNeedsDisplay()
            
            colorCollection.deselectAll(self)
            
            var inputimage = image
            
            if(Int(inputimage.size.width) > Int(maximumLen) || Int(inputimage.size.height) > Int(maximumLen)){
                
                let largestSide = max(Int(inputimage.size.width), Int(inputimage.size.height))
                
                if(Int(inputimage.size.width) == largestSide){
                    let factor = Double(maximumLen/inputimage.size.width)
                    let newHeight = Int((factor*Double(inputimage.size.height)).rounded())
                    
                    inputimage = inputimage.resize(img: inputimage, w: Int(maximumLen), h: newHeight)
                    
                } else{
                    let factor = Double(maximumLen/inputimage.size.height)
                    let newWidth = Int((factor*Double(inputimage.size.width)).rounded())
                    
                    inputimage = inputimage.resize(img: inputimage, w: newWidth, h: Int(maximumLen))
                    
                }
            }
            
            let cgc = CGContext.init(data: nil, width: Int(inputimage.size.width), height: Int(inputimage.size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB() , bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            
            cgc!.draw((NSBitmapImageRep.init(data: inputimage.tiffRepresentation!)?.cgImage)!, in: CGRect(x: 0, y: 0, width: (cgc?.width)!, height: (cgc?.height)!))
            
            inputimage = NSImage.init(cgImage: (cgc?.makeImage())!, size: inputimage.size)
            
            mainImageView.image = inputimage
            backupImage = inputimage
            unSmoothedBackup = backupImage
            currentCGImage = NSBitmapImageRep.init(data: inputimage.tiffRepresentation!)!.cgImage!
            
            if(image != NSImage.init(named: "Placeholder")){
                placeholderLoaded = false
                metricsFooter.stringValue = (backupImage?.getImageMetrics())!
                (self.view.window?.windowController as! WindowController).exportButton.isEnabled = true
                (self.view.window?.windowController as! WindowController).compareButton.alphaValue = 0
                (self.view.window?.windowController as! WindowController).eraserButton.alphaValue = 0
                (self.view.window?.windowController as! WindowController).compareButton.isEnabled = true
                (self.view.window?.windowController as! WindowController).compareButton.isHidden = false
                (self.view.window?.windowController as! WindowController).eraserButton.isHidden = false
                (self.view.window?.windowController as! WindowController).eraserButton.isEnabled = true
                (self.view.window?.windowController as! WindowController).convertButton.isEnabled = true
                
                (self.view.window?.windowController as! WindowController).compareButton.animator().alphaValue = 1
                (self.view.window?.windowController as! WindowController).eraserButton.animator().alphaValue = 1
                
                self.initialImageView.isHidden = false
                self.initialimageText.isHidden = false
                self.initialImageBorder.isHidden = false
                
                mainImageView.mouseUp(with: NSEvent.init())
                
                colorCollection.isEnabled = true
            }
            
            layerController.layers.removeAll()
            layerCount = 0
            addLayer(1)
            movedSlider(1)
            
        }
    }
    
    func loadRotatedImage(image: NSImage){
        
        if(image.tiffRepresentation != nil){
            
            //mainImageView.brushes.removeAll()
            Slider1.selection.start = Slider1.minValue
            Slider1.selection.end = Slider1.maxValue
            
            Slider2.selection.start = Slider2.minValue
            Slider2.selection.end = Slider2.maxValue
            
            Slider3.selection.start = Slider3.minValue
            Slider3.selection.end = Slider3.maxValue
            
            blueRange.start = Int(Slider1.selection.start)
            blueRange.end = Int(Slider1.selection.end)
            
            greenRange.start = Int(Slider2.selection.start)
            greenRange.end = Int(Slider2.selection.end)
            
            redRange.start = Int(Slider3.selection.start)
            redRange.end = Int(Slider3.selection.end)
            
            Slider3Cell.refBlue = Slider1.getRef()
            Slider3Cell.refGreen = Slider2.getRef()
            
            Slider2Cell.refRed = Slider3.getRef()
            Slider2Cell.refBlue = Slider1.getRef()
            
            Slider1Cell.refGreen = Slider2.getRef()
            Slider1Cell.refRed = Slider3.getRef()
            
            Slider1Cell.doubleValue = 0
            Slider1Cell.secondKnobValue = Slider1.maxValue
            
            Slider2Cell.doubleValue = 0
            Slider2Cell.secondKnobValue = Slider2.maxValue
            
            Slider3Cell.doubleValue = 0
            Slider3Cell.secondKnobValue = Slider3.maxValue
            
            smoothed = false
            gaussianBlurrMode.integerValue = 0
            medianBlurrMode.integerValue = 0
            noiseReductionMode.integerValue = 0
            
            configuration = filterConfig.init(filterRange1:blueRange , filterRange2: greenRange, filterRange3: redRange, Smoothing: (gaussianBlurrMode.integerValue, medianBlurrMode.integerValue, noiseReductionMode.integerValue))
            
            Slider1.setNeedsDisplay()
            Slider2.setNeedsDisplay()
            Slider3.setNeedsDisplay()
            
            colorCollection.deselectAll(self)
            
            var inputimage = image
            
            if(Int(inputimage.size.width) > Int(maximumLen) || Int(inputimage.size.height) > Int(maximumLen)){
                
                let largestSide = max(Int(inputimage.size.width), Int(inputimage.size.height))
                
                if(Int(inputimage.size.width) == largestSide){
                    let factor = Double(maximumLen/inputimage.size.width)
                    let newHeight = Int((factor*Double(inputimage.size.height)).rounded())
                    
                    inputimage = inputimage.resize(img: inputimage, w: Int(maximumLen), h: newHeight)
                    
                } else{
                    let factor = Double(maximumLen/inputimage.size.height)
                    let newWidth = Int((factor*Double(inputimage.size.width)).rounded())
                    
                    inputimage = inputimage.resize(img: inputimage, w: newWidth, h: Int(maximumLen))
                    
                }
            }
            
            let cgc = CGContext.init(data: nil, width: Int(inputimage.size.width), height: Int(inputimage.size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB() , bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            
            cgc!.draw((NSBitmapImageRep.init(data: inputimage.tiffRepresentation!)?.cgImage)!, in: CGRect(x: 0, y: 0, width: (cgc?.width)!, height: (cgc?.height)!))
            
            inputimage = NSImage.init(cgImage: (cgc?.makeImage())!, size: inputimage.size)
            
            mainImageView.image = inputimage
            backupImage = inputimage
            unSmoothedBackup = backupImage
            currentCGImage = NSBitmapImageRep.init(data: inputimage.tiffRepresentation!)!.cgImage!
            
            if(image != NSImage.init(named: "Placeholder")){
                placeholderLoaded = false
                metricsFooter.stringValue = (backupImage?.getImageMetrics())!
                (self.view.window?.windowController as! WindowController).exportButton.isEnabled = true
                (self.view.window?.windowController as! WindowController).compareButton.alphaValue = 0
                (self.view.window?.windowController as! WindowController).eraserButton.alphaValue = 0
                (self.view.window?.windowController as! WindowController).compareButton.isEnabled = true
                (self.view.window?.windowController as! WindowController).compareButton.isHidden = false
                (self.view.window?.windowController as! WindowController).eraserButton.isHidden = false
                (self.view.window?.windowController as! WindowController).eraserButton.isEnabled = true
                (self.view.window?.windowController as! WindowController).convertButton.isEnabled = true
                
                (self.view.window?.windowController as! WindowController).compareButton.animator().alphaValue = 1
                (self.view.window?.windowController as! WindowController).eraserButton.animator().alphaValue = 1
                
                mainImageView.mouseUp(with: NSEvent.init())
                colorCollection.isEnabled = true
            }
            
            
            
            layerController.layers.removeAll()
            layerCount = 0
            addLayer(1)
            movedSlider(1)
            
        }
    }
    
    func updateSmoothedImage(image: NSImage){
        
        if(image.tiffRepresentation != nil){
            
            var inputimage = image
            
            let cgc = CGContext.init(data: nil, width: Int(inputimage.size.width), height: Int(inputimage.size.height), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB() , bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            
            cgc!.draw((NSBitmapImageRep.init(data: inputimage.tiffRepresentation!)?.cgImage)!, in: CGRect(x: 0, y: 0, width: (cgc?.width)!, height: (cgc?.height)!))
            
            inputimage = NSImage.init(cgImage: (cgc?.makeImage())!, size: inputimage.size)
            
            mainImageView.image = inputimage
            
            
        }
    }
    
    @IBAction func showInitialImage(_ sender: Any) {
        
        self.mainImageView.image = self.initialImageView.image
        
    }
    
    
}

