//
//  ServerBrowser.swift
//  PlanetTSViewer
//
//  Created by Felix on 14/06/15.
//  Copyright (c) 2015 wz. All rights reserved.
//

import Foundation

protocol ServerBrowserDelegate : class {
    func serverBrowserLoadedServers(_ serverBrowser: ServerBrowser)
}

class ServerInfo : NSObject {
    
    enum Membership: Int {
        case basic = 0
        case member
        case premium
        
        init(value: Int) {
            if value >= Membership.basic.rawValue && value <= Membership.premium.rawValue {
                self = Membership(rawValue: value)!
            }
            else {
                self = .basic
            }
        }
    }
    
    var address: String = ""
    var country: String = ""
    var name: String = ""
    var membership: Membership = .basic
    var slots: Int = 0
    var users: Int = 0
    var createChannels: Bool = false
    var online: Bool = false
    var password: Bool = false
    
    func takeValuesFromJSONObject(_ json: NSDictionary) {
        
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
            self.membership = Membership(value: membership.intValue)
        }
        
        if let slots = json["slots"] as? NSNumber {
            self.slots = slots.intValue
        }
        
        if let users = json["users"] as? NSNumber {
            self.users = users.intValue
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
        let url = URL(string: "https://api.planetteamspeak.com/serverlist/?limit=10")!
        
        let session = URLSession.shared
        let task = session.downloadTask(with: url, completionHandler: handleDownloadTask)
        print("starting download task  for server list \(url)")
        task.resume()

    }
    
    fileprivate func handleDownloadTask(_ location: URL?, _ response: URLResponse?, _ error: Error?) {
        guard let actualLocation = location else {
            if let actualError = error {
                print("download task error \(actualError._code): \(actualError.localizedDescription)")
            }
            return
        }

        print("downlaod server list task completed")
            
        if let data = try? Data(contentsOf: actualLocation) {
            print("response size in bytes: \(data.count)")
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! NSDictionary
                DispatchQueue.main.async { //load the data on the main thread
                    if let newServers = self.loadJSONObject(json) {
                        DispatchQueue.main.async { //load the data on the main thread
                            self.servers = newServers
                            self.delegate?.serverBrowserLoadedServers(self)
                        }
                    }
                    else {
                        print("can't load servers from json")
                    }
                }
            } catch {
                print("can't get json data from response. error: \(error)")
            }

        }
    }
    
    fileprivate func loadJSONObject(_ json: NSDictionary) -> [ServerInfo]? {
        let result: NSDictionary
        let data: NSArray
        
        if let actualResult = json["result"] as? NSDictionary {
            result = actualResult
        }
        else {
            print("no result object inside json data")
            return nil
        }
        
        if let actualData = result["data"] as? NSArray {
            data = actualData
        }
        else {
            print("no data object inside json")
            return nil
        }
        
        print("json data node count: \(data.count)")
        
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
//                print("node has no parent")
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
//                    print("found node with no parent and root is already initialized")
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
