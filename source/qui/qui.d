/++
	This module contains most of the functions you'll need.
	All the 'base' classes, like QWidget are defined in this.
+/
module qui.qui;

import std.datetime.stopwatch;
import utils.misc;
import utils.lists;
import std.conv : to;
import qui.termwrap;

import qui.utils;

/// the default foreground color
const Color DEFAULT_FG = Color.white;
/// the default background color
const Color DEFAULT_BG = Color.black;

/// Available colors are in this enum
public alias Color = qui.termwrap.Color;
/// Availabe Keys (keyboard) for input
public alias Key = qui.termwrap.Event.Keyboard.Key;
/// Mouse Event
public alias MouseEvent = Event.Mouse;
/// Keyboard Event
public alias KeyboardEvent = Event.Keyboard;

/// Used to store position for widgets
struct Position{
	/// x and y position
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

/// mouseEvent function. Return true if the event should be dropped
alias MouseEventFuction = bool delegate(QWidget, MouseEvent);
///keyboardEvent function. Return true if the event should be dropped
alias KeyboardEventFunction = bool delegate(QWidget, KeyboardEvent);
/// resizeEvent function. Return true if the event should be dropped
alias ResizeEventFunction = bool delegate(QWidget, Size);
/// activateEvent function. Return true if the event should be dropped
alias ActivateEventFunction = bool delegate(QWidget, bool);
/// TimerEvent function. Return true if the event should be dropped
alias TimerEventFunction = bool delegate(QWidget, uinteger);
/// Init function. Return true if the event should be dropped
alias InitFunction = bool delegate(QWidget);


/// Base class for all widgets, including layouts and QTerminal
///
/// Use this as parent-class for new widgets
abstract class QWidget{
private:
	/// stores the position of this widget, relative to it's parent widget's position
	Position _position;
	/// stores index of active widget. -1 if none. This is useful only for Layouts. For widgets, this stays 0
	integer _activeWidgetIndex = 0;
	/// stores if this widget is the active widget
	bool _isActive = false;
	/// stores what child widgets want updates
	bool[] _requestingUpdate;
	/// what key handlers are registered for what keys (key/index)
	QWidget[dchar]  _keyHandlers;
	/// the parent widget
	QWidget _parent = null;
	/// the index it is stored at in _parent. -1 if no parent asigned yet
	integer _indexInParent = -1;
	/// called by owner for initialize event
	void initializeCall(){
		if (!_customInitEvent || !_customInitEvent(this))
			this.initialize();
	}
	/// called by owner for mouseEvent
	void mouseEventCall(MouseEvent mouse){
		mouse.x = mouse.x - cast(int)this._position.x;
		mouse.y = mouse.y - cast(int)this._position.y;
		if (!_customMouseEvent || !_customMouseEvent(this, mouse))
			this.mouseEvent(mouse);
	}
	/// called by owner for keyboardEvent
	void keyboardEventCall(KeyboardEvent key){
		if (!_customKeyboardEvent || !_customKeyboardEvent(this, key))
			this.keyboardEvent(key);
	}
	/// called by owner for resizeEvent
	void resizeEventCall(Size size){
		this._size = size;
		_display._width = size.width;
		_display._height = size.height;
		_display._xOff = _position.x;
		_display._yOff = _position.y;
		if (!_customResizeEvent || !_customResizeEvent(this, size))
			this.resizeEvent(size);
	}
	/// called by owner for activateEvent
	void activateEventCall(bool isActive){
		if (!_customActivateEvent || !_customActivateEvent(this, isActive))
			this.activateEvent(isActive);
	}
	/// called by owner for mouseEvent
	void timerEventCall(uinteger msecs){
		if (!_customTimerEvent || !_customTimerEvent(this, msecs))
			this.timerEvent(msecs);
	}
	/// Called by children of this widget to request updates
	void requestUpdate(uinteger index){
		if (index < _requestingUpdate.length){
			_requestingUpdate[index] = true;
			requestUpdate();
		}
	}
	/// Called by children of this widget to register key handlers
	bool registerKeyHandler(QWidget widget, dchar key){
		if (key in _keyHandlers || _parent is null)
			return false;
		_keyHandlers[key] = widget;
		this.registerKeyHandler(key);
		return true;
	}
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
	/// whether the cursor should be visible or not
	bool _showCursor = false;
	/// used to write to terminal
	Display _display = null;

