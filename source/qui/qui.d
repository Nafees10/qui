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
/// default active widget cycling key (tab)
const dchar WIDGET_CYCLE_KEY = '\t';

/// Available colors are in this enum
public alias Color = qui.termwrap.Color;
/// Availabe Keys (keyboard) for input
public alias Key = qui.termwrap.Event.Keyboard.Key;
/// Mouse Event
public alias MouseEvent = Event.Mouse;
/// Keyboard Event
public alias KeyboardEvent = Event.Keyboard;

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
/// UpdateEvent function. Return true if the event should be dropped
alias UpdateEventFunction = bool delegate(QWidget);

/// mask of events subscribed
enum EventMask : uint{
	MousePress = 1, /// mouse clicks/presses
	MouseRelease = 1 << 1, /// mouse releases
	MouseHover = 1 << 2, /// mouse move/hover
	KeyboardPress = 1 << 3, /// key presses
	KeyboardRelease = 1 << 4, /// key releases
	KeyboardWidgetCycleKey = 1 << 5, /// keyboard events concerning active widget cycling key. Use this in combination with KeyboardPress or KeyboardRelease
	Resize = 1 << 6, /// widget resize
	Activate = 1 << 7, /// widget activated/deactivated.
	Timer = 1 << 8, /// timer 
	Initialize = 1 << 9, /// initialize
	Update = 1 << 10, /// update/draw itself
	MouseAll = MousePress | MouseRelease | MouseHover, /// all mouse events
	KeyboardAll = KeyboardPress | KeyboardRelease, /// all keyboard events, this does **NOT** include KeyboardWidgetCycleKey 
	InputAll = MouseAll | KeyboardAll, /// MouseAll and KeyboardAll
	All = uint.max, /// all events (all bits=1)
}

/// A cell on terminal
struct Cell{
	/// character
	dchar c;
	/// foreground and background colors
	Color fg, bg;
}

/// Base class for all widgets, including layouts and QTerminal
///
/// Use this as parent-class for new widgets
abstract class QWidget{
private:
	/// stores the position of this widget, relative to it's parent widget's position
	uint _posX, _posY;
	/// width of widget
	uint _width;
	/// height of widget
	uint _height;
	/// Display buffer. Read as: `_dBuf[y][x]`
	Cell[][] _dBuf;
	/// next write position in `_dBuf`.
	uint _dBufX, _dBufY;
	/// horizontal scroll
	int _scrollX;
	/// vertical scroll
	int _scrollY;
	/// top left corner X coordinate of viewport. Used to limit writing to visible area
	uint _viewX;
	/// top left corner Y coordinate of viewport. Used to limit writing to visible area
	uint _viewY;
	/// width of viewport. Used to limit writing to visible area
	uint _viewWidth;
	/// height of viewport. Used to limit writing to visible area
	uint _viewHeight;
	/// stores if this widget is the active widget
	bool _isActive = false;
	/// whether this widget is requesting update
	bool _requestingUpdate;
	/// Whether to call resize before next update
	bool _requestingResize;
	/// the parent widget
	QWidget _parent = null;
	/// the index it is stored at in _parent. -1 if no parent asigned yet
	int _indexInParent = -1;
	/// the key used for cycling active widget
	dchar _activeWidgetCycleKey = WIDGET_CYCLE_KEY;
	/// Events this widget is subscribed to, see `EventMask`
	uint _eventSub = 0;

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
	/// custom upedateEvent, if not null, it should be called before doing anything else in updateEvent
	UpdateEventFunction _customUpdateEvent;

	/// Called when it needs to request an update.  
	/// Will not do anything if not subscribed to update events
	void _requestUpdate(){
		if ((_eventSub & EventMask.Update) == 0)
			return;
		_requestingUpdate = true;
		if (_parent)
			_parent._requestUpdate();
	}
	/// Called to request this widget to resize at next update
	/// Will not do anything if not subscribed to resize events
	void _requestResize(){
		if ((_eventSub & EventMask.Resize) == 0)
			return;
		_requestingResize = true;
		if (_parent)
			_parent._requestResize();
	}

