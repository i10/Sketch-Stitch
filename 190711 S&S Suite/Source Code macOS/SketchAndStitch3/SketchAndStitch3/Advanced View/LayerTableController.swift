import Cocoa

class LayerTableController: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    
    var layers: ContiguousArray<LayerCell>! = []
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return (layers!.count)
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {

        return layers![row]
        
    }
}
