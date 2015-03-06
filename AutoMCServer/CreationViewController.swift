import Cocoa
import SwiftHTTP

class CreationViewController: NSViewController {
    
    var notificationCenter = NSNotificationCenter.defaultCenter()

    var fileManager = NSFileManager.defaultManager()
    
    var total = 0.0

    var options:ServerOptions!
    var properties:ServerProperties!
    var path:NSString!
    let spigot = "https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar"
    let latestjson = NSURL(string: "https://s3.amazonaws.com/Minecraft.Download/versions/versions.json")

    @IBOutlet var progresstext: NSTextField!
    @IBOutlet var subtext: NSTextField!
    @IBOutlet var percent: NSTextField!
    @IBOutlet var progress: NSProgressIndicator!
    
    @IBOutlet var ram: NSTextField!
    @IBOutlet var servertype: NSTextField!
    @IBOutlet var username: NSTextField!
    @IBOutlet var output: NSTextView!
    @IBOutlet var spin: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        options = Data.options
        properties = Data.properties
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
            self.updateGui(0.0, label: "Creating folder")
            updateSub(" ")
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
            self.updateGui(0.00, label: "Starting download of BuildTools...")
        }
        
        queue.tasks +=~ { result, next in
            let fileUrl = NSURL(fileURLWithPath: self.path + "/BuildTools.jar")
            self.downloadFile(self.spigot, toPath: fileUrl!) {(_) in
                next(nil)
            }
        }
        
        queue.tasks +=! {
            self.output.append("Downloaded BuildTools.jar")
            self.updateGui(1.0, label: "Downloaded BuildTools")
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
            self.updateGui(0.25, label: "Starting download of minecraft_server.jar...")
        }
        
        queue.tasks +=~ { result, next in
            self.updateGui(0.5, label: "Getting latest minecraft version...")
            let dataFromNetworking = NSData(contentsOfURL: self.latestjson!)
            let json = JSON(data: dataFromNetworking!)
            let version = json["latest"]["release"]
            let vanilla = "https://s3.amazonaws.com/Minecraft.Download/versions/\(version)/minecraft_server.\(version).jar"
            let fileUrl = NSURL(fileURLWithPath: self.path + "/minecraft_server.jar")
            self.updateGui(0.0, label: "Downloading Minecraft Jar...")
            self.downloadFile(vanilla, toPath: fileUrl!) {(_) in
                next(nil)
            }
        }

        queue.tasks +=! {
            self.output.append("Downloaded minecraft_server.jar")
            self.updateGui(0.0, label: "Downloaded minecraft_server.jar")
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
            self.parseOutput(dstring)
            fh.waitForDataInBackgroundAndNotify()
        }
    }
    
    var perc = 0.00
    func parseOutput(line: String) {
        perc += 1/5800
        output.append(line)
        self.updateGui(perc, label: nil)
        let trimmed = line.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        let check = ["Starting clone": "Downloading files", "Maven does not exist":"Downloading Maven", "Pulling updates":"Getting updates","https://s3.amazonaws.com/Minecraft.Download/":"Downloading Minecraft Jar", "Final mapped jar":"Preparing Minecraft Jar","Remapping final jar":"Modifying Minecraft Jar","Decompiling class net/minecraft/server/WorldType":"Decompiling", "Applying CraftBukkit Patches":"Creating CraftBukkit","Compiling Bukkit":"Compiling Bukkit","Compiling CraftBukkit":"Compiling CraftBukkit","Applying patches to Spigot-API":"Applying Spigot changes","Building Spigot-API":"Building Spigot-API","Building Spigot ":"Building Spigot","Success! Everything compiled successfully.":"Success! Everything compiled successfully."]
        for (find, print) in check {
            if (trimmed.rangeOfString(find) != nil) {
                perc += 0.014
                updateGui(perc, label: "\(print)...")
                updateSub(" ")
            }
        }
        let subs = ["Starting clone of":" ","Extracted: work/decompile-":"/","Decompiling class":"/", "Applying:":"Applying: ","Patching with":" ", "Running":".","BUILD SUCCESS":" ", "Building jar":"/", "Starting download":"/"]
        for (needle, split) in subs {
            setSubFor(trimmed, needle: needle, split: split)
        }
    }
    
    func setSubFor(line: String, needle: String, split: String) {
        if (line.rangeOfString(needle) != nil) {
            updateSub(line.componentsSeparatedByString(split).last!)
        }
    }
    
    func downloadFile(fromUrl: NSString, toPath: NSURL, done: () -> ()) {
        var request = HTTPTask()
        let server = options.servertype.rawValue
        let downloadTask = request.download(fromUrl, parameters: nil, progress: {(complete: Double) in
            self.updateGuiFast(complete)
            }, success: {(response: HTTPResponse) in
                if response.responseObject != nil {
                    //we MUST copy the file from its temp location to a permanent location.
                    if let url = response.responseObject as? NSURL {
                        if let path = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first as? String {
                            if let fileName = response.suggestedFilename {
                                if let newPath = NSURL(fileURLWithPath: "\(path)/\(fileName)") {
                                    let fileManager = NSFileManager.defaultManager()
                                    fileManager.removeItemAtURL(toPath, error: nil)
                                    fileManager.moveItemAtURL(url, toURL: toPath, error:nil)
                                    done()
                                }
                            }
                        }
                    }
                }
            }, failure: {(error: NSError, response: HTTPResponse?) in
                println("failure")
        })
    }
    
    func updateGui(amount: Double, label: String?) {
        let amountp = Int(amount * 100)
        self.percent.stringValue = "\(amountp)%"
        self.progress.doubleValue = amount
        if label != nil {
            self.progresstext.stringValue = label!
        }
    }
    
    func updateSub(sub: String) {
        self.subtext.stringValue = sub.truncate(60)
    }

    func updateGuiFast(amount: Double) {
        self.percent.stringValue = "\(Int(amount*100))%"
        self.progress.doubleValue = amount
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
        self.updateGui(0.8, label: "Creating files")
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
        self.updateGui(0.9, label: "Creating properties")
        createProperties()
        self.updateGui(1.0, label: "Launching server")
        let attributes = [NSFilePosixPermissions : NSNumber(short: 0x755.shortValue)]
        fileManager.setAttributes(attributes, ofItemAtPath: start, error: nil)
        NSWorkspace.sharedWorkspace().openFile(start, withApplication: "terminal")
    }
    
    func createProperties() {
        let prop = NSBundle.mainBundle().pathForResource("server", ofType: "properties")
        var content = String(contentsOfFile:prop!, encoding: NSUTF8StringEncoding, error: nil)
        content = content?.replace("mobs", withString: properties.mobs.toString())
        content = content?.replace("nether", withString: properties.nether.toString())
        content = content?.replace("leveltype", withString: properties.leveltype.rawValue)
        content = content?.replace("whitelist", withString: properties.whitelist.toString())
        content = content?.replace("pvp", withString: properties.pvp.toString())
        content = content?.replace("difficulty", withString: String(properties.difficulty.rawValue))
        content = content?.replace("gamemode", withString: String(properties.gamemode.rawValue))
        content = content?.replace("maxplayers", withString: String(properties.maxplayers))
        content = content?.replace("motd", withString: properties.motd)
        createFile(path.stringByAppendingPathComponent("server.properties"), contents: content!)
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

extension String {
    func truncate(length: Int) -> String {
        if countElements(self) > length {
            return self.substringToIndex(advance(self.startIndex, length))
        } else {
            return self
        }
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

extension String {
    func replace(target: String, withString: String) -> String {
        return self.stringByReplacingOccurrencesOfString("{\(target)}", withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
}

extension Bool {
    func toString() -> String {
        return self.boolValue ? "true" : "false"
    }
}