//
//  MIDIManager.swift
//  MIDISourceOSX
//
//  Created by Gene De Lisa on 6/9/15.
//  Copyright © 2015 Gene De Lisa. All rights reserved.
//

import Foundation
import CoreMIDI
import AudioToolbox


//http://blog.willbenton.com/2003/12/os-x-audio-toolbox-programming-tip-of-the-day/

/**
 # MIDIManager
 
 > Here is an initial cut at using the new Swift 2.0 MIDI frobs.
 
 */
class MIDIManager : NSObject {
    
    static var sharedInstance = MIDIManager()
    
    var midiClient = MIDIClientRef()
    
    var outputPort = MIDIPortRef()
    
    var inputPort = MIDIPortRef()
    
    var virtualDestinationEndpointRef = MIDIEndpointRef()
    
    var virtualSourceEndpointRef = MIDIEndpointRef()
    
    typealias MIDINotifier = (message:UnsafePointer<MIDINotification>) -> ()
    
    var midiNotifier: MIDINotifier?
    
    var midiReadBlock:MIDIReadBlock?
    
    /**
     This will initialize the midiClient, outputPort, and inputPort variables.
     */
    
    func initMIDI(midiNotifier: MIDINotifyBlock? = nil) {
        
        
        var notifyBlock: MIDINotifyBlock
        
        if midiNotifier != nil {
            notifyBlock = midiNotifier!
        } else {
            notifyBlock = myNotifyCallback
        }
        
        var status = OSStatus(noErr)
        
        status = MIDIClientCreateWithBlock("com.rockhoppertech.MyMIDIClient", &midiClient, notifyBlock)
        
        if status == OSStatus(noErr) {
            print("created client")
        } else {
            print("error creating client : \(status)")
            CheckError(status)
        }
        
        if status == OSStatus(noErr) {
            
            status = MIDIDestinationCreateWithBlock(midiClient,
                                                    "MIDISourceOSX.VirtualDest",
                                                    &virtualDestinationEndpointRef,
                                                    MIDIPassThru)
            
            if status != noErr {
                print("error creating virtual destination: \(status)")
            } else {
                print("midi virtual destination created \(virtualDestinationEndpointRef)")
            }
            saveVirtualDestinationID()
            
            
            //use MIDIReceived to transmit MIDI messages from your virtual source to any clients connected to the virtual source. Since we're using a MusicSequence, we need to use a virtual dest to catch the events and forward them via MIDIReceived.
            status = MIDISourceCreate(midiClient,
                                      "MIDISourceOSX.VirtualSource",
                                      &virtualSourceEndpointRef
            )
            if status != noErr {
                print("error creating virtual source: \(status)")
            } else {
                print("midi virtual source created \(virtualSourceEndpointRef)")
            }
            saveVirtualSourceID()
        }
        
    }
    
    func saveVirtualSourceID() {
        
        
        let sid = NSUserDefaults.standardUserDefaults().integerForKey(savedVirtualSourceKey)
        var uniqueID = MIDIUniqueID(sid)
        
        // it's not in defaults. get it and save it
        if sid == 0 {
            let (s,id) = getUniqueID(virtualSourceEndpointRef)
            if s == noErr {
                print("saving id for src: \(id)")
                NSUserDefaults.standardUserDefaults().setInteger(Int(id),
                                                                 forKey:savedVirtualSourceKey)
                uniqueID = MIDIUniqueID(id)
            }
        } else {
            
            let status = setUniqueID(virtualSourceEndpointRef, id: uniqueID)
            if status == kMIDIIDNotUnique {
                print("oops. id not unique for src: \(uniqueID)")
                uniqueID = 0
            }
            else {
                print("set id for src: \(uniqueID)")
            }
        }
        
    }
    
    func saveVirtualDestinationID() {
        
        let sid = NSUserDefaults.standardUserDefaults().integerForKey(savedVirtualDestinationKey)
        var uniqueID = MIDIUniqueID(sid)
        
        // it's not in defaults. get it and save it
        if sid == 0 {
            let (s,id) = getUniqueID(virtualDestinationEndpointRef)
            if s == noErr {
                print("saving id for dest: \(id)")
                NSUserDefaults.standardUserDefaults().setInteger(Int(id),
                                                                 forKey:savedVirtualDestinationKey)
                uniqueID = MIDIUniqueID(id)
            }
        } else {
            
            let status = setUniqueID(virtualDestinationEndpointRef, id: uniqueID)
            if status == kMIDIIDNotUnique {
                print("oops. id not unique for dest: \(uniqueID)")
                uniqueID = 0
            }
            else {
                print("set id for dest: \(uniqueID)")
            }
        }
    }
    
