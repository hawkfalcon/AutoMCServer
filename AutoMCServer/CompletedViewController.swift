import Cocoa

class CompletedViewController: NSViewController {
    var options: ServerOptions!
    @IBOutlet var ip: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        options = Data.options
        getIP()
    }
    
    func getIP() {
        let url = NSURL(string: "http://icanhazip.com")
        
        let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
            let ip = NSString(data: data, encoding: NSUTF8StringEncoding)!
            self.ip.stringValue = ip
            let paste = NSPasteboard.generalPasteboard()
            paste.clearContents()
            paste.setString(ip, forType: NSPasteboardTypeString)
        }
        task.resume()
    }
    @IBAction func quitapp(sender: AnyObject) {
        NSApplication.sharedApplication().stop(self)
    }
    
    @IBAction func portforward(sender: AnyObject) {
        let help = NSURL(string: "http://portforward.com/english/applications/port_forwarding/Minecraft_Server/")
        NSWorkspace.sharedWorkspace().openURL(help!)
    }
    
    @IBAction func editprop(sender: AnyObject) {
        let help = options.path.stringByAppendingPathComponent("minecraft/server.properties")
        NSWorkspace.sharedWorkspace().openFile(help)
    }
    
    @IBAction func openfolder(sender: AnyObject) {
        let help = options.path.stringByAppendingPathComponent("minecraft/")
        NSWorkspace.sharedWorkspace().openFile(help)
    }
    @IBAction func donatepls(sender: AnyObject) {
        let help = NSURL(string: "https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=MVENJVD6Y6EXJ&lc=US&item_name=hawkfalcon&item_number=hawkfalcon&currency_code=USD&bn=PP%2dDonationsBF%3abtn_donate_LG%2egif%3aNonHosted")
        NSWorkspace.sharedWorkspace().openURL(help!)
    }
}
