# QUI Events

All event functions are protected boolean functions. They must return true if
the Widget handled the event, else, false.

This is especially useful for keyboard events. Where returning false will give
up focus, and the parent will look for another widget to send further keyboard
input to.

## `bool adoptEvent(bool)`
Called when this widget is adopted by a parent, or disowned. The boolean flag
will be true when it is adopted, false when disowned.

Usually, you will want to `requestResize` in this.

## `bool mouseEvent(MouseEvent)`
Called when a mouse event occurs while the mouse cursor was on top of this
widget.

The coordinates in MouseEvent are relative to top-left (0,0) corner of this
widget.

## `bool keyboardEvent(KeyboardEvent, bool)`
Called when this widget is the active widget, and a keyboard event occurs.

It also receives a flag, which is true in case the parent wants to cycle
focus to next possible active widget. In most scenarios, you will want to do
nothing and `return false` in case the flag is true.

Note that by returning false, whether or not the flag is true, will move focus
away from this widget.

## `bool resizeEvent()`
Called when the parent underwent resizing, and this widget may have been resized
as well.

Usually you will want to `requestUpdate` in this.

## `bool scrollEvent()`
Called when this widget or its parent has been scrolled.

Usually you will want to `requestUpdate` in this.

## `bool activateEvent(bool)`
This is called whenever this widget is made the active widget, or is un-made the
active widget.

If it was made the active widget, the flag will be true, else it will be false.

## `bool timerEvent(uint msecs)`
Called every time `msecs` amount of milliseconds have passed.

## `bool updateEvent()`
This is the event in which your widget shold draw itself.

# Custom Event Handlers

In case you are not writing a widget, but using one, and you want a function to
be called each time a specific event handler for a widget is called, you can
use custom events.

These can be assigned like:
```D
QWidget.onInitEvent = delegate(QWidget callerWidget){
	// do stuff
	return false; // return true to prevent widget receiving event
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

These functions are called before the event handler of that widget is called.
And if the custom handler returns true, the event is dropped and the event
handler for widget is **not** called.