    let savedVirtualDestinationKey = "savedVirtualDestinationKey"
    let savedVirtualSourceKey = "savedVirtualSourceKey"
    
    
    func myNotifyCallback(message:UnsafePointer<MIDINotification>) -> Void {
        print("got a MIDINotification!")
        
        let notification = message.memory
        print("MIDI Notify, messageId= \(notification.messageID)")
        
        switch (notification.messageID) {
        case MIDINotificationMessageID.MsgSetupChanged:
            NSLog("MIDI setup changed")
            break
            
        case MIDINotificationMessageID.MsgObjectAdded:
            NSLog("added")
            let mp = UnsafeMutablePointer<MIDIObjectAddRemoveNotification>(message)
            let m:MIDIObjectAddRemoveNotification = mp.memory
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            print("child \(m.child)")
            print("child type \(m.childType)")
            print("parent \(m.parent)")
            print("parentType \(m.parentType)")
            
            //            let m:MIDIObjectAddRemoveNotification =
            //            unsafeBitCast(notification, MIDIObjectAddRemoveNotification.self)
            //
            //            print("id \(m.messageID)")
            //            print("size \(m.messageSize)")
            //            print("child \(m.child)")
            //            print("child type \(m.childType)")
            //            print("parent \(m.parent)")
            //            print("parentType \(m.parentType)")
            
            break
            
        case MIDINotificationMessageID.MsgObjectRemoved:
            NSLog("kMIDIMsgObjectRemoved")
            let mp = UnsafeMutablePointer<MIDIObjectAddRemoveNotification>(message)
            let m:MIDIObjectAddRemoveNotification = mp.memory
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            print("child \(m.child)")
            print("child type \(m.childType)")
            print("parent \(m.parent)")
            print("parentType \(m.parentType)")
            
            break
            
        case MIDINotificationMessageID.MsgPropertyChanged :
            NSLog("kMIDIMsgPropertyChanged")
            let mp = UnsafeMutablePointer<MIDIObjectPropertyChangeNotification>(message)
            let m:MIDIObjectPropertyChangeNotification = mp.memory
            print("id \(m.messageID)")
            print("size \(m.messageSize)")
            print("property name \(m.propertyName)")
            print("object type \(m.objectType)")
            print("object \(m.object)")
            
            break
            
        case MIDINotificationMessageID.MsgThruConnectionsChanged :
            NSLog("MIDI thru connections changed.")
            break
            
        case MIDINotificationMessageID.MsgSerialPortOwnerChanged :
            NSLog("MIDI serial port owner changed.")
            break
            
        case MIDINotificationMessageID.MsgIOError :
            NSLog("MIDI I/O error.")
            break
            
        }
        
    }
    
    
    
    
    ///  Take the packets emitted frome the MusicSequence and forward them to the virtual source.
    ///
    ///  - parameter packetList:    packets from the MusicSequence
    ///  - parameter srcConnRefCon: not used
    func MIDIPassThru(packetList: UnsafePointer<MIDIPacketList>, srcConnRefCon: UnsafeMutablePointer<Void>) -> Void {
        print("sending packets to source \(packetList)")
        MIDIReceived(virtualSourceEndpointRef, packetList)
    }
    
    
    /**
     Not as detailed as Adamson's CheckError, but adequate.
     For other projects you can uncomment the Core MIDI constants.
     */
    func CheckError(error:OSStatus) {
        if error == 0 {return}
        
        switch(error) {
            // beta4 change
        //            switch(Int(error)) {
        case kMIDIInvalidClient :
            print( "kMIDIInvalidClient ")
            
        case kMIDIInvalidPort :
            print( "kMIDIInvalidPort ")
            
        case kMIDIWrongEndpointType :
            print( "kMIDIWrongEndpointType")
            
        case kMIDINoConnection :
            print( "kMIDINoConnection ")
            
        case kMIDIUnknownEndpoint :
            print( "kMIDIUnknownEndpoint ")
            
        case kMIDIUnknownProperty :
            print( "kMIDIUnknownProperty ")
            
        case kMIDIWrongPropertyType :
            print( "kMIDIWrongPropertyType ")
            
        case kMIDINoCurrentSetup :
            print( "kMIDINoCurrentSetup ")
            
        case kMIDIMessageSendErr :
            print( "kMIDIMessageSendErr ")
            
        case kMIDIServerStartErr :
            print( "kMIDIServerStartErr ")
            
        case kMIDISetupFormatErr :
            print( "kMIDISetupFormatErr ")
            
        case kMIDIWrongThread :
            print( "kMIDIWrongThread ")
            
        case kMIDIObjectNotFound :
            print( "kMIDIObjectNotFound ")
            
        case kMIDIIDNotUnique :
            print( "kMIDIIDNotUnique ")
            
        default: print( "huh? \(error) ")
        }
        
        
        switch(error) {
        //AUGraph.h
        case kAUGraphErr_NodeNotFound:
            print("Error:kAUGraphErr_NodeNotFound \n")
            
        case kAUGraphErr_OutputNodeErr:
            print( "Error:kAUGraphErr_OutputNodeErr \n")
            
        case kAUGraphErr_InvalidConnection:
            print("Error:kAUGraphErr_InvalidConnection \n")
            
        case kAUGraphErr_CannotDoInCurrentContext:
            print( "Error:kAUGraphErr_CannotDoInCurrentContext \n")
            
        case kAUGraphErr_InvalidAudioUnit:
            print( "Error:kAUGraphErr_InvalidAudioUnit \n")
            
            // core audio
            
        case kAudio_UnimplementedError:
            print("kAudio_UnimplementedError")
        case kAudio_FileNotFoundError:
            print("kAudio_FileNotFoundError")
        case kAudio_FilePermissionError:
            print("kAudio_FilePermissionError")
        case kAudio_TooManyFilesOpenError:
            print("kAudio_TooManyFilesOpenError")
        case kAudio_BadFilePathError:
            print("kAudio_BadFilePathError")
        case kAudio_ParamError:
            print("kAudio_ParamError")
        case kAudio_MemFullError:
            print("kAudio_MemFullError")
            
            
            // AudioToolbox
            
        case kAudioToolboxErr_InvalidSequenceType :
            print( " kAudioToolboxErr_InvalidSequenceType ")
            
        case kAudioToolboxErr_TrackIndexError :
            print( " kAudioToolboxErr_TrackIndexError ")
            
        case kAudioToolboxErr_TrackNotFound :
            print( " kAudioToolboxErr_TrackNotFound ")
            
        case kAudioToolboxErr_EndOfTrack :
            print( " kAudioToolboxErr_EndOfTrack ")
            
        case kAudioToolboxErr_StartOfTrack :
            print( " kAudioToolboxErr_StartOfTrack ")
            
        case kAudioToolboxErr_IllegalTrackDestination :
            print( " kAudioToolboxErr_IllegalTrackDestination")
            
        case kAudioToolboxErr_NoSequence :
            print( " kAudioToolboxErr_NoSequence ")
            
        case kAudioToolboxErr_InvalidEventType :
            print( " kAudioToolboxErr_InvalidEventType")
            
        case kAudioToolboxErr_InvalidPlayerState :
            print( " kAudioToolboxErr_InvalidPlayerState")
            
            // AudioUnit
            
            
        case kAudioUnitErr_InvalidProperty :
            print( " kAudioUnitErr_InvalidProperty")
            
        case kAudioUnitErr_InvalidParameter :
            print( " kAudioUnitErr_InvalidParameter")
            
        case kAudioUnitErr_InvalidElement :
            print( " kAudioUnitErr_InvalidElement")
            
        case kAudioUnitErr_NoConnection :
            print( " kAudioUnitErr_NoConnection")
            
        case kAudioUnitErr_FailedInitialization :
            print( " kAudioUnitErr_FailedInitialization")
            
        case kAudioUnitErr_TooManyFramesToProcess :
            print( " kAudioUnitErr_TooManyFramesToProcess")
            
        case kAudioUnitErr_InvalidFile :
            print( " kAudioUnitErr_InvalidFile")
            
        case kAudioUnitErr_FormatNotSupported :
            print( " kAudioUnitErr_FormatNotSupported")
            
        case kAudioUnitErr_Uninitialized :
            print( " kAudioUnitErr_Uninitialized")
            
        case kAudioUnitErr_InvalidScope :
            print( " kAudioUnitErr_InvalidScope")
            
        case kAudioUnitErr_PropertyNotWritable :
            print( " kAudioUnitErr_PropertyNotWritable")
            
        case kAudioUnitErr_InvalidPropertyValue :
            print( " kAudioUnitErr_InvalidPropertyValue")
            
        case kAudioUnitErr_PropertyNotInUse :
            print( " kAudioUnitErr_PropertyNotInUse")
            
        case kAudioUnitErr_Initialized :
            print( " kAudioUnitErr_Initialized")
            
        case kAudioUnitErr_InvalidOfflineRender :
            print( " kAudioUnitErr_InvalidOfflineRender")
            
        case kAudioUnitErr_Unauthorized :
            print( " kAudioUnitErr_Unauthorized")
            
        default:
            print("huh?")
        }
    }
    func showError(status:OSStatus) {
        
        switch status {
            
        case OSStatus(kMIDIInvalidClient):
            print("invalid client")
            break
        case OSStatus(kMIDIInvalidPort):
            print("invalid port")
            break
        case OSStatus(kMIDIWrongEndpointType):
            print("invalid endpoint type")
            break
        case OSStatus(kMIDINoConnection):
            print("no connection")
            break
        case OSStatus(kMIDIUnknownEndpoint):
            print("unknown endpoint")
            break
            
        case OSStatus(kMIDIUnknownProperty):
            print("unknown property")
            break
        case OSStatus(kMIDIWrongPropertyType):
            print("wrong property type")
            break
        case OSStatus(kMIDINoCurrentSetup):
            print("no current setup")
            break
        case OSStatus(kMIDIMessageSendErr):
            print("message send")
            break
        case OSStatus(kMIDIServerStartErr):
            print("server start")
            break
        case OSStatus(kMIDISetupFormatErr):
            print("setup format")
            break
        case OSStatus(kMIDIWrongThread):
            print("wrong thread")
            break
        case OSStatus(kMIDIObjectNotFound):
            print("object not found")
            break
            
        case OSStatus(kMIDIIDNotUnique):
            print("not unique")
            break
            
        case OSStatus(kMIDINotPermitted):
            print("not permitted")
            break
            
        default:
            print("dunno \(status)")
        }
    }
    
