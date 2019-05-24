//
//  AppDelegate.swift
//  sketchandstitch
//
//  Created by Kirill Timchenko on 07.11.18.
//  Copyright © 2018 Kirill Timchenko. All rights reserved.
//

import Cocoa
import Accelerate

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var userColorList: [String: ((Int,Int,Int),(Int,Int,Int),Int,(Int,Int,Int))] = [:]
    var userConfigList: [String: [Int]] = [:]
    var currentLoadedImage :NSImage!
    var isStockImage = true
    var RecieveServerStarted = false
    
    var selectedConfig = 1
    var numberOfConfigs = 1
    
    var i = 0
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let file = "UserColorList"
        let config = "ConfigList"
        
        let desktopDirectory  = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        
        let fileURL = desktopDirectory.appendingPathComponent(file)
        let configURL = desktopDirectory.appendingPathComponent(config)
        
        do {
            let dataraw = try String(contentsOf: fileURL, encoding: String.Encoding.utf8)
            
            let datasorted = dataraw.components(separatedBy: .newlines)
            
            for entry in datasorted{
                if(entry != ""){
                    let key = entry.components(separatedBy: ":")[0]
                    
                    userConfigList[key] = []
                    
                    let range = entry.components(separatedBy: ":")[1].components(separatedBy: CharacterSet.decimalDigits.inverted)
                    var rangeclean: [Int] = []
                    
                    for element in range{
                        if(element != ""){
                            rangeclean.append(Int(element)!)
                        }
                    }
                    
                    let color = entry.components(separatedBy: ":")[2].components(separatedBy: CharacterSet.decimalDigits.inverted)
                    var colorclean: [Int] = []
                    
                    for element in color{
                        if(element != ""){
                            colorclean.append(Int(element)!)
                        }
                    }
                    
                    userColorList[key] = ((rangeclean[0],rangeclean[1],rangeclean[2]),(rangeclean[3],rangeclean[4],rangeclean[5]), rangeclean[6],(colorclean[0],colorclean[1],colorclean[2]))
                    
                }
                
                
            }
        } catch {
            print("ERROR: Could not find or load colorlist.")
        }
        
        do {
            let dataraw = try String(contentsOf: configURL, encoding: String.Encoding.utf8)
            
            let datasorted = dataraw.components(separatedBy: .newlines)
            
            for entry in datasorted{
                if(entry != ""){
                    let key = entry.components(separatedBy: ":")[0]
                    self.numberOfConfigs = Int(entry.components(separatedBy: ":")[2])!
                    
                    let range = entry.components(separatedBy: ":")[1].components(separatedBy: ",")
                    var rangeclean: [Int] = []
                    
                    for element in range{
                        if(element != ""){
                            rangeclean.append(Int(element)!)
                        }
                    }
                    
                    userConfigList[key] = rangeclean
                    
                }
                
            }
        } catch {
            print("ERROR: Could not find or load configList.")
        }
        
        self.i = 1
        
    }
    func applicationWillTerminate(_ aNotification: Notification) {
        if(!(userColorList.isEmpty)){
            let file = "UserColorList"
            
            let desktopDirectory  = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            
            let fileURL = desktopDirectory.appendingPathComponent(file)
            
            let emptystring = ""
            do {
                try emptystring.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            } catch  {
                print("[ERROR] Could not create user color list file.")
            }
            
            do {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                
                
                for color in userColorList{
                    fileHandle.seekToEndOfFile()
                    let datastring = String(color.key)+": (("+String(color.value.0.0)+","+String(color.value.0.1)+","+String(color.value.0.2)+"),("+String(color.value.1.0)+","+String(color.value.1.1)+","+String(color.value.1.2)+")"+","+String(color.value.2)+"):("+String(color.value.3.0)+","+String(color.value.3.1)+","+String(color.value.3.2)+")"+"\r\n"
                    fileHandle.write(datastring.data(using: String.Encoding.utf8)!)
                }
                
            } catch {
                print("[ERROR] Could not save user colors to file.")
            }
        }
        
        if(!(userConfigList.isEmpty)){
            let config = "ConfigList"
            let desktopDirectory  = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
            let fileURL = desktopDirectory.appendingPathComponent(config)
            
            let emptystring = ""
            do {
                try emptystring.write(to: fileURL, atomically: true, encoding: String.Encoding.utf8)
            } catch  {
                print("[ERROR] Could not create color configuration file.")
            }
            
            do {
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                
                
                for color in userConfigList{
                    fileHandle.seekToEndOfFile()
                    var fullIdString = ""
                    for configid in color.value{
                        fullIdString = fullIdString + String(configid) + ","
                    }
                    
                    fullIdString = fullIdString + ":"+String(self.numberOfConfigs)
                    
                    let datastring = String(color.key)+":"+fullIdString+"\r\n"
                    fileHandle.write(datastring.data(using: String.Encoding.utf8)!)
                }
                
            } catch {
                print("[ERROR] Could not save configurations to file.")
            }
            
        }
    }
    
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        NSApplication.shared.terminate(self)
        return true
    }
    
    
}

