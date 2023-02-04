# QParent

This is to be used as a base class for creating containers or parent widgets.

It provides several functions to access private properties of a child widget.

## Events

These events, on top of the ones from QWidget, are available to QParent.

### `disownEvent(QWidget)`
Called right before this is made to disown a child.

## Functions

All these functions first perform a check to make sure the child widget is
a child of the QParent calling the function.

### `final widgetPositionX(QWidget, uint)`
Sets the position along x coordinate of a child widget.

### `final widgetPositionY(QWidget, uint)`
Sets the position along y coordinate of a child widget.

### `final widgetPosition(QWidget, uint x, uint y)`
Sets the position along x and y coordinate of a child widget.

### `final bool widgetSizeWidth(QWidget, uint)`
Attempts to set the width of a child widget. If the width is constrained, 
appropriate value will be selected.

Returns true if paramter value (a.k.a natural size) was used, false if a
constrained value was used.

### `final bool widgetSizeHeight(QWidget, uint)`
Attempts to set the height of a child widget. If the height is constrained, 
appropriate value will be selected.

Returns true if paramter value (a.k.a natural size) was used, false if a
constrained value was used.

### `final bool widgetSize(QWidget, uint width, uint height)`
Sets both width and height of widget.

Returns true if paramter values were used, false if constrained values were
used.

### `final bool widgetViewportAssign(QWidget, width, height, scrollX, scrollY)`
Assigns viewport to a child, of size width x height. The default width & height
of 0 will cause it to use the widget's own width & height.

scrollX and scrollY can be used to add to the x and y offsets in the viewport,
which can give an effect of scrolling to the child widget.

### `final adopt(QWidget)`
Adopts a widget. If the widget currently has a parent, the current parent will
disown it, the current parent's disown event will be called, and the child's
`adoptEvent(false)` will be called.

Child's `adoptEvent(true)` will be called at end.

### `final bool disown(QWidget)`
Disowns a widget. Will return false if the widget is its child.
The widget's viewport will be reset, caller's disownEvent will be called, and
child's `adoptEvent(false)` will be called.

## Event Triggers
The following functions are used to send events to child widget.
As usual, they perform a check to ensure the caller is the child's parent, if
not, they return false.

In the case the event is sent, the return value is what was returned from the
child.

Any appropriate custom event on the child is called before calling the event
handler function.

For description on what these events are, see `docs/events.md`

* `bool adoptEventCall(QWidget, bool)`
* `bool mouseEventCall(QWidget, MouseEvent)`
* `bool keyboardEventCall(QWidget, KeyboardEvent, bool)`
* `bool resizeEventCall(QWidget)`
* `bool scrollEventCall(QWidget)`
* `bool activateEvent(QWidget, bool)`
* `bool timerEventCall(QWidget, uint)`
* `bool updateEventCall(QWidget)`
