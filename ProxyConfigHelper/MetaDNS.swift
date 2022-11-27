//
//  MetaDNS.swift
//  ClashX



import Cocoa
import SystemConfiguration

// https://github.com/zhuhaow/Specht2/blob/main/app/me.zhuhaow.Specht2.proxy-helper/ProxyHelper.swift

class MetaDNS: NSObject {
    
    var savedDns = [String: [String]]()
    let defaultDNS = "198.18.0.2"
    
    let authRef: AuthorizationRef

    override init() {
        var auth: AuthorizationRef?
        let authFlags: AuthorizationFlags = [.extendRights, .interactionAllowed, .preAuthorize]

        let authErr = AuthorizationCreate(nil, nil, authFlags, &auth)

        if authErr != noErr {
            NSLog("Error: Failed to create administration authorization due to error \(authErr).")
        }

        if auth == nil {
            NSLog("Error: No authorization has been granted to modify network configuration.")
        }

        authRef = auth!

        super.init()
    }

    deinit {
        AuthorizationFree(authRef, AuthorizationFlags())
    }
    
    @objc func updateDns() {
        let dns = getAllDns()
        dns.forEach {
            if $0.value.count == 1,
               $0.value[0] == defaultDNS {
                savedDns[$0.key] = []
            } else {
                savedDns[$0.key] = $0.value
            }
        }
        
        let dnsDic = dns.reduce(into: [:]) {
            $0[$1.key] = [defaultDNS]
        }
        
        updateDNSConfigure(dnsDic)
    }
    
    @objc func revertDns() {
        updateDNSConfigure(savedDns)
        savedDns.removeAll()
    }
    
    func getAllDns() -> [String: [String]] {
        var re = [String: [String]]()
        
        guard let prefs = SCPreferencesCreate(nil, "ClashX" as CFString, nil),
              let values = SCPreferencesGetValue(prefs, kSCPrefNetworkServices) as? [String: AnyObject] else {
            return re
        }
        
        values.reduce(into: [:]) {
            $0[$1.key] = $1.value.value(forKeyPath: "Interface.Hardware") as? String
        }.filter {
            ["AirPort", "Wi-Fi", "Ethernet"].contains($0.value)
        }.forEach {
            re[$0.key] = DNSConfiguration.getDNSForServiceID($0.key)
        }
        
        return re
    }
    
    @objc func flushDnsCache() {
        CommonUtils.runCommand("/usr/bin/killall", args: ["-HUP", "mDNSResponder"])
        
        print("flushDnsCache")
    }

    private func updateDNSConfigure(_ dnsDic: [String: [String]]) {

        guard let prefRef = SCPreferencesCreateWithAuthorization(
            nil,
            "com.metacubex.ClashX.ProxyConfigHelper.config" as CFString,
            nil,
            authRef) else {
            NSLog("Error: Failed to obtain preference ref.")
            return
        }

        guard SCPreferencesLock(prefRef, true) else {
            NSLog("Error: Failed to obtain lock to preference.")
            return
        }

        defer {
            SCPreferencesUnlock(prefRef)
        }

        guard let networks = SCNetworkSetCopyCurrent(prefRef),
              let services = SCNetworkSetCopyServices(networks) as? [SCNetworkService] else {
            NSLog("Error: Failed to load network services.")
            return
        }
        
        let type = kSCNetworkProtocolTypeDNS

        services.forEach { service in
            guard let id = SCNetworkServiceGetServiceID(service) as? String,
                  let dns = dnsDic[id] else {
                return
            }
            
            
            guard let protoc = SCNetworkServiceCopyProtocol(service, type) else {
                NSLog("Error: Failed to obtain \(type) settings for \(SCNetworkServiceGetName(service)!)")
                return
            }

            let config = SCNetworkProtocolGetConfiguration(protoc)

            var dic = (config as NSDictionary?)?.mutableCopy() as? NSMutableDictionary ?? NSMutableDictionary()
            
            dic["ServerAddresses"] = dns

            guard SCNetworkProtocolSetConfiguration(protoc, dic as CFDictionary) else {
                NSLog("Error: Failed to set \(type) settings for \(SCNetworkServiceGetName(service)!)")
                return
            }

            NSLog("Set \(type) settings for \(SCNetworkServiceGetName(service)!)")
        }


        guard SCPreferencesCommitChanges(prefRef) else {
            NSLog("Error: Failed to commit preference change")
            return
        }

        guard SCPreferencesApplyChanges(prefRef) else {
            NSLog("Error: Failed to apply preference change")
            return
        }
    }
}
