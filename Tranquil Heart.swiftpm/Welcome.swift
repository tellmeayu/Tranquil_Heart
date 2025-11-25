import SwiftUI

struct Star: Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGFloat
    let twinkleSpeed: Double
    
    static func random(in rect: CGRect) -> Star {
        Star(
            position: CGPoint(
                x: CGFloat.random(in: 0...rect.width),
                y: CGFloat.random(in: 0...rect.height)
            ),
            size: CGFloat.random(in: 1...3),
            twinkleSpeed: Double.random(in: 1.5...3.0)
        )
    }
}

struct TwinklingStar: View {
    let size: CGFloat
    let speed: Double
    @State private var opacity: Double = 0.3
    
    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(Color.white)
                .frame(width: size * 2, height: size * 2)
                .blur(radius: size * 1.5)
                .opacity(opacity * 0.3)
            
            // Middle glow
            Circle()
                .fill(Color.white)
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: size)
                .opacity(opacity * 0.5)
            
            // Core
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
                .blur(radius: size * 0.3)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(
                .easeInOut(duration: speed)
                .repeatForever(autoreverses: true)
            ) {
                opacity = 0.8
            }
        }
    }
}

struct LogoView: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1
    
    var body: some View {
        ZStack {
            // Outer circle
            Circle()
                .stroke(Color.white.opacity(0.6), lineWidth: 1)
                .frame(width: 60, height: 60)
            
            // Inner wave-like pattern
            Path { path in
                path.move(to: CGPoint(x: 15, y: 30))
                path.addCurve(
                    to: CGPoint(x: 45, y: 30),
                    control1: CGPoint(x: 25, y: 20),
                    control2: CGPoint(x: 35, y: 40)
                )
            }
            .stroke(Color.white, lineWidth: 2)
            .frame(width: 60, height: 60)
//            .rotationEffect(.degrees(rotation))
        }
        .scaleEffect(scale)
        .onAppear {
//            withAnimation(
//                .easeInOut(duration: 5)
//                .repeatForever(autoreverses: true)
//            ) {
//                rotation = 360
//                scale = 1.1
//            }
        }
    }
}

struct Welcome: View {
    @State private var stars: [Star] = []
    @State private var navigateToHome = false
    @State private var textOpacity: Double = 0
    @State private var logoOpacity: Double = 0
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                        Color(red: 0.05, green: 0.05, blue: 0.1)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)
                
                ForEach(stars) { star in
                    TwinklingStar(size: star.size, speed: star.twinkleSpeed)
                        .position(star.position)
                }
                
                VStack(spacing: 40) {
                    LogoView()
                        .opacity(logoOpacity)
                        .padding(.top, 120)
                    
                    VStack(spacing: 30) {
                        Text("Tranquil Heart")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .padding(20)
                        
                        Text("A unique meditation experience\nthrough interactive soundscapes")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .multilineTextAlignment(.center)
                            .opacity(0.8)
                        
                        Text("Touch • Feel • Harmonize")
                            .font(.system(size: 16, weight: .regular, design: .rounded))
                            .opacity(0.6)
                        
                        Text("START")
                            .font(.system(size: 30, weight:.bold, design: .rounded))
                            .padding(.top, 160)
                    }
                    .foregroundColor(.white)
                    .opacity(textOpacity)
                    Spacer()
                }
            }
            .onAppear {
                // Generate random stars
                let screenBounds = UIScreen.main.bounds
                stars = (0..<30).map { _ in Star.random(in: screenBounds) }
                
                withAnimation(.easeIn(duration: 0.5)) {
                    logoOpacity = 1
                }
                withAnimation(.easeIn(duration: 0.5).delay(0.1)) {
                    textOpacity = 1
                }
            }
            .onTapGesture {
                withAnimation {
                    isPresented = false
                }
            }
        }
    }
}

#Preview {
//    LogoView()
    Welcome(isPresented: .constant(true))
}
