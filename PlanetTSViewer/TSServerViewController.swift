//
//  TSServerViewController.swift
//  PlanetTSViewer
//
//  Created by Felix on 12/06/15.
//  Copyright © 2015 wz. All rights reserved.
//

import UIKit

class TSServerViewCell: UITableViewCell {
    
    @IBOutlet var indentationConstraint: NSLayoutConstraint?
    @IBOutlet var typeImageView: UIImageView?
    @IBOutlet var iconImageView: UIImageView?
    @IBOutlet var nameLabel: UILabel?
    
    override var indentationLevel: Int {
        didSet {
            if let constaint = indentationConstraint {
                constaint.constant = 18 + CGFloat(indentationLevel) * indentationWidth
                setNeedsLayout()
            }
        }
    }
    
    override var indentationWidth: CGFloat {
        didSet {
            let currentLevel = indentationLevel
            indentationLevel = currentLevel // so the constaint gets updated
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        imageView!.frame.origin.x += CGFloat(indentationLevel) * indentationWidth
    }
}

class TSServerViewController: UITableViewController, TSServerDelegate {

    var server: TSServer? {
        didSet {
            if let actualServer = server where actualServer.delegate == nil {
                actualServer.delegate = self
            }
        }
    }
    
    var activityIndikator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .None
        tableView.scrollEnabled = false
        
        activityIndikator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        if let indikator = activityIndikator {
            indikator.setTranslatesAutoresizingMaskIntoConstraints(false)
        
            tableView.addSubview(indikator)
            tableView.addConstraint(NSLayoutConstraint(item: indikator, attribute: .CenterX, relatedBy: .Equal,
                toItem: tableView, attribute: .CenterX, multiplier: 1, constant: 0))
            tableView.addConstraint(NSLayoutConstraint(item: indikator, attribute: .Top, relatedBy: .Equal,
                toItem: self.topLayoutGuide, attribute: .Top, multiplier: 1, constant: 44))

            indikator.startAnimating()
        }
        
//        let url = NSURL(string: "https://api.planetteamspeak.com/servernodes/82.211.30.15:9987/")!
//        server = TSServer(contentsOfURL: url)
//        server!.delegate = self

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - TSServer delegate
    
    func serverLoaded(server: TSServer) {
        navigationItem.title = server.name
        //tableView.separatorStyle = .SingleLine
        tableView.scrollEnabled = true
        
        if let indikator = activityIndikator {
            indikator.hidden = true
            indikator.stopAnimating()
        }
        
        tableView.reloadData()
    }
    
    func server(server: TSServer, updatedIconForNode node: TSNode) {
        if let row = server.indexOfNode(node) {
            tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: row, inSection: 0)], withRowAnimation: UITableViewRowAnimation.Automatic)
        }
    }
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if self.server != nil {
            return 1
        }
        return 0
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let server = self.server {
            return server.allNodes.count
        }
        return 0
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("tsNode", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...

        return cell
    }

    override func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        let server: TSServer
        if let actualServer = self.server {
            server = actualServer
        }
        else {
            return
        }
        
        let tsNode = server.allNodes[indexPath.row].value
        
        if let tsCell = cell as? TSServerViewCell {
            tsCell.nameLabel!.text = tsNode.name
            tsCell.indentationWidth = 20
            tsCell.indentationLevel = tsNode.indentation - (server.showServerInTree ? 1 : 2)

            if tsNode.spacerType == .None {
                tsCell.typeImageView!.image = UIImage(named: tsNode.imageName)
                tsCell.nameLabel!.textColor = UIColor.darkTextColor()
            }
            else {
                // is spacer
                tsCell.typeImageView!.image = nil
                tsCell.nameLabel!.textColor = UIColor(white: 0.36, alpha: 1)
            }

            if tsNode.type == .Server {
                tsCell.typeImageView!.image = UIImage(named: "server")
            }
            
            if let iconImage = tsNode.iconImage {
                tsCell.iconImageView!.image = iconImage
                tsCell.typeImageView!.alpha = 0.6
            }
            else {
                tsCell.typeImageView!.alpha = 1
                
            }
        }
        
//        cell.textLabel!.text = tsNode.name
//        cell.indentationLevel = tsNode.indentation - (server.showServerInTree ? 1 : 2)
//        cell.indentationWidth = 20
//        
//        if tsNode.spacerType == .None {
//            cell.imageView!.image = UIImage(named: tsNode.imageName)
//            cell.textLabel!.textColor = UIColor.darkTextColor()
//        }
//        else {
//            // is spacer
//            cell.imageView!.image = nil
//            cell.textLabel!.textColor = UIColor(white: 0.36, alpha: 1)
//        }
//
//        if tsNode.type == .Server {
//            cell.imageView!.image = UIImage(named: "server")
//        }
//        
//        if let iconImage = tsNode.iconImage {
//            cell.imageView!.image = iconImage
//        }
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        } else if editingStyle == .Insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return NO if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
