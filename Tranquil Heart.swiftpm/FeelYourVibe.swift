import SwiftUI
import AVFoundation

@MainActor
struct FeelYourVibe: View {
    @State private var musicPlayer: AVAudioPlayer?
    @State private var lfo: LFO?
    @State private var lfoTimer: Timer?
    @State private var isPlaying = false
    @State private var lfoFreq: Double = 0.1
    @State private var lfoAmp: Double = 0.6
    
    @State private var swipeCount = 0
    @State private var isSwipingDown = false
    @State private var dragStartLocation: CGPoint?
    @State private var minimumDragDistance: CGFloat = 100
    @State private var crossings: [Date] = []
    @State private var lastCrossingDirection: Bool? = nil // true for upward, false for downward
    private let maxCrossingsToKeep = 2
    private let crossingTimeWindow: TimeInterval = 1.5
    @State private var fingerMoveSpeedVer: Double = 0.29
    
    @State private var showPlayButton = false
    @State private var showStopButton = false
    @State private var showHomeButton = false
    @State private var hasGameStarted = false
    
    private let inactivityThreshold: TimeInterval = 5.0
    @State private var fadeOutDuration = 1.2
    @State private var lastInteractionTime = Date()
    @State private var inactivityTimer: Timer?
    @State private var showInstructions = true
    @State private var textOpacity: Double = 0
    @State private var diagramOpacity: Double = 0
    @State private var fingerOffset: CGPoint = .zero
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black
                        .edgesIgnoringSafeArea(.all)
                    
