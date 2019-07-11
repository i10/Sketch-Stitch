import Cocoa
import Socket

class ConnectOverlay: NSViewController{
    
    var appDel = NSApplication.shared.delegate as! AppDelegate
    
    let networkQ = DispatchQueue.init(label: "networkQ")
    var socket: Socket?
    var server: EchoServer?
    
    @IBOutlet weak var qrCodeView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        qrCodeView.wantsLayer = true
        
        let ipv4 = IPHandler.ipv4
        let ipv6 = IPHandler.ipv6
        
        print(ipv4 ?? "No IPV4",ipv6 ?? "No IPV6")
        
        let concat = ipv4! + "+" + ipv6!
        
        let data = concat.data(using: .utf8)
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        filter!.setValue(data, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 20, y: 20)
        
        var output = filter!.outputImage?.transformed(by: transform)
        
        let colorParameters = ["inputColor0": CIColor(color: NSColor.black),"inputColor1": CIColor(color: NSColor.clear)]
        
        output = output!.applyingFilter("CIFalseColor", parameters: colorParameters as [String : Any])
        
        let rep = NSCIImageRep(ciImage: output!)
        let qrcode = NSImage(size: rep.size)
        
        
        qrcode.addRepresentation(rep)
        qrCodeView.layer?.shouldRasterize = true
        qrCodeView.imageScaling = NSImageScaling.scaleProportionallyUpOrDown
        qrCodeView.layer?.magnificationFilter = CALayerContentsFilter.nearest
        self.qrCodeView.image = qrcode
        
        let port = 1337
        server = EchoServer.init(port: port)
        server!.run()
        print("Server started! Waiting for images.")
    }
    
}
