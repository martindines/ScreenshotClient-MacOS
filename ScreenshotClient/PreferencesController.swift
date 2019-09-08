//
//  PreferencesController.swift
//  ScreenshotClient
//
//  Created by Martin Dines on 21/08/2019.
//  Copyright © 2019 Martin Dines. All rights reserved.
//

import Cocoa

protocol PreferencesControllerDelegate {
    func onSave(_ sender: NSButton, _ host: String, _ secret: String) -> Void
    func onTestConnection(_ sender: NSButton, _ host: String, _ secret: String) -> Void
}

class PreferencesController: NSViewController {

    @IBOutlet weak var hostField: NSTextField!
    @IBOutlet weak var secretField: NSTextField!
    
    @IBAction func onSaveClick(_ sender: NSButton) {
        let hostValue = hostField.stringValue
        let secretValue = secretField.stringValue
        
        if (hostValue.count > 0 && secretValue.count > 0) {
            delegate.onSave(sender, hostValue, secretValue)
        }
    }
    
    @IBAction func onTestConnectionClick(_ sender: NSButton) {
        let hostValue = hostField.stringValue
        let secretValue = secretField.stringValue
        
        if (hostValue.count > 0 && secretValue.count > 0) {
            delegate.onTestConnection(sender, hostValue, secretValue)
        }
    }
    
    var delegate: PreferencesControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let host = UserDefaults.standard.string(forKey: "host") ?? ""
        let secret = UserDefaults.standard.string(forKey: "secret") ?? ""
        
        hostField.stringValue = host
        secretField.stringValue = secret
    }
    
}
