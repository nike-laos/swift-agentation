//
//  DebugMarkdownGenerator.swift
//  DebugAnnotationKit
//
//  Generates structured markdown bug reports from annotation pins.
//  Paste into GitHub issues, Slack, Notes, etc.
//
//  License: MIT
//

#if DEBUG && os(iOS)
import UIKit

enum DebugMarkdownGenerator {

    /// Generate a markdown report from annotation pins.
    /// - Parameters:
    ///   - pins: The annotation pins placed by the user.
    ///   - appContext: Optional key-value pairs describing app state (e.g. ["screen": "Home", "loggedIn": "true"]).
    static func generate(pins: [AnnotationPin], appContext: [String: String] = [:]) -> String {
        var lines: [String] = []

        lines.append("## Debug Report")
        lines.append("**Device:** \(deviceDescription)")
        if !appContext.isEmpty {
            let state = appContext.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ", ")
            lines.append("**App State:** \(state)")
        }
        lines.append("**Date:** \(formattedDate)")
        lines.append("")

        if pins.isEmpty {
            lines.append("_No annotations._")
        } else {
            lines.append("### Annotations")
            for pin in pins {
                let coords = "(\(Int(pin.point.x)), \(Int(pin.point.y)))"
                let element: String
                if let info = pin.elementInfo {
                    let label = info.accessibilityLabel.map { " \"\($0)\"" } ?? ""
                    element = "\(info.className)\(label)"
                } else {
                    element = "(no element)"
                }
                lines.append("\(pin.number). \(coords) — \(element)")

                if let info = pin.elementInfo {
                    let f = info.frame
                    lines.append("   Frame: (\(Int(f.origin.x)), \(Int(f.origin.y)), \(Int(f.width)), \(Int(f.height)))")
                    lines.append("   Traits: \(info.traits)")
                }

                if !pin.note.isEmpty {
                    lines.append("   Note: \"\(pin.note)\"")
                }

                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Private

    private static var deviceDescription: String {
        let device = UIDevice.current
        let name = device.name
        let system = "\(device.systemName) \(device.systemVersion)"
        return "\(name), \(system)"
    }

    private static var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: Date())
    }
}
#endif
