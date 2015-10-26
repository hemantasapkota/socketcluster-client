//
//  SocketClusterClient.swift
//  SocketClusterTest
//
//  Created by Hemanta Sapkota on 7/08/2015.
//  Copyright (c) 2015 Hemanta Sapkota. All rights reserved.
//

import Foundation
import Starscream
import JSONJoy
import XCGLogger
import GCDTimer

internal protocol SCEvent : JSONStringConvertible {
}

internal protocol JSONDictConvertible {
    func toDict() -> Dictionary<String, AnyObject>?
}

internal protocol JSONStringConvertible {
    func toJSON() -> String?
}

internal protocol JSONDataConvertible {
    func toJSONData() -> NSData?
}

internal struct StringData : JSONDictConvertible {
    var key: String
    var value: String

    internal func toDict() -> Dictionary<String, AnyObject>? {
        return [
            key : value
        ]
    }
}

internal struct Event : JSONDataConvertible, JSONStringConvertible {
    var cid:    Int?
    var rid:    Int?
    var event:  String?
    var data:   AnyObject?

    init(cid: Int?, rid: Int?, event: String?, data: AnyObject?) {
        self.cid = cid
        self.rid = rid
        self.event = event
        self.data = data
    }

    internal func toJSON() -> String? {
        if let data = self.toJSONData() {
            let str = NSString(data: data, encoding: NSUTF8StringEncoding)
            return String(str!)
        }
        return nil
    }

    internal func toJSONData() -> NSData? {
        var dict = NSMutableDictionary()
        
        dict.setValue(event, forKey: "event")
        dict.addEntriesFromDictionary(["data" : data!])
        dict.setValue(cid, forKey: "cid")
        dict.setValue(rid, forKey: "rid")

        return NSJSONSerialization.dataWithJSONObject(dict, options: nil, error: nil)
    }
}

internal struct SCAuthObject {
    var authError: String?
    var rid: Int?
    var isAuthenticated: Bool?
    var pingTimeout: Int?

    init(dict: [String:AnyObject]) {
        self.rid = dict["rid"] as? Int
        self.authError = dict["authError"] as? String
        self.isAuthenticated = dict["isAuthenticated"] as? Bool
        self.pingTimeout = dict["pingTimeout"] as? Int
    }
}

internal struct SCAuthResponse {
    var rid: Int?
    var data: SCAuthObject?

    init(dict: [String:AnyObject]) {
        self.rid = dict["rid"] as? Int
        if let _data: AnyObject = dict["data"] {
            self.data = SCAuthObject(dict: _data as! [String : AnyObject])
        }
    }
}

internal struct SCLoginResponse {
    var rid: Int?
    var timeToExpiry: Int?

    init(dict: [String:AnyObject]) {
        // Eventually this dict with have a field called timeToExpiry
        self.timeToExpiry = dict["data"] as? Int
    }
}

internal struct SCSetAuthTokenResponse {
    var token: String?

    init(dict: [String:AnyObject]) {
        self.token = dict["token"] as? String
    }
}

class SocketClusterClient {

    /* Constants */
    private static let PONG = "2"

    private static let SCAuthTokenStoreKey = "kSCAuthTokenKey"

    private static let SCTimeToExpiryStoreKey = "kSCTimeToExpiryKey"

    static let dispatchQueue = dispatch_queue_create("socketClusterQueue", DISPATCH_QUEUE_CONCURRENT)

    /* Private variables */
    private var cid = 1

    private var serverAuthToken: String?
    
    private var events = [Int:Event]()

    /* Internal variables */
    internal var log = XCGLogger.defaultInstance()

    /* Public variables */
    var socket: WebSocket!

    var profileName: String!
    
    /* Properties */
    var _loginAuthToken: String!
    var LoginAuthToken: String {
        get {
            return _loginAuthToken
        }
        set {
            _loginAuthToken = newValue
        }
    }

    /* Handlers */

    var onAuthenticationSuccess: (() -> Void)?

    var onAuthenticationFailure: ((erorr:String?) -> Void)?

    var onEventResponse: ((event:Event)->Void)?

    var onRenewToken: (() -> Void)?

    /* End Handlers */

    init(profileName: String, host: String) {
        //TODO: Change the scheme to WSS for production
        socket = WebSocket(url: NSURL(scheme: "wss", host: "\(host)/socketcluster/", path: "/")!)

        self.profileName = profileName

        /* Set any headers here */
        /* socket.headers["Some-header"] = "somValue" */

        socket.onConnect = {
            self.log.info("SC: Connected")

            // Handshake event
            var id = self.newCid()
            var event = Event(cid: id, rid:nil, event: "#handshake", data: [ "authToken" : OLDB.store[SocketClusterClient.SCAuthTokenStoreKey]! ])
            self.emit(event)
            self.events[id] = event
        }

        socket.onDisconnect = { error in
            self.log.info("SC: Disconnected")
        }

        socket.onData = { data in
            self.log.info("\(data)")
        }

        socket.onText = { text in
//            self.log.info("SC: onText: \(text)")
            
            dispatch_async(SocketClusterClient.dispatchQueue, { () -> Void in
                
                // Ping data
                if text == "1" {
                    return self.socket.writeString(SocketClusterClient.PONG)
                }

                self.lookupEventForResponse(text, completion: { (event, response) -> Void in
                    if let eventVal = event!.event {
                        if eventVal == "login" {
                            return self.processLogin(response as! SCLoginResponse)
                        }

                        if eventVal == "#disconnect" {
                            return self.socket.disconnect()
                        }

                        if eventVal == "#handshake" {
                            return self.processHandshake(response as! SCAuthResponse)
                        }

                        if eventVal == "#setAuthToken" {
                            return self.processSetAuthToken(response as! SCSetAuthTokenResponse)
                        }
                    }
                    
                    // Forward event
                    if let forwardEvent = self.onEventResponse {
                        return forwardEvent(event: event!)
                    }
                })
            })
        }

        socket.onPong = {
            self.log.info("SC: Pong")
        }
    }
}

