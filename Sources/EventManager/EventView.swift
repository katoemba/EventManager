//
//  EventView.swift
//  Inbound
//
//  Created by Berrie Kremers on 08/09/2022.
//

import SwiftUI

/// A (Navigation)View to inspect the history of published events and log messages.
public struct EventView: View {
    enum EventType {
        case event
        case info
        case error
    }
    
    @ObservedObject var eventManager = NotificationEventManager.shared
    /// The event type to list on.
    @State var filter = EventType.event
    
    public init() {
    }
    
    public var body: some View {
        VStack {
            Picker("", selection: $filter) {
                Text("Events").tag(EventType.event)
                Text("Errors").tag(EventType.error)
                Text("Infos").tag(EventType.info)
            }
            .padding()
            .pickerStyle(.segmented)
            
            List {
                ForEach(eventManager.publishedEvents.filter( {
                    switch filter {
                    case .error: return $0.name == "Error"
                    case .info: return $0.name == "Log"
                    default: return $0.name != "Log" && $0.name != "Error"
                    }
                }), id: \.self) { event in
                    NavigationLink(destination: EventDetailView(event: event)) {
                        HStack {
                            Image(systemName: event.name == "Log" ? "info.circle" : (event.name == "Error" ? "exclamationmark.shield" : "bolt"))
                                .foregroundColor(.accentColor)
                            
                            VStack(alignment: .leading) {
                                Text(event.sender)
                                    .font(.headline)
                                Text(event.name)
                                    .font(.body)
                            }
                        }
                    }
                }
            }
        }
        #if os(macOS)
        .frame(width: 300)
        #endif
        .navigationTitle("Events")
    }
}

struct EventView_Previews: PreviewProvider {
    static var previews: some View {
        EventView()
    }
}