extension NSImage {
    func saveToFile(as fileName: String, fileType: NSBitmapImageRep.FileType = .jpeg, at directory: URL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)) -> Bool {
        guard let tiffRepresentation = tiffRepresentation, directory.hasDirectoryPath, !fileName.isEmpty else { return false }
        do {
            try NSBitmapImageRep(data: tiffRepresentation)?
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

public extension NSImage {
    public func rotateImageByAngle(angle:CGFloat) -> NSImage {
        
        var imageBounds = NSZeroRect
        imageBounds.size = self.size
        let pathBounds = NSBezierPath(rect: imageBounds)
        var transform = NSAffineTransform()
        transform.rotate(byDegrees: angle)
        pathBounds.transform(using: transform as AffineTransform)
        let rotatedBounds:NSRect = NSMakeRect(NSZeroPoint.x, NSZeroPoint.y , max(self.size.width,self.size.height), max(self.size.width,self.size.height))
        let rotatedImage = NSImage(size: rotatedBounds.size)
        
        imageBounds.origin.x = NSMidX(rotatedBounds) - (NSWidth(imageBounds) / 2)
        imageBounds.origin.y  = NSMidY(rotatedBounds) - (NSHeight(imageBounds) / 2)
        
        transform = NSAffineTransform()
        
        transform.translateX(by: +(NSWidth(rotatedBounds) / 2 ), yBy: +(NSHeight(rotatedBounds) / 2))
        transform.rotate(byDegrees: angle)
        
        transform.translateX(by: -(NSWidth(rotatedBounds) / 2 ), yBy: -(NSHeight(rotatedBounds) / 2))
        
        rotatedImage.lockFocus()
        transform.concat()
        self.draw(in: imageBounds, from: NSZeroRect, operation: NSCompositingOperation.copy, fraction: 1.0)
        rotatedImage.unlockFocus()
        
        return rotatedImage
    }
}

extension NSImage {
    func getOutlineHor() -> NSImage{
        var image = self
        image = OpenCV.getBlackAndWhiteVersion(image)
        let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let blackcopy = bitmap!.copy() as! NSBitmapImageRep
        let width = image.size.width
        let height = image.size.height
        let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
        let white = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
        var i = 0
        var j = 0
        var component = 1
        var pixellist = [((Int,Int),(Int,Int),Int)]()
        
        for i in 0...Int(width)-1{
            for j in 0...Int(height)-1{
                blackcopy.setColor(black, atX:i, y:j)
            }
        }
        
        while(i <= Int(height)-1){
            var startpoint = (0,0)
            var endpoint = (0,0)
            
            var pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            
            while(pixelcolorRaw!.blueComponent <= 0.1 && j < Int(width)-1){
                j = j+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            startpoint = (j,i)
            
            while(pixelcolorRaw!.blueComponent > 0.1 && j < Int(width)-1){
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
        var image = self
        image = OpenCV.getBlackAndWhiteVersion(image)
        let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let blackcopy = bitmap!.copy() as! NSBitmapImageRep
        let width = image.size.width
        let height = image.size.height
        let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
        let white = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
        var i = 0
        var j = 0
        var component = 1
        var pixellist = [((Int,Int),(Int,Int),Int)]()
        
        for i in 0...Int(width)-1{
            for j in 0...Int(height)-1{
                blackcopy.setColor(black, atX:i, y:j)
            }
        }
        
        while(j <= Int(width)-1){
            var startpoint = (0,0)
            var endpoint = (0,0)
            
            var pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            
            while(pixelcolorRaw!.blueComponent <= 0.1 && i < Int(height)-1){
                i = i+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            startpoint = (j,i)
            
            while(pixelcolorRaw!.blueComponent > 0.1 && i < Int(height)-1){
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
    
    func getSkeletonHOR() -> NSImage{
        var image = self
        image = OpenCV.getBlackAndWhiteVersion(image)
        let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let blackcopy = bitmap!.copy() as! NSBitmapImageRep
        let width = image.size.width
        let height = image.size.height
        let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
        let white = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
        var i = 0
        var j = 0
        var component = 1
        var centerpixellist = [((Int,Int),(Int,Int),Int)]()
        
        for i in 0...Int(width)-1{
            for j in 0...Int(height)-1{
                blackcopy.setColor(black, atX:i, y:j)
            }
        }
        
        while(i <= Int(height)-1){
            var startpoint = (0,0)
            var endpoint = (0,0)
            
            var pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            
            while(pixelcolorRaw!.blueComponent <= 0.1 && j < Int(width)-1){
                j = j+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            startpoint = (j,i)
            
            while(pixelcolorRaw!.blueComponent > 0.1 && j < Int(width)-1){
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
    
    func getSkeletonVERT() -> NSImage{
        var image = self
        image = OpenCV.getBlackAndWhiteVersion(image)
        let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let blackcopy = bitmap!.copy() as! NSBitmapImageRep
        let width = image.size.width
        let height = image.size.height
        let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
        let white = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
        var i = 0
        var j = 0
        var component = 1
        var centerpixellist = [((Int,Int),(Int,Int),Int)]()
        
        for i in 0...Int(width)-1{
            for j in 0...Int(height)-1{
                blackcopy.setColor(black, atX:i, y:j)
            }
        }
        
        while(j <= Int(width)-1){
            var startpoint = (0,0)
            var endpoint = (0,0)
            
            var pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            
            while(pixelcolorRaw!.blueComponent <= 0.1 && i < Int(height)-1){
                i = i+1
                pixelcolorRaw = bitmap!.colorAt(x: j, y: i)
            }
            
            startpoint = (j,i)
            
            while(pixelcolorRaw!.blueComponent > 0.1 && i < Int(height)-1){
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
    
    func optimizeSkeleton() -> NSImage{
        let image = self
        let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
        let width = image.size.width
        let height = image.size.height
        let white = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
        let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
        
        for i in 1...Int(width)-2{
            for j in 1...Int(height)-2{
                let topleft = bitmap!.colorAt(x: i-1, y: j-1)!.blueComponent
                let topmid = bitmap!.colorAt(x: i, y: j-1)!.blueComponent
                let topright = bitmap!.colorAt(x: i+1, y: j-1)!.blueComponent
                
                let left = bitmap!.colorAt(x: i-1, y: j)!.blueComponent
                let right = bitmap!.colorAt(x: i+1, y: j)!.blueComponent
                
                let botleft = bitmap!.colorAt(x: i-1, y: j+1)!.blueComponent
                let botmid = bitmap!.colorAt(x: i, y: j+1)!.blueComponent
                let botright = bitmap!.colorAt(x: i+1, y: j+1)!.blueComponent
                
                let sumall = topleft+topmid+topright+left+right+botleft+botmid+botright
                
                let sumleftcol = topleft+left+botleft
                let sumrightcol = topright+right+botright
                let sumtoprow = topleft+topmid+topright
                let sumbotrow = botleft+botmid+botright
                
                if(bitmap!.colorAt(x: i, y: j) == black && sumall == 2 && (left+right==2 || topmid+botmid==2 || topleft+right==2 || topright+left==2 || botleft+right==2 || botright+left==2 || botmid+topleft==2 || botmid+topright==2 || topmid+botleft==2 || topmid+botright==2)){
                    bitmap!.setColor(white, atX: i, y: j)
                }
                
                if(bitmap!.colorAt(x: i, y: j) == black && sumall == 3 && (sumbotrow > 0 && sumtoprow > 0 && sumtoprow+sumbotrow == 3)){
                    bitmap!.setColor(white, atX: i, y: j)
                }
                
                if(bitmap!.colorAt(x: i, y: j) == black && sumall == 3 && (sumleftcol > 0 && sumrightcol > 0 && sumleftcol+sumrightcol == 3)){
                    bitmap!.setColor(white, atX: i, y: j)
                }
            }
        }
        
        let output = NSImage(cgImage: bitmap!.cgImage!, size: bitmap!.size)
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
                if(refbitmap!.colorAt(x: i, y: j) == white){
                    bitmap!.setColor(white, atX: i, y: j)
                }
            }
        }
        let cgoutput = bitmap!.cgImage!
        
        let output = NSImage(cgImage: cgoutput, size: bitmap!.size)
        return output
        
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

func getComponentsRecursive(bitmap: NSBitmapImageRep, startpoint: (Int,Int)) -> [(Int,Int)]{
    let debugqueue = DispatchQueue.init(label: "DebugQ")
    
    let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
    
    var component: [(Int,Int)] = []
    component.append(startpoint)
    bitmap.setColor(black, atX: startpoint.0, y: startpoint.1)
    
    var surroundings: [(Int,Int)] = []
    
    for a in [-1,0,1]{
        for b in [-1,0,1]{
            if((0 <= startpoint.0+a) && (startpoint.0+a <= Int(bitmap.size.width)) && (0 <= startpoint.1+b) && (startpoint.1+b <= Int(bitmap.size.height))){
                
                if(!(a == 0 && b == 0) && bitmap.colorAt(x: startpoint.0+a, y: startpoint.1+b)!.blueComponent >= 0.1){
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
        debugqueue.sync {
            component.append(contentsOf: getComponentsRecursive(bitmap: bitmap, startpoint: pixel))
        }
    }
    
    return component
    
}

func getFirstWhitePixel(image: NSImage) -> (Int,Int){
    let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
    let width = image.size.width
    let height = image.size.height
    var pixel = (0,0)
    
    for i in 0...Int(width)-1{
        for j in 0...Int(height)-1{
            if(bitmap!.colorAt(x: i, y: j)!.blueComponent > 0.1){
                pixel = (i,j)
                return pixel
            }
        }
    }
    
    return pixel
}

func getFilteredComponents(img: NSImage) -> NSImage {
    
    var image = img
    let inputbitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
    let imagebitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
    let bitmap = NSBitmapImageRep.init(data: image.tiffRepresentation!)
    
    let width = image.size.width
    let height = image.size.height
    let white = NSColor(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
    let black = NSColor(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
    var empty = false
    
    for i in 0...Int(width)-1{
        for j in 0...Int(height)-1{
            bitmap!.setColor(black, atX: i, y: j)
        }
    }
    
    var componentlist: [[(Int,Int)]] = []
    
    while(!empty){
        let point = getFirstWhitePixel(image: image)
        
        if(point != (0,0)){
            let res = getComponentsRecursive(bitmap: inputbitmap!, startpoint: point)
            
            componentlist.append(res)
            
            for pixel in res{
                imagebitmap!.setColor(black, atX: pixel.0, y: pixel.1)
            }
            
            
            let temp = imagebitmap!.cgImage!
            
            image = NSImage(cgImage: temp, size: imagebitmap!.size)
            
        }
        
        if(point == (0,0)){
            empty = true
        }
    }
    
    
    for component in componentlist{
        if(component.count > 20){
            for pixel in component{
                bitmap!.setColor(white, atX: pixel.0, y: pixel.1)
            }
        }
    }
    
    let cgoutput = bitmap!.cgImage!
    
    let output = NSImage(cgImage: cgoutput, size: bitmap!.size)
    
    return output
    
}
