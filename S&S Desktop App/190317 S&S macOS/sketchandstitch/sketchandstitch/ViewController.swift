//
//  ViewController.swift
//  sketchandstitch
//
//  Created by Kirill Timchenko on 07.11.18.
//  Copyright © 2018 Kirill Timchenko. All rights reserved.
//

import Cocoa
import AVFoundation

class ViewController: NSViewController {
    
    //Variables and delegates necessary for the functioning of the application and the communication
    //between different components.
    
    var delegate = NSApplication.shared.delegate! as! AppDelegate
    let dispatchGroup = DispatchGroup()
    let processqueue = DispatchQueue(label: "ProcessColorFilter")
    var currSelColor = (255,255,255)
    
    //The interface components in order of appearance and/or importance.
    @IBOutlet weak var busyIndicator: NSProgressIndicator!
    
    @IBOutlet weak var colorSpaceSelector: NSSegmentedControl!
    @IBOutlet weak var recieveImageServer: NSButton!
    
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var backupView: NSImageView!
    
    @IBOutlet weak var detectAndMask: NSButton!
    @IBOutlet weak var HSVColorReference1: NSImageView!
    @IBOutlet weak var HSVColorReference2: NSImageView!
    
    //Sliders and their corresponding cells/information.
    @IBOutlet weak var BlueSlider: NSSlider!
    @IBOutlet weak var BlueSliderCell: CustomSliderCell!
    @IBOutlet weak var BlueValueText: NSTextField!
    @IBOutlet weak var GreenSlider: NSSlider!
    @IBOutlet weak var GreenSliderCell: CustomSliderCell!
    @IBOutlet weak var GreenValueText: NSTextField!
    @IBOutlet weak var RedSlider: NSSlider!
    @IBOutlet weak var RedSliderCell: CustomSliderCell!
    @IBOutlet weak var RedValueText: NSTextField!
    
    @IBOutlet weak var BlueSliderLow: NSSlider!
    @IBOutlet weak var BlueSliderLowCell: CustomSliderCell!
    @IBOutlet weak var BlueValueTextLow: NSTextField!
    @IBOutlet weak var GreenSliderLow: NSSlider!
    @IBOutlet weak var GreenSliderLowCell: CustomSliderCell!
    @IBOutlet weak var GreenValueTextLow: NSTextField!
    @IBOutlet weak var RedSliderLow: NSSlider!
    @IBOutlet weak var RedSliderLowCell: CustomSliderCell!
    @IBOutlet weak var RedValueTextLow: NSTextField!
    
    //Image functions and their corresponding elements.
    @IBOutlet weak var userColorSelector: NSPopUpButton!
    @IBOutlet weak var addUserColor: NSButton!
    @IBOutlet weak var addUserColorName: NSTextField!
    @IBOutlet weak var addUserColorTickmark: NSImageView!
    @IBOutlet weak var removeUserColor: NSButton!
    
    @IBOutlet weak var canvasBackgroundColor: NSButton!
    @IBOutlet weak var preNoiseMode: NSButton!
    @IBOutlet weak var preNoiseStepper: NSStepper!
    @IBOutlet weak var preNoiseText: NSTextField!
    @IBOutlet weak var postNoiseMode: NSButton!
    @IBOutlet weak var postNoiseStepper: NSStepper!
    @IBOutlet weak var postNoiseText: NSTextField!
    
    @IBOutlet weak var coloringMode: NSSegmentedControl!
    @IBOutlet weak var coloringModeCustom: NSColorWell!
    
    @IBOutlet weak var hoopType: NSTextField!
    @IBOutlet weak var rotateButton: NSButton!
    @IBOutlet weak var ScalingStepper: NSStepper!
    @IBOutlet weak var ScalingText: NSTextField!
    
    //File handling.
    @IBOutlet weak var exportButton: NSButton!
    @IBOutlet weak var openImageButton: NSButton!
    
