//
//  TSServer.swift
//  PlanetTSViewer
//
//  Created by Felix on 12/06/15.
//  Copyright © 2015 wz. All rights reserved.
//

import UIKit

protocol TSServerDelegate : class {
    func serverLoaded(_ server: TSServer)
    func server(_ server: TSServer, updatedIconForNode node: TSNode)
}

class TSNode : NSObject {
    enum `Type` {
        case invalid
        case server
        case channel
        case client
        
        init(string: String) {
            switch string {
            case "server": self = .server
            case "channel": self = .channel
            case "client": self = .client
            default: self = .invalid
            }
        }
    }
    
    enum SpacerType {
        case none
        case some
        
        init(string: String) {
            switch string {
            case "none": self = .none
            default: self = .some
            }
        }
    }
    
    var type: Type = .invalid
    var children: [TSNode] = []
    var name = "unnamed"
    var identifier = ""
    var indentation = 0
    var imageName = ""
    var iconId = 0
    var iconImage: UIImage?
    weak var parent: TSNode?

    var spacerType: SpacerType = .none
    
    func takeValuesFromJSONObject(_ json: NSDictionary) {
        if let type = json["class"] as? String {
            self.type = Type(string: type)
        }
        
        if let level = json["level"] as? NSNumber {
            self.indentation = level.intValue
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
            if let spacer = props["spacer"] as? String, type == .channel {
                spacerType = SpacerType(string: spacer)
            }
            
            if let icon = props["icon"] as? NSNumber {
                self.iconId = icon.intValue
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
    
    init(contentsOfURL: URL) {
        super.init()
        
        let session = URLSession.shared
        let task = session.downloadTask(with: contentsOfURL, completionHandler: handleDownloadTask)
        print("starting download task for url \(contentsOfURL)")
        task.resume()
        
        host = contentsOfURL.lastPathComponent
        print("host is \(host)")
    }
    
    func nodeWithIdentifier(_ identifier: String) -> TSNode? {
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
    
    func indexOfNode(_ node: TSNode) -> Int? {
        for (index, childNode) in allNodes.enumerated() {
            if childNode.value == node {
                return index
            }
        }
        return nil
    }
    
    fileprivate func handleDownloadTask(_ location: URL?, _ response: URLResponse?, _ error: Error?) {
        if let actualLocation = location {
            print("downlaod task completed")
            
            if let data = NSData(contentsOf: actualLocation) {
                print("response size in bytes: \(data.length)")
                do {
                    let json = try JSONSerialization.jsonObject(with: data as Data, options: .mutableContainers) as! NSDictionary
                    DispatchQueue.main.async { //load the data on the main thread
                        self.loadJSONObject(json)
                    }
                } catch {
                    print("can't get json data from response. error: \(error)")
                }
            }

        }
        
        if let actualError = error {
            print("download task error \(actualError.localizedDescription)")
        }
    }
    
    fileprivate func loadJSONObject(_ json: NSDictionary) {
        let result: NSDictionary
        let data: NSArray
        
        if let actualResult = json["result"] as? NSDictionary {
            result = actualResult
        }
        else {
            print("no result object inside json data")
            return
        }
        
        if let actualData = result["data"] as? NSArray {
            data = actualData
        }
        else {
            print("no data object inside json")
            return
        }
        
        print("json data node count: \(data.count)")
        
        for node in data as! [NSDictionary] {
            let parentIdent: String
            if let parent = node["parent"] as? String {
                parentIdent = parent
            }
            else {
                print("node has no parent")
                continue
            }
            
            let tsNode: TSNode
            
            if let parent = nodeWithIdentifier(parentIdent) {
                tsNode = TSNode()
                parent.children.append(tsNode)
            }
            else {
                if type != .invalid {
                    print("found node with no parent and root is already initialized")
                    continue
                }
                tsNode = self
            }
            
            tsNode.takeValuesFromJSONObject(node)
            
            if let server = tsNode as? TSServer, server.showServerInTree == false {
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
    
    fileprivate func requestIconForNode(_ node: TSNode) {
        if node.iconId == 0 {
            return
        }
        
        if let image = allIcons[node.iconId] {
            print("image \(node.iconId) already cached")
            setIcon(image, forNode: node)
            return
        }
        
        if var imageRequests = allIconRequests[node.iconId] {
            print("image \(node.iconId) already requesting")
            imageRequests.append(node)
            allIconRequests[node.iconId] = imageRequests
            return
        }
        
        if let host = self.host {
            var url = URL(string: "https://api.planetteamspeak.com/servericon/\(host)/?id=\(node.iconId)&img=1")!
            
            // registering this request. currenty this is the only node that wants this iconId
            allIconRequests[node.iconId] = [node]
            
            let session = URLSession.shared
            let task = session.downloadTask(with: url, completionHandler: { (_ location: URL?, _ response: URLResponse?, _ error: Error?) in
                if let actualLocation = location {
                    
                    if let data = try? Data(contentsOf: actualLocation) {
                        if let image = UIImage(data: data) {
                            
                            let biggerImage = image.resize(CGSize(width: 34, height: 34), pixelated: true)
                            
                            DispatchQueue.main.async { //load the data on the main thread
                                print("image \(node.iconId) downloaded")
                                self.allIcons[node.iconId] = biggerImage
                                
                                if let requestingNodes = self.allIconRequests[node.iconId] {
                                    if requestingNodes.count > 1 {
                                        print("- was requested \(requestingNodes.count) times")
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
                            print("can't get image \(node.iconId) from response")
                        }
                    }
                }
                
                if let actualError = error {
                    print("download image \(node.iconId) task error \(actualError.localizedDescription)")
                }

            })
            
            print("starting download of image \(node.iconId)")
            task.resume()
        }
    }
    
    fileprivate func setIcon(_ icon: UIImage, forNode node: TSNode) {
        node.iconImage = icon
        self.delegate?.server(self, updatedIconForNode: node)
    }
}
