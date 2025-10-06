import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSCollectionViewDataSource, NSCollectionViewDelegate, NSCollectionViewDelegateDrop, NSCollectionViewKeyDelegate, NSDraggingDestination {

    var statusItem: NSStatusItem!
    var floatingPanel: NSPanel!
    var appListView: NSCollectionView!
    var managedApps: [NSRunningApplication] = []
    var preferencesWindowController: PreferencesWindowController?
    var isPanelVisible = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        setupStatusItem()
        setupFloatingPanel()
        setupAppMonitoring()
        loadPersistedApps()

        // Hide dock icon for menu bar utility
        NSApp.setActivationPolicy(.accessory)

        // Setup preferences defaults
        setupDefaultPreferences()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        savePersistedApps()
    }

    private func setupStatusItem() {
        // Check if status icon should be shown
        let showStatusIcon = UserDefaults.standard.bool(forKey: "ShowStatusIcon")

        if showStatusIcon {
            // Create status item
            statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

            // Set up the button with title and target/action
            if let button = statusItem.button {
                button.title = "App Manager"
                button.target = self
                button.action = #selector(togglePanel)
                updateStatusItemAppearance()
            }
        }
    }

    private func setupDefaultPreferences() {
        let defaults = UserDefaults.standard

        // Set default values if not already set
        if defaults.object(forKey: "ShowStatusIcon") == nil {
            defaults.set(true, forKey: "ShowStatusIcon")
        }
        if defaults.object(forKey: "AutoCollapseEnabled") == nil {
            defaults.set(false, forKey: "AutoCollapseEnabled")
        }
        if defaults.object(forKey: "AutoCollapseDelay") == nil {
            defaults.set(5, forKey: "AutoCollapseDelay")
        }
        if defaults.object(forKey: "PanelWidth") == nil {
            defaults.set(300, forKey: "PanelWidth")
        }
    }

    @objc private func togglePanel() {
        if isPanelVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    private func updateStatusItemAppearance() {
        if let button = statusItem.button {
            let arrow = isPanelVisible ? "▲" : "▼"
            button.title = "App Manager \(arrow)"
        }
    }

    private func setupFloatingPanel() {
        let panelWidth = CGFloat(UserDefaults.standard.integer(forKey: "PanelWidth"))

        // Create borderless panel
        floatingPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: 400),
            styleMask: [.nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        floatingPanel.level = .popUpMenu
        floatingPanel.isFloatingPanel = true
        floatingPanel.hasShadow = true
        floatingPanel.backgroundColor = NSColor.windowBackgroundColor.withAlphaComponent(0.95)
        floatingPanel.isOpaque = false

        // Create scroll view for app list
        let scrollView = NSScrollView(frame: floatingPanel.contentView!.bounds)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Create collection view for app items
        let flowLayout = NSCollectionViewFlowLayout()
        let panelWidth = CGFloat(UserDefaults.standard.integer(forKey: "PanelWidth"))
        flowLayout.itemSize = NSSize(width: panelWidth - 32, height: 50)
        flowLayout.minimumInteritemSpacing = 8
        flowLayout.minimumLineSpacing = 8
        flowLayout.sectionInset = NSEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        appListView = NSCollectionView(frame: scrollView.bounds)
        appListView.collectionViewLayout = flowLayout
        appListView.isSelectable = true
        appListView.allowsMultipleSelection = false
        appListView.backgroundColors = [.clear]
        appListView.translatesAutoresizingMaskIntoConstraints = false

        // Enable keyboard navigation
        appListView.keyDelegate = self

        // Register collection view item class
        appListView.register(AppCollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier("AppCollectionViewItem"))

        scrollView.documentView = appListView
        floatingPanel.contentView?.addSubview(scrollView)

        // Setup constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: floatingPanel.contentView!.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: floatingPanel.contentView!.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: floatingPanel.contentView!.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: floatingPanel.contentView!.trailingAnchor)
        ])

        // Setup drag and drop
        setupDragAndDrop()

        // Setup click outside to close
        setupClickOutsideToClose()
    }

    private func showPanel() {
        guard let statusItem = statusItem,
              let button = statusItem.button else { return }

        // Calculate panel position below the status item, handling multiple displays
        let buttonFrame = button.window!.frame
        let statusBarHeight: CGFloat = 22
        let panelWidth = CGFloat(UserDefaults.standard.integer(forKey: "PanelWidth"))
        let panelHeight: CGFloat = 400

        // Get the screen containing the status item
        let screen = NSScreen.screens.first { screen in
            screen.frame.contains(buttonFrame.origin)
        } ?? NSScreen.main!

        // Calculate position, ensuring panel stays within screen bounds
        var panelX = buttonFrame.origin.x - panelWidth / 2
        var panelY = buttonFrame.origin.y - statusBarHeight - panelHeight

        // Adjust for screen bounds
        if panelX < screen.visibleFrame.origin.x {
            panelX = screen.visibleFrame.origin.x
        } else if panelX + panelWidth > screen.visibleFrame.origin.x + screen.visibleFrame.width {
            panelX = screen.visibleFrame.origin.x + screen.visibleFrame.width - panelWidth
        }

        if panelY < screen.visibleFrame.origin.y {
            // If not enough space below, position above the status item
            panelY = buttonFrame.origin.y + buttonFrame.height
        }

        let panelFrame = NSRect(
            x: panelX,
            y: panelY,
            width: panelWidth,
            height: panelHeight
        )

        floatingPanel.setFrame(panelFrame, display: false, animate: false)

        // Animate in
        floatingPanel.alphaValue = 0.0
        floatingPanel.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            floatingPanel.animator().alphaValue = 1.0
        }

        isPanelVisible = true
        updateStatusItemAppearance()
        showAllManagedApps()
    }

    private func hidePanel() {
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            floatingPanel.animator().alphaValue = 0.0
        } completionHandler: {
            self.floatingPanel.orderOut(nil)
            self.isPanelVisible = false
            self.updateStatusItemAppearance()
            self.hideAllManagedApps()
        }
    }

    private func setupClickOutsideToClose() {
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
            if self.isPanelVisible {
                let panelFrame = self.floatingPanel.frame
                let clickLocation = NSEvent.mouseLocation

                // Check if click is outside the panel
                if !panelFrame.contains(clickLocation) {
                    DispatchQueue.main.async {
                        self.hidePanel()
                    }
                }
            }
        }
    }

    private func setupDragAndDrop() {
        // Register for drag types
        appListView.registerForDraggedTypes([.fileURL, .string])

        // Set up as drag destination
        appListView.setDraggingSourceOperationMask(.copy, forLocal: false)
    }

    private func setupAppMonitoring() {
        // Monitor for app launches and terminations
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch(_:)),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidTerminate(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
    }

    @objc private func appDidLaunch(_ notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            // Check if this app was in our persisted list
            loadPersistedApps()
        }
    }

    @objc private func appDidTerminate(_ notification: Notification) {
        if let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
            // Remove terminated app from managed list
            managedApps.removeAll { $0.bundleIdentifier == app.bundleIdentifier }
            updateAppListView()
            savePersistedApps()
        }
    }

    private func loadPersistedApps() {
        let defaults = UserDefaults.standard
        let bundleIDs = defaults.stringArray(forKey: "ManagedAppBundleIDs") ?? []

        managedApps = bundleIDs.compactMap { bundleID in
            NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first
        }

        updateAppListView()
    }

    private func savePersistedApps() {
        let bundleIDs = managedApps.compactMap { $0.bundleIdentifier }
        UserDefaults.standard.set(bundleIDs, forKey: "ManagedAppBundleIDs")
    }

    private func updateAppListView() {
        DispatchQueue.main.async {
            self.appListView.reloadData()
        }
    }

    private func showAllManagedApps() {
        for app in managedApps {
            if !app.isHidden {
                app.activate(options: [.activateIgnoringOtherApps])
            } else {
                app.unhide()
            }
        }
    }

    private func hideAllManagedApps() {
        for app in managedApps {
            app.hide()
        }
    }

    // MARK: - NSCollectionViewDataSource & Delegate

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return managedApps.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("AppCollectionViewItem"), for: indexPath) as! AppCollectionViewItem
        let app = managedApps[indexPath.item]
        item.configure(with: app)
        return item
    }

    // MARK: - NSCollectionViewKeyDelegate

    func collectionView(_ collectionView: NSCollectionView, keyDown event: NSEvent) -> Bool {
        switch event.keyCode {
        case 36: // Return key
            if let selectedIndex = collectionView.selectionIndexPaths.first?.item {
                let app = managedApps[selectedIndex]
                app.activate(options: [.activateIgnoringOtherApps])
                return true
            }
        case 51: // Delete key
            if !collectionView.selectionIndexPaths.isEmpty {
                let indexesToRemove = collectionView.selectionIndexPaths.map { $0.item }
                for index in indexesToRemove.sorted(by: >) {
                    managedApps.remove(at: index)
                }
                updateAppListView()
                savePersistedApps()
                return true
            }
        default:
            break
        }
        return false
    }

    // MARK: - NSCollectionViewDelegateDrop (for reordering)

    func collectionView(_ collectionView: NSCollectionView, canDragItemsAt indexes: IndexSet, with event: NSEvent) -> Bool {
        return true
    }

    func collectionView(_ collectionView: NSCollectionView, pasteboardWriterForItemAt index: Int) -> NSPasteboardWriting? {
        return managedApps[index]
    }

    func collectionView(_ collectionView: NSCollectionView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forItemsAt indexes: IndexSet) {
        // Set up dragging pasteboard for internal reordering
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setString(String(indexes.first!), forType: .string)
        session.draggingPasteboard.clearContents()
        session.draggingPasteboard.writeObjects([pasteboardItem])
    }

    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation: UnsafeMutablePointer<NSCollectionView.DropOperation>) -> NSDragOperation {
        if draggingInfo.draggingSource as? NSCollectionView === collectionView {
            dropOperation.pointee = .on
            return .move
        }
        return .copy
    }

    func collectionView(_ collectionView: NSCollectionView, acceptDrop draggingInfo: NSDraggingInfo, indexPath: IndexPath, dropOperation: NSCollectionView.DropOperation) -> Bool {
        if draggingInfo.draggingSource as? NSCollectionView === collectionView {
            // Handle internal reordering
            if let sourceIndexString = draggingInfo.draggingPasteboard.string(forType: .string),
               let sourceIndex = Int(sourceIndexString) {
                let targetIndex = indexPath.item
                reorderApps(from: sourceIndex, to: targetIndex)
                return true
            }
        }
        return false
    }

    private func reorderApps(from sourceIndex: Int, to targetIndex: Int) {
        let app = managedApps.remove(at: sourceIndex)
        managedApps.insert(app, at: targetIndex)
        updateAppListView()
        savePersistedApps()
    }

    // MARK: - NSDraggingDestination

    func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }

    func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard

        // Check for file URLs (apps dragged from Finder)
        if let fileURLs = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in fileURLs {
                if url.pathExtension == "app" {
                    addAppFromURL(url)
                    return true
                }
            }
        }

        // Check for bundle identifiers (apps dragged from other sources)
        if let bundleIDs = pasteboard.readObjects(forClasses: [NSString.self], options: nil) as? [String] {
            for bundleID in bundleIDs {
                if let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
                    addApp(app)
                    return true
                }
            }
        }

        return false
    }

    private func addAppFromURL(_ url: URL) {
        let bundleID = Bundle(url: url)?.bundleIdentifier
        if let bundleID = bundleID,
           let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first {
            addApp(app)
        }
    }

    private func addApp(_ app: NSRunningApplication) {
        // Check if app is already in the list
        guard !managedApps.contains(where: { $0.bundleIdentifier == app.bundleIdentifier }) else {
            return
        }

        managedApps.append(app)
        updateAppListView()
        savePersistedApps()
    }

    @objc private func showPreferences() {
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }

        preferencesWindowController?.showWindow(nil)
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
    }
}