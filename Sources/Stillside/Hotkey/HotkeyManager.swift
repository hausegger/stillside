import AppKit
import Carbon
import HotKey

final class HotkeyManager {
    private var hotKey: HotKey?
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    func register(hotkeyString: String) {
        guard let (key, modifiers) = Self.parse(hotkeyString) else {
            fputs("Warning: invalid hotkey '\(hotkeyString)', using default cmd+option+b\n", stderr)
            register(key: .b, modifiers: [.command, .option])
            return
        }
        register(key: key, modifiers: modifiers)
    }

    private func register(key: Key, modifiers: NSEvent.ModifierFlags) {
        hotKey = HotKey(key: key, modifiers: modifiers)
        hotKey?.keyDownHandler = handler
    }

    static func parse(_ string: String) -> (Key, NSEvent.ModifierFlags)? {
        let parts = string.lowercased().split(separator: "+").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count >= 2 else { return nil }

        var modifiers: NSEvent.ModifierFlags = []
        var keyPart: String?

        for part in parts {
            switch part {
            case "cmd", "command": modifiers.insert(.command)
            case "opt", "option", "alt": modifiers.insert(.option)
            case "shift": modifiers.insert(.shift)
            case "ctrl", "control": modifiers.insert(.control)
            default: keyPart = part
            }
        }

        guard let keyString = keyPart, let key = keyFromString(keyString) else { return nil }
        return (key, modifiers)
    }

    private static func keyFromString(_ string: String) -> Key? {
        switch string {
        case "a": return .a
        case "b": return .b
        case "c": return .c
        case "d": return .d
        case "e": return .e
        case "f": return .f
        case "g": return .g
        case "h": return .h
        case "i": return .i
        case "j": return .j
        case "k": return .k
        case "l": return .l
        case "m": return .m
        case "n": return .n
        case "o": return .o
        case "p": return .p
        case "q": return .q
        case "r": return .r
        case "s": return .s
        case "t": return .t
        case "u": return .u
        case "v": return .v
        case "w": return .w
        case "x": return .x
        case "y": return .y
        case "z": return .z
        case "0": return .zero
        case "1": return .one
        case "2": return .two
        case "3": return .three
        case "4": return .four
        case "5": return .five
        case "6": return .six
        case "7": return .seven
        case "8": return .eight
        case "9": return .nine
        case "f1": return .f1
        case "f2": return .f2
        case "f3": return .f3
        case "f4": return .f4
        case "f5": return .f5
        case "f6": return .f6
        case "f7": return .f7
        case "f8": return .f8
        case "f9": return .f9
        case "f10": return .f10
        case "f11": return .f11
        case "f12": return .f12
        case "space": return .space
        case "escape", "esc": return .escape
        case "return", "enter": return .return
        case "tab": return .tab
        case "delete", "backspace": return .delete
        default: return nil
        }
    }
}
