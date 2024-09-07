import SwiftUI

struct PlanFormView: View {
    let screenshot: NSImage?
    let apiResponse: [String: Any]?
    let isLoading: Bool
    
    @State private var title: String = ""
    @State private var location: String = ""
    @State private var startTime: Date = Date()
    @State private var endTime: Date = Date()
    @State private var details: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Plan Form")
                .font(.title)
            
            if isLoading {
                ProgressView("Loading...")
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Title: \(title)")
                    Text("Location: \(location)")
                    Text("Start Time: \(startTime, formatter: dateFormatter)")
                    Text("End Time: \(endTime, formatter: dateFormatter)")
                    Text("Details: \(details)")
                }
            }
            
            HStack {
                Button("Save") {
                    // Implement save functionality
                }
                
                Button("Cancel") {
                    NSApp.keyWindow?.close()
                }
            }
        }
        .padding()
        .frame(width: 400, height: 500)
        .background(Color(.windowBackgroundColor))
        .onAppear(perform: updateForm)
    }
    
    private func updateForm() {
        guard let response = apiResponse else { return }
        
        title = response["title"] as? String ?? ""
        location = response["location"] as? String ?? ""
        details = response["details"] as? String ?? ""
        
        let dateFormatter = ISO8601DateFormatter()
        if let startTimeString = response["start_time"] as? String,
           let start = dateFormatter.date(from: startTimeString) {
            startTime = start
        }
        if let endTimeString = response["end_time"] as? String,
           let end = dateFormatter.date(from: endTimeString) {
            endTime = end
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }
}