    @IBAction func recieveImagesToggle(_ sender: Any) {
        if(delegate.RecieveServerStarted == false){
            delegate.RecieveServerStarted = true
            recieveImageServer.image = NSImage(named: "NSStatusAvailable")
            let myWindowController3 = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "3") as! NSWindowController
            self.view.window!.contentViewController!.presentAsSheet(myWindowController3.contentViewController!)
        } else {
            delegate.RecieveServerStarted = false
            recieveImageServer.image = NSImage(named: "NSStatusNone")
        }
        
    }
    @IBAction func userColorName(_ sender: Any) {
        addUserColor.isEnabled = true
        addUserColorTickmark.isHidden = true
    }
    
    @IBAction func coloringchanged(_ sender: Any) {
        userColorSelector.selectItem(withTitle: "None")
        Process()
    }
    @IBAction func backgroundColorChanged(_ sender: Any) {
        Process()
    }
    
    @IBAction func noiseModeChanged(_ sender: Any) {
        Process()
    }
    
    @IBAction func movedBlueSlider(_ sender: Any) {
        userColorSelector.selectItem(withTitle: "None")
        let bluevalue = BlueSlider.integerValue
        BlueValueText.stringValue = String(bluevalue)
        
        let event = NSApplication.shared.currentEvent
        switch event!.type{
        case .leftMouseUp:
            Process()
        default:
            break
        }
    }
    
    @IBAction func movedGreenSlider(_ sender: Any) {
        userColorSelector.selectItem(withTitle: "None")
        let greenvalue = GreenSlider.integerValue
        GreenValueText.stringValue = String(greenvalue)
        let event = NSApplication.shared.currentEvent
        switch event!.type{
        case .leftMouseUp:
            Process()
        default:
            break
        }
    }
    
    @IBAction func movedRedSlider(_ sender: Any) {
        userColorSelector.selectItem(withTitle: "None")
        let redvalue = RedSlider.integerValue
        RedValueText.stringValue = String(redvalue)
        let event = NSApplication.shared.currentEvent
        switch event!.type{
        case .leftMouseUp:
            Process()
        default:
            break
        }
    }
    
    @IBAction func movedBlueSliderLow(_ sender: Any) {
        userColorSelector.selectItem(withTitle: "None")
        let lowbluevalue = BlueSliderLow.integerValue
        BlueValueTextLow.stringValue = String(lowbluevalue)
        let event = NSApplication.shared.currentEvent
        switch event!.type{
        case .leftMouseUp:
            Process()
        default:
            break
        }
    }
    @IBAction func movedGreenSliderLow(_ sender: Any) {
        userColorSelector.selectItem(withTitle: "None")
        let lowgreenvalue = GreenSliderLow.integerValue
        GreenValueTextLow.stringValue = String(lowgreenvalue)
        let event = NSApplication.shared.currentEvent
        switch event!.type{
        case .leftMouseUp:
            Process()
        default:
            break
        }
    }
    @IBAction func movedRedSliderLow(_ sender: Any) {
        userColorSelector.selectItem(withTitle: "None")
        let lowredvalue = RedSliderLow.integerValue
        RedValueTextLow.stringValue = String(lowredvalue)
        let event = NSApplication.shared.currentEvent
        switch event!.type{
        case .leftMouseUp:
            Process()
        default:
            break
        }
    }
    
    @IBAction func saveJPG(_ sender: Any) {
        let exportimage = imageView.image
        let desktopDirectory  = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        _ = exportimage?.saveToFile(as: "Output", fileType: .jpeg, at: desktopDirectory)
    }
    
    @IBAction func prenoiseValChanged(_ sender: Any) {
        preNoiseText.intValue = preNoiseStepper.intValue
        if(preNoiseMode.state.rawValue > 0){
            Process()
        }
    }
    
    @IBAction func postnoisevalChanged(_ sender: Any) {
        postNoiseText.intValue = postNoiseStepper.intValue
        if(postNoiseMode.state.rawValue > 0){
            Process()
        }
    }
    
    @IBAction func AddColorToFilterlist(_ sender: Any) {
        let bh: Int = Int(BlueSlider!.doubleValue)
        let gh: Int  = Int(GreenSlider!.doubleValue)
        let rh: Int  = Int(RedSlider!.doubleValue)
        
        let bl: Int = Int(BlueSliderLow!.doubleValue)
        let gl: Int = Int(GreenSliderLow!.doubleValue)
        let rl: Int = Int(RedSliderLow!.doubleValue)
        
        let colormd = colorSpaceSelector.selectedSegment
        var nameadd = "(BGR)"
        
        if(colormd == 1){
            nameadd = "(HSV)"
        }
        
        let entryname = addUserColorName.stringValue+" "+nameadd
        
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        
        appDelegate.userColorList[entryname] = ((bl,gl,rl),(bh,gh,rh), colormd, currSelColor)
        
        addUserColor.isEnabled = false
        addUserColorName.stringValue = ""
        addUserColorTickmark.isHidden = false
        
        updateUserColorSelector()
    }
    
    @IBAction func selectedUserColorChanged(_ sender: Any) {
        if(userColorSelector.titleOfSelectedItem != "None"){
            let appDelegate = NSApplication.shared.delegate as! AppDelegate
            
            let selecteditem = userColorSelector.titleOfSelectedItem
            
            let rangedata = appDelegate.userColorList[selecteditem!]!
            
            colorSpaceSelector.selectedSegment = rangedata.2
            
            colorSpace(self)
            
            BlueSlider.integerValue = rangedata.1.0
            GreenSlider.integerValue = rangedata.1.1
            RedSlider.integerValue = rangedata.1.2
            
            BlueSliderLow.integerValue = rangedata.0.0
            GreenSliderLow.integerValue = rangedata.0.1
            RedSliderLow.integerValue = rangedata.0.2
            
            currSelColor = (rangedata.3.0,rangedata.3.1,rangedata.3.2)
            
            switch(currSelColor){
            case (255,255,255):
                coloringMode.selectedSegment = 0
            case (149,66,15):
                coloringMode.selectedSegment = 1
            case (60,15,178):
                coloringMode.selectedSegment = 2
            case (58,204,253):
                coloringMode.selectedSegment = 3
            default:
                coloringMode.selectedSegment = 4
                coloringModeCustom.color = NSColor(calibratedRed: CGFloat(currSelColor.0), green: CGFloat(currSelColor.1), blue: CGFloat(currSelColor.2), alpha: 1.0)
            }
            
            
            updateSliderText()
            removeUserColor.isEnabled = true
        }
        
        if(userColorSelector.titleOfSelectedItem! == "None"){
            currSelColor = (255,255,255)
            coloringMode.selectedSegment = 0
            removeUserColor.isEnabled = false
            postNoiseMode.integerValue = 0
            preNoiseMode.integerValue = 0
            canvasBackgroundColor.integerValue = 0
            BlueSlider.doubleValue = BlueSlider.maxValue
            RedSlider.doubleValue = RedSlider.maxValue
            GreenSlider.doubleValue = GreenSlider.maxValue
            
            BlueSliderLow.doubleValue = BlueSliderLow.minValue
            RedSliderLow.doubleValue = RedSliderLow.minValue
            GreenSliderLow.doubleValue = GreenSliderLow.minValue
            
            updateSliderText()
        }
        
        Process()
    }
    
    @IBAction func ClearUserColorList(_ sender: Any) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        
        if(userColorSelector.titleOfSelectedItem! != "None"){
            appDelegate.userColorList.removeValue(forKey: userColorSelector.titleOfSelectedItem!)
            userColorSelector.removeItem(withTitle: userColorSelector.titleOfSelectedItem!)
            
            let file = "UserColorList"
            
            let desktopDirectory  = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            
            let fileURL = desktopDirectory.appendingPathComponent(file)
            
            let emptystring = ""
            do {
                try emptystring.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            } catch  {
                print("ERROR: Could not clear usercolors.")
            }
            
        }
        
        removeUserColor.isEnabled = false
        BlueSlider.doubleValue = BlueSlider.maxValue
        RedSlider.doubleValue = RedSlider.maxValue
        GreenSlider.doubleValue = GreenSlider.maxValue
        
        BlueSliderLow.doubleValue = BlueSliderLow.minValue
        RedSliderLow.doubleValue = RedSliderLow.minValue
        GreenSliderLow.doubleValue = GreenSliderLow.minValue
        
        coloringMode.selectedSegment = 0
        
        updateSliderText()
        
        if(userColorSelector.numberOfItems == 1){
            userColorSelector.isEnabled = false
        }
        
        Process()
        
    }
    
    @IBAction func openImage(_ sender: Any) {
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose an image file";
        dialog.showsResizeIndicator    = false;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = false;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["jpg","jpeg","png"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                let scaling = ScalingStepper.doubleValue
                let newimage = NSImage(byReferencingFile: path)
                let scaledimage = OpenCV.resize(newimage!, scaling)
                
                
                self.delegate.currentLoadedImage = newimage!
                
                delegate.currentLoadedImage = self.delegate.currentLoadedImage
                delegate.isStockImage = false
                
                backupView.image = scaledimage
                imageView.image = backupView.image
                
                hoopType.stringValue = "None"
                hoopType.textColor = NSColor.lightGray
                detectAndMask.isEnabled = false
                
                BlueSlider.integerValue = Int(BlueSlider.maxValue)
                GreenSlider.integerValue = Int(GreenSlider.maxValue)
                RedSlider.integerValue = Int(RedSlider.maxValue)
                
                BlueSliderLow.integerValue = Int(BlueSliderLow.minValue)
                GreenSliderLow.integerValue = Int(GreenSliderLow.minValue)
                RedSliderLow.integerValue = Int(RedSliderLow.minValue)
                
                coloringMode.selectedSegment = 0
                preNoiseMode.integerValue = 0
                postNoiseMode.integerValue = 0
                canvasBackgroundColor.integerValue = 0
                userColorSelector.selectItem(withTitle: "None")
                updateSliderText()
                openImageOnlyMode(mode: 0)
                
            }
        } else {
            // User clicked on "Cancel"
            return
        }
        
    }
    
    @IBAction func dragAndDropImage(_ sender: Any) {
        let scaling = ScalingStepper.doubleValue
        let newimage = self.backupView.image!
        self.delegate.currentLoadedImage = newimage
        let scaledimage = OpenCV.resize(newimage, scaling)
        
        delegate.isStockImage = false
        
        self.backupView.image = scaledimage
        
        imageView.image = backupView.image
        
        hoopType.stringValue = "None"
        hoopType.textColor = NSColor.lightGray
        detectAndMask.isEnabled = false
        
        BlueSlider.integerValue = Int(BlueSlider.maxValue)
        GreenSlider.integerValue = Int(GreenSlider.maxValue)
        RedSlider.integerValue = Int(RedSlider.maxValue)
        
        BlueSliderLow.integerValue = Int(BlueSliderLow.minValue)
        GreenSliderLow.integerValue = Int(GreenSliderLow.minValue)
        RedSliderLow.integerValue = Int(RedSliderLow.minValue)
        
        coloringMode.selectedSegment = 0
        preNoiseMode.integerValue = 0
        postNoiseMode.integerValue = 0
        canvasBackgroundColor.integerValue = 0
        userColorSelector.selectItem(withTitle: "None")
        updateSliderText()
        openImageOnlyMode(mode: 0)
        
    }
    
    @IBAction func Rotate(_ sender: Any) {
        let rotatequeue = DispatchQueue(label: "RotateQueue")
        let imager = delegate.currentLoadedImage!
        var output = OpenCV.getMarkers(imager) as! [Int]
        var i = 0.0
        var inc = 0.0
        let backup = delegate.currentLoadedImage!
        self.busyIndicator.isHidden = false
        
        rotatequeue.async {
            
            if(output[0] != 404){
                
                if(output[0] == 1 || output[0] == 0){
                    
                    var markerPos1 = OpenCV.getMarkerCenter(imager, Int32(0)) as! [Int]
                    var markerPos2 = OpenCV.getMarkerCenter(imager, Int32(1)) as! [Int]
                    var bot = [Int(imager.size.width), Int(imager.size.height)]
                    var top = [0,0]
                    
                    if(markerPos1[1] > markerPos2[1]){
                        top = markerPos2
                        bot = markerPos1
                    } else {
                        top = markerPos1
                        bot = markerPos2
                    }
                    
                    if(top[0] > bot[0]){
                        i = 1.0
                        inc = 1.0
                    } else{
                        i = -1.0
                        inc = -1.0
                    }
                    var dst = abs(top[0]-bot[0])
                    //print(markerPos1, markerPos2)
                    //print(dst)
                    
                    var image = backup
                    
                    while(dst > 20){
                        image = backup
                        image = image.rotateImageByAngle(angle: CGFloat(i))
                        let output = OpenCV.getMarkers(image) as! [Int]
                        //print(output)
                        var markerPos1 = OpenCV.getMarkerCenter(image, Int32(0)) as! [Int]
                        var markerPos2 = OpenCV.getMarkerCenter(image, Int32(1)) as! [Int]
                        // print(markerPos1, markerPos2)
                        var bot = [Int(image.size.width), Int(image.size.height)]
                        var top = [0,0]
                        
                        if(output.count == 2){
                            if(markerPos1[1] > markerPos2[1]){
                                top = markerPos2
                                bot = markerPos1
                            } else {
                                top = markerPos1
                                bot = markerPos2
                            }
                        } else{
                            break
                        }
                        
                        dst = abs(top[0]-bot[0])
                        print(dst)
                        i = i+inc
                    }
                    
                    DispatchQueue.main.async {
                        self.delegate.currentLoadedImage = image
                        self.ScalingChanged(self)
                        self.detectAndMask.isEnabled = true
                        self.busyIndicator.isHidden = true
                        self.detectAndMask.isHighlighted = true
                    }
                    
                }
            }
            
            DispatchQueue.main.async {
                self.busyIndicator.isHidden = true
            }
            
        }
        
        
    }
    
    @IBAction func customColorChanged(_ sender: Any) {
        coloringMode.selectedSegment = 4
        Process()
    }
    
    @IBAction func detectAndCrop(_ sender: Any) {
        let image = self.delegate.currentLoadedImage!
        var output = OpenCV.getMarkers(image) as! [Int]
        let cropqueue = DispatchQueue.init(label: "CropQueue")
        
        if(output[0] != 404){
            
            if(output[0] == 1 || output[0] == 0){
                
                hoopType.stringValue = "Round"
                hoopType.textColor = NSColor.systemGreen
                self.busyIndicator.isHidden = false
                
                cropqueue.async {
                    var markerPos1 = OpenCV.getMarkerCenter(image, Int32(0)) as! [Int]
                    var markerPos2 = OpenCV.getMarkerCenter(image, Int32(1)) as! [Int]
                    var bot = [Int(image.size.width), Int(image.size.height)]
                    var top = [0,0]
                    
                    if(markerPos1[1] > markerPos2[1]){
                        top = markerPos2
                        bot = markerPos1
                    } else {
                        top = markerPos1
                        bot = markerPos2
                    }
                    //print(markerPos1, markerPos2)
                    let dst = abs(bot[1]-top[1])
                    
                    var inDarkMode: Bool {
                        let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
                        return mode == "Dark"
                    }
                    
                    var darkbg = 0
                    
                    if(inDarkMode){
                        darkbg = 1
                    }
                    
                    let cropped = OpenCV.cropHoop(image, Int32(0), Int32(top[1]), Int32(bot[0]), Int32(dst), Int32(top[0]), Int32(darkbg))
                    
                    DispatchQueue.main.async {
                        self.delegate.currentLoadedImage = cropped
                        self.ScalingStepper.doubleValue = 1.0
                        self.ScalingChanged(self)
                        self.busyIndicator.isHidden = true
                        self.detectAndMask.isEnabled = false
                        
                    }
                }
            }
            
            if(output[0] == 2 || output[0] == 3){
                
                hoopType.stringValue = "Square"
                hoopType.textColor = NSColor.systemGreen
                self.busyIndicator.isHidden = false
                
                cropqueue.async {
                    var markerPos1 = OpenCV.getMarkerCenter(image, Int32(0)) as! [Int]
                    var markerPos2 = OpenCV.getMarkerCenter(image, Int32(1)) as! [Int]
                    var bot = [Int(image.size.width), Int(image.size.height)]
                    var top = [0,0]
                    
                    if(markerPos1[1] > markerPos2[1]){
                        top = markerPos2
                        bot = markerPos1
                    } else {
                        top = markerPos1
                        bot = markerPos2
                    }
                    //print(markerPos1, markerPos2)
                    let dst = abs(bot[1]-top[1])
                    
                    var inDarkMode: Bool {
                        let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
                        return mode == "Dark"
                    }
                    
                    var darkbg = 0
                    
                    if(inDarkMode){
                        darkbg = 1
                    }
                    
                    let cropped = OpenCV.cropHoop(image, Int32(0), Int32(top[1]), Int32(bot[0]), Int32(dst), Int32(top[0]), Int32(darkbg))
                    
                    DispatchQueue.main.async {
                        self.delegate.currentLoadedImage = cropped
                        self.ScalingStepper.doubleValue = 1.0
                        self.ScalingChanged(self)
                        self.busyIndicator.isHidden = true
                        
                    }
                }
            }
        }
    }
    
    func Process() {
        self.busyIndicator.startAnimation(1)
        let input = backupView.image
        let colormode = colorSpaceSelector.integerValue
        var output: NSImage = input!
        let bh: Double = BlueSlider!.doubleValue
        let gh: Double  = GreenSlider!.doubleValue
        let rh: Double  = RedSlider!.doubleValue
        
        let bl: Double = BlueSliderLow!.doubleValue
        let gl: Double = GreenSliderLow!.doubleValue
        let rl: Double = RedSliderLow!.doubleValue
        let noise = postNoiseMode.state.rawValue
        let prenoise = preNoiseMode.state.rawValue
        let noiseval = postNoiseStepper.intValue
        let prenoiseval = preNoiseStepper.intValue
        
        let coloring = coloringMode.selectedSegment
        var color = (0,0,0)
        switch coloring {
        case 0:
            color = (255,255,255)
            break
        case 1:
            color = (149,66,15)
            break
        case 2:
            color = (60,15,178)
            break
        case 3:
            color = (58,204,253)
            break
        case 4:
            color = (Int(coloringModeCustom.color.blueComponent*255),
                     Int(coloringModeCustom.color.greenComponent*255),
                     Int(coloringModeCustom.color.redComponent*255))
        default:
            color = (255,255,255)
            break
        }
        
        self.currSelColor = color
        
        let whitebgstate = canvasBackgroundColor.state
        let checkstate = NSButton.StateValue(1)
        DispatchQueue.main.async {
            self.busyIndicator.isHidden = false
        }
        
        dispatchGroup.wait()
        dispatchGroup.enter()
        processqueue.async {
            output = OpenCV.filter(byBounds: input!, bl,gl,rl, bh, gh ,rh, Int32(0) , Int32(noiseval), Int32(coloring), Int32(colormode), Int32(prenoise), Int32(prenoiseval))
            
            if(coloring != 0){
                output = OpenCV.colorImage(output, Int32(Int(coloring)), Int32(color.0), Int32(color.1), Int32(color.2))
            }
            
            if(whitebgstate == checkstate){
                output = OpenCV.whiteBackground(output)
            }
            
            DispatchQueue.main.async {
                self.imageView.image = output
                if(noise == 1){
                    self.postNoiseReduction()
                }
                self.busyIndicator.isHidden = true
            }
            
            self.dispatchGroup.leave()
        }
        
        
        
        
    }
    
    @IBAction func ScalingChanged(_ sender: Any) {
        ScalingText.stringValue = String(format:"%1.f", ScalingStepper.doubleValue * 100) +  "%"
        
        let scaling = ScalingStepper.doubleValue
        let scaledimage = OpenCV.resize(delegate.currentLoadedImage, scaling)
        
        backupView.image = scaledimage
        
        Process()
    }
    
    @IBAction func modeChange(_ sender: Any) {
        let myWindowController2 = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "2") as! NSWindowController
        myWindowController2.showWindow(self)
        self.view.window?.close()
    }
    
    @IBAction func colorSpace(_ sender: Any) {
        if(colorSpaceSelector.indexOfSelectedItem == 1){
            BlueSlider.maxValue = 179.0
            BlueSlider.numberOfTickMarks = 3
            BlueSliderLow.maxValue = 179.0
            BlueSliderLow.numberOfTickMarks = 3
            HSVColorReference1.isHidden = false
            HSVColorReference2.isHidden = false
            BlueSliderLowCell.changeColor(color: 4)
            GreenSliderLowCell.changeColor(color: 3)
            RedSliderLowCell.changeColor(color: 3)
            
            BlueSliderCell.changeColor(color: 4)
            GreenSliderCell.changeColor(color: 3)
            RedSliderCell.changeColor(color: 3)
            
            BlueSlider.updateCell(BlueSliderCell)
            GreenSlider.updateCell(GreenSliderCell)
            RedSlider.updateCell(RedSliderCell)
            
            BlueSliderLow.updateCell(BlueSliderLowCell)
            GreenSliderLow.updateCell(GreenSliderLowCell)
            RedSliderLow.updateCell(RedSliderLowCell)
            
            
        } else {
            BlueSlider.maxValue = 255.0
            BlueSlider.numberOfTickMarks = 0
            BlueSliderLow.maxValue = 255.0
            BlueSliderLow.numberOfTickMarks = 0
            HSVColorReference1.isHidden = true
            HSVColorReference2.isHidden = true
            BlueSliderLowCell.changeColor(color: 0)
            GreenSliderLowCell.changeColor(color: 1)
            RedSliderLowCell.changeColor(color: 2)
            
            BlueSliderCell.changeColor(color: 0)
            GreenSliderCell.changeColor(color: 1)
            RedSliderCell.changeColor(color: 2)
            
            BlueSlider.updateCell(BlueSliderCell)
            GreenSlider.updateCell(GreenSliderCell)
            RedSlider.updateCell(RedSliderCell)
            
            BlueSliderLow.updateCell(BlueSliderLowCell)
            GreenSliderLow.updateCell(GreenSliderLowCell)
            RedSliderLow.updateCell(RedSliderLowCell)
        }
        
        BlueSlider.doubleValue = BlueSlider.maxValue
        RedSlider.doubleValue = RedSlider.maxValue
        GreenSlider.doubleValue = GreenSlider.maxValue
        
        BlueSliderLow.doubleValue = BlueSliderLow.minValue
        RedSliderLow.doubleValue = RedSliderLow.minValue
        GreenSliderLow.doubleValue = GreenSliderLow.minValue
        
        updateSliderText()
        coloringMode.selectedSegment = 0
        
        Process()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = NSApplication.shared.delegate! as! AppDelegate
        addUserColorName.isHighlighted = false
        ScalingStepper.doubleValue = 0.4
        ScalingText.stringValue = String(format:"%1.f", ScalingStepper.doubleValue * 100) +  "%"
        imageView.wantsLayer = true
        imageView.canDrawSubviewsIntoLayer = true
        imageView.layer!.cornerRadius = 4.0
        imageView.layer!.masksToBounds = true
        
        backupView.wantsLayer = true
        backupView.canDrawSubviewsIntoLayer = true
        backupView.layer!.cornerRadius = 4.0
        backupView.layer!.masksToBounds = true
        
        self.view.window?.titlebarAppearsTransparent = true
        self.view.window?.isMovableByWindowBackground = true
        var inputimg: NSImage
        
        if(delegate.isStockImage == true){
            inputimg = NSImage(named: "PlaceHolder")!
            openImageOnlyMode(mode: 1)
            
        } else{
            
            inputimg = delegate.currentLoadedImage!
            openImageOnlyMode(mode: 0)
        }
        
        if(delegate.RecieveServerStarted == true){
            recieveImageServer.image = NSImage(named: "NSStatusAvailable")
            recieveImageServer.integerValue = 1
        } else {
            recieveImageServer.image = NSImage(named: "NSStatusNone")
            recieveImageServer.integerValue = 0
        }
        
        let scaledimg = OpenCV.resize(inputimg, ScalingStepper.doubleValue)
        imageView.image = scaledimg
        backupView.image = imageView.image
        preNoiseStepper.intValue = 25
        postNoiseStepper.intValue = preNoiseStepper.intValue
        let bluevalue = BlueSlider.integerValue
        BlueValueText.stringValue = String(bluevalue)
        
        
        let greenvalue = GreenSlider.integerValue
        GreenValueText.stringValue = String(greenvalue)
        
        
        let redvalue = RedSlider.integerValue
        RedValueText.stringValue = String(redvalue)
        
        
        let lowbluevalue = BlueSliderLow.integerValue
        BlueValueTextLow.stringValue = String(lowbluevalue)
        
        let lowgreenvalue = GreenSliderLow.integerValue
        GreenValueTextLow.stringValue = String(lowgreenvalue)
        
        let lowredvalue = RedSliderLow.integerValue
        RedValueTextLow.stringValue = String(lowredvalue)
        
        coloringModeCustom.color = NSColor.orange
        
        BlueSliderLowCell.changeColor(color: 0)
        GreenSliderLowCell.changeColor(color: 1)
        RedSliderLowCell.changeColor(color: 2)
        
        BlueSliderCell.changeColor(color: 0)
        GreenSliderCell.changeColor(color: 1)
        RedSliderCell.changeColor(color: 2)
        
        userColorSelector.removeAllItems()
        userColorSelector.display()
        updateUserColorSelector()
        userColorSelector.isEnabled = false
    }
    
    func updateUserColorSelector(){
        var i = 0
        var appDelegate = NSApplication.shared.delegate as! AppDelegate
        let launchqueue = DispatchQueue(label: "LaunchQ")
        
        self.userColorSelector.addItem(withTitle: "None")
        
        launchqueue.async {
            while(i == 0){
                appDelegate = NSApplication.shared.delegate as! AppDelegate
                i = appDelegate.i
            }
            
            if(!appDelegate.userColorList.isEmpty){
                DispatchQueue.main.async{
                    for color in appDelegate.userColorList{
                        self.userColorSelector.addItem(withTitle: color.key)
                    }
                    
                }
            }
        }
        
        if(!appDelegate.userColorList.isEmpty){
            DispatchQueue.main.async{
                self.userColorSelector.isEnabled = true
            }
        }
        
    }
    
    func updateSliderText(){
        BlueValueText.integerValue = BlueSlider.integerValue
        GreenValueText.integerValue = GreenSlider.integerValue
        RedValueText.integerValue = RedSlider.integerValue
        
        BlueValueTextLow.integerValue = BlueSliderLow.integerValue
        GreenValueTextLow.integerValue = GreenSliderLow.integerValue
        RedValueTextLow.integerValue = RedSliderLow.integerValue
    }
    
    func postNoiseReduction(){
        self.imageView.image = OpenCV.deNoise(self.imageView.image!, Int32(postNoiseStepper.integerValue))
    }
    
    func openImageOnlyMode(mode: Int){
        
        if(mode == 1){
            self.coloringMode.isEnabled = false
            self.colorSpaceSelector.isEnabled = false
            self.BlueSlider.isEnabled = false
            self.BlueSliderLow.isEnabled = false
            self.GreenSlider.isEnabled = false
            self.GreenSliderLow.isEnabled = false
            self.RedSlider.isEnabled = false
            self.RedSliderLow.isEnabled = false
            
            self.canvasBackgroundColor.isEnabled = false
            self.preNoiseMode.isEnabled = false
            self.postNoiseMode.isEnabled = false
            
            self.userColorSelector.isEnabled = false
            addUserColor.isEnabled = false
            self.postNoiseStepper.isEnabled = false
            self.ScalingStepper.isEnabled = false
            self.preNoiseStepper.isEnabled = false
            self.coloringModeCustom.isEnabled = false
            self.rotateButton.isEnabled = false
            self.exportButton.isEnabled = false
            
            self.openImageButton.isHighlighted = true
        } else if(mode == 0){
            self.coloringMode.isEnabled = true
            self.colorSpaceSelector.isEnabled = true
            self.BlueSlider.isEnabled = true
            self.BlueSliderLow.isEnabled = true
            self.GreenSlider.isEnabled = true
            self.GreenSliderLow.isEnabled = true
            self.RedSlider.isEnabled = true
            self.RedSliderLow.isEnabled = true
            
            self.canvasBackgroundColor.isEnabled = true
            self.preNoiseMode.isEnabled = true
            self.postNoiseMode.isEnabled = true
            
            addUserColor.isEnabled = true
            self.postNoiseStepper.isEnabled = true
            self.ScalingStepper.isEnabled = true
            self.preNoiseStepper.isEnabled = true
            self.coloringModeCustom.isEnabled = true
            self.rotateButton.isEnabled = true
            self.exportButton.isEnabled = true
            
            self.openImageButton.isHighlighted = false
            
            updateUserColorSelector()
        }
    }
    
}
