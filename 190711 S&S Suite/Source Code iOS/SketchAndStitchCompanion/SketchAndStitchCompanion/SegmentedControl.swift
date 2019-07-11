import UIKit

class SegmentedControl: UISegmentedControl {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.frame = CGRect.init(x: self.frame.minX, y: self.frame.minY, width: self.frame.width, height: self.frame.height/1.4)
        self.backgroundColor = UIColor.clear
    }

}
