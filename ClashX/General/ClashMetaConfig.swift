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

            callback(json)
        }
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
