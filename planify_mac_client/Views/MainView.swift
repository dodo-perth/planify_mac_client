import SwiftUI

struct MainView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var viewModel: ContentViewModel
    
    var body: some View {
        ZStack {
            VStack(spacing: 20) {
                Button("Start Area Selection") {
                    viewModel.startAreaSelection()
                }
                
                if viewModel.isProcessing {
                    ProgressView("Processing...")
                }
                
                if let image = viewModel.processedImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 200)
                }
                
                if !viewModel.processedText.isEmpty {
                    Text("Recognized Text:")
                        .font(.headline)
                    Text(viewModel.processedText)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
                
                if let apiResponse = viewModel.apiResponse {
                    Text("API Response:")
                        .font(.headline)
                    Text(String(describing: apiResponse))
                        .padding()
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                }
                
                Button("Logout") {
                    performLogout()
                }
            }
            .padding()
            
            if viewModel.isSelectingArea {
                ScreenshotSelectionView(
                    selectionRect: $viewModel.selectionRect,
                    isDragging: $viewModel.isDragging,
                    showScreenshotSelection: $viewModel.isSelectingArea,
                    onCapture: {
                        viewModel.takeScreenshot(.area)
                        viewModel.isSelectingArea = false
                    }
                )
            }
        }
        .sheet(isPresented: $viewModel.showPlanForm) {
            if let apiResponse = viewModel.apiResponse {
                PlanFormView(
                    screenshot: viewModel.processedImage,
                    apiResponse: apiResponse,
                    isLoading: viewModel.isLoadingAPIResponse
                )
            }
        }
        .onChange(of: viewModel.processedImage) { _, newValue in
            if let image = newValue {
                viewModel.performOCR(on: image)
            }
        }
    }
    
    func performLogout() {
        guard let token = UserDefaults.standard.string(forKey: "authToken") else {
            appState.isLoggedIn = false
            return
        }
        
        APIService.shared.logout(token: token) { success in
            DispatchQueue.main.async {
                if success {
                    UserDefaults.standard.removeObject(forKey: "authToken")
                    appState.isLoggedIn = false
                } else {
                    // Handle logout failure
                    print("Logout failed")
                }
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView(viewModel: ContentViewModel())
            .environmentObject(AppState())
    }
}
