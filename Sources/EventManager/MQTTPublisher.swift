//
//  MQTTPublisher.swift
//  
//
//  Created by Berrie Kremers on 02/10/2022.
//

import Foundation
import MQTTNIO
import NIOSSL
import NIOCore

/// A publisher for MQTT, to simplify publishing of codable objects.
public class MQTTPublisher: MQTTConnection {
    /// Publish an encodable object as JSON onto a MQTT topic. Will connect to the broker if needed.
    /// - Parameters:
    ///   - topic: The name of the topic to publish the object to.
    ///   - sender: The sender of the object.
    ///   - object: The encodable object to be published. Will be converted to JSON and posted onto the specified topic.
    ///   - qos: The quality of service to use, default is atLeastOnce.
    /// - Throws: an error in case the encoding of the object fails.
    public func publish<T: Encodable>(_ topic: String, sender: String, object: T, qos: MQTTQoS = .atLeastOnce) throws {
        let objectData = try JSONEncoder().encode(object)
        
        if mqttClient.isActive() {
            mqttClient.publish(
                to: topic,
                payload: ByteBuffer(data: objectData),
                qos: qos
            ).whenComplete { result in
                if let json = try? JSONSerialization.jsonObject(with: objectData, options: .mutableContainers) {
                    if let prettyPrintedData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                        DispatchQueue.main.async {
                            NotificationEventManager.shared.publishedEvents.insert(Event(sender: sender, date: Date(), name: topic, data: String(decoding: prettyPrintedData, as: UTF8.self)), at: 0)
                        }
                    }
                }
            }
        }
        else {
            mqttClient.connect().whenComplete { result in
                switch result {
                case .success:
                    print("Succesfully connected")
                    self.mqttClient.publish(
                        to: topic,
                        payload: ByteBuffer(data: objectData),
                        qos: qos
                    ).whenComplete { result in
                        if let json = try? JSONSerialization.jsonObject(with: objectData, options: .mutableContainers) {
                            if let prettyPrintedData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
                                DispatchQueue.main.async {
                                    NotificationEventManager.shared.publishedEvents.insert(Event(sender: sender, date: Date(), name: topic, data: String(decoding: prettyPrintedData, as: UTF8.self)), at: 0)
                                }
                            }
                        }
                    }
                case .failure(let error):
                    print("Error while connecting \(error)")
                }
            }
        }
    }
}
