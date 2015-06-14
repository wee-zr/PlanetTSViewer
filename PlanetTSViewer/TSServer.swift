//
//  TSServer.swift
//  PlanetTSViewer
//
//  Created by Felix on 12/06/15.
//  Copyright © 2015 wz. All rights reserved.
//

import UIKit

protocol TSServerDelegate : class {
    func serverLoaded(server: TSServer)
    func server(server: TSServer, updatedIconForNode node: TSNode)
}

class TSNode : NSObject {
    enum Type {
        case Invalid
        case Server
        case Channel
        case Client
        
        init(string: String) {
            switch string {
            case "server": self = .Server
            case "channel": self = .Channel
            case "client": self = .Client
            default: self = .Invalid
            }
        }
    }
    
    enum SpacerType {
        case None
        case Some
        
        init(string: String) {
            switch string {
            case "none": self = .None
            default: self = .Some
            }
        }
    }
    
    var type: Type = .Invalid
    var children: [TSNode] = []
    var name = "unnamed"
    var identifier = ""
    var indentation = 0
    var imageName = ""
    var iconId = 0
    var iconImage: UIImage?
    weak var parent: TSNode?

    var spacerType: SpacerType = .None
    
    func takeValuesFromJSONObject(json: NSDictionary) {
        if let type = json["class"] as? String {
            self.type = Type(string: type)
        }
        
        if let level = json["level"] as? NSNumber {
            self.indentation = level.integerValue
        }
        
        if let ident = json["ident"] as? String {
            self.identifier = ident
        }
        
        if let image = json["image"] as? String {
           self.imageName = image
        }

        if let name = json["name"] as? String {
            self.name = name
        }
        
        if let props = json["props"] as? NSDictionary {
            if let spacer = props["spacer"] as? String where type == .Channel {
                spacerType = SpacerType(string: spacer)
            }
            
            if let icon = props["icon"] as? NSNumber {
                self.iconId = icon.integerValue
            }
        }
    }
}

class Weak<T: AnyObject> {
    weak var value: T!
    init (_ value: T) {
        self.value = value
    }
}

class TSServer : TSNode {
    
    let showServerInTree = true // true will lead to a retain cycle, because TSServer adds itself to allNodes
    var host: String?
    
    weak var delegate: TSServerDelegate?
    var allNodes: [Weak<TSNode>] = []
    var allIcons = [Int: UIImage]()
    var allIconRequests = [Int: [TSNode]]()
    
    init(contentsOfURL: NSURL) {
        super.init()
        
        let session = NSURLSession.sharedSession()
        let task = session.downloadTaskWithURL(contentsOfURL, completionHandler: handleDownloadTask)
        println("starting download task for url \(contentsOfURL)")
        task.resume()
        
        host = contentsOfURL.path?.lastPathComponent
        println("host is \(host)")
    }
    
    func nodeWithIdentifier(identifier: String) -> TSNode? {
        if self.identifier == identifier {
            return self
        }
        
        for node in allNodes {
            if node.value.identifier == identifier {
                return node.value
            }
        }
        
        return nil
    }
    
    func indexOfNode(node: TSNode) -> Int? {
        for (index: Int, childNode) in enumerate(allNodes) {
            if childNode.value == node {
                return index
            }
        }
        return nil
    }
    
    private func handleDownloadTask(location: NSURL?, response: NSURLResponse?, error: NSError?) {
        if let actualLocation = location {
            println("downlaod task completed")
            
            if let data = NSData(contentsOfURL: actualLocation) {
                println("response size in bytes: \(data.length)")
                if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
                    //println(json)
                    dispatch_async(dispatch_get_main_queue()) { //load the data on the main thread
                        self.loadJSONObject(json)
                    }
                }
                else {
                    println("can't get json data from response. error: \(error)")
                }
            }
        }
        
        if let actualError = error {
            println("download task error \(actualError.code): \(actualError.localizedDescription)")
        }
    }
    
    private func loadJSONObject(json: NSDictionary) {
        let result: NSDictionary
        let data: NSArray
        
        if let actualResult = json["result"] as? NSDictionary {
            result = actualResult
        }
        else {
            println("no result object inside json data")
            return
        }
        
        if let actualData = result["data"] as? NSArray {
            data = actualData
        }
        else {
            println("no data object inside json")
            return
        }
        
        println("json data node count: \(data.count)")
        
        for node in data as! [NSDictionary] {
            let parentIdent: String
            if let parent = node["parent"] as? String {
                parentIdent = parent
            }
            else {
                println("node has no parent")
                continue
            }
            
            let tsNode: TSNode
            
            if let parent = nodeWithIdentifier(parentIdent) {
                tsNode = TSNode()
                parent.children.append(tsNode)
            }
            else {
                if type != .Invalid {
                    println("found node with no parent and root is already initialized")
                    continue
                }
                tsNode = self
            }
            
            tsNode.takeValuesFromJSONObject(node)
            
            if let server = tsNode as? TSServer where server.showServerInTree == false {
                // don't add server itself to the tree
            }
            else {
                allNodes.append(Weak(tsNode))
            }
            
            if tsNode.iconId != 0 {
                requestIconForNode(tsNode)
            }
        }
        
        delegate?.serverLoaded(self)
    }
    
    private func requestIconForNode(node: TSNode) {
        if node.iconId == 0 {
            return
        }
        
        if let image = allIcons[node.iconId] {
            println("image \(node.iconId) already cached")
            setIcon(image, forNode: node)
            return
        }
        
        if var imageRequests = allIconRequests[node.iconId] {
            println("image \(node.iconId) already requesting")
            imageRequests.append(node)
            allIconRequests[node.iconId] = imageRequests
            return
        }
        
        if let host = self.host {
            var url = NSURL(string: "https://api.planetteamspeak.com/servericon/\(host)/?id=\(node.iconId)&img=1")!
            
            // registering this request. currenty this is the only node that wants this iconId
            allIconRequests[node.iconId] = [node]
            
            let session = NSURLSession.sharedSession()
            let task = session.downloadTaskWithURL(url) { (location: NSURL?, response: NSURLResponse?, error: NSError?) in
                if let actualLocation = location {
                    
                    if let data = NSData(contentsOfURL: actualLocation) {
                        if let image = UIImage(data: data) {
                            
                            let biggerImage = image.resize(CGSize(width: 34, height: 34), pixelated: true)
                            
                            dispatch_async(dispatch_get_main_queue()) { //load the data on the main thread
                                println("image \(node.iconId) downloaded")
                                self.allIcons[node.iconId] = biggerImage
                                
                                if let requestingNodes = self.allIconRequests[node.iconId] {
                                    if requestingNodes.count > 1 {
                                        println("- was requested \(requestingNodes.count) times")
                                    }
                                    for requestingNode in requestingNodes {
                                        self.setIcon(biggerImage, forNode: requestingNode)
                                    }
                                    
                                    // request is finished, can be removed
                                    self.allIconRequests[node.iconId] = nil
                                }
                            }
                        }
                        else {
                            println("can't get image \(node.iconId) from response")
                        }
                    }
                }
                
                if let actualError = error {
                    println("download image \(node.iconId) task error \(actualError.code): \(actualError.localizedDescription)")
                }

            }
            
            println("starting download of image \(node.iconId)")
            task.resume()
        }
    }
    
    private func setIcon(icon: UIImage, forNode node: TSNode) {
        node.iconImage = icon
        self.delegate?.server(self, updatedIconForNode: node)
    }
}