	/// called by parent for initialize event
	void _initializeCall(){
		if (_eventSub & EventMask.Initialize && (!_customInitEvent || !_customInitEvent(this)))
			this.initialize();
	}
	/// called by parent for mouseEvent
	void _mouseEventCall(MouseEvent mouse){
		if ((_eventSub & EventMask.MouseHover && mouse.state == MouseEvent.State.Hover)
		|| (_eventSub & EventMask.MousePress && mouse.state == MouseEvent.State.Click)
		|| (_eventSub & EventMask.MouseRelease && mouse.state == MouseEvent.State.Release)){
			mouse.x = (mouse.x - cast(int)this._posX) + _viewX; // mouse input comes relative to visible area
			mouse.y = (mouse.y - cast(int)this._posY) + _viewY;
			if (!_customMouseEvent || !_customMouseEvent(this, mouse))
				this.mouseEvent(mouse);
		}
	}
	/// called by parent for keyboardEvent
	void _keyboardEventCall(KeyboardEvent key){
		if (((_eventSub & EventMask.KeyboardPress && key.pressed)
		|| (_eventSub & EventMask.KeyboardRelease && !key.pressed))
		&& (_eventSub & EventMask.KeyboardWidgetCycleKey || key.key != _activeWidgetCycleKey)){
			if (!_customKeyboardEvent || !_customKeyboardEvent(this, key))
				this.keyboardEvent(key);
		}
	}
	/// called by parent for resizeEvent
	void _resizeEventCall(){
		_requestingResize = false;
		if (_eventSub & EventMask.Resize && (!_customResizeEvent || !_customResizeEvent(this)))
			this.resizeEvent();
	}
	/// called by parent for activateEvent
	void _activateEventCall(bool isActive){
		/*if (_isActive == isActive)
			return;*/
		_isActive = isActive;
		if (_eventSub & EventMask.Activate && (!_customActivateEvent || !_customActivateEvent(this, isActive)))
			this.activateEvent(isActive);
	}
	/// called by parent for mouseEvent
	void _timerEventCall(uint msecs){
		if (_eventSub && EventMask.Timer && (!_customTimerEvent || !_customTimerEvent(this, msecs)))
			this.timerEvent(msecs);
	}
	/// called by parent for updateEvent
	void _updateEventCall(){
		_requestingUpdate = false;
		_dBufX = _viewX;
		_dBufY = _viewY;
		if (_eventSub & EventMask.Update && (!_customUpdateEvent || !_customUpdateEvent(this)))
			this.updateEvent();
	}
protected:
	/// minimum width
	uint _minWidth;
	/// maximum width
	uint _maxWidth;
	/// minimum height
	uint _minHeight;
	/// maximum height
	uint _maxHeight;
	/// whether this widget should be drawn or not.
	bool _show = true;
	/// specifies that how much height (in horizontal layout) or width (in vertical) is given to this widget.  
	/// The ratio of all widgets is added up and height/width for each widget is then calculated using this.
	uint _sizeRatio = 1;
	/// where to draw cursor if this is active widget.
	int _cursorX = -1, _cursorY = -1;

	/// If a coordinate is within writing area, and writing area actually exists
	bool isWritable(uint x, uint y){
		return x >= _viewX && x < _viewX + _viewWidth && y >= _viewY && y < _viewY + _viewHeight;
	}

