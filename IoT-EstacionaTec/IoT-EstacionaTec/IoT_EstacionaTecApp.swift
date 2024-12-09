//
//  IoT_EstacionaTecApp.swift
//  IoT-EstacionaTec
//
//  Created by Jozef David Hernandez Campos on 05/11/24.
//

import SwiftUI

@main
struct IoT_EstacionaTecApp: App {
    @StateObject var userManager = UserManager()
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(userManager)
        }
    }
}
