import Cocoa

class ColorCollection: NSCollectionView, NSCollectionViewDataSource, NSCollectionViewDelegate {
    
    var bAndW = 0
    var isEnabled = true
    
    var colors : ContiguousArray<ColorCollectionItem> = []
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return 100
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let newItem = makeItem(withIdentifier: .init(rawValue: "ColorCollectionItem"), for: indexPath) as! ColorCollectionItem
        
        if(bAndW > 1){
            let hue = CGFloat(indexPath.item)/110
            
            let color = NSColor.init(hue: hue, saturation: 1, brightness: 1, alpha: 1).cgColor
            
            newItem.view.layer?.backgroundColor = color
            newItem.view.layer?.borderWidth = 1
            newItem.view.layer?.borderColor = window?.backgroundColor.cgColor
            newItem.color = newItem.view.layer?.backgroundColor
            newItem.view.alphaValue = 0.2
        }
        
        if(bAndW == 0){
            let color = NSColor.init(hue: 0, saturation: 0, brightness: 0, alpha: 1).cgColor
            
            newItem.view.layer?.backgroundColor = color
            newItem.view.layer?.borderWidth = 1
            newItem.view.layer?.borderColor = window?.backgroundColor.cgColor
            newItem.color = newItem.view.layer?.backgroundColor
            newItem.view.alphaValue = 0.2
        }
        
        if(bAndW == 1){
            let color = NSColor.init(hue: 0, saturation: 0, brightness: 1, alpha: 1).cgColor
            
            newItem.view.layer?.backgroundColor = color
            newItem.view.layer?.borderWidth = 1
            newItem.view.layer?.borderColor = window?.backgroundColor.cgColor
            newItem.color = newItem.view.layer?.backgroundColor
            newItem.view.alphaValue = 0.2
        }
        
        bAndW += 1
        
        colors.append(newItem)
        
        return colors.last!
        
    }
    
    override func draw(_ dirtyRect: NSRect) {
        self.allowsMultipleSelection = false
        super.draw(dirtyRect)
        
        // Drawing code here.
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.register(ColorCollectionItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ColorCollectionItem"))
        self.deselectAll(self)
        
    }
    
    override func deselectAll(_ sender: Any?) {
        super.deselectAll(sender)
        
        for color in colors{
            color.view.layer?.borderColor = window?.backgroundColor.cgColor
            color.view.alphaValue = 0.2
        }
    }
    
    override func selectItems(at indexPaths: Set<IndexPath>, scrollPosition: NSCollectionView.ScrollPosition) {
        if(isEnabled){
            super.selectItems(at: indexPaths, scrollPosition: scrollPosition)
            
            colors[indexPaths.first![1]].view.layer?.borderColor = CGColor.white
            colors[indexPaths.first![1]].view.alphaValue = 1
        }
    }
    
}
