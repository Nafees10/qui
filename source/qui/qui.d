/++
	This module contains most of the functions you'll need.
	All the 'base' classes, like QWidget are defined in this.
+/
module qui.qui;

import std.datetime.stopwatch;
import utils.misc;
import std.conv : to;
import termbox;

import qui.utils;

/// How much time between each timer event
const ushort TIMER_MSECS = 500;
/// If a widget registers itself as keyHandler for either of these keys, the keyboardEvent for _activeWidget will also be called 
/// when these keys are tirggered, along with handler's keyboardEvent
const UNCATCHABLE_KEYS = [Key.space, Key.backspace, Key.tab];
/// the default foreground color
const Color DEFAULT_FG = Color.green;
/// the default background color
const Color DEFAULT_BG = Color.black;

/// Available colors are in this enum
public import termbox : Color;
/// Availabe Keys (keyboard) for input
public import termbox : Key;

///Mouse Click, or Ms Wheel scroll event
///
///The mouseEvent function is called with this.
struct MouseEvent{
	///Types of buttons
	enum Button{
		Left,/// Left mouse button
		ScrollUp,/// MS wheel was scrolled up
		ScrollDown,/// MS wheel was scrolled down
		Right,/// Right mouse button was pressed
	}
	///Stores which button was pressed
	Button button;
	/// the x-axis of mouse cursor, 0 means left-most
	uinteger x;
	/// the y-axis of mouse cursor, 0 means top-most
	uinteger y;
	/// Returns: a string representation of MouseClick, in JSON
	string tostring(){
		return "{button:"~to!string(button)~",x:"~to!string(x)~",y:"~to!string(y)~"}";
	}
}

///Key press event, keyboardEvent function is called with this
struct KeyboardEvent{
	/// which character was entered
	char charKey;
	/// which key was pressed, only valid if `charKey == 0`, or if reported char is also present in enum `Key`
	Key key;
	/// Returns: true if the pressed key is not a character
	/// 
	/// Enter (`\n`), Tab (`\t`), backsace (`\b`), and space (` `) are considered characters too
	@property bool isChar(){
		if (charKey)
			return true;
		return false;
	}
	/// Returns: a string representation of KeyPress, in JSON
	string tostring(){
		if (isChar){
			return "{charKey:"~cast(char)charKey~'}';
		}
		return "{key:"~to!string(key)~'}';
	}
	/// constructor to construct from termbox.Event
	private this(Event e){
		if (e.ch == 0){
			this.charKey = 0;
			this.key = cast(Key)e.key;
			if (this.key == Key.space)
				charKey = cast(dchar)' ';
			else if (this.key == Key.backspace || this.key == Key.backspace2)
				charKey = cast(dchar)'\b';
			else if (this.key == Key.tab)
				charKey = cast(dchar)'\t';
			else if (this.key == Key.enter)
				charKey = cast(dchar)'\n';
		}else{
			this.charKey = to!char(cast(dchar)e.ch);
		}
	}
}

/// Used to store position for widgets
struct Position{
	integer x = 0, y = 0;
	/// Returns: a string representation of Position
	string tostring(){
		return "{x:"~to!string(x)~",y:"~to!string(y)~"}";
	}
}

