import SwiftUI

struct LoginView: View {
    @State private var username = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Planify")
                .font(.system(size: 24, weight: .bold))
                .padding(.top, 20)
            
            Text("Log in to your account")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            CustomTextField(placeholder: "Username", text: $username, imageName: "person")
            CustomTextField(placeholder: "Password", text: $password, imageName: "lock", isSecure: true)
            
            Button(action: performLogin) {
                Text("Log In")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Spacer(minLength: 20)
            
            HStack {
                Text("No account?")
                Button("Sign up") {
                    // Sign up action
                }
            }
            .font(.caption)
        }
        .padding(20)
        .frame(width: 300, height: 400)
        .background(Color(.windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
        func performLogin() {
        guard let url = URL(string: "http://localhost:8000/api/login/") else { return }
        
        let body: [String: String] = ["username": username, "password": password]
        let finalBody = try? JSONSerialization.data(withJSONObject: body)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = finalBody
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "Error: \(error.localizedDescription)"
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self.errorMessage = "Invalid response from server"
                    return
                }
                
                if httpResponse.statusCode == 200 {
                    if let data = data, let tokenResponse = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                        UserDefaults.standard.set(tokenResponse.token, forKey: "authToken")
                        appState.isLoggedIn = true
                    } else {
                        self.errorMessage = "Invalid response from server"
                    }
                } else {
                    self.errorMessage = "Login failed. Please check your credentials."
                }
            }
        }.resume()
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let imageName: String
    var isSecure: Bool = false
    @State private var isFocused = false
    
    var body: some View {
        HStack {
            Image(systemName: imageName)
                .foregroundColor(.secondary)
                .frame(width: 20)
                
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture { isFocused = true }
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture { isFocused = true }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Color.blue : Color.gray.opacity(0.5), lineWidth: isFocused ? 2 : 1)
                .background(Color(.controlBackgroundColor).cornerRadius(8))
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .onTapGesture {
            isFocused = true
        }
        .onSubmit {
            isFocused = false
        }
    }
}
