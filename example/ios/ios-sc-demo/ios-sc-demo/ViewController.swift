//
//  ViewController.swift
//  ios-sc-demo
//
//  Created by Hemanta Sapkota on 9/06/2016.
//  Copyright © 2016 Hemanta Sapkota. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var sClient = SocketClusterProxy()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onConnect() {
        sClient.connect()
    }
    
    @IBAction func onDisconnect() {
        sClient.disconnect()
    }

}