/// To store size for widgets
/// 
/// zero in min/max means no limit
struct Size{
	private{
		uinteger _w = 0, _h = 0;
		bool _changed = false; /// specifies if has been changed.
	}
	/// returns whether the size was changed since the last time this property was read
	@property bool changed(){
		if (_changed){
			_changed = false;
			return true;
		}
		return false;
	}
	/// width
	@property uinteger width(){
		return _w;
	}
	/// width
	@property uinteger width(uinteger newWidth){
		_changed = true;
		if (minWidth > 0 && newWidth < minWidth){
			return _w = minWidth;
		}else if (maxWidth > 0 && newWidth > maxWidth){
			return _w = maxWidth;
		}
		return _w = newWidth;
	}
	/// height
	@property uinteger height(){
		return _h;
	}
	/// height
	@property uinteger height(uinteger newHeight){
		_changed = true;
		if (minHeight > 0 && newHeight < minHeight){
			return _h = minHeight;
		}else if (maxHeight > 0 && newHeight > maxHeight){
			return _h = maxHeight;
		}
		return _h = newHeight;
	}
	/// minimun width & height. These are "applied" automatically when setting value using `width` or `height`
	uinteger minWidth = 0, minHeight = 0;
	/// maximum width & height. These are "applied" automatically when setting value using `width` or `height`
	uinteger maxWidth = 0, maxHeight = 0;
	/// Returns: a string representation of KeyPress, in JSON
	string tostring(){
		return "{width:"~to!string(_w)~",height:"~to!string(_h)~
			",minWidth:"~to!string(minWidth)~",maxWidth:"~to!string(maxWidth)~
				",minHeight:"~to!string(minHeight)~",maxHeight:"~to!string(maxHeight)~"}";
	}
}

/// mouseEvent function
alias MouseEventFuction = void delegate(QWidget, MouseEvent);
///keyboardEvent function
alias KeyboardEventFunction = void delegate(QWidget, KeyboardEvent);
/// resizeEvent function
alias ResizeEventFunction = void delegate(QWidget, Size);
/// activateEvent function
alias ActivateEventFunction = void delegate(QWidget, bool);
/// TimerEvent function
alias TimerEventFunction = void delegate(QWidget);
/// Init function
alias InitFunction = void delegate(QWidget);


/// Base class for all widgets, including layouts and QTerminal
///
/// Use this as parent-class for new widgets
abstract class QWidget{
private:
	/// stores the position of this widget, relative to it's parent widget's position
	/// 
	/// This is private so it won't be modified by the widget, only classes present in this module are concerned with it
	Position _position;
protected:
	///size of this widget
	Size _size;
	///whether this widget should be drawn or not
	bool _show = true;
	/// specifies that how much height (in horizontal layout) or width (in vertical) is given to this widget.
	/// The ratio of all widgets is added up and height/width for each widget is then calculated using this
	uinteger _sizeRatio = 1;
	/// specifies whether this widget should receive the Tab key press, default is false, and should only be changed to true
	/// if only required, for example, in text editors
	bool _wantsTab = false;
	/// whether the widget wants input
	bool _wantsInput = false;
	/// the interface used to "talk" to the terminal, for example, to change the cursor position etc
	QTermInterface _termInterface = null;

	/// custom onInit event, if not null, it should be called before doing anything else in init();
	InitFunction _customInitEvent;
	/// custom mouse event, if not null, it should be called before doing anything else in mouseEvent.
	MouseEventFuction _customMouseEvent;
	/// custom keyboard event, if not null, it should be called before doing anything else in keyboardEvent.
	KeyboardEventFunction _customKeyboardEvent;
	/// custom resize event, if not null, it should be called before doing anything else in the resizeEvent
	ResizeEventFunction _customResizeEvent;
	/// custom onActivate event, if not null, it should be called before doing anything else in activateEvent
	ActivateEventFunction _customActivateEvent;
	/// custom onTimer event, if not null, it should be called before doing anything else in timerEvent
	TimerEventFunction _customTimerEvent;

	/// Called by parent to update this widget
	/// 
	/// If `force==true`, then the widget must update, whether it needs to or not
	abstract void update(bool force=false);

	/// Called by QTerminal after `_termInterface` has been set and this widget is registered
	/// 
	/// Must be inherited like:
	/// ```
	/// 	override void init(){
	/// 		super.mouseEvent(mouse);
	/// 		// code to handle this event here
	/// 	}
	/// ```
	void init(){
		if (_customInitEvent)
			_customInitEvent(this);
	}

	/// Called by parent when mouse is clicked with cursor on this widget.
	/// 
	/// Must be inherited like:
	/// ```
	/// 	override void mouseEvent(MouseClick mouse){
	/// 		super.mouseEvent(mouse);
	/// 		// code to handle this event here
	/// 	}
	/// ```
	void mouseEvent(MouseEvent mouse){
		if (_customMouseEvent !is null)
			_customMouseEvent(this, mouse);
	}
	
