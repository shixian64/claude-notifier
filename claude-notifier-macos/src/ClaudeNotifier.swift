import Foundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }
}

/// 安装自定义音效到 ~/Library/Sounds/
func installCustomSound(from path: String) -> String? {
    let fileManager = FileManager.default
    let sourceURL = URL(fileURLWithPath: path)

    // 验证文件存在
    guard fileManager.fileExists(atPath: path) else {
        fputs("Sound file not found: \(path)\n", stderr)
        return nil
    }

    // 验证文件格式
    let ext = sourceURL.pathExtension.lowercased()
    guard ["aiff", "aif", "wav", "caf", "m4a"].contains(ext) else {
        fputs("Unsupported sound format: \(ext). Use .aiff, .wav, .caf, or .m4a\n", stderr)
        return nil
    }

    // 创建 ~/Library/Sounds/ 目录
    let soundsDir = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Sounds")

    do {
        try fileManager.createDirectory(at: soundsDir, withIntermediateDirectories: true)
    } catch {
        fputs("Failed to create Sounds directory: \(error.localizedDescription)\n", stderr)
        return nil
    }

    // 复制音效文件
    let destURL = soundsDir.appendingPathComponent(sourceURL.lastPathComponent)

    // 如果已存在则删除
    if fileManager.fileExists(atPath: destURL.path) {
        try? fileManager.removeItem(at: destURL)
    }

    do {
        try fileManager.copyItem(at: sourceURL, to: destURL)
        fputs("Installed sound: \(destURL.path)\n", stderr)
    } catch {
        fputs("Failed to copy sound file: \(error.localizedDescription)\n", stderr)
        return nil
    }

    // 返回不带扩展名的文件名
    return sourceURL.deletingPathExtension().lastPathComponent
}

func sendNotification(title: String, message: String, sound: String?, soundFile: String?) {
    let center = UNUserNotificationCenter.current()
    let delegate = NotificationDelegate()
    center.delegate = delegate

    let semaphore = DispatchSemaphore(value: 0)

    // 处理自定义音效文件
    var soundName = sound ?? "Glass"
    if let file = soundFile {
        if let installed = installCustomSound(from: file) {
            soundName = installed
        }
    }

    center.requestAuthorization(options: [.alert, .sound]) { granted, error in
        if let error = error {
            fputs("Authorization error: \(error.localizedDescription)\n", stderr)
            semaphore.signal()
            return
        }

        if !granted {
            fputs("Notification permission denied\n", stderr)
            semaphore.signal()
            return
        }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound(named: UNNotificationSoundName(rawValue: soundName))

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                fputs("Failed to send notification: \(error.localizedDescription)\n", stderr)
            }
            semaphore.signal()
        }
    }

    _ = semaphore.wait(timeout: .now() + 5)
}

// Parse arguments
var title = "Claude Code"
var message = "Task completed"
var sound: String? = "Glass"
var soundFile: String? = nil

var args = CommandLine.arguments.dropFirst()
while let arg = args.popFirst() {
    switch arg {
    case "-t", "--title":
        if let val = args.popFirst() { title = val }
    case "-m", "--message":
        if let val = args.popFirst() { message = val }
    case "-s", "--sound":
        if let val = args.popFirst() { sound = val }
    case "-f", "--sound-file":
        if let val = args.popFirst() { soundFile = val }
    case "--no-sound":
        sound = nil
    case "-h", "--help":
        print("""
        ClaudeNotifier - Send macOS notifications with Claude icon

        Usage: ClaudeNotifier [options]

        Options:
          -t, --title <text>       Notification title (default: "Claude Code")
          -m, --message <text>     Notification message (default: "Task completed")
          -s, --sound <name>       System sound name (default: "Glass")
          -f, --sound-file <path>  Custom sound file (.aiff, .wav, .caf, .m4a)
          --no-sound               Disable notification sound
          -h, --help               Show this help

        System sounds: Basso, Blow, Bottle, Frog, Funk, Glass, Hero, Morse,
                       Ping, Pop, Purr, Sosumi, Submarine, Tink

        Custom sounds: Files are copied to ~/Library/Sounds/ automatically.
                       Sound files must be < 30 seconds.

        Examples:
          ClaudeNotifier -t "Done" -m "Build completed"
          ClaudeNotifier -s Hero
          ClaudeNotifier -f ~/Music/notification.aiff
        """)
        exit(0)
    default:
        break
    }
}

sendNotification(title: title, message: message, sound: sound, soundFile: soundFile)
RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
