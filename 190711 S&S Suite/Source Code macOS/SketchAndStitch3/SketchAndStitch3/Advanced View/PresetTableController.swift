import Cocoa

class PresetTableController: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    
    var presets: ContiguousArray<PresetCell>! = []
    var appDel = NSApplication.shared.delegate as! AppDelegate
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (presets!.count)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        return presets[row]
    }
    
}
