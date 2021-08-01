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

This can be useful in some cases for example, on pressing Enter on a EditLineWidget, you drop 
the event.

---

# Writing Event Handlers for Widget:

Below is a list of all event handlers, and how you can override them to fit your widget's use case:  

# initialize()

This is called right after the widget has been assigned a parent, and a `_display`.  
No event handlers will be called before this has been called, and the widget should not access `_display` before `initialize()` has been called, it will be `null`.  

Override like:  
```D
protected: 
	override void initialize(){
		/// ...
	}
```

# mouseEvent(MouseEvent)

This is called when a mouse event occurs where the mouse cursor is over the widget. the passed argument is of type `MouseEvent` and contains the x and y coordinates of mouse relative to top left corner of widget (0, 0), along with type of event.  

Override like:
```D
protected: 
	override void mouseEvent(MouseEvent mouse){
		/// ...
	}
```

## MouseEvent
the x and y coordinates are stored in `MouseEvent.x` and `MouseEvent.y` as `int`.  

The button clicked or released can be read through `MouseEvent.buttons`.  

Whether a button was pressed or released can be read through `MouseEvent.State`. However, Release events might contain an invalid button (`MouseEvent.Button.None`).

# keyboardEvent(KeyboardEvent)

Called when a keyboard event occurs and this widget is the active widget (i.e widget currently "selected"). Argument of type `KeyboardEvent` is passed, this contains what key was pressed.  

keyboardEvent will never be called for Escape key, as it is used for cycling between active widgets. And unless the widget has `this._wantsTab == true`, it will not receive tab key (`\t` character) either.  

Override like:  
```D
protected: 
	override void keyboardEvent(KeyboardEvent){
		/// ...
	}
```
  
## KeyboardEvent
the key pressed is stored in `KeyboardEvent.key` as a `dchar`.  
This struct also contains `KeyboardEvent.Key` enum which stores what specific values of `KeyboardEvent.key` represent what special keys like Delete etc.  
  
The `KeyboardEvent.isChar` function can be called to check if pressed key is a character or not.  
`KeyboardEvent.isCtrlKey` can be used to check if Ctrl+Letter was pressed.  
`KeyboardEvent.CtrlKeys` stores the values in `dchar` for Ctrl+Letter key combinations.  

Keep in mind that backspace (`\b`), space, and Tab (`\t`) are characters.

# resizeEvent()

This is called when the widget has been resized, _or_ if it's parent was resized. This being called does not necessary mean the widget's size was changed. If a widget needs to know if it's size changes, it should keep a copy of `this._size`.

The widget should call `this.requestUpdate()` in `resizeEvent` so that it's parent widget will update it, so it can re-draw itself to fit the new size.

# activateEvent(bool)

Called by parent when this widget has been made the active widget or if it was active widget, but no longer is.  

In case it is made the active widget, the argument is `true`, otherwise, it is `false`.

# timerEvent(uint)

_Be aware that the duration between timerEvents is not fixed, it can be changed by changing `QTerminal.timerMsecs` even while the application is running._  

the argument, of type `uint`, stores the amount of milliseconds since the last `timerEvent` was called. It is **not** accurate.
