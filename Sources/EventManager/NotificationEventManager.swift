import Foundation


/// A structured logging struct to log info or error messages.
public struct Log: Codable {
    /// The message to log.
    public let message: String
    /// An optional context to which the message applies.
    public let context: String?
    /// Optional input data (like an incoming JSON message on which an error is reported).
    public let input: String?

    public init(message: String, context: String? = nil, input: String? = nil) {
        self.message = message
        self.context = context
        self.input = input
    }
}

/// An event manager implementation that supports a pub-sub mechanism on Codable objects.
/// The implementation uses NotificationManager internally.
public class NotificationEventManager: ObservableObject {
    /// A generic handler block that subscribers use to process subscribed events.
    /// Parameters are the event name and a decodable object.
    public typealias EventHandlerObject<T> = ((_ name: String, _ object: T)->())
    
    /// A history of events published, to which a SwiftUI view can bind.
    @Published var publishedEvents = [Event]()
    
    /// A shared singleton that can be used to subscribe to events, and publish events.
    public static let shared = NotificationEventManager()
    
    private init() {
    }
    
    /// Publish a codable object as JSON onto the eventing infrastructure.
    /// - Parameters:
    ///   - name: The name of the event that is published. Interested parties can subscribe on this name. There are 2 special event names when object is of type ``Log``:  name = "Error" and name = "Info".
    ///   - sender: The party that is sending the event.
    ///   - object: The codable object to be published. Will be converted to JSON.
    public func publish<T: Codable>(_ name: String, sender: String, object: T) {
        guard let objectData = try? JSONEncoder().encode(object) else { return }
        
        if let json = try? JSONSerialization.jsonObject(with: objectData, options: .mutableContainers) {
           if let prettyPrintedData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) {
               DispatchQueue.main.async {
                   self.publishedEvents.insert(Event(sender: sender, date: Date(), name: name, data: String(decoding: prettyPrintedData, as: UTF8.self)), at: 0)
               }
           }
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: name),
                                        object: nil,
                                        userInfo: ["data": objectData])
        
    }
    
    /// Subscribe to an event by name.
    /// This call is strongly typed, it will attempt to deserialize a JSON object into the type passed in.
    /// In case deserialization fails, an error will be logged, but the subscriber is not separately notified of the failure.
    ///
    /// - Parameters:
    ///   - name: The name of the event to subscribe to.
    ///   - handler: A handler block that takes a codable object as parameter.
    /// - Returns: A token that can be used to unsubscribe.
    public func subscribe<T: Codable>(_ name: String, handler: @escaping EventHandlerObject<T>) -> Any {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: name),
                                               object: nil,
                                               queue: nil) { notification in
            guard let userInfo = notification.userInfo,
                  let data = userInfo["data"] as? Data else { return }
                    
            do {
                let object = try JSONDecoder().decode(T.self, from: data)
                handler(name, object)
            } catch let DecodingError.dataCorrupted(context) {
                self.publish("Error", sender: "EventManager", object: Log(message: "Handler for \(name)", context: context.debugDescription, input: String(decoding: data, as: UTF8.self)))
            } catch let DecodingError.keyNotFound(key, context) {
                self.publish("Error", sender: "EventManager", object: Log(message: "Handler for \(name): Key '\(key)' not found", context: "\(context.codingPath)", input: String(decoding: data, as: UTF8.self)))
            } catch let DecodingError.valueNotFound(value, context) {
                self.publish("Error", sender: "EventManager", object: Log(message: "Handler for \(name): Value '\(value)' not found", context: "\(context.codingPath)", input: String(decoding: data, as: UTF8.self)))
            } catch let DecodingError.typeMismatch(type, context)  {
                self.publish("Error", sender: "EventManager", object: Log(message: "Handler for \(name): Type '\(type)' not found", context: "\(context.codingPath)", input: String(decoding: data, as: UTF8.self)))
            } catch {
                self.publish("Error", sender: "EventManager", object: Log(message: "Handler for \(name): error, \(error)", input: String(decoding: data, as: UTF8.self)))
            }
        }
    }
    
    /// Unsubscribe from an event.
    /// - Parameters:
    ///   - name: the name of the event to unsubscribe from
    ///   - token: the token that was received when subscribing to the event.
    public func unsubscribe(_ name: String, token: Any) {
        NotificationCenter.default.removeObserver(token,
                                                  name: NSNotification.Name(rawValue: name),
                                                  object: nil)
    }
    
    /// Clear the entire history of published events.
    func clearEventHistory() {
        publishedEvents.removeAll()
    }
}
