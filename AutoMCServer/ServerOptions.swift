import Cocoa

enum ServerType: String {
    case Spigot = "Spigot"
    case Bukkit = "Bukkit"
    case Vanilla = "Vanilla"
}

class ServerOptions {
    var path: NSString
    var servertype: ServerType = .Spigot
    var ram = 2048
    var bytesize: String
    var username = "Notch"
    
    init(path: NSString, servertype: ServerType, ram: Int, bytesize: String, username: String) {
        self.path = path
        self.servertype = servertype
        self.ram = ram
        self.bytesize = bytesize
        self.username = username
    }
}
