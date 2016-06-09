//
//  SocketCluster.swift
//  ios-sc-demo
//
//  Created by Hemanta Sapkota on 9/06/2016.
//  Copyright © 2016 Hemanta Sapkota. All rights reserved.
//

import Foundation
import SocketClusterClient

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
        } else {
            
        }
    }
    
    func disconnect() {
        GoSocketClusterClientDisconnect()
    }
}
