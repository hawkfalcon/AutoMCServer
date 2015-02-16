import Cocoa

class CreateServer: NSViewController {
    
    var notificationCenter = NSNotificationCenter.defaultCenter()
    var fileManager = NSFileManager.defaultManager()

    var options:ServerOptions!
    var path:NSString!
    let spigot = NSURL(string: "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar")
    let latestjson = NSURL(string: "https://s3.amazonaws.com/Minecraft.Download/versions/versions.json")

    @IBOutlet var ram: NSTextField!
    @IBOutlet var servertype: NSTextField!
    @IBOutlet var username: NSTextField!
    @IBOutlet var output: NSTextView!
    @IBOutlet var spin: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        options = Data.options
        path = options.path.stringByAppendingPathComponent("minecraft")
        notificationCenter.addObserver(self, selector: "receivedOut:", name: NSFileHandleDataAvailableNotification, object: nil)
        setupGUI()
    }
    
    func setupGUI() {
        username.stringValue = "OP: \(options.username)"
        ram.stringValue = "RAM: \(options.ram)\(options.bytesize)"
        servertype.stringValue = "Creating \(options.servertype.rawValue) Server"
        spin.startAnimation(1)
    }
    
    override func viewDidAppear() {
        startCreation()
    }
    
    func startCreation() {
        if (!self.fileManager.fileExistsAtPath(self.path)) {
            self.fileManager.createDirectoryAtPath(self.path, withIntermediateDirectories: false, attributes: nil, error: nil)
        }
        if (options.servertype == ServerType.Vanilla) {
            queueVanilla()
        } else {
            queueBuildTools()
        }
    }
    
    func queueBuildTools() {
        let queue = TaskQueue()
        queue.tasks +=! {
            self.output.append("Starting download of BuildTools...")
        }
        
        queue.tasks +=~ {
            let jar = NSData(contentsOfURL: self.spigot!)
            self.fileManager.createFileAtPath(self.path + "/BuildTools.jar", contents: jar, attributes: nil)
        }
        
        queue.tasks +=! {
            self.output.append("Downloaded BuildTools.jar")
            self.output.append("Running BuildTools...")
        }
        
        queue.tasks +=! { result, next in
            let task = NSTask()
            task.launchPath = "/usr/bin/java"
            task.currentDirectoryPath = self.path
            task.arguments = ["-jar", "BuildTools.jar"]
            
            let pipe = NSPipe()
            task.standardOutput = pipe
            let data = pipe.fileHandleForReading
            data.waitForDataInBackgroundAndNotify()
            task.launch()
            task.terminationHandler = {task -> Void in
                next(nil)
            }
        }
        
        queue.tasks +=! {
            self.cleanFolder()
        }
        
        queue.run {
            self.finishCreation()
        }
    }
    
    func queueVanilla() {
        let queue = TaskQueue()
        queue.tasks +=! {
            self.output.append("Starting download of minecraft_server.jar...")
        }
        
        queue.tasks +=~ {
            let dataFromNetworking = NSData(contentsOfURL: self.latestjson!)
            let json = JSON(data: dataFromNetworking!)
            let version = json["latest"]["release"]
            let vanilla = NSURL(string: "https://s3.amazonaws.com/Minecraft.Download/versions/\(version)/minecraft_server.\(version).jar")
            let jar = NSData(contentsOfURL: vanilla!)
            self.fileManager.createFileAtPath(self.path + "/minecraft_server.jar", contents: jar, attributes: nil)
        }

        queue.tasks +=! {
            self.output.append("Downloaded minecraft_server.jar")
        }
        
        queue.run {
            self.finishCreation()
        }
    }
    
    func receivedOut(notif : NSNotification) {
        let fh:NSFileHandle = notif.object as NSFileHandle
        let data = fh.availableData
        if data.length > 0 {
            let dstring = NSString(data: data, encoding: NSUTF8StringEncoding)!
            output.append(dstring)
            fh.waitForDataInBackgroundAndNotify()
        }
    }
    
    func cleanFolder() {
        var removeList = ["CraftBukkit", "Bukkit", "Spigot", "BuildData", "BuildTools.jar", "work", "BuildTools.log.txt"]
        removeList.append(getFullName("apache-maven"))
        for remove in removeList {
            removeFromFolder(remove)
            output.append("Cleaning \(remove)...")
        }
        output.append("DONE CREATING SERVER JAR")
    }
    
    func finishCreation() {
        createFiles()
        self.performSegueWithIdentifier("final", sender: self)
    }
    
    func createFiles() {
        var serverjar = getFullName("spigot")
        if options.servertype == ServerType.Bukkit {
            serverjar = getFullName("craftbukkit")
        } else if options.servertype == ServerType.Vanilla {
            serverjar = getFullName("minecraft_server")
        }
        var size = options.bytesize
        let sh = "#!/bin/sh\n\ncd \"$( dirname \"$0\" )\"\njava -Xms\(options.ram)\(size) -Xmx\(options.ram)\(size) -jar \(serverjar) nogui -o true"
        let start = path.stringByAppendingPathComponent("start.sh")
        createFile(start, contents: sh)
        createFile(path.stringByAppendingPathComponent("eula.txt"), contents: "eula=true")
        createFile(path.stringByAppendingPathComponent("ops.txt"), contents: options.username)
        let attributes = [NSFilePosixPermissions : NSNumber(short: 0x755.shortValue)]
        fileManager.setAttributes(attributes, ofItemAtPath: start, error: nil)
        NSWorkspace.sharedWorkspace().openFile(start, withApplication: "terminal")
    }
    
    func createFile(fpath: String, contents: String) {
        fileManager.createFileAtPath(fpath, contents: contents.dataUsingEncoding(NSUTF8StringEncoding), attributes: nil)
    }
    
    func removeFromFolder(file: String) {
        let toRemove = path.stringByAppendingPathComponent(file)
        if fileManager.fileExistsAtPath(toRemove) {
            fileManager.removeItemAtPath(toRemove, error: nil)
        }
    }
    
    func getFullName(partial: String) -> String {
        var longestCompletion = ""
        var match = path.stringByAppendingPathComponent(partial).completePathIntoString(&longestCompletion, caseSensitive: false)
        return longestCompletion.lastPathComponent
    }
}

extension NSTextView {
    func append(string: String) {
        dispatch_async(dispatch_get_main_queue(), {
            self.textStorage?.appendAttributedString(NSAttributedString(string: "\(string) \n"))
            self.scrollToEndOfDocument(nil)
        })
    }
}
