import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(aNotification: NSNotification) {
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(sender: NSApplication) -> Bool {
        return true
    }

    @IBAction func help(sender: AnyObject) {
        var help = NSURL(string: "http://minecraft.gamepedia.com/Server.properties")
        NSWorkspace.sharedWorkspace().openURL(help!)
    }
}

