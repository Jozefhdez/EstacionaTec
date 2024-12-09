import SwiftUI

struct EscanearView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var userManager: UserManager
    @State private var scannedCode: String?
    @State private var showAlert = false
    @State private var isCorrectPassword = false
    @State private var hasEntered = UserDefaults.standard.bool(forKey: "hasEntered")
    @State private var selectedBuilding: String = UserDefaults.standard.string(forKey: "selectedBuilding") ?? ""
    @State private var showBuildingSelection = false // Controls building selection view
    
    let correctPassword = "contraseñaSuperSecreta"
    let correctExitPassword = "contraseñaSuperSecretaSalida" // JUST EXAMPLES FOR EASIER TESTS
    
    var body: some View {
        VStack {
            if selectedBuilding.isEmpty {
                VStack {
                    Text("Please select a building.")
                        .font(.headline)
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        showBuildingSelection.toggle()
                    }) {
                        Text("Select Building")
                            .frame(maxWidth: 200, maxHeight: 50)
                            .background(.buttonColorBlue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
                .padding()
                .shadow(radius: 5)
                .padding(.bottom, 16)
            }
            
            if scannedCode == nil && (!selectedBuilding.isEmpty || hasEntered) {
                // Show QR scanner only if the user has selected a building
                QRCodeScannerView { code in
                    self.scannedCode = code
                    
                    guard let tuition = userManager.usuario?.tuition else {
                        print("Error: No user tuition found.")
                        return
                    }

                    if !hasEntered {
                        verifyEntryCode(code)
                    } else {
                        verifyExitCode(code, tuition: tuition)
                    }
                }
                .edgesIgnoringSafeArea(.all)
            } else if selectedBuilding.isEmpty && !hasEntered {
                Text("")
                    .foregroundColor(.red)
                    .padding()
            } else {
                ProgressView().progressViewStyle(CircularProgressViewStyle())
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(isCorrectPassword ? "QR read successfully." : "Access denied"),
                  message: Text(isCorrectPassword ? (hasEntered ? "Exit allowed" : "Welcome!") : "The password is incorrect."),
                  dismissButton: .default(Text("OK")) {
                    if isCorrectPassword {
                        if !hasEntered {
                            hasEntered = true
                            UserDefaults.standard.set(true, forKey: "hasEntered") // Save if the user has already entered
                            selectedTab = 0 // Change view to MyPlace
                        } else {
                            hasEntered = false
                            UserDefaults.standard.set(false, forKey: "hasEntered") // Save if the user has already exited
                            resetBuildingSelection()
                        }
                    }
                    scannedCode = nil
                })
        }
        .sheet(isPresented: $showBuildingSelection) {
            BuildingSelectionView(selectedBuilding: $selectedBuilding)
                .onDisappear {
                    UserDefaults.standard.set(selectedBuilding, forKey: "selectedBuilding")
                }
        }
    }
    
    private func verifyEntryCode(_ code: String) {
        isCorrectPassword = (code == correctPassword)
        if isCorrectPassword {
            updateEntryRequest()
        }
        showAlert = true
    }

    private func verifyExitCode(_ code: String, tuition: String) {
        isCorrectPassword = (code == correctExitPassword)
        if isCorrectPassword {
            updateExitAndResetBuilding(tuition: tuition)
            releasePlace()
            deleteAssignedPlace()
        }
        showAlert = true
    }
    
    func deleteAssignedPlace() {
        // Delete assigned place from UserDefaults when the user leaves
        UserDefaults.standard.removeObject(forKey: "assignedPlace")
    }

    private func updateEntryRequest() {
        guard let url = URL(string: "\(Config.baseURL)/set_requested_entry") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating entry:", error)
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Entry updated successfully.")
            } else {
                print("Error updating entry.")
            }
        }.resume()
    }
    
    private func updateExitAndResetBuilding(tuition: String) {
        guard let url = URL(string: "http://\(Config.baseURL)/update_exit_and_reset") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let body: [String: Any] = ["tuition": tuition]
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        } catch {
            print("Error serializing request body: \(error)")
            return
        }

        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error updating exit and resetting building:", error)
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                print("Exit and building updated successfully.")
            } else {
                print("Error updating exit and resetting building.")
            }
        }.resume()
    }
    
    func releasePlace() {
        guard let tuition = userManager.usuario?.tuition else { return }
        guard let url = URL(string: "http://\(Config.baseURL)/release_place") else { return }
        
        let parameters: [String: Any] = ["tuition": tuition]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: [])
        } catch {
            print("Error converting parameters to JSON")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error releasing the place: \(error.localizedDescription)")
            } else {
                print("Place released successfully")
            }
        }.resume()
    }

    private func resetBuildingSelection() {
        selectedBuilding = "" // Reset selected building
        UserDefaults.standard.removeObject(forKey: "selectedBuilding") // Remove selected building from UserDefaults
    }
}
