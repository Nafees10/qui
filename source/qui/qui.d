/++
	This module contains most of the functions you'll need.
	All the 'base' classes, like QWidget are defined in this.
+/
module qui.qui;

import std.datetime.stopwatch;
import std.concurrency;
import utils.misc;
import std.conv : to;
import termbox;

import qui.utils;

/// How much time between each timer event
const ushort TIMER_MSECS = 500;
/// If a widget registers itself as keyHandler for either of these keys, the keyboardEvent for _activeWidget will also be called 
/// when these keys are tirggered, along with handler's keyboardEvent
const UNCATCHABLE_KEYS = [Key.space, Key.backspace, Key.tab];

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
	/// 
	/// if the character is present in enum `Key` as well, then it's value will be in `KeyboardEvent.key` as well
	dchar charKey;
	/// which key was pressed, only valid if `charKey == 0`, or if reported char is also present in enum `Key`
	Key key;
	/// Returns: true if the pressed key is not a character
	/// 
	/// Enter (`\n`), Tab (`\t`), backsace (`\b`) are considered characters too
	@property bool isChar(){
		if (charKey)
			return true;
		return false;
	}
	/// Returns: a string representation of KeyPress, in JSON
	string tostring(){
		if (isChar){
			return "{charKey:"~cast(char)~'}';
		}
		return "{key:"~to!string(key)~'}';
	}
	/// constructor to construct from termbox.Event
	private this(Event e){
		this.charKey = e.ch;
		if (this.charKey == 0){
			this.key = cast(Key)e.key;
			if (this.key == Key.space)
				charKey = cast(dchar)' ';
			else if (this.key == Key.backspace)
				charKey = cast(dchar)'\b';
			else if (this.key == Key.tab)
				charKey = cast(dchar)'\t';
			else if (this.key == Key.enter)
				charKey = cast(dchar)'\n';
		}
	}
}

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
	/// specifies if the widget needs to show the cursor
	bool _showCursor = false;
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
	abstract void update();

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
	/// Returns: whether the widget needs to show a cursor, only considered when this widget is active
	@property bool showCursor(){
		return _showCursor;
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
	override void update(){
		foreach(widget; _widgets){
			_termInterface.restrictWrite(widget._position.x, widget._position.y, widget._size.width, widget._size.height);
			widget.update();
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
		if (x + width >= _qterminal._size.width || y + height >= _qterminal._size.height || width == 0 || height == 0)
			return false;
		// TODO implement restrictWrite
	}
public:
	this(QTerminal term){
		_qterminal = term;
	}
	/// Returns: true if the caller widget is _activeWidget
	bool isActive(QWidget caller){
		return _qterminal.isActive(caller);
	}
	/// Sets color
	/// 
	/// Returs: true if successful, false if not
	bool setColors(Color foreground, Color background){
		// TODO implement setColors
	}
	/// Writes characters on terminal
	/// 
	/// if `c` has more characters than there is space for, first few will be written, rest will be skipped
	/// 
	/// Returns: true if successful, false if not, or if there was not space for some characters (or all)
	bool write(char[] c){
		// TODO implement write
	}
	/// Fills the terminal, or restricted area, with a character
	void fill(char c){
		// TODO implement fill
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
		// TODO implement setting the _cursorPos
		return _cursorPos;
	}
	/// sets position of cursor on terminal.
	/// 
	/// position is relative to caller widget's position.
	/// 
	/// Returns: true if successful, false if not
	bool setCursorPos(QWidget caller, uinteger x, uinteger y){
		if (_qterminal.isActive(caller)){
			_postUpdateCursorPos.x = _qterminal._activeWidget._position.x + x;
			_postUpdateCursorPos.y = _qterminal._activeWidget._position.y + y;
			// TODO implement setting _postUpdateCursorPos
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
		if (_activeWidget && _activeWidget._show && _activeWidget._showCursor){
			// todo implement show/hide cursor
		}else{
			// hide
		}
	}

	/// Reads InputEvent[] and calls appropriate functions to address those events
	/// 
	/// Returns: true when there is no need to terminate (no CTRL+C pressed). false when it should terminate
	bool readEvents(Event[] events){
		foreach (event; events){
			if (event.type == EventType.key){
				if (event.key == Key.ctrlC){
					break;
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
					continue;
				this.mouseEvent(mEvent);
			}else if (event.type == EventType.resize){
				//update self size
				_size.height = event.h;
				_size.width = event.w;
				// fill empty, apply color
				_termInterface.setColors(textColor, backgroundColor);
				_termInterface.fill(' ');
				//call size change on all widgets
				resizeEvent(_size);
			}
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
	
	override public void update(){
		super.update;
		// set the cursor
		showCursor;
	}

public:
	/// text color, and background color
	Color textColor, backgroundColor;
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
		// TODO terminate the other thread
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
			// because timeout is given 0, if there's event, update will be called
			if (_requestingUpdate.length > 0)
				timeout = 0;
			if (_input.timedCheckForInput(cast(int)(cast(long)TIMER_MSECS - sw.peek.total!"msecs"))){
				// go through the events
				if (!readEvents(_input.readNextEvents))
					break;
				update;
			}else{
				// if no events triggered, then just update the widgets that want to be updated
				foreach(widget; _requestingUpdate)
					widget.update;
				showCursor;
			}
			_requestingUpdate = [];
		}
	}
}

/// used to contain messages sent to the terminalIOThread
private struct IOMessage{
	enum Type{
		UpdateProperties, /// updates terminal's properties. The new properties are in `newProperties`
		UpdateWriteProperties, /// updates writing properties. New properties in `newWriteProperties`
		UpdateCursorProperties, /// updates cursor properties. New properties in `newCursorProperties`
		Write, /// write on terminal. text to write in `writeChar`
		CheckEvent, /// stop receiving messages, wait for event, then send it
		Fill, /// fill the terminal with a space character. bg and fg colors will be used from last received writeProperties
		Terminate, /// shutdown termbox and terminate the terminalIOThread
	}
}

/// runs in a separate thread, receives input from termbox, and writes to termbox
private void terminalIOThread(){
	// init termbox
	init();
	// TODO receive commands from ownerTid and do them
	shutdown();
}