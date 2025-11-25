import SwiftUI
import AVFoundation
import CoreHaptics

//MARK: - delegate handling playback finish and loop
private class MusicDelegate: NSObject, AVAudioPlayerDelegate {
    var onMusicLoop: () -> Void
    
    init(onMusicLoop: @escaping () -> Void) {
        self.onMusicLoop = onMusicLoop
        super.init()
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if flag {
            print("🔄 Background music loop completed, resetting game")
            onMusicLoop()
        }
    }
}

//MARK: - main view
struct HarmonyWithMe: View {
    @State private var circlePosition: CGPoint = .zero
    @State private var showCircle = false
    @State private var showHomeButton = false
    @State private var lastInteractionTime = Date()
    private let inactivityThreshold: TimeInterval = 9
    @State private var backgroundPlayer: AVAudioPlayer?
    @State private var harmonySoundPlayer: AVAudioPlayer?
    @State private var musicTimer: Timer?
    @State private var nextTriggerIndex = 0
    @State private var engine: CHHapticEngine?
    @State private var circleScale: CGFloat = 1.0
    @State private var circleOpacity: Double = 0.0
    @State private var instructionOpacity: Double = 0.0
    private let circleDuration: TimeInterval = 2.0
    private let circleRadius: CGFloat = 35.0
    private let circlePressSoundAmp: Float = 0.95
    
    //MARK: - circle sound setting
    private let soundGroups: [[String]] = [
        ["Kalimba_7.636", "Lullaby_Vibes_7.636"],
        ["Kalimba_13.091", "Lullaby_Vibes_13.091"],
        ["Kalimba_20.727", "Lullaby_Vibes_20.727"],
        ["Kalimba_27.273", "Lullaby_Vibes_27.273"],
        ["Kalimba_32.727", "Lullaby_Vibes_32.727"],
        ["Kalimba_39.273", "Lullaby_Vibes_39.273"],
        ["Kalimba_49.091", "Lullaby_Vibes_49.091"],
        ["Kalimba_55.636", "Lullaby_Vibes_55.636"],
        ["Kalimba_62.182", "Lullaby_Vibes_62.182"],
        ["ZenGarden_SylviaOh_72.0"],
        ["ZenGarden_SylviaOh_78.545"],
        ["ZenGarden_SylviaOh_85.091"],
        ["ZenGarden_SylviaOh_98.182"],
        ["ZenGarden_SylviaOh_104.727"],
        ["ZenGarden_SylviaOh_111.273"],
        ["ZenGarden_SylviaOh_117.818"],
        ["DiamondShower_124.364"],
        ["DiamondShower_137.455"],
        ["DiamondShower_150.545"],
        ["AcousGuitar_161.455"],
        ["AcousGuitar_168.0"]
    ]
    
// 21 time points [7.636, 13.091, 20.727, 27.273, 32.727, 39.273, 49.091, 55.636, 62.182, 72.0, 78.545, 85.091, 98.182, 104.727, 111.273, 117.818, 124.364, 137.455, 150.545, 161.455, 168.0]
    private let circleTriggerTimes: [TimeInterval] = [5.64, 11.09, 18.73, 25.27, 30.73, 37.27, 47.09, 53.64, 60.18, 70.0, 76.54, 83.09, 96.18, 102.73, 109.27, 115.82, 122.36, 135.46, 148.54, 159.46, 166.0]

    @State private var currentSoundGroupIndex = 0
    @State private var isCircleActive = false
    @State private var isShowingCircle = false
    @State private var musicDelegate: MusicDelegate?