	/// Called by parent when key is pressed and this widget is active.
	/// 
	/// Must be inherited like:
	/// ```
	/// 	override void keyboardEvent(KeyPress key){
	/// 		super.keyboardEvent(key);
	/// 		// code to handle this event here
	/// 	}
	/// ```
	void keyboardEvent(KeyboardEvent key){
		if (_customKeyboardEvent !is null)
			_customKeyboardEvent(this, key);
	}

	/// Called by parent when widget size is changed.
	/// 
	/// Must be inherited like:
	/// ```
	/// 	override void resizeEvent(Size size){
	/// 		super.resizeEvent(size);
	/// 		// code to handle this event here
	/// 	}
	/// ```
	void resizeEvent(Size size){
		if (_customResizeEvent !is null)
			_customResizeEvent(this, size);
	}

	/// called by QTerminal right after this widget is activated, or de-activated, i.e: is made _activeWidget, or un-made _activeWidget
	/// 
	/// Must be inherited, only if inherited, like:
	/// ```
	/// 	override void activateEvent(bool activated){
	/// 		super.activateEvent(activated);
	/// 		// code to handle this event here
	/// 	}
	/// ```
	void activateEvent(bool isActive){
		if (_customActivateEvent)
			_customActivateEvent(this, isActive);
	}

	/// called by QTerminal every 500ms, not accurate
	/// 
	/// Must be inherited, only if inherited, like:
	/// ```
	/// 	override void timerEvent(){
	/// 		super.timerEvent();
	/// 		// code to handle this event here
	/// 	}
	/// ```
	void timerEvent(){
		if (_customTimerEvent)
			_customTimerEvent(this);
	}
public:
	/// use to change the custom init event
	@property InitFunction onInitEvent(InitFunction func){
		return _customInitEvent = func;
	}
	/// use to change the custom mouse event
	@property MouseEventFuction onMouseEvent(MouseEventFuction func){
		return _customMouseEvent = func;
	}
	/// use to change the custom keyboard event
	@property KeyboardEventFunction onKeyboardEvent(KeyboardEventFunction func){
		return _customKeyboardEvent = func;
	}
	/// use to change the custom resize event
	@property ResizeEventFunction onResizeEvent(ResizeEventFunction func){
		return _customResizeEvent = func;
	}
	/// use to change the custom activate event
	@property ActivateEventFunction onActivateEvent(ActivateEventFunction func){
		return _customActivateEvent = func;
	}
	/// use to change the custom timer event
	@property TimerEventFunction onTimerEvent(TimerEventFunction func){
		return _customTimerEvent = func;
	}
	/// Returns: whether the widget is receiving the Tab key press or not
	@property bool wantsTab(){
		return _wantsTab;
	}
	/// ditto
	@property bool wantsTab(bool newStatus){
		return _wantsTab = newStatus;
	}
	/// Returns: true if the widget wants input
	@property bool wantsInput(){
		return _wantsInput;
	}
	/// size of width (height/width, depending of Layout.Type it is in) of this widget, in ratio to other widgets in that layout
	@property uinteger sizeRatio(){
		return _sizeRatio;
	}
	/// ditto
	@property uinteger sizeRatio(uinteger newRatio){
		return _sizeRatio = newRatio;
	}
	/// visibility of the widget. getter
	@property bool show(){
		return _show;
	}
	/// visibility of the widget. setter
	@property bool show(bool visibility){
		return _show = visibility;
	}
	/// size of the widget. getter
	@property ref Size size(){
		return _size;
	}
	/// size of the widget. setter
	@property ref Size size(Size newSize){
		return _size = newSize;
	}
}

///Used to place widgets in an order (i.e vertical or horizontal)
///
///The QTerminal is also a layout, basically.
///
///Name in theme: 'layout';
class QLayout : QWidget{
private:
	/// array of all the widgets that have been added to this layout
	QWidget[] _widgets;
	/// stores the layout type, horizontal or vertical
	QLayout.Type _type;
	
