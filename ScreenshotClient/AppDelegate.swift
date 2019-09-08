//
//  AppDelegate.swift
//  ScreenshotClient
//
//  Created by Martin Dines on 20/08/2019.
//  Copyright © 2019 Martin Dines. All rights reserved.
//

import Cocoa

let PREFERENCES_WINDOW_CONTROLLER: NSWindowController = NSWindowController(window: nil)

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var previewView: PreviewView!
    
    // Use if not using an icon: withLength: NSStatusItem.variableLength
    let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    
    let authService = AuthService()
    let uploadService = UploadService()
    
    var monitor : Monitor!
    var previewMenuItem: NSMenuItem!
    var uploadMenuItem: NSMenuItem!
    var currentScreenshot: URL?
    
    @IBAction func onUploadClick(_ sender: NSMenuItem) {
        if let path = currentScreenshot {
            
            let host = UserDefaults.standard.string(forKey: "host") ?? ""
            let secret = UserDefaults.standard.string(forKey: "secret") ?? ""
            
            uploadService.upload(host: host, secret: secret, file: path, success: { uploadPath in
                
                // Not obvious from the docs, but this will close the menu
                self.statusMenu.cancelTracking()
                
                // Copy upload path to clipboard
                let pasteboard = NSPasteboard.general
                pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
                pasteboard.setString(uploadPath, forType: NSPasteboard.PasteboardType.string)
                
                
                // Display a notification to the user
                let notification = NSUserNotification()
                notification.title = "Upload Successful"
                notification.subtitle = "Copied to clipboard"
                notification.informativeText = uploadPath
                notification.contentImage = NSImage(contentsOf: path)
                notification.soundName = nil
                notification.deliveryDate = Date(timeIntervalSinceNow: 0)
                
                NSUserNotificationCenter.default.delegate = self
                NSUserNotificationCenter.default.scheduleNotification(notification)
                
            }, failure: { error in
                
                // Display the error to the user
                let alert = NSAlert()
                alert.alertStyle = .warning
                alert.messageText = "Upload Failed"
                alert.informativeText = error
                alert.runModal()
                
            }, progress: { percent in
                print(percent)
            })
        }
    }
    
    @IBAction func onPreferencesClick(_ sender: NSMenuItem) {
        if let vc = WindowsManager.getVC(withIdentifier: "Preferences", ofType: PreferencesController.self) {
            vc.delegate = self
            let window: NSWindow = {
                let w = NSWindow(contentViewController: vc)
                
                w.styleMask.remove(.fullScreen)
                w.styleMask.remove(.resizable)
                w.styleMask.remove(.miniaturizable)
                
                w.level = .floating
                
                return w
            }()
            
            if PREFERENCES_WINDOW_CONTROLLER.window == nil {
                PREFERENCES_WINDOW_CONTROLLER.window = window
            }
            
            PREFERENCES_WINDOW_CONTROLLER.showWindow(self)
        }
    }
    
    @IBAction func onQuitClick(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(self)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // Icons taken from https://www.flaticon.com/free-icon/camera_1372551#term=camera&page=1&position=52
        if let button = statusItem.button {
            let icon = NSImage(named: "camera-16")
            icon?.isTemplate = true
            button.image = icon
        }
        
        statusItem.menu = statusMenu
        
        previewMenuItem = statusMenu.item(withTitle: "Preview")
        previewMenuItem.view = previewView
        // Assign a zero size Rect to the frame to allow it to be hidden
        previewMenuItem.view?.frame = NSRect(x: 0, y: 0, width: 0, height: 0)
        previewMenuItem.isHidden = true
        
        uploadMenuItem = statusMenu.item(withTitle: "Upload")
        uploadMenuItem.isHidden = true
        
        monitor = Monitor(callback: receiveScreenshotData)
        monitor.startMonitoring()
        
        // Preview an existing screenshot
//        if let url = URL(string: "file:///Users/martin/Desktop/Screen%20Shot%202019-08-15%20at%2020.17.57.png") {
//            receiveScreenshotData(path: url, width: 3360, height: 2100)
//        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Tear down goes here
    }

    @objc func receiveScreenshotData(path: URL, width: Int, height: Int)
    {
        if let image = NSImage(contentsOf: path) {
            self.currentScreenshot = path
            self.previewView.update(image, width: width, height: height)
            self.uploadMenuItem.isHidden = false
        }
    }
}

/**
 * Preferences Controller Delegate
 */
extension AppDelegate: PreferencesControllerDelegate {
    func onSave(_ sender: NSButton, _ host: String, _ secret: String) {
        UserDefaults.standard.set(host, forKey: "host")
        UserDefaults.standard.set(secret, forKey: "secret")
        
        PREFERENCES_WINDOW_CONTROLLER.close()
    }
    
    func onTestConnection(_ sender: NSButton, _ host: String, _ secret: String) {
        sender.isEnabled = false
        
        authService.test(host: host, secret: secret, success: { result in
            
            sender.isEnabled = true
            
            print(result)
            let alert = NSAlert()
            alert.alertStyle = .informational
            alert.messageText = "Connection Successful"
            alert.informativeText = "A connection has been successfully established"
            alert.runModal()
            
        }, failure: { error in
            
            sender.isEnabled = true
            
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.messageText = "Connection Failed"
            alert.informativeText = error
            alert.runModal()
            
        })
    }
}

/**
 * Notification Center Delegate
 */
extension AppDelegate: NSUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
    
    func userNotificationCenter(_ center: NSUserNotificationCenter, didActivate notification: NSUserNotification) {
        if let path = notification.informativeText as String? {
            if let url = URL(string: path) {
                NSWorkspace.shared.open(url)
            }
        }
    }
}


