import Cocoa

class CustomSegmentedCell: NSSegmentedCell {
    
    var label: String?
    var labelFont: NSFont?
    var labelColor = NSColor.init(calibratedRed: 1, green: 1, blue: 1, alpha: 1)
    var labelStyle = NSMutableParagraphStyle()
    var drawingOptions: NSString.DrawingOptions?
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        labelFont = NSFont.systemFont(ofSize: 13, weight: NSFont.Weight.bold)
        labelStyle.alignment = .center
        drawingOptions = NSString.DrawingOptions.init(rawValue: 0)
    }
    
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        
        super.drawInterior(withFrame: cellFrame, in: controlView)
        
        let labelAttributes = [NSAttributedString.Key.font: labelFont, NSAttributedString.Key.foregroundColor: NSColor.init(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1), NSAttributedString.Key.paragraphStyle: labelStyle]
        let label: NSAttributedString = NSAttributedString.init(string: title, attributes: labelAttributes as [NSAttributedString.Key : Any])
        label.draw(with: cellFrame,options: self.drawingOptions!)
        
        
    }
    
    override func drawSegment(_ segment: Int, inFrame frame: NSRect, with controlView: NSView) {
        
        let selectFrame:NSRect?
        var endFrame: NSRect?
        var cellInteriorFrame: NSBezierPath?
        var removedPart: NSRect?
        
        if(segment < 1){
            selectFrame = NSRect.init(x: frame.minX+2, y: frame.minY+2, width: frame.width+2, height: frame.height-3)
            endFrame = NSRect.init(x: selectFrame!.maxX, y: selectFrame!.minY, width: 1, height: selectFrame!.height)
            
            let removeEnd = NSRect.init(x: selectFrame!.minX, y: selectFrame!.minY, width: selectFrame!.width-3, height: selectFrame!.height)
            removeEnd.clip()
            cellInteriorFrame = NSBezierPath.init(rect: NSRect.init(x: frame.minX+2, y: frame.minY+2, width: frame.width+4, height: frame.height-3))
            removedPart = NSRect.init(x: selectFrame!.maxX-3, y: selectFrame!.minY, width: 3, height: selectFrame!.height)
        } else{
            selectFrame = NSRect.init(x: frame.minX+2, y: frame.minY+2, width: frame.width+2, height: frame.height-3)
            endFrame = NSRect.init(x: selectFrame!.minX-1, y: selectFrame!.minY, width: 1, height: selectFrame!.height)
            
            let removeStart = NSRect.init(x: selectFrame!.minX+3, y: selectFrame!.minY, width: selectFrame!.width-3, height: selectFrame!.height)
            removeStart.clip()
            cellInteriorFrame = NSBezierPath.init(rect: NSRect.init(x: frame.minX, y: frame.minY+2, width: frame.width-2, height: frame.height-3))
            removedPart = NSRect.init(x: selectFrame!.minX, y: selectFrame!.minY, width: 3, height: selectFrame!.height)
        }
        
        let select = NSBezierPath.init(roundedRect: selectFrame!, xRadius: 4, yRadius: 4)
        
        if((controlView as! CustomSegmentedControl).isEnabled(forSegment: segment)){
            if((controlView as! CustomSegmentedControl).isSelected(forSegment: segment)){
                NSColor.init(white: 0, alpha: 0.6).setFill()
                select.fill()
                cellInteriorFrame!.setClip()
                removedPart!.fill()
                NSColor.init(red: 14/255, green: 14/255, blue: 14/255, alpha: 1.0).setFill()
                endFrame?.fill()
                labelColor = NSColor.init(calibratedRed: 0.8, green: 0.8, blue: 0.8, alpha: 1)
                labelFont = NSFont.systemFont(ofSize: 13, weight: NSFont.Weight.bold)
            } else{
                labelColor = NSColor.init(white: 0.15, alpha: 1)
                labelFont = NSFont.systemFont(ofSize: 13, weight: NSFont.Weight.regular)
            }
        } else{
            labelColor = NSColor.init(white: 0.15, alpha: 0.3)
            labelFont = NSFont.systemFont(ofSize: 13, weight: NSFont.Weight.regular)
        }

        
        let labelAttributes = [NSAttributedString.Key.font: labelFont, NSAttributedString.Key.foregroundColor: labelColor, NSAttributedString.Key.paragraphStyle: labelStyle]
        
        
        let cellLabel: NSAttributedString = NSAttributedString.init(string: label(forSegment: segment)!, attributes: labelAttributes as [NSAttributedString.Key : Any])
        
        let textframe = NSRect.init(x: selectFrame!.minX, y: selectFrame!.minY+1, width: selectFrame!.width, height: selectFrame!.height)
        cellLabel.draw(in: textframe)
        
        
        
        

    }

}
