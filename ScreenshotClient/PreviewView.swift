//
//  PreviewView.swift
//  ScreenshotUploader01
//
//  Created by Martin Dines on 13/08/2019.
//  Copyright © 2019 Martin Dines. All rights reserved.
//

// To allow the NSImageView to fit the parent:
// Image View > Scaling > Proportionately Up and Down
// Autosizing should be enabled on every edge(?)

import Cocoa

class PreviewView: NSView {
    
    @IBOutlet weak var imageView: NSImageView!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    func update(_ image: NSImage, width: Int, height: Int) {
        var scaledWidth: Int
        var scaledHeight: Int
        
        // Scale according to aspect ratio (portrait vs landscape)
        if (width < height) {
            (scaledWidth, scaledHeight) = scaleDimensionsToMaxHeight(width: width, height: height) as (width: Int, height: Int)
        } else {
            (scaledWidth, scaledHeight) = scaleDimensionsToMaxWidth(width: width, height: height) as (width: Int, height: Int)
        }
        
        // do UI updates on the main thread
        DispatchQueue.main.async {
            self.frame = NSRect.init(x: 0, y: 0, width: scaledWidth, height: scaledHeight)
            self.imageView.image = image
        }
    }
    
    func scaleDimensionsToMaxWidth(width: Int, height: Int, maxWidth: Float = 200) -> (width: Int, height: Int)
    {
        let ratio: Float = Float(width) / Float (height)
        
        let scaledWidth = Int(Float(maxWidth))
        let scaledHeight = Int(Float(maxWidth) / ratio)
        
        return (scaledWidth, scaledHeight)
    }
    
    func scaleDimensionsToMaxHeight(width: Int, height: Int, maxHeight: Float = 200) -> (width: Int, height: Int)
    {
        let ratio: Float = Float(width) / Float (height)
        
        let scaledWidth = Int(Float(maxHeight))
        let scaledHeight = Int(Float(maxHeight) / ratio)
        
        return (scaledWidth, scaledHeight)
    }
}
