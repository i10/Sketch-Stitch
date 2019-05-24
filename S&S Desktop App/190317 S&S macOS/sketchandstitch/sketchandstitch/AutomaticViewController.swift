//
//  AutomaticViewController.swift
//  sketchandstitch
//
//  Created by Kirill Timchenko on 07.11.18.
//  Copyright © 2018 Kirill Timchenko. All rights reserved.
//

import Cocoa
import AVFoundation

class AutomaticViewController: NSViewController {
    
    //Variables and delegates necessary for the functioning of the application and the communication
    //between different components.
    
    var delegate = NSApplication.shared.delegate as! AppDelegate
    var colorList: [String: ((Int,Int,Int),(Int,Int,Int),Int,(Int,Int,Int))] = [:]
    var configList: [String: [Int]] = [:]
    let processqueue = DispatchQueue(label: "Process")
    var desktopDirectory  = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
    var outputURL: URL = URL(fileURLWithPath: "/")
    var configID = 1
    var numberOfConfigs = 1
    let scaling = 0.5
    
    //The interface components in order of appearance and/or importance.
    @IBOutlet weak var AutomaticImageView: NSImageView!
    @IBOutlet weak var ConfigurationSelector: NSPopUpButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var backgroundColorSelector: NSSegmentedControl!
    @IBOutlet weak var filterMode: NSSegmentedControl!
    @IBOutlet weak var colorSelectionSidebar: NSTableView!
    @IBOutlet weak var recieveImagesButton: NSButton!
    @IBOutlet weak var busyIndicator: NSProgressIndicator!
    @IBOutlet weak var currentStepInformationText: NSTextField!
    
