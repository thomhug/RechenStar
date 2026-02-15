import AVFoundation

enum SoundService {
    private static var audioPlayer: AVAudioPlayer?
    private static var sessionConfigured = false

    private static func configureSession() {
        guard !sessionConfigured else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .mixWithOthers)
        try? AVAudioSession.sharedInstance().setActive(true)
        sessionConfigured = true
    }

    static func playCorrect() {
        playTone(frequency: 880, duration: 0.15) // A5 – freundlicher hoher Ton
    }

    static func playIncorrect() {
        playTone(frequency: 280, duration: 0.25) // tiefer Ton
    }

    private static func playTone(frequency: Double, duration: Double) {
        let sampleRate: Double = 44100
        let frameCount = Int(sampleRate * duration)

        var samples = [Float](repeating: 0, count: frameCount)
        for i in 0..<frameCount {
            let t = Double(i) / sampleRate
            // Sinus-Ton mit Fade-out
            let envelope = Float(1.0 - t / duration)
            samples[i] = envelope * sin(Float(2.0 * .pi * frequency * t))
        }

        // WAV-Header erstellen
        let dataSize = UInt32(frameCount * 2) // 16-bit samples
        var wavData = Data()

        // RIFF header
        wavData.append(contentsOf: "RIFF".utf8)
        appendUInt32(&wavData, 36 + dataSize)
        wavData.append(contentsOf: "WAVE".utf8)

        // fmt chunk
        wavData.append(contentsOf: "fmt ".utf8)
        appendUInt32(&wavData, 16)           // chunk size
        appendUInt16(&wavData, 1)            // PCM format
        appendUInt16(&wavData, 1)            // mono
        appendUInt32(&wavData, UInt32(sampleRate))
        appendUInt32(&wavData, UInt32(sampleRate) * 2) // byte rate
        appendUInt16(&wavData, 2)            // block align
        appendUInt16(&wavData, 16)           // bits per sample

        // data chunk
        wavData.append(contentsOf: "data".utf8)
        appendUInt32(&wavData, dataSize)

        for sample in samples {
            let clamped = max(-1.0, min(1.0, sample))
            let intSample = Int16(clamped * Float(Int16.max))
            appendInt16(&wavData, intSample)
        }

        do {
            configureSession()
            audioPlayer = try AVAudioPlayer(data: wavData)
            audioPlayer?.volume = 0.5
            audioPlayer?.play()
        } catch {
            // Fallback: System-Sound
            AudioToolbox.AudioServicesPlayAlertSound(SystemSoundID(1057))
        }
    }

    private static func appendUInt32(_ data: inout Data, _ value: UInt32) {
        var v = value.littleEndian
        data.append(Data(bytes: &v, count: 4))
    }

    private static func appendUInt16(_ data: inout Data, _ value: UInt16) {
        var v = value.littleEndian
        data.append(Data(bytes: &v, count: 2))
    }

    private static func appendInt16(_ data: inout Data, _ value: Int16) {
        var v = value.littleEndian
        data.append(Data(bytes: &v, count: 2))
    }
}