	/// recalculates the size of every widget inside layout
	void recalculateWidgetsSize(QLayout.Type T)(QWidget[] widgets, uinteger totalSpace, uinteger totalRatio){
		static if (T != QLayout.Type.Horizontal && T != QLayout.Type.Vertical){
			assert(false);
		}
		bool repeat;
		do{
			repeat = false;
			foreach(i, widget; widgets){
				if (widget._show){
					// calculate width or height
					uinteger newSpace = ratioToRaw(widget._sizeRatio, totalRatio, totalSpace);
					uinteger calculatedSpace = newSpace;
					//apply size
					static if (T == QLayout.Type.Horizontal){
						widget._size.height = _size.height;
						widget._size.width = newSpace;
						newSpace = widget._size.width;
					}else{
						widget._size.width = _size.width;
						widget._size.height = newSpace;
						newSpace = widget._size.height;
					}
					if (newSpace != calculatedSpace){
						totalRatio -= widget._sizeRatio;
						totalSpace -= newSpace;
						widgets = widgets.dup.deleteElement(i);
						repeat = true;
						break;
					}
					// check if there's enough space to contain that widget
					if (newSpace > totalSpace){
						newSpace = 0;
						widget._show = false;
					}
				}
			}
		} while (repeat);
	}
	/// calculates and assigns widgets positions based on their sizes
	void recalculateWidgetsPosition(QLayout.Type T)(QWidget[] widgets){
		static if (T != QLayout.Type.Horizontal && T != QLayout.Type.Vertical){
			assert(false);
		}
		uinteger previousSpace = (T == QLayout.Type.Horizontal ? _position.x : _position.y);
		uinteger fixedPoint = (T == QLayout.Type.Horizontal ? _position.y : _position.x);
		foreach(widget; widgets){
			if (widget._show){
				static if (T == QLayout.Type.Horizontal){
					widget._position.y = _position.y;
					widget._position.x = previousSpace;
					previousSpace += widget._size.width;
				}else{
					widget._position.x = _position.x;
					widget._position.y = previousSpace;
					previousSpace += widget._size.height;
				}
			}
		}
	}
protected:
	/// Recalculates size and position for all visible widgets
	/// If a widget is too large to fit in, it's visibility is marked false
	override void resizeEvent(Size size){
		super.resizeEvent(_size);
		uinteger ratioTotal;
		foreach(w; _widgets){
			if (w._show){
				ratioTotal += w._sizeRatio;
			}
		}
		if (_type == QLayout.Type.Horizontal){
			recalculateWidgetsSize!(QLayout.Type.Horizontal)(_widgets, _size.width, ratioTotal);
			recalculateWidgetsPosition!(QLayout.Type.Horizontal)(_widgets);
		}else{
			recalculateWidgetsSize!(QLayout.Type.Vertical)(_widgets, _size.height, ratioTotal);
			recalculateWidgetsPosition!(QLayout.Type.Vertical)(_widgets);
		}
		foreach (widget; _widgets){
			widget.resizeEvent(size);
		}
	}
	
	/// Redirects the mouseEvent to the appropriate widget
	override public void mouseEvent(MouseEvent mouse) {
		super.mouseEvent(mouse);
		foreach (widget; _widgets){
			if (widget._show && widget._wantsInput &&
				mouse.x >= widget._position.x && mouse.x < widget._position.x + widget._size.width &&
				mouse.y >= widget._position.y && mouse.y < widget._position.y + widget._size.height){
				// make it active, and call it's mouseEvent
				if (_termInterface._qterminal.makeActive(widget))
					widget.mouseEvent(mouse);
				break;
			}
		}
	}
	
	/// called by owner widget to update
	override void update(bool force=false){
		foreach(widget; _widgets){
			if (widget._show){
				_termInterface.restrictWrite(widget._position.x, widget._position.y, widget._size.width, widget._size.height);
				widget.update(force);
			}
		}
	}
	
public:
	/// Layout type
	enum Type{
		Vertical,
		Horizontal,
	}
	/// constructor
	this(QLayout.Type type){
		_type = type;
	}
	