extension SocketClusterClient {

    private func processLogin(response: SCLoginResponse) {
        let timeToExpiry = response.timeToExpiry!

        OLDB.store[SocketClusterClient.SCTimeToExpiryStoreKey] = "\(timeToExpiry)"

        self.setUpAuthRenewMechanism(timeToExpiry)
    }

    private func setUpAuthRenewMechanism(timeToExpiry: Int) {
        GCDTimer.delay(Double(timeToExpiry), queue: SocketClusterClient.dispatchQueue, block: { () -> Void in
            if let requestNewAuthToken = self.onRenewToken {
                requestNewAuthToken()
            }
        })
    }

    private func processSetAuthToken(response: SCSetAuthTokenResponse) {
        OLDB.store[SocketClusterClient.SCAuthTokenStoreKey] = response.token!

        if let triggerAuthSuccess = onAuthenticationSuccess {
            triggerAuthSuccess()
        }
    }

    private func processHandshake(authObject: SCAuthResponse) {
        // Check if authenticated

        if let authData = authObject.data {

            // TODO: What to do with authData.pingTimeout ?
            if !authData.isAuthenticated! {
                
                // Emit clearoldsession event
                var id = newCid()
                var event = Event(cid: id, rid: nil, event: "clearoldsessions", data: self.profileName)
                self.emit(event)
                self.events[id] = event

                // Emit login event
                id = newCid()
                let loginEvent = Event(
                    cid: id,
                    rid:nil,
                    event: "login",
                    data: [
                        "profileName" : self.profileName,
                        "auth_token"  : self._loginAuthToken
                    ])
                self.emit(loginEvent)
                self.events[id] = event
                
            } else {

                if let triggerAuthSuccess = onAuthenticationSuccess {
                    triggerAuthSuccess()
                }
            }
        }
    }
}

// Plumbing stuff
extension SocketClusterClient {

    internal func JSONStringify(data: AnyObject) -> NSString? {
        var data = NSJSONSerialization.dataWithJSONObject(data, options: nil, error: nil)
        
        // See http://stackoverflow.com/questions/19651009/how-to-prevent-nsjsonserialization-from-adding-extra-escapes-in-url
        var str:NSString = NSString(data: data!, encoding: NSUTF8StringEncoding)!
        str = str.stringByReplacingOccurrencesOfString("\\/", withString: "/")
        
        return str
    }


    internal func newCid() -> Int {
        dispatch_sync(SocketClusterClient.dispatchQueue, { () -> Void in
            self.cid = self.cid + 1
        })
        return cid
    }
}

// Events and responses
extension SocketClusterClient {

    internal func emit(event: Event) {
        // Emit events in a serial order
        dispatch_sync(SocketClusterClient.dispatchQueue, { () -> Void in
            if let jsonData = event.toJSONData() {
                self.log.info("\(NSString(data: jsonData, encoding: NSUTF8StringEncoding)!)")
                self.socket.writeData(jsonData)
            }
        })
    }

    private func lookupEventForResponse(text: String, completion:((Event?, Any?) -> Void))  {
        let data = text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        let resp: AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableContainers, error: nil)

        var event:Event? = nil
        var response:Any? = nil

        if resp == nil {
            return completion(event, response)
        }

        let d = resp as? [String:AnyObject]

        if d == nil {
            return completion(event, response)
        }

        let dict = d!

        // Check the return id
        let rid = dict["rid"] as? Int
        let cid = dict["cid"] as? Int
        let eventName = dict["event"] as? String
        
        // Check if the events are internal
        if let id = rid {
            if let event = events[id] {
                var name = event.event!
                if name == "#handshake" {
                    response = SCAuthResponse(dict: dict)
                } else if name == "login" {
                    response = SCLoginResponse(dict: dict)
                }
                return completion(event, response)
            }
        }
        
        event = Event(cid: cid, rid: rid, event: eventName, data: dict["data"])
        if eventName == "#setAuthToken" {
            response = SCSetAuthTokenResponse(dict: dict["data"] as! [String:AnyObject])
        }
        
        completion(event, response)
    }

}

//Public interface
extension SocketClusterClient {

    func connect() {
        log.info("SC: connecting...")
        dispatch_async(SocketClusterClient.dispatchQueue, { () -> Void in
            self.socket.connect()
        })
    }

    func disconnect() {
        log.info("SC: Disconnecting...")
        dispatch_async(SocketClusterClient.dispatchQueue, { () -> Void in
            self.socket.disconnect()
        })
    }

    func subscribe(channels: [String], completion:(eventId:Int) -> ()) {
        dispatch_async(SocketClusterClient.dispatchQueue, { () -> Void in
            var id = self.newCid()
            let event = Event(cid: id, rid: nil, event: "#subscribe", data: self.JSONStringify(channels)!)
            self.emit(event)
            completion(eventId: id)
        })
    }

    func unsubscribeFromAllChannels() {
    }
}