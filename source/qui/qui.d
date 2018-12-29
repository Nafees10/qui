/++
	This module contains most of the functions you'll need.
	All the 'base' classes, like QWidget are defined in this.
+/
module qui.qui;

import arsd.terminal;
import std.datetime.stopwatch;
//import std.stdio;
import utils.baseconv;
import utils.lists;
import utils.misc;
import std.conv : to;

import qui.utils;

const RGB DEFAULT_TEXT_COLOR = hexToColor("00FF00");
const RGB DEFAULT_BACK_COLOR = hexToColor("000000");
const ushort TIMER_MSECS = 500;

///Mouse Click, or Ms Wheel scroll event
///
///The mouseEvent function is called with this.
struct MouseClick{
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
	/// constructor, to construct from arsd's MouseEvent
	this (MouseEvent mEvent){
		x = mEvent.x;
		y = mEvent.y;
		switch (mEvent.buttons){
			case MouseEvent.Button.Left:
				button = Button.Left;
				break;
			case MouseEvent.Button.Right:
				button = Button.Right;
				break;
			case MouseEvent.Button.ScrollUp:
				button = Button.ScrollUp;
				break;
			case MouseEvent.Button.ScrollDown:
				button = Button.ScrollDown;
				break;
			default:
				break;
		}
	}
}

///Key press event, keyboardEvent function is called with this
///
///A note: backspace (`\b`) and enter (`\n`) are not included in KeyPress.NonCharKey
struct KeyPress{
	dchar key;/// stores which key was pressed

	/// Returns true if the key was a character.
	/// 
	/// A note: Enter/Return ('\n') is not included in KeyPress.NonCharKey
	bool isChar(){
		return !(key >= NonCharKey.min && key <= NonCharKey.max);
	}
	/// Types of non-character keys
	enum NonCharKey{
		Escape = 0x1b + 0xF0000,
		F1 = 0x70 + 0xF0000,
		F2 = 0x71 + 0xF0000,
		F3 = 0x72 + 0xF0000,
		F4 = 0x73 + 0xF0000,
		F5 = 0x74 + 0xF0000,
		F6 = 0x75 + 0xF0000,
		F7 = 0x76 + 0xF0000,
		F8 = 0x77 + 0xF0000,
		F9 = 0x78 + 0xF0000,
		F10 = 0x79 + 0xF0000,
		F11 = 0x7A + 0xF0000,
		F12 = 0x7B + 0xF0000,
		LeftArrow = 0x25 + 0xF0000,
		RightArrow = 0x27 + 0xF0000,
		UpArrow = 0x26 + 0xF0000,
		DownArrow = 0x28 + 0xF0000,
		Insert = 0x2d + 0xF0000,
		Delete = 0x2e + 0xF0000,
		Home = 0x24 + 0xF0000,
		End = 0x23 + 0xF0000,
		PageUp = 0x21 + 0xF0000,
		PageDown = 0x22 + 0xF0000,
	}
	/// Returns: a string representation of KeyPress, in JSON
	string tostring(){
		if (isChar){
			return "{key:"~cast(char)key~'}';
		}
		return "{key:\""~to!string(cast(NonCharKey)key)~"\"}";
	}
}

/// A 24 bit, RGB, color
/// 
/// `r` represents amount of red, `g` is green, and `b` is blue.
/// the `a` is ignored
public import arsd.terminal : RGB;

/// Used to store position for widgets
struct Position{
	uinteger x = 0, y = 0;
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
		uinteger _w, _h;
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
alias MouseEventFuction = void delegate(QWidget, MouseClick);
///keyboardEvent function
alias KeyboardEventFunction = void delegate(QWidget, KeyPress);
/// resizeEvent function
alias ResizeEventFunction = void delegate(QWidget, Size);
/// activateEvent function
alias ActivateEventFunction = void delegate(QWidget, bool);
/// TimerEvent function
alias TimerEventFunction = void delegate(QWidget);


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
	/// specifies if the widget needs to show the cursor
	bool _showCursor = false;
	/// the interface used to "talk" to the terminal, for example, to change the cursor position etc
	QTermInterface _termInterface;
	
	/// custom mouse event, if not null, it should be called before doing anything else in mouseEvent.
	/// 
	/// Override like this:
	/// ```
	/// override void mouseEvent(MouseClick mouse){
	/// 	super.mouseEvent(mouse);
	/// 	// rest of the code for mouse event here
	/// }
	/// ```
	MouseEventFuction _customMouseEvent;
	
	/// custom keyboard event, if not null, it should be called before doing anything else in keyboardEvent.
	/// 
	/// Override like this:
	/// ```
	/// override void keyboardEvent(KeyPress key){
	/// 	super.keyboardEvent(key);
	/// 	// rest of the code for keyboard event here
	/// }
	/// ```
	KeyboardEventFunction _customKeyboardEvent;