	/// adds (appends) a widget to the widgetList, and makes space for it
	/// 
	/// If there a widget is too large, it's marked as not visible
	void addWidget(QWidget widget){
		//add it to array
		_widgets ~= widget;
	}
	/// adds (appends) widgets to the widgetList, and makes space for them
	/// 
	/// If there a widget is too large, it's marked as not visible
	void addWidget(QWidget[] widgets){
		// add to array
		_widgets ~= widgets.dup;
	}
}

class QTermInterface{
private:
	/// The QTerminal
	QTerminal _qterminal;
	/// The current position of cursor, i.e where the next character will be written
	Position _cursorPos;
	/// The position that cursor will be moved to when its done drawing
	Position _postUpdateCursorPos;
	/// X coordinates of area where writing is allowed
	uinteger _restrictX1, _restrictX2;
	/// Y coordinates of area where writing is allowed
	uinteger _restrictY1, _restrictY2;
	/// restricts writing to a rectangle inside the terminal
	/// 
	/// The cursor is also moved to x and y
	/// After applying this restriction, the cursor position returned will also be relative to x and y provided here
	/// 
	/// Returns: true if restricted, false if not restricted, because the area specified is outside terminal, or width || height == 0
	bool restrictWrite(uinteger x, uinteger y, uinteger width, uinteger height){
		if (x + width > _qterminal._size.width || y + height > _qterminal._size.height || width == 0 || height == 0)
			return false;
		_restrictX1 = x;
		_restrictX2 = x + width;
		_restrictY1 = y;
		_restrictY2 = y + height;
		// move to position
		setCursor(cast(int)x, cast(int)y);
		_cursorPos = Position(x, y);
		return true;
	}
	/// called by QTerminal after all updating is finished, and right before checking for more events
	void updateFinished(){
		// set cursor position
		setCursor(cast(int)_postUpdateCursorPos.x, cast(int)_postUpdateCursorPos.y);
		// flush
		flush();
	}
	/// called by QTerminal right before starting to update widgets
	void updateStarted(){
		// set cursor position to (-1,-1), so if not set, its not visible
		_postUpdateCursorPos = Position(-1,-1);
	}
public:
	this(QTerminal term){
		_qterminal = term;
	}
	/// Returns: true if the caller widget is _activeWidget
	bool isActive(QWidget caller){
		return _qterminal.isActive(caller);
	}
	/// Writes characters on terminal
	/// 
	/// if `c` has more characters than there is space for, first few will be written, rest will be skipped.  
	/// **and tab character is not supported, as in it will be read as a single space character. `'\t' = ' '`**
	void write(char[] c, Color fg, Color bg){
		for (uinteger i = 0; _cursorPos.y < _restrictY2;){
			for (; _cursorPos.x < _restrictX2 && i < c.length; _cursorPos.x ++){
				if (c[i] == '\t')
					setCell(cast(int)_cursorPos.x, cast(int)_cursorPos.y, cast(uint)to!dchar(' '), fg, bg);
				else
					setCell(cast(int)_cursorPos.x, cast(int)_cursorPos.y, cast(uint)to!dchar(c[i]), fg, bg);
				i ++;
			}
			if (_cursorPos.x >= _restrictX2){
				_cursorPos.x = _restrictX1;
				_cursorPos.y ++;
			}
			if (i >= c.length)
				break;
		}
	}
	/// Fills the remaining part of curent line with `c`
	/// 
	/// `maxCount` is the maximum number of cells to fill. 0 for no limit
	void fillLine(char c, Color fg, Color bg, uinteger maxCount = 0){
		dchar dC = to!dchar(c);
		for (uinteger i = 0; _cursorPos.x < _restrictX2; _cursorPos.x ++){
			setCell(cast(int)_cursorPos.x, cast(int)_cursorPos.y, cast(uint)dC, fg, bg);
			i ++;
			if (i == maxCount)
				break;
		}
		if (_cursorPos.x >= _restrictX2){
			_cursorPos.x = _restrictX1;
			_cursorPos.y ++;
		}
	}
	/// Fills the terminal, or restricted area, with a character
	void fill(char c, Color fg, Color bg){
		dchar dC = to!dchar(c);
		for (; _cursorPos.y < _restrictY2; _cursorPos.y ++){
			for (; _cursorPos.x < _restrictX2; _cursorPos.x ++){
				setCell(cast(int)_cursorPos.x, cast(int)_cursorPos.y, cast(uint)dC, fg, bg);
			}
			_cursorPos.x = _restrictX1;
		}
	}
	/// the position of next write
	/// 
	/// relative to the (0,0) of area where writing has been restricted (usually the area occupied by a widget)
	/// 
	/// Returns: position of cursor
	@property Position cursor(){
		return Position(_cursorPos.x - _restrictX1, _cursorPos.y - _restrictY1);
	}
	/// ditto
	@property Position cursor(Position newPosition){
		_cursorPos = newPosition;
		_cursorPos.x += _restrictX1;
		_cursorPos.y += _restrictY1;
		if (_cursorPos.x > _restrictX2)
			_cursorPos.x = _restrictX2;
		if (_cursorPos.y > _restrictY2)
			_cursorPos.y = _restrictY2;
		setCursor(cast(int)_cursorPos.x, cast(int)_cursorPos.y);
		return _cursorPos;
	}
	/// sets position of cursor on terminal, after updating is done
	/// 
	/// position is relative to caller widget's position.
	/// 
	/// Returns: true if successful, false if not
	bool setCursorPos(QWidget caller, uinteger x, uinteger y){
		if (_qterminal.isActive(caller)){
			_postUpdateCursorPos.x = _qterminal._activeWidget._position.x + x;
			_postUpdateCursorPos.y = _qterminal._activeWidget._position.y + y;
			return true;
		}
		return false;
	}
	/// Registers a keypress to a QWidget. When that key is pressed, the keyboardEvent of that widget will be called, regardless of _activeWidget
	/// 
	/// Returns: true if successfully set, false if not, for example if key is already registered
	bool setKeyHandler(Key key, QWidget handlerWidget){
		return _qterminal.registerKeyHandler(key, handlerWidget);
	}
	/// adds a request to QTerminal so right after it's done with `timerEvent`s, this widget's update will be called
	void requestUpdate(QWidget widget){
		_qterminal.requestUpdate(widget);
	}
}

