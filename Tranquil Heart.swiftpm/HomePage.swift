import SwiftUI

//game title buttons
struct FloatingGameBubble: View {
    let title: String
    let icon: String
    let position: CGPoint
    let action: () -> Void
    @State private var animationScale: CGFloat = 1.0
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                animationScale = 0.9
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animationScale = 1.0
                }
            }
            action()
        }) {
            VStack(spacing: 10) {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.8),
                                Color.white.opacity(0.3)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 40))
                            .foregroundColor(.black.opacity(0.6))
                    )
                    .shadow(color: .white.opacity(0.4), radius: 10, x: 0, y: 0)
                
                Text(title)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .medium))
            }
            .scaleEffect(animationScale)
        }
        .position(position)
    }
}

struct HomePage: View {
    @State private var navigateToHarmony = false
    @State private var navigateToTouch = false
    @State private var navigateToVibe = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Night sky background
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                // Stars
                ForEach(0..<50) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                            y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                        )
                        .opacity(Double.random(in: 0.3...0.8))
                }
                
                // Guide text
                Text("Touch screen to play.\nWhen you're done, just do nothing for a few seconds.")
                    .foregroundColor(.white.opacity(0.7))
                    .font(.system(size: 18, weight: .medium))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .position(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height * 0.15)
                
                // Game bubbles
                FloatingGameBubble(
                    title: "Harmony With Me",
                    icon: "music.note",
                    position: CGPoint(x: UIScreen.main.bounds.width * 0.3,
                                    y: UIScreen.main.bounds.height * 0.3)
                ) {
                    navigateToHarmony = true
                }
                
                FloatingGameBubble(
                    title: "Touch For Music",
                    icon: "hand.tap",
                    position: CGPoint(x: UIScreen.main.bounds.width * 0.7,
                                    y: UIScreen.main.bounds.height * 0.5)
                ) {
                    navigateToTouch = true
                }
                
                FloatingGameBubble(
                    title: "Feel Your Vibe",
                    icon: "waveform",
                    position: CGPoint(x: UIScreen.main.bounds.width * 0.4,
                                    y: UIScreen.main.bounds.height * 0.7)
                ) {
                    navigateToVibe = true
                }
            }
            .navigationDestination(isPresented: $navigateToHarmony) {
                HarmonyWithMe()
            }
            .navigationDestination(isPresented: $navigateToTouch) {
                TouchForMusic()
            }
            .navigationDestination(isPresented: $navigateToVibe) {
                FeelYourVibe()
            }
        }
    }
}

#Preview {
    HomePage()
}
