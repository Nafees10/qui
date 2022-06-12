/++
	Contains all the classes that make up qui.
+/
module qui.qui;

import std.datetime.stopwatch;
import utils.misc;
import utils.ds;
import std.conv : to;
import qui.termwrap;

import qui.utils;

/// default foreground color, white
enum Color DEFAULT_FG = Color.white;
/// default background color, black
enum Color DEFAULT_BG = Color.black;
/// default background color of overflowing layouts, red
enum Color DEFAULT_OVERFLOW_BG = Color.red;
/// default active widget cycling key, tab
enum dchar WIDGET_CYCLE_KEY = '\t';

/// Colors
public alias Color = qui.termwrap.Color;
/// Availabe Keys (keyboard) for input
public alias Key = qui.termwrap.Event.Keyboard.Key;
/// Mouse Event
public alias MouseEvent = Event.Mouse;
/// Keyboard Event
public alias KeyboardEvent = Event.Keyboard;

/// MouseEvent function. Return true to drop event
alias MouseEventFuction = bool delegate(QWidget, MouseEvent);
/// KeyboardEvent function. Return true to drop event
alias KeyboardEventFunction = bool delegate(QWidget, KeyboardEvent,
	bool);
/// ResizeEvent function. Return true to drop event
alias ResizeEventFunction = bool delegate(QWidget);
/// ScrollEvent function. Return true to drop event
alias ScrollEventFunction = bool delegate(QWidget);
/// ActivateEvent function. Return true to drop event
alias ActivateEventFunction = bool delegate(QWidget, bool);
/// TimerEvent function. Return true to drop event
alias TimerEventFunction = bool delegate(QWidget, uint);
/// Init function. Return true to drop event
alias InitFunction = bool delegate(QWidget);
/// UpdateEvent function. Return true to drop event
alias UpdateEventFunction = bool delegate(QWidget);

/// mask of events subscribed
enum EventMask : uint{
	/// mouse clicks/presses.
	/// This value matches `MouseEvent.State.Click`
	MousePress = 1,
	/// mouse releases
	/// This value matches `MouseEvent.State.Release`
	MouseRelease = 1 << 1,
	/// mouse move/hover.
	/// This value matches `MouseEvent.State.Hover`
	MouseHover = 1 << 2,
	/// key presses.
	/// This value matches `KeyboardEvent.State.Pressed`
	KeyboardPress = 1 << 3,
	/// key releases.
	/// This value matches `KeyboardEvent.State.Released`
	KeyboardRelease = 1 << 4,
	/// widget scrolling.
	Scroll = 1 << 5,
	/// widget resize.
	Resize = 1 << 6,
	/// widget activated/deactivated.
	Activate = 1 << 7,
	/// timer
	Timer = 1 << 8,
	/// initialize
	Initialize = 1 << 9,
	/// draw itself.
	Update = 1 << 10,
	/// All mouse events
	MouseAll = MousePress | MouseRelease | MouseHover,
	/// All keyboard events
	/// this does **NOT** include KeyboardWidgetCycleKey
	KeyboardAll = KeyboardPress | KeyboardRelease,
	/// All keyboard and mouse events
	InputAll = MouseAll | KeyboardAll,
}

/// A cell on terminal
struct Cell{
	/// character
	dchar c;
	/// foreground color
	Color fg;
	/// background colors
	Color bg;
	/// if colors are same with another Cell
	bool colorsSame(Cell b){
		return this.fg == b.fg && this.bg == b.fg;
	}
}

/// Display buffer
struct Viewport{
private:
	Cell[] _buffer;
	uint _seekX, _seekY;
	uint _width, _height;
	uint _actualWidth;
	// these are subtracted, only when seek is set, not after
	uint _offsetX, _offsetY;

	/// reset
	void _reset(){
		_buffer = [];
		_seekX = 0;
		_seekY = 0;
		_width = 0;
		_height = 0;
		_actualWidth = 0;
		_offsetX = 0;
		_offsetY = 0;
	}

