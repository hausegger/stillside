import Foundation

final class ConfigManager {
    static let shared = ConfigManager()
    private init() {}

    private var eventStream: FSEventStreamRef?
    private var onChange: ((StillsideConfig) -> Void)?
    private var lastConfig: StillsideConfig?

    let configURL: URL = {
        let home = FileManager.default.homeDirectoryForCurrentUser
        return home.appendingPathComponent(".config/stillside/config.json")
    }()

    func load() -> StillsideConfig {
        guard FileManager.default.fileExists(atPath: configURL.path),
              let data = try? Data(contentsOf: configURL),
              let config = try? JSONDecoder().decode(StillsideConfig.self, from: data)
        else {
            return .default
        }
        return config
    }

    func save(_ config: StillsideConfig) throws {
        let dir = configURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: configURL, options: .atomic)
    }

    func stopWatching() {
        if let stream = eventStream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            eventStream = nil
        }
    }

    func watch(onChange: @escaping (StillsideConfig) -> Void) {
        stopWatching()
        self.onChange = onChange
        self.lastConfig = load()

        let dir = configURL.deletingLastPathComponent().path as CFString
        var context = FSEventStreamContext()
        context.info = Unmanaged.passUnretained(self).toOpaque()

        guard let stream = FSEventStreamCreate(
            nil,
            { _, info, _, _, _, _ in
                guard let info else { return }
                let manager = Unmanaged<ConfigManager>.fromOpaque(info).takeUnretainedValue()
                let config = manager.load()
                guard config != manager.lastConfig else { return }
                manager.lastConfig = config
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
