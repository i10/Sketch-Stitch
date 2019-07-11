import UIKit
import AVFoundation
import Socket

class FirstViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate {

    @IBOutlet weak var shutterButton: ShutterButton!
    @IBOutlet weak var imagePreview: CameraPreview!
    @IBOutlet weak var connectionState: UILabel!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var conInfoDesc: UILabel!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var currentConIP: UILabel!

    @IBOutlet weak var captureImageView: UIImageView!
    
    @IBOutlet weak var sendIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var qualitySelection: SegmentedControl!
    
    var session :AVCaptureSession?
    var device :AVCaptureDevice?
    var captureOut :AVCapturePhotoOutput?
    var captureSettings :AVCapturePhotoSettings?
    var previewLayer :AVCaptureVideoPreviewLayer?
    var captureIn: AVCaptureDeviceInput?
    var previewPixelType :FourCharCode?
    var conState = 0
    let workQ = DispatchQueue.init(label: "workQ")
    let sessionQ = DispatchQueue.init(label: "sessionQ")
    var metadataOutput :AVCaptureMetadataOutput = AVCaptureMetadataOutput()
    let connectionStatusQ = DispatchQueue.init(label: "constatQ")
    
    let generator = UINotificationFeedbackGenerator()
    
    var currentImage : UIImage?
    
    var socket :Socket?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.startAnimating()
        cancelButton.setTitleColor(UIColor.init(red: 215/255, green: 115/255, blue: 130/255, alpha: 1), for: UIControl.State.normal)
        socket = try! Socket.create()
        self.updateConnectionLabel()
    
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.imagePreview.videoPreviewLayer.session = self.session
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    

