//
//  DebugElementInspector.swift
//  DebugAnnotationKit
//
//  UIKit hit-testing to identify views backing SwiftUI elements.
//  Extracts class name, accessibility label, frame, and traits.
//
//  License: MIT
//

#if DEBUG && os(iOS)
import UIKit

enum DebugElementInspector {

    /// Hit-test the key window at the given screen-coordinate point.
    static func inspect(at point: CGPoint) -> ElementInfo? {
        guard let window = keyWindow else { return nil }
        guard let hitView = window.hitTest(point, with: nil) else { return nil }
        return elementInfo(for: hitView)
    }

    /// Capture a screenshot of the key window.
    static func captureScreenshot() -> UIImage? {
        guard let window = keyWindow else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: window.bounds)
        return renderer.image { ctx in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: false)
        }
    }

    // MARK: - Private

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }
    }

    private static func elementInfo(for view: UIView) -> ElementInfo {
        let className = String(describing: type(of: view))
        let label = view.accessibilityLabel
        let frame = view.convert(view.bounds, to: nil)
        let traits = readableTraits(view.accessibilityTraits)
        return ElementInfo(
            className: className,
            accessibilityLabel: label,
            frame: frame,
            traits: traits
        )
    }

    private static func readableTraits(_ traits: UIAccessibilityTraits) -> String {
        var parts: [String] = []
        if traits.contains(.button) { parts.append("button") }
        if traits.contains(.link) { parts.append("link") }
        if traits.contains(.header) { parts.append("header") }
        if traits.contains(.image) { parts.append("image") }
        if traits.contains(.staticText) { parts.append("staticText") }
        if traits.contains(.adjustable) { parts.append("adjustable") }
        if traits.contains(.selected) { parts.append("selected") }
        if traits.contains(.notEnabled) { parts.append("notEnabled") }
        return parts.isEmpty ? "none" : parts.joined(separator: ", ")
    }
}
#endif
