//
//  DebugAnnotationState.swift
//  DebugAnnotationKit
//
//  Drop-in debug annotation overlay for any SwiftUI iOS app.
//  Capture screenshots, place numbered pins, add notes, copy markdown reports.
//
//  Usage: See README.md
//  License: MIT
//

#if DEBUG && os(iOS)
import SwiftUI
import Observation
import UIKit

@Observable
class DebugAnnotationState {
    var isActive = false
    var screenshot: UIImage?
    var pins: [AnnotationPin] = []
    var selectedPinId: UUID?
    var noteText = ""

    func addPin(at point: CGPoint, elementInfo: ElementInfo?) {
        let pin = AnnotationPin(
            number: pins.count + 1,
            point: point,
            elementInfo: elementInfo
        )
        pins.append(pin)
        selectedPinId = pin.id
        noteText = ""
    }

    func saveNoteToSelectedPin() {
        guard let id = selectedPinId,
              let index = pins.firstIndex(where: { $0.id == id }) else { return }
        pins[index].note = noteText
    }

    func reset() {
        isActive = false
        screenshot = nil
        pins = []
        selectedPinId = nil
        noteText = ""
    }
}

struct AnnotationPin: Identifiable {
    let id = UUID()
    let number: Int
    let point: CGPoint
    let elementInfo: ElementInfo?
    var note: String = ""
}

struct ElementInfo {
    let className: String
    let accessibilityLabel: String?
    let frame: CGRect
    let traits: String
}
#endif
