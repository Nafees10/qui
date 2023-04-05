# QUI Widgets

This document will help you understand how to write/use QUI widgets.

## Protected

These are never accessed directly outside of the QWidget class,
only through their respective getters:
* `uint _minWidth` - Minimum width specifier. Accessed through setter/getter
* `uint _maxWdith` - Maximum width specifier. Accessed through setter/getter
* `uint _minHeight` - Minimum height specifier. Accessed through setter/getter
* `uint _maxHeight` - Maximum height specifier. Accessed through setter/getter

The following can be used to send requests to the parent widget this widget
resides in, only if this widget is the active widget:
* `bool scrollToX(uint)` - Request parent to scroll to an X coordinate
* `bool scrollToY(uint)` - Request parent to scroll to an Y coordinate
* `void cursorPos(x, y)` - Request parent to draw cursor at x, y.
	Sending negative values for either x or y will hide the cursor.

The following work even if this widget is not the active widget:
* `bool update()` - requests parent to update this widget. Without calling
	this, the `updateEvent` will never occur.
* `bool resize()` - requests parent to resize widgets. This should be called
	when the widget wishes to be resized. **Do not call in a resizeEvent**

The `view` property, of type `Viewport`, can be used to draw on the area
designated to the widget. See `docs/viewport.md`.

Event handling functions are also protected. See `docs/events.md`

## Public

Functions:
* `bool heightConstraint(uint min, uint max)` - For setting min/maxHeight
* `bool widthConstraint(uint min, uint max)` - For setting min/maxWidth
* `bool sizeConstraint(minWidth, maxWidth, minHeight, maxHeight)`

Properties:
* `uint width` _final_ - Width of this widget.
* `uint height` _final_ - Height of this widget.
* `uint minWidth` - Minimum width.
* `uint maxWdith` - Maximum width.
* `uint minHeight` - Minimum height.
* `uint maxHeight` - Maximum height.
* `bool heightConstrained` _final_ - Whether the min/max height constraints
	apply. This is determined by if either min/max is non-zero, and if both are
	non-zero, then `min <= max`
* `bool widthConstrained` _final_ - Same as heightConstrained but for width.
* `bool sizeConstrained` _final_ - if either width or height is constrained.
* `bool wantsFocus` - Should return true if this widget wants keyboard input.
	By default it always returns false, should be overrided accordingly.

