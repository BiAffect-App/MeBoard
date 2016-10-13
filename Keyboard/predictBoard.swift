//
//  predictboard.swift
//  TransliteratingKeyboard
//
//  Created by Alexei Baboulevitch on 9/24/14.
//  Copyright (c) 2014 Alexei Baboulevitch ("Archagon"). All rights reserved.
//

import UIKit

/*
 This is the demo keyboard. If you're implementing your own keyboard, simply follow the example here and then
 set the name of your KeyboardViewController subclass in the Info.plist file.
 */
let predictionEnabled = "predictionEnabled"

class predictBoard: KeyboardViewController {
    
    let takeDebugScreenshot: Bool = false
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        NSUserDefaults.standardUserDefaults().registerDefaults([predictionEnabled: true])
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func keyPressed(key: Key) {
        let textDocumentProxy = self.textDocumentProxy
        let keyOutput = key.outputForCase(self.shiftState.uppercase())
        
        if !NSUserDefaults.standardUserDefaults().boolForKey(predictionEnabled) {
            textDocumentProxy.insertText(keyOutput)
            return
        }
        
        if key.type == .Character || key.type == .SpecialCharacter {
            if let context = textDocumentProxy.documentContextBeforeInput {
                if context.characters.count < 2 {
                    textDocumentProxy.insertText(keyOutput)
                    return
                }
                
                var index = context.endIndex
                
                index = index.predecessor()
                if context[index] != " " {
                    textDocumentProxy.insertText(keyOutput)
                    return
                }
                
                index = index.predecessor()
                if context[index] == " " {
                    textDocumentProxy.insertText(keyOutput)
                    return
                }
                //textDocumentProxy.insertText("\(autoComplete())")
                textDocumentProxy.insertText(" ")
                textDocumentProxy.insertText(keyOutput)
                return
            }
            else {
                textDocumentProxy.insertText(keyOutput)
                return
            }
        }
        else {
            textDocumentProxy.insertText(keyOutput)
            return
        }
    }
    
    override func setupKeys() {
        super.setupKeys()
        
        if takeDebugScreenshot {
            if self.layout == nil {
                return
            }
            
            for page in keyboard.pages {
                for rowKeys in page.rows {
                    for key in rowKeys {
                        if let keyView = self.layout!.viewForKey(key) {
                            keyView.addTarget(self, action: "takeScreenshotDelay", forControlEvents: .TouchDown)
                        }
                    }
                }
            }
        }
    }
    
    override func createBanner() -> ExtraView? {
        return predictboardBanner(globalColors: self.dynamicType.globalColors, darkMode: false, solidColorMode: self.solidColorMode(), outputFunc: autoComplete)
    }
    
    func takeScreenshotDelay() {
        NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: Selector("takeScreenshot"), userInfo: nil, repeats: false)
    }
    
    func takeScreenshot() {
        if !CGRectIsEmpty(self.view.bounds) {
            UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
            
            let oldViewColor = self.view.backgroundColor
            self.view.backgroundColor = UIColor(hue: (216/360.0), saturation: 0.05, brightness: 0.86, alpha: 1)
            
            let rect = self.view.bounds
            UIGraphicsBeginImageContextWithOptions(rect.size, true, 0)
            var context = UIGraphicsGetCurrentContext()
            self.view.drawViewHierarchyInRect(self.view.bounds, afterScreenUpdates: true)
            let capturedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            let name = (self.interfaceOrientation.isPortrait ? "Screenshot-Portrait" : "Screenshot-Landscape")
            let imagePath = "/Users/archagon/Documents/Programming/OSX/RussianPhoneticKeyboard/External/tasty-imitation-keyboard/\(name).png"
            
            if let pngRep = UIImagePNGRepresentation(capturedImage) {
                pngRep.writeToFile(imagePath, atomically: true)
            }
            
            self.view.backgroundColor = oldViewColor
        }
    }
    
    //added
    func autoComplete(word:String) -> () {
        let textDocumentProxy = self.textDocumentProxy
        
        if let context = textDocumentProxy.documentContextBeforeInput
        {
            if context.characters.count > 0
            {
                var index = context.endIndex
                index = index.predecessor()

                while index > context.startIndex && context[index] != " "
                {
                        index = index.predecessor()

                    textDocumentProxy.deleteBackward()
                }
                if index == context.startIndex && context[index] != " "
                {
                    textDocumentProxy.deleteBackward()
                }
            }
        }
        var insertionWord = word
        if let postContext = textDocumentProxy.documentContextAfterInput
        {
            let postIndex = postContext.startIndex
            if postContext[postIndex] != " " //add space if next word doesnt begin with space
            {
                insertionWord = word + " "
            }
        }
        else //add space if you are the last added word.
        {
            insertionWord = word + " "
        }
        textDocumentProxy.insertText(insertionWord)
    }
    
}


