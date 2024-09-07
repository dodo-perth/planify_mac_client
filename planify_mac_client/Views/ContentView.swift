import SwiftUI
import Vision
import ScreenCaptureKit
import UserNotifications

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var viewModel = ContentViewModel()

    var body: some View {
    Group {
        if appState.isLoggedIn {
            MainView(viewModel: viewModel)
        } else {
            LoginView()
        }
    }
    .animation(.default, value: appState.isLoggedIn)
    .onAppear(perform: setup)
}
    
    func setup() {
        requestNotificationPermission()
        validateToken()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    func validateToken() {
        print("Starting token validation")
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            print("Token not found")
            appState.isLoggedIn = false
            return
        }
        
        APIService.shared.validateToken(token) { isValid in
            DispatchQueue.main.async {
                if isValid {
                    print("Token is valid, setting isLoggedIn to true")
                    self.appState.isLoggedIn = true
                } else {
                    print("Token is invalid or expired")
                    self.appState.isLoggedIn = false
                    UserDefaults.standard.removeObject(forKey: "authToken")
                }
            }
        }
    }
}
