import Cocoa

class AppCollectionViewItem: NSCollectionViewItem, NSDraggingSource {

    private var appIconView: NSImageView!
    private var appNameLabel: NSTextField!

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 50))
        view.wantsLayer = true
        view.layer?.cornerRadius = 8
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.8).cgColor

        setupViews()
    }

    private func setupViews() {
        // Icon view
        appIconView = NSImageView(frame: NSRect(x: 8, y: 8, width: 32, height: 32))
        appIconView.imageScaling = .scaleProportionallyDown
        view.addSubview(appIconView)

        // Name label
        appNameLabel = NSTextField(frame: NSRect(x: 48, y: 14, width: 224, height: 22))
        appNameLabel.isEditable = false
        appNameLabel.isBordered = false
        appNameLabel.backgroundColor = .clear
        appNameLabel.font = NSFont.systemFont(ofSize: 14)
        appNameLabel.textColor = .labelColor
        view.addSubview(appNameLabel)
    }

    func configure(with app: NSRunningApplication) {
        appIconView.image = app.icon
        appNameLabel.stringValue = app.localizedName ?? "Unknown App"
        representedObject = app

        // Set accessibility properties
        view.setAccessibilityLabel("Application: \(app.localizedName ?? "Unknown")")
        view.setAccessibilityRole(.button)
        view.setAccessibilitySubrole(.applicationDockItem)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)

        if event.clickCount == 2 {
            // Double-click to activate app
            if let app = representedObject as? NSRunningApplication {
                app.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }

    // Drag and drop support
    override var draggingImageComponents: [NSDraggingImageComponent] {
        let component = NSDraggingImageComponent(key: NSDraggingItem.ImageComponentKey.icon)
        component.contents = appIconView.image
        component.frame = NSRect(x: 0, y: 0, width: 32, height: 32)
        return [component]
    }

    override func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return .move
    }

    override func mouseDragged(with event: NSEvent) {
        let dragItem = NSDraggingItem(pasteboardWriter: representedObject as Any)

        // Set the dragging frame to the bounds of the view
        dragItem.draggingFrame = view.bounds

        // Set the image components for dragging
        let component = NSDraggingImageComponent(key: NSDraggingItem.ImageComponentKey.icon)
        component.contents = appIconView.image
        component.frame = NSRect(x: 0, y: 0, width: 32, height: 32)
        dragItem.imageComponentsProvider = { return [component] }

        // Begin dragging session
        beginDraggingSession(with: [dragItem], event: event, source: self)
    }

    // MARK: - NSDraggingSource

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        switch context {
        case .withinApplication:
            return .move
        default:
            return .copy
        }
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        // Handle drag completion if needed
    }
}