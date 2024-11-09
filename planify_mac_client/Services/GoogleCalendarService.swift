import Foundation
import GoogleAPIClientForREST_Calendar
import GoogleSignIn
import AppKit

class GoogleCalendarService {
    static let shared = GoogleCalendarService()
    private let clientID = "YOUR_CLIENT_ID.apps.googleusercontent.com"  // 여기에 실제 클라이언트 ID 입력
    private let service = GTLRCalendarService()
    
    private let scopes = [
        "https://www.googleapis.com/auth/calendar",
        "https://www.googleapis.com/auth/calendar.events"
    ]
    
    private init() {
        setupGoogleSignIn()
    }
    
    private func setupGoogleSignIn() {
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: clientID,
            serverClientID: nil,
            serverClientSecret: nil,
            openIDRealm: nil,
            hostedDomain: nil,
            additionalScopes: scopes
        )
    }
    
    func signIn() async throws -> GIDGoogleUser {
        guard let windowScene = NSApplication.shared.windows.first else {
            throw NSError(domain: "GoogleCalendarError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No window scene found"])
        }
        
        return try await GIDSignIn.sharedInstance.signIn(withPresenting: windowScene)
    }
    
    func addEventToCalendar(plan: Plan) async throws -> GTLRCalendar_Event {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw NSError(domain: "GoogleCalendarError", code: 2, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
        }
        
        let event = GTLRCalendar_Event()
        event.summary = plan.title
        event.location = plan.location
        event.descriptionProperty = plan.details
        
        let startDateTime = GTLRDateTime(date: plan.startTime)
        let endDateTime = GTLRDateTime(date: plan.endTime)
        
        let startEventDateTime = GTLRCalendar_EventDateTime()
        startEventDateTime.dateTime = startDateTime
        event.start = startEventDateTime
        
        let endEventDateTime = GTLRCalendar_EventDateTime()
        endEventDateTime.dateTime = endDateTime
        event.end = endEventDateTime
        
        let query = GTLRCalendarQuery_EventsInsert.query(withObject: event, calendarId: "primary")
        service.authorizer = user.authentication.fetcherAuthorizer()
        
        return try await withCheckedThrowingContinuation { continuation in
            service.executeQuery(query) { (ticket, event, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let event = event as? GTLRCalendar_Event {
                    continuation.resume(returning: event)
                } else {
                    continuation.resume(throwing: NSError(domain: "GoogleCalendarError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create event"]))
                }
            }
        }
    }
} 