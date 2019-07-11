import Cocoa

class Slider: NSSlider {
    
    enum DraggedSlider {
        case start
        case end
    }
    
    struct SelectionRange {
        var start: Double
        var end: Double
    }
    
    private var currentSliderDragging: DraggedSlider? = nil
    
    var refSlider1: Slider?
    var refSlider2: Slider?
    
    var lastLow = 0
    var lastHigh = 255
    
    var selection: SelectionRange = SelectionRange(start: 0.0, end: 255)

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        selection.start = minValue
        selection.end = maxValue
        let newbounds = NSSize.init(width: bounds.width, height: bounds.height+25)
        let neworigin = NSPoint.init(x: frame.minX, y: frame.minY-15)
        setFrameSize(newbounds)
        setFrameOrigin(neworigin)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func mouseUp(with event: NSEvent) {
        sendAction(action, to: target)
    }
    
    func checkForAction(){
        if(Int(floor(selection.start)) != lastLow || Int(floor(selection.end)) != lastHigh){
            lastLow = Int(floor(selection.start))
            lastHigh = Int(floor(selection.end))
            sendAction(action, to: target)
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        
        currentSliderDragging = nil
        
        var point = convert(event.locationInWindow, from: nil)
        point = NSPoint.init(x: point.x-8, y: point.y)
        let cell = self.cell as! SliderCell
        
        if(point.x < cell.barRect(flipped: false).minX){
            point.x = cell.barRect(flipped: false).minX
        }
        if(point.x > cell.barRect(flipped: false).maxX){
            point.x = cell.barRect(flipped: false).maxX
        }
        
        let startSlider = cell.knobRect(flipped: false)
        let endSlider = cell.knobRectSecond()
        
        let diststart = abs(point.x-startSlider.midX + point.y-startSlider.midY)
        let distend = abs(point.x-endSlider.midX + point.y-endSlider.midY)
        
        if diststart < distend {
            currentSliderDragging = .start
        } else if distend < diststart{
            currentSliderDragging = .end
        } else{
            let borderDist = min(startSlider.midX, CGFloat(maxValue)-endSlider.midX)
            
            if(borderDist == startSlider.midX){
                currentSliderDragging = .end
            } else{
                currentSliderDragging = .start
            }
        }
        
        if(selection.start == 0 && selection.end == 0){
            currentSliderDragging = .end
        }
        
        if(selection.start == maxValue && selection.end == maxValue){
            currentSliderDragging = .start
        }
        
        updateForClick(atPoint: point)
        
    }
    
    override func mouseDragged(with event: NSEvent) {
        
        let cell = self.cell as! SliderCell
        var point = convert(event.locationInWindow, from: nil)
        point = NSPoint.init(x: point.x-8, y: point.y)
        
        if(point.x < cell.barRect(flipped: false).minX){
            point.x = cell.barRect(flipped: false).minX
        }
        if(point.x > cell.barRect(flipped: false).maxX){
            point.x = cell.barRect(flipped: false).maxX
        }
        updateForClick(atPoint: point)
        
        checkForAction()
    }
    
    private func updateForClick(atPoint point: NSPoint) {
        
        let cell = self.cell as! SliderCell
        
        if currentSliderDragging != nil {
            let bnds = cell.barRect(flipped: false).width-20
            var x = Double((point.x/bnds * CGFloat(maxValue))-CGFloat(Int(maxValue/50)))
            x = max(min(maxValue, x), 0.0)
            
            if currentSliderDragging! == .start {
                if(Int(x) > Int(cell.secondKnobValue)){
                    x = cell.secondKnobValue
                    NSSound(named: "Basso")?.play()
                }
                selection = SelectionRange(start: x, end: cell.secondKnobValue)
                cell.doubleValue = selection.start
            } else {
                if(x < cell.doubleValue){
                    x = cell.doubleValue
                    NSSound(named: "Basso")?.play()
                }
                selection = SelectionRange(start: cell.doubleValue, end: x)
                cell.secondKnobValue = selection.end
            }
            
        }
        
        self.needsDisplay = true
        refSlider1?.needsDisplay = true
        refSlider2?.needsDisplay = true
    }
    
    func getRef()->Int{
        return Int((selection.start+selection.end)/2)
    }
    
}
