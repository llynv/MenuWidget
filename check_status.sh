#!/bin/bash

echo "=== MenuWidget Status Check ==="
echo ""

# Check if app is running
if pgrep -x "MenuWidget" > /dev/null; then
    echo "✓ MenuWidget is running (PID: $(pgrep -x MenuWidget))"
else
    echo "✗ MenuWidget is NOT running"
    exit 1
fi

echo ""
echo "=== What to look for ==="
echo "1. Look at the TOP-RIGHT of your screen in the menu bar"
echo "2. Search for text that says 'App Manager ▼'"
echo "3. It should be near the clock/date"
echo ""
echo "=== If you don't see it ==="
echo "The menu bar might be crowded. Try:"
echo "- Hiding other menu bar items temporarily"
echo "- Looking carefully - it's text-based, not an icon"
echo "- Checking if macOS is hiding it (Command+drag to rearrange menu bar items)"
echo ""
echo "=== Opening Activity Monitor to verify ==="
open -a "Activity Monitor"
sleep 1
osascript -e 'tell application "Activity Monitor"
    activate
    tell application "System Events"
        keystroke "f" using command down
        keystroke "MenuWidget"
    end tell
end tell' 2>/dev/null

echo ""
echo "Check Activity Monitor - MenuWidget should be listed"

