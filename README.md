# App Manager - macOS Menu Bar Utility

A macOS menu bar utility that allows you to manage application visibility by showing/hiding multiple applications with a single click.

## Features

### Core Functionality
- **Menu Bar Integration**: Runs as a status item in the macOS menu bar (no dock icon)
- **Application Management**: Maintains a list of managed applications
- **Show/Hide Toggle**: Click the menu bar item to show/hide all managed applications
- **Drag & Drop Support**: Drag applications from Finder or other sources to add them to the managed list
- **Draggable Reordering**: Reorder applications within the panel by dragging

### User Interface
- **Floating Panel**: Semi-transparent panel that appears below the menu bar
- **Application Icons**: Each managed app displays its icon and name
- **Animations**: Smooth fade and slide animations for panel appearance
- **Auto-collapse**: Panel closes when clicking outside of it
- **Scrolling**: Supports many applications with scrollable list

### Persistence & Settings
- **Persistent Storage**: App list is saved to UserDefaults and restored on launch
- **Preferences Window**: Configure panel width, auto-collapse settings, and status icon visibility
- **Smart Validation**: Automatically removes terminated applications from the list

### Advanced Features
- **Multiple Display Support**: Panel positioning adapts to different screen configurations
- **Keyboard Navigation**: Navigate with arrow keys, activate apps with Return, remove with Delete
- **Accessibility**: Proper accessibility labels and keyboard support
- **App Monitoring**: Automatically detects app launches and terminations

## Usage

1. **Adding Applications**:
   - Drag applications from Finder onto the floating panel
   - Or drag from other locations that support app dragging

2. **Managing Applications**:
   - Click the menu bar item to toggle show/hide all managed apps
   - Double-click an app in the panel to activate it
   - Drag apps within the panel to reorder
   - Select and press Delete to remove apps from the list

3. **Preferences**:
   - Open Preferences from the main menu (App → Preferences...)
   - Configure panel width, auto-collapse settings, and status icon visibility

## Keyboard Shortcuts

- **Arrow Keys**: Navigate through the application list
- **Return**: Activate the selected application
- **Delete**: Remove selected applications from the list
- **Cmd+,**: Open preferences window

## Technical Details

### Architecture
- Built with Swift and AppKit
- Uses NSStatusItem for menu bar integration
- NSPanel for the floating interface
- NSCollectionView for the application list
- NSRunningApplication for app management
- UserDefaults for persistence

### System Integration
- Monitors NSWorkspace notifications for app lifecycle events
- Handles multiple displays and screen configurations
- Respects macOS accessibility guidelines
- Uses proper activation policies for menu bar utilities

### Edge Cases Handled
- Applications that are force-quit or terminated
- Multiple display configurations
- Screen boundary detection for panel positioning
- Invalid or corrupted application data

## Building

This project is designed as a standard Xcode macOS AppKit project. To build:

1. Open the project in Xcode
2. Select the macOS App target
3. Build and run (Cmd+R)

## Requirements

- macOS 10.15 or later
- Xcode 11.0 or later
- Swift 5.0 or later

## License

This project is provided as-is for educational and development purposes.