	/// move seek for next write to terminal.  
	/// can only write in between `(_viewX .. _viewX + _viewWidth, _viewY .. _viewX + _viewHeight)`
	/// 
	/// Returns: false if writing to new coordinates not possible
	bool moveTo(uint newX, uint newY){
		if (!isWritable(newX, newY))
			return false;
		_dBufX = newX;
		_dBufY = newY;
		return true;
	}
	/// writes a character on terminal
	/// 
	/// Returns: true if done, false if outside writing area
	bool write(dchar c, Color fg, Color bg){
		if (!isWritable(_dBufX, _dBufY))
			return false;
		_dBuf[_dBufY - _viewY][_dBufX - _viewX] = Cell(c, fg, bg);
		_dBufX ++;
		if (_dBufX >= _viewX + _viewWidth){
			_dBufY ++;
			_dBufX = _viewX;
		}
		return true;
	}
	/// writes a (d)string to terminal. if it does not fit in one line, it is wrapped
	/// 
	/// Returns: true if done, false if not (not enough area for whole string?)
	bool write(dstring s, Color fg, Color bg){
		foreach (c; s){
			if (!write(c, fg, bg))
				return false;
		}
		return true;
	}
	/// fill current line with a character. `max` is ignored if `max==0`
	/// 
	/// Returns: number of cells written
	uint fillLine(dchar c, Color fg, Color bg, uint max = 0){
		if (!isWritable(_dBufX, _dBufY))
			return 0;
		uint r = _viewWidth + _viewX - _dBufX;
		if (r > max)
			r = max;
		_dBuf[_dBufY - _viewY][_dBufX - _viewX .. _dBufX - _viewX + r] = Cell(c, fg, bg);
		_dBufX += r;
		if (_dBufX >= _viewX + _viewWidth){
			_dBufY ++;
			_dBufX = _viewX;
		}
		return r;
	}

	/// For cycling between widgets.
	/// 
	/// Returns: whether any cycling happened
	bool cycleActiveWidget(){
		return false;
	}
	/// activate the passed widget if this is actually the correct widget
	/// 
	/// Returns: if it was activated or not
	bool searchAndActivateWidget(QWidget target) {
		if (this == target) {
			this._isActive = true;
			if (this._eventSub & EventMask.Activate)
				this._activateEventCall(true);
			return true;
		}
		return false;
	}

	/// changes the key used for cycling active widgets
	void setActiveWidgetCycleKey(dchar newKey){
		this._activeWidgetCycleKey = newKey;
	}

	/// called by itself, to update events subscribed to
	final void eventSubscribe(uint newSub){
		_eventSub = newSub;
		if (_parent)
			_parent.eventSubscribe();
	}
	/// called by children to update events subscribed
	void eventSubscribe(){}

