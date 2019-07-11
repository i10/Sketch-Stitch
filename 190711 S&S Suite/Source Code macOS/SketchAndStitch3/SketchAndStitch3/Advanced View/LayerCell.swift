import Cocoa

class LayerCell: NSTableCellView {

    @IBOutlet weak var layerTitle: NSTextField!
    @IBOutlet weak var layerImageView: NSImageView!
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var visibleButton: NSButton!
    @IBOutlet var selectedMarker: NSTextField!
    @IBOutlet weak var Background: NSTextField!
    @IBOutlet weak var imageBgBox: NSTextField!
    
    @IBOutlet weak var singleStitchButton: NSButton!
    @IBOutlet weak var zigZagStitchButton: NSButton!
    @IBOutlet weak var trippleStitchButton: NSButton!
    @IBOutlet weak var satinStitchButton: NSButton!
    
    var configuration: filterConfig?
    var visible: Bool = true
    var appDel = NSApplication.shared.delegate as! AppDelegate
    var controller :LayerTableController?
    var table :NSTableView?
    var coloringNumber: Int = -1
    var selectedStitch = -1
    
    @IBAction func visibilityChanged(_ sender: Any) {
        if(visible){
            visible = false
            visibleButton.alphaValue = 0.3
        } else{
            visible = true
            visibleButton.alphaValue = 1
        }
    }
    
    @IBAction func stitchChanged(_ sender: Any) {
        
        if(singleStitchButton.integerValue+zigZagStitchButton.integerValue+trippleStitchButton.integerValue+satinStitchButton.integerValue > 0){
            if(singleStitchButton.integerValue == 1 && selectedStitch != 1){
                selectedStitch = 1
                singleStitchButton.alphaValue = 1
                zigZagStitchButton.alphaValue = 0.3
                trippleStitchButton.alphaValue = 0.3
                satinStitchButton.alphaValue = 0.3
                
                zigZagStitchButton.integerValue = 0
                trippleStitchButton.integerValue = 0
                satinStitchButton.integerValue = 0
            }
            
            if(zigZagStitchButton.integerValue == 1 && selectedStitch != 2){
                selectedStitch = 2
                singleStitchButton.alphaValue = 0.3
                zigZagStitchButton.alphaValue = 1
                trippleStitchButton.alphaValue = 0.3
                satinStitchButton.alphaValue = 0.3
                
                singleStitchButton.integerValue = 0
                trippleStitchButton.integerValue = 0
                satinStitchButton.integerValue = 0
            }
            
            if(trippleStitchButton.integerValue == 1 && selectedStitch != 3){
                selectedStitch = 3
                singleStitchButton.alphaValue = 0.3
                zigZagStitchButton.alphaValue = 0.3
                trippleStitchButton.alphaValue = 1
                satinStitchButton.alphaValue = 0.3
                
                singleStitchButton.integerValue = 0
                zigZagStitchButton.integerValue = 0
                satinStitchButton.integerValue = 0
            }
            
            if(satinStitchButton.integerValue == 1 && selectedStitch != 4){
                selectedStitch = 4
                singleStitchButton.alphaValue = 0.3
                zigZagStitchButton.alphaValue = 0.3
                trippleStitchButton.alphaValue = 0.3
                satinStitchButton.alphaValue = 1
                
                singleStitchButton.integerValue = 0
                zigZagStitchButton.integerValue = 0
                trippleStitchButton.integerValue = 0
            }
        } else{
            selectedStitch = -1
            singleStitchButton.alphaValue = 0.3
            zigZagStitchButton.alphaValue = 0.3
            trippleStitchButton.alphaValue = 0.3
            satinStitchButton.alphaValue = 0.3
            
            singleStitchButton.integerValue = 0
            zigZagStitchButton.integerValue = 0
            trippleStitchButton.integerValue = 0
            satinStitchButton.integerValue = 0
        }
        
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.controller = (appDel.windowController?.advancedViewController.layerController)!
        self.table = (appDel.windowController?.advancedViewController.layerView)!
    }

    @IBAction func deleteCell(_ sender: Any) {
        
        if((table!.numberOfRows) > 1){
            
            controller!.layers.remove(at: (table?.row(for: self))!)
            (appDel.windowController?.advancedViewController)!.layerCount = ((appDel.windowController?.advancedViewController)?.layerCount)! - 1
            
            table?.reloadData()
            (appDel.windowController?.advancedViewController)!.layersChanged(self)
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    func updateLayerImage(image: NSImage){
        self.layerImageView.image = image
    }
    
}
