import SwiftUI
import AVFoundation
import CoreHaptics

struct TouchForMusic: View {
    @State private var lastInteractionTime = Date()
    private let inactivityThreshold: TimeInterval = 5
    @State private var touchLocation: CGPoint?
    @State private var isPressed = false
    @State private var fadeOutDuration = 2.0
    @State private var circleScale: CGFloat = 1.0
    @State private var circleOpacity: Double = 0.0
    @State private var isAnimating = false
    @State private var textOpacity: Double = 0.0
    @State private var isHandlingTouch = false
    @State private var hasTriggeredHaptic = false
    @State private var musicPlayer: AVAudioPlayer?
    @State private var hasGameStarted = false
    @State private var inactivityTimer: Timer?
    @State private var showHomeButton = false
    @State private var showTouchInstructions = false
    
    var body: some View {
        NavigationStack {
            //MARK: - UI
            GeometryReader { geometry in
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    if let location = touchLocation {
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 100, height: 100)
                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                            .opacity(circleOpacity)
                            .blur(radius: 15)
                            .position(location)
                            .onAppear {
                                withAnimation(
                                    .easeInOut(duration: 2.0)
                                    .repeatForever(autoreverses: true)
                                ) {
                                    isAnimating = true
                                }
                            }
                    }
                    
                    Text("Touch and hold on the screen, \nthen drag it up or down.")
                        .foregroundStyle(.white)
                        .bold()
                        .multilineTextAlignment(.center)
                        .frame(width: geometry.size.width*0.8)
                        .opacity(textOpacity)
                        .onAppear {
                            withAnimation(Animation.easeIn(duration: 0.8)) {
                                textOpacity = 0.85
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now()+7.0) {
                                withAnimation(Animation.easeOut(duration: 1.2)) {
                                    textOpacity = 0.0
                                }
                            }
                        }
                    
                    if showTouchInstructions {
                        TouchInstruction(
                            isVisible: $showTouchInstructions,
                            screenSize: CGSize(width: geometry.size.width, height: geometry.size.height)
                        )
                    }
                    
                    HomeButton(
                        action: { AudioManager.cleanupAudioSession() },
                        isVisible: $showHomeButton,
                        screenSize: CGSize(width: geometry.size.width, height: geometry.size.height)
                    )
                }
                
                //MARK: - gesture handling
                .simultaneousGesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            resetInteractionTimer()
                            
                            if isHandlingTouch {
                                touchLocation = value.location
                                updateMusicVolume(touchPosition: value.location, screenHeight: geometry.size.height)
                            } else {
                                isHandlingTouch = true
                                touchLocation = value.location
                                isPressed = true
                                HapticManager.triggerHeavyHaptic()
                                startMusic()
                                withAnimation(.easeIn(duration: fadeOutDuration)) {
                                    circleOpacity = 0.8
                                }
                            }
                        }
                        .onEnded {_ in
                            isHandlingTouch = false
                            isPressed = false
                            touchLocation = nil
                            fadeOutMusic()
                            withAnimation(.easeOut(duration: fadeOutDuration)) {
                                circleOpacity = 0.0
                            }
                        }
                )
            }
            //MARK: - view events handling
            .onAppear {
                #if DEBUG
                FileSystemManager.debugFileSystem()
                #endif
                if !FileSystemManager.checkFileExists(filename: "TouchMusic-1", extension: "m4a") {
                    print("⚠️ Warning: Touch music file not found")
                }
                // FileSystemManager.listFiles(inDirectory: "AudioFiles")
                
                handleOnAppear()
            }
            .onDisappear {
                stopInactivityTimer()
                AudioManager.cleanupAudioSession(fadeOutDuration: fadeOutDuration)
            }
        }
    }
    
    //MARK: - activity monitoring
    @MainActor
    private func startInactivityTimer() {
        stopInactivityTimer()
        resetInteractionTimer()
        
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                let timeSinceLastInteraction = Date().timeIntervalSince(lastInteractionTime)
                if timeSinceLastInteraction >= inactivityThreshold {
                    withAnimation(.easeIn(duration: 2.0)) {
                        showHomeButton = true
                    }
                }
            }
        }
    }
    
    private func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
    
    private func resetInteractionTimer() {
        lastInteractionTime = Date()
        withAnimation {
            showHomeButton = false
        }
    }
    
    //MARK: - life cycle methods, music setting up
    private func handleOnAppear() {
        print("Setting up audio and haptic for TouchForMusic...")
        AudioManager.configureAudioSession()
        HapticManager.prepareHaptics()
        
        musicPlayer = AudioManager.createAudioPlayer(filename: "TouchMusic-1", fileExtension: "m4a")
        if musicPlayer == nil {
            print("Failed to create music player")
        } else {
            print("Music player of 'TouchMusic-1' created successfully")
            musicPlayer?.prepareToPlay()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            showTouchInstructions = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 8.8) {
            showTouchInstructions = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
            startInactivityTimer()
        }
    }
    
    private func startMusic() {
        guard let player = musicPlayer else { return }
        player.currentTime = 0
        player.volume = 0.6
        player.play()
    }
    
    private func updateMusicVolume(touchPosition: CGPoint, screenHeight: CGFloat) {
        guard let player = musicPlayer else { return }
        
        let relativePosition = 1 - (touchPosition.y / screenHeight)
        let volume = Float(relativePosition) * 0.9 + 0.1
        withAnimation(.linear(duration: 0.1)) {
            player.volume = min(max(volume, 0.05), 0.9)
        }
    }
    
    private func fadeOutMusic() {
        guard let player = musicPlayer else { return }
        AudioManager.fadeOut(player, duration: fadeOutDuration)
        print("faded out!")
    }
}

//MARK: - instruction views
struct TouchInstruction: View {
    @Binding var isVisible: Bool
    let screenSize: CGSize
    
    var body: some View {
        UpDownMove()
            .frame(height: 200)
            .opacity(isVisible ? 0.9 : 0)
            .animation(.easeInOut(duration: 1.5), value: isVisible)
            .position(x: screenSize.width/2,
                      y: screenSize.height * 0.6)
    }
}

struct UpDownMove: View {
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 0
    
    let instructionSize: CGSize = CGSize(width: 120, height: 200)
    let moveDistance: CGFloat = 330
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: 60, height: 60)
                .blur(radius: 3)
            
            // Hand icon
            Image(systemName: "hand.point.up.fill")
                .resizable()
                .frame(width: 30, height: 40)
                .foregroundColor(.white.opacity(0.65))
                .rotationEffect(.degrees(-15))
                .offset(x: -5, y: 25)  // Position finger to "touch" the circle
        }
        .offset(y: offset)
        .animation(
            Animation
                .easeInOut(duration: 4)
                .repeatForever(autoreverses: true),
            value: offset
        )
        .opacity(opacity)
        .onAppear {
            offset = -moveDistance
            withAnimation(.easeIn(duration: 1.0)) {
                opacity = 0.7
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+5.5) {
                withAnimation(Animation.easeOut(duration: 1.2)) {
                    opacity = 0.0
                }
            }
        }
    }
}


#Preview {
    TouchForMusic()
}


//#Preview {
//    ZStack {
//        Color.black.edgesIgnoringSafeArea(.all)
//        TouchInstruction(isVisible: .constant(true),
//                         screenSize: CGSize(width: 390, height: 844))
//    }
//}
