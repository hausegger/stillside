import Foundation

struct TerminalPicker {
    struct Item {
        let label: String
        let value: Int
    }

    /// Shows an interactive picker in the terminal. Returns the selected item's value.
    /// Uses arrow keys to navigate, Enter to confirm, q/Esc to cancel.
    static func pick(title: String, items: [Item], initial: Int = 0) -> Int? {
        guard !items.isEmpty else { return nil }

        var selected = items.firstIndex(where: { $0.value == initial }) ?? 0
        let originalTermios = enableRawMode()

        defer {
            restoreTerminalMode(originalTermios)
            // Clear the picker output
            print("\u{1B}[\(items.count + 1)A", terminator: "") // move up
            for _ in 0...items.count {
                print("\u{1B}[2K\u{1B}[1B", terminator: "") // clear line, move down
            }
            print("\u{1B}[\(items.count + 1)A", terminator: "") // move back up
            fflush(stdout)
        }

        render(title: title, items: items, selected: selected)

        while true {
            let c = readChar()
            switch c {
            case 0x1B: // escape sequence
                let next = readChar()
                if next == 0x5B { // [
                    let arrow = readChar()
                    if arrow == 0x41 { // up
                        selected = max(0, selected - 1)
                    } else if arrow == 0x42 { // down
                        selected = min(items.count - 1, selected + 1)
                    }
                } else if next == 0 || next == 0x1B {
                    return nil // bare Esc
                }
            case 0x0A, 0x0D: // Enter
                return items[selected].value
            case 0x71, 0x03: // q, Ctrl-C
                return nil
            default:
                break
            }
            // Move cursor up to redraw
            print("\u{1B}[\(items.count + 1)A", terminator: "")
            render(title: title, items: items, selected: selected)
        }
    }

    private static func render(title: String, items: [Item], selected: Int) {
        print("\u{1B}[1m\(title)\u{1B}[0m")
        for (i, item) in items.enumerated() {
            if i == selected {
                print("  \u{1B}[36m❯ \(item.label)\u{1B}[0m")
            } else {
                print("    \(item.label)")
            }
        }
        fflush(stdout)
    }

    private static func readChar() -> UInt8 {
        var c: UInt8 = 0
        read(STDIN_FILENO, &c, 1)
        return c
    }

    private static func enableRawMode() -> termios {
        var original = termios()
        tcgetattr(STDIN_FILENO, &original)
        var raw = original
        raw.c_lflag &= ~UInt(ECHO | ICANON)
        raw.c_cc.16 = 1 // VMIN
        raw.c_cc.17 = 0 // VTIME
        tcsetattr(STDIN_FILENO, TCSANOW, &raw)
        // Hide cursor
        print("\u{1B}[?25l", terminator: "")
        fflush(stdout)
        return original
    }

    private static func restoreTerminalMode(_ original: termios) {
        var t = original
        tcsetattr(STDIN_FILENO, TCSANOW, &t)
        // Show cursor
        print("\u{1B}[?25h", terminator: "")
        fflush(stdout)
    }
}
