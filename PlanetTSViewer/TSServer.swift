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
    
    var type: Type = .Invalid
    var children: [TSNode] = []
    var name = "unnamed"
    var identifier = ""
    var indentation = 0
    var imageName = ""
    weak var parent: TSNode?
}

class TSServer : TSNode {
    
    weak var delegate: TSServerDelegate?
    var allNodes: [TSNode] = []
    
    var root: TSNode? {
        return nodeWithIdentifier("ts3_s1")
    }
    
    init(contentsOfURL: NSURL) {
        super.init()
        type = .Server
        
        let session = NSURLSession.sharedSession()
        if let task = session.downloadTaskWithURL(contentsOfURL, completionHandler: handleDownloadTask) {
            print("starting download task for url \(contentsOfURL)")
            task.resume()
        }
        else {
            print("can't create download task for url \(contentsOfURL)")
        }
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
            print("downlaod task completed")
            
            if let data = NSData(contentsOfURL: actualLocation) {
                print("response size in bytes: \(data.length)")
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers) as! NSDictionary
                    dispatch_async(dispatch_get_main_queue()) { //load the data on the main thread
                        self.loadJSONObject(json)
                    }
                } catch {
                    print("can't get json data from response. error: \(error)")
                }
            }
        }
        
        if let actualError = error {
            print("download task error \(actualError.code): \(actualError.localizedDescription)")
        }
    }
    
    private func loadJSONObject(json: NSDictionary) {
        guard let result = json["result"] as? NSDictionary else {
            print("no result object inside json data")
            return
        }
        
        guard let data = result["data"] as? NSArray else {
            print("no data object inside json")
            return
        }
        
        print("json data node count: \(data.count)")
        
        for node in data as! [NSDictionary] {
            //var ident = node["ident"]
            guard let typeString = node["class"] as? String,
                let level = node["level"] as? NSNumber,
                let ident = node["ident"] as? String,
                let parentIdent = node["parent"] as? String,
                let imageName = node["image"] as? String else {
                    print("node data is not complete")
                    print("data is: \(node)")
                    return
            }
            
            let tsNode = TSNode()
            tsNode.type = Type(string: typeString)
            tsNode.identifier = ident
            tsNode.indentation = level.integerValue
            tsNode.imageName = imageName
            
            if let name = node["name"] as? String {
                tsNode.name = name
            }
            
            allNodes.append(tsNode)
            
            if let parent = nodeWithIdentifier(parentIdent) {
                parent.children.append(tsNode)
            }
            else {
                if parentIdent == "ts3" {
                    print("found root")
                }
                else {
                    print("can't find parent with identifier \(parentIdent)")
                }
            }
        }
        
        delegate?.serverLoaded(self)
    }
    
}
