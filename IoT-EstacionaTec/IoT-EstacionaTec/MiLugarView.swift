import SwiftUI

struct MiLugarView: View {
    @State private var selectedBuilding: String = "Building A"
    @State private var assignedPlace: Int? = nil
    @EnvironmentObject var userManager: UserManager

    var body: some View {
        NavigationView {
            VStack {
                Text("EstacionaTec")
                    .bold()
                    .font(.title)
                
                MapView(assignedPlace: $assignedPlace)
                
                Text("My Place")
                    .bold()
                    .font(.title2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                
                Text(assignedPlace != nil ? "Slot \(assignedPlace!)" : "Not assigned")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                Text("")
                Text("")
                Text("")
                Text("")
                Text("")
                Text("")
            }
            .onAppear {
                if UserDefaults.standard.bool(forKey: "hasEntered") {
                    if let savedPlace = UserDefaults.standard.value(forKey: "assignedPlace") as? Int {
                        assignedPlace = savedPlace
                    } else {
                        fetchAssignedPlace() // If no saved place, assign a new one
                    }
                } else {
                    assignedPlace = nil
                }
            }
        }
    }
    
    func fetchAssignedPlace() {
        guard let tuition = userManager.usuario?.tuition else { return }
        guard let url = URL(string: "http://\(Config.baseURL)/assign_place") else { return }
        
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
                print("Error fetching assigned place: \(error.localizedDescription)")
                return
            }
            
            guard let data = data else { return }
            
            do {
                if let result = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let placeId = result["place_id"] as? Int {
                    DispatchQueue.main.async {
                        self.assignedPlace = placeId
                        // Save to UserDefaults
                        UserDefaults.standard.set(placeId, forKey: "assignedPlace")
                    }
                }
            } catch {
                print("Error decoding assigned place: \(error.localizedDescription)")
            }
        }.resume()
    }
}

struct BuildingSelectionView: View {
    @Binding var selectedBuilding: String
    @EnvironmentObject var userManager: UserManager
    @Environment(\.presentationMode) var presentationMode // To close the view when updated
    
    let buildings = ["Building A", "Building B"] // List of buildings
    
    var body: some View {
        VStack {
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")
            Text("")

            Picker("Building", selection: $selectedBuilding) {
                ForEach(buildings, id: \.self) { building in
                    Text(building).tag(building)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            Button("Confirm Selection") {
                updateBuilding()
            }
            .disabled(selectedBuilding.isEmpty)
            .padding()
            .frame(width: 210, height: 50)
            .bold()
            .foregroundColor(.white)
            .background(.buttonColorBlue)
            .cornerRadius(16)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.white)
        .navigationBarTitle("Select Building", displayMode: .inline)
    }
    
    func updateBuilding() {
        guard let tuition = userManager.usuario?.tuition else { return }
        
        // Backend call to update building
        guard let url = URL(string: "http://\(Config.baseURL)/updateBuilding") else { return }
        
        let parameters: [String: Any] = [
            "tuition": tuition,
            "building": selectedBuilding
        ]
        
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
                print("Error updating building: \(error.localizedDescription)")
            } else {
                print("Building updated successfully")
            }
        }.resume()
        
        // Close the view and return to the previous view
        presentationMode.wrappedValue.dismiss()
    }
}

struct MapView: View {
    @Binding var assignedPlace: Int? // Receive assigned place
    @State private var places: [(id: Int, occupied: Bool)] = []
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack {
            ZStack {
                Image("MapImage")
                    .resizable()
                    .frame(width: 360, height: 480)
                    .cornerRadius(16)
                
                // Draw circles within the map
                ForEach(places, id: \.id) { place in
                    Circle()
                        .fill(
                            place.id == assignedPlace ? Color.blue : // Assigned place
                            place.occupied ? Color.red : Color.green // Occupied or available
                        )
                        .frame(width: 20, height: 20)
                        .position(x: 160, y: place.id == 1 ? 440 : place.id == 2 ? 330 : 225)
                }
            }
            .onAppear {
                fetchPlaceStatus()
            }
            .onReceive(timer) { _ in
                fetchPlaceStatus()
            }
        }
    }
    
    func fetchPlaceStatus() {
        guard let url = URL(string: "http://\(Config.baseURL)/get_places") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                print("Error fetching place status: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            do {
                if let status = try JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                    DispatchQueue.main.async {
                        self.places = status.map {
                            (id: $0["place_id"] as? Int ?? 0,
                             occupied: $0["status"] as? Int == 0)
                        }
                    }
                }
            } catch {
                print("Error decoding place status: \(error.localizedDescription)")
            }
        }.resume()
    }
}
