import Foundation
import Socket
import Dispatch

class EchoServer {
    
    var appDel = NSApplication.shared.delegate as! AppDelegate
    static let bufferSize = 8192
    
    var vc: AdvancedViewController!
    let port: Int
    var listenSocket: Socket? = nil
    var continueRunningValue = true
    var connectedSockets = [Int32: Socket]()
    let socketLockQueue = DispatchQueue(label: "networkQ")
    var continueRunning: Bool {
        set(newValue) {
            socketLockQueue.sync {
                self.continueRunningValue = newValue
            }
        }
        get {
            return socketLockQueue.sync {
                self.continueRunningValue
            }
        }
    }
    
    init(port: Int) {
        self.port = port
        vc = (appDel.windowController!.contentViewController) as? AdvancedViewController
    }
    
    deinit {
        // Close all open sockets...
        for socket in connectedSockets.values {
            socket.close()
        }
        self.listenSocket?.close()
    }
    
    func run() {
        
        let queue = DispatchQueue.global(qos: .userInteractive)
        
        queue.async {
            
            do {
                
                var fam :Socket.ProtocolFamily?
                
                if((IPHandler.ipv6?.contains(":"))!){
                    fam = Socket.ProtocolFamily.inet6
                } else{
                    fam = Socket.ProtocolFamily.inet
                }
                
                try self.listenSocket = Socket.create(family: fam! )
                
                guard let socket = self.listenSocket else {
                    return
                }
                
                try socket.listen(on: self.port)
                repeat {
                    let newSocket = try socket.acceptClientConnection()
                    self.addNewConnection(socket: newSocket)
                    
                } while self.continueRunning
                
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error...")
                    return
                }
                
                if self.continueRunning {
                    
                    print("Error reported:\n \(socketError.description)")
                    
                }
            }
        }
    }
    
    func addNewConnection(socket: Socket) {
        
        socketLockQueue.sync {
            self.connectedSockets[socket.socketfd] = socket
        }
        
        let queue = DispatchQueue.global(qos: .default)
        
        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async {
            
            let shouldKeepRunning = true
            
            var readData = Data(capacity: EchoServer.bufferSize)
            var imageData: Data? = Data.init()
            var recievedImage :NSImage?
            
            do {
                repeat {
                    let bytesRead = try socket.read(into: &readData)
                    
                    if bytesRead > 0 {
                        
                        let copy = readData.advanced(by: bytesRead-4)
                        guard let recImage = String(bytes: copy, encoding: .utf8) else {
                            imageData!.append(readData)
                            readData.count = 0
                            print("Recieved Frame. ("+String(bytesRead)+" Bytes)")
                            continue
                        }
                        
                        if(recImage != "DONE"){
                            imageData!.append(readData)
                            readData.count = 0
                            print("Recieved Frame. ("+String(bytesRead)+" Bytes)")
                        }

                        if(recImage == "DONE"){
                            let withoutEnd = readData.subdata(in: .init(uncheckedBounds: (0,bytesRead-4)))
                            imageData!.append(withoutEnd)
                            print(recImage)
                            recievedImage = NSImage.init(data: imageData!)
                            imageData!.count = 0
                            DispatchQueue.main.sync {
                                self.vc.loadImage(image: recievedImage!)
                                let _ = try? socket.write(from: "Successfully transfered image.\n")
                                print("Successfully recieved image.")
                            }
                            print("Buffer cleared.")
                        }

                        readData = Data(capacity: EchoServer.bufferSize)
                        
                    }
                    
                } while shouldKeepRunning
                
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                    return
                }
                if self.continueRunning {
                    print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
                }
            }
        }
    }
    
    func shutdownServer() {
        print("\nShutdown in progress...")
        
        self.continueRunning = false
        
        // Close all open sockets...
        for socket in connectedSockets.values {
            
            self.socketLockQueue.sync {
                self.connectedSockets[socket.socketfd] = nil
                socket.close()
            }
        }
    }
}