	/// Called to update this widget
	void updateEvent(){}

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
	/// To request parent to trigger an update event
	void requestUpdate(){
		_requestUpdate();
	}
	/// To request parent to trigger a resize event
	void requestResize(){
		_requestResize();
	}
	/// use to change the custom initialize event
	final @property InitFunction onInitEvent(InitFunction func){
		return _customInitEvent = func;
	}
	/// use to change the custom mouse event
	final @property MouseEventFuction onMouseEvent(MouseEventFuction func){
		return _customMouseEvent = func;
	}
	/// use to change the custom keyboard event
	final @property KeyboardEventFunction onKeyboardEvent(KeyboardEventFunction func){
		return _customKeyboardEvent = func;
	}
	/// use to change the custom resize event
	final @property ResizeEventFunction onResizeEvent(ResizeEventFunction func){
		return _customResizeEvent = func;
	}
	/// use to change the custom activate event
	final @property ActivateEventFunction onActivateEvent(ActivateEventFunction func){
		return _customActivateEvent = func;
	}
	/// use to change the custom timer event
	final @property TimerEventFunction onTimerEvent(TimerEventFunction func){
		return _customTimerEvent = func;
	}
	/// Returns: this widget's parent
	final @property QWidget parent(){
		return _parent;
	}
	/// Returns: true if this widget is the current active widget
	final @property bool isActive(){
		return _isActive;
	}
	/// Returns: EventMask of subscribed events
	final @property uint eventSub(){
		return _eventSub;
	}
	/// Returns: x position of cursor to be displayed. if <0, cursor is hidden
	@property uint cursorX(){
		return _cursorX;
	}
	/// Returns: y position of cursor to be displayed. if <0, cursor is hidden
	@property uint cursorY(){
		return _cursorY;
	}
	/// size of width (height/width, depending of Layout.Type it is in) of this widget, in ratio to other widgets in that layout
	@property uint sizeRatio(){
		return _sizeRatio;
	}
	/// ditto
	@property uint sizeRatio(uint newRatio){
		_sizeRatio = newRatio;
		_requestResize();
		return _sizeRatio;
	}
	/// visibility of the widget. getter
	@property bool show(){
		return _show;
	}
	/// visibility of the widget. setter
	@property bool show(bool visibility){
		_show = visibility;
		_requestResize();
		return _show;
	}
	/// horizontal scroll. Use for drawing scrollbar
	final @property int scrollX(){
		return _scrollX;
	}
	/// vertical scroll. Use for drawing scrollbar
	final @property int scrollY(){
		return _scrollY;
	}
	/// viewport coordinates. (drawable area for widget)
	final @property uint viewportX(){
		return _viewX;
	}
	/// ditto
	final @property uint viewportY(){
		return _viewY;
	}
	/// viewport size. (drawable area for widget)
	final @property uint viewportWidth(){
		return _viewWidth;
	}
	/// ditto
	final @property uint viewportHeight(){
		return _viewHeight;
	}
	/// width of widget
	final @property uint width(){
		return _width;
	}
	/// width setter. This will actually do `minWidth=maxWidth=value` and call requestResize
	@property uint width(uint value){
		_minWidth = value;
		_maxWidth = value;
		_requestResize();
		return value;
	}
	/// height of widget
	final @property uint height(){
		return _height;
	}
	/// height setter. This will actually do `minHeight=maxHeight=value` (which will then call `requestResize`)
	@property uint height(uint value){
		_minHeight = value;
		_maxHeight = value;
		_requestResize();
		return value;
	}
	/// minimum width
	@property uint minWidth(){
		return _minWidth;
	}
	/// ditto
	@property uint minWidth(uint value){
		_requestResize();
		return _minWidth = value;
	}
	/// minimum height
	@property uint minHeight(){
		return _minHeight;
	}
	/// ditto
	@property uint minHeight(uint value){
		_requestResize();
		return _minHeight = value;
	}
	/// maximum width
	@property uint maxWidth(){
		return _maxWidth;
	}
	/// ditto
	@property uint maxWidth(uint value){
		_requestResize();
		return _maxWidth = value;
	}
	/// maximum height
	@property uint maxHeight(){
		return _maxHeight;
	}
	/// ditto
	@property uint maxHeight(uint value){
		_requestResize();
		return _maxHeight = value;
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
		immutable uint calculatedSize = cast(uint)((widget.sizeRatio*totalSpace)/ratioTotal);
		static if (type == QLayout.Type.Horizontal){
			free = widget.minWidth == 0 && widget.maxWidth == 0;
			return getLimitedSize(calculatedSize, widget.minWidth, widget.maxWidth);
		}else{ // this else just exists to shut up compiler about "statement not reachable"
			free = widget.minHeight == 0 && widget.maxHeight == 0;
			return getLimitedSize(calculatedSize, widget.minHeight, widget.maxHeight);
		}
	}
	/// ditto
	static uint calculateWidgetSize(QLayout.Type type)(QWidget widget, uint ratioTotal, uint totalSpace){
		bool free; // @suppress(dscanner.suspicious.unmodified) shut up vscode
		return calculateWidgetSize!type(widget, ratioTotal, totalSpace, free);
	}
	
