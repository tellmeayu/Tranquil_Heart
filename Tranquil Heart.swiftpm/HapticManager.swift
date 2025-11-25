import CoreHaptics

enum HapticManager {
    
    static nonisolated(unsafe) private var engine: CHHapticEngine?
    
    static func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        do {
            engine = try CHHapticEngine()
            try engine?.start()
            print("📳 Haptic engine started")
        } catch {
            print("📳 Haptic engine Creation Error: \(error.localizedDescription)")
        }
    }
    
    static private func restartEngine() {
        do {
            try engine?.start()
        } catch {
            print("Failed to restart haptic engine: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Normal Haptic, a single tap
    static func triggerNormalHaptic() {
        guard let engine = engine else { return }
        
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.4)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity,sharpness], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play normal haptic pattern: \(error.localizedDescription)")
            restartEngine()
        }
    }
    
    // MARK: - Dynamic haptic params, design for Feel Your Vibe
    static func triggerMultiPattern(frequency: Double, amplitude: Double) async {
        guard let engine = engine else { return }
        
        do {
            if frequency <= 2.0 {
                // For low frequencies, use continuous pattern
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(amplitude)*0.7)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                let event = CHHapticEvent(
                    eventType: .hapticContinuous,
                    parameters: [intensity, sharpness],
                    relativeTime: 0,
                    duration: 0.2
                )
                
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            } else {
                // For higher frequencies, use quick pulses
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(amplitude)*0.6)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: 0
                )
                
                let pattern = try CHHapticPattern(events: [event], parameters: [])
                let player = try engine.makePlayer(with: pattern)
                try player.start(atTime: 0)
            }
        } catch {
            print("Failed to play haptic pattern: \(error.localizedDescription)")
            restartEngine()
        }
    }
    
    // MARK: - Gradual Haptic, increase then decrease intensity
    static func triggerGradualHaptic(intensity: Float = 0.6) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        guard let engine = engine else { return }
        
        // Create a 1-second gradual haptic pattern
        var events: [CHHapticEvent] = []
        let duration = 1.2
        
        // Create intensity curve that gradually increases then decreases
        for i in 0...18 {
            let progress = Float(i) / 20.0
            let time = Double(i) * (duration / 20.0)
            
            // Create a bell curve for intensity
            let normalizedIntensity = 1 - pow(2 * progress - 1, 2)  // Peak in the middle
            let currentIntensity = intensity * normalizedIntensity
            
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: currentIntensity),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: time,
                duration: duration / 20.0
            ))
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try engine.start()
            try player.start(atTime: 0)
        } catch {
            print("Failed to play gradual haptic pattern: \(error.localizedDescription)")
            restartEngine()
        }
    }
    
    // MARK: - Heavy Haptic, decrease from a strong intensity
    static func triggerHeavyHaptic() {
        guard let engine = engine else { return }
        
        let events = stride(from: 0.0, to: 1.0, by: 0.2).map { time in
            CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(1.0 - time)),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: time,
                duration: 0.2
            )
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play heavy haptic pattern: \(error.localizedDescription)")
            restartEngine()
        }
    }
}

