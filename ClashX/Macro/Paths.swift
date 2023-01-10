//
//  Paths.swift
//  ClashX
//
//  Created by CYC on 2018/8/26.
//  Copyright © 2018年 west2online. All rights reserved.
//
import Foundation

let kConfigFolderPath = "\(NSHomeDirectory())/.config/sing-box/"

let kDefaultConfigFilePath = "\(kConfigFolderPath)config.json"

let kDefauleMetaCoreName = "com.SagerNet.sing-box.ProxyConfigHelper.core"

struct Paths {
    static func localConfigPath(for name: String) -> String {
        return "\(kConfigFolderPath)\(configFileName(for: name))"
    }
    
    static func localSubConfigPath(for name: String) -> String {
        return "\(kConfigFolderPath)" + "sub/" + "\(subFileName(for: name))"
    }

    static func configFileName(for name: String) -> String {
        ConfigManager.useYamlConfig ? subFileName(for: name) : "\(name).json"
    }
    
    static func subFileName(for name: String) -> String {
        return "\(name).yaml"
    }

    static func defaultCorePath() -> String? {
        guard var path = Bundle.main.resourcePath else {
            return nil
        }
        path += "/\(kDefauleMetaCoreName)"
        return FileManager.default.fileExists(atPath: path) ? path : nil
    }

    static func defaultCoreGzPath() -> String? {
        Bundle.main.path(forResource: kDefauleMetaCoreName, ofType: "gz")
    }

}
