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
	int x = 0, y = 0;
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
		uint _w = 0, _h = 0;
		/// width
		@property uint width(uint newWidth){
			if (newWidth == 0)
				return _w = 0;
			if (minWidth > 0 && newWidth < minWidth){
				return _w = minWidth;
			}else if (maxWidth > 0 && newWidth > maxWidth){
				return _w = maxWidth;
			}
			return _w = newWidth;
		}
		/// height
		@property uint height(uint newHeight){
			if (newHeight == 0)
				return _h = 0;
			if (minHeight > 0 && newHeight < minHeight){
				return _h = minHeight;
			}else if (maxHeight > 0 && newHeight > maxHeight){
				return _h = maxHeight;
			}
			return _h = newHeight;
		}
	}
	/// width
	@property uint width(){
		return _w;
	}
	/// height
	@property uint height(){
		return _h;
	}
	
	/// minimun width & height. These are "applied" automatically when setting value using `width` or `height`
	uint minWidth = 0, minHeight = 0;
	/// maximum width & height. These are "applied" automatically when setting value using `width` or `height`
	uint maxWidth = 0, maxHeight = 0;
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
alias ResizeEventFunction = bool delegate(QWidget);
/// activateEvent function. Return true if the event should be dropped
alias ActivateEventFunction = bool delegate(QWidget, bool);
/// TimerEvent function. Return true if the event should be dropped
alias TimerEventFunction = bool delegate(QWidget, uint);
/// Init function. Return true if the event should be dropped
alias InitFunction = bool delegate(QWidget);


