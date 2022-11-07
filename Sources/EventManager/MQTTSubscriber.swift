//
//  MQTTSubscriber.swift
//  
//
//  Created by Berrie Kremers on 02/10/2022.
//

import Foundation
import MQTTNIO
import NIOSSL
import NIOCore

/// A subscriber for MQTT, to simplify handling of incoming events as structured objects.
public class MQTTSubscriber: MQTTConnection {
    /// A generic handler block that subscribers use to process subscribed events.
    /// Parameters are the event name and a decodable object.
    public typealias EventHandlerObject<T> = ((_ name: String, _ object: T)->())

    /// Initiatilize a subscriber, and immediately subscribe to a topic on a specific MQTT broker.
    /// This call is strongly typed, it will attempt to deserialize a JSON object into the type passed in.
    /// In case deserialization fails, an error will be logged, but the subscriber is not separately notified of the failure.
    ///
    /// - Parameters:
    ///   - connectionInfo: The connection parameters for the connection.
    ///   - topic: The topic to subscribe to.
    ///   - qos: The quality of service to use, default is atLeastOnce.
    ///   - handler: A handler block that takes a codable object as parameter.
    public init<T: Decodable>(_ connectionInfo: MQTTConnectionInfo, topic: String, qos: MQTTQoS = .atLeastOnce, handler: @escaping EventHandlerObject<T>) {
        super.init(connectionInfo)

        mqttClient.connect().whenComplete { result in
            switch result {
            case .success:
                print("Succesfully connected")
                self.subscribe(topic: topic, qos: qos, handler: handler)
            case .failure(let error):
                print("Error while connecting \(error)")
            }
        }
    }

    /// Subscribe to a topic on a connected MQTT broker.
    /// This call is strongly typed, it will attempt to deserialize a JSON object into the type passed in.
    /// In case deserialization fails, an error will be logged, but the subscriber is not separately notified of the failure.
    ///
    /// - Parameters:
    ///   - topic: The topic to subscribe to.
    ///   - qos: The quality of service to use, default is atLeastOnce.
    ///   - handler: A handler block that takes a codable object as parameter.
    private func subscribe<T: Decodable>(topic: String, qos: MQTTQoS = .atLeastOnce, handler: @escaping EventHandlerObject<T>) {
        let subscription = MQTTSubscribeInfo(topicFilter: topic, qos: .atLeastOnce)
        mqttClient.subscribe(to: [subscription]).whenComplete { result in
            print("Subscription completed \(result)")
        }

        mqttClient.addPublishListener(named: topic) { result in
            switch result {
            case .success(let publish):
                let buffer = publish.payload
                let topic = publish.topicName
                
                do {
                    if let object = try buffer.getJSONDecodable(T.self, at: 0, length: buffer.readableBytes) {
                        handler(topic, object)
                    }
                } catch let DecodingError.dataCorrupted(context) {
                    NotificationEventManager.shared.publish("Error", sender: "EventManager", object: Log(message: "Handler for \(topic)", context: context.debugDescription, input: buffer.getString(at: 0, length:buffer.readableBytes) ?? ""))
                } catch let DecodingError.keyNotFound(key, context) {
                    NotificationEventManager.shared.publish("Error", sender: "EventManager", object: Log(message: "Handler for \(topic): Key '\(key)' not found", context: "\(context.codingPath)", input: buffer.getString(at: 0, length:buffer.readableBytes) ?? ""))
                } catch let DecodingError.valueNotFound(value, context) {
                    NotificationEventManager.shared.publish("Error", sender: "EventManager", object: Log(message: "Handler for \(topic): Value '\(value)' not found", context: "\(context.codingPath)", input: buffer.getString(at: 0, length:buffer.readableBytes) ?? ""))
                } catch let DecodingError.typeMismatch(type, context)  {
                    NotificationEventManager.shared.publish("Error", sender: "EventManager", object: Log(message: "Handler for \(topic): Type '\(type)' not found", context: "\(context.codingPath)", input: buffer.getString(at: 0, length:buffer.readableBytes) ?? ""))
                } catch {
                    NotificationEventManager.shared.publish("Error", sender: "EventManager", object: Log(message: "Handler for \(topic): error, \(error)", input: buffer.getString(at: 0, length:buffer.readableBytes) ?? ""))
                }
            case .failure(_):
                print("Error while receiving PUBLISH event")
            }
        }
    }
}
