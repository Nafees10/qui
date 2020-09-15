/++
	This module contains most of the functions you'll need.
	All the 'base' classes, like QWidget are defined in this.
+/
module qui.qui;

import std.datetime.stopwatch;
import utils.misc;
import std.conv : to;
import qui.termwrap;

import qui.utils;

/// How much time between each timer event
const ushort TIMER_MSECS = 500;
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
	/// x and u position
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
	/// 
	/// This is private so it won't be modified by the widget, only classes present in this module are concerned with it
	Position _position;
	/// stores index of active widget. -1 if none. This is useful only for Layouts. For widgets, this stays 0
	integer _activeWidgetIndex = 0;
	/// stores if this widget is the active widget
	bool _isActive = false;
	/// called by owner for initialize event
	void initializeCall(){
		if (!_customInitEvent || !_customInitEvent(this))
			this.initialize();
	}
	/// called by owner for mouseEvent
	void mouseEventCall(MouseEvent mouse){
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
	/// the interface used to "talk" to the terminal
	QTermInterface _termInterface = null;

	/// For cycling between widgets. Returns false, always.
	bool cycleActiveWidget(bool forward = true){
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
	/// 
	/// If `force==true`, then the widget must update, whether it needs to or not
	abstract void update(bool force=false);

	/// Called by QTerminal after `_termInterface` has been set and this widget is ready to be used
	abstract void initialize();
	/// Called by parent when mouse is clicked with cursor on this widget.
	abstract void mouseEvent(MouseEvent mouse);
	/// Called by parent when key is pressed and this widget is active.
	abstract void keyboardEvent(KeyboardEvent key);
	/// Called by parent when widget size is changed.
	abstract void resizeEvent(Size size);
	/// called by QTerminal right after this widget is activated, or de-activated, i.e: is made _activeWidget, or un-made _activeWidget
	abstract void activateEvent(bool isActive);
	/// called by QTerminal often. `msecs` is the msecs since last timerEvent, not accurate
	abstract void timerEvent(uinteger msecs);
public:
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
		static if (T != QLayout.Type.Horizontal && T != QLayout.Type.Vertical){
			assert(false);
		}
		uinteger previousSpace = (T == QLayout.Type.Horizontal ? _position.x : _position.y);
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
			widget.resizeEvent(size);
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
			activeWidget.mouseEvent(mouse);
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
					widget.mouseEvent(mouse);
					break;
				}
			}
		}
	}

	/// Redirects the keyboardEvent to appropriate widget
	override public void keyboardEvent(KeyboardEvent key){
		// check if need to cycle
		if ((key.key == '\t' && (_activeWidgetIndex == -1 || !_widgets[_activeWidgetIndex].wantsTab)) || 
		key.key == KeyboardEvent.Key.Escape){
			cycleActiveWidget();
		}else if (_activeWidgetIndex > -1){
			_widgets[_activeWidgetIndex].keyboardEventCall(key);
		}
	}

	/// override initialize to initliaze child widgets
	override void initialize(){
		foreach (widget; _widgets){
			widget._termInterface = _termInterface;
		}
	}
	
	/// called by owner widget to update
	override void update(bool force=false){
		foreach(widget; _widgets){
			if (widget.show){
				_termInterface.restrictWrite(widget._position.x, widget._position.y, widget.size.width, widget.size.height);
				widget.update(force);
			}
		}
	}
	/// called to cycle between actveWidgets. This is called by owner widget
	/// 
	/// Returns: true if cycled to another widget, false if _activeWidgetIndex set to -1
	override bool cycleActiveWidget(bool forward = true){
		// check if need to cycle within current active widget
		if (_activeWidgetIndex == -1 || !(_widgets[_activeWidgetIndex].cycleActiveWidget(forward))){
			integer lastActiveWidgetIndex = _activeWidgetIndex;
			if (forward){
				if (_activeWidgetIndex < 0)
					_activeWidgetIndex = 0;
				for (; _activeWidgetIndex < _widgets.length; _activeWidgetIndex ++){
					if (_widgets[_activeWidgetIndex].wantsInput && _widgets[_activeWidgetIndex].show)
						break;
				}
				if (_activeWidgetIndex >= _widgets.length)
					_activeWidgetIndex = -1;
			}else if (_widgets.length > 0){
				if (_activeWidgetIndex < 0)
					_activeWidgetIndex = cast(integer)(_widgets.length)-1;
				for (; _activeWidgetIndex >= 0; _activeWidgetIndex --){
					if (_widgets[_activeWidgetIndex].wantsInput && _widgets[_activeWidgetIndex].show)
						break;
				}
				if (_activeWidgetIndex < 0)
					_activeWidgetIndex = -1;
			}
			
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

	/// Cycles between active widgets. If current active widget is last in the list, the first will be made active
	/// 
	/// does effectively nothing if no widgets added, or no widgets want input, or if this layout isn't the active widget
	void cycleActiveWidgetLoop(bool forward = true){
		if (this.isActive && _widgets.length > 0){
			immutable integer lastActiveWidgetIndex = _activeWidgetIndex;
			if (_activeWidgetIndex == -1)
				_activeWidgetIndex = 0;
			immutable integer startIndex = _activeWidgetIndex;
			do{
				if (_widgets[_activeWidgetIndex].wantsInput && _widgets[_activeWidgetIndex].show)
					break;
				_activeWidgetIndex = _activeWidgetIndex + (forward ? 1 : -1);
				if (_activeWidgetIndex >= _widgets.length)
					_activeWidgetIndex = 0;
				else if (_activeWidgetIndex < 0)
					_activeWidgetIndex = cast(integer)_widgets.length - 1;
			}while (_activeWidgetIndex != lastActiveWidgetIndex);
			if (_activeWidgetIndex != lastActiveWidgetIndex){
				if (lastActiveWidgetIndex != -1){
					_widgets[lastActiveWidgetIndex]._isActive = false;
					_widgets[lastActiveWidgetIndex].activateEventCall(false);
				}
				if (_activeWidgetIndex != -1){
					_widgets[_activeWidgetIndex]._isActive = true;
					_widgets[_activeWidgetIndex].activateEventCall(true);
				}
			}
		}
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

/// Used by widgets to draw on terminal & etc
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
		if (x + width > _qterminal.size.width || y + height > _qterminal.size.height || width == 0 || height == 0)
			return false;
		_restrictX1 = x;
		_restrictX2 = x + width;
		_restrictY1 = y;
		_restrictY2 = y + height;
		// move to position
		_qterminal._termWrap.moveCursor(cast(int)x, cast(int)y);
		_cursorPos = Position(x, y);
		return true;
	}
	/// called by QTerminal after all updating is finished, and right before checking for more events
	void updateFinished(){
		// set cursor position
		_qterminal._termWrap.moveCursor(cast(int)_postUpdateCursorPos.x, cast(int)_postUpdateCursorPos.y);
		// flush
		_qterminal._termWrap.flush();
	}
	/// called by QTerminal right before starting to update widgets
	void updateStarted(){
		// set cursor position to (-1,-1), so if not set, its not visible
		_qterminal._termWrap.cursorVisible = false;
	}
public:
	/// Constructor
	this(QTerminal term){
		_qterminal = term;
	}
	/// Writes characters on terminal
	/// 
	/// if `c` has more characters than there is space for, first few will be written, rest will be skipped.  
	/// **and tab character is not supported, as in it will be read as a single space character. `'\t' = ' '`**
	void write(dstring c, Color fg, Color bg){
		for (uinteger i = 0; _cursorPos.y < _restrictY2;){
			for (; _cursorPos.x < _restrictX2 && i < c.length; _cursorPos.x ++){
				if (c[i] == '\t')
					_qterminal._termWrap.put(cast(int)_cursorPos.x, cast(int)_cursorPos.y,' ', fg, bg);
				else
					_qterminal._termWrap.put(cast(int)_cursorPos.x, cast(int)_cursorPos.y, c[i], fg, bg);
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
	void fillLine(dchar c, Color fg, Color bg, uinteger maxCount = 0){
		for (uinteger i = 0; _cursorPos.x < _restrictX2; _cursorPos.x ++){
			_qterminal._termWrap.put(cast(int)_cursorPos.x, cast(int)_cursorPos.y, c, fg, bg);
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
	void fill(dchar c, Color fg, Color bg){
		for (; _cursorPos.y < _restrictY2; _cursorPos.y ++){
			for (; _cursorPos.x < _restrictX2; _cursorPos.x ++){
				_qterminal._termWrap.put(cast(int)_cursorPos.x, cast(int)_cursorPos.y, c, fg, bg);
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
		_qterminal._termWrap.moveCursor(cast(int)_cursorPos.x, cast(int)_cursorPos.y);
		return _cursorPos;
	}
	/// sets position of cursor on terminal, after updating is done
	/// 
	/// position is relative to caller widget's position.
	/// 
	/// Returns: true if successful, false if not
	void setCursorPos(QWidget caller, uinteger x, uinteger y){
		_postUpdateCursorPos.x = caller._position.x + x;
		_postUpdateCursorPos.y = caller._position.y + y;
		_qterminal._termWrap.cursorVisible = true;
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
class QTerminal : QLayout{
private:
	/// To actually access the terminal
	TermWrapper _termWrap;
	/// stores list of keys and widgets that will catch their KeyPress event
	QWidget[dchar] _keysToCatch;
	/// list of widgets requesting early `update();`
	QWidget[] _requestingUpdate;

	/// registers a key with a widget, so regardless of _activeWidget, that widget will catch that key's KeyPress event
	/// 
	/// Returns:  true on success, false on failure, which can occur because that key is already registered, or if widget is not registered
	bool registerKeyHandler(dchar key, QWidget widget){
		if (key in _keysToCatch){
			return false;
		}else{
			_keysToCatch[key] = widget;
			return true;
		}
	}

	/// adds a widget to `_requestingUpdate`, so it'll be updated right after `timerEvent`s are done with
	void requestUpdate(QWidget widget){
		_requestingUpdate ~= widget;
	}

	/// Reads InputEvent[] and calls appropriate functions to address those events
	/// 
	/// Returns: true when there is no need to terminate (no CTRL+C pressed). false when it should terminate
	bool readEvent(Event event){
		if (event.type == Event.Type.HangupInterrupt){
			return false;
		}else if (event.type == Event.Type.Keyboard){
			KeyboardEvent kPress = event.keyboard;
			this.keyboardEvent(kPress);
		}else if (event.type == Event.Type.Mouse){
			this.mouseEvent(event.mouse);
		}else if (event.type == Event.Type.Resize){
			//update self size
			_size.height = event.resize.height;
			_size.width = event.resize.width;
			//call size change on all widgets
			resizeEvent(_size);
		}
		return true;
	}

protected:
	override public void mouseEvent(MouseEvent mouse){
		foreach (i, widget; _regdWidgets){
			if (widget.show && widget.wantsInput){
				Position p = widget._position;
				Size s = widget.size;
				//check x-y-axis
				if (mouse.x >= p.x && mouse.x < p.x + s.width && mouse.y >= p.y && mouse.y < p.y + s.height){
					//mark this widget as active
					if (makeActive(i) && _activeWidgetIndex == i){
						// make mouse position relative to widget position, not 0:0
						mouse.x = mouse.x - cast(int)_activeWidget._position.x;
						mouse.y = mouse.y - cast(int)_activeWidget._position.y;
						//call mouseEvent
						widget.mouseEvent(mouse);
					}
					break;
				}
			}
		}
	}
	
	override public void keyboardEvent(KeyboardEvent key){
		// check if the _activeWidget wants Tab, otherwise, if is Tab, make the next widget active
		if (key.key == Key.Escape || (key.key == '\t' && (!_activeWidget || !_activeWidget.wantsTab))){
			// make the next widget active
			makeActive(_activeWidgetIndex+1);
		}else if (_activeWidget !is null){
			_activeWidget.keyboardEvent (key);
		}
		if (key.key in _keysToCatch){
			_keysToCatch[key.key].keyboardEvent(key);
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
	/// constructor
	this(QLayout.Type displayType = QLayout.Type.Vertical){
		super(displayType);

		textColor = DEFAULT_FG;
		backgroundColor = DEFAULT_BG;

		_termWrap = new TermWrapper();
		_termInterface = new QTermInterface(this);
	}
	~this(){
		.destroy(_termWrap);
		.destroy(_termInterface);
	}

	/// registers a widget
	/// 
	/// **All** widgets that are to be present on terminal must be registered.  
	/// All means widgets added to QTerminal, and any QLayout and any other widget.
	void registerWidget(QWidget widget){
		_regdWidgets ~= widget;
		widget._termInterface = _termInterface;
		widget.initialize();
	}
	/// registers widgets
	/// 
	/// **All** widgets that are to be present on terminal must be registered.  
	/// All means widgets added to QTerminal, and any QLayout and any other widget.
	void registerWidget(QWidget[] widgets){
		_regdWidgets = _regdWidgets ~ widgets.dup;
		foreach (widget; widgets){
			widget._termInterface = _termInterface;
			widget.initialize();
		}
	}
	
	/// starts the UI loop
	void run(){
		// init termbox
		_size.width = _termWrap.width();
		_size.height = _termWrap.height();
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
			if (_termWrap.getEvent(timeout, event) > 0){
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
						if (widget.show){
							_termInterface.restrictWrite(widget._position.x, widget._position.y, widget.size.width, widget.size.height);
							widget.update;
						}
					}
					_termInterface.updateFinished;
				}
			}
			_requestingUpdate = [];
		}
	}
}