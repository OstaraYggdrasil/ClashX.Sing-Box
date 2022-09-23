//
//  ClashVmess.swift
//  Sing-Box

import Foundation

struct ClashVmess: Codable {
    let name: String
    let type: String
    let server: String
    let port: Int
    let uuid: String
    let alterId: Int
    let cipher: String
    
    let network: String?
    let udp: Bool?
    let tls: Bool?
    let servername: String?
    let skipCertVerify: Bool?

    let grpcOpts: GrpcOpts?
    let wsOpts: WsOpts?
    let h2Opts: H2Opts?
    let httpOpts: HttpOpts?
    
    struct GrpcOpts: Codable {
        let grpcServiceName: String?
        enum CodingKeys: String, CodingKey {
            case grpcServiceName = "grpc-service-name"
        }
    }

    struct WsOpts: Codable {
        let path: String?
        let headers: [String: String]?
        let maxEarlyData: Int?
        let earlyDataHeaderName: String?
        enum CodingKeys: String, CodingKey {
            case path, headers,
                 maxEarlyData = "max-early-data",
                 earlyDataHeaderName = "early-data-header-name"
        }
    }

    struct H2Opts: Codable {
        let host: [String]?
        let path: String?
    }

    struct HttpOpts: Codable {
        let method: String?
        let path: [String]?
        let headers: [String: String]?
    }

    enum CodingKeys: String, CodingKey {
        case name, type, server, port, uuid, alterId, cipher, network, udp, tls, servername,
             skipCertVerify = "skip-cert-verify",
             grpcOpts = "grpc-opts",
             wsOpts = "ws-opts",
             h2Opts = "h2-opts",
             httpOpts = "http-opts"
    }
    
    func toSingBox() -> SingBoxVmess {
        let tls: SingBoxVmess.Tls? = {
            guard let tls = self.tls else {
                return nil
            }
            return .init(
                enabled: tls,
                disable_sni: nil,
                server_name: servername,
                insecure: skipCertVerify,
                alpn: nil,
                min_version: nil,
                max_version: nil,
                cipher_suites: nil,
                certificate: nil,
                certificate_path: nil)
        }()
        
        let transport: SingBoxVmess.Transport? = {
            guard var network = self.network else {
                return nil
            }
            if network == "h2" {
                network = "http"
            }
            
            let path = wsOpts?.path ?? h2Opts?.path ?? httpOpts?.path?.first
            
            return .init(
                type: network,
                host: h2Opts?.host,
                path: path,
                method: httpOpts?.method,
                headers: wsOpts?.headers ?? httpOpts?.headers,
                max_early_data: wsOpts?.maxEarlyData,
                early_data_header_name: wsOpts?.earlyDataHeaderName,
                service_name: grpcOpts?.grpcServiceName)
        }()
        
        return .init(
            type: type,
            tag: name,
            server: server,
            server_port: port,
            uuid: uuid,
            alter_id: alterId,
            security: cipher,
            network: nil,
            global_padding: nil,
            authenticated_length: nil,
            packet_encoding: nil,
            tls: self.tls == true ? tls : nil,
            multiplex: nil,
            transport: transport)
    }
}
