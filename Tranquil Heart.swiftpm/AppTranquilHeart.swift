import SwiftUI

@main
struct MyApp: App {
    @State private var showWelcome = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                HomePage()
                    .zIndex(0)
                
                if showWelcome {
                    Welcome(isPresented: $showWelcome)
                        .zIndex(1)
                        .transition(.opacity)
                }
            }
            .animation(.easeOut(duration: 0.5), value: showWelcome)
        }
    }
}