/// Base class for all widgets, including layouts and QTerminal
///
/// Use this as parent-class for new widgets
abstract class QWidget{
private:
	/// stores the position of this widget, relative to it's parent widget's position
	Position _position;
	/// stores if this widget is the active widget
	bool _isActive = false;
	/// stores what child widgets want updates
	bool[] _requestingUpdate;
	/// what key handlers are registered for what keys (key/index)
	QWidget[dchar]  _keyHandlers;
	/// the parent widget
	QWidget _parent = null;
	/// the index it is stored at in _parent. -1 if no parent asigned yet
	int _indexInParent = -1;
	/// the key used for cycling active widget, defaults to tab
	dchar _activeWidgetCycleKey = '\t';
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
	void resizeEventCall(){
		if (!_customResizeEvent || !_customResizeEvent(this))
			this.resizeEvent();
	}
	/// called by owner for activateEvent
	void activateEventCall(bool isActive){
		_isActive = isActive;
		if (!_customActivateEvent || !_customActivateEvent(this, isActive))
			this.activateEvent(isActive);
	}
	/// called by owner for mouseEvent
	void timerEventCall(uint msecs){
		if (!_customTimerEvent || !_customTimerEvent(this, msecs))
			this.timerEvent(msecs);
	}
	/// Called by children of this widget to request updates
	void requestUpdate(uint index){
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
	uint _sizeRatio = 1;
	/// specifies whether this widget should receive the Tab key press, default is false, and should only be changed to true
	/// if only required, for example, in text editors
	bool _wantsTab = false;
	/// whether the widget wants input
	bool _wantsInput = false;
	/// used to write to terminal
	Display _display = null;

	/// For cycling between widgets. Returns false, always.
	bool cycleActiveWidget(){
		return false;
	}
	/// activate the passed widget if this is actually the correct widget, return if it was activated or not
	bool searchAndActivateWidget(QWidget target) {
		if (this == target) {
			this.activateEventCall(true);
			return true;
		}
		return false;
	}

	/// changes the key used for cycling active widgets
	void setActiveWidgetCycleKey(dchar newKey){
		this._activeWidgetCycleKey = newKey;
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

	/// Called after `_display` has been set and this widget is ready to be used
	void initialize(){}
	/// Called when mouse is clicked with cursor on this widget.
	void mouseEvent(MouseEvent mouse){}
	/// Called when key is pressed and this widget is active.
	void keyboardEvent(KeyboardEvent key){}
	/// Called when widget size is changed, or widget should recalculate it's child widgets' sizes;
	void resizeEvent(){}
	/// called right after this widget is activated, or de-activated, i.e: is made _activeWidget, or un-made _activeWidget
	void activateEvent(bool isActive){}
	/// called often. `msecs` is the msecs since last timerEvent, not accurate
	void timerEvent(uint msecs){}
public:
	/// Called by itself when it needs to request an update
	void requestUpdate(){
		if (_parent && _indexInParent > -1 && _indexInParent < _parent._requestingUpdate.length && 
		_parent._requestingUpdate[_indexInParent] == false)
			_parent.requestUpdate(_indexInParent);
	}
	/// Called to request this widget to resize at next update
	void requestResize(){
		if (_parent)
			_parent.requestResize();
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
	@property uint sizeRatio(){
		return _sizeRatio;
	}
	/// ditto
	@property uint sizeRatio(uint newRatio){
		requestResize;
		return _sizeRatio = newRatio;
	}
	/// visibility of the widget. getter
	@property bool show(){
		return _show;
	}
	/// visibility of the widget. setter
	@property bool show(bool visibility){
		requestResize;
		return _show = visibility;
	}
	/// size of the widget. getter
	/// **NOTE: call this.requestResize() if you change the size!**
	@property ref Size size(){
		return _size;
	}
	/// size of the widget. setter
	@property ref Size size(Size newSize){
		requestResize;
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
	/// stores index of active widget. -1 if none. This is useful only for Layouts. For widgets, this stays 0
	int _activeWidgetIndex = -1;
	/// Color to fill with in unoccupied space
	Color _fillColor;

	/// gets height/width of a widget using it's sizeRatio and min/max-height/width
	static uint calculateWidgetSize(QLayout.Type type)(QWidget widget, uint ratioTotal, uint totalSpace,
	ref bool free){
		Size wSize = widget.size;
		immutable calculatedSize = cast(uint)((widget.sizeRatio*totalSpace)/ratioTotal);
		static if (type == QLayout.Type.Horizontal){
			wSize.width = calculatedSize;
			free = wSize.minWidth == 0 && wSize.maxWidth == 0;
			return wSize.width;
		}else{ // this else just exists to shut up compiler about "statement not reachable"
			wSize.height = calculatedSize;
			free = wSize.minHeight == 0 && wSize.maxHeight == 0;
			return wSize.height;
		}
	}
	
	/// recalculates the size of every widget inside layout
	void recalculateWidgetsSize(QLayout.Type T)(){
		static if (T != QLayout.Type.Horizontal && T != QLayout.Type.Vertical)
			assert(false);
		FIFOStack!QWidget widgetStack = new FIFOStack!QWidget;
		uint totalRatio = 0;
		uint totalSpace = T == QLayout.Type.Horizontal ? _size.width : _size.height;
		foreach (widget; _widgets){
			if (!widget.show)
				continue;
			totalRatio += widget.sizeRatio;
			widget._size.height = _size.height;
			widget._size.width = _size.width;
			widgetStack.push(widget);
		}
		// do widgets with size limits
		uint limitWRatio, limitWSize; /// totalRatio, and space used of widgets with limits
		for (int i = 0; i < widgetStack.count; i ++){
			QWidget widget = widgetStack.pop;
			bool free;
			immutable uint space = calculateWidgetSize!(T)(widget, totalRatio, totalSpace, free);
			if (free){
				widgetStack.push(widget);
				continue;
			}
			static if (T == QLayout.Type.Horizontal)
				widget._size.width = space;
			else
				widget._size.height = space;
			limitWRatio += widget.sizeRatio;
			limitWSize += space;
		}
		totalSpace -= limitWSize;
		totalRatio -= limitWRatio;
		while (widgetStack.count){
			QWidget widget = widgetStack.pop;
			bool free;
			immutable uint space = calculateWidgetSize!(T)(widget, totalRatio, totalSpace, free);
			static if (T == QLayout.Type.Horizontal)
				widget._size.width = space;
			else
				widget._size.height = space;
			totalRatio -= widget.sizeRatio;
			totalSpace -= space;
		}
		.destroy(widgetStack);
	}
	/// calculates and assigns widgets positions based on their sizes
	void recalculateWidgetsPosition(QLayout.Type T)(){
		static if (T != QLayout.Type.Horizontal && T != QLayout.Type.Vertical)
			assert(false);
		uint previousSpace = 0;
		foreach(widget; _widgets){
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
	override void resizeEvent(){
		uint ratioTotal;
		foreach(w; _widgets){
			if (w.show){
				ratioTotal += w._sizeRatio;
			}
		}
		if (_type == QLayout.Type.Horizontal){
			recalculateWidgetsSize!(QLayout.Type.Horizontal);
			recalculateWidgetsPosition!(QLayout.Type.Horizontal);
		}else{
			recalculateWidgetsSize!(QLayout.Type.Vertical);
			recalculateWidgetsPosition!(QLayout.Type.Vertical);
		}
		foreach (i, widget; _widgets){
			this._display.getSlice(widget._display, widget.size.width, widget.size.height,widget._position.x,widget._position.y);
			widget.resizeEventCall();
		}
	}
	
	/// Redirects the mouseEvent to the appropriate widget
	override public void mouseEvent(MouseEvent mouse) {
		/// first check if it's already inside active widget, might not have to search through each widget
		QWidget activeWidget = null;
		if (_activeWidgetIndex > -1)
			activeWidget = _widgets[_activeWidgetIndex];
		if (activeWidget && mouse.x >= activeWidget._position.x && mouse.x < activeWidget._position.x +activeWidget.size.width 
		&& mouse.y >= activeWidget._position.y && mouse.y < activeWidget._position.y + activeWidget.size.height){
			activeWidget.mouseEventCall(mouse);
		}else{
			foreach (i, widget; _widgets){
				if (widget.show && widget.wantsInput &&
					mouse.x >= widget._position.x && mouse.x < widget._position.x + widget.size.width &&
					mouse.y >= widget._position.y && mouse.y < widget._position.y + widget.size.height){
					// make it active only if this layout is itself active
					if (this.isActive){
						if (activeWidget)
							activeWidget.activateEventCall(false);
						widget.activateEventCall(true);
						_activeWidgetIndex = cast(uint)i;
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
		if (key.key == _activeWidgetCycleKey || key.key == KeyboardEvent.Key.Escape){
			if (key.key == '\t'){ // now need to make sure active widget doesnt want to catch tab
				if (_activeWidgetIndex == -1)
					this.cycleActiveWidget();
				else{
					if (_widgets[_activeWidgetIndex].wantsTab)
						_widgets[_activeWidgetIndex].keyboardEventCall(key);
					else
						this.cycleActiveWidget();
				}
			}else
				this.cycleActiveWidget();
		}else if (_activeWidgetIndex > -1 && (key.key != '\t' || _widgets[_activeWidgetIndex].wantsTab))
			_widgets[_activeWidgetIndex].keyboardEventCall(key);
	}

	/// override initialize to initliaze child widgets
	override void initialize(){
		foreach (widget; _widgets){
			widget._display = _display.getSlice(1,1, _position.x, _position.y); // just throw in dummy size/position, resize event will fix that
			widget.initializeCall();
		}
	}

	/// override timer event to call child widgets' timers
	override void timerEvent(uint msecs){
		foreach (widget; _widgets)
			widget.timerEventCall(msecs);
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
		uint space = 0;
		foreach(i, widget; _widgets){
			if (widget.show){
				if (_requestingUpdate[i]){
					widget._display.cursor = Position(0,0);
					widget.update();
					_requestingUpdate[i] = false;
				}
				if (_type == Type.Horizontal){
					space += widget.size.width;
					if (widget.size.height < this._size.height){
						foreach (y; widget.size.height ..  this._size.height){
							_display.cursor = Position(widget._position.x, y);
							_display.fillLine(' ', _fillColor, _fillColor, widget.size.width);
						}
					}
				}else{
					space += widget.size.height;
					if (widget.size.width < this._size.width){
						immutable lineWidth = _size.width - widget.size.width;
						foreach (y; 0 .. widget.size.height){
							_display.cursor = Position(widget.size.width, widget._position.y + y);
							_display.fillLine(' ', _fillColor, _fillColor, lineWidth);
						}
					}
				}
			}
		}
		if (_type == Type.Horizontal && space < this._size.width){
			immutable uint lineWidth = this._size.width - space;
			foreach (y; 0 .. this._size.height){
				_display.cursor = Position(space, y);
				_display.fillLine(' ', _fillColor, _fillColor, lineWidth);
			}
		}else if (_type == Type.Vertical && space < this._size.height){
			foreach (y; space .. this._size.height){
				_display.cursor = Position(0, y);
				_display.fillLine(' ', _fillColor, _fillColor, this._size.width);
			}
		}
	}
	/// called to cycle between actveWidgets. This is called by owner widget
	/// 
	/// Returns: true if cycled to another widget, false if _activeWidgetIndex set to -1
	override bool cycleActiveWidget(){
		// check if need to cycle within current active widget
		if (_activeWidgetIndex == -1 || !(_widgets[_activeWidgetIndex].cycleActiveWidget())){
			int lastActiveWidgetIndex = _activeWidgetIndex;
			for (_activeWidgetIndex ++; _activeWidgetIndex < _widgets.length; _activeWidgetIndex ++){
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

	/// activate the passed widget if it's in the current layout, return if it was activated or not
	override bool searchAndActivateWidget(QWidget target){
		immutable int lastActiveWidgetIndex = _activeWidgetIndex;

		// search and activate recursively
		_activeWidgetIndex = -1;
		foreach (index, widget; _widgets) {
			if (widget.wantsInput && widget.show && widget.searchAndActivateWidget(target)) {
				_activeWidgetIndex = cast(int)index;
				break;
			}
		}

		// and then manipulate the current layout
		if (lastActiveWidgetIndex != _activeWidgetIndex && lastActiveWidgetIndex > -1)
			_widgets[lastActiveWidgetIndex].activateEventCall(false);
			// no need to call activateEvent on new activeWidget, doing `searchAndActivateWidget` in above loop should've done that
		return _activeWidgetIndex != -1;
	}

	/// Change the key used for cycling active widgets, changes it for all added widgets as well
	override void setActiveWidgetCycleKey(dchar newKey){
		_activeWidgetCycleKey = newKey;
		foreach (widget; _widgets)
			widget.setActiveWidgetCycleKey(newKey);
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
		this._fillColor = DEFAULT_BG;
	}
	/// Color for unoccupied space
	@property Color fillColor(){
		return _fillColor;
	}
	/// ditto
	@property Color fillColor(Color newColor){
		return _fillColor = newColor;
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
		if (_activeWidgetIndex == -1)
			return Position(-1, -1);
		Position cursorPosition = _widgets[_activeWidgetIndex].cursorPosition;
		if (cursorPosition == Position(-1, -1))
			return cursorPosition;
		return Position(_widgets[_activeWidgetIndex]._position.x + cursorPosition.x,
			_widgets[_activeWidgetIndex]._position.y + cursorPosition.y);
	}
	
	/// adds (appends) a widget to the widgetList, and makes space for it
	/// 
	/// If there a widget is too large, it's marked as not visible
	void addWidget(QWidget widget){
		widget._parent = this;
		widget._indexInParent = cast(int)_widgets.length;
		widget.setActiveWidgetCycleKey(this._activeWidgetCycleKey);
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
			widget._indexInParent = cast(int)(_widgets.length+i);
			widget.setActiveWidgetCycleKey(this._activeWidgetCycleKey);
		}
		// add to array
		_widgets ~= widgets.dup;
		// make space in _requestingUpdate
		_requestingUpdate.length += widgets.length;
		_requestingUpdate[$ - widgets.length .. $] = true;
	}
}

/// Used to write to display by widgets
class Display{
private:
	/// width & height
	uint _width, _height;
	/// x and y offsets
	uint _xOff, _yOff;
	/// cursor position, relative to _xOff and _yOff
	Position _cursor;
	/// the terminal
	TermWrapper _term;
	/// constructor for when this buffer is just a slice of the actual buffer
	this(uint w, uint h, uint xOff, uint yOff, TermWrapper terminal){
		_xOff = xOff;
		_yOff = yOff;
		_width = w;
		_height = h;
		_term = terminal;
	}
	/// Returns: a "slice" of this buffer, that is only limited to some rectangular area
	/// 
	/// no bound checking is done
	Display getSlice(uint w, uint h, uint x, uint y){
		return new Display(w, h, _xOff + x, _yOff + y, _term);
	}
	/// modifies an existing Display to act as a "slice"
	/// 
	/// no bound checking is done
	void getSlice(Display sliced, uint w, uint h, uint x, uint y){
		sliced._width = w;
		sliced._height = h;
		sliced._xOff = _xOff + x;
		sliced._yOff = _yOff + y;
	}
public:
	/// constructor
	this(uint w, uint h, TermWrapper terminal){
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
		if (newPos.x < 0)
			newPos.x = 0;
		if (newPos.y < 0)
			newPos.y = 0;
		return _cursor = newPos;
	}
	/// sets background and foreground color
	void colors(Color fg, Color bg){
		_term.color(fg, bg);
	}
	/// Writes a line. if string has more characters than there is space for, extra characters will be ignored.
	/// Each character is written in a 1 cell.
	void write(dstring str, Color fg, Color bg){
		_term.color(fg, bg);
		this.write(str);
	}
	/// ditto
	void write(dstring str){
		foreach (c; str){
			if (_cursor.x >= _width){
				_cursor.x = 0;
				_cursor.y ++;
			}
			if (_cursor.x < _width && _cursor.y < _height)
				_term.put(cast(int)(_cursor.x + _xOff), cast(int)(_cursor.y + _yOff), c == '\t' || c == '\n' ? ' ' : c);
			else
				break;
			_cursor.x ++;
		}
	}
	/// fills all remaining cells with a character
	void fill(dchar c, Color fg, Color bg){
		dchar[] line;
		line.length = _width;
		line[] = c;
		_term.color(fg, bg);
		while (_cursor.y < _height){
			_term.write(cast(int)(_cursor.x + _xOff), cast(int)(_cursor.y + _yOff), cast(dstring)line[0 .. _width - _cursor.x]);
			_cursor.y ++;
			_cursor.x = 0;
		}
	}
	/// fills rest of current line with a character
	void fillLine(dchar c, Color fg, Color bg, uint max = 0){
		dchar[] line;
		line.length =  max < _width - _cursor.x && max > 0 ? max : _width - _cursor.x;
		line[] = c;
		_term.color(fg, bg);
		_term.write(cast(int)(_cursor.x + _xOff), cast(int)(_cursor.y + _yOff), cast(dstring)line);
		_cursor.x += line.length;
		if (_cursor.x >= _width -1){
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
	/// Whether to call resize before next update
	bool _requestingResize;
	/// set to false to stop UI loop in run()
	bool _isRunning;

	/// Reads InputEvent and calls appropriate functions to address those events
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
			_display._height = _size.height;
			_display._width = _size.width;
			//call size change on all widgets
			resizeEventCall();
		}
	}

protected:

	override void resizeEvent(){
		_requestingResize = false;
		super.resizeEvent();
	}
	
	override void update(){
		// resize if needed
		if (_requestingResize)
			this.resizeEventCall();
		super.update();
		// check if need to show/hide cursor
		Position cursorPos = this.cursorPosition;
		if (cursorPos == Position(-1, -1)){
			_termWrap.cursorVisible = false;
		}else{
			_termWrap.moveCursor(cast(int)cursorPos.x, cast(int)cursorPos.y);
			_termWrap.cursorVisible = true;
		}
		_termWrap.flush;
	}

public:
	/// time to wait between timer events (milliseconds)
	ushort timerMsecs;
	/// constructor
	this(QLayout.Type displayType = QLayout.Type.Vertical, ushort timerDuration = 500){
		super(displayType);
		timerMsecs = timerDuration;

		_termWrap = new TermWrapper();
		_display = new Display(1,1, _termWrap);
		this._isActive = true; // so it can make other widgets active on mouse events
	}
	~this(){
		.destroy(_termWrap);
		.destroy(_display);
	}

	/// Called to make container widgets (QLayouts) recalcualte widgets' sizes before update;
	override void requestResize(){
		_requestingResize = true;
	}

	/// stops UI loop. **not instant**, if it is in-between updates, event functions, or timers, it will complete those first
	void terminate(){
		_isRunning = false;
	}
	
	/// starts the UI loop
	void run(){
		// set size
		_size.width = _termWrap.width();
		_size.height = _termWrap.height();
		_display._width = _size.width;
		_display._height = _size.height;
		//ready
		initializeCall();
		resizeEventCall();
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
				this.timerEventCall(cast(uint)sw.peek.total!"msecs");
				sw.reset;
				sw.start;
				update();
			}
		}
	}

	/// search the passed widget recursively and activate it, returns if the activation was successful
	bool activateWidget(QWidget target) {
		return this.searchAndActivateWidget(target);
	}

	/// Changes the key used to cycle between active widgets.
	/// 
	/// for `key`, use either ASCII value of keyboard key, or use KeyboardEvent.Key or KeyboardEvent.CtrlKeys
	override void setActiveWidgetCycleKey(dchar key){
		super.setActiveWidgetCycleKey(key);
	}
}
