import Cocoa

class PreferencesWindowController: NSWindowController {

    @IBOutlet weak var autoCollapseCheckbox: NSButton!
    @IBOutlet weak var autoCollapseDelayField: NSTextField!
    @IBOutlet weak var panelWidthField: NSTextField!
    @IBOutlet weak var showStatusIconCheckbox: NSButton!

    override var windowNibName: NSNib.Name? {
        return NSNib.Name("PreferencesWindow")
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        loadSettings()
    }

    @IBAction func saveSettings(_ sender: Any) {
        saveSettingsToDefaults()
        window?.close()
    }

    @IBAction func cancelSettings(_ sender: Any) {
        window?.close()
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard

        autoCollapseCheckbox.state = defaults.bool(forKey: "AutoCollapseEnabled") ? .on : .off
        autoCollapseDelayField.integerValue = defaults.integer(forKey: "AutoCollapseDelay")
        panelWidthField.integerValue = defaults.integer(forKey: "PanelWidth")
        showStatusIconCheckbox.state = defaults.bool(forKey: "ShowStatusIcon") ? .on : .off
    }

    private func saveSettingsToDefaults() {
        let defaults = UserDefaults.standard

        defaults.set(autoCollapseCheckbox.state == .on, forKey: "AutoCollapseEnabled")
        defaults.set(autoCollapseDelayField.integerValue, forKey: "AutoCollapseDelay")
        defaults.set(panelWidthField.integerValue, forKey: "PanelWidth")
        defaults.set(showStatusIconCheckbox.state == .on, forKey: "ShowStatusIcon")
    }
}
