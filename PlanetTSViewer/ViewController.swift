//
//  ViewController.swift
//  PlanetTSViewer
//
//  Created by Felix on 12/06/15.
//  Copyright © 2015 wz. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var serverUrl: URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showPlanetTeamSpeak(_ sender: AnyObject) {
        serverUrl = URL(string: "https://api.planetteamspeak.com/servernodes/84.200.62.248:9987/")
        self.performSegue(withIdentifier: "showServerView", sender: self)
    }
    
    @IBAction func showRocketBeans(_ sender: AnyObject) {
        serverUrl = URL(string: "https://api.planetteamspeak.com/servernodes/176.57.130.67:9987")
        self.performSegue(withIdentifier: "showServerView", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let serverViewController = segue.destination as? TSServerViewController,
            let url = serverUrl, segue.identifier == "showServerView" {
            serverViewController.server = TSServer(contentsOfURL: url)
        }
    }
}