/// A terminal (as the name says).
/// 
/// All widgets, receives events, runs UI loop...
/// 
/// Name in theme: 'terminal';
class QTerminal : QLayout{
private:
	/// stores the position of the cursor on terminal
	Position _cursor;
	/// array containing registered widgets
	QWidget[] _regdWidgets;
	/// stores the index of the active widget, which is in `_regdWidgets`, it will be -1 if none is active
	integer _activeWidgetIndex = -1;
	// contains reference to the active widget, null if no active widget
	QWidget _activeWidget;
	/// stores list of keys and widgets that will catch their KeyPress event
	QWidget[Key] _keysToCatch;
	/// list of widgets requesting early `update();`
	QWidget[] _requestingUpdate;

	/// Called by QTermInterface to position the cursor, only the _activeWidget can change the cursorPos
	/// 
	/// the cursor position is relative to caller widget's position
	/// 
	/// Returns: true on success, false on failure
	bool setCursorPos(uinteger x, uinteger y, QWidget callerWidget){
		if (_activeWidget && callerWidget == _activeWidget){
			_cursor.x = _activeWidget._position.x + x;
			_cursor.y = _activeWidget._position.y + y;
			return true;
		}
		return false;
	}

	/// registers a key with a widget, so regardless of _activeWidget, that widget will catch that key's KeyPress event
	/// 
	/// Returns:  true on success, false on failure, which can occur because that key is already registered, or if widget is not registered
	bool registerKeyHandler(Key key, QWidget widget){
		if (key in _keysToCatch || _regdWidgets.hasElement(widget)){
			return false;
		}else{
			_keysToCatch[key] = widget;
			return true;
		}
	}

