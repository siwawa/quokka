package com.example.quokka // Update with your package name

import android.accessibilityservice.AccessibilityService
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityEvent
import android.util.Log

class MacroAccessibilityService : AccessibilityService() {

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("MacroAccessibilityService", "Accessibility Service connected.")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) {
            Log.d("MacroAccessibilityService", "Received null event.")
            return
        }

        // Log event details
        Log.d(
            "MacroAccessibilityService",
            "Event received: ${AccessibilityEvent.eventTypeToString(event.eventType)} from package: ${event.packageName}"
        )

        // Only process events from the target app
        if (event.packageName != "com.jype.fans") {
            Log.d("MacroAccessibilityService", "Event ignored. Source package: ${event.packageName}")
            return
        }

        // Get the root node of the current window
        val rootNode = rootInActiveWindow ?: run {
            Log.d("MacroAccessibilityService", "Root node is null. Skipping event.")
            return
        }

        // Perform actions based on the target elements
        performClickByText(rootNode, "Stray Kids") // Click "Stray Kids"
        performClickByText(rootNode, "이벤트") // Click "이벤트"
        performClickByText(rootNode, "[2024.12.31] 2024 MBC 가요대제전 참여 안내") // Click "2024 MBC..."
        performClickByText(rootNode, "신청마감") // Click "신청마감"
    }

    override fun onInterrupt() {
        Log.d("MacroAccessibilityService", "Accessibility Service interrupted.")
    }

    // Helper method to find and click a node by text
    private fun performClickByText(rootNode: AccessibilityNodeInfo, text: String) {
        val nodes = rootNode.findAccessibilityNodeInfosByText(text)
        if (nodes.isEmpty()) {
            Log.d("MacroAccessibilityService", "No nodes found with text: $text")
        }

        for (node in nodes) {
            if (node.isClickable) {
                val clicked = node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                if (clicked) {
                    Log.d("MacroAccessibilityService", "Clicked on node with text: $text")
                } else {
                    Log.d("MacroAccessibilityService", "Failed to click node with text: $text")
                }
                return
            }
        }
        Log.d("MacroAccessibilityService", "Node with text '$text' not found or not clickable.")
    }

    // Optional: Helper method to click by bounds (if text is not reliable)
    private fun performClickByBounds(rootNode: AccessibilityNodeInfo, bounds: IntArray) {
        rootNode.refresh()
        if (rootNode.childCount > 0) {
            for (i in 0 until rootNode.childCount) {
                val child = rootNode.getChild(i) ?: continue
                val rect = android.graphics.Rect()
                child.getBoundsInScreen(rect)
                if (rect.contains(bounds[0], bounds[1])) {
                    if (child.isClickable) {
                        val clicked = child.performAction(AccessibilityNodeInfo.ACTION_CLICK)
                        if (clicked) {
                            Log.d(
                                "MacroAccessibilityService",
                                "Clicked on node within bounds: ${bounds.joinToString()}"
                            )
                        } else {
                            Log.d(
                                "MacroAccessibilityService",
                                "Failed to click node within bounds: ${bounds.joinToString()}"
                            )
                        }
                        return
                    }
                }
                performClickByBounds(child, bounds) // Recursively search
            }
        }
    }

    // Optional utility method to get event type as string (for better logging)
    companion object {
        fun AccessibilityEvent.eventTypeToString(eventType: Int): String {
            return when (eventType) {
                AccessibilityEvent.TYPE_VIEW_CLICKED -> "TYPE_VIEW_CLICKED"
                AccessibilityEvent.TYPE_VIEW_FOCUSED -> "TYPE_VIEW_FOCUSED"
                AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> "TYPE_WINDOW_STATE_CHANGED"
                AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED -> "TYPE_WINDOW_CONTENT_CHANGED"
                else -> "UNKNOWN"
            }
        }
    }
}
