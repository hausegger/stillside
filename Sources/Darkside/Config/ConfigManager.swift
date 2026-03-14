import Foundation

final class ConfigManager {
    static let shared = ConfigManager()

    private var eventStream: FSEventStreamRef?
    private var onChange: ((DarksideConfig) -> Void)?

    let configURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/darkside/config.json")
    }()

    func load() -> DarksideConfig {
        guard FileManager.default.fileExists(atPath: configURL.path),
              let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(DarksideConfig.self, from: data)
        else {
            return .default
        }
        return config
    }

    func save(_ config: DarksideConfig) throws {
        let dir = configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: configURL)
    }

    func watch(onChange: @escaping (DarksideConfig) -> Void) {
        self.onChange = onChange

        let dir = configURL.deletingLastPathComponent().path as CFString
        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        guard let stream = FSEventStreamCreate(
            nil,
            { _, info, _, _, _, _ in
                guard let info else { return }
                let manager = Unmanaged<ConfigManager>.fromOpaque(info).takeUnretainedValue()
                let config = manager.load()
                manager.onChange?(config)
            },
            &context,
            [dir] as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            0.5,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagUseCFTypes)
        ) else { return }

        FSEventStreamSetDispatchQueue(stream, DispatchQueue.main)
        FSEventStreamStart(stream)
        eventStream = stream
    }
}