	/// Returns: true if a widget is active widget
	bool isActive(QWidget widget){
		if (_activeWidget && widget == _activeWidget){
			return true;
		}
		return false;
	}

	/// makes a widget active, i.e, redirects keyboard input to a `widget`
	/// 
	/// Return: true on success, false on error, or if the widget isn't registered
	bool makeActive(QWidget widget){
		QWidget lastActiveWidget = _activeWidget;
		foreach (i, aWidget; _regdWidgets){
			if (widget == aWidget){
				_activeWidgetIndex = i;
				_activeWidget = aWidget;
				if (lastActiveWidget != _activeWidget){
					if (lastActiveWidget)
						lastActiveWidget.activateEvent(false);
					_activeWidget.activateEvent(true);
				}
				return true;
			}
		}
		return false;
	}

	/// ditto
	bool makeActive(uinteger widgetIndex){
		if (_activeWidgetIndex == widgetIndex)
			return true;
		if (_activeWidgetIndex >= 0 && widgetIndex < _regdWidgets.length){
			_activeWidget.activateEvent(false);
			_activeWidgetIndex = widgetIndex;
			_activeWidget = _regdWidgets[widgetIndex];
			_activeWidget.activateEvent(true);
			return true;
		}
		_activeWidget = null;
		_activeWidgetIndex = -1;
		return false;
	}

	/// adds a widget to `_requestingUpdate`, so it'll be updated right after `timerEvent`s are done with
	void requestUpdate(QWidget widget){
		_requestingUpdate ~= widget;
	}

	/// Reads InputEvent[] and calls appropriate functions to address those events
	/// 
	/// Returns: true when there is no need to terminate (no CTRL+C pressed). false when it should terminate
	bool readEvent(Event event){
		if (event.type == EventType.key){
			if (event.key == Key.ctrlC){
				return false;
			}
			KeyboardEvent kPress = KeyboardEvent(event);
			this.keyboardEvent(kPress);
		}else if (event.type == EventType.mouse){
			// only button clicks & scroll are events, hovering is not (at least yet)
			MouseEvent mEvent;
			mEvent.x = event.x;
			mEvent.y = event.y;
			if (event.key == Key.mouseLeft)
				mEvent.button = MouseEvent.Button.Left;
			else if (event.key == Key.mouseRight)
				mEvent.button = MouseEvent.Button.Right;
			else if (event.key == Key.mouseWheelUp)
				mEvent.button = MouseEvent.Button.ScrollUp;
			else if (event.key == Key.mouseWheelDown)
				mEvent.button = MouseEvent.Button.ScrollDown;
			else
				return true;
			this.mouseEvent(mEvent);
		}else if (event.type == EventType.resize){
			//update self size
			_size.height = event.h;
			_size.width = event.w;
			//call size change on all widgets
			resizeEvent(_size);
		}
		return true;
	}

protected:
	override public void mouseEvent(MouseEvent mouse){
		super.mouseEvent(mouse);
		foreach (i, widget; _widgets){
			if (widget._show && widget._wantsInput){
				Position p = widget._position;
				Size s = widget._size;
				//check x-y-axis
				if (mouse.x >= p.x && mouse.x < p.x + s.width && mouse.y >= p.y && mouse.y < p.y + s.height){
					//mark this widget as active
					makeActive(i);
					if (_activeWidgetIndex == -1)
						makeActive(0);
					// make mouse position relative to widget position, not 0:0
					mouse.x = mouse.x - _activeWidget._position.x;
					mouse.y = mouse.y - _activeWidget._position.y;
					//call mouseEvent
					widget.mouseEvent(mouse);
					break;
				}
			}
		}
	}
	
