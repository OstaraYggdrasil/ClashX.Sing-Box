//
//  ClashMetaConfig.swift
//  ClashX Meta

import Foundation
import Cocoa
import SwiftyJSON

class ClashMetaConfig: NSObject {
    static func generateInitConfig(_ callback: @escaping ((JSON?) -> Void)) {
        ApiRequest.findConfigPath(configName: ConfigManager.selectConfigName) {
            guard let path = $0,
                  let data = FileManager.default.contents(atPath: path),
                  var json = try? JSON(data: data) else {
                callback(nil)
                return
            }
            json = updateClashAPI(json)
            json = updateMixedIn(json)
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
}