    @State private var hasGameStarted = false
    @State private var inactivityTimer: Timer?
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                //MARK: - UI
                ZStack{
                    Color.black.edgesIgnoringSafeArea(.all)
                    //instruction
                    Text("Tap the white dot when it appears.")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(width: 300)
                        .opacity(instructionOpacity)
                        .onAppear {
                            withAnimation(Animation.easeIn(duration: 1.0)) {
                                instructionOpacity = 0.9
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(Animation.easeOut(duration: 1.0)) {
                                    instructionOpacity = 0.0
                                }
                            }
                        }
                    
                    //MARK: - circle tap handling
                    if showCircle {
                        Circle()
                            .fill(Color.white.opacity(0.8))
                            .frame(width: 100, height: 100)
                            .scaleEffect(circleScale)
                            .opacity(circleOpacity)
                            .blur(radius: 15)
                            .position(circlePosition)
                            .onTapGesture {
                                if isCircleActive {
                                    print("Circle tapped")
                                    playRandomSoundFromCurrentGroup()
                                    HapticManager.triggerGradualHaptic()
                                    resetInactivityTimer()
                                }
                            }
                    }
                    
                    HomeButton(
                        action: { fadeOutAndClean() },
                        isVisible: $showHomeButton,
                        screenSize: CGSize(width: geometry.size.width, height: geometry.size.height)
                    )
                }
                
                //MARK: - view events handling
                .onAppear {
                    #if DEBUG
                    FileSystemManager.debugFileSystem()
                    #endif
                    if !FileSystemManager.checkFileExists(filename: "HarmonyWithMe", extension: "m4a") {
                        print("⚠️ Warning: Background music file not found")
                    }
//                    FileSystemManager.listFiles(inDirectory: "AudioFiles")
                    
                    AudioManager.configureAudioSession()
                    HapticManager.prepareHaptics()
                    startBackgroundMusic()
                    initializeGame()
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if isTouchInsideCircle(at: value.location) && !isPlayingHarmonySound() {
                                playRandomSoundFromCurrentGroup()
                                HapticManager.triggerGradualHaptic()
                            }
                            resetInactivityTimer()
                        }
                )
                .onDisappear {
                    fadeOutAndClean()
                }
            }
        }
    }
    
    //MARK: - game start
    private func startBackgroundMusic() {
        backgroundPlayer = AudioManager.createAudioPlayer(filename: "HarmonyWithMe4", fileExtension: "m4a")
         
        guard let player = backgroundPlayer else {
            print("❌ Failed to create background player")
            return
        }

        musicDelegate = MusicDelegate {
            DispatchQueue.main.async {
                self.resetGame()
            }
        }
        
        AudioManager.fadeIn(player, volume: 1.0)
        player.delegate = musicDelegate
        player.numberOfLoops = -1
    }
    
    private func initializeGame() {
        nextTriggerIndex = 0
        startMusicTimer()
        startInactivityTimer()
        print(">>>>>>>Game initialized<<<<<<<<<")
    }
    
    //MARK: - harmony circle handling
    private func playRandomSoundFromCurrentGroup() {
        guard currentSoundGroupIndex < soundGroups.count,
              isCircleActive else {
            print("⭕️ Cannot play sound: circle not active or invalid group index")
            print("current group index: \(currentSoundGroupIndex), circle active? \(isCircleActive)")
            return
        }
        
        let currentGroup = soundGroups[currentSoundGroupIndex]
        let randomSound = currentGroup.randomElement() ?? currentGroup[0]
//        print("⚪️ Playing sound from group \(currentSoundGroupIndex + 1): \(randomSound)")
        
        harmonySoundPlayer = AudioManager.createAudioPlayer(filename: randomSound, fileExtension: "m4a")
        
        guard let player = harmonySoundPlayer else {
            print("⭕️ Failed to create harmony sound player")
            return
        }
        
        player.volume = circlePressSoundAmp
        player.play()
        print("🟢 Harmony sound played")
    }

    private func isPlayingHarmonySound() -> Bool {
        return harmonySoundPlayer?.isPlaying ?? false
    }
    
    private func isTouchInsideCircle(at location: CGPoint) -> Bool {
        let dx = location.x - circlePosition.x
        let dy = location.y - circlePosition.y
        return sqrt(dx*dx+dy*dy) <= circleRadius
    }
    
    private func showCircleAtRandomPosition() {
        guard !isShowingCircle else { return }
        
        isShowingCircle = true
        isCircleActive = true
        
        let bounds = UIScreen.main.bounds
        let randomX = CGFloat.random(in: circleRadius*2...(bounds.width - circleRadius*2))
        let randomY = CGFloat.random(in: circleRadius*6...(bounds.height - circleRadius*10))
        
        withAnimation(Animation.easeIn(duration: 0.5)) {
            circlePosition = CGPoint(x: randomX, y: randomY)
            showCircle = true
            circleOpacity = 1.0
        }
        print("⭕️ Circle positioned at: (\(randomX), \(randomY))")
        DispatchQueue.main.asyncAfter(deadline: .now() + circleDuration) {
            withAnimation(.easeOut(duration: 1.0)) {
                self.showCircle = false
                self.circleOpacity = 0.0
            }
            self.isShowingCircle = false
            self.isCircleActive = false
        }
    }
    
    //MARK: - playback position monitoring
    private func startMusicTimer() {
        musicTimer?.invalidate()
        nextTriggerIndex = 0
        
        print("❗️about to creat new music timer!")
        musicTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            Task { @MainActor in
                guard let player = self.backgroundPlayer else { return }
                if player.currentTime >= player.duration - 0.2 {
                    print("🔄 Music about to loop, resetting game")
                    self.resetGame()
                }
                self.checkMusicPosition()
            }
        }
