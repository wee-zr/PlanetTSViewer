//
//  ServerBrowser.swift
//  PlanetTSViewer
//
//  Created by Felix on 14/06/15.
//  Copyright (c) 2015 wz. All rights reserved.
//

import Foundation

protocol ServerBrowserDelegate : class {
    func serverBrowserLoadedServers(serverBrowser: ServerBrowser)
}

class ServerInfo : NSObject {
    
    enum Membership: Int {
        case Basic = 0
        case Member
        case Premium
        
        init(value: Int) {
            if value >= Membership.Basic.rawValue && value <= Membership.Premium.rawValue {
                self = Membership(rawValue: value)!
            }
            else {
                self = .Basic
            }
        }
    }
    
    var address: String = ""
    var country: String = ""
    var name: String = ""
    var membership: Membership = .Basic
    var slots: Int = 0
    var users: Int = 0
    var createChannels: Bool = false
    var online: Bool = false
    var password: Bool = false
    
    func takeValuesFromJSONObject(json: NSDictionary) {
        
        if let address = json["address"] as? String {
            self.address = address
        }
        
        if let country = json["country"] as? String {
            self.country = country
        }
        
        if let name = json["name"] as? String {
            self.name = name
        }
        
        if let membership = json["membership"] as? NSNumber {
            self.membership = Membership(value: membership.integerValue)
        }
        
        if let slots = json["slots"] as? NSNumber {
            self.slots = slots.integerValue
        }
        
        if let users = json["users"] as? NSNumber {
            self.users = users.integerValue
        }
        
        if let createChannels = json["createchannels"] as? NSNumber {
            self.createChannels = createChannels.boolValue
        }
        
        if let online = json["online"] as? NSNumber {
            self.online = online.boolValue
        }
        
        if let password = json["password"] as? NSNumber {
            self.password = password.boolValue
        }
    }

}

class ServerBrowser : NSObject {
    
    weak var delegate: ServerBrowserDelegate?
    var servers: [ServerInfo] = []
    
    override init() {
        super.init()
    }
    
    func requestServers() {
        
        //let url = NSURL(string: "https://api.planetteamspeak.com/serverlist/?country=de&limit=100&order=users:desc&userid=1")!
        let url = NSURL(string: "https://api.planetteamspeak.com/serverlist/?limit=10")!
        
        let session = NSURLSession.sharedSession()
        let task = session.downloadTaskWithURL(url, completionHandler: handleDownloadTask)
        println("starting download task  for server list \(url)")
        task.resume()

    }
    
    private func handleDownloadTask(location: NSURL?, response: NSURLResponse?, error: NSError?) {
        if let actualLocation = location {
            println("downlaod server list task completed")
            
            if let data = NSData(contentsOfURL: actualLocation) {
                println("response size in bytes: \(data.length)")
                if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
                    println(json)
                    if let newServers = self.loadJSONObject(json) {
                        dispatch_async(dispatch_get_main_queue()) { //load the data on the main thread
                            self.servers = newServers
                            self.delegate?.serverBrowserLoadedServers(self)
                        }
                    }
                    else {
                        println("can't load servers from json")
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
    
    private func loadJSONObject(json: NSDictionary) -> [ServerInfo]? {
        let result: NSDictionary
        let data: NSArray
        
        if let actualResult = json["result"] as? NSDictionary {
            result = actualResult
        }
        else {
            println("no result object inside json data")
            return nil
        }
        
        if let actualData = result["data"] as? NSArray {
            data = actualData
        }
        else {
            println("no data object inside json")
            return nil
        }
        
        println("json data node count: \(data.count)")
        
        var servers = [ServerInfo]()
        
        for node in data as! [NSDictionary] {
            var serverInfo = ServerInfo()
            serverInfo.takeValuesFromJSONObject(node)
            
            servers.append(serverInfo)
        }
        
        return servers
//
//        for node in data as! [NSDictionary] {
//            let parentIdent: String
//            if let parent = node["parent"] as? String {
//                parentIdent = parent
//            }
//            else {
//                println("node has no parent")
//                continue
//            }
//            
//            let tsNode: TSNode
//            
//            if let parent = nodeWithIdentifier(parentIdent) {
//                tsNode = TSNode()
//                parent.children.append(tsNode)
//            }
//            else {
//                if type != .Invalid {
//                    println("found node with no parent and root is already initialized")
//                    continue
//                }
//                tsNode = self
//            }
//            
//            tsNode.takeValuesFromJSONObject(node)
//            
//            if let server = tsNode as? TSServer where server.showServerInTree == false {
//                // don't add server itself to the tree
//            }
//            else {
//                allNodes.append(Weak(tsNode))
//            }
//            
//            if tsNode.iconId != 0 {
//                requestIconForNode(tsNode)
//            }
//        }
    }

}