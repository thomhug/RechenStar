import AudioToolbox

enum SoundService {
    static func playCorrect() {
        AudioServicesPlaySystemSound(1025)
    }

    static func playIncorrect() {
        AudioServicesPlaySystemSound(1073)
    }
}
