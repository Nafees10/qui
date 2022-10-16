# QUI Documentation

This guide will help you understand how to write/use QUI widgets.

# QWidget properties

Every Widget is a class that inherits the `QWidget` class from `qui.qui`.

## Protected

* `uint _minWidth` - Minimum width specifier. Accessed through setter/getter
* `uint _maxWdith` - Maximum width specifier. Accessed through setter/getter
* `uint _minHeight` - Minimum height specifier. Accessed through setter/getter
* `uint _maxHeight` - Maximum height specifier. Accessed through setter/getter
* `uint viewportX` _(read only)_ - how many columns, from left, are out of view.  
	Use this to optimise drawing by only drawing visible portion.
* `uint viewportY` _(read only)_ - how many rows, from top, are out of view.  
	Use this to optimise drawing by only drawing visible portion.
* `uint viewportWidth` _(read only)_ - how many rows are visible.
* `uint viewportHeight` _(read only)_ - how many columns are visible.
* `requestScrollX(uint)` - Request parent to scroll on X coordinates
* `requestScrollY(uint)` - Request parent to scroll on Y coordinates
* `requestCursorPos(x, y)` - Request parent to draw cursor at x, y. or hide if they are negative

## Public

* `bool isActive` _(read only)_ - If this is currently the focused widget.
	i.e: all keyboard input will be directed towards it.
* `uint eventSub` _(read only)_ - Flags for which Events this Widget subscribes to.
	`&` with EventMask members to read.
* `uint sizeRatio` - When sizing widgets, what ratio of parent's size to be assigned.  
	Setter triggers a resize event.
* `bool show` - Whether this widget is visible or not.
	Any widget not visible cannot become active widget. Setter triggers a resize event.
* `uint scrollX` - How many columns have been scrolled.
* `uint scrollY` - How many rows have been scrolled.
* `uint width` - Width of this widget. Setter triggers a resize event.
* `uint height` - Height of this widget. Setter triggers a resize event.
* `uint minWidth` - Minimum width. Setter triggers a resize event.
* `uint maxWdith` - Maximum width. Setter triggers a resize event.
* `uint minHeight` - Minimum height. Setter triggers a resize event.
* `uint maxHeight` - Maximum height. Setter triggers a resize event.

# Events

All event functions are boolean functions. They must return true if the Widget handled the event, else, false.  

An example can be: a number input widget, must return true on its keyboard event function, when they key is pressed and is a digit. in all other cases, it must return false.  

## Event Subscribing

By default, no event handler functions of a QWidget inheriting class will be called.  
A widget must subscribe to events.  
This can be done by calling the protected `eventSubscribe(uint sub)` function, where
sub is constructed by OR-ing together EventMask members, corresponding to the
desired events.  

For example, to receive Mouse Click and Resize events, you could do following in constructor:
```D
this(){
	...
	eventSubscribe(EventMask.MousePress | EventMask.Resize);
	...
}
```

## `bool initialize()`
Called when the event loop is starting.

## `bool mouseEvent(MouseEvent)`
Called when a mouse event occurs while the mouse cursor was on top of this widget.  

The coordinates in MouseEvent are relative to top-left (0,0) corner of this widget.

## `bool keyboardEvent(KeyboardEvent, bool)`
Called when this widget is the active widget, and a keyboard event occurs.  

It also receives a flag, which is true in case the parent wants to cycle
focus to next possible active widget. In most scenarios, you will want to do nothing
and `return false` in case the flag is true.  

Note that by returning false, whether or not the flag is true, will move focus away
from this widget.

## `bool resizeEvent()`
Called when the parent underwent resizing, and this widget may have been resized as
well.  

Whether or not you subscribe to this event, a resize will automatically request an
update event from parent, in case your widget is subscribed to updates.

## `bool scrollEvent()`
Called when the parent this widget resides in, has been scrolled.  

Whether or not you subscribe to this event, a resize will automatically request an
update event from parent, in case your widget is subscribed to updates.

## `bool activateEvent(bool)`
This is called whenever this widget is made the active widget, or is un-made the
active widget.  

If it was made the active widget, the flag will be true, else it will be false.

## `bool timerEvent(uint msecs)`
Called every time `msecs` amount of milliseconds have passed.

## `bool updateEvent()`
This is the event in which your widget shold draw itself.  

This event is not triggered directly by user action, though resize or scroll event will
request this from parent.  

When your widget has to redraw, it should call the protected `requestUpdate()` function.

# Custom Event Handlers

In case you are not writing a widget, but using one, and you want a function to be called each time a specific event handler for a widget is called, you can use custom events.  

These can be assigned like:  
```D
QWidget.onInitEvent = delegate(QWidget callerWidget){
	// do stuff
	return false; // return true in case you dont want the event handler of widget to be called
}
QWidget.onTimerEvent = delegate(QWidget callerWidget, uint msecs){
	// do stuff
	return false;
}
QWidget.onMouseEvent = delegate(QWidget callerWidget, MouseEvent mouse){
	// do stuff
	return false;
}
```
All events can be assigned custom event handlers in this manner.  

These functions are called before the event handler of that widget is called. And if the custom handler returns true, the event is dropped and the event handler for widget is **not** called.  

# Drawing on Terminal

The `update()` delegate of a widget is called by it's parent widget each time the widget should re-draw itself.
The parent widget only calls this function if the widget has previously called `this.requestUpdate`.  

Each QWidget class has these protected delegates, which can be used to write:

## `bool isWritable(uint x, uint y)`
This will return true if a widget can write at x, y.

Visible area is (`[inclusive .. exclusive]`):  

* `x: [ viewportX .. viewportX + viewportWidth ]`
* `y: [ viewportY .. viewportY + viewportHeight ]`

## `void moveTo(uint x, uint y)`
This will try to move the seek to x, y. So the next write happens at x, y.  

## `bool write(dchar c, Color foreground, Color background)`
This will write character c, with colors, at current seek.  

Seek is incremented. It will wrap over to next row if it was the last column
of current row.

It returns true if it was written, or false if it was outside writing area

## `uint write(dstring s, Color foreground, Color background)`
Same as the above write. but this one writes a dstring.

The number of characters written is returned.

## `uint fillLine(dchar c, Color foreground, Color background, uint max = 0)`
Starting at seek, write a maximum of `max` number of character `c`.  

`max` is ignored if 0. It writes till either `max` is met, or the current
line/row is filled.

