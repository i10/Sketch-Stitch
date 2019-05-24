//
//  OverlayViewController.swift
//  sketchandstitch
//
//  Created by Kirill Timchenko on 17.02.19.
//  Copyright © 2019 Kirill Timchenko. All rights reserved.
//

import Cocoa

class OverlayViewController: NSViewController {
    
    let delegate = NSApplication.shared.delegate
    
    @IBOutlet weak var qrCodeView: NSImageView!
    
    @IBAction func done(_ sender: Any) {
        self.view.window?.close()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let x = GetNetworkInterfaceAdresses()
        let filtered = x.filter { $0.contains(".")}
        let localIP = filtered[0]
        
        let data = localIP.data(using: String.Encoding.ascii)
        
        let filter = CIFilter(name: "CIQRCodeGenerator")
        
        filter!.setValue(data, forKey: "inputMessage")
        
        let transform = CGAffineTransform(scaleX: 20, y: 20)
        
        let output = filter!.outputImage?.transformed(by: transform)
        let rep = NSCIImageRep(ciImage: output!)
        let qrcode = NSImage(size: rep.size)
        
        qrcode.addRepresentation(rep)
        
        self.qrCodeView.image = qrcode
    }
    
}
