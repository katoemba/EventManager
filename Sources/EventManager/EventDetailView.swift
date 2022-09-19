//
//  EventDetailView.swift
//  Inbound
//
//  Created by Berrie Kremers on 08/09/2022.
//

import SwiftUI

struct EventDetailView: View {
    var event: Event
    let dateFormatter: DateFormatter
    
    init(event: Event) {
        self.event = event
        
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'  'HH:mm:ss.SSS"
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Text("Sender")
                        .fontWeight(.bold)
                    Text(event.sender)
                }

                HStack {
                    Text("Name")
                        .fontWeight(.bold)
                    Text(event.name)
                }

                HStack {
                    Text("Date & time")
                        .fontWeight(.bold)

                    Text(event.date, formatter: dateFormatter)
                }
                
                Text("Content")
                    .fontWeight(.bold)
                
                Text(event.data)
                    .font(.custom("Courier", size: 12))
                
                Spacer()
            }
            .padding()
            .navigationTitle(event.name)
            
            Spacer()
        }
    }
}

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        EventDetailView(event: Event(sender: "SomeComponent", date: Date(), name: "Event", data: "{\n  \"count\": 2\n}"))
    }
}

