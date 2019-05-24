//
//  TableColorCell.swift
//  sketchandstitch
//
//  Created by Kirill Timchenko on 19.01.19.
//  Copyright © 2019 Kirill Timchenko. All rights reserved.
//

import Cocoa

class TableColorCell: NSTableCellView {
    
    @IBOutlet weak var filterState: NSButtonCell!
    @IBOutlet weak var colorName: NSTextFieldCell!
    
    var id = 0
    
    @IBAction func colorSelected(_ sender: Any) {
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        var configList = appDelegate.userConfigList
        
        if(filterState.intValue == 1){
            configList[colorName.stringValue] = configList[colorName.stringValue]! + [appDelegate.selectedConfig]
            appDelegate.userConfigList = configList
        }
        
        if(filterState.intValue == 0){
            let removeind = configList[colorName.stringValue]!.firstIndex(of: appDelegate.selectedConfig)
            configList[colorName.stringValue]!.remove(at: removeind!)
            appDelegate.userConfigList = configList
        }
        
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
}