    //The system assigns unique IDs to all objects
    func getUniqueID(endpoint:MIDIEndpointRef) -> (OSStatus, MIDIUniqueID) {
        var id = MIDIUniqueID(0)
        let s = MIDIObjectGetIntegerProperty(endpoint, kMIDIPropertyUniqueID, &id)
        if s != noErr {
            print("error getting unique id \(s)")
        }
        return (s,id)
    }
    
    func setUniqueID(endpoint:MIDIEndpointRef, id:MIDIUniqueID) -> OSStatus {
        let s = MIDIObjectSetIntegerProperty(endpoint, kMIDIPropertyUniqueID, id)
        if s != noErr {
            print("error getting unique id \(s)")
        }
        return s
    }
    
    
    
    //MARK: playback
    
    func createMusicSequence() -> MusicSequence {
        // create the sequence
        var musicSequence:MusicSequence = nil
        var status = NewMusicSequence(&musicSequence)
        if status != OSStatus(noErr) {
            print("bad status \(status) creating sequence")
            CheckError(status)
        }
        
        // add a track
        var track:MusicTrack = nil
        status = MusicSequenceNewTrack(musicSequence, &track)
        if status != OSStatus(noErr) {
            print("error creating track \(status)")
            CheckError(status)
        }
        
        // now make some notes and put them on the track
        var beat = MusicTimeStamp(1.0)
        for i:UInt8 in 60...72 {
            var mess = MIDINoteMessage(channel: 0,
                                       note: i,
                                       velocity: 64,
                                       releaseVelocity: 0,
                                       duration: 1.0 )
            status = MusicTrackNewMIDINoteEvent(track, beat, &mess)
            if status != OSStatus(noErr) {
                CheckError(status)
            }
            beat += 1
        }
        
        //loopTrack(track)
        
        status = MusicSequenceSetMIDIEndpoint(musicSequence, virtualDestinationEndpointRef)
        if status != OSStatus(noErr) {
            CheckError(status)
        }
        
        return musicSequence
    }
    
