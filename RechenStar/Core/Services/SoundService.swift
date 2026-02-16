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

    // Aufmerksamkeitston bei +/- Verwechslung
    static func playOperationHint() {
        playMelody(notes: [
            (frequency: 523.25, duration: 0.12),  // C5 – aufsteigend
            (frequency: 659.25, duration: 0.20),  // E5 – "Achtung!"
        ])
    }

    // Fanfare "tütertütüü" bei Session-Abschluss
    static func playSessionComplete() {
        playMelody(notes: [
            (frequency: 523.25, duration: 0.13),  // C5  "tü"
            (frequency: 659.25, duration: 0.13),  // E5  "ter"
            (frequency: 783.99, duration: 0.13),  // G5  "tü"
            (frequency: 1046.50, duration: 0.45), // C6  "tüü"
        ])
    }

    // Triumphaler 3-Ton bei Revenge (Schwäche-Aufgabe gemeistert)
    static func playRevenge() {
        playMelody(notes: [
            (frequency: 659.25, duration: 0.12),  // E5
            (frequency: 783.99, duration: 0.12),  // G5
            (frequency: 1046.50, duration: 0.30), // C6
        ])
    }

    // Aufsteigender Chime bei neuem Achievement
    static func playAchievement() {
        playMelody(notes: [
            (frequency: 659.25, duration: 0.1),   // E5
            (frequency: 830.61, duration: 0.1),   // G#5
            (frequency: 987.77, duration: 0.1),   // B5
            (frequency: 1318.51, duration: 0.35), // E6
        ])
    }

    private static func playMelody(notes: [(frequency: Double, duration: Double)]) {
        let sampleRate: Double = 44100
        let pauseDuration: Double = 0.025

        var allSamples = [Float]()

        for note in notes {
            let frameCount = Int(sampleRate * note.duration)
            for i in 0..<frameCount {
                let t = Double(i) / sampleRate
                let attack = min(t / 0.008, 1.0)
                let release = min((note.duration - t) / 0.04, 1.0)
                let envelope = Float(max(0, min(attack, release)))
                let fundamental = sin(Float(2.0 * .pi * note.frequency * t))
                let harmonic2 = 0.35 * sin(Float(2.0 * .pi * note.frequency * 2.0 * t))
                let harmonic3 = 0.12 * sin(Float(2.0 * .pi * note.frequency * 3.0 * t))
                allSamples.append(envelope * (fundamental + harmonic2 + harmonic3))
            }
            let gapFrames = Int(sampleRate * pauseDuration)
            allSamples.append(contentsOf: [Float](repeating: 0, count: gapFrames))
        }

        // Normalisieren
        let peak = allSamples.map { abs($0) }.max() ?? 1.0
        if peak > 0 {
            for i in 0..<allSamples.count {
                allSamples[i] /= peak
            }
        }

        let dataSize = UInt32(allSamples.count * 2)
        var wavData = Data()

        wavData.append(contentsOf: "RIFF".utf8)
        appendUInt32(&wavData, 36 + dataSize)
        wavData.append(contentsOf: "WAVE".utf8)

        wavData.append(contentsOf: "fmt ".utf8)
        appendUInt32(&wavData, 16)
        appendUInt16(&wavData, 1)
        appendUInt16(&wavData, 1)
        appendUInt32(&wavData, UInt32(sampleRate))
        appendUInt32(&wavData, UInt32(sampleRate) * 2)
        appendUInt16(&wavData, 2)
        appendUInt16(&wavData, 16)

        wavData.append(contentsOf: "data".utf8)
        appendUInt32(&wavData, dataSize)

        for sample in allSamples {
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
            AudioToolbox.AudioServicesPlayAlertSound(SystemSoundID(1057))
        }
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
