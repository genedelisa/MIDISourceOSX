//
//  Preferences.swift
//  MIDISourceOSX
//
//  Created by Gene De Lisa on 5/6/16.
//  Copyright © 2016 Gene De Lisa. All rights reserved.
//

import Foundation


class Preferences {
    static let sharedInstance = Preferences()
    
    private let defaults = NSUserDefaults.standardUserDefaults()

    private struct Keys {
        static let mainWindowFrame = "mainWindowFrame"
    }
    
    private struct DefaultValues {
        static let mainWindowFrame = NSZeroRect
    }

    var mainWindowFrame: NSRect {
        set {
            defaults.setObject(NSStringFromRect(newValue), forKey: Keys.mainWindowFrame)
        }
        get {
            if let rectString = defaults.objectForKey(Keys.mainWindowFrame) as? String {
                return NSRectFromString(rectString)
            } else {
                return DefaultValues.mainWindowFrame
            }
        }
    }
}

/*
 NSNotificationCenter.defaultCenter().addObserverForName(NSWindowWillCloseNotification, object: nil, queue: nil) { _ in
 if let window = self.window {
 Preferences.sharedInstance.mainWindowFrame = window.frame
 }
 }
 */