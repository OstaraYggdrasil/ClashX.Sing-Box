//
//  ClashMetaConfig.swift
//  ClashX Meta

import Foundation
import Cocoa
import SwiftyJSON
import Yams

class ClashMetaConfig: NSObject {
    static func generateInitConfig(_ callback: @escaping ((JSON?) -> Void)) {
        ApiRequest.findConfigPath(configName: ConfigManager.selectConfigName) {
            guard let path = $0,
                  var json = try? JSON(data: RemoteConfigManager.shared.verifyConfigTask.formatConfig(path)) else {
                callback(nil)
                return
            }
            json = updateClashAPI(json)
            json = updateMixedIn(json)
            json = updateSub(json)
            callback(json)
        }
    }

    static func updateClashAPI(_ config: JSON) -> JSON {
        var json = config
        json["experimental"]["clash_api"]["external_ui"].string = {
            guard let htmlPath = Bundle.main.path(forResource: "index", ofType: "html", inDirectory: "dashboard") else {
                return nil
            }
            return URL(fileURLWithPath: htmlPath).deletingLastPathComponent().path
        }()
        if json["experimental"]["clash_api"]["external_controller"].string == nil {
            json["experimental"]["clash_api"]["external_controller"].string = "127.0.0.1:9090"
        }
        if json["experimental"]["clash_api"]["secret"].string == nil {
            json["experimental"]["clash_api"]["secret"] = ""
        }
        return json
    }

    static func updateMixedIn(_ config: JSON) -> JSON {
        var json = config
        let mixeds = json["inbounds"].arrayValue.filter {
            $0["type"].string == "mixed"
        }
        var port = 7890
        if mixeds.count == 0 {
            let obj = JSON([[
                "type": "mixed",
                "tag": "mixed-in",
                "listen": "::",
                "listen_port": port
            ]])
            do {
                try json["inbounds"].merge(with: obj)
            } catch let error {
                print(error)
            }
        } else if let mixed = mixeds.first {
            port = mixed["listen_port"].int ?? -1
        }
        return json
    }

    static func updatePorts(_ config: JSON, usedPorts: String) -> JSON {
        var json = config
        let usedPorts = usedPorts.split(separator: ",").compactMap {
            Int($0)
        }

        var availablePorts = Set(1..<65534)
        availablePorts.subtract(usedPorts)

        func update(_ port: Int?) -> Int? {
            guard let p = port, p != 0 else {
                return port
            }

            if availablePorts.contains(p) {
                availablePorts.remove(p)
                return p
            } else if let p = Set(p..<65534).intersection(availablePorts).min() {
                availablePorts.remove(p)
                return p
            } else {
                return nil
            }
        }

        let externalController = json["experimental"]["clash_api"]["external_controller"].string ?? "127.0.0.1:9090"

        let ecPort: Int = {
            if let port = externalController.components(separatedBy: ":").last,
               let p = Int(port) {
                return p
            } else {
                return 9090
            }
        }()

        json["experimental"]["clash_api"]["external_controller"].string = "127.0.0.1:\(update(ecPort) ?? 9090)"

        return json
    }
    
    static func updateSub(_ config: JSON) -> JSON {
        var json = config
        var names = json["outbounds"].arrayValue.map {
            $0["tag"].stringValue
        }
        let rcm = RemoteConfigManager.shared
        rcm.configs.forEach { conf in
            let path = Paths.localSubConfigPath(for: conf.name)
            guard let data = FileManager.default.contents(atPath: path),
                  let string = String(data: data, encoding: .utf8),
                  RemoteConfigManager.verifyConfig(string: string) == nil else {
                return
            }
            
            func findSelectorIndex(for tag: String) -> Int? {
                outbounds.firstIndex(where: {
                    $0["tag"].stringValue == tag &&
                    $0["type"].stringValue == "selector"
                })
            }
            
            func tagName(_ name: String) -> String {
                var new = name
                if new == "" {
                    new = conf.name
                }
                
                let n = new
                var i = 1
                while names.contains(new) {
                    new = n + "-\(i)"
                    i += 1
                }
                return new
            }
            
            let encoder = JSONEncoder()
            var proxies = RemoteConfigManager.loadProxies(string: string).0.compactMap { proxy -> Data? in
                var sb = proxy.toSingBox()
                sb.tag = tagName(sb.tag)
                return try? encoder.encode(sb)
            }.compactMap {
                try? JSON(data: $0)
            }
            guard proxies.count > 0 else { return }
            
//            let groupName = tagName(conf.name)
            let groupName = conf.name
            let outbounds = json["outbounds"].arrayValue
            
            if let i = findSelectorIndex(for: groupName) {
                let names = proxies.map({ $0["tag"].stringValue })
                json["outbounds"][i]["outbounds"] = .init(names)
            } else {
                proxies.insert([
                    "tag": groupName,
                    "type": "selector",
                    "outbounds": proxies.map({ $0["tag"].stringValue })
                ], at: 0)
            }
            
            proxies.forEach {
                names.append($0["tag"].stringValue)
            }
            
            if let i = findSelectorIndex(for: "PROXY") {
                var names = json["outbounds"][i]["outbounds"].arrayObject as? [String] ?? []
                if !names.contains(groupName) {
                    names.append(groupName)
                }
                json["outbounds"][i]["outbounds"] = .init(names)
            } else {
                proxies.append([
                    "tag": "PROXY",
                    "type": "selector",
                    "outbounds": [groupName]
                ])
            }
            
            try? json.merge(with: [
                "outbounds": proxies
            ])
        }
        
        return json
    }
}