                    //MARK: - Instructions UI
                    if showInstructions {       //instruction contents
                        VStack(spacing: -100) {
                            // Instruction text
                            VStack(spacing: 20) {
                                Text("How to Play")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Text("Up/down to generate tremolo,\nLeft/right to adjust depth. \n\nThe faster you swipe, the quicker the tremolo.")
                                    .font(.system(size: 20, weight: .medium, design: .rounded))
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(.horizontal)
                            }
                            .opacity(textOpacity)
                            
                            // Instruction diagram
                            ZStack {
                                // diagram - bars with titles
                                HStack(spacing: 10) {
                                    Text("rate")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                        .padding(.leading,-30)
                                    
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white.opacity(0.4))
                                        .frame(width: 4, height: 180)
                                }
                                .offset(y: -113)
                                
                                VStack(spacing: 10) {
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(Color.white.opacity(0.4))
                                        .frame(width: 280, height: 4)
                                    
                                    Text("depth")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                .offset(y: 200)
                                
                                // diagram - Moving finger and circle
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.3))
                                        .frame(width: 60, height: 60)
                                        .blur(radius: 3)
                                    
                                    Image(systemName: "hand.point.up.fill")
                                        .resizable()
                                        .frame(width: 30, height: 40)
                                        .foregroundColor(.white.opacity(0.8))
                                        .rotationEffect(.degrees(-15))
                                        .offset(x: -5, y: 25)
                                }
                                .offset(x: fingerOffset.x, y: fingerOffset.y)
                            }
                            .frame(width: 300, height: 500)
                            .opacity(diagramOpacity)
                        }
                        .padding(.top, 30)
                    }
                    
                    //MARK: - Rate and depth display while playing
                    if isPlaying {
                        VStack {
                            Text("Rate: \(String(format: "%.1f", lfoFreq)) Hz\nDepth: \(String(format: "%.2f", lfoAmp))")
                                .font(.system(size: 16, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.4))
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Spacer()
                        }
                        .padding(.top, 40)
                        .padding(.leading, 5)
                    }
                    
                    // MARK: - Play/Stop/Back button handling
                    if !isPlaying && showPlayButton && !showInstructions {
                        PlayButton(isPlaying: false) {
                            handlePlayButtonTap()      //update game states
                        }
                        .position(x: geometry.size.width/2, y: geometry.size.height * 0.5)
                        .transition(.opacity)
                        .opacity(0.85)
                    }
                    
                    if isPlaying && showStopButton {
                        PlayButton(isPlaying: true) {
                            handleStopButtonTap()
                        }
                        .position(x: geometry.size.width/2, y: geometry.size.height * 0.5)
                        .transition(.opacity)
                        .opacity(0.85)
                    }
                    
                    HomeButton(
                        action: handleHomeButtonTap,
                        isVisible: $showHomeButton,
                        screenSize: CGSize(width: geometry.size.width, height: geometry.size.height)
                    )
                }
                
                //MARK: -  touch gestures for LFO control
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if isPlaying {
                                resetInteractionTimer()
                                withAnimation {
                                    showStopButton = false
                                }
                                
                                handleFreqSwipe(value: value, screenHeight: geometry.size.height)
                                handleAmpSwipe(value: value, screenWidth: geometry.size.width, screenHeight: geometry.size.height)
                                
                                Task {
                                    try? await HapticManager.triggerMultiPattern(frequency: Double(lfoFreq), amplitude: Double(lfoAmp))
                                }
                            }
                        }
                )
            }
            
            //MARK: - view events handling
            .onAppear {
                #if DEBUG
                FileSystemManager.debugFileSystem()
                #endif
                if !FileSystemManager.checkFileExists(filename: "FeelYourVibe", extension: "m4a") {
                    print("⚠️ Warning: FeelVibe music file not found")
                }
                
                withAnimation(.easeIn(duration: 0.5)) {
                    textOpacity = 1
                }
                handleOnAppear()
            }
            .onDisappear {
                handleOnDisappear()
                stopInactivityTimer()
            }
        }
    }
    
    // MARK: - Button Actions
    private func handlePlayButtonTap() {
        withAnimation {                                                 //update states var
            showPlayButton = false
            isPlaying = true
            hasGameStarted = true
        }
        print("Starting playback...")
        
        //start to play
        guard let player = musicPlayer else { return }
        withAnimation(.easeOut(duration: 0.5)) {
            showPlayButton = false                                      //button gone while playing
        }
        AudioManager.fadeIn(player)
        setupLFO()
        resetInteractionTimer()
    }
    
    private func handleStopButtonTap() {
        withAnimation {                                                 //update states var
            showStopButton = false
            isPlaying = false
            hasGameStarted = false
        }
        print("Stopping playback...")
        fadeOutMusic()
        
        withAnimation(.easeOut(duration: fadeOutDuration)) {            //play/stop button toggle
            showStopButton = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration) {
            withAnimation(.easeIn(duration: 1.0)) {
                showPlayButton = true
            }
        }
        stopLFO()
        resetInteractionTimer()
    }
    
    private func handleHomeButtonTap() {
        hasGameStarted = false
        stopLFO()
        stopInactivityTimer()
        AudioManager.cleanupAudioSession()
    }
    
    // MARK: - Lifecycle Methods
    private func handleOnAppear() {
        print("Setting up audio and haptic for FeelYourVibe")
        AudioManager.configureAudioSession()
        HapticManager.prepareHaptics()
        musicPlayer = AudioManager.createAudioPlayer(filename: "FeelYourVibe", fileExtension: "m4a")
        
        if musicPlayer == nil {
            print("Failed to create music player")
        } else {
            print("Music player of 'FeelYourVibe' created successfully")
            musicPlayer?.volume = 0.0
            musicPlayer?.numberOfLoops = -1
            musicPlayer?.prepareToPlay()
        }
                
        //instruction and buttons animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 1.3)) {
                textOpacity = 0 // Fade out instruction text
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeIn(duration: 0.5)) {
                    diagramOpacity = 1 // Show instruction diagram
                }
                animateFingerMovement()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.8)) {
                        diagramOpacity = 0
                    } // fade out diagram and show play button
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showInstructions = false
                        withAnimation(.easeIn(duration: 1.0)) {
                            showPlayButton = true
                        }
                    }
                }
            }
        }
        
        //timer starts after play button shows up
        DispatchQueue.main.asyncAfter(deadline: .now() + 11.0) {
            startInactivityTimer()
        }
    }
    
    private func handleOnDisappear() {
        AudioManager.fadeOutAndCleanup(musicPlayer)
        stopInactivityTimer()
        stopLFO()
        musicPlayer?.stop()
        musicPlayer = nil
        isPlaying = false
    }
    
    //MARK: - activity monitoring
    @MainActor
    private func startInactivityTimer() {
        stopInactivityTimer()    // Cancel any existing timer first
        
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                let timeSinceLastInteraction = Date().timeIntervalSince(lastInteractionTime)
                
                if isPlaying {
                    withAnimation(.easeIn(duration: 2.0)) {
                        showStopButton = timeSinceLastInteraction >= inactivityThreshold
                    }
                } else {
                    withAnimation(.easeIn(duration: 2.0)) {
                        showHomeButton = timeSinceLastInteraction >= inactivityThreshold
                    }
                }
            }
        }
    }
    
    private func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
    
    @MainActor
    private func resetInteractionTimer() {
        lastInteractionTime = Date()
        withAnimation {
            showStopButton = false
            showHomeButton = false
        }
    }
    
    // MARK: - music and LFO params handling
    private func fadeOutMusic() {
        guard let player = musicPlayer else { return }
        AudioManager.fadeOut(player, duration: fadeOutDuration)
    }
    
    private func handleFreqSwipe(value: DragGesture.Value, screenHeight: CGFloat) {
        let middleY = screenHeight / 2
        let currentLocation = value.location.y
        let previousLocation = value.predictedEndLocation.y
        
        // Detect crossing the middle line
        if previousLocation != currentLocation {
            let crossedUpward = previousLocation > middleY && currentLocation <= middleY
            let crossedDownward = previousLocation < middleY && currentLocation >= middleY
            
            if crossedUpward || crossedDownward {
                let currentDirection = crossedUpward
                
                // Only record if direction changed
                if lastCrossingDirection != currentDirection {
                    crossings.append(Date())
                    lastCrossingDirection = currentDirection
                    
                    // Keep only recent crossings
                    if crossings.count > maxCrossingsToKeep {
                        crossings.removeFirst()
                    }
                    
                    // Calculate frequency if we have enough crossings
                    if crossings.count >= 2 {
                        calculateFrequencyFromCrossings()
                    }
                }
            }
        }
        
        // Reset if no recent crossings
        if let lastCrossing = crossings.last,
           Date().timeIntervalSince(lastCrossing) > crossingTimeWindow {
            crossings.removeAll()
            lastCrossingDirection = nil
        }
    }
    
    private func calculateFrequencyFromCrossings() {
        guard crossings.count >= 2 else { return }
        
        // Calculate average time between crossings
        var totalTime: TimeInterval = 0
        for i in 1..<crossings.count {
            totalTime += crossings[i].timeIntervalSince(crossings[i-1])
        }
        let averageTime = totalTime / Double(crossings.count - 1)
        
        // Convert to frequency (two crossings per round of crossing)
        let frequency = (1.0 / (averageTime * 2)) * 1.2          // scale to make it easier to reach higher frequencies
        
        // Apply new limits and update
        lfoFreq = min(max(frequency, 0.05), 8.0)
        print("🎵 LFO Frequency updated: \(String(format: "%.2f", lfoFreq)) Hz")
        print("⏱️ Average time between crossings: \(String(format: "%.3f", averageTime))s")
        
        if isPlaying {
            setupLFO()
        }
    }
    
    private func handleAmpSwipe(value: DragGesture.Value, screenWidth: CGFloat, screenHeight: CGFloat) {
        // Check if touch is in bottom fifth of screen
        if value.location.y > screenHeight * 5/6 {
            let amplitude = min(max((value.location.x / screenWidth) * 0.9 + 0.15, 0.15), 0.99)
            lfoAmp = amplitude
            print("📊 LFO Amplitude updated: \(String(format: "%.2f", lfoAmp))")
            
            if isPlaying {
                setupLFO()
            }
        }
    }
    
    private func setupLFO() {
        print("⚙️ Setting up LFO - Frequency: \(String(format: "%.2f", lfoFreq)) Hz, Amplitude: \(String(format: "%.2f", lfoAmp))")
        lfo = LFO(frequency: lfoFreq, amplitude: lfoAmp, offset: 0.1, waveform: .square)
        
        lfoTimer?.invalidate()
        lfoTimer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
            Task { @MainActor in
                guard let lfoValue = lfo?.getValue(),
                      let player = musicPlayer else { return }
                
                let baseVolume = player.volume
                let modulatedVolume = baseVolume * Float(lfoValue)
                player.volume = min(max(modulatedVolume, 0.1), 1.0)
            }
        }
    }
    
    private func stopLFO() {
        lfoTimer?.invalidate()
        lfoTimer = nil
    }
    
    // MARK: - instruction finger animation
    private func animateFingerMovement() {
        fingerOffset = CGPoint(x: 0, y: -40)
        
        withAnimation(Animation.easeInOut(duration: fingerMoveSpeedVer)) {
            fingerOffset = CGPoint(x: 0, y: -220)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + fingerMoveSpeedVer) {
            withAnimation(Animation.easeInOut(duration: fingerMoveSpeedVer)) {
                fingerOffset = CGPoint(x: 0, y: -40)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + fingerMoveSpeedVer) {
                withAnimation(Animation.easeInOut(duration: fingerMoveSpeedVer)) {
                    fingerOffset = CGPoint(x: 0, y: -220)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + fingerMoveSpeedVer) {
                    withAnimation(Animation.easeInOut(duration: fingerMoveSpeedVer)) {
                        fingerOffset = CGPoint(x: 0, y: -40)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + fingerMoveSpeedVer) {
                        withAnimation(Animation.easeInOut(duration: 0.5)) {
                            fingerOffset = CGPoint(x: -120, y: 200)
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            withAnimation(Animation.easeInOut(duration: 0.5)) {
                                fingerOffset = CGPoint(x: 120, y: 200)
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation(Animation.easeInOut(duration: 0.9)) {
                                    fingerOffset = CGPoint(x: -120, y: 200)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    FeelYourVibe()
}
