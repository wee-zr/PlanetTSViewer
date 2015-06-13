//
//  ViewController.swift
//  PlanetTSViewer
//
//  Created by Felix on 12/06/15.
//  Copyright © 2015 wz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var serverUrl: NSURL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showPlanetTeamSpeak(sender: AnyObject) {
        serverUrl = NSURL(string: "https://api.planetteamspeak.com/servernodes/82.211.30.15:9987/")
        self.performSegueWithIdentifier("showServerView", sender: self)
    }
    
    @IBAction func showRocketBeans(sender: AnyObject) {
        serverUrl = NSURL(string: "https://api.planetteamspeak.com/servernodes/176.57.130.67:9987")
        self.performSegueWithIdentifier("showServerView", sender: self)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let serverViewController = segue.destinationViewController as? TSServerViewController,
            let url = serverUrl
            where segue.identifier == "showServerView" {
            serverViewController.server = TSServer(contentsOfURL: url)
        }
    }
}