	/// seek position in _buffer calculated from _seekX & _seekY
	@property int _seek(){
		return (_seekX - _offsetX) +
			((_seekY - _offsetY) * _actualWidth);
	}
	/// set another Viewport so that it is a rectangular slice
	/// of this
	///
	/// Returns: true if done, false if not
	void _getSlice(Viewport* sub, int x, int y, uint width,
			uint height){
		sub._reset();
		sub._actualWidth = _actualWidth;
		if (width + height == 0)
			return;
		x -= _offsetX;
		y -= _offsetY;
		if (x > cast(int)_width || y > cast(int)_height ||
		x + width <= 0 || y + height <= 0)
			return;
		if (x < 0){
			sub._offsetX = -x;
			x = 0;
		}
		if (y < 0){
			sub._offsetY = -y;
			y = 0;
		}
		if (width + x > _width)
			width = _width - x;
		if (height + y > _height)
			height = _height - y;
		immutable uint buffStart  = x + (y*_actualWidth),
			buffEnd = buffStart + ((height-1)*_actualWidth) + width;
		if (buffEnd > _buffer.length || buffStart >= buffEnd)
			return;
		sub._width = width;
		sub._height = height;
		sub._buffer = _buffer[buffStart .. buffEnd];
	}
public:
	/// if x and y are at a position where writing can happen
	bool isWritable(uint x, uint y){
		return x >= _offsetX && y >= _offsetY &&
			x < _width + _offsetX && y < _height + _offsetY;
	}
	/// move to a position. if x > width, moved to x=0 of next row
	void moveTo(uint x, uint y){
		_seekX = x;
		_seekY = y;
		if (_seekY >= _width){
			_seekX = 0;
			_seekY ++;
		}
	}
	/// Writes a character at current position and move ahead
	/// 
	/// Returns: false if outside writing area
	bool write(dchar c, Color fg, Color bg){
		if (_seekX < _offsetX || _seekY < _offsetY){
			_seekX ++;
			if (_seekY >= _width){
				_seekX = 0;
				_seekY ++;
			}
			return false;
		}
		if (_seekX >= _width && _seekY >= _height)
			return false;
		if (_buffer.length > _seek)
			_buffer[_seek] = Cell(c, fg, bg);
		_seekX ++;
		if (_seekX >= _width){
			_seekX = 0;
			_seekY ++;
		}
		return true;
	}
	/// Writes a string.
	/// 
	/// Returns: number of characters written
	uint write(dstring s, Color fg, Color bg){
		uint r;
		foreach (c; s){
			if (!write(c, fg, bg))
				break;
			r ++;
		}
		return r;
	}
	/// Fills line, starting from current coordinates,
	/// with maximum `max` number of chars, if `max>0`
	/// 
	/// Returns: number of characters written
	uint fillLine(dchar c, Color fg, Color bg, uint max=0){
		uint r = 0;
		const uint currentY = _seekY;
		bool status = true;
		while (status && (max == 0 || r < max) &&
				_seekY == currentY){
			status = write(c, fg, bg);
			r ++;
		}
		return r;
	}
}

/// Base class for all widgets, including layouts and QTerminal
///
/// Use this as parent-class for new widgets
abstract class QWidget{
private:
	/// position of this widget, relative to parent
	uint _posX, _posY;
	/// width of widget
	uint _width;
	/// height of widget
	uint _height;
	/// scroll
	uint _scrollX, _scrollY;
	/// viewport
	Viewport _view;
	/// if this widget is the active widget
	bool _isActive = false;
	/// whether this widget is requesting update
	bool _requestingUpdate = true;
	/// Whether to call resize before next update
	bool _requestingResize = false;
	/// the parent widget
	QWidget _parent = null;
	/// if it can make parent change scrolling
	bool _canReqScroll = false;
	/// if this widget is itself a scrollable container
	bool _isScrollableContainer = false;
	/// Events this widget is subscribed to, see `EventMask`
	uint _eventSub = 0;
	/// whether this widget should be drawn or not.
	bool _show = true;
	/// specifies ratio of height or width
	uint _sizeRatio = 1;

	/// custom onInit event
	InitFunction _customInitEvent;
	/// custom mouse event
	MouseEventFuction _customMouseEvent;
	/// custom keyboard event
	KeyboardEventFunction _customKeyboardEvent;
	/// custom resize event
	ResizeEventFunction _customResizeEvent;
	/// custom rescroll event
	ScrollEventFunction _customScrollEvent;
	/// custom onActivate event,
	ActivateEventFunction _customActivateEvent;
	/// custom onTimer event
	TimerEventFunction _customTimerEvent;
	/// custom upedateEvent
	UpdateEventFunction _customUpdateEvent;

	/// Called when it needs to request an update.  
	void _requestUpdate(){
		if (_requestingUpdate || !(_eventSub & EventMask.Update))
			return;
		_requestingUpdate = true;
		if (_parent)
			_parent.requestUpdate();
	}
	/// Called to request this widget to resize at next update
	void _requestResize(){
		if (_requestingResize)
			return;
		_requestingResize = true;
		if (_parent)
			_parent.requestResize();
	}
	/// Called to request cursor to be positioned at x,y
	/// Will do nothing if not active widget
	void _requestCursorPos(int x, int y){
		if (_isActive && _parent)
			_parent.requestCursorPos(x < 0 ?
					x :
					_posX + x - _view._offsetX,
				y < 0 ?
					y :
					_posY + y - _view._offsetY);
	}
	/// Called to request _scrollX to be adjusted
	/// Returns: true if _scrollX was modified
	bool _requestScrollX(uint x){
		if (_canReqScroll && _parent && _view._width < _width &&
				x < _width - _view._width)
			return _parent.requestScrollX(x + _posX);
		return false;
	}
	/// Called to request _scrollY to be adjusted
	/// Returns: true if _scrollY was modified
	bool _requestScrollY(uint y){
		if (_canReqScroll && _parent && _view._height < _height &&
				y < _height - _view._height)
			return _parent.requestScrollY(y + _posY);
		return false;
	}

