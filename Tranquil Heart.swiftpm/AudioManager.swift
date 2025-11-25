import Foundation
import AVFoundation

enum AudioManager {
    static let fadeOutDuration: TimeInterval = 2.0
    
    static func url(for filename: String, withExtension ext: String) -> URL? {
//        print("...Looking for resource: \(filename).\(ext)")
        
        if let bundleURL = Bundle.main.url(forResource: filename, withExtension: ext) {
//            print("✅ 😄 Found in bundle: \(bundleURL.path())")
            return bundleURL
        }
        print("🥺 Not found in bundle")
        
        return nil
    }
    
    static func configureAudioSession() {
        do {
            print("Configuring audio session...")
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            Thread.sleep(forTimeInterval: 0.1)
            
            //create new session
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("✅ Audio session configured successfully")
        } catch {
            print("❌ Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    static func createAudioPlayer(filename: String, fileExtension: String) -> AVAudioPlayer? {
        guard let url = url(for: filename, withExtension: fileExtension) else {
            print("❌ Could not find audio file: \(filename).\(fileExtension)")
            return nil
        }
        
        do {
            let player = try AVAudioPlayer(contentsOf: url)
           print("✅ Created player for: \(filename).\(fileExtension)")
            return player
        } catch {
            print("❌ Error creating audio player: \(error.localizedDescription)")
            return nil
        }
    }

    @MainActor
    static func fadeIn(_ player: AVAudioPlayer, duration: TimeInterval = 1.3, volume: Float = 1.0) {
        player.volume = 0.0
        player.play()
            
        let fadeDuration: TimeInterval = duration
        let fadeSteps = 20
        let fadeStepDuration = fadeDuration / Double(fadeSteps)
        let fadeStepVolume = volume / Float(fadeSteps)
        
        for step in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeStepDuration*Double(step)) {
                player.volume += fadeStepVolume
            }
        }
    }

    @MainActor
    static func fadeOut(_ player: AVAudioPlayer?, duration: TimeInterval = 2.0, completion: (() -> Void)? = nil) {
        guard let player = player else {
            completion?()                   //completion: for possible extra action after music fade-out
            return
        }
        
        let fadeDuration: TimeInterval = duration
        let fadeSteps = 20
        let fadeStepDuration = fadeDuration / Double(fadeSteps)
        let fadeStepVolume = player.volume / Float(fadeSteps)
        
        for step in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + fadeStepDuration*Double(step)) {
                player.volume -= fadeStepVolume
                if player.volume <= 0 {
                    player.stop()
                    if step == fadeSteps - 1 {
                        completion?()
                    }
                }
            }
        }
    }

    static func cleanupAudioSession(fadeOutDuration: TimeInterval = 0.1) {
        DispatchQueue.main.asyncAfter(deadline: .now() + fadeOutDuration) {                 // small delay before cleanup
            print("trying to clean up.....")
            do {
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(.playback, mode: .default)
                if audioSession.isOtherAudioPlaying {
                    try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
                } else {
                    try audioSession.setActive(false)
                    print("audio session deactivated!")
                }
            } catch {
                print("Audio session cleanup warning: \(error.localizedDescription)")
            }
        }
    }
    
    @MainActor static func fadeOutAndCleanup(_ player: AVAudioPlayer?, duration: TimeInterval = fadeOutDuration) {
        fadeOut(player, duration: duration) {
            cleanupAudioSession()
        }
    }

}


