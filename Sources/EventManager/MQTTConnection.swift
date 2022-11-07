//
//  MQTTConnection.swift
//  
//
//  Created by Berrie Kremers on 02/10/2022.
//

import Foundation
import MQTTNIO
import NIOSSL
import NIOCore

/// MQTT connection parameters
public struct MQTTConnectionInfo {
    /// The identifier to use when connecting to the MQTT broker
    public let identifier: String
    /// The hostname or ipAddress of the MQTT broker
    public let host: String
    /// The username with which to connect to the MQTT broker
    public let userName: String
    /// The password to authenticate with the MQTT broker
    public let password: String
    /// Optional root certificate to use for a SSL connection
    public let rootCertificate: NIOSSLCertificate?
    /// Optional certificate to use for a SSL connection
    public let certificate: NIOSSLCertificate?
    /// Optional private key to use for a SSL connection
    public let privateKey: NIOSSLPrivateKey?
    
    public init(identifier: String, host: String, userName: String, password: String, rootCertificate: NIOSSLCertificate? = nil, certificate: NIOSSLCertificate? = nil, privateKey: NIOSSLPrivateKey? = nil) {
        self.identifier = identifier
        self.host = host
        self.userName = userName
        self.password = password
        self.rootCertificate = rootCertificate
        self.certificate = certificate
        self.privateKey = privateKey
    }
}

/// A MQTT connection that holds an MQTT connection, that can be used
/// as the base class for both MQTTPublisher and MQTTSubscriber.
public class MQTTConnection {
    internal let mqttClient: MQTTClient

    /// Initialize a MQTT connection. It will not attempt to connect.
    /// - Parameters:
    ///   - connectionInfo: The connection parameters for the connection.
    public init(_ connectionInfo: MQTTConnectionInfo) {
        var configuration: MQTTClient.Configuration!
        
        if let rootCertificate = connectionInfo.rootCertificate,
           let certificate = connectionInfo.certificate,
           let privateKey = connectionInfo.privateKey {
            var tlsConfiguration = TLSConfiguration.makeClientConfiguration()
            tlsConfiguration.privateKey = .privateKey(privateKey)
            tlsConfiguration.trustRoots = .certificates([rootCertificate])
            tlsConfiguration.certificateChain = [.certificate(certificate)]

            configuration = MQTTClient.Configuration(version: .v5_0, userName: connectionInfo.userName, password: connectionInfo.password, useSSL: true, tlsConfiguration: .niossl(tlsConfiguration))
        }
        else {
            configuration = MQTTClient.Configuration(version: .v5_0, userName: connectionInfo.userName, password: connectionInfo.password, useSSL: true)
        }
        
        mqttClient = MQTTClient(
            host: connectionInfo.host,
            identifier: connectionInfo.identifier,
            eventLoopGroupProvider: .createNew,
            configuration: configuration
        )
    }

    /// Upon release, disconnect from the broker.
    deinit {
        try? mqttClient.syncShutdownGracefully()
    }
}
