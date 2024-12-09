import SwiftUI

struct Usuario: Identifiable, Codable {
    let id: Int
    let name: String
    let tuition: String
    let major: String
    let access_type: String
    let vehicle: String
    let password: String
    let building: String
}

class UserManager: ObservableObject {
    @Published var usuario: Usuario? {
        didSet {
            saveUsuario()
        }
    }
    init() {
        loadUsuario()
    }
    
    func login(usuario: Usuario) {
        self.usuario = usuario
    }
    
    func logout() {
        self.usuario = nil
        UserDefaults.standard.removeObject(forKey: "lastLoggedUser")
    }
    
    private func saveUsuario() {
        guard let usuario = usuario else { return }
        if let encoded = try? JSONEncoder().encode(usuario) {
            UserDefaults.standard.set(encoded, forKey: "lastLoggedUser")
        }
    }
    
    private func loadUsuario() {
        if let savedUserData = UserDefaults.standard.data(forKey: "lastLoggedUser"),
           let savedUsuario = try? JSONDecoder().decode(Usuario.self, from: savedUserData) {
            self.usuario = savedUsuario
        }
    }
}

struct PerfilView: View {
    @EnvironmentObject var userManager: UserManager
    
    @State private var errorMessage: String?
    @State private var showAjustes = false
    @State private var showLoginScreen = false
    
    var body: some View {
        VStack {
            if let usuario = userManager.usuario {
                HStack (alignment: .center){
                    Image("Default")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 90, height: 90)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        .shadow(radius: 15)
                    VStack {
                        Text(usuario.name).bold()
                            .font(.title)
                        Text(usuario.tuition).bold()
                    }.padding(.horizontal, 8)
                }.padding(.vertical, 15)
                Text("Student - \(usuario.major)")
                
                Divider().padding(.horizontal, 16)
                
                DropdownAccesos(tipoAcceso: usuario.access_type)
                
                Divider().padding(.horizontal, 16)
                
                DropdownVehiculos(vehiculo: usuario.vehicle)
                
                Divider().padding(.horizontal, 16)
                
                Button(action: {
                    userManager.logout()
                    showLoginScreen = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.fill.badge.minus")
                            .foregroundColor(.colorTextos)
                        Text("Logout")
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading).bold()
                            .foregroundColor(.colorTextos)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }.padding(.horizontal, 16)
                
                Button(action: {
                    print("")
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle.fill")
                            .foregroundColor(.colorTextos)
                        Text("Help and about us")
                            .font(.system(size: 20))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(.colorTextos).bold()
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }.padding(.horizontal, 16)
            } else {
                if showLoginScreen {
                    AjustesView(errorMessage: $errorMessage, showLoginScreen: $showLoginScreen)
                } else {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.backgroundApp)
        .onAppear {
            if userManager.usuario == nil {
                fetchUsuarioData()
            }
        }
    }
    
    private func fetchUsuarioData() {
        // Cambiar la IP cuando estés en el TEC
        guard let url = URL(string: "http://\(Config.baseURL)/data") else {
            errorMessage = "URL inválida."
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Error al cargar datos: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No se recibieron datos."
                }
                return
            }
            
            do {
                let usuarios = try JSONDecoder().decode([Usuario].self, from: data)
                DispatchQueue.main.async {
                    userManager.usuario = usuarios.first
                }
            } catch {
                DispatchQueue.main.async {
                    print(String(data: data, encoding: .utf8) ?? "Error en datos")
                    errorMessage = "Error al parsear los datos: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}

struct AjustesView: View {
    @EnvironmentObject var userManager: UserManager
    @Binding var errorMessage: String?
    @Binding var showLoginScreen: Bool
    
    @State private var matricula = ""
    @State private var contrasena = ""
    
    var body: some View {
        VStack {
            Text("Iniciar sesión")
                .font(.largeTitle)
                .padding().bold()
            
            TextField("Matrícula", text: $matricula)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            SecureField("Contraseña", text: $contrasena)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button(action: {
                validateLogin()
            }) {
                Text("Iniciar sesión")
                    .foregroundColor(.white)
                    .padding()
                    .background(.buttonColorBlue)
                    .cornerRadius(8)
            }
            .padding()
        }
        .padding()
    }
    
    private func validateLogin() {
        guard let url = URL(string: "http://\(Config.baseURL)/data") else {
            errorMessage = "URL inválida."
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    errorMessage = "Error al cargar datos: \(error.localizedDescription)"
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    errorMessage = "No se recibieron datos."
                }
                return
            }
            
            do {
                let usuarios = try JSONDecoder().decode([Usuario].self, from: data)
                if let foundUser = usuarios.first(where: { $0.tuition == matricula && $0.password == contrasena }) {
                    DispatchQueue.main.async {
                        userManager.login(usuario: foundUser)
                        showLoginScreen = false
                    }
                } else {
                    DispatchQueue.main.async {
                        errorMessage = "Matrícula o contraseña incorrectos. Intenta nuevamente."
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = "Error al parsear los datos: \(error.localizedDescription)"
                }
            }
        }.resume()
    }
}


struct DropdownAccesos: View {
    var tipoAcceso: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Tipo de acceso:")
                        .foregroundColor(.colorTextos)
                        .font(.system(size: 20)).bold()
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.colorTextos)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            if isExpanded {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(tipoAcceso)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .transition(.opacity)
            }
        }
        .padding()
    }
}

struct DropdownVehiculos: View {
    var vehiculo: String
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Button(action: {
                withAnimation {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Text("Vehículo registrado:")
                        .foregroundColor(.colorTextos)
                        .font(.system(size: 20)).bold()
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.colorTextos)
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)
            }
            if isExpanded {
                VStack(alignment: .leading, spacing: 5) {
                    Text("\(vehiculo)")
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .transition(.opacity)
            }
        }
        .padding()
    }
}

#Preview {
    PerfilView()
}
