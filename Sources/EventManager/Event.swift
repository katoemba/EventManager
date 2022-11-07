//
//  File.swift
//  
//
//  Created by Berrie Kremers on 07/11/2022.
//

import Foundation

/// Event types that can be stored. Error and Info are treated as special cases.
enum EventType: String, Codable {
    case event
    case error
    case info
}

/// A structure to maintain published events.
struct Event: Hashable {
    /// The sender of the event
    let sender: String
    /// The timestamp at which the event was received
    let date: Date
    /// The name of the event
    let name: String
    /// The raw json data in the event
    let data: String
}

extension Data {
    /// Print a data object as nicely formatted json.
    func printJson() {
        do {
            let json = try JSONSerialization.jsonObject(with: self, options: [])
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            guard let jsonString = String(data: data, encoding: .utf8) else {
                print("Invalid data")
                return
            }
            print(jsonString)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