	/// custom resize event, if not null, it should be called before doing anything else in the resizeEvent
	/// 
	/// Override like this:
	/// ```
	/// override void resizeEvent(Size size){
	/// 	super.resizeEvent(size);
	/// 	// the rest of the code for resizeEvent here
	/// }
	/// ```
	ResizeEventFunction _customResizeEvent;

	/// custom onActivate event, if not null, it should be called before doing anything else in activateEvent
	/// 
	/// Override like this:
	/// ```
	/// override void activateEvent(bool activated){
	/// 	super.activateEvent(activated);
	/// 	// rest of the code for resize here
	/// }
	/// ```
	ActivateEventFunction _customActivateEvent;

	/// custom onTimer event, if not null, it should be called before doing anything else in timerEvent
	/// 
	/// Override like this:
	/// ```
	/// override void timerEvent(){
	/// 	super.timerEvent();
	/// 	// rest of code for timerEvent here
	/// }
	/// ```
	TimerEventFunction _customTimerEvent;

	/// Called by QTerminal after `_termInterface` has been set and this widget is registered
	/// 
	/// In this function, the widget should set the keyHandlers (if needed) and any other thing before `QTerminal.run` is called
	void init(){
		// 404 - not found
	}
public:
	/// Called by parent when mouse is clicked with cursor on this widget.
	/// 
	/// Must be inherited like:
	/// ```
	/// 	override void mouseEvent(MouseClick mouse){
	/// 		super.mouseEvent(mouse);
	/// 		// code to handle this event here
	/// 	}
	/// ```
	void mouseEvent(MouseClick mouse){
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
	void keyboardEvent(KeyPress key){
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

	/// Returns: whether the widget is receiving the Tab key press or not
	@property bool wantsTab(){
		return _wantsTab;
	}

	/// Returns: true if the widget wants input
	@property bool wantsInput(){
		return _wantsInput;
	}

	/// Returns: whether the widget needs to show a cursor, only considered when this widget is active
	@property bool showCursor(){
		return _showCursor;
	}
	
	/// Called by parent to update this widget
	abstract void update();
	
	//event properties
	/// use to change the custom mouse event
	@property MouseEventFuction onMouseEvent(MouseEventFuction func){
		return _customMouseEvent = func;
	}
	/// use to change the custom keyboard event
	@property KeyboardEventFunction onKeyboardEvent(KeyboardEventFunction func){
		return _customKeyboardEvent = func;
	}
	/// use to change the custom activate event
	@property ActivateEventFunction onActivateEvent(ActivateEventFunction func){
		return _customActivateEvent = func;
	}
	/// use to change the custom timer event
	@property TimerEventFunction onTimerEvent(TimerEventFunction func){
		return _customTimerEvent = func;
	}
	
	
	//properties:
	
	/// size (width/height) of the widget. getter
	@property uinteger sizeRatio(){
		return _sizeRatio;
	}
	/// size (width/height) of the widget. setter
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
				if (widget.show){
					// calculate width or height
					uinteger newSpace = ratioToRaw(widget.sizeRatio, totalRatio, totalSpace);
					uinteger calculatedSpace = newSpace;
					//apply size
					static if (T == QLayout.Type.Horizontal){
						widget.size.height = _size.height;
						widget.size.width = newSpace;
						newSpace = widget.size.width;
					}else{
						widget.size.width = _size.width;
						widget.size.height = newSpace;
						newSpace = widget.size.height;
					}
					if (newSpace != calculatedSpace){
						totalRatio -= widget.sizeRatio;
						totalSpace -= newSpace;
						widgets = widgets.dup.deleteElement(i);
						repeat = true;
						break;
					}
					// check if there's enough space to contain that widget
					if (newSpace > totalSpace){
						newSpace = 0;
						widget.show = false;
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
			if (widget.show){
				static if (T == QLayout.Type.Horizontal){
					widget._position.y = _position.y;
					widget._position.x = previousSpace;
					previousSpace += widget.size.width;
				}else{
					widget._position.x = _position.x;
					widget._position.y = previousSpace;
					previousSpace += widget.size.height;
				}
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
	
	/// Recalculates size and position for all visible widgets
	/// If a widget is too large to fit in, it's visibility is marked false
	override void resizeEvent(Size size){
		super.resizeEvent(_size);
		uinteger ratioTotal;
		foreach(w; _widgets){
			if (w.show){
				ratioTotal += w.sizeRatio;
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
	override public void mouseEvent(MouseClick mouse) {
		super.mouseEvent(mouse);
		foreach (widget; _widgets){
			if (widget.show && widget.wantsInput &&
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
	override void update(){
		foreach(widget; _widgets){
			_termInterface.restrictWrite(widget._position.x, widget._position.y, widget._size.width, widget._size.height);
			widget.update();
		}
	}
}

class QTermInterface{
private:
	/// The Terminal to use
	Terminal* _terminal;
	/// The QTerminal
	QTerminal _qterminal;
	/// The current position of cursor, i.e where the next character will be written
	Position _cursorPos;
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
		if (x + width >= _terminal.width || y + height >= _terminal.height || width == 0 || height == 0)
			return false;
		_restrictX1 = x;
		_restrictX2 = x + width;
		_restrictY1 = y;
		_restrictY2 = y + height;
		
		_terminal.moveTo(cast(int)x, cast(int)y);
		_cursorPos.x = x;
		_cursorPos.y = y;
		return true;
	}
public:
	this(QTerminal term){
		_qterminal = term;
		_terminal = &(term._terminal);
	}
	/// Returns: true if the caller widget is _activeWidget
	bool isActive(QWidget caller){
		return _qterminal.isActive(caller);
	}
	/// Sets color
	/// 
	/// Returs: true if successful, false if not
	bool setColors(RGB foreground, RGB background){
		return _terminal.setTrueColor(foreground, background);
	}
	/// Writes characters on terminal
	/// 
	/// if `c` has more characters than there is space for, first few will be written, rest will be skipped
	/// 
	/// Returns: true if successful, false if not, or if there was not space for some characters (or all)
	bool write(char[] c){
		// fix cursor position
		if (_cursorPos.x >= _restrictX2){
			_cursorPos.x = _restrictX1;
			_cursorPos.y ++;
		}
		// can write? is there space?
		if (_cursorPos.y >= _restrictY2){
			return false;
		}
		// divide c into lines if it overflows one line
		char[][] lines = [];
		if (c.length > _restrictX2 - _cursorPos.x){
			lines = [c[0 .. _restrictX2 - _cursorPos.x]];
			c = c[_restrictX2 - _cursorPos.x .. c.length].dup;
		}
		lines = lines ~ c.divideArray(_restrictX2 - _restrictX1);
		foreach (line; lines){
			_terminal.write(line);
			_cursorPos.x += line.length;
			if (_cursorPos.x >= _restrictX2){
				_cursorPos.y ++;
				_cursorPos.x = _restrictX1;
			}
			if (_cursorPos.y >= _restrictY2)
				return false;
			_terminal.moveTo(cast(int)(_cursorPos.x), cast(int)(_cursorPos.y));
		}
		return true;
	}
	/// Fills the terminal, or restricted area, with a character
	void fill(char c){
		char[] line;
		line.length = _restrictX2 - _restrictX1;
		line[] = c;
		// set position
		_cursorPos.x = _restrictX1;
		_cursorPos.y = _restrictY2;
		_terminal.moveTo(cast(int)_cursorPos.x, cast(int)_cursorPos.y);
		// start writing
		for (; _cursorPos.y <= _restrictY1;){
			_terminal.write(line);
			_cursorPos.y ++;
			_terminal.moveTo(cast(int)_cursorPos.x, cast(int)_cursorPos.y);
		}
	}
	/// the position of next write
	/// 
	/// Returns: position of cursor
	@property Position cursor(){
		return _cursorPos;
	}
	/// ditto
	@property Position cursor(Position newPosition){
		_cursorPos = newPosition;
		if (_cursorPos.x > _restrictX2)
			_cursorPos.x = _restrictX2;
		if (_cursorPos.y > _restrictY2)
			_cursorPos.y = _restrictY2;
		return _cursorPos;
	}
	/// sets position of cursor on terminal.
	/// 
	/// position is relative to caller widget's position.
	/// 
	/// Returns: true if successful, false if not
	bool setCursorPos(QWidget caller, uinteger x, uinteger y){
		return _qterminal.setCursorPos(x, y, caller);
	}
	/// Registers a keypress to a QWidget. When that key is pressed, the keyboardEvent of that widget will be called, regardless of _activeWidget
	/// 
	/// Returns: true if successfully set, false if not, for example if key is already registered
	bool setKeyHandler(KeyPress key, QWidget handlerWidget){
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
	Terminal _terminal;
	RealTimeConsoleInput _input;
	/// stores the position of the cursor on terminal
	Position _cursor;
	/// array containing registered widgets
	QWidget[] _regdWidgets;
	/// stores the index of the active widget, which is in `_regdWidgets`, it will be -1 if none is active
	integer _activeWidgetIndex = -1;
	// contains reference to the active widget, null if no active widget
	QWidget _activeWidget;
	/// stores list of keys and widgets that will catch their KeyPress event
	QWidget[KeyPress] _keysToCatch;
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
	bool registerKeyHandler(KeyPress key, QWidget widget){
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
		if (_activeWidgetIndex >= 0)
			_activeWidget.activateEvent(false);
		if (widgetIndex < _regdWidgets.length){
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

	/// Sets position of cursor if requested by an activeWidget.
	/// only used by QTerminal itself, called right after updating is done
	void showCursor(){
		if (_activeWidget && _activeWidget.show && _activeWidget.showCursor){
			_terminal.moveTo(cast(int)_cursor.x, cast(int)_cursor.y);
			_terminal.showCursor;
		}else{
			_terminal.hideCursor();
		}
	}
public:
	/// text color, and background color
	RGB textColor, backgroundColor;
	this(string caption = "QUI Text User Interface", QLayout.Type displayType = QLayout.Type.Vertical){
		super(displayType);
		//create terminal & input
		_terminal = Terminal(ConsoleOutputType.cellular);
		_input = RealTimeConsoleInput(&_terminal, ConsoleInputFlags.allInputEvents);
		_terminal.showCursor();
		//init vars
		textColor = DEFAULT_TEXT_COLOR;
		backgroundColor = DEFAULT_BACK_COLOR;
		_termInterface = new QTermInterface(this);
		_size.height = _terminal.height;
		_size.width = _terminal.width;
		//set caption
		_terminal.setTitle(caption);
		//fill it with space, to set color
		_termInterface.setColors(textColor, backgroundColor);
		_termInterface.fill(' ');
	}
	~this(){
		_terminal.clear;
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
	
	override public void mouseEvent(MouseClick mouse){
		super.mouseEvent(mouse);
		foreach (i, widget; _widgets){
			if (widget.show && widget.wantsInput){
				Position p = widget._position;
				Size s = widget._size;
				//check x-y-axis
				if (mouse.x >= p.x && mouse.x < p.x + s.width && mouse.y >= p.y && mouse.y < p.y + s.height){
					//mark this widget as active
					makeActive(i);
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

	override public void keyboardEvent(KeyPress key){
		super.keyboardEvent(key);
		// check if the _activeWidget wants Tab, otherwise, if is Tab, make the next widget active
		if (key.key == KeyPress.NonCharKey.Escape || (key.key == '\t' && (_activeWidgetIndex < 0 || !_activeWidget.wantsTab))){
			QWidget lastActiveWidget = _activeWidget;
			// make the next widget active
			if (_regdWidgets.length > 0){
				uinteger newIndex = _activeWidgetIndex + 1;
				// see if it wants input, case no, switch to some other widget
				for (;newIndex < _regdWidgets.length; newIndex ++){
					if (_widgets[newIndex].show && _widgets[newIndex].wantsInput){
						break;
					}
				}
				makeActive(newIndex);
			}
		}else if (key in _keysToCatch){
			// this is a registered key, only a specific widget catches it
			_keysToCatch[key].keyboardEvent(key);
		}else if (_activeWidget !is null){
			_activeWidget.keyboardEvent (key);
		}
	}

	override public void update(){
		super.update;
		// set the cursor
		showCursor;
	}
	
	/// starts the UI loop
	void run(){
		// the stop watch, to count how much time has passed after each timerEvent
		StopWatch sw = StopWatch(AutoStart.no);
		//resize all widgets
		resizeEvent(_size);
		//draw the whole thing
		update();
		sw.start;
		while (true){
			if (sw.peek.total!"msecs" >= TIMER_MSECS){
				foreach (widget; _regdWidgets)
					widget.timerEvent;
				sw.reset;
			}
			// take a look at _requestingUpdate
			int timeout = cast(int)(TIMER_MSECS - sw.peek.total!"msecs");
			bool eventTriggered = false;
			// because timeout is given 0, if there's event, update will be called
			if (_requestingUpdate.length > 0)
				timeout = 0;
			if (_input.timedCheckForInput(cast(int)(TIMER_MSECS - sw.peek.total!"msecs"))){
				eventTriggered = true;
				InputEvent event = _input.nextEvent;
				//check event type
				if (event.type == event.Type.KeyboardEvent){
					KeyPress kPress;
					kPress.key = event.get!(event.Type.KeyboardEvent).which;
					this.keyboardEvent(kPress);
				}else if (event.type == event.Type.MouseEvent){
					this.mouseEvent(MouseClick(event.get!(event.Type.MouseEvent)));
				}else if (event.type == event.Type.SizeChangedEvent){
					//update self size
					_terminal.updateSize;
					_size.height = _terminal.height;
					_size.width = _terminal.width;
					// fill empty, apply color
					_termInterface.setColors(textColor, backgroundColor);
					_termInterface.fill(' ');
					//call size change on all widgets
					resizeEvent(_size);
				}else if (event.type == event.Type.UserInterruptionEvent || event.type == event.Type.HangupEvent){
					//die here
					_terminal.clear;
					break;
				}
				update;
			}
			if (!eventTriggered){
				foreach(widget; _requestingUpdate)
					widget.update;
				_requestingUpdate = [];
				showCursor;
			}
		}
	}
}
