import UIKit
import AVFoundation

class CameraPreview: UIView {
    override class var layerClass: AnyClass {
        return AVCaptureVideoPreviewLayer.self
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    /// Convenience wrapper to get layer as its statically known type.
    var videoPreviewLayer: AVCaptureVideoPreviewLayer {
        
        let lay = layer as! AVCaptureVideoPreviewLayer
        lay.videoGravity = AVLayerVideoGravity.resizeAspectFill
        lay.bounds = self.bounds
        
        return lay
    }
}
