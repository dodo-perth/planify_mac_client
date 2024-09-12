import SwiftUI

struct Plan: Identifiable {
    let id = UUID()
    var title: String
    var location: String
    var startTime: Date
    var endTime: Date
    var details: String
}

struct PlanFormView: View {
    let screenshot: NSImage?
    let apiResponse: [String: Any]?
    let isLoading: Bool
    @Environment(\.presentationMode) var presentationMode
    
    @State private var plans: [Plan] = []
    @State private var selectedPlan: Plan?
    
    var body: some View {
        HStack(spacing: 0) {
            // List of plans
            VStack {
                Text("Your Plans")
                    .font(.headline)
                    .padding()
                
                if isLoading {
                    ProgressView("Loading...")
                } else {
                    List(plans) { plan in
                        PlanRowView(plan: plan)
                            .onTapGesture {
                                selectedPlan = plan
                            }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .frame(width: 250)
            .background(Color(NSColor.controlBackgroundColor))
            
            // Divider
            Divider()
            
            // Plan edit form
            if let plan = selectedPlan {
                PlanEditView(plan: binding(for: plan))
            } else {
                Text("Select a plan to edit")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 700, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear(perform: updatePlans)
        .onExitCommand {
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func updatePlans() {
        guard let response = apiResponse,
              let extractedInfo = response["extracted_info"] as? [[String: Any]] else { return }
        
        let dateFormatter = ISO8601DateFormatter()
        
        plans = extractedInfo.compactMap { planData -> Plan? in
            guard let title = planData["title"] as? String,
                  let startTimeString = planData["start_time"] as? String,
                  let endTimeString = planData["end_time"] as? String,
                  let startTime = dateFormatter.date(from: startTimeString),
                  let endTime = dateFormatter.date(from: endTimeString) else {
                return nil
            }
            
            return Plan(
                title: title,
                location: planData["location"] as? String ?? "",
                startTime: startTime,
                endTime: endTime,
                details: planData["details"] as? String ?? ""
            )
        }
        
        if !plans.isEmpty {
            selectedPlan = plans[0]
        }
    }
    
    private func binding(for plan: Plan) -> Binding<Plan> {
        guard let index = plans.firstIndex(where: { $0.id == plan.id }) else {
            fatalError("Can't find plan in array")
        }
        return $plans[index]
    }
}

struct PlanRowView: View {
    let plan: Plan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(plan.title)
                .font(.headline)
            Text(plan.startTime, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
}

struct PlanEditView: View {
    @Binding var plan: Plan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Edit Plan")
                .font(.title)
                .padding(.top)
            
            BorderlessTextField(text: $plan.title, placeholder: "Title")
            BorderlessTextField(text: $plan.location, placeholder: "Location")
            
            HStack {
                DatePicker("Start", selection: $plan.startTime, displayedComponents: [.date, .hourAndMinute])
                DatePicker("End", selection: $plan.endTime, displayedComponents: [.date, .hourAndMinute])
            }
            
            VStack(alignment: .leading) {
                Text("Details").font(.caption)
                TextEditor(text: $plan.details)
                    .frame(height: 100)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3), lineWidth: 1))
            }
            
            HStack {
                Button(action: {
                    print("Add to Google Calendar button tapped")
                }) {
                    Label("Add to Google Calendar", systemImage: "calendar.badge.plus")
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                Button(action: {
                    print("Settings button tapped")
                }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct BorderlessTextField: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        TextField(placeholder, text: $text)
            .textFieldStyle(PlainTextFieldStyle())
            .padding(.vertical, 8)
            .background(
                VStack {
                    Spacer()
                    Color.gray.opacity(0.3)
                        .frame(height: 1)
                }
            )
    }
}
