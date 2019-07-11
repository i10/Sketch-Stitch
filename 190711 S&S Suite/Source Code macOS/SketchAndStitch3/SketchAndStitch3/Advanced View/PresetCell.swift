import Cocoa

class PresetCell: NSTableCellView {
    
    var appDel = NSApplication.shared.delegate as! AppDelegate

    @IBOutlet weak var presetName: NSTextField!
    @IBOutlet weak var selectionMarker: NSTextField!
    @IBOutlet weak var background: NSTextField!
    @IBOutlet weak var deleteButton: NSButton!
    @IBOutlet weak var spectrumView: NSImageView!
    @IBOutlet weak var highlightMarker: NSTextField!
    
    var filterConfig :filterConfig?
    
    @IBAction func delete(_ sender: Any) {
        
        let ownRow = appDel.windowController?.advancedViewController.presetView.row(for: self)
        appDel.windowController?.advancedViewController.presetController.presets.remove(at: ownRow!)
        appDel.windowController?.advancedViewController.presetView.selectRowIndexes(IndexSet.init(integer: 0), byExtendingSelection: false)
        appDel.windowController?.advancedViewController.presetCount += -1
        appDel.windowController?.advancedViewController.presetView.reloadData()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
}