	/// recalculates the size of every widget inside layout
	void recalculateWidgetsSize(QLayout.Type T)(){
		static if (T != QLayout.Type.Horizontal && T != QLayout.Type.Vertical)
			assert(false);
		FIFOStack!QWidget widgetStack = new FIFOStack!QWidget;
		uint totalRatio = 0;
		uint totalSpace = T == QLayout.Type.Horizontal ? _width : _height;
		foreach (widget; _widgets){
			if (!widget.show)
				continue;
			totalRatio += widget.sizeRatio;
			widget._height = getLimitedSize(_height, widget.minHeight, widget.maxHeight);
			widget._width = getLimitedSize(_width, widget.minWidth, widget.maxWidth);
			widgetStack.push(widget);
		}
		// do widgets with size limits
		uint limitWRatio, limitWSize; /// totalRatio, and space used of widgets with limits
		for (int i = 0; i < widgetStack.count; i ++){
			QWidget widget = widgetStack.pop;
			bool free; // @suppress(dscanner.suspicious.unmodified) shut up vscode
			immutable uint space = calculateWidgetSize!(T)(widget, totalRatio, totalSpace, free);
			if (free){
				widgetStack.push(widget);
				continue;
			}
			static if (T == QLayout.Type.Horizontal)
				widget._width = space;
			else
				widget._height = space;
			limitWRatio += widget.sizeRatio;
			limitWSize += space;
		}
		totalSpace -= limitWSize;
		totalRatio -= limitWRatio;
		while (widgetStack.count){
			QWidget widget = widgetStack.pop;
			immutable uint space = calculateWidgetSize!(T)(widget, totalRatio, totalSpace);
			static if (T == QLayout.Type.Horizontal)
				widget._width = space;
			else
				widget._height = space;
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
					widget._posY = 0;
					widget._posX = previousSpace;
					previousSpace += widget._width;
				}else{
					widget._posX = 0;
					widget._posY = previousSpace;
					previousSpace += widget._height;
				}
			}
		}
	}
