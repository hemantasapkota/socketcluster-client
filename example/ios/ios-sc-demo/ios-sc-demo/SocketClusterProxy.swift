//
//  SocketCluster.swift
//  ios-sc-demo
//
//  Created by Hemanta Sapkota on 9/06/2016.
//  Copyright © 2016 Hemanta Sapkota. All rights reserved.
//

import Foundation
import SocketClusterClient
import GCDTimer

class SocketClusterProxy {
    
    var scQueue = dispatch_queue_create("scQueue", DISPATCH_QUEUE_CONCURRENT)
    
    func getDocumentsPath() -> String {
        //TODO: This makes the assumption of dir name Documents.
        return NSHomeDirectory() + "/Documents/"
    }
    
    init() {
    }
    
    func connect() {
        let host = "localhost:8000"
        let profileName = ""
        let authToken = ""
        let userAgent = ""
        let secure = false
        let dbPath = getDocumentsPath()
        var error:NSError? = nil
        
        GoSocketClusterClientNewSocketClusterClient(host, profileName, authToken, userAgent, secure, dbPath, &error)
        
        if error != nil {
            return
        }
        
        let dataPollTimer = GCDTimer(intervalInSecs: 0.5)
        dataPollTimer.Event = {
            var data:NSData? = nil
            var err:NSError? = nil
            GoSocketClusterClientGetData(&data, &err)
            if err != nil {
//                print("\(err)")
            } else {
//                let s = NSString(data: data!, encoding: NSUTF8StringEncoding)
                // Do something with the data
//                print(s)
            }
        }
        dataPollTimer.start()
        
    }
    
    func disconnect() {
        GoSocketClusterClientDisconnect()
    }
}
