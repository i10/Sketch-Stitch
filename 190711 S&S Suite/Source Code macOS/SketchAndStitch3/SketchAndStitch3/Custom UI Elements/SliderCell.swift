import Cocoa
import AppKit

@IBDesignable
class SliderCell: NSSliderCell {
    
    var secondKnobValue :Double = 0
    
    var gradient :ContiguousArray<ContiguousArray<ContiguousArray<NSColor>>> =  []
    
    var refRed :Int = 127
    var refGreen :Int = 127
    var refBlue :Int = 127
    
    @IBInspectable var cellType :String = "Red"
    
    var labelFont: NSFont?
    var knobFont: NSFont?
    var labelColor = NSColor.init(calibratedRed: 0, green: 0, blue: 0, alpha: 1)
    var paragraphStyle = NSMutableParagraphStyle()
    var labelStyle = NSMutableParagraphStyle()
    var drawingOptions: NSString.DrawingOptions?
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        self.secondKnobValue = maxValue
        self.doubleValue = minValue
        self.controlView!.wantsLayer = true
        
        labelFont = NSFont.systemFont(ofSize: 7, weight: NSFont.Weight.regular)
        knobFont = NSFont.systemFont(ofSize: 9, weight: NSFont.Weight.bold)
        paragraphStyle.alignment = .center
        drawingOptions = NSString.DrawingOptions.init(rawValue: 1)
    }
    
    override func drawKnob() {
        let firstKnobRect = knobRect(flipped: false)
        let secondKnobRect = knobRectSecond()
        drawKnob(firstKnobRect)
        drawsSecondKnob(secondKnobRect)
        
    }
    
    override func drawKnob(_ knobRect: NSRect) {
        
        let shadowRect = NSRect.init(x: knobRect.minX+3, y: 10.5, width: knobRect.width-6, height: knobRect.width-6)
        let shadow = NSBezierPath.init(roundedRect: shadowRect, xRadius: 10, yRadius: 10)
        
        let knobRectNew = NSRect.init(x: shadowRect.minX+1, y: shadowRect.minY+1, width: shadowRect.width-2, height: shadowRect.width-2)
        let knob = NSBezierPath.init(roundedRect: knobRectNew, xRadius: 10, yRadius: 10)
        
        let labelRect = NSRect.init(x: knobRectNew.minX-4.5, y: knobRectNew.maxY, width: knobRectNew.width+10, height: knobRectNew.height)
        let label = String(Int(doubleValue))
        let labelAttributes = [NSAttributedString.Key.font: knobFont, NSAttributedString.Key.foregroundColor: NSColor.white.withAlphaComponent(1), NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let knobLabel: NSAttributedString = NSAttributedString.init(string: label, attributes: labelAttributes as [NSAttributedString.Key : Any])
        
        NSColor.black.withAlphaComponent(1).setFill()
        shadow.fill()
        
        switch cellType {
        case "Red":
            gradient[Int((Double(doubleValue)/maxValue) * 255)][refGreen][refBlue].setFill()
            break
        case "Green":
            gradient[refRed][Int((Double(doubleValue)/maxValue) * 255)][refBlue].setFill()
            break
        case "Blue":
            gradient[refRed][refGreen][Int((Double(doubleValue)/maxValue) * 255)].setFill()
            break
        default:
            NSColor.white.setFill()
        }
        
        knob.fill()
        knobLabel.draw(in: labelRect)
        
    }
    
    func drawsSecondKnob(_ knobRect: NSRect) {
        
        let shadowRect = NSRect.init(x: knobRect.minX+3, y: 10.5, width: knobRect.width-6, height: knobRect.width-6)
        let shadow = NSBezierPath.init(roundedRect: shadowRect, xRadius: 10, yRadius: 10)
        
        let knobRectNew = NSRect.init(x: shadowRect.minX+1, y: shadowRect.minY+1, width: shadowRect.width-2, height: shadowRect.height-2)
        let knob = NSBezierPath.init(roundedRect: knobRectNew, xRadius: 10, yRadius: 10)
        
        let labelRect = NSRect.init(x: knobRectNew.minX-4.5, y: knobRectNew.minY-13.5, width: knobRectNew.width+10, height: knobRectNew.height)
        let label = String(Int(secondKnobValue))
        let labelAttributes = [NSAttributedString.Key.font: knobFont, NSAttributedString.Key.foregroundColor: NSColor.white.withAlphaComponent(1), NSAttributedString.Key.paragraphStyle: paragraphStyle]
        let knobLabel: NSAttributedString = NSAttributedString.init(string: label, attributes: labelAttributes as [NSAttributedString.Key : Any])
        
        NSColor.black.withAlphaComponent(1).setFill()
        shadow.fill()
        
        switch cellType {
        case "Red":
            gradient[Int((Double(secondKnobValue)/maxValue) * 255)][refGreen][refBlue].setFill()
            break
        case "Green":
            gradient[refRed][Int((Double(secondKnobValue)/maxValue) * 255)][refBlue].setFill()
            break
        case "Blue":
            gradient[refRed][refGreen][Int((Double(secondKnobValue)/maxValue) * 255)].setFill()
            break
        default:
            NSColor.white.setFill()
        }
        
        knob.fill()
        knobLabel.draw(in: labelRect)
        
    }
    
    func knobRectSecond() -> NSRect{
        return NSRect.init(x: (CGFloat(secondKnobValue)/CGFloat(maxValue))*253, y: knobRect(flipped: false).minY, width: knobRect(flipped: false).width, height: knobRect(flipped: false).height)
    }
    
    override func drawBar(inside rect: NSRect, flipped: Bool) {
        
        let shadowRect = NSRect.init(x: rect.minX+2, y: rect.minY-7, width: rect.width-2, height: 11)
        let barRect = NSRect.init(x: shadowRect.minX+1, y: shadowRect.minY+1, width: shadowRect.width-2, height: shadowRect.height-2)
        let overlayLeft = NSRect.init(x: shadowRect.minX+1, y: shadowRect.minY+1, width: knobRect(flipped: false).midX, height: shadowRect.height-2)
        let overlayRight = NSRect.init(x: knobRectSecond().midX, y: shadowRect.minY+1, width: shadowRect.maxX-knobRectSecond().midX, height: shadowRect.height-2)
        
        
        let radius :CGFloat = 5
        
        let shadow = NSBezierPath.init(roundedRect: shadowRect, xRadius: radius, yRadius: radius)
        let bar = NSBezierPath.init(roundedRect: barRect, xRadius: radius, yRadius: radius)
        let overleft = NSBezierPath.init(roundedRect: overlayLeft, xRadius: radius, yRadius: radius)
        let overright = NSBezierPath.init(roundedRect: overlayRight, xRadius: radius, yRadius: radius)
        
        let labelRect = NSRect.init(x: barRect.minX, y: barRect.minY-10, width: 30, height: 18)
        let labelAttributes = [NSAttributedString.Key.font: labelFont, NSAttributedString.Key.foregroundColor: NSColor.white.withAlphaComponent(0.3), NSAttributedString.Key.paragraphStyle: labelStyle]
        let barLabel: NSAttributedString = NSAttributedString.init(string: cellType, attributes: labelAttributes as [NSAttributedString.Key : Any])
        
        var subArray :[NSColor] = []
            
        switch cellType {
        case "Red":
            for red in 0...255{
                subArray.insert(gradient[red][refGreen][refBlue], at: red)
            }
            break
        case "Green":
            for green in 0...255{
                subArray.insert(gradient[refRed][green][refBlue], at: green)
            }
            break
        case "Blue":
            for blue in 0...255{
                subArray.insert(gradient[refRed][refGreen][blue], at: blue)
            }
            break
        default:
            subArray.insert(NSColor.white, at: 0)
        }
            
        let gradientor = NSGradient.init(colors: subArray)
        
        NSColor.black.withAlphaComponent(1).setFill()
        shadow.fill()
        gradientor?.draw(in: bar, angle: 0)
        NSColor.black.withAlphaComponent(0.6).setFill()
        overleft.fill()
        overright.fill()
        barLabel.draw(in: labelRect)
        
        
    }

}