protected:
	override void eventSubscribe(){
		_eventSub = 0;
		foreach (widget; _widgets)
			_eventSub |= widget._eventSub;
		if (_eventSub & EventMask.InputAll)
			_eventSub |= EventMask.Activate; // if children want input, then need activate too
		_eventSub |= EventMask.Resize;
		if (_parent)
			_parent.eventSubscribe();
	}

	/// Recalculates size and position for all visible widgets
	override void resizeEvent(){
		if (_type == QLayout.Type.Horizontal){
			recalculateWidgetsSize!(QLayout.Type.Horizontal);
			recalculateWidgetsPosition!(QLayout.Type.Horizontal);
		}else{
			recalculateWidgetsSize!(QLayout.Type.Vertical);
			recalculateWidgetsPosition!(QLayout.Type.Vertical);
		}
		foreach (i, widget; _widgets){
			// this._display.getSlice(widget._display, widget._width, widget._height, widget._posX, widget._posY);
			// TODO: adjust _dBuff slice
			widget._resizeEventCall();
		}
	}
	
	/// Redirects the mouseEvent to the appropriate widget
	override public void mouseEvent(MouseEvent mouse) {
		/// first check if it's already inside active widget, might not have to search through each widget
		QWidget activeWidget = null;
		if (_activeWidgetIndex > -1)
			activeWidget = _widgets[_activeWidgetIndex];
		if (activeWidget && mouse.x >= activeWidget._posX && mouse.x < activeWidget._posX+activeWidget._width
		&& mouse.y >= activeWidget._posY && mouse.y < activeWidget._posY + activeWidget._height){
			activeWidget._mouseEventCall(mouse);
		}else{
			foreach (i, widget; _widgets){
				if (widget.show &&
					mouse.x >= widget._posX && mouse.x < widget._posX + widget._width &&
					mouse.y >= widget._posY && mouse.y < widget._posY + widget._height){
					// make it active only if this layout is itself active, and widget wants keyboard input
					if (this._isActive && (widget._eventSub & EventMask.KeyboardAll)){
						if (activeWidget)
							activeWidget._activateEventCall(false);
						widget._activateEventCall(true);
						_activeWidgetIndex = cast(uint)i;
					}
					widget._mouseEventCall(mouse);
					break;
				}
			}
		}
	}

	/// Redirects the keyboardEvent to appropriate widget
	override public void keyboardEvent(KeyboardEvent key){
		QWidget activeWidget = null;
		uint eSub = 0;
		if (_activeWidgetIndex > -1){
			activeWidget = _widgets[_activeWidgetIndex];
			eSub = activeWidget._eventSub;
		}
		if (key.key == _activeWidgetCycleKey && key.pressed &&
		(!activeWidget || !(eSub & EventMask.KeyboardWidgetCycleKey))){
			this.cycleActiveWidget();
			return;
		}
		if (!activeWidget)
			return;
		activeWidget._keyboardEventCall(key);
	}

	/// override initialize to initliaze child widgets
	override void initialize(){
		foreach (widget; _widgets){
			// widget._display = _display.getSlice(1,1, _posX, _posY); // just throw in dummy size/position, resize event will fix that
			// TODO: init _dBuff to null
			widget._initializeCall();
		}
	}

	/// override timer event to call child widgets' timers
	override void timerEvent(uint msecs){
		foreach (widget; _widgets)
			widget._timerEventCall(msecs);
	}

	/// override activate event
	override void activateEvent(bool isActive){
		if (isActive){
			_activeWidgetIndex = -1;
			this.cycleActiveWidget();
		}else if (_activeWidgetIndex > -1)
			_widgets[_activeWidgetIndex]._activateEventCall(isActive);
	}
	
	/// called by parent widget to update
	override void updateEvent(){
		// TODO: fill empty space with fill color
		foreach(i, widget; _widgets){
			if (widget.show && widget._requestingUpdate)
				widget._updateEventCall();
		}
	}
	/// called to cycle between actveWidgets. This is called by parent widget
	/// 
	/// Returns: true if cycled to another widget, false if _activeWidgetIndex set to -1
	override bool cycleActiveWidget(){
		// check if need to cycle within current active widget
		if (_activeWidgetIndex == -1 || !(_widgets[_activeWidgetIndex].cycleActiveWidget())){
			int lastActiveWidgetIndex = _activeWidgetIndex;
			for (_activeWidgetIndex ++; _activeWidgetIndex < _widgets.length; _activeWidgetIndex ++){
				if ((_widgets[_activeWidgetIndex]._eventSub & EventMask.KeyboardAll) && _widgets[_activeWidgetIndex].show)
					break;
			}
			if (_activeWidgetIndex >= _widgets.length)
				_activeWidgetIndex = -1;
			
			if (lastActiveWidgetIndex != _activeWidgetIndex){
				if (lastActiveWidgetIndex > -1)
					_widgets[lastActiveWidgetIndex]._activateEventCall(false);
				if (_activeWidgetIndex > -1)
					_widgets[_activeWidgetIndex]._activateEventCall(true);
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
			if ((widget._eventSub & EventMask.KeyboardAll) && widget.show && widget.searchAndActivateWidget(target)){
				_activeWidgetIndex = cast(int)index;
				break;
			}
		}

		// and then manipulate the current layout
		if (lastActiveWidgetIndex != _activeWidgetIndex && lastActiveWidgetIndex > -1)
			_widgets[lastActiveWidgetIndex]._activateEventCall(false);
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
	/// Returns: x position of cursor, <0 if hidden
	override @property uint cursorX(){
		if (_activeWidgetIndex == -1)
			return -1;
		if (_widgets[_activeWidgetIndex].cursorX < 0)
			return -1;
		return _widgets[_activeWidgetIndex]._posX + _widgets[_activeWidgetIndex].cursorX;
	}
	/// Returns: y position of cursor, <0 if hidden
	override @property uint cursorY(){
		if (_activeWidgetIndex == -1)
			return -1;
		if (_widgets[_activeWidgetIndex].cursorY < 0)
			return -1;
		return _widgets[_activeWidgetIndex]._posY + _widgets[_activeWidgetIndex].cursorY;
	}
	/// adds a widget, and makes space for it
	void addWidget(QWidget widget){
		widget._parent = this;
		widget._indexInParent = cast(int)_widgets.length;
		widget._requestingUpdate = true;
		widget.setActiveWidgetCycleKey(this._activeWidgetCycleKey);
		_widgets ~= widget;
		eventSubscribe;
	}
	/// ditto
	void addWidget(QWidget[] widgets){
		foreach (i, widget; widgets){
			widget._parent = this;
			widget._indexInParent = cast(int)(_widgets.length+i);
			widget._requestingUpdate = true;
			widget.setActiveWidgetCycleKey(this._activeWidgetCycleKey);
		}
		_widgets ~= widgets;
		eventSubscribe;
	}
}

/// A terminal (as the name says).
class QTerminal : QLayout{
private:
	/// To actually access the terminal
	TermWrapper _termWrap;
	/// set to false to stop UI loop in run()
	bool _isRunning;
	/// whether to stop UI loop on Interrupt
	bool _stopOnInterrupt;

	/// Reads InputEvent and calls appropriate functions to address those events
	void readEvent(Event event){
		if (event.type == Event.Type.HangupInterrupt){
			if (_stopOnInterrupt)
				_isRunning = false;
			else{ // otherwise read it as a Ctrl+C
				KeyboardEvent keyEvent;
				keyEvent.key = KeyboardEvent.CtrlKeys.CtrlC;
				this._keyboardEventCall(keyEvent);
			}
		}else if (event.type == Event.Type.Keyboard){
			KeyboardEvent kPress = event.keyboard;
			this._keyboardEventCall(kPress);
		}else if (event.type == Event.Type.Mouse){
			this._mouseEventCall(event.mouse);
		}else if (event.type == Event.Type.Resize){
			this._resizeEventCall();
		}
	}

protected:

	override void eventSubscribe(){
		_eventSub = EventMask.All;
	}

	override void resizeEvent(){
		_height = _termWrap.height;
		_width = _termWrap.width;
		// TODO: adjust _dBuff size
		super.resizeEvent();
	}
	
	override void updateEvent(){
		// resize if needed
		if (_requestingResize)
			this._resizeEventCall();
		super.updateEvent(); // no, this is not a mistake, dont change this to updateEventCall again!
		// check if need to show/hide cursor
		uint x = cursorX, y = cursorY;
		if (x < 0 || y < 0)
			_termWrap.cursorVisible = false;
		else{
			_termWrap.moveCursor(cast(int)x, cast(int)y);
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
		this._isActive = true; // so it can make other widgets active on mouse events
	}
	~this(){
		.destroy(_termWrap);
	}

	/// stops UI loop. **not instant**, if it is in-between updates, event functions, or timers, it will complete those first
	void terminate(){
		_isRunning = false;
	}

	/// whether to stop UI loop on HangupInterrupt (Ctrl+C)
	@property bool terminateOnHangup(){
		return _stopOnInterrupt;
	}
	/// ditto
	@property bool terminateOnHangup(bool newVal){
		return _stopOnInterrupt = newVal;
	}
	
	/// starts the UI loop
	void run(){
		_initializeCall();
		_resizeEventCall();
		_updateEventCall();
		_isRunning = true;
		StopWatch sw = StopWatch(AutoStart.yes);
		while (_isRunning){
			int timeout = cast(int)(timerMsecs - sw.peek.total!"msecs");
			Event event;
			while (_termWrap.getEvent(timeout, event) > 0){
				readEvent(event);
				timeout = cast(int)(timerMsecs - sw.peek.total!"msecs");
				_updateEventCall();
			}
			if (sw.peek.total!"msecs" >= timerMsecs){
				_timerEventCall(cast(uint)sw.peek.total!"msecs");
				sw.reset;
				sw.start;
				_updateEventCall();
			}
		}
	}

	/// search the passed widget recursively and activate it
	/// 
	/// Returns: true if the widget was made active, false if not found and not done
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
