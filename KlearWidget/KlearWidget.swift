//
//  KlearWidget.swift
//  KlearWidget
//
//  Created by Spencer Ward on 02/10/2022.
//  Copyright © 2022 Yorwos Pallikaropoulos. All rights reserved.
//

import WidgetKit
import SwiftUI
import Intents


struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationIntent())
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), configuration: configuration)
        completion(entry)
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []

        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset * 10, to: currentDate)!
            let entry = SimpleEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
}

struct KlearWidgetEntryView : View {
    var entry: Provider.Entry

    private let colors: [UIColor] = [#colorLiteral(red: 0.8509803922, green: 0, blue: 0.0862745098, alpha: 1), #colorLiteral(red: 0.862745098, green: 0.1137254902, blue: 0.09019607843, alpha: 1), #colorLiteral(red: 0.8745098039, green: 0.2274509804, blue: 0.09411764706, alpha: 1), #colorLiteral(red: 0.8862745098, green: 0.3450980392, blue: 0.09803921569, alpha: 1), #colorLiteral(red: 0.8941176471, green: 0.4588235294, blue: 0.1019607843, alpha: 1), #colorLiteral(red: 0.9058823529, green: 0.5725490196, blue: 0.1058823529, alpha: 1), #colorLiteral(red: 1, green: 0.7647058824, blue: 0.2431372549, alpha: 1)]
 
    let mainItems: [Item] = ItemRepo.allIn(moc: CoreDataStack.regularStore().moc!).reversed()

    
    var shape : RoundedRectangle { RoundedRectangle(cornerRadius: 11) }
    
    fileprivate func item(text: String) -> some View {
        return Text(text)
            .foregroundColor(.white)
            .font(.footnote)
            .padding(.leading, 10)
            .padding([.top, .bottom], 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(colors[3]))
            .containerShape(shape)
    }
    
    fileprivate func items() ->  [some View] {
        let count = min(4, mainItems.count)
        let displayItems = (count > 0) ? mainItems[0...count - 1] : []
        return displayItems.map { item(text: $0.title!) }
    }
    
    var body: some View {
        ZStack {
            Color(colors[0])
            ZStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Personal")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .font(.footnote)
                    ForEach(0..<self.items().count) { index in
                        self.items()[index]
                            
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
                .padding(.top, 6)
            }
            .padding(.horizontal, 8.0)
        }
    }
}

@main
struct KlearWidget: Widget {
    let kind: String = "KlearWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            KlearWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
    }
}

struct KlearWidget_Previews: PreviewProvider {
    static var previews: some View {
        KlearWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: ConfigurationIntent()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