	override public void keyboardEvent(KeyboardEvent key){
		super.keyboardEvent(key);
		// check if the _activeWidget wants Tab, otherwise, if is Tab, make the next widget active
		if (key.key == Key.esc || (key.charKey == '\t' && (_activeWidgetIndex < 0 || !_activeWidget._wantsTab))){
			QWidget lastActiveWidget = _activeWidget;
			// make the next widget active
			if (_regdWidgets.length > 0){
				uinteger newIndex = _activeWidgetIndex + 1;
				// see if it wants input, case no, switch to some other widget
				for (;newIndex < _regdWidgets.length; newIndex ++){
					if (_widgets[newIndex]._show && _widgets[newIndex]._wantsInput){
						break;
					}
				}
				makeActive(newIndex);
				if (_activeWidgetIndex == -1)
					makeActive(0);
			}
		}else if (key.key in _keysToCatch){
			// this is a registered key, only a specific widget catches it
			// check if it's in UNCATCHABLE_KEYS, if yes, the call _activeWidget's keyboard event too
			if (UNCATCHABLE_KEYS.hasElement(key.key))
				_activeWidget.keyboardEvent(key);
			_keysToCatch[key.key].keyboardEvent(key);
		}else if (_activeWidget !is null){
			_activeWidget.keyboardEvent (key);
		}
	}
	
	override public void update(bool force=false){
		_termInterface.updateStarted;
		if (force){
			_termInterface.restrictWrite(0,0,_size.width,_size.height);
			_termInterface.fill(' ', DEFAULT_FG, DEFAULT_BG);
		}
		super.update(force);
		_termInterface.updateFinished;
	}

public:
	/// text color, and background color
	Color textColor, backgroundColor;
	this(QLayout.Type displayType = QLayout.Type.Vertical){
		super(displayType);

		textColor = DEFAULT_FG;
		backgroundColor = DEFAULT_BG;

		_termInterface = new QTermInterface(this);
	}
	~this(){
		.destroy(_termInterface);
	}

	/// registers a widget
	/// 
	/// **All** widgets that are to be present on terminal must be registered.  
	/// All means widgets added to QTerminal, and any QLayout and any other widget.
	void registerWidget(QWidget widget){
		_regdWidgets ~= widget;
		widget._termInterface = _termInterface;
		widget.init();
	}
	/// registers widgets
	/// 
	/// **All** widgets that are to be present on terminal must be registered.  
	/// All means widgets added to QTerminal, and any QLayout and any other widget.
	void registerWidget(QWidget[] widgets){
		_regdWidgets = _regdWidgets ~ widgets.dup;
		foreach (widget; widgets){
			widget._termInterface = _termInterface;
			widget.init();
		}
	}
	
	/// starts the UI loop
	void run(){
		// init termbox
		termbox.init();
		termbox.setInputMode(InputMode.esc | InputMode.mouse);
		_size.width = width();
		_size.height = height();
		//resize all widgets
		resizeEvent(_size);
		//draw the whole thing
		update(true);
		ubyte timerCount = 0; /// times timerEvent's been called after last force update
		// the stop watch, to count how much time has passed after each timerEvent
		StopWatch sw = StopWatch(AutoStart.no);
		sw.start;
		while (true){
			if (sw.peek.total!"msecs" >= TIMER_MSECS){
				timerCount ++;
				foreach (widget; _regdWidgets)
					widget.timerEvent;
				sw.reset;
				sw.start;
			}
			// take a look at _requestingUpdate
			int timeout = cast(int)(TIMER_MSECS - sw.peek.total!"msecs");
			if (_requestingUpdate.length > 0)
				timeout = 0;
			Event event;
			if (peekEvent(&event, timeout) > 0){
				// go through the events
				if (!readEvent(event))
					break;
				update();
			}else{
				if (timerCount >= 2){
					update(true);
					timerCount = 0;
				}else if (_requestingUpdate.length > 0){
					_termInterface.updateStarted;
					foreach(widget; _requestingUpdate){
						if (widget._show){
							_termInterface.restrictWrite(widget._position.x, widget._position.y, widget._size.width, widget._size.height);
							widget.update;
						}
					}
					_termInterface.updateFinished;
				}
			}
			_requestingUpdate = [];
		}
		// shutdown termbox
		shutdown();
	}
}