    var musicPlayer:MusicPlayer = nil
    func createPlayer(musicSequence:MusicSequence) {
        
        var status = OSStatus(noErr)
        status = NewMusicPlayer(&musicPlayer)
        if status != OSStatus(noErr) {
            print("bad status \(status) creating player")
            CheckError(status)
        }
        status = MusicPlayerSetSequence(musicPlayer, musicSequence)
        if status != OSStatus(noErr) {
            print("setting sequence \(status)")
            CheckError(status)
        }
        status = MusicPlayerPreroll(musicPlayer)
        if status != OSStatus(noErr) {
            print("prerolling player \(status)")
            CheckError(status)
        }
    }
    
    // called fron the button's action
    func startPlaying() {
        var status = OSStatus(noErr)
        
        var playing = DarwinBoolean(false)
        status = MusicPlayerIsPlaying(musicPlayer, &playing)
        if playing != false {
            print("music player is playing. stopping")
            status = MusicPlayerStop(musicPlayer)
            if status != OSStatus(noErr) {
                print("Error stopping \(status)")
                CheckError(status)
                return
            }
        } else {
            print("music player is not playing. No need to stop it.")
        }
        
        status = MusicPlayerSetTime(musicPlayer, 0)
        if status != OSStatus(noErr) {
            print("setting time \(status)")
            CheckError(status)
            return
        } else {
            print("set playback time to 0")
        }
        
        status = MusicPlayerStart(musicPlayer)
        if status != OSStatus(noErr) {
            print("Error starting \(status)")
            CheckError(status)
            return
        } else {
            print("started playing")
        }
    }
    
    func stopPlaying() {
        var status = OSStatus(noErr)
        status = MusicPlayerStop(musicPlayer)
        if status != OSStatus(noErr) {
            print("Error stopping \(status)")
            CheckError(status)
            return
        }
    }
    
}



