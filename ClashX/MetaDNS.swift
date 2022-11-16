//
//  MetaDNS.swift
//  ClashX

import Cocoa

class MetaDNS: NSObject {

    var defaultDNS = "198.18.0.2"
    var savedDNS: [String]?

    func updateTunState(_ isTun: Bool) {
        if isTun {
            if savedDNS == nil {
                let dns = getDNS()
                if dns.count == 1, dns[0] == defaultDNS {
                    savedDNS = []
                } else {
                    savedDNS = dns
                }
            }
            setDNS()
        } else {
            if savedDNS == nil || savedDNS!.count == 0 {
                setDNS([])
            } else if let dns = savedDNS {
                setDNS(dns)
            }
        }
    }

    func getDNS() -> [String] {
        let re = runCommand("/usr/sbin/networksetup", args: [
            "-getdnsservers",
            "\(networkServiceName())"
        ])

        if re.contains("There aren't any DNS Servers") {
            return []
        }

        return re.split(separator: "\n").map(String.init)
    }

    func setDNS(_ dns: [String] = ["198.18.0.2"]) {
        var args = [
            "-setdnsservers",
            "\(networkServiceName())"
        ]
        if dns.count > 0 {
            args.append(contentsOf: dns)
        } else {
            args.append("Empty")
        }
        _ = runCommand("/usr/sbin/networksetup", args: args)
    }

    func networkServiceName() -> String {
        // https://apple.stackexchange.com/a/432170

        runCommand("/bin/bash", args: ["-c", "networksetup -listnetworkserviceorder | awk -v DEV=$(/usr/sbin/scutil --nwi | awk -F': ' '/Network interfaces/ {print $2;exit;}') -F': |,' '$0~ DEV  {print $2;exit;}'"])
    }

    func runCommand(_ path: String, args: [String]) -> String {
        let proc = Process()
        proc.executableURL = .init(fileURLWithPath: path)
        proc.arguments = args
        let pipe = Pipe()
        proc.standardOutput = pipe
        do {
            try proc.run()
        } catch let error {
            Logger.log(error.localizedDescription)
            return ""
        }
        proc.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()

        guard proc.terminationStatus == 0,
              var out = String(data: data, encoding: .utf8) else {
            return ""
        }
        if out.last == "\n" {
            out.removeLast()
        }

        return out
    }
}
