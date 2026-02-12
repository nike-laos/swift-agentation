//
//  DebugAnnotationOverlay.swift
//  DebugAnnotationKit
//
//  Floating debug trigger + full-screen annotation overlay.
//  Tap the ant to capture a screenshot, place numbered pins, add notes,
//  and copy a structured markdown report to the clipboard.
//
//  License: MIT
//

#if DEBUG && os(iOS)
import SwiftUI
import UIKit

// MARK: - View Modifier

/// Attaches the debug annotation overlay to any view.
///
/// - Parameter appContext: An autoclosure returning key-value pairs that describe
///   your app's current state. These are included in the generated markdown report.
///   Example: `["screen": "Home", "loggedIn": "true"]`
struct DebugAnnotationModifier: ViewModifier {
    let appContext: () -> [String: String]
    @State private var annotationState = DebugAnnotationState()

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottomLeading) {
                if !annotationState.isActive {
                    DebugTriggerButton {
                        activateOverlay()
                    }
                }
            }
            .fullScreenCover(isPresented: $annotationState.isActive) {
                DebugAnnotationView(state: annotationState, appContext: appContext)
            }
    }

    private func activateOverlay() {
        annotationState.screenshot = DebugElementInspector.captureScreenshot()
        annotationState.pins = []
        annotationState.selectedPinId = nil
        annotationState.noteText = ""
        annotationState.isActive = true
    }
}

extension View {
    /// Adds a debug annotation overlay to this view.
    ///
    /// A small ant icon appears in the bottom-left corner (0.3 opacity).
    /// Tap it to capture a screenshot, place numbered pins, add notes,
    /// and copy a structured markdown report to the clipboard.
    ///
    /// Everything compiles out in Release builds (`#if DEBUG && os(iOS)`).
    ///
    /// - Parameter appContext: A closure returning key-value pairs describing
    ///   your app's current state, included in the markdown report.
    ///   Defaults to empty. Example:
    ///   ```swift
    ///   .debugAnnotation {
    ///       ["screen": viewModel.currentScreen, "user": authState.userId ?? "none"]
    ///   }
    ///   ```
    func debugAnnotation(appContext: @escaping () -> [String: String] = { [:] }) -> some View {
        modifier(DebugAnnotationModifier(appContext: appContext))
    }
}

// MARK: - Trigger Button

private struct DebugTriggerButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "ant")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(.white.opacity(0.3))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .padding(.leading, 4)
        .padding(.bottom, 4)
        .accessibilityLabel("Debug annotation")
    }
}

// MARK: - Annotation View

private struct DebugAnnotationView: View {
    @Bindable var state: DebugAnnotationState
    let appContext: () -> [String: String]
    @State private var copiedFeedback = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Screenshot image
            if let screenshot = state.screenshot {
                GeometryReader { geo in
                    let imageSize = screenshot.size
                    let scale = min(
                        geo.size.width / imageSize.width,
                        geo.size.height / imageSize.height
                    )
                    let displaySize = CGSize(
                        width: imageSize.width * scale,
                        height: imageSize.height * scale
                    )
                    let offset = CGSize(
                        width: (geo.size.width - displaySize.width) / 2,
                        height: (geo.size.height - displaySize.height) / 2
                    )

                    ZStack(alignment: .topLeading) {
                        Image(uiImage: screenshot)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: displaySize.width, height: displaySize.height)

                        // Pins
                        ForEach(state.pins) { pin in
                            PinView(
                                pin: pin,
                                isSelected: state.selectedPinId == pin.id
                            )
                            .position(
                                x: pin.point.x * scale,
                                y: pin.point.y * scale
                            )
                            .onTapGesture {
                                selectPin(pin)
                            }
                        }
                    }
                    .frame(width: displaySize.width, height: displaySize.height)
                    .offset(offset)
                    .contentShape(Rectangle())
                    .onTapGesture { location in
                        let imagePoint = CGPoint(
                            x: (location.x - offset.width) / scale,
                            y: (location.y - offset.height) / scale
                        )
                        guard imagePoint.x >= 0, imagePoint.x <= imageSize.width,
                              imagePoint.y >= 0, imagePoint.y <= imageSize.height else { return }
                        let info = DebugElementInspector.inspect(at: imagePoint)
                        state.addPin(at: imagePoint, elementInfo: info)
                    }
                }
            }

            // Bottom controls
            VStack {
                Spacer()
                BottomControlSheet(
                    state: state,
                    copiedFeedback: copiedFeedback,
                    onCopy: { copyReport() },
                    onDone: { dismiss() }
                )
            }
        }
    }

    private func selectPin(_ pin: AnnotationPin) {
        state.saveNoteToSelectedPin()
        state.selectedPinId = pin.id
        state.noteText = pin.note
    }

    private func copyReport() {
        state.saveNoteToSelectedPin()
        let markdown = DebugMarkdownGenerator.generate(
            pins: state.pins,
            appContext: appContext()
        )
        UIPasteboard.general.string = markdown
        copiedFeedback = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            copiedFeedback = false
        }
    }

    private func dismiss() {
        state.reset()
    }
}

// MARK: - Pin View

private struct PinView: View {
    let pin: AnnotationPin
    let isSelected: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.red)
                .frame(width: isSelected ? 32 : 26, height: isSelected ? 32 : 26)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)

            Text("\(pin.number)")
                .font(.system(size: isSelected ? 14 : 12, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

// MARK: - Bottom Control Sheet

private struct BottomControlSheet: View {
    @Bindable var state: DebugAnnotationState
    let copiedFeedback: Bool
    let onCopy: () -> Void
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            // Note editor for selected pin
            if let selectedId = state.selectedPinId,
               let pin = state.pins.first(where: { $0.id == selectedId }) {
                HStack {
                    Text("Pin \(pin.number)")
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.7))
                    Spacer()
                }

                TextField("Add a note...", text: $state.noteText)
                    .textFieldStyle(.roundedBorder)
                    .font(.callout)
                    .onSubmit {
                        state.saveNoteToSelectedPin()
                    }
            }

            // Action buttons
            HStack(spacing: 16) {
                Button(action: onCopy) {
                    HStack(spacing: 6) {
                        Image(systemName: copiedFeedback ? "checkmark" : "doc.on.doc")
                        Text(copiedFeedback ? "Copied!" : "Copy Report")
                    }
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(copiedFeedback ? Color.green.opacity(0.6) : Color.white.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button(action: onDone) {
                    Text("Done")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            // Pin count
            if !state.pins.isEmpty {
                Text("\(state.pins.count) pin\(state.pins.count == 1 ? "" : "s") placed")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}
#endif