    @IBAction func modeChange(_ sender: Any) {
        let myWindowController2 = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "1") as! NSWindowController
        myWindowController2.showWindow(self)
        self.view.window?.close()
    }
    
    @IBAction func recieveImagesAct(_ sender: Any) {
        
        delegate = NSApplication.shared.delegate! as! AppDelegate
        
        if(delegate.RecieveServerStarted == false){
            delegate.RecieveServerStarted = true
            recieveImagesButton.image = NSImage(named: "NSStatusAvailable")
            let myWindowController3 = NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "3") as! NSWindowController
            self.view.window!.contentViewController!.presentAsSheet(myWindowController3.contentViewController!)
        } else {
            delegate.RecieveServerStarted = false
            recieveImagesButton.image = NSImage(named: "NSStatusNone")
        }
        
    }
    
    @IBAction func addConfiguration(_ sender: Any) {
        self.ConfigurationSelector.addItem(withTitle: "Configuration "+String(configID))
        self.ConfigurationSelector.selectItem(withTitle: "Configuration "+String(configID))
        
        var i = 0
        
        for _ in colorList{
            let cell = colorSelectionSidebar.view(atColumn: 0, row: i, makeIfNecessary: false) as! TableColorCell
            cell.filterState.integerValue = 0
            i = i+1
        }
        
        
        
        configID = configID+1
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.selectedConfig = configID
        appDelegate.numberOfConfigs = appDelegate.numberOfConfigs+1
    }
    
    @IBAction func selectedConfigurationChanged(_ sender: Any) {
        
        var i = 0
        
        for _ in colorList{
            let cell = colorSelectionSidebar.view(atColumn: 0, row: i, makeIfNecessary: false) as! TableColorCell
            cell.filterState.integerValue = 0
            i = i+1
        }
        
        let selectedid = ConfigurationSelector.indexOfSelectedItem+1
        configID = selectedid
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        
        appDelegate.selectedConfig = selectedid
        
        for color in colorList{
            if(configList[color.key] != nil){
                if((configList[color.key]?.contains(selectedid))!){
                    for i in 0...colorList.count-1{
                        let cell = colorSelectionSidebar.view(atColumn: 0, row: i, makeIfNecessary: false) as! TableColorCell
                        
                        if(cell.colorName.stringValue == color.key){
                            cell.filterState.integerValue = 1
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func imageChanged(_ sender: Any) {
        delegate.isStockImage = false
        delegate.currentLoadedImage = self.AutomaticImageView.image
        self.currentStepInformationText.stringValue = ""
        self.AutomaticImageView.image = OpenCV.resize(self.AutomaticImageView.image!, self.scaling)
        self.progressIndicator.doubleValue = 0.0
        Rotate()
    }
    
    @IBAction func Process(_ sender: Any) {
        
        let selectedColors = getSelectedColors()
        self.currentStepInformationText.stringValue = "Starting processing"
        if(selectedColors.count > 0){
            do {
                try FileManager.default.createDirectory(at: desktopDirectory.appendingPathComponent("Output"), withIntermediateDirectories: false, attributes: nil)
            } catch _ as NSError {
                
            }
            self.busyIndicator.startAnimation(self)
            var currentColorNumber = selectedColors.count
            let steps = selectedColors.endIndex
            let increment = Int(100/steps)
            
            self.progressIndicator.doubleValue = 0.0
            
            let input = self.AutomaticImageView.image!
            let desiredbackgroundcolor = self.backgroundColorSelector.selectedSegment
            let skeletonize = self.filterMode.selectedSegment
            self.currentStepInformationText.stringValue = "Filtering color"
            for color in selectedColors{
                processqueue.async {
                    let lh = Double(self.colorList[color]!.0.0)
                    let ls = Double(self.colorList[color]!.0.1)
                    let lv = Double(self.colorList[color]!.0.2)
                    
                    let uh = Double(self.colorList[color]!.1.0)
                    let us = Double(self.colorList[color]!.1.1)
                    let uv = Double(self.colorList[color]!.1.2)
                    
                    
                    var output = OpenCV.filter(byBounds: input, lh,ls,lv, uh, us ,uv, Int32(1) , Int32(25), Int32(0), Int32(self.colorList[color]!.2), Int32(1), Int32(25))
                    
                    let coloringParam = self.colorList[color]!.3
                    if(coloringParam != (255,255,255)){
                        output = OpenCV.colorImage(output, Int32(1), Int32(coloringParam.0), Int32(coloringParam.1), Int32(coloringParam.2))
                    }
                    
                    
                    if(desiredbackgroundcolor == 1){
                        output = OpenCV.whiteBackground(output)
                    }
                    
                    _ = output.saveToFile(as: color, fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Output"))
                    
                    if(skeletonize == 1){
                        self.currentStepInformationText.stringValue = "Getting skeleton"
                        do {
                            try FileManager.default.createDirectory(at: self.desktopDirectory.appendingPathComponent("Skeletons"), withIntermediateDirectories: false, attributes: nil)
                        } catch _ as NSError {
                            
                        }
                        
                        do {
                            try FileManager.default.createDirectory(at: self.desktopDirectory.appendingPathComponent("Outlines"), withIntermediateDirectories: false, attributes: nil)
                        } catch _ as NSError {
                            
                        }
                        
                        var skelet1 = output.getSkeletonHOR()
                        var skelet2 = output.getSkeletonVERT()
                        //var skelet3 = output.getSkeletonDiag1()
                        //var skelet4 = output.getSkeletonDiag2()
                        
                        skelet1 = skelet1.optimizeSkeleton()
                        skelet2 = skelet2.optimizeSkeleton()
                        //skelet3 = skelet3.optimizeSkeleton()
                        //skelet4 = skelet4.optimizeSkeleton()
                        
                        let skelet1Filt = getFilteredComponents(img: skelet1)
                        let skelet2Filt = getFilteredComponents(img: skelet2)
                        
                        let skeletOpt = skelet1Filt.combineWithImage(refimage: skelet2Filt)
                        
                        let outline1 = output.getOutlineHor()
                        let outline2 = output.getOutlineVert()
                        let outlineOpt = outline1.combineWithImage(refimage: outline2)
                        
                        self.currentStepInformationText.stringValue = "Saving files"
                        //_ = skelet1.save(as: color + " Skelet Horizontal", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Skeletons"))
                        //_ = skelet2.save(as: color + " Skelet Vertical", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Skeletons"))
                        //_ = skelet3.save(as: color + " Skelet Diagonal1", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Skeletons"))
                        //_ = skelet4.save(as: color + " Skelet Diagonal2", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Skeletons"))
                        _ = skeletOpt.saveToFile(as: color + " Skelet Optimal", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Skeletons"))
                        
                        //_ = outline1.save(as: "Output" + " Outline Horizontal", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Outlines"))
                        
                        //_ = outline2.save(as: "Output" + " Outline Vertical", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Outlines"))
                        
                        _ = outlineOpt.saveToFile(as: color + " Outline Optimal", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Outlines"))
                        
                    }
                    DispatchQueue.main.sync {
                        self.progressIndicator.doubleValue = self.progressIndicator.doubleValue + Double(increment)
                        currentColorNumber = currentColorNumber - 1
                        
                        if(currentColorNumber == 0){
                            self.progressIndicator.doubleValue = 100
                            self.busyIndicator.stopAnimation(self)
                            self.currentStepInformationText.stringValue = "Done"
                        }
                    }
                }
            }
            
        }
    }
    
    @IBAction func getSkeletonsAndOutlines(_ sender: Any) {
        
        do {
            try FileManager.default.createDirectory(at: desktopDirectory.appendingPathComponent("Skeletons"), withIntermediateDirectories: false, attributes: nil)
        } catch _ as NSError {
            
        }
        
        do {
            try FileManager.default.createDirectory(at: desktopDirectory.appendingPathComponent("Outlines"), withIntermediateDirectories: false, attributes: nil)
        } catch _ as NSError {
            
        }
        
        let output = self.AutomaticImageView.image!
        self.currentStepInformationText.stringValue = "Getting Skeletons And Outlines"
        self.progressIndicator.doubleValue = 0.0
        self.busyIndicator.startAnimation(self)
        processqueue.async {
            
            let outline1 = output.getOutlineHor()
            let outline2 = output.getOutlineVert()
            
            let outlineOpt = outline1.combineWithImage(refimage: outline2)
            
            var skelet1 = output.getSkeletonHOR()
            
            DispatchQueue.main.sync {
                self.progressIndicator.doubleValue = self.progressIndicator.doubleValue + 10
            }
            
            var skelet2 = output.getSkeletonVERT()
            
            DispatchQueue.main.sync {
                self.progressIndicator.doubleValue = self.progressIndicator.doubleValue + 10
                
            }
            
            
            skelet1 = skelet1.optimizeSkeleton()
            
            DispatchQueue.main.sync {
                self.progressIndicator.doubleValue = self.progressIndicator.doubleValue + 10
                
            }
            
            skelet2 = skelet2.optimizeSkeleton()
            
            DispatchQueue.main.sync {
                self.progressIndicator.doubleValue = self.progressIndicator.doubleValue + 30
                
            }
            
            let skelet1Filt = getFilteredComponents(img: skelet1)
            let skelet2Filt = getFilteredComponents(img: skelet2)
            
            
            DispatchQueue.main.sync {
                self.progressIndicator.doubleValue = self.progressIndicator.doubleValue + 10
                
            }
            
            let skeletOpt = skelet1Filt.combineWithImage(refimage: skelet2Filt)
            
            DispatchQueue.main.sync {
                self.progressIndicator.doubleValue = self.progressIndicator.doubleValue + 10
                
            }
            
            
            //_ = skelet1.save(as: "Output" + " Skelet Horizontal", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Skeletons"))
            //_ = skelet2.save(as: "Output" + " Skelet Vertical", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Skeletons"))
            
            DispatchQueue.main.sync {
                self.progressIndicator.doubleValue = self.progressIndicator.doubleValue + 10
                
            }
            
            _ = skeletOpt.saveToFile(as: "Output" + " Skelet Optimal", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Skeletons"))
            
            
            //_ = outline1.save(as: "Output" + " Outline Horizontal", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Outlines"))
            
            //_ = outline2.save(as: "Output" + " Outline Vertical", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Outlines"))
            
            _ = outlineOpt.saveToFile(as: "Output" + " Outline Optimal", fileType: .jpeg, at: self.desktopDirectory.appendingPathComponent("Outlines"))
            DispatchQueue.main.sync {
                self.progressIndicator.doubleValue = 100
                self.busyIndicator.stopAnimation(self)
                self.currentStepInformationText.stringValue = "Done"
                
            }
        }
        
    }
    
    func getSelectedColors()-> [String]{
        var selectedColors : [String] = []
        
        if(colorSelectionSidebar.numberOfRows == 0){
            return selectedColors
        }
        
        for i in 0...colorSelectionSidebar.numberOfRows-1{
            let cell = colorSelectionSidebar.view(atColumn: 0, row: i, makeIfNecessary: false) as! TableColorCell
            if(cell.filterState.integerValue == 1){
                selectedColors.append(cell.colorName.title)
            }
        }
        
        return selectedColors
    }
    
    func Rotate(){
        let rotatequeue = DispatchQueue(label: "RotateQueue")
        let imager = self.AutomaticImageView.image!
        var output = OpenCV.getMarkers(imager) as! [Int]
        var i = 0.0
        var inc = 0.0
        let backup = imager
        
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
                        self.AutomaticImageView.image = image
                        self.detectAndCrop()
                    }
                    
                }
            }
            
        }
    }
    
    func detectAndCrop() {
        let image = self.AutomaticImageView.image!
        var output = OpenCV.getMarkers(image) as! [Int]
        let cropqueue = DispatchQueue.init(label: "CropQueue")
        
        if(output[0] != 404){
            
            if(output[0] == 1 || output[0] == 0){
                
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
                        self.AutomaticImageView.image = cropped
                        
                    }
                }
                
                
                
            }
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = NSApplication.shared.delegate! as! AppDelegate
        
        if(delegate.isStockImage == true){
            AutomaticImageView.image = NSImage(named: "PlaceHolder")!
        } else{
            AutomaticImageView.image = OpenCV.resize(delegate.currentLoadedImage!, self.scaling)
            Rotate()
        }
        
        if(delegate.RecieveServerStarted == true){
            recieveImagesButton.image = NSImage(named: "NSStatusAvailable")
            recieveImagesButton.integerValue = 1
        } else {
            recieveImagesButton.image = NSImage(named: "NSStatusNone")
            recieveImagesButton.integerValue = 0
        }
        
        AutomaticImageView.isEditable = true
        AutomaticImageView.wantsLayer = true // Use a layer as backing store for this view
        AutomaticImageView.canDrawSubviewsIntoLayer = true
        AutomaticImageView.layer!.cornerRadius = 4.0
        AutomaticImageView.layer!.masksToBounds = true
        ConfigurationSelector.removeAllItems()
        ConfigurationSelector.addItem(withTitle: "Configuration "+String(configID))
        configID = configID+1
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        colorList = appDelegate.userColorList
        configList = appDelegate.userConfigList
        var i = 0
        colorSelectionSidebar.beginUpdates()
        
        for _ in colorList{
            colorSelectionSidebar.insertRows(at: IndexSet(integer: i), withAnimation: .effectFade)
            i = i+1
        }
        
        colorSelectionSidebar.endUpdates()
        
        i = 0
        
        for color in colorList{
            let cell = colorSelectionSidebar.view(atColumn: 0, row: i, makeIfNecessary: false) as! TableColorCell
            cell.colorName.title = color.key
            cell.id = i
            i = i+1
        }
        
        let selectedid = ConfigurationSelector.indexOfSelectedItem+1
        
        for color in colorList{
            if(configList[color.key] != nil){
                if((configList[color.key]?.contains(selectedid))!){
                    for i in 0...colorList.count-1{
                        let cell = colorSelectionSidebar.view(atColumn: 0, row: i, makeIfNecessary: false) as! TableColorCell
                        
                        if(cell.colorName.stringValue == color.key){
                            cell.filterState.integerValue = 1
                        }
                    }
                }
            }
        }
        
        numberOfConfigs = appDelegate.numberOfConfigs
        
        for i in 1...numberOfConfigs{
            self.ConfigurationSelector.addItem(withTitle: "Configuration "+String(i))
        }
        
    }
}