	/// called by parent for initialize event
	bool _initializeCall(){
		if (!(_eventSub & EventMask.Initialize))
			return false;
		if (_customInitEvent && _customInitEvent(this))
			return true;
		return this.initialize();
	}
	/// called by parent for mouseEvent
	bool _mouseEventCall(MouseEvent mouse){
		if (!(_eventSub & mouse.state)) 
			return false;
		// mouse input comes relative to visible area
		mouse.x = (mouse.x - cast(int)this._posX) + _view._offsetX;
		mouse.y = (mouse.y - cast(int)this._posY) + _view._offsetY;
		if (_customMouseEvent && _customMouseEvent(this, mouse))
			return true;
		return this.mouseEvent(mouse);
	}
	/// called by parent for keyboardEvent
	bool _keyboardEventCall(KeyboardEvent key, bool cycle){
		if (!(_eventSub & key.state))
			return false;
		if (_customKeyboardEvent &&
				_customKeyboardEvent(this, key, cycle))
			return true;
		return this.keyboardEvent(key, cycle);
	}
	/// called by parent for resizeEvent
	bool _resizeEventCall(){
		_requestingResize = false;
		_requestUpdate();
		if (!(_eventSub & EventMask.Resize))
			return false;
		if (_customResizeEvent && _customResizeEvent(this))
			return true;
		return this.resizeEvent();
	}
	/// called by parent for scrollEvent
	bool _scrollEventCall(){
		_requestUpdate();
		if (!(_eventSub & EventMask.Scroll))
			return false;
		if (_customScrollEvent && _customScrollEvent(this))
			return true;
		return this.scrollEvent();
	}
	/// called by parent for activateEvent
	bool _activateEventCall(bool isActive){
		if (!(_eventSub & EventMask.Activate))
			return false;
		if (_isActive == isActive)
			return false;
		_isActive = isActive;
		if (_customActivateEvent &&
				_customActivateEvent(this, isActive))
			return true;
		return this.activateEvent(isActive);
	}
	/// called by parent for timerEvent
	bool _timerEventCall(uint msecs){
		if (!(_eventSub & EventMask.Timer))
			return false;
		if (_customTimerEvent && _customTimerEvent(this, msecs))
			return true;
		return timerEvent(msecs);
	}
	/// called by parent for updateEvent
	bool _updateEventCall(){
		if (!_requestingUpdate || !(_eventSub & EventMask.Update))
			return false;
		_requestingUpdate = false;
		_view.moveTo(_view._offsetX,_view._offsetY);
		if (_customUpdateEvent && _customUpdateEvent(this))
			return true;
		return this.updateEvent();
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

	/// viewport coordinates. (drawable area for widget)
	final @property uint viewportX(){
		return _view._offsetX;
	}
	/// ditto
	final @property uint viewportY(){
		return _view._offsetY;
	}
	/// viewport size. (drawable area for widget)
	final @property uint viewportWidth(){
		return _view._width;
	}
	/// ditto
	final @property uint viewportHeight(){
		return _view._height;
	}

	/// If a coordinate is within writing area,
	/// and writing area actually exists
	final bool isWritable(uint x, uint y){
		return _view.isWritable(x,y);
	}

	/// move seek for next write to terminal.  
	/// can only write in between:
	/// `(_viewX .. _viewX + _viewWidth,
	/// _viewY .. _viewX + _viewHeight)`
	final void moveTo(uint newX, uint newY){
		_view.moveTo(newX, newY);
	}
	/// writes a character on terminal
	/// 
	/// Returns: true if done, false if outside writing area
	final bool write(dchar c, Color fg, Color bg){
		return _view.write(c, fg, bg);
	}
	/// writes a string to terminal.
	/// if it does not fit in one line, it is wrapped
	/// 
	/// Returns: number of characters written
	final uint write(dstring s, Color fg, Color bg){
		return _view.write(s, fg, bg);
	}
	/// fill current line with a character.
	/// `max` is ignored if `max==0`
	/// 
	/// Returns: number of cells written
	final uint fillLine(dchar c, Color fg, Color bg, uint max = 0){
		return _view.fillLine(c, fg, bg, max);
	}

	/// activate the passed widget if this is the correct widget
	/// 
	/// Returns: if it was activated or not
	bool searchAndActivateWidget(QWidget target) {
		if (this == target) {
			this._isActive = true;
			this._activateEventCall(true);
			return true;
		}
		return false;
	}

	/// called by itself, to update events subscribed to
	final void eventSubscribe(uint newSub){
		_eventSub = newSub;
		if (_parent)
			_parent.eventSubscribe();
	}
	/// called by children when they want to subscribe to events
	void eventSubscribe(){}

	/// to set cursor position on terminal.
	/// only works if this is active widget.  
	/// set x or y or both to negative to hide cursor
	void requestCursorPos(int x, int y){
		_requestCursorPos(x, y);
	}

	/// called to request to scrollX
	bool requestScrollX(uint x){
		return _requestScrollX(x);
	}
	/// called to request to scrollY
	bool requestScrollY(uint y){
		return _requestScrollY(y);
	}

	/// Called after UI has been run
	bool initialize(){
		return false;
	}
	/// Called when mouse is clicked with cursor on this widget.
	bool mouseEvent(MouseEvent mouse){
		return false;
	}
	/// Called when key is pressed and this widget is active.
	/// 
	/// `cycle` indicates if widget cycling should happen, if this
	/// widget has child widgets
	bool keyboardEvent(KeyboardEvent key, bool cycle){
		return false;
	}
	/// Called when widget size is changed,
	bool resizeEvent(){
		return false;
	}
	/// Called when the widget is rescrolled, ~but size not changed.~  
	bool scrollEvent(){
		return false;
	}
	/// called right after this widget is activated, or de-activated
	bool activateEvent(bool isActive){
		return false;
	}
	/// called often.
	/// 
	/// `msecs` is the msecs since last timerEvent, not accurate
	bool timerEvent(uint msecs){
		return false;
	}
	/// Called when this widget should re-draw itself
	bool updateEvent(){
		return false;
	}
public:
	/// To request parent to trigger an update event
	void requestUpdate(){
		_requestUpdate();
	}
	/// To request parent to trigger a resize event
	void requestResize(){
		_requestResize();
	}
	/// custom initialize event
	final @property InitFunction onInitEvent(InitFunction func){
		return _customInitEvent = func;
	}
	/// custom mouse event
	final @property MouseEventFuction onMouseEvent(
			MouseEventFuction func){
		return _customMouseEvent = func;
	}
	/// custom keyboard event
	final @property KeyboardEventFunction onKeyboardEvent(
			KeyboardEventFunction func){
		return _customKeyboardEvent = func;
	}
	/// custom resize event
	final @property ResizeEventFunction onResizeEvent(
			ResizeEventFunction func){
		return _customResizeEvent = func;
	}
	/// custom scroll event
	final @property ScrollEventFunction onScrollEvent(
			ScrollEventFunction func){
		return _customScrollEvent = func;
	}
	/// custom activate event
	final @property ActivateEventFunction onActivateEvent(
			ActivateEventFunction func){
		return _customActivateEvent = func;
	}
	/// custom timer event
	final @property TimerEventFunction onTimerEvent(
			TimerEventFunction func){
		return _customTimerEvent = func;
	}
	/// Returns: true if this widget is the current active widget
	final @property bool isActive(){
		return _isActive;
	}
	/// Returns: EventMask of subscribed events
	final @property uint eventSub(){
		return _eventSub;
	}
	/// ratio of height or width
	final @property uint sizeRatio(){
		return _sizeRatio;
	}
	/// ditto
	final @property uint sizeRatio(uint newRatio){
		_sizeRatio = newRatio;
		_requestResize();
		return _sizeRatio;
	}
	/// if widget is visible.
	final @property bool show(){
		return _show;
	}
	/// ditto
	final @property bool show(bool visibility){
		_show = visibility;
		_requestResize();
		return _show;
	}
	/// horizontal scroll.
	final @property uint scrollX(){
		return _scrollX;
	}
	/// ditto
	final @property uint scrollX(uint newVal){
		_requestScrollX(newVal);
		return _scrollX;
	}
	/// vertical scroll.
	final @property uint scrollY(){
		return _scrollY;
	}
	/// ditto
	final @property uint scrollY(uint newVal){
		_requestScrollY(newVal);
		return _scrollY;
	}
	/// width of widget
	final @property uint width(){
		return _width;
	}
	/// ditto
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
	/// ditto
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

/// Used to place widgets in an order (i.e vertical or horizontal)
class QLayout : QWidget{
private:
	/// widgets
	QWidget[] _widgets;
	/// layout type, horizontal or vertical
	QLayout.Type _type;
	/// index of active widget. -1 if none.
	int _activeWidgetIndex = -1;
	/// if it is overflowing
	bool _isOverflowing = false;
	/// Color to fill with in unoccupied space
	Color _fillColor;
	/// Color to fill with when overflowing
	Color _overflowColor = DEFAULT_OVERFLOW_BG;

	/// gets height/width of a widget using:
	/// it's sizeRatio and min/max-height/width
	uint _calculateWidgetSize(QWidget widget, uint ratioTotal,
			uint totalSpace, ref bool free){
		immutable uint calculatedSize =
			cast(uint)(widget._sizeRatio * totalSpace / ratioTotal);
		if (_type == QLayout.Type.Horizontal){
			free = widget.minWidth == 0 && widget.maxWidth == 0;
			return getLimitedSize(calculatedSize, widget.minWidth,
				widget.maxWidth);
		}
		free = widget.minHeight == 0 && widget.maxHeight == 0;
		return getLimitedSize(calculatedSize, widget.minHeight,
			widget.maxHeight);
	}
	
	/// recalculates the size of every widget inside layout
	void _recalculateWidgetsSize(){
		FIFOStack!QWidget widgetStack = new FIFOStack!QWidget;
		uint totalRatio = 0;
		uint totalSpace = _type == QLayout.Type.Horizontal ?
			_width : _height;
		bool free = false;
		foreach (widget; _widgets){
			if (!widget._show)
				continue;
			totalRatio += widget._sizeRatio;
			widget._height = getLimitedSize(_height,
				widget.minHeight, widget.maxHeight);
			
			widget._width = getLimitedSize(_width,
				widget.minWidth, widget.maxWidth);
			widgetStack.push(widget);
		}
		// do widgets with size limits
		/// totalRatio, and space used of widgets with limits
		uint limitWRatio, limitWSize;
		for (int i = 0; i < widgetStack.count; i ++){
			QWidget widget = widgetStack.pop;
			immutable uint space = _calculateWidgetSize(widget,
				totalRatio, totalSpace, free);
			if (free){
				widgetStack.push(widget);
				continue;
			}
			if (_type == QLayout.Type.Horizontal)
				widget._width = space;
			else
				widget._height = space;
			limitWRatio += widget._sizeRatio;
			limitWSize += space;
		}
		totalSpace -= limitWSize;
		totalRatio -= limitWRatio;
		while (widgetStack.count){
			QWidget widget = widgetStack.pop;
			immutable uint space = _calculateWidgetSize(widget,
				totalRatio, totalSpace, free);
			if (_type == QLayout.Type.Horizontal)
				widget._width = space;
			else
				widget._height = space;
			totalRatio -= widget._sizeRatio;
			totalSpace -= space;
		}
		.destroy(widgetStack);
	}

	/// find the next widget to activate
	/// Returns: index, or -1 if no one wanna be active
	int _nextActiveWidget(){
		for (int i = _activeWidgetIndex + 1; i < _widgets.length;
				i ++){
			if ((_widgets[i]._eventSub & EventMask.KeyboardAll) &&
					_widgets[i]._show)
				return i;
		}
		return -1;
	}
protected:
	override void eventSubscribe(){
		_eventSub = 0;
		foreach (widget; _widgets)
			_eventSub |= widget._eventSub;
		
		// if children can become active, then need activate too
		if (_eventSub & EventMask.KeyboardAll)
			_eventSub |= EventMask.Activate;
		
		_eventSub |= EventMask.Scroll;

		if (_parent)
			_parent.eventSubscribe();
	}

	/// Recalculates size and position for all visible widgets
	override bool resizeEvent(){
		_recalculateWidgetsSize(); // resize everything
		// if parent is scrollable container, and there are no size
		// limits, then grow as needed
		if (minHeight + maxHeight + minWidth + maxWidth == 0 && 
				_parent && _parent._isScrollableContainer){
			_width = 0;
			_height = 0;
			if (_type == Type.Horizontal){
				foreach (widget; _widgets){
					if (_height < widget._height)
						_height = widget._height;
					_width += widget._width;
				}
			}else{
				foreach (widget; _widgets){
					if (_width < widget._width)
						_width = widget._width;
					_height += widget._height;
				}
			}
		}
		// now reposition everything
		/// space taken by widgets before
		uint previousSpace = 0;
		uint w, h;
		foreach(widget; _widgets){
			if (!widget._show)
				continue;
			if (_type == QLayout.Type.Horizontal){
				widget._posY = 0;
				widget._posX = previousSpace;
				previousSpace += widget._width;
				w += widget._width;
				if (widget._height > h)
					h = widget._height;
			}else{
				widget._posX = 0;
				widget._posY = previousSpace;
				previousSpace += widget._height;
				h += widget._height;
				if (widget._width > w)
					w = widget._width;
			}
		}
		_isOverflowing = w > _width || h > _height;
		if (_isOverflowing){
			foreach (widget; _widgets)
				widget._view._reset();
		}else{
			foreach (i, widget; _widgets){
				_view._getSlice(&(widget._view), widget._posX,
					widget._posY, widget._width, widget._height);
				widget._resizeEventCall();
			}
		}
		return true;
	}

	/// Resize event
	override bool scrollEvent(){
		if (_isOverflowing){
			foreach (widget; _widgets)
				widget._view._reset();
			return false;
		}
		foreach (i, widget; _widgets){
			_view._getSlice(&(widget._view), widget._posX,
				widget._posY, widget._width, widget._height);
			widget._scrollEventCall();
		}
		return true;
	}
	
	/// Redirects the mouseEvent to the appropriate widget
	override public bool mouseEvent(MouseEvent mouse){
		if (_isOverflowing)
			return false;
		int index;
		if (_type == Type.Horizontal){
			foreach (i, w; _widgets){
				if (w._show && w._posX <= mouse.x &&
						w._posX + w._width > mouse.x){
					index = cast(int)i;
					break;
				}
			}
		}else{
			foreach (i, w; _widgets){
				if (w._show && w._posY <= mouse.y &&
						w._posY + w._height > mouse.y){
					index = cast(int)i;
					break;
				}
			}
		}
		if (index > -1){
			if (mouse.state != MouseEvent.State.Hover &&
					index != _activeWidgetIndex &&
					_widgets[index]._eventSub &
						EventMask.KeyboardAll){
				if (_activeWidgetIndex > -1)
					_widgets[_activeWidgetIndex]._activateEventCall(
						false);
				_widgets[index]._activateEventCall(true);
				_activeWidgetIndex = index;
			}
			return _widgets[index]._mouseEventCall(mouse);
		}
		return false;
	}

	/// Redirects the keyboardEvent to appropriate widget
	override public bool keyboardEvent(KeyboardEvent key,
			bool cycle){
		if (_isOverflowing)
			return false;
		if (_activeWidgetIndex > -1 &&
		_widgets[_activeWidgetIndex]._keyboardEventCall(key, cycle))
			return true;
		
		if (!cycle)
			return false;
		immutable int next = _nextActiveWidget();

		if (_activeWidgetIndex > -1 && next != _activeWidgetIndex)
			_widgets[_activeWidgetIndex]._activateEventCall(false);

		if (next == -1)
			return false;
		_activeWidgetIndex = next;
		_widgets[_activeWidgetIndex]._activateEventCall(true);
		return true;
	}

	/// initialise
	override bool initialize(){
		foreach (widget; _widgets){
			widget._view._reset();
			widget._initializeCall();
		}
		return true;
	}

	/// timer
	override bool timerEvent(uint msecs){
		foreach (widget; _widgets)
			widget._timerEventCall(msecs);
		return true;
	}

	/// activate event
	override bool activateEvent(bool isActive){
		if (isActive){
			_activeWidgetIndex = -1;
			_activeWidgetIndex = _nextActiveWidget();
		}
		if (_activeWidgetIndex > -1)
			_widgets[_activeWidgetIndex]._activateEventCall(
				isActive);
		return true;
	}
	
	/// called by parent widget to update
	override bool updateEvent(){
		if (_isOverflowing){
			foreach (y; viewportY .. viewportY + viewportHeight){
				moveTo(viewportX, y);
				fillLine(' ', DEFAULT_FG, _overflowColor);
			}
			return false;
		}
		if (_type == Type.Horizontal){
			foreach(i, widget; _widgets){
				if (widget._show && widget._requestingUpdate)
					widget._updateEventCall();
				foreach (y; widget._height ..
						viewportY + viewportHeight){
					moveTo(widget._posX, y);
					fillLine(' ', DEFAULT_FG, _fillColor,
						widget._width);
				}
			}
		}else{
			foreach(i, widget; _widgets){
				if (widget._show && widget._requestingUpdate)
					widget._updateEventCall();
				if (widget._width == _width)
					continue;
				foreach (y; widget._posY ..
						widget._posY + widget._height){
					moveTo(widget._posX + widget._width, y);
					fillLine(' ', DEFAULT_FG, _fillColor);
				}
			}
		}
		return true;
	}

	/// activate the passed widget if it's in the current layout
	/// Returns: true if it was activated or not
	override bool searchAndActivateWidget(QWidget target){
		immutable int lastActiveWidgetIndex = _activeWidgetIndex;

		// search and activate recursively
		_activeWidgetIndex = -1;
		foreach (index, widget; _widgets) {
			if ((widget._eventSub & EventMask.KeyboardAll) &&
					widget._show &&
					widget.searchAndActivateWidget(target)){
				_activeWidgetIndex = cast(int)index;
				break;
			}
		}

		// and then manipulate the current layout
		if (lastActiveWidgetIndex != _activeWidgetIndex &&
				lastActiveWidgetIndex > -1)
			_widgets[lastActiveWidgetIndex]._activateEventCall(
				false);
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
		this._fillColor = DEFAULT_BG;
	}
	/// destructor, kills children
	~this(){
		foreach (child; _widgets)
			.destroy(child);
	}
	/// Color for unoccupied space
	@property Color fillColor(){
		return _fillColor;
	}
	/// ditto
	@property Color fillColor(Color newColor){
		return _fillColor = newColor;
	}
	/// Color to fill with when out of space
	@property Color overflowColor(){
		return _overflowColor;
	}
	/// ditto
	@property Color overflowColor(Color newColor){
		return _overflowColor = newColor;
	}
	/// adds a widget
	/// 
	/// `allowScrollControl` specifies if the widget will be able
	/// to make scrolling requests
	void addWidget(QWidget widget, bool allowScrollControl = false){
		widget._parent = this;
		widget._canReqScroll = allowScrollControl && _canReqScroll;
		_widgets ~= widget;
		eventSubscribe();
	}
	/// ditto
	void addWidget(QWidget[] widgets){
		foreach (i, widget; widgets){
			widget._parent = this;
		}
		_widgets ~= widgets;
		eventSubscribe();
	}
}

/// A Scrollable Container
class ScrollContainer : QWidget{
private:
	/// offset in _widget before adding scrolling to it
	uint _offX, _offY;
protected:
	/// widget
	QWidget _widget;
	/// if scrollbar is to be shown
	bool _scrollbarV, _scrollbarH;
	/// if page down/up button should scroll
	bool _pgDnUp = false;
	/// if mouse wheel should scroll
	bool _mouseWheel = false;
	/// height and width available to widget
	uint _drawAreaHeight, _drawAreaWidth;
	
	override void eventSubscribe(){
		_eventSub = EventMask.Resize | EventMask.Scroll;
		if (_widget)
			_eventSub |= _widget._eventSub;
		if (_pgDnUp)
			_eventSub |= EventMask.KeyboardPress;
		if (_mouseWheel)
			_eventSub |= EventMask.MouseAll;
		if (_scrollbarH || _scrollbarV)
			_eventSub |= EventMask.Update;
		if (_parent)
			_parent.eventSubscribe();
	}

	/// re-assings display buffer based on _subScrollX/Y,
	/// and calls scrollEvent on child if `callScrollEvents`
	final void rescroll(bool callScrollEvent = true){
		if (!_widget)
			return;
		_widget._view._reset();
		if (_width == 0 || _height == 0)
			return;
		uint w = _drawAreaWidth, h = _drawAreaHeight;
		if (w > _widget._width)
			w = _widget._width;
		if (h > _widget._height)
			h = _widget._height;
		_view._getSlice(&(_widget._view), 0, 0, w, h);
		_widget._view._offsetX = _offX + _widget._scrollX;
		_widget._view._offsetY = _offY + _widget._scrollY;
		if (callScrollEvent)
			_widget._scrollEventCall();
	}

	override bool requestScrollX(uint x){
		if (!_widget)
			return false;
		if (_widget._width <= _drawAreaWidth)
			x = 0;
		else if (x > _widget._width - _drawAreaWidth)
			x = _widget._width - _drawAreaWidth;
		
		if (_widget._scrollX == x)
			return false;
		_widget._scrollX = x;
		rescroll();
		return true;
	}
	override bool requestScrollY(uint y){
		if (!_widget)
			return false;
		if (_widget._height <= _drawAreaHeight)
			y = 0;
		else if (y > _widget._height - _drawAreaHeight)
			y = _widget._height - _drawAreaHeight;
		
		if (_widget._scrollY == y)
			return false;
		_widget._scrollY = y;
		rescroll();
		return true;
	}

	override bool resizeEvent(){
		_offX = _view._offsetX;
		_offY = _view._offsetY;
		_drawAreaHeight = _height - (1*(_height>0 && _scrollbarV));
		_drawAreaWidth = _width - (1*(_width>0 && _scrollbarV));
		if (!_widget)
			return false;
		if (_scrollbarH || _scrollbarV)
			requestUpdate();
		// try to size widget to fit
		if (_height > 0 && _width > 0){
			_widget._width = getLimitedSize(_drawAreaWidth,
				_widget.minWidth, _widget.maxWidth);
			_widget._height = getLimitedSize(_drawAreaHeight,
				_widget.minHeight, _widget.maxHeight);
		}
		rescroll(false);
		_widget._resizeEventCall();

		return true;
	}

	override bool scrollEvent(){
		_offX = _view._offsetX;
		_offY = _view._offsetY;
		if (_scrollbarH || _scrollbarV)
			requestUpdate();
		rescroll();

		return true;
	}

	override bool keyboardEvent(KeyboardEvent key, bool cycle){
		if (!_widget)
			return false;
		if (_widget.isActive && _widget._keyboardEventCall(key,
				cycle))
			return true;
		
		if (!cycle && _pgDnUp && _drawAreaHeight < _widget._height
				&& key.state == KeyboardEvent.State.Pressed){
			if (key.key == Key.PageUp){
				return requestScrollY(
					_drawAreaHeight > _widget._scrollY ? 0 :
					_widget._scrollY - _drawAreaHeight);
			}
			if (key.key == Key.PageDown){
				return requestScrollY(
					_drawAreaHeight + _widget._scrollY >
						_widget._height ? 
					_widget._height - _drawAreaHeight :
					_widget._scrollY + _drawAreaHeight);
			}
		}
		_widget._activateEventCall(false);
		return false;
	}

	override bool mouseEvent(MouseEvent mouse){
		if (!_widget)
			return false;
		if (_widget._mouseEventCall(mouse)){
			_widget._activateEventCall(true);
			return true;
		}
		_widget._activateEventCall(false);
		if (_mouseWheel && _drawAreaHeight < _widget._height){
			if (mouse.button == mouse.Button.ScrollUp){
				if (_widget._scrollY)
					return requestScrollY(_widget._scrollY - 1);
			}
			if (mouse.button == mouse.Button.ScrollDown){
				if (_widget._scrollY + _drawAreaHeight <
						_widget._height)
					return requestScrollY(_widget._scrollY + 1);
			}
		}
		return false;
	}

	override bool updateEvent(){
		if (!_widget)
			return false;
		if (_widget.show)
			_widget._updateEventCall();
		if (_width > _widget._view._width + (1*(_scrollbarV))){
			foreach (y; 0 .. _widget._view._height){
				moveTo(_widget._view._width, y);
				fillLine(' ', DEFAULT_FG, DEFAULT_BG);
			}
		}
		if (_height > _widget._view._height + (1*(_scrollbarH))){
			foreach (y; _widget._view._height ..
					_height - (1*(_scrollbarH))){
				moveTo(0, y);
				fillLine(' ', DEFAULT_BG, DEFAULT_FG);
			}
		}
		drawScrollbars();

		return true;
	}

	/// draws scrollbars, very basic stuff
	void drawScrollbars(){
		if (!_widget || _width == 0 || _height == 0)
			return;
		const dchar verticalLine = '│', horizontalLine = '─';
		if (_scrollbarH && _scrollbarV){
			moveTo(_width - 1, _height - 1);
			write('┘', DEFAULT_FG, DEFAULT_BG);
		}
		if (_scrollbarH){
			moveTo(0, _drawAreaHeight);
			fillLine(horizontalLine, DEFAULT_FG, DEFAULT_BG,
				_drawAreaWidth);
			const int maxScroll = _widget._width - _drawAreaWidth;
			if (maxScroll > 0){
				const uint barPos =
					(_widget._scrollX * _drawAreaWidth) / maxScroll;
				moveTo(barPos, _drawAreaHeight);
				write(' ', DEFAULT_BG, DEFAULT_FG);
			}
		}
		if (_scrollbarV){
			foreach (y; 0 .. _drawAreaHeight){
				moveTo(_drawAreaWidth, y);
				write(verticalLine, DEFAULT_FG, DEFAULT_BG);
			}
			const int maxScroll = _widget._height - _drawAreaHeight;
			if (maxScroll > 0){
				const uint barPos =
					(_widget._scrollY * _drawAreaHeight) / maxScroll;
				moveTo(_drawAreaWidth, barPos);
				write(' ', DEFAULT_BG, DEFAULT_FG);
			}
		}
	}
public:
	/// constructor
	this(){
		this._isScrollableContainer = true;
		this._scrollbarV = true;
		this._scrollbarH = true;
	}
	~this(){
		if (_widget)
			.destroy(_widget);
	}

	/// Sets the child widget.
	/// 
	/// Returns: false if alreadty has a child
	bool setWidget(QWidget child){
		if (_widget)
			return false;
		_widget = child;
		_widget._parent = this;
		_widget._canReqScroll = true;
		_widget._posX = 0;
		_widget._posY = 0;
		eventSubscribe();
		return true;
	}

	override void requestResize(){
		// just do a the resize within itself
		_resizeEventCall();
	}

	/// Whether to scroll on page up/down keys
	@property bool scrollOnPageUpDown(){
		return _pgDnUp;
	}
	/// ditto
	@property bool scrollOnPageUpDown(bool newVal){
		_pgDnUp = newVal;
		eventSubscribe();
		return _pgDnUp;
	}

	/// Whether to scroll on mouse scroll wheel
	@property bool scrollOnMouseWheel(){
		return _mouseWheel;
	}
	/// ditto
	@property bool scrollOnMouseWheel(bool newVal){
		_mouseWheel = newVal;
		eventSubscribe();
		return _mouseWheel;
	}

	/// Whether to show vertical scrollbar.  
	/// 
	/// Modifying this will request update 
	@property bool scrollbarV(){
		return _scrollbarV;
	}
	/// ditto
	@property bool scrollbarV(bool newVal){
		if (newVal != _scrollbarV){
			_scrollbarV = newVal;
			rescroll();
		}
		return _scrollbarV;
	}
	/// Whether to show horizontal scrollbar.  
	/// 
	/// Modifying this will request update
	@property bool scrollbarH(){
		return _scrollbarH;
	}
	/// ditto
	@property bool scrollbarH(bool newVal){
		if (newVal != _scrollbarH){
			_scrollbarH = newVal;
			rescroll();
		}
		return _scrollbarH;
	}
}

/// Terminal
class QTerminal : QLayout{
private:
	/// To actually access the terminal
	TermWrapper _termWrap;
	/// set to false to stop UI loop in run()
	bool _isRunning;
	/// the key used for cycling active widget
	dchar _activeWidgetCycleKey = WIDGET_CYCLE_KEY;
	/// whether to stop UI loop on Interrupt
	bool _stopOnInterrupt = true;
	/// cursor position
	int _cursorX = -1, _cursorY = -1;

	/// Reads InputEvent and calls appropriate functions
	void _readEvent(Event event){
		if (event.type == Event.Type.HangupInterrupt){
			if (_stopOnInterrupt)
				_isRunning = false;
			else{ // otherwise read it as a Ctrl+C
				KeyboardEvent keyEvent;
				keyEvent.key = KeyboardEvent.CtrlKeys.CtrlC;
				this._keyboardEventCall(keyEvent, false);
			}
		}else if (event.type == Event.Type.Keyboard){
			KeyboardEvent kPress = event.keyboard;
			this._keyboardEventCall(kPress, false);
		}else if (event.type == Event.Type.Mouse){
			this._mouseEventCall(event.mouse);
		}else if (event.type == Event.Type.Resize){
			this._resizeEventCall();
		}
	}

	/// writes _view to _termWrap
	void _flushBuffer(){
		if (_view._buffer.length == 0)
			return;
		Cell prev = _view._buffer[0];
		_termWrap.color(prev.fg, prev.bg);
		uint x, y;
		foreach (cell; _view._buffer){
			if (!prev.colorsSame(cell))
				_termWrap.color(cell.fg, cell.bg);
			prev = cell;
			_termWrap.put(x, y, cell.c);
			x ++;
			if (x == _width){
				x = 0;
				y ++;
			}
		}
	}

protected:

	override void eventSubscribe(){
		// ignore what children want, this needs all events
		// so custom event handlers can be set up 
		_eventSub = uint.max;
	}

	override void requestCursorPos(int x, int y){
		_cursorX = x;
		_cursorY = y;
	}

	override bool resizeEvent(){
		_height = _termWrap.height;
		_width = _termWrap.width;
		_view._buffer.length = _width * _height;
		_view._width = _width;
		_view._actualWidth = _width;
		_view._height = _height;
		super.resizeEvent();
		return true;
	}

	override bool keyboardEvent(KeyboardEvent key, bool cycle){
		cycle = key.state == KeyboardEvent.State.Pressed &&
			key.key == _activeWidgetCycleKey;
		return super.keyboardEvent(key, cycle);
	}
	
	override bool updateEvent(){
		// resize if needed
		if (_requestingResize)
			this._resizeEventCall();
		_cursorX = -1;
		_cursorY = -1;
		// no, this is not a mistake, dont change this to
		// updateEventCall again!
		super.updateEvent();
		// flush _view._buffer to _termWrap
		_flushBuffer();
		// check if need to show/hide cursor
		if (_cursorX < 0 || _cursorY < 0)
			_termWrap.cursorVisible = false;
		else{
			_termWrap.moveCursor(_cursorX, _cursorY);
			_termWrap.cursorVisible = true;
		}
		_termWrap.flush();
		return true;
	}

public:
	/// time to wait between timer events (milliseconds)
	ushort timerMsecs;
	/// constructor
	this(QLayout.Type displayType = QLayout.Type.Vertical,
			ushort timerDuration = 500){
		super(displayType);
		timerMsecs = timerDuration;

		_termWrap = new TermWrapper();
		// so it can make other widgets active on mouse events
		this._isActive = true;
	}
	~this(){
		.destroy(_termWrap);
	}

	/// stops UI loop. **not instant**
	/// if it is in-between event functions, it will complete
	/// those first
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
			int timeout = cast(int)
				(timerMsecs - sw.peek.total!"msecs");
			Event event;
			while (_termWrap.getEvent(timeout, event) > 0){
				_readEvent(event);
				timeout = cast(int)
					(timerMsecs - sw.peek.total!"msecs");
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
	/// Returns: true if the widget was made active, false if not
	bool activateWidget(QWidget target) {
		return this.searchAndActivateWidget(target);
	}

	/// Changes the key used to cycle between active widgets.
	void setActiveWidgetCycleKey(dchar key){
		_activeWidgetCycleKey = key;
	}
}