    @IBAction func shutterToggled(_ sender: Any) {
        let settings = AVCapturePhotoSettings()
        captureOut!.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        if let error = error {
            print("error occured : \(error.localizedDescription)")
        }
        
        if let dataImage = photo.fileDataRepresentation() {
            
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 1.0, orientation: UIImage.Orientation.right)
            
            self.captureImageView.image = image
            self.captureImageView.isHidden = false
            self.cancelButton.isHidden = false
            
            if(conState == 2){
                self.sendButton.isHidden = false
                self.qualitySelection.isHidden = false
                self.qualitySelection.isEnabled = true
            }
            
            self.shutterButton.isEnabled = false
            self.shutterButton.isHidden = true
            
        } else {
            print("Could not take picture.")
        }
    }
    
    @IBAction func sendImage(_ sender: Any) {
    
        let fullResImage = captureImageView.image
        
        var width :CGFloat?
        
        switch qualitySelection.selectedSegmentIndex {
        case 0:
            width = 500
        case 1:
            width = 1000
        case 2:
            width = 2000
        default:
            width = 1000
        }
        
        let imageToSend = resizeImage(image: fullResImage!, newWidth: width!)
        
        let data = imageToSend.pngData()
        
        let t = "DONE"
        
        sendIndicator.startAnimating()
        
        workQ.async {
            
                let status = try? self.socket!.write(from: data!)

            if(status != nil){
                DispatchQueue.main.async {
                    self.captureImageView.isHidden = true
                    self.captureImageView.image = nil
                    
                    self.cancelButton.isHidden = true
                    self.sendButton.isHidden = true
                    
                    self.shutterButton.isEnabled = true
                    self.shutterButton.isHidden = false
                    
                    self.qualitySelection.isHidden = true
                    self.qualitySelection.isEnabled = false
                    
                    self.generator.notificationOccurred(.success)
                    
                    self.sendIndicator.stopAnimating()
                    
                    let _ = try? self.socket!.write(from: t.data(using: .utf8)!)
                }
            } else{
                DispatchQueue.main.async {
                    self.lostConnection()
                }
            }
            
        }
            
    }
    
    func resizeImage(image: UIImage, newWidth: CGFloat) -> UIImage {
        let scale = newWidth / image.size.width
        let newHeight = image.size.height * scale
        UIGraphicsBeginImageContext(CGSize(width: newWidth, height: newHeight))
        image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage! }
    
    
    
    @IBAction func userCancelledSend(_ sender: Any) {
        self.captureImageView.isHidden = true
        self.captureImageView.image = nil
        
        self.cancelButton.isHidden = true
        self.sendButton.isHidden = true
        
        self.shutterButton.isEnabled = true
        self.shutterButton.isHidden = false
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        if(conState < 2){
            if let metadataObject = metadataObjects.first {
                guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
                guard let stringValue = readableObject.stringValue else { return }
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                found(code: stringValue)
            }
            
            dismiss(animated: true)
        }
    }
    
    func found(code: String) {
        print(code)
        
        let conIPs = code.components(separatedBy: "+")
        
        self.conInfoDesc.isHidden = true
        self.conState = 2
        self.currentConIP.text = conIPs.last
        self.currentConIP.isHidden = false
        self.conInfoDesc.isHidden = true
        self.shutterButton.isEnabled = true
        self.shutterButton.isHidden = false
    
        try! socket!.connect(to: conIPs.last!, port: 1337)
        self.updateConnectionLabel()
    }
    
    func updateConnectionLabel(){
        if(self.conState == 2){
            self.connectionState.textColor = UIColor.init(red: 115/255, green: 215/255, blue: 130/255, alpha: 1)
            self.connectionState.text = "Connected"
        }
        
        if(self.conState == 0){
            self.connectionState.textColor = UIColor.init(red: 215/255, green: 115/255, blue: 130/255, alpha: 1)
            self.connectionState.text = "Not Connected"
        }
        
        if(self.conState == 1){
            self.connectionState.textColor = UIColor.init(red: 255/255, green: 180/255, blue: 80/255, alpha: 1)
            self.connectionState.text = "Lost Connection"
        }
    }
    
    func lostConnection(){
        
        self.conState = 1
        
        self.currentConIP.isHidden = true
        self.conInfoDesc.isHidden = false
        self.shutterButton.isEnabled = false
        self.shutterButton.isHidden = true
        
        self.captureImageView.isHidden = true
        self.captureImageView.image = nil
        
        self.cancelButton.isHidden = true
        self.sendButton.isHidden = true
        
        self.shutterButton.isEnabled = false
        self.shutterButton.isHidden = true
        
        self.sendIndicator.stopAnimating()
        
        self.qualitySelection.isHidden = true
        self.qualitySelection.isEnabled = false
        
        updateConnectionLabel()
        socket!.close()
        socket = try! Socket.create()
        
        
    }
    func initCam(){
        
        sessionQ.async {
            self.session =  AVCaptureSession()
            self.previewLayer = AVCaptureVideoPreviewLayer.init()
            self.device = AVCaptureDevice.default(for: .video)
            self.captureOut = AVCapturePhotoOutput.init()
            self.captureOut!.isLivePhotoCaptureEnabled = false
            self.captureOut!.isDepthDataDeliveryEnabled = false
            self.captureIn = try! AVCaptureDeviceInput.init(device: self.device!)
            self.captureSettings = AVCapturePhotoSettings()
            self.previewPixelType = self.captureSettings!.availablePreviewPhotoPixelFormatTypes.first!
            
            self.captureSettings!.flashMode = AVCaptureDevice.FlashMode(rawValue: 0)!
            
            let previewFormat = [
                kCVPixelBufferPixelFormatTypeKey as String: self.previewPixelType,
                kCVPixelBufferWidthKey as String: 160,
                kCVPixelBufferHeightKey as String: 160
            ]
            
            self.captureSettings!.previewPhotoFormat = previewFormat as [String : Any]
            
            self.session!.beginConfiguration()
            self.session!.sessionPreset = .photo
            
            self.session!.addInput(self.captureIn!)
            self.session!.addOutput(self.captureOut!)
            self.session!.addOutput(self.metadataOutput)
            
            self.session!.commitConfiguration()
            self.session!.startRunning()
            
            self.metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            self.metadataOutput.metadataObjectTypes = [.qr]

        }
        
    }
}
