import Foundation

public struct IPHandler {
    
    static var ipv4 : String?
    static var ipv6 : String?
    
    public typealias JSONDictionary = [String: Any]
    
    static var serviceURLipv4 = "https://api.ipify.org?format=json"
    static var serviceURLipv6 = "https://api6.ipify.org?format=json"
    
    public static func getPublicIPV4(){
        let url = URL(string: IPHandler.serviceURLipv4)!
        
        URLSession.shared.dataTask(with: url){ data, response, error in
            handleResponse4(with: data)
            }.resume()
    }
    
    
    public static func getPublicIPV6(){
        let url = URL(string: IPHandler.serviceURLipv6)!
        
        URLSession.shared.dataTask(with: url){ data, response, error in
            handleResponse6(with: data)
            }.resume()
    }
    
    
    
    internal static func handleResponse4(with data: Data?){
        
        let data = data
        
        let json = try! JSONSerialization.jsonObject(with: data!, options: []) as? JSONDictionary
        
        let ip = json!["ip"] as? String
        
        self.ipv4 = ip
    
        //print(ip!)
    }
    
    internal static func handleResponse6(with data: Data?){
        
        let data = data
        
        let json = try! JSONSerialization.jsonObject(with: data!, options: []) as? JSONDictionary
        
        let ip = json!["ip"] as? String
        
        self.ipv6 = ip
        
        getPublicIPV4()
        //print(ip!)
    }
    
}
