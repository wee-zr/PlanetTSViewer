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
        }
    }
}

class TSServer : TSNode {
    
    let showServerInTree = true // true will lead to a retain cycle, because TSServer adds itself to allNodes
    
    weak var delegate: TSServerDelegate?
    var allNodes: [TSNode] = []
    
    init(contentsOfURL: NSURL) {
        super.init()
        
        let session = NSURLSession.sharedSession()
        let task = session.downloadTaskWithURL(contentsOfURL, completionHandler: handleDownloadTask)
        println("starting download task for url \(contentsOfURL)")
        task.resume()
    }
    
    func nodeWithIdentifier(identifier: String) -> TSNode? {
        if self.identifier == identifier {
            return self
        }
        
        for node in allNodes {
            if node.identifier == identifier {
                return node
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
                allNodes.append(tsNode)
            }
            
            
        }
        
        delegate?.serverLoaded(self)
    }
    
}