	/// For cycling between widgets. Returns false, always.
	bool cycleActiveWidget(){
		return false;
	}

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
	void update(){}

	/// Called after `_termInterface` has been set and this widget is ready to be used
	void initialize(){}
	/// Called when mouse is clicked with cursor on this widget.
	void mouseEvent(MouseEvent mouse){}
	/// Called when key is pressed and this widget is active.
	void keyboardEvent(KeyboardEvent key){}
	/// Called when widget size is changed.
	void resizeEvent(Size size){}
	/// called right after this widget is activated, or de-activated, i.e: is made _activeWidget, or un-made _activeWidget
	void activateEvent(bool isActive){}
	/// called often. `msecs` is the msecs since last timerEvent, not accurate
	void timerEvent(uinteger msecs){}
public:
	/// Called by itself when it needs to request an update
	void requestUpdate(){
		if (_parent && _indexInParent > -1 && _indexInParent < _parent._requestingUpdate.length && 
		_parent._requestingUpdate[_indexInParent] == false)
			_parent.requestUpdate(_indexInParent);
	}
	/// Called by itself (not necessarily) to register itself as a key handler
	bool registerKeyHandler(dchar key){
		return _parent && _indexInParent > -1 && _parent.registerKeyHandler(this, key);
	}
	/// use to change the custom initialize event
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
	/// Returns: this widget's parent
	@property QWidget parent(){
		return _parent;
	}
	/// Returns: true if this widget is the current active widget
	@property bool isActive(){
		return _isActive;
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
	/// Returns: position of cursor to be shown on terminal. (-1,-1) if dont show
	@property Position cursorPosition(){
		return Position(-1,-1);
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
					uinteger newSpace = ratioToRaw(widget._sizeRatio, totalRatio, totalSpace);
					const uinteger calculatedSpace = newSpace;
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
						totalRatio -= widget._sizeRatio;
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
		static if (T != QLayout.Type.Horizontal && T != QLayout.Type.Vertical)
			assert(false);
		uinteger previousSpace = 0;
		foreach(widget; widgets){
			if (widget.show){
				static if (T == QLayout.Type.Horizontal){
					widget._position.y = 0;
					widget._position.x = previousSpace;
					previousSpace += widget.size.width;
				}else{
					widget._position.x = 0;
					widget._position.y = previousSpace;
					previousSpace += widget.size.height;
				}
			}
		}
	}
protected:
	/// Recalculates size and position for all visible widgets
	/// If a widget is too large to fit in, it's visibility is marked false
	override void resizeEvent(Size size){
		uinteger ratioTotal;
		foreach(w; _widgets){
			if (w.show){
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
			widget.resizeEventCall(size);
		}
	}
	
	/// Redirects the mouseEvent to the appropriate widget
	override public void mouseEvent(MouseEvent mouse) {
		/// first check if it's already inside active widget, might not have to search through each widget
		QWidget activeWidget = null;
		if (_activeWidgetIndex > -1)
			activeWidget = _widgets[_activeWidgetIndex];
		if (activeWidget && mouse.x >= activeWidget._position.x && mouse.x < activeWidget._position.x + activeWidget.size.width 
		&& mouse.y >= activeWidget._position.y && mouse.y < activeWidget._position.y + activeWidget.size.height){
			activeWidget.mouseEventCall(mouse);
		}else{
			foreach (i, widget; _widgets){
				if (widget.show && widget._wantsInput &&
					mouse.x >= widget._position.x && mouse.x < widget._position.x + widget.size.width &&
					mouse.y >= widget._position.y && mouse.y < widget._position.y + widget.size.height){
					// make it active only if this layout is itself active
					if (this.isActive){
						if (activeWidget)
							activeWidget._isActive = false;
						widget._isActive = true;
						_activeWidgetIndex = i;
					}
					widget.mouseEventCall(mouse);
					break;
				}
			}
		}
	}

	/// Redirects the keyboardEvent to appropriate widget
	override public void keyboardEvent(KeyboardEvent key){
		// check if key handler registered
		if (key.key in _keyHandlers)
			_keyHandlers[key.key].keyboardEventCall(key);
		// check if need to cycle
		if ((key.key == '\t' && (_activeWidgetIndex == -1 || !_widgets[_activeWidgetIndex].wantsTab)) || 
		key.key == KeyboardEvent.Key.Escape){
			this.cycleActiveWidget();
		}else if (_activeWidgetIndex > -1){
			_widgets[_activeWidgetIndex].keyboardEventCall(key);
		}
	}

	/// override initialize to initliaze child widgets
	override void initialize(){
		foreach (widget; _widgets){
			widget._display = _display.getSlice(1,1, _position.x, _position.y); // just throw in dummy size/position, resize event will fix that
			widget.initializeCall();
		}
	}

	/// override timer event to call child widgets' timers
	override void timerEvent(uinteger msecs){
		foreach (widget; _widgets){
			widget.timerEventCall(msecs);
		}
	}

	/// override activate event
	override void activateEvent(bool isActive){
		if (isActive){
			_activeWidgetIndex = -1;
			this.cycleActiveWidget();
		}else if (_activeWidgetIndex > -1){
			_widgets[_activeWidgetIndex].activateEventCall(isActive);
		}
	}
	
	/// called by owner widget to update
	override void update(){
		foreach(i, widget; _widgets){
			if (_requestingUpdate[i] && widget.show){
				widget.update();
				_requestingUpdate[i] = false;
			}
		}
	}
	/// called to cycle between actveWidgets. This is called by owner widget
	/// 
	/// Returns: true if cycled to another widget, false if _activeWidgetIndex set to -1
	override bool cycleActiveWidget(){
		// check if need to cycle within current active widget
		if (_activeWidgetIndex == -1 || !(_widgets[_activeWidgetIndex].cycleActiveWidget())){
			integer lastActiveWidgetIndex = _activeWidgetIndex;
			if (_activeWidgetIndex == -1)
				_activeWidgetIndex = 0;
			for (; _activeWidgetIndex < _widgets.length; _activeWidgetIndex ++){
				if (_widgets[_activeWidgetIndex].wantsInput && _widgets[_activeWidgetIndex].show)
					break;
			}
			if (_activeWidgetIndex >= _widgets.length)
				_activeWidgetIndex = -1;
			
			if (lastActiveWidgetIndex != _activeWidgetIndex){
				if (lastActiveWidgetIndex > -1)
					_widgets[lastActiveWidgetIndex].activateEventCall(false);
				if (_activeWidgetIndex > -1)
					_widgets[_activeWidgetIndex].activateEventCall(true);
			}
		}
		return _activeWidgetIndex != -1;
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
	/// Returns: whether the widget is receiving the Tab key press or not
	override @property bool wantsTab(){
		foreach (widget; _widgets){
			if (widget.wantsTab)
				return true;
		}
		return false;
	}
	/// Returns: true if the widget wants input
	override @property bool wantsInput(){
		foreach (widget; _widgets){
			if (widget.wantsInput)
				return true;
		}
		return false;
	}
	/// Returns: true if the cursor should be visible if this widget is active
	override @property Position cursorPosition(){
		// just do a hack, and check only for active widget
		return _activeWidgetIndex > -1 ? _widgets[_activeWidgetIndex].cursorPosition : Position(-1,-1);
	}
	
	/// adds (appends) a widget to the widgetList, and makes space for it
	/// 
	/// If there a widget is too large, it's marked as not visible
	void addWidget(QWidget widget){
		widget._parent = this;
		widget._indexInParent = _widgets.length;
		//add it to array
		_widgets ~= widget;
		// make space in _requestingUpdate
		_requestingUpdate ~= true;
	}
	/// adds (appends) widgets to the widgetList, and makes space for them
	/// 
	/// If there a widget is too large, it's marked as not visible
	void addWidget(QWidget[] widgets){
		foreach (i, widget; widgets){
			widget._parent = this;
			widget._indexInParent = _widgets.length+i;
		}
		// add to array
		_widgets ~= widgets.dup;
		// make space in _requestingUpdate
		bool[] reqUpdates;
		reqUpdates.length = widgets.length;
		reqUpdates[] = true;
		_requestingUpdate ~= reqUpdates;
	}
}

/// Used to write to display by widgets
class Display{
private:
	/// width & height
	uinteger _width, _height;
	/// x and y offsets
	uinteger _xOff, _yOff;
	/// cursor position
	Position _cursor;
	/// the terminal
	TermWrapper _term;
	/// constructor for when this buffer is just a slice of the actual buffer
	this(uinteger w, uinteger h, uinteger xOff, uinteger yOff, TermWrapper terminal){
		_xOff = xOff;
		_yOff = yOff;
		_width = w;
		_height = h;
		_term = terminal;
	}
	/// Returns: a "slice" of this buffer, that is only limited to some rectangular area
	Display getSlice(uinteger w, uinteger h, uinteger x, uinteger y){
		return new Display(w, h, x, y, _term);
	}
public:
	/// constructor
	this(uinteger w, uinteger h, TermWrapper terminal){
		_width = w;
		_height = h;
		_term = terminal;
	}
	~this(){

	}
	/// Returns: cursor  position
	@property Position cursor(){
		return _cursor;
	}
	/// ditto
	@property Position cursor(Position newPos){
		if (newPos.x >= _width)
			newPos.x = _width-1;
		if (newPos.y >= _height)
			newPos.y = _height-1;
		return _cursor = newPos;
	}
	/// Writes a line. if string has more characters than there is space for, extra characters will be ignored.
	/// Tab character is converted to a single space character
	void write(dstring str, Color fg, Color bg){
		str = str.dup;
		while (str.length > 0){
			if (_cursor.x == _width-1){
				if (_cursor.y < _height){
					_cursor.y ++;
					_cursor.x = 0;
				}else{
					break;
				}
			}
			dchar[] line = cast(dchar[])str[0 .. _width - (_cursor.x > str.length ? str.length : _width - _cursor.x)];
			str = str[line.length .. $];
			// change `\t` to ` `
			foreach (i; 0 .. line.length)
				if (line[i] == '\t')
					line[i] = ' ';
			_term.write(cast(int)(_cursor.x + _xOff), cast(int)(_cursor.y + _yOff), cast(dstring)line, fg, bg);
			_cursor.x += line.length;
		}
	}
	/// ditto
	void write(dstring str){
		str = str.dup;
		while (str.length > 0){
			if (_cursor.x == _width-1){
				if (_cursor.y < _height){
					_cursor.y ++;
					_cursor.x = 0;
				}else{
					break;
				}
			}
			dchar[] line = cast(dchar[])str[0 .. _width - (_cursor.x > str.length ? str.length : _width - _cursor.x)];
			str = str[line.length .. $];
			// change `\t` to ` `
			foreach (i; 0 .. line.length)
				if (line[i] == '\t')
					line[i] = ' ';
			_term.write(cast(int)(_cursor.x + _xOff), cast(int)(_cursor.y + _yOff), cast(dstring)line);
			_cursor.x += line.length;
		}
	}
	/// fills all remaining cells with a character
	void fill(dchar c, Color fg, Color bg){
		dchar[] line;
		line.length = _width;
		line[] = c;
		while (_cursor.y < _height){
			_term.write(cast(int)(_cursor.x + _xOff), cast(int)(_cursor.y + _yOff), cast(dstring)line[0 .. _width - _cursor.x],
				fg, bg);
			_cursor.y ++;
			_cursor.x = 0;
		}
	}
	/// fills rest of current line with a character
	void fillLine(dchar c, Color fg, Color bg, uinteger max = 0){
		dchar[] line;
		line.length =  max < _width - _cursor.x ? max : _width - _cursor.x;
		line[] = c;
		_term.write(cast(int)(_cursor.x + _xOff), cast(int)(_cursor.y + _yOff), cast(dstring)line);
		_cursor.x += line.length;
		if (_cursor.x == _width){
			_cursor.y ++;
			_cursor.x = 0;
		}
	}
}

/// A terminal (as the name says).
class QTerminal : QLayout{
private:
	/// To actually access the terminal
	TermWrapper _termWrap;
	/// set to false to stop UI loop in run()
	bool _isRunning;

	/// Reads InputEvent[] and calls appropriate functions to address those events
	void readEvent(Event event){
		if (event.type == Event.Type.HangupInterrupt){
			_isRunning = false;
		}else if (event.type == Event.Type.Keyboard){
			KeyboardEvent kPress = event.keyboard;
			this.keyboardEventCall(kPress);
		}else if (event.type == Event.Type.Mouse){
			this.mouseEventCall(event.mouse);
		}else if (event.type == Event.Type.Resize){
			//update self size
			_size.height = event.resize.height;
			_size.width = event.resize.width;
			//call size change on all widgets
			resizeEventCall(_size);
		}
	}

protected:
	
	override void update(){
		super.update();
		// check if need to show/hide cursor
		Position cursorPos = _widgets[_activeWidgetIndex].cursorPosition;
		if (_activeWidgetIndex > -1 && cursorPos != Position(-1,-1)){
			_termWrap.moveCursor(cast(int)cursorPos.x, cast(int)cursorPos.y);
			_termWrap.cursorVisible = true;
		}else
			_termWrap.cursorVisible = false;
		_termWrap.flush;
	}

public:
	/// text color, and background color
	Color textColor, backgroundColor;
	/// time to wait between timer events (milliseconds)
	ushort timerMsecs;
	/// constructor
	this(QLayout.Type displayType = QLayout.Type.Vertical, ushort timerDuration = 500){
		super(displayType);

		textColor = DEFAULT_FG;
		backgroundColor = DEFAULT_BG;
		timerMsecs = timerDuration;

		_termWrap = new TermWrapper();
		_display = new Display(1,1, _termWrap);
	}
	~this(){
		.destroy(_termWrap);
		.destroy(_display);
	}

	/// stops UI loop. **not instantly**, if it is in-between updates, calling event functions, or timers, it will complete those first
	void terminate(){
		_isRunning = false;
	}
	
	/// starts the UI loop
	void run(){
		// init termbox
		_size.width = _termWrap.width();
		_size.height = _termWrap.height();
		//ready
		initializeCall();
		resizeEventCall(_size);
		//draw the whole thing
		update();
		_isRunning = true;
		// the stop watch, to count how much time has passed after each timerEvent
		StopWatch sw = StopWatch(AutoStart.yes);
		while (_isRunning){
			int timeout = cast(int)(timerMsecs - sw.peek.total!"msecs");
			Event event;
			while (_termWrap.getEvent(timeout, event) > 0){
				readEvent(event);
				timeout = cast(int)(timerMsecs - sw.peek.total!"msecs");
				update();
			}
			if (sw.peek.total!"msecs" >= timerMsecs){
				foreach (widget; _widgets)
					widget.timerEventCall(sw.peek.total!"msecs");
				sw.reset;
				sw.start;
				update();
			}
		}
	}
}