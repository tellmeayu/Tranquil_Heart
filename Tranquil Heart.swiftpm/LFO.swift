import Foundation
import AVFoundation

public class LFO {
    public enum WaveformType {
        case sine
        case triangle
        case square
        case sawUp
        case sawDown
    }
    
    private var startTime: TimeInterval
    private let frequency: Double
    private let amplitude: Double
    private let offset: Double
    private let waveform: WaveformType
    
    public init(frequency: Double = 1.0, amplitude: Double = 0.1, offset: Double = 0.0, waveform: WaveformType = .sine) {
        self.frequency = frequency
        self.amplitude = amplitude
        self.offset = offset
        self.waveform = waveform
        self.startTime = CACurrentMediaTime()
    }
    
    public func getValue() -> Double {
        let currentTime = CACurrentMediaTime()
        let elapsedTime = currentTime - startTime
        let phase = elapsedTime * frequency
        
        switch waveform {
        case .sine:
            return sin(2.0 * .pi * phase) * amplitude + offset
        case .triangle:
            let normalized = phase - floor(phase)
            return (abs(normalized * 4.0 - 2.0) - 1.0) * amplitude + offset
        case .square:
            return (phase - floor(phase) < 0.5 ? 1.0 : -1.0) * amplitude + offset
        case .sawUp:
            return ((phase - floor(phase)) * 2.0 - 1.0) * amplitude + offset
        case .sawDown:
            return ((1.0 - (phase - floor(phase))) * 2.0 - 1.0) * amplitude + offset
        }
    }
    
    public func reset() {
        startTime = CACurrentMediaTime()
    }
}
