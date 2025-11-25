import SwiftUI

struct HomeButton: View {
    var action: () -> Void
    @Binding var isVisible: Bool
    let screenSize: CGSize
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToHome = false
    
    var body: some View {
        if isVisible {
            VStack(spacing: 15) {
                Button {
                    action()
                    dismiss()
                } label: {
                    Text("HOME")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(20)
                        .opacity(0.9)
                }
                
            }
            .opacity(isVisible ? 0.9 : 0.0)
            .animation(.easeIn(duration: 3.5), value: isVisible)
            .transition(.opacity)
            .position(x: screenSize.width/2, y: screenSize.height * 0.85)
        }
    }
}

struct PlayButton: View {
    let isPlaying: Bool
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
            Image(systemName: isPlaying ? "stop.circle" : "play.circle")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.8))
                .scaleEffect(animationScale)
        }
    }
}
