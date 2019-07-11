import Cocoa
import Socket
import simd

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var windowController : WindowController?
    var introController: NSWindowController?
    var colorArray: ContiguousArray<ContiguousArray<ContiguousArray<NSColor>>> = []
    var workQ: DispatchQueue = DispatchQueue.init(label: "workQ", qos: .userInteractive)
    var ipQ: DispatchQueue = DispatchQueue.init(label: "ipQ", qos: .default)
    var cgc :CGContext?
    let networkImageOverlay: ConnectOverlay? = nil
    let black = NSColor.init(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
    let white = NSColor.init(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
    
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        introController = (NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "2") as! NSWindowController)
        
        introController?.showWindow(nil)
        
        ipQ.async {
            IPHandler.getPublicIPV6()
        }
        
        workQ.async {
            
            self.initColorArrs()
        
            DispatchQueue.main.sync {
                self.windowController =  NSStoryboard(name: "Main", bundle: nil).instantiateController(withIdentifier: "1") as? WindowController
                self.introController?.window?.orderOut(nil)
                self.windowController?.showWindow(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
            
        }
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        windowController?.connectButton.connectView?.server?.shutdownServer()
        savePresets()
        
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        //NSApplication.shared.terminate(1)
        return true
    }
    
    func applicationWillResignActive(_ notification: Notification) {
        
    }
    
    func applicationDidUnhide(_ notification: Notification) {
        
    }
    
    func savePresets(){
    
        let exportDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("Sketch And Stitch")
        try! FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        
        var presets2save = windowController?.advancedViewController.presetController.presets
        presets2save?.remove(at: 0)
        
        var presetData2Encode : [PresetData] = []
        
        var i = 1
        
        for preset in presets2save!{
            let newPresetData = PresetData.init(index: i, name: preset.presetName.stringValue, low1: (preset.filterConfig?.filterRange1.start)!, low2: (preset.filterConfig?.filterRange2.start)!, low3: (preset.filterConfig?.filterRange3.start)!, high1: (preset.filterConfig?.filterRange1.end)!, high2: (preset.filterConfig?.filterRange2.end)!, high3: (preset.filterConfig?.filterRange3.end)!, gaus: (preset.filterConfig?.Smoothing.0)!, median: (preset.filterConfig?.Smoothing.1)!, noise: (preset.filterConfig?.Smoothing.2)!)
            presetData2Encode.append(newPresetData)
            i += 1
        }
        
        let data = try! NSKeyedArchiver.archivedData(withRootObject: presetData2Encode, requiringSecureCoding: false)
        
        try? data.write(to: exportDir.appendingPathComponent("PresetData"))
        
        
    }
    
    func initColorArrs(){
        
        var redArray : ContiguousArray<ContiguousArray<ContiguousArray<NSColor>>> = []
        var blueArray: ContiguousArray<NSColor> = []
        var greenArray: ContiguousArray<ContiguousArray<NSColor>> = []
        
        for red in 0...255{
            for green in 0...255{
                for blue in 0...255{
                    let color = NSColor.init(calibratedRed: CGFloat(red)/255, green: CGFloat(green)/255,
                                             blue: CGFloat(blue)/255, alpha: 1)
                    blueArray.insert(color, at: blue)
                }
                greenArray.insert(blueArray, at: green)
                blueArray.removeAll()
            }
            redArray.insert(greenArray, at: red)
            greenArray.removeAll()
        }
        
        self.colorArray = redArray
        redArray.removeAll()
        
    }
    
    func rotateByDegrees(image : NSImage, degree :Int) -> NSImage{
        
        let cgImage = NSBitmapImageRep.init(data: image.tiffRepresentation!)!.cgImage
        
        var maxSide :CGFloat =  (image.size.width)*(image.size.width)+(image.size.height)*(image.size.height)
        maxSide = maxSide.squareRoot()+1
        
        cgc = CGContext.init(data: nil, width: Int(maxSide), height: Int(maxSide), bitsPerComponent: 8, bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB() , bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        cgc?.setFillColor(CGColor.clear)
        cgc?.translateBy(x: maxSide/2 , y: maxSide/2)
        
        cgc?.interpolationQuality = CGInterpolationQuality(rawValue: 1)!
        
        cgc?.rotate(by: (CGFloat(-1*degree) * (CGFloat.pi/180)))
        
        let vector : (CGFloat,CGFloat) = (-1*image.size.width/2, image.size.height/2)
        let orthogonal : (CGFloat,CGFloat) = (image.size.width/2, image.size.height/2)
        
        let angle = -1*CGFloat(degree) * (CGFloat.pi/180)
        
        let rotatedVector : (CGFloat,CGFloat) = (vector.0 * cos(angle) + vector.1 * -sin(angle), vector.0 * sin(angle) + vector.1 * cos(angle))
        
        let rotatedOrthogonal : (CGFloat,CGFloat) = (orthogonal.0 * cos(angle) + orthogonal.1 * -sin(angle), orthogonal.0 * sin(angle) + orthogonal.1 * cos(angle))
        
        cgc?.draw(cgImage!, in: CGRect.init(origin: CGPoint.init(x: -1*(image.size.width)/2, y: -1*(image.size.height)/2), size: (image.size)))
        
        cgc?.rotate(by: (CGFloat(degree) * (CGFloat.pi/180)))
        
        let minX = CGFloat(min(rotatedVector.0, -1*rotatedVector.0, rotatedOrthogonal.0, -1*rotatedOrthogonal.0))
        let minY = CGFloat(min(rotatedVector.1, -1*rotatedVector.1, rotatedOrthogonal.1, -1*rotatedOrthogonal.1))
        
        let cropRect = CGRect.init(x: (maxSide/2 + minX).rounded(), y: (maxSide/2 + minY).rounded(), width: 2*abs(minX), height: 2*abs(minY))
        
        var output = cgc!.makeImage()
        
        output = output!.cropping(to: cropRect)
        
        return NSImage.init(cgImage: output!, size: cropRect.size)
        
    }
    
    func fixRotation(image: NSImage) -> Int {
        
        let features = detectQR(image: image)
        
        if(features.count == 2){
            var top : CGPoint = .zero
            var bot : CGPoint = .zero
            
            for feature in features{
                if(feature.messageString!.contains("1")){
                    top = CGPoint.init(x: feature.bounds.midX, y: feature.bounds.midY)
                }
                
                if(feature.messageString!.contains("2")){
                    bot = CGPoint.init(x: feature.bounds.midX, y: feature.bounds.midY)
                }
            }
            
            let middle = CGPoint.init(x: (top.x+bot.x)/2, y: (top.y+bot.y)/2)
            
            let refAxis :(CGFloat,CGFloat) = (0, middle.y)
            let topVector:(CGFloat,CGFloat) = (top.x-middle.x,top.y-middle.y)
            
            let angle = atan2(topVector.1, topVector.0) - atan2(refAxis.1, refAxis.0)
            let degree = (angle * CGFloat(180.0 / CGFloat.pi)).rounded()
            
            return Int(degree)
        }
        return 0
    }
    
    func detectQR(image: NSImage) -> [CIQRCodeFeature]{
        let ciImage = CIImage.init(data: image.tiffRepresentation!)
        let codes = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
            .features(in: ciImage!)
        return codes as! [CIQRCodeFeature]
    }
    
    func getFilteredComponents(img: NSImage) -> NSImage {
        
        var image = img
        let inputbitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let imagebitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        
        let width = image.size.width
        let height = image.size.height
        var empty = false
        
        for i in 0...Int(width)-1{
            for j in 0...Int(height)-1{
                bitmap!.setColor(black.withAlphaComponent(0), atX: i, y: j)
            }
        }
        
        var componentlist: [[(Int,Int)]] = []
        
        while(!empty){
            let point = getFirstWhitePixel(image: image)
            
            if(point != (0,0)){
                let res = getComponentsRecursive(bitmap: inputbitmap!, startpoint: point)
                
                componentlist.append(res)
                
                for pixel in res{
                    imagebitmap!.setColor(black.withAlphaComponent(0), atX: pixel.0, y: pixel.1)
                }
                
                
                let temp = imagebitmap!.cgImage!
                
                image = NSImage(cgImage: temp, size: imagebitmap!.size)
                
            }
            
            if(point == (0,0)){
                empty = true
            }
        }
        
        
        for component in componentlist{
            if(component.count > 5){
                for pixel in component{
                    bitmap!.setColor(white, atX: pixel.0, y: pixel.1)
                }
            }
        }
        
        let cgoutput = bitmap!.cgImage!
        
        let output = NSImage(cgImage: cgoutput, size: bitmap!.size)
        
        return output
        
    }
    
    func getFirstWhitePixel(image: NSImage) -> (Int,Int){
        let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let width = image.size.width
        let height = image.size.height
        var pixel = (0,0)
        
        for i in 0...Int(width)-1{
            for j in 0...Int(height)-1{
                if((bitmap!.colorAt(x: i, y: j)!.blueComponent+bitmap!.colorAt(x: i, y: j)!.redComponent+bitmap!.colorAt(x: i, y: j)!.greenComponent) * bitmap!.colorAt(x: i, y: j)!.alphaComponent > 0){
                    pixel = (i,j)
                    return pixel
                }
            }
        }
        
        return pixel
    }
    
    func getComponentsRecursive(bitmap: NSBitmapImageRep, startpoint: (Int,Int)) -> [(Int,Int)]{
        
        let recursiveQ = DispatchQueue.init(label: "recursiveQ")
        
        var component: [(Int,Int)] = []
        component.append(startpoint)
        bitmap.setColor(black.withAlphaComponent(0), atX: startpoint.0, y: startpoint.1)
        
        var surroundings: [(Int,Int)] = []
        
        for a in [-1,0,1]{
            for b in [-1,0,1]{
                if((0 <= startpoint.0+a) && (startpoint.0+a <= Int(bitmap.size.width)) && (0 <= startpoint.1+b) && (startpoint.1+b <= Int(bitmap.size.height))){
                    
                    if(!(a == 0 && b == 0) && (bitmap.colorAt(x: startpoint.0+a, y: startpoint.1+b)!.blueComponent+bitmap.colorAt(x: startpoint.0+a, y: startpoint.1+b)!.redComponent+bitmap.colorAt(x: startpoint.0+a, y: startpoint.1+b)!.greenComponent) * bitmap.colorAt(x: startpoint.0+a, y: startpoint.1+b)!.alphaComponent > 0){
                        surroundings.append((startpoint.0+a,startpoint.1+b))
                        bitmap.setColor(black, atX: startpoint.0+a, y: startpoint.1+b)
                    }
                }
            }
        }
        
        if(surroundings.count == 0){
            return component
        } else {
        }
        
        for pixel in surroundings{
            recursiveQ.sync {
                component.append(contentsOf: getComponentsRecursive(bitmap: bitmap, startpoint: pixel))
            }
        }
        
        return component
        
    }
    
    func getSkeletonHOR(image: NSImage) -> NSImage{
        let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let blackcopy = bitmap!.copy() as! NSBitmapImageRep
        let width = image.size.width
        let height = image.size.height
        var i = 0
        var j = 0
        var component = 1
        var centerpixellist = [((Int,Int),(Int,Int),Int)]()
        
        for i in 0...Int(width)-1{
            for j in 0...Int(height)-1{
                blackcopy.setColor(black.withAlphaComponent(0), atX:i, y:j)
            }
        }
        
        while(i <= Int(height)-1){
            var startpoint = (0,0)
            var endpoint = (0,0)
            
            var pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            
            while((pixelcolorRaw!.blueComponent+pixelcolorRaw!.redComponent+pixelcolorRaw!.greenComponent) * pixelcolorRaw!.alphaComponent == 0 && j < Int(width)-1){
                j = j+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            startpoint = (j,i)
            
            while((pixelcolorRaw!.blueComponent+pixelcolorRaw!.redComponent+pixelcolorRaw!.greenComponent) * pixelcolorRaw!.alphaComponent > 0 && j < Int(width)-1){
                j = j+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            endpoint = (j-1,i)
            
            if(startpoint != (0,0) && endpoint != (0,0)){
                centerpixellist.append((startpoint,endpoint,component))
                component = component+1
            }
            
            
            
            if(j == Int(width)-1){
                j = 0
                i = i+1
                component = 1
            }
        }
        
        var finalpixellist = [((Int,Int),Int)]()
        
        for entry in centerpixellist{
            let dst = abs(entry.0.0-entry.1.0)
            
            if(entry.0.0 != Int(width)-1 && dst > 1){
                finalpixellist.append(((Int(entry.0.0+abs(entry.0.0-entry.1.0)/2),entry.0.1), entry.2))
            }
        }
        
        
        for componentpixel in finalpixellist{
            blackcopy.setColor(white, atX:componentpixel.0.0, y:componentpixel.0.1)
        }
        
        let output = NSImage(cgImage: blackcopy.cgImage!, size: blackcopy.size)
        return output
        
    }
    
    func getSkeletonVERT(image :NSImage) -> NSImage{
        let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let blackcopy = bitmap!.copy() as! NSBitmapImageRep
        let width = image.size.width
        let height = image.size.height
        var i = 0
        var j = 0
        var component = 1
        var centerpixellist = [((Int,Int),(Int,Int),Int)]()
        
        for i in 0...Int(width)-1{
            for j in 0...Int(height)-1{
                blackcopy.setColor(black.withAlphaComponent(0), atX:i, y:j)
            }
        }
        
        while(j <= Int(width)-1){
            var startpoint = (0,0)
            var endpoint = (0,0)
            
            var pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            
            while((pixelcolorRaw!.blueComponent+pixelcolorRaw!.redComponent+pixelcolorRaw!.greenComponent) * pixelcolorRaw!.alphaComponent == 0 && i < Int(height)-1){
                i = i+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            startpoint = (j,i)
            
            while((pixelcolorRaw!.blueComponent+pixelcolorRaw!.redComponent+pixelcolorRaw!.greenComponent) * pixelcolorRaw!.alphaComponent > 0 && i < Int(height)-1){
                i = i+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            endpoint = (j,i-1)
            
            if(startpoint != (0,0) && endpoint != (0,0)){
                centerpixellist.append((startpoint,endpoint,component))
                component = component+1
            }
            
            
            
            if(i == Int(height)-1){
                i = 0
                j = j+1
                component = 1
            }
        }
        
        var finalpixellist = [((Int,Int),Int)]()
        
        for entry in centerpixellist{
            let dst = abs(entry.0.1-entry.1.1)
            
            if(entry.0.1 != Int(height)-1 && dst > 1){
                finalpixellist.append(((entry.0.0,Int(entry.0.1+abs(entry.0.1-entry.1.1)/2)), entry.2))
            }
        }
        
        
        for componentpixel in finalpixellist{
            //print(componentpixel)
            blackcopy.setColor(white, atX:componentpixel.0.0, y:componentpixel.0.1)
        }
        
        let output = NSImage(cgImage: blackcopy.cgImage!, size: blackcopy.size)
        return output
        
    }
    
    func optimizeSkeleton(image :NSImage) -> NSImage{
        let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let width = image.size.width
        let height = image.size.height
        
        for i in 1...Int(width)-2{
            for j in 1...Int(height)-2{
                
                var topleft :CGFloat = 0
                var topmid :CGFloat = 0
                var topright :CGFloat = 0
                
                var left :CGFloat = 0
                var right :CGFloat = 0
                
                var botleft :CGFloat = 0
                var botmid :CGFloat = 0
                var botright :CGFloat = 0
                
                if((bitmap!.colorAt(x: i-1, y: j-1)!.blueComponent+bitmap!.colorAt(x: i-1, y: j-1)!.redComponent+bitmap!.colorAt(x: i-1, y: j-1)!.greenComponent)*bitmap!.colorAt(x: i-1, y: j-1)!.alphaComponent > 0){
                    topleft = 1
                }
                
                if((bitmap!.colorAt(x: i, y: j-1)!.blueComponent+bitmap!.colorAt(x: i, y: j-1)!.redComponent+bitmap!.colorAt(x: i, y: j-1)!.greenComponent)*bitmap!.colorAt(x: i, y: j-1)!.alphaComponent > 0){
                    topmid = 1
                }
                
                if((bitmap!.colorAt(x: i+1, y: j-1)!.blueComponent+bitmap!.colorAt(x: i+1, y: j-1)!.redComponent+bitmap!.colorAt(x: i+1, y: j-1)!.greenComponent)*bitmap!.colorAt(x: i+1, y: j-1)!.alphaComponent > 0){
                    topright = 1
                }
                
                if((bitmap!.colorAt(x: i-1, y: j)!.blueComponent+bitmap!.colorAt(x: i-1, y: j)!.redComponent+bitmap!.colorAt(x: i-1, y: j)!.greenComponent)*bitmap!.colorAt(x: i-1, y: j)!.alphaComponent > 0){
                    left = 1
                }
                
                if((bitmap!.colorAt(x: i+1, y: j)!.blueComponent+bitmap!.colorAt(x: i+1, y: j)!.redComponent+bitmap!.colorAt(x: i+1, y: j)!.greenComponent)*bitmap!.colorAt(x: i+1, y: j)!.alphaComponent > 0){
                    right = 1
                }
                
                if((bitmap!.colorAt(x: i-1, y: j+1)!.blueComponent+bitmap!.colorAt(x: i-1, y: j+1)!.redComponent+bitmap!.colorAt(x: i-1, y: j+1)!.greenComponent)*bitmap!.colorAt(x: i-1, y: j+1)!.alphaComponent > 0){
                    botleft = 1
                }
                
                if((bitmap!.colorAt(x: i, y: j+1)!.blueComponent+bitmap!.colorAt(x: i, y: j+1)!.redComponent+bitmap!.colorAt(x: i, y: j+1)!.greenComponent)*bitmap!.colorAt(x: i-1, y: j+1)!.alphaComponent > 0){
                    botmid = 1
                }
                
                if((bitmap!.colorAt(x: i+1, y: j+1)!.blueComponent+bitmap!.colorAt(x: i+1, y: j+1)!.redComponent+bitmap!.colorAt(x: i+1, y: j+1)!.greenComponent)*bitmap!.colorAt(x: i+1, y: j+1)!.alphaComponent > 0){
                    botright = 1
                }
                
                let sumall = topleft+topmid+topright+left+right+botleft+botmid+botright
                
                let sumleftcol = topleft+left+botleft
                let sumrightcol = topright+right+botright
                let sumtoprow = topleft+topmid+topright
                let sumbotrow = botleft+botmid+botright
                
                if(bitmap!.colorAt(x: i, y: j)?.alphaComponent == 0 && sumall == 2 && (left+right==2 || topmid+botmid==2 || topleft+right==2 || topright+left==2 || botleft+right==2 || botright+left==2 || botmid+topleft==2 || botmid+topright==2 || topmid+botleft==2 || topmid+botright==2)){
                    bitmap!.setColor(white, atX: i, y: j)
                }
                
                if(bitmap!.colorAt(x: i, y: j)?.alphaComponent == 0 && sumall == 3 && (sumbotrow > 0 && sumtoprow > 0 && sumtoprow+sumbotrow == 3)){
                    bitmap!.setColor(white, atX: i, y: j)
                }
                
                if(bitmap!.colorAt(x: i, y: j)?.alphaComponent == 0 && sumall == 3 && (sumleftcol > 0 && sumrightcol > 0 && sumleftcol+sumrightcol == 3)){
                    bitmap!.setColor(white, atX: i, y: j)
                }
            }
        }
        
        let output = NSImage(cgImage: bitmap!.cgImage!, size: bitmap!.size)
        return output
        
    }
    
}

extension String  {
    func conformsTo(pattern: String) -> Bool {
        let pattern = NSPredicate(format:"SELF MATCHES %@", pattern)
        return pattern.evaluate(with: self)
    }
    
    func isValidUrl() -> Bool {
        let urlRegEx = "^(https?://)?(www\\.)?([-a-z0-9]{1,63}\\.)*?[a-z0-9][-a-z0-9]{0,61}[a-z0-9]\\.[a-z]{2,6}(/[-\\w@\\+\\.~#\\?&/=%]*)?$"
        let urlTest = NSPredicate(format:"SELF MATCHES %@", urlRegEx)
        let result = urlTest.evaluate(with: self)
        return result
    }
}

struct Range {
    var start: Int
    var end: Int
}

struct filterConfig {
    var filterRange1: Range
    var filterRange2: Range
    var filterRange3: Range
    var Smoothing: (Int,Int,Int)
}

extension NSColor {
    
    convenience init(hex: String, alpha: Float){
        var cleanedString = ""
        if hex.hasPrefix("0x") {
            cleanedString = String(hex.suffix(from: hex.index(hex.startIndex, offsetBy: 2)))
        } else if hex.hasPrefix("#") {
            cleanedString = String(hex.suffix(from: hex.index(hex.startIndex, offsetBy: 1)))
        }
        // Ensure it only contains valid hex characters 0
        let validHexPattern = "[a-fA-F0-9]+"
        if cleanedString.conformsTo(pattern: validHexPattern) {
            var theInt: UInt32 = 0
            let scanner = Scanner(string: cleanedString)
            scanner.scanHexInt32(&theInt)
            let red = CGFloat((theInt & 0xFF0000) >> 16) / 255.0
            let green = CGFloat((theInt & 0xFF00) >> 8) / 255.0
            let blue = CGFloat((theInt & 0xFF)) / 255.0
            self.init(calibratedRed: red, green: green, blue: blue, alpha: 1.0)
            
        } else{
            self.init(calibratedWhite: 1, alpha: 1)
        }
    }
}

extension NSImage {
    
    func filter(redRange: Range, greenRange: Range, blueRange: Range, bitmap: NSBitmapImageRep) -> NSImage{
        
        for i in 0...Int(bitmap.size.height)-1{
            let rowStart = bitmap.bitmapData!.advanced(by: (i * (bitmap.bytesPerRow)))
            var nextChannel = rowStart
            
            for _ in 0...Int(bitmap.size.width)-1{
                if((nextChannel[0] > blueRange.end) || (nextChannel[0] < blueRange.start) ){
                    nextChannel[0] = 0
                    nextChannel[1] = 0
                    nextChannel[2] = 0
                    nextChannel[3] = 0
                }
                if((nextChannel[1] > greenRange.end) || (nextChannel[1] < greenRange.start) ){
                    nextChannel[0] = 0
                    nextChannel[1] = 0
                    nextChannel[2] = 0
                    nextChannel[3] = 0
                }
                if((nextChannel[2] > redRange.end) || (nextChannel[2] < redRange.start) ){
                    nextChannel[0] = 0
                    nextChannel[1] = 0
                    nextChannel[2] = 0
                    nextChannel[3] = 0
                }
                nextChannel = nextChannel.advanced(by: bitmap.bitsPerPixel/8)
            }
        }
        
        return NSImage.init(data: bitmap.tiffRepresentation!)!
        
    }
    
    func resize(img: NSImage, w: Int, h: Int) -> NSImage {
        let destSize = NSMakeSize(CGFloat(w), CGFloat(h))
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        img.draw(in: NSMakeRect(0, 0, destSize.width, destSize.height))
        newImage.unlockFocus()
        newImage.size = destSize
        return newImage
    }
    
    func getImageMetrics() -> String{
        
        let bitmap = NSBitmapImageRep.init(data: self.tiffRepresentation!)
        
        let prefix = ""
        
        let width = String(Int(self.size.width))
        let height = String(Int(self.size.height))
        
        let colorSpace = (bitmap?.colorSpaceName.rawValue)!
        let alphaVal = Int(Float((bitmap!.cgImage?.alphaInfo)!.rawValue))
        var alphaInfo = ""
        
        if(alphaVal == 1){
            alphaInfo = "AlphaPremultipliedFirst"
        }
        
        let metricsString = prefix + width + "px x " + height + "px " + " " + colorSpace + " " + alphaInfo
        
        return metricsString
    }
}

func GetNetworkInterfaceAdresses() -> [String] {
    var addresses = [String]()
    
    var ifaddr : UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return [] }
    guard let firstAddr = ifaddr else { return [] }
    
    // For each interface ...
    for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let flags = Int32(ptr.pointee.ifa_flags)
        let addr = ptr.pointee.ifa_addr.pointee
        
        // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
        if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
            if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                
                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if (getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                    let address = String(cString: hostname)
                    addresses.append(address)
                }
            }
        }
    }
    
    freeifaddrs(ifaddr)
    return addresses
}

extension NSImage {
    func saveToFile(as fileName: String, fileType: NSBitmapImageRep.FileType, at directory: URL) -> Bool {
        
        do {
            try NSBitmapImageRep(data: self.tiffRepresentation!)?
                .representation(using: fileType, properties: [:])?
                .write(to: directory.appendingPathComponent(fileName).appendingPathExtension(fileType.pathExtension))
            return true
        } catch {
            return false
        }
    }
}

extension NSBitmapImageRep.FileType {
    var pathExtension: String {
        switch self {
        case .bmp:
            return "bmp"
        case .gif:
            return "gif"
        case .jpeg:
            return "jpg"
        case .jpeg2000:
            return "jp2"
        case .png:
            return "png"
        case .tiff:
            return "tif"
        }
    }
}

extension NSImage {
    
    func getOutlineHor() -> NSImage{
        let bitmap = NSBitmapImageRep.init(data: self.tiffRepresentation!)
        let blackcopy = bitmap!.copy() as! NSBitmapImageRep
        let width = self.size.width
        let height = self.size.height
        let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
        let white = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
        var i = 0
        var j = 0
        var component = 1
        var pixellist = [((Int,Int),(Int,Int),Int)]()
        
        for i in 0...Int(width)-1{
            for j in 0...Int(height)-1{
                blackcopy.setColor(black.withAlphaComponent(0), atX:i, y:j)
            }
        }
        
        while(i <= Int(height)-1){
            var startpoint = (0,0)
            var endpoint = (0,0)
            
            var pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            
            while((pixelcolorRaw!.blueComponent+pixelcolorRaw!.redComponent+pixelcolorRaw!.greenComponent) * pixelcolorRaw!.alphaComponent == 0 && j < Int(width)-1){
                j = j+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            startpoint = (j,i)
            
            while((pixelcolorRaw!.blueComponent+pixelcolorRaw!.redComponent+pixelcolorRaw!.greenComponent) * pixelcolorRaw!.alphaComponent > 0  && j < Int(width)-1){
                j = j+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            endpoint = (j-1,i)
            
            if(startpoint != (0,0) && endpoint != (0,0)){
                pixellist.append((startpoint,endpoint,component))
                component = component+1
            }
            
            
            
            if(j == Int(width)-1){
                j = 0
                i = i+1
                component = 1
            }
        }
        
        for entry in pixellist{
            
            if(entry.0.0 != Int(width)-1){
                blackcopy.setColor(white, atX:entry.0.0, y:entry.0.1)
                blackcopy.setColor(white, atX:entry.1.0, y:entry.1.1)
            }
        }
        
        let output = NSImage(cgImage: blackcopy.cgImage!, size: blackcopy.size)
        return output
        
    }
    
    func getOutlineVert() -> NSImage{
        let bitmap = NSBitmapImageRep.init(data: self.tiffRepresentation!)
        let blackcopy = bitmap!.copy() as! NSBitmapImageRep
        let width = self.size.width
        let height = self.size.height
        let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
        let white = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
        var i = 0
        var j = 0
        var component = 1
        var pixellist = [((Int,Int),(Int,Int),Int)]()
        
        for i in 0...Int(width)-1{
            for j in 0...Int(height)-1{
                blackcopy.setColor(black.withAlphaComponent(0), atX:i, y:j)
            }
        }
        
        while(j <= Int(width)-1){
            var startpoint = (0,0)
            var endpoint = (0,0)
            
            var pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            
            while((pixelcolorRaw!.blueComponent+pixelcolorRaw!.redComponent+pixelcolorRaw!.greenComponent) * pixelcolorRaw!.alphaComponent == 0 && i < Int(height)-1){
                i = i+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            startpoint = (j,i)
            
            while((pixelcolorRaw!.blueComponent+pixelcolorRaw!.redComponent+pixelcolorRaw!.greenComponent) * pixelcolorRaw!.alphaComponent > 0 && i < Int(height)-1){
                i = i+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            endpoint = (j,i-1)
            
            if(startpoint != (0,0) && endpoint != (0,0)){
                pixellist.append((startpoint,endpoint,component))
                component = component+1
            }
            
            if(i == Int(height)-1){
                i = 0
                j = j+1
                component = 1
            }
        }
        
        for entry in pixellist{
            if(entry.0.1 != Int(height)-1 ){
                blackcopy.setColor(white, atX:entry.0.0, y:entry.0.1)
                blackcopy.setColor(white, atX:entry.1.0, y:entry.1.1)
            }
        }
        
        let output = NSImage(cgImage: blackcopy.cgImage!, size: blackcopy.size)
        return output
        
    }
    
    func combineWithImage(refimage: NSImage) -> NSImage{
        let image = self
        let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let refbitmap = NSBitmapImageRep.init(data: refimage.tiffRepresentation!)
        let width = image.size.width
        let height = image.size.height
        let white = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
        
        for i in 0...Int(width)-1{
            for j in 0...Int(height)-1{
                
                let color = refbitmap!.colorAt(x: i, y: j)
                
                if(color!.redComponent+color!.blueComponent+color!.greenComponent > 0){
                    bitmap!.setColor(white, atX: i, y: j)
                }
            }
        }
        let cgoutput = bitmap!.cgImage!
        
        let output = NSImage(cgImage: cgoutput, size: bitmap!.size)
        return output
        
    }
    
}


extension URL {
    func createDir(){
        
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: self.path) {
            do {
                try fileManager.createDirectory(atPath: self.path,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

class PresetData: NSObject, NSCoding{
    
    private var _index = 0
    
    private var _low1 = 0
    private var _low2 = 0
    private var _low3 = 0
    
    private var _high1 = 255
    private var _high2 = 255
    private var _high3 = 255
    
    private var _gaus = 0
    private var _median = 0
    private var _noise = 0
    
    private var _name = "Default"
    
    struct Keys {
        static let index = "index"
        static let name = "name"
        static let low1 = "low1"
        static let low2 = "low2"
        static let low3 = "low3"
        static let high1 = "high1"
        static let high2 = "high2"
        static let high3 = "high3"
        static let gaus = "gaus"
        static let median = "median"
        static let noise = "noise"
    }

    override init() {}
    
    init(index: Int, name: String, low1: Int, low2: Int, low3: Int, high1: Int, high2: Int, high3: Int, gaus: Int, median: Int, noise: Int){
        self._index = index
        self._name = name
        self._low1 = low1
        self._low2 = low2
        self._low3 = low3
        self._high1 = high1
        self._high2 = high2
        self._high3 = high3
        self._gaus = gaus
        self._median = median
        self._noise = noise
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        _index = aDecoder.decodeInteger(forKey: Keys.index)
        _name = (aDecoder.decodeObject(forKey: Keys.name) as? String)!
        _low1 = aDecoder.decodeInteger(forKey: Keys.low1)
        _low2 = aDecoder.decodeInteger(forKey: Keys.low2)
        _low3 = aDecoder.decodeInteger(forKey: Keys.low3)
        _high1 = aDecoder.decodeInteger(forKey: Keys.high1)
        _high2 = aDecoder.decodeInteger(forKey: Keys.high2)
        _high3 = aDecoder.decodeInteger(forKey: Keys.high3)
        _gaus = aDecoder.decodeInteger(forKey: Keys.gaus)
        _median = aDecoder.decodeInteger(forKey: Keys.median)
        _noise = aDecoder.decodeInteger(forKey: Keys.noise)
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(_index, forKey: Keys.index)
        aCoder.encode(_name, forKey: Keys.name)
        aCoder.encode(_low1, forKey: Keys.low1)
        aCoder.encode(_low2, forKey: Keys.low2)
        aCoder.encode(_low3, forKey: Keys.low3)
        aCoder.encode(_high1, forKey: Keys.high1)
        aCoder.encode(_high2, forKey: Keys.high2)
        aCoder.encode(_high3, forKey: Keys.high3)
        aCoder.encode(_gaus, forKey: Keys.gaus)
        aCoder.encode(_median, forKey: Keys.median)
        aCoder.encode(_noise, forKey: Keys.noise)
    }
    
    var index: Int{
        get {
            return _index
        }
        set{
            _index = newValue
        }
    }
    
    var name: String{
        get {
            return _name
        }
        set{
            _name = newValue
        }
    }
    
    var low1: Int{
        get {
            return _low1
        }
        set{
            _low1 = newValue
        }
    }
    
    var low2: Int{
        get {
            return _low2
        }
        set{
            _low2 = newValue
        }
    }
    
    var low3: Int{
        get {
            return _low3
        }
        set{
            _low3 = newValue
        }
    }
    
    var high1: Int{
        get {
            return _high1
        }
        set{
            _high1 = newValue
        }
    }
    
    var high2: Int{
        get {
            return _high2
        }
        set{
            _high2 = newValue
        }
    }
    
    var high3: Int{
        get {
            return _high3
        }
        set{
            _high3 = newValue
        }
    }
    
    var gaus: Int{
        get {
            return _gaus
        }
        set{
            _gaus = newValue
        }
    }
    
    var median: Int{
        get {
            return _median
        }
        set{
            _median = newValue
        }
    }
    
    var noise: Int{
        get {
            return _noise
        }
        set{
            _noise = newValue
        }
    }
    
}
