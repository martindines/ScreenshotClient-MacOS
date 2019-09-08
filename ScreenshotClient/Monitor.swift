import Foundation

class Monitor {
    
    let callback: (URL, Int, Int) -> Void
    var query: NSMetadataQuery
    var blacklist: [String]
    
    init(callback: @escaping (URL, Int, Int) -> Void) {
        self.callback = callback
        self.blacklist = []
        
        query = NSMetadataQuery()
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture = 1")
    }
    
    func startMonitoring() {
        print("startMonitoring")
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query, queue: nil, using: initialPhaseComplete)
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSMetadataQueryDidUpdate, object: query, queue: nil, using: liveUpdatePhaseEvent)
        query.start()
    }
    
    func stopMonitoring() {
        print("stopMonitoring")
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidFinishGathering, object: query)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.NSMetadataQueryDidUpdate, object: query)
        query.stop()
    }
    
    func initialPhaseComplete(_ notification: Notification) {
        print("initialPhaseComplete")
        // Blacklist all screenshots that already exist
        if let itemsAdded = (notification.object as AnyObject).results as? [NSMetadataItem] {
            for item in itemsAdded {
                // Get the path to the screenshot
                if let screenshotPath = item.value(forAttribute: NSMetadataItemPathKey) as? String {
                    let screenshotName = ((screenshotPath as NSString).lastPathComponent as NSString).deletingPathExtension
                    
                    // Blacklist the screenshot if it hasn't already been blacklisted
                    if !blacklist.contains(screenshotName) {
                        blacklist.append(screenshotName)
                    }
                }
            }
        }
    }
    
    func liveUpdatePhaseEvent(_ notification: Notification) {
        print("liveUpdatePhaseEvent")
        
        if let itemsAdded = notification.userInfo?["kMDQueryUpdateAddedItems"] as? [NSMetadataItem] {
            for item in itemsAdded {
                // Get the path to the screenshot
                if let path = item.value(forAttribute: NSMetadataItemPathKey) as? String,
                    let width = item.value(forAttribute: NSMetadataItemPixelWidthKey) as? NSNumber,
                    let height = item.value(forAttribute: NSMetadataItemPixelHeightKey) as? NSNumber,
                    let creationDate = item.value(forAttribute: NSMetadataItemFSCreationDateKey) as? Date {
                    let screenshotName = ((path as NSString).lastPathComponent as NSString).deletingPathExtension
                    
                    let oldestAllowedCreationDate = Date(timeIntervalSinceNow: -30) // 30 seconds ago
                    let defaultScreenshotDirectoryPath = ((path as NSString).deletingLastPathComponent as NSString).standardizingPath
                    let currentScreenshotDirectoryPath = (screenshotDirectoryPath as NSString).standardizingPath
                    
                    let isInScreenshotFolder = currentScreenshotDirectoryPath == defaultScreenshotDirectoryPath
                    let isRecentlyCreated = creationDate.compare(oldestAllowedCreationDate) == .orderedDescending
                    let isBlacklisted = blacklist.contains(screenshotName)
                    
                    // Ensure that the screenshot detected is from the right folder and isn't blacklisted
                    if isRecentlyCreated && isInScreenshotFolder && !isBlacklisted {
                        callback(URL(fileURLWithPath: path), width.intValue, height.intValue)
                        blacklist.append(screenshotName)
                    }
                }
            }
        }
    }
    
    var screenshotDirectoryPath: String {
        // Check for custom screenshot location chosen by user
        if let customLocation = UserDefaults.standard.persistentDomain(forName: "com.apple.screencapture")?["location"] as? String {            print(customLocation)
            // Check that the chosen directory exists, otherwise screencapture will not use it
            var isDir = ObjCBool(false)
            if FileManager.default.fileExists(atPath: customLocation, isDirectory: &isDir) {
                return customLocation
            }
        }
        // If a custom location is not defined (or invalid) return the default screenshot location (~/Desktop)
        return NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true)[0]
    }
}
