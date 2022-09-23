//
//  SingBoxVmess.swift
//  Sing-Box

import Foundation

struct SingBoxVmess: Codable {
    let type: String
    var tag: String
    let server: String
    let server_port: Int
    let uuid: String
    let alter_id: Int
    let security: String
    
    
    let network: String?
    let global_padding: Bool?
    let authenticated_length: Bool?
    let packet_encoding: String?
    let tls: Tls?
    let multiplex: Multiplex?
    let transport: Transport?
    
    struct Tls: Codable {
        let enabled: Bool
        let disable_sni: Bool?
        let server_name: String?
        let insecure: Bool?
        let alpn: [String]?
        let min_version: String?
        let max_version: String?
        let cipher_suites: [String]?
        let certificate: String?
        let certificate_path: String?
    }
    
    struct Multiplex: Codable {
        let enabled: Bool
        let `protocol`: String?
        let max_connections: Int?
        let min_streams: Int?
        let max_streams: Int?
    }
    
    struct Transport: Codable {
        let type: String
        let host: [String]?
        let path: String?
        let method: String?
        let headers: [String: String]?

        let max_early_data: Int?
        let early_data_header_name: String?
        let service_name: String?
    }
}
