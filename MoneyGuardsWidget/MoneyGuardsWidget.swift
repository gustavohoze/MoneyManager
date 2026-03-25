import WidgetKit
import SwiftUI
import AppIntents

struct FastCaptureProvider: TimelineProvider {
    func placeholder(in context: Context) -> FastCaptureEntry {
        FastCaptureEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (FastCaptureEntry) -> ()) {
        let entry = FastCaptureEntry(date: Date())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FastCaptureEntry>) -> ()) {
        let entries = [FastCaptureEntry(date: Date())]
        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct FastCaptureEntry: TimelineEntry {
    let date: Date
}

struct FastCaptureWidgetEntryView: View {
    var entry: FastCaptureProvider.Entry

    var body: some View {
        VStack {
            Image(systemName: "plus.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white, .green)
        }
        // Link to the main app with a specific URL scheme or app intent to open AddTransaction directly
        .widgetURL(URL(string: "moneyguard://add-transaction"))
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
}

// NOTE: To use this Widget, add a new Widget Extension target to the project in Xcode, and include this file in that target.
// @main would go here if this file were perfectly isolated in a Widget extension.
struct FastCaptureWidget: Widget {
    let kind: String = "FastCaptureWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FastCaptureProvider()) { entry in
            FastCaptureWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Add")
        .description("Log transactions quickly from your Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryInline])
    }
}

#if canImport(WidgetKit)
import WidgetKit

@available(iOS 18.0, UIApplicationExtension 18.0, *)
struct FastCaptureControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "com.moneyguard.FastCaptureControl"
        ) {
            ControlWidgetButton(action: OpenURLIntent(URL(string: "moneyguard://add-transaction")!)) {
                Label("Log Expense", systemImage: "plus.circle.fill")
            }
        }
        .displayName("Log Expense")
        .description("Quickly add a new financial transaction.")
    }
}
#endif
