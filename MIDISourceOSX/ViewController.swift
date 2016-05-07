//
//  ViewController.swift
//  MIDISourceOSX
//
//  Created by Gene De Lisa on 5/5/16.
//  Copyright © 2016 Gene De Lisa. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        MIDIManager.sharedInstance.initMIDI()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
                                                         selector:(#selector(NSWindowDelegate.windowWillClose(_:))),
                                                         name:NSWindowWillCloseNotification,
                                                         object:self.view.window)

    }
    
    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func playAction(sender: NSButton) {
        let musicSequence = MIDIManager.sharedInstance.createMusicSequence()
        MIDIManager.sharedInstance.createPlayer(musicSequence)
        MIDIManager.sharedInstance.startPlaying()
    }
    
    func windowWillClose(notification: NSNotification) {
        NSApplication.sharedApplication().terminate(0)
    }

}