//        print("about to check music position...")
    }
    
    private func checkMusicPosition() {
        guard let player = backgroundPlayer,
              nextTriggerIndex < circleTriggerTimes.count else { return }
        
        let currentTime = player.currentTime
        let nextTriggerTime = circleTriggerTimes[nextTriggerIndex]
        
        let tolerance: TimeInterval = 0.2
        if currentTime >= nextTriggerTime && currentTime <= nextTriggerTime + tolerance && !isShowingCircle {
//            print("⭕️ Attempting to show circle at trigger time: \(nextTriggerTime)")
            currentSoundGroupIndex = nextTriggerIndex
            showCircleAtRandomPosition()
            nextTriggerIndex += 1
        }
    }
    
    //MARK: - activity monitoring
    @MainActor
    private func startInactivityTimer() {
        stopInactivityTimer()
        resetInactivityTimer()
        
        inactivityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            Task { @MainActor in
                checkForInactivity()
            }
        }
    }
    
    private func stopInactivityTimer() {
        inactivityTimer?.invalidate()
        inactivityTimer = nil
    }
    
    private func resetInactivityTimer() {
        lastInteractionTime = Date()
        withAnimation {
            showHomeButton = false
        }
    }
    
    private func checkForInactivity() {
        let timeSinceLastInteraction = Date().timeIntervalSince(lastInteractionTime)
        if timeSinceLastInteraction >= inactivityThreshold {
            withAnimation(.easeIn(duration: 2.0)) {
                showHomeButton = true
            }
        }
    }
    
    //MARK: - game reset and cleanup
    private func resetGame() {
        currentSoundGroupIndex = 0
        isShowingCircle = false
        isCircleActive = false
        showCircle = false
        circleOpacity = 0.0
        startMusicTimer()
        print("❗️game reset!")
    }
    
    private func fadeOutAndClean() {
        guard let player = backgroundPlayer else { return }
        AudioManager.fadeOut(player)
        musicTimer?.invalidate()
        musicTimer = nil
        stopInactivityTimer()
        
        guard let harmony = harmonySoundPlayer else { return }
        harmony.stop()
        harmonySoundPlayer = nil
        print("All players cleaned up")
        
        musicDelegate = nil
        isShowingCircle = false
        isCircleActive = false
        showCircle = false
        circleOpacity = 0.0
        currentSoundGroupIndex = 0
        nextTriggerIndex = 0
        print("Game states reset")

        DispatchQueue.main.asyncAfter(deadline: .now() + AudioManager.fadeOutDuration) {
            backgroundPlayer = nil
        }
        
        print("✅ HarmonyWithMe cleanup completed")
    }
}

#Preview {
    HarmonyWithMe()
}
