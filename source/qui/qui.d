/++
	Contains all the classes that make up qui.
+/
module qui.qui;

import utils.ds;

import std.datetime.stopwatch;
import std.conv : to;
import std.process;
import std.algorithm;
debug import std.stdio;

import qui.termwrap;

/// default active widget cycling key, tab
enum dchar WIDGET_CYCLE_KEY = '\t';

/// Colors
alias Color = qui.termwrap.Color;
/// Availabe Keys (keyboard) for input
alias Key = qui.termwrap.Event.Keyboard.Key;
/// Mouse Event
alias MouseEvent = Event.Mouse;
/// Keyboard Event
alias KeyboardEvent = Event.Keyboard;

/// MouseEvent function.
alias MouseEventFuction = void delegate(QWidget, MouseEvent);
/// KeyboardEvent function.
alias KeyboardEventFunction = void delegate(QWidget, KeyboardEvent, bool);
/// ResizeEvent function.
alias ResizeEventFunction = void delegate(QWidget);
/// ScrollEvent function.
alias ScrollEventFunction = void delegate(QWidget);
/// ActivateEvent function.
alias ActivateEventFunction = void delegate(QWidget, bool);
/// TimerEvent function.
alias TimerEventFunction = void delegate(QWidget, uint);
/// AdoptEvent function.
alias AdoptEventFunction = void delegate(QWidget, bool);
/// UpdateEvent function.
alias UpdateEventFunction = void delegate(QWidget);

/// Display buffer
struct Viewport{
private:
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

	Cell[][] _buffer;
	/// where cursor is right now (offsets applied)
	uint _seekX, _seekY;
	/// these are subtracted, only when seek is set, not after
	uint _offX, _offY;

	/// reset
	void _reset(){
		_buffer = null;
		_seekX = _seekY = _offX = _offY = 0;
	}

	/// increments seekX, if overflowing, increments seekY
	void _incSeekX(uint inc = 1){
		_seekX += inc;
		if (width && _seekX >= width){
			_seekY += _seekX / width;
			_seekX %= width;
		}
	}

	/// set another Viewport so that it is a rectangular slice of this
	void _getSlice(ref Viewport sub, uint x, uint y, uint width, uint height,
			uint offX = 0, uint offY = 0){
		sub._reset;
		// if zero size, or sub completely outside viewport, do nothing
		if (width == 0 || height == 0 || x + width < _offX || y + height < _offY ||
				x > this.width + _offX || y > this.height + _offY)
			return;

		// apply offsets to x and y
		if (x < _offX){
			sub._offX = _offX - x;
			width -= sub._offX;
			x = 0;
		}else{
			x -= _offX;
		}
		if (y < _offY){
			sub._offY = _offY - y;
			height -= sub._offY;
			y = 0;
		}else{
			y -= _offY;
		}

		// apply offX/Y to sub
		sub._offX += offX;
		sub._offY += offY;

		// if width or height overflowing, reduce them to fit
		if (width + x > this.width)
			width = this.width - x;
		if (height + y > this.height)
			height = this.height - y;

		// now set buffer
		sub._buffer.length = height;
		foreach (i; 0 .. height)
			sub._buffer[i] = _buffer[i + y][x .. x + width];
	}

public:
	/// width
	@property uint width(){
		return cast(uint)(_buffer.length ? _buffer[0].length : 0);
	}
	/// height
	@property uint height() const {
		return cast(uint)_buffer.length;
	}
	/// x coordinate of viewport (offset X)
	@property uint x() const {
		return _offX;
	}
	/// y coordinate of viewport (offset Y)
	@property uint y() const {
		return _offY;
	}

	/// Returns: true if x and y are at a position where writing can happen
	bool isWritable(uint x, uint y){
		return x >= _offX && y >= _offY &&
			x < width + _offX && y < height + _offY;
	}

	/// move to a position. if x > width, moved to x=0 of next row
	///
	/// Returns: true if done, false if outside writing area
	bool moveTo(uint x, uint y){
		if (!isWritable(x, y))
			return false;
		_seekX = x - _offX;
		_seekY = y - _offY;
		_incSeekX(0); // increment by 0, to fix overflow. TODO is this necessary?
		return true;
	}

	/// Writes a character at current position and move ahead
	///
	/// Returns: false if outside writing area
	bool write(dchar c, Color fg = Color.Default, Color bg = Color.Default){
		if (_seekX < width && _seekY < height)
			_buffer[_seekY][_seekX] = Cell(c, fg, bg);
		_incSeekX;
		return true;
	}

	/// Writes a string.
	///
	/// Returns: number of characters written
	uint write(dstring s, Color fg = Color.Default, Color bg = Color.Default){
		foreach (i, c; s){
			if (!write(c, fg, bg))
				return cast(uint)i;
		}
		return cast(uint)s.length;
	}

	/// Fills line, starting from current coordinates,
	/// with maximum `max` number of chars, if `max>0`
	///
	/// Returns: number of characters written, or 0 if outside bounds
	uint fillLine(dchar c = ' ', Color fg = Color.Default,
			Color bg = Color.Default, uint max = 0){
		if (_seekX >= width || _seekY >= height)
			return 0;
		// find how many cells to fill
		uint r = width - _seekX;
		if (max)
			r = min(max, r);
		// fill them
		_buffer[_seekY][_seekX .. _seekX + r] = Cell(c, fg, bg);
		// increment seek
		_incSeekX(r);
		return r;
	}
}

/// Returns: size after considering minimum and maximum allowed
///
/// if `min==0`, it is ignored. if `max==0`, it is ignored
private uint getLimitedSize(uint calculated, uint min, uint max){
	if (min && calculated < min)
		return min;
	if (max && calculated > max)
		return max;
	return calculated;
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
	/// if this widget is the active widget
	bool _isActive = false;
	/// if this widget is requesting update
	bool _requestingUpdate = true;
	/// the parent widget
	QParent _parent;

	/// custom adopt event
	AdoptEventFunction _customAdoptEvent;
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

protected:
	/// minimum width
	uint _minWidth;
	/// maximum width
	uint _maxWidth;
	/// minimum height
	uint _minHeight;
	/// maximum height
	uint _maxHeight;
	/// viewport
	Viewport view;

	/// TODO: Redesign this so the widget doesnt call this itself
	/// activate the passed widget if this is the correct widget
	///
	/// Returns: if it was activated or not
	bool widgetActivate(QWidget target){
		if (this != target)
			return false;
		this._isActive = true;
		activateEvent(true);
		return true;
	}

	/// to set cursor position on terminal.
	/// only works if this is active widget.
	/// set x or y or both to negative to hide cursor
	void requestCursorPos(int x, int y){
		if (!_isActive || !_parent)
			return;
		if (x < 0 || y < 0)
			_parent.requestCursorPos(-1, -1);
		else
			_parent.requestCursorPos(_posX + x - view.x, _posY + y - view.x);
	}

	/// called to request to scrollX
	bool scrollToX(int x){
		if (!_isActive || !_parent)
			return false;
		return _parent.scrollToX(_posX + x - view.x);
	}

	/// called to request to scrollY
	bool scrollToY(int y){
		if (!_isActive || !_parent)
			return false;
		return _parent.scrollToY(_posY + y - view.y);
	}

	/// Called when this widget is adopted by a parent, or disowned.
	/// The `adopted` flag is true when adopted, false when disowned
	bool adoptEvent(bool adopted){
		return false;
	}

	/// Called when mouse is clicked with cursor on this widget.
	bool mouseEvent(MouseEvent mouse){
		return false;
	}

	/// Called when key is pressed and this widget is active.
	/// `cycle` indicates if widget cycling should happen
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

	/// called `msecs` milliseconds after the previous timerEvent was called
	bool timerEvent(uint msecs){
		return false;
	}

	/// called when this widget should re-draw itself
	bool updateEvent(){
		return false;
	}

public:
	/// Requests parent widget to update it
	void requestUpdate(){
		if (_requestingUpdate)
			return;
		_requestingUpdate = true;
		if (_parent)
			_parent.requestUpdate;
	}

	/// Requests parent widget to resize it
	/// **Do not call this in a resizeEvent**
	void requestResize(){
		if (_parent)
			_parent.requestResize;
	}

	/// custom initialize event
	final @property AdoptEventFunction onAdoptEvent(AdoptEventFunction func){
		return _customAdoptEvent = func;
	}

	/// custom mouse event
	final @property MouseEventFuction onMouseEvent(MouseEventFuction func){
		return _customMouseEvent = func;
	}

	/// custom keyboard event
	final @property KeyboardEventFunction onKeyboardEvent(
			KeyboardEventFunction func){
		return _customKeyboardEvent = func;
	}

	/// custom resize event
	final @property ResizeEventFunction onResizeEvent(ResizeEventFunction func){
		return _customResizeEvent = func;
	}

	/// custom scroll event
	final @property ScrollEventFunction onScrollEvent(ScrollEventFunction func){
		return _customScrollEvent = func;
	}

	/// custom activate event
	final @property ActivateEventFunction onActivateEvent(
			ActivateEventFunction func){
		return _customActivateEvent = func;
	}

	/// custom timer event
	final @property TimerEventFunction onTimerEvent(TimerEventFunction func){
		return _customTimerEvent = func;
	}

	/// custom update event
	final @property UpdateEventFunction onUpdateEvent(UpdateEventFunction func){
		return _customUpdateEvent = func;
	}

	/// Returns: true if this widget is the current active widget
	final @property bool isActive() const {
		return _isActive;
	}

	/// width of widget
	final @property uint width() const {
		return _width;
	}

	/// height of widget
	final @property uint height() const {
		return _height;
	}

	/// if this widget's height has constraints
	final @property bool heightConstrained(){
		return (minHeight || maxHeight) &&
			(!(minHeight && maxHeight) || maxHeight >= minHeight);
	}

	/// if this widget's width has constraints
	final @property bool widthConstrained(){
		return (minWidth || maxWidth) &&
			(!(minWidth && maxWidth) || maxWidth >= minWidth);
	}

	/// if this widget's size is constrained
	final @property bool sizeConstrained(){
		return heightConstrained || widthConstrained;
	}

	/// if this widget wants focus.
	/// This should return true if the widget wants keyboard input
	@property bool wantsFocus() const {
		return false;
	}

	/// minimum width
	@property uint minWidth(){
		return _minWidth;
	}

	/// ditto
	@property uint minWidth(uint value){
		_minWidth = value;
		requestResize;
		return minWidth;
	}

	/// minimum height
	@property uint minHeight(){
		return _minHeight;
	}

	/// ditto
	@property uint minHeight(uint value){
		_minHeight = value;
		requestResize;
		return minHeight;
	}

	/// maximum width
	@property uint maxWidth(){
		return _maxWidth;
	}

	/// ditto
	@property uint maxWidth(uint value){
		_maxWidth = value;
		requestResize;
		return maxWidth;
	}

	/// maximum height
	@property uint maxHeight(){
		return _maxHeight;
	}

	/// ditto
	@property uint maxHeight(uint value){
		_maxHeight = value;
		requestResize;
		return maxHeight;
	}
}

/// Base class for parent widgets
abstract class QParent : QWidget{
protected:
	/// positions child widget on X axis
	final void widgetPositionX(QWidget child, uint x){
		if (!child || child._parent != this)
			return;
		child._posX = x;
	}

	/// positions child widget on y axis
	final void widgetPositionY(QWidget child, uint y){
		if (!child || child._parent != this)
			return;
		child._posY = y;
	}

	/// positions child widget on X and Y coordinates
	final void widgetPosition(QWidget child, uint x, uint y){
		if (!child || child._parent != this)
			return;
		child._posX = x;
		child._posY = y;
	}

	/// Assigns widget a viewport based on its position and size
	/// if width is 0, `widget.width` is used
	/// if height is 0, `widget.height` is used
	final void widgetViewportAssign(QWidget child,
			uint width = 0, uint height = 0,
			uint scrollX = 0, uint scrollY = 0){
		if (!child || child._parent != this)
			return;
		if (!width)
			width = child.width;
		if (!height)
			height = child.height;
		view._getSlice(child.view, child._posX, child._posY,
				width, height, scrollX, scrollY);
	}

	/// sets child widget's width
	/// Returns: true if width applied as it is, false if constrained
	final bool widgetSizeWidth(QWidget child, uint width){
		if (!child || child._parent != this)
			return false;
		child._width = width;
		if (!child.widthConstrained)
			return true;
		if (child.minWidth && child._width < child.minWidth)
			child._width = child.minWidth;
		if (child.maxWidth && child._width > child.maxWidth)
			child._width = child.maxWidth;
		return width == child._width;
	}

	/// sets child widget's height
	/// Returns: true if height applied as it is, false if constrained
	final bool widgetSizeHeight(QWidget child, uint height){
		if (!child || child._parent != this)
			return false;
		child._height = height;
		if (!child.heightConstrained)
			return true;
		if (child.minHeight && child._height < child.minHeight)
			child._height = child.minHeight;
		if (child.maxHeight && child._height > child.maxHeight)
			child._height = child.maxHeight;
		return height == child._height;
	}

	/// sets child widget's width and height
	/// Returns: true if sizes applied as it is, false if constrained
	final bool widgetSize(QWidget child, uint width, uint height){
		return widgetSizeWidth(child, width) & widgetSizeHeight(child, height);
	}

	/// Called when this widget was made to disown a child
	void disownEvent(QWidget widget){}

	/// Adopt another widget (i.e become its parent)
	/// If the widget already has a parent, the current parent will disown it
	/// i.e: current parent will receive a `disownEvent`
	final void adopt(QWidget widget){
		if (!widget)
			return;
		if (widget._parent)
			widget._parent.disown(widget);
		widget._parent = this;
		widget.view._reset;
		adoptEventCall(widget, true);
	}

	/// Disown a widget. Doing so will trigger it's own disownEvent
	/// Returns: true if done, false if not (probably due to it not being child)
	final bool disown(QWidget widget){
		if (!widget || widget._parent != this)
			return false;
		disownEvent(widget);
		widget.view._reset;
		widget._parent = null;
		adoptEventCall(widget, false);
		return true;
	}

	/// Calls adoptEvent on child
	final bool adoptEventCall(QWidget child, bool adopted){
		if (!child || child._parent != this)
			return false;
		if (child._customAdoptEvent)
			child._customAdoptEvent(child, adopted);
		return child.adoptEvent(adopted);
	}

	/// Calls mouseEvent on child
	final bool mouseEventCall(QWidget child, MouseEvent mouse){
		if (!child || child._parent != this)
			return false;
		mouse.x = (mouse.x - cast(int)child._posX) + child.view.x;
		mouse.y = (mouse.y - cast(int)child._posY) + child.view.y;
		if (child._customMouseEvent)
			child._customMouseEvent(child, mouse);
		return child.mouseEvent(mouse);
	}

	/// Calls keyboardEvent on child
	final bool keyboardEventCall(QWidget child, KeyboardEvent key, bool cycle){
		if (!child || child._parent != this)
			return false;
		if (child._customKeyboardEvent)
			child._customKeyboardEvent(child, key, cycle);
		return child.keyboardEvent(key, cycle);
	}

	/// Calls resizeEvent on child
	final bool resizeEventCall(QWidget child){
		if (!child || child._parent != this)
			return false;
		if (child._customResizeEvent)
			child._customResizeEvent(child);
		return child.resizeEvent;
	}

	/// Calls scrollEvent on child
	final bool scrollEventCall(QWidget child){
		if (!child || child._parent != this)
			return false;
		if (child._customScrollEvent)
			child._customScrollEvent(child);
		return child.scrollEvent;
	}

	/// Calls activateEvent on child
	final bool activateEventCall(QWidget child, bool isActive){
		if (!child || child._parent != this || isActive == child._isActive)
			return false;
		child._isActive = isActive;
		if (child._customActivateEvent)
			child._customActivateEvent(child, isActive);
		return child.activateEvent(isActive);
	}

	/// Calls timerEvent on child
	final bool timerEventCall(QWidget child, uint msecs){
		if (!child || child._parent != this)
			return false;
		if (child._customTimerEvent)
			child._customTimerEvent(child, msecs);
		return child.timerEvent(msecs);
	}

	/// Calls updateEvent on child
	final bool updateEventCall(QWidget child){
		if (!child || child._parent != this || !child._requestingUpdate)
			return false;
		child._requestingUpdate = false;
		if (child._customUpdateEvent)
			child._customUpdateEvent(child);
		return child.updateEvent;
	}
}

/// Layout type
enum QLayoutType{
	Horizontal,
	Vertical,
}

/// Positions widgets in a Vertical or Horizontal layout
/// Attempts to best mimic size properties of widgets inside it.
class QLayout(QLayoutType type) : QParent{
private:
	/// Sets sizes for a widget
	/// Returns: true if "natural" size was used, false if size was constrained
	bool widgetSizeByRatio(QWidget widget, uint sizeTotal, uint count){
		assert (count != 0);
		static if (type == Type.Horizontal){
			return widgetSizeWidth(widget, sizeTotal / count);
		}else static if (type == Type.Vertical){
			return widgetSizeHeight(widget, sizeTotal / count);
		}
	}

	/// Resets sizes caches
	void _sizeCacheReset(){
		_maxWidth = _maxHeight = _minWidth = _minHeight = uint.max;
	}

protected:
	/// widgets
	QWidget[] widgets;
	/// active widget index. `>=_widgets.length` when no widgets
	uint activeWidgetIndex;

	/// recalculates all widgets' sizes
	void widgetsSizeRecalculate(){
		QWidget[] queue = widgets.dup;
		uint sizeTotal = height;
		static if (type == Type.Horizontal)
			sizeTotal = width;
		uint count = cast(uint)queue.length, size = sizeTotal;
		for (int i = 0; i < queue.length; i ++){
			QWidget widget = queue[i];
			bool natural = widgetSizeByRatio(widget, size, count);
			uint sizeUsed;
			static if (type == Type.Horizontal){
				widgetSizeHeight(widget, height);
				sizeUsed = widget.width;
			}else static if (type == Type.Vertical){
				widgetSizeWidth(widget, width);
				sizeUsed = widget.height;
			}
			if (!natural){
				// start over again, exclude this widget
				if (queue.length == 1)
					break;
				queue[i] = queue[$ - 1];
				queue.length --;
				sizeTotal -= sizeUsed;
				count = cast(uint)queue.length;
				size = sizeTotal;
				i = -1;
				continue;
			}
			count --;
			size -= sizeUsed;
		}
	}

	/// Positions widgets in the widgets array
	void widgetsReposition(){
		uint pos = 0;
		foreach (widget; widgets){
			static if (type == Type.Horizontal){
				widgetPosition(widget, pos, 0);
				pos += widget.width;
			}else static if (type == Type.Vertical){
				widgetPosition(widget, 0, pos);
				pos += widget.height;
			}
			widgetViewportAssign(widget);
		}
	}

	/// Gets widget at x, y coorinates
	/// Returns: widget index in widgets, or >= widgets.length if none
	uint widgetAt(uint x, uint y){
		uint ret = uint.max;
		foreach (i, widget; widgets[1 .. $]){
			static if (type == Type.Horizontal){
				if (widget._posX > x)
					ret = cast(uint)i;
			}else static if (type == Type.Vertical){
				if (widget._posY > y)
					ret = cast(uint)i;
			}
		}
		if (ret < widgets.length){
			static if (type == Type.Horizontal){
				if (y < widgets[ret].height)
					return ret;
			}else static if (type == Type.Vertical){
				if (x < widgets[ret].width)
					return ret;
			}
		}
		return cast(uint)widgets.length;
	}

	/// Gets next candidate for focus
	/// Returns: index of widget, or >= widgets.length if none
	uint activeWidgetNext(){
		foreach (i; 1 .. widgets.length + (activeWidgetIndex >= widgets.length)){
			immutable uint index = cast(uint)(i + activeWidgetIndex) % widgets.length;
			QWidget widget = widgets[index];
			if (widget.wantsFocus)
				return index;
		}
		return uint.max;
	}

	/// Activates a widget, by index. taking care of calling activate events
	void widgetActivate(uint index){
		if (activeWidgetIndex == index)
			return;
		if (activeWidgetIndex < widgets.length){
			activateEventCall(widgets[activeWidgetIndex], false);
		}
		if (index < widgets.length && widgets[index].wantsFocus){
			activeWidgetIndex = index;
			activateEventCall(widgets[activeWidgetIndex], true);
			return;
		}
		activeWidgetIndex = cast(uint)widgets.length;
	}

	override bool widgetActivate(QWidget target){
		foreach (i, widget; widgets){
			if (widget.wantsFocus && widget.widgetActivate(target)){
				widgetActivate(cast(uint)i);
				return true;
			}
		}
		return false;
	}

	override void disownEvent(QWidget widget){
		int index = cast(int)widgets.countUntil(widget);
		if (index < 0)
			return;
		widgets[index .. $ - 1] = widgets[index + 1 .. $];
		widgets.length --;
		_sizeCacheReset;
		requestResize;
		requestUpdate;
	}

	override bool adoptEvent(bool adopted){
		if (!adopted){
			activeWidgetIndex = cast(uint)widgets.length;
			return true;
		}
		_sizeCacheReset;
		requestUpdate;
		requestResize;
		return true;
	}

	override bool mouseEvent(MouseEvent mouse){
		uint index = widgetAt(mouse.x, mouse.y);
		if (index >= widgets.length)
			return false;
		widgetActivate(index);
		return mouseEventCall(widgets[index], mouse);
	}

	override bool keyboardEvent(KeyboardEvent key, bool cycle){
		if (!widgets.length)
			return false;
		if (activeWidgetIndex < widgets.length &&
				keyboardEventCall(widgets[activeWidgetIndex], key, cycle))
			return true;
		if (!cycle)
			return false;
		widgetActivate(activeWidgetNext);
		return activeWidgetIndex < widgets.length;
	}

	override bool resizeEvent(){
		_sizeCacheReset;
		// reposition stuff, and assign them views
		widgetsSizeRecalculate;
		widgetsReposition;
		foreach (widget; widgets)
			resizeEventCall(widget);
		return true;
	}

	override bool scrollEvent(){
		widgetsReposition;
		foreach (widget; widgets)
			scrollEventCall(widget);
		return true;
	}

	override bool activateEvent(bool isActive){
		if (!widgets.length)
			return false;
		if (!isActive){
			if (activeWidgetIndex < widgets.length)
				activateEventCall(widgets[activeWidgetIndex], false);
			return true;
		}
		if (activeWidgetIndex >= widgets.length)
			activeWidgetIndex = activeWidgetNext;
		widgetActivate(activeWidgetIndex);
		return true;
	}

	override bool timerEvent(uint msecs){
		foreach (widget; widgets)
			timerEventCall(widget, msecs);
		return true;
	}

	override bool updateEvent(){
		foreach(widget; widgets)
			updateEventCall(widget);
		return true;
	}

public:
	/// Layout types
	alias Type = QLayoutType;
	/// constructor
	this(){
		// in this widget, uint.max indicates yet to be calculated
		_sizeCacheReset;
	}

	override void requestResize(){
		_sizeCacheReset;
		super.requestResize;
	}

	/// Adds a widget at end
	/// If the widget already has a parent, they will disown it
	void widgetAdd(QWidget widget){
		if (!widget)
			return;
		adopt(widget);
		widgets ~= widget;
		requestResize;
	}

	/// Removes a widget
	/// Returns: true if done, false if failed (probably due to it not existing)
	bool widgetRemove(QWidget widget){
		if (widgets.countUntil(widget) < 0 || !disown(widget))
			return false;
		requestResize;
		return true;
	}

	override @property bool wantsFocus() const {
		foreach (widget; widgets){
			if (widget.wantsFocus)
				return true;
		}
		return false;
	}

	override @property uint minWidth(){
		if (_minWidth != uint.max)
			return _minWidth;
		_minWidth = 0;
		static if (type == Type.Horizontal){
			foreach (widget; widgets)
				_minWidth += widget.minWidth;
		}else static if (type == Type.Vertical){
			foreach (widget; widgets)
				_minWidth = max(widget.minWidth, _minWidth);
		}
		return _minWidth;
	}

	override @property uint minWidth(uint val){
		return minWidth;
	}

	override @property uint minHeight(){
		if (_minHeight != uint.max)
			return _minHeight;
		_minHeight = 0;
		static if (type == Type.Horizontal){
			foreach (widget; widgets)
				_minHeight = max(widget.minHeight, _minHeight);
		}else static if (type == Type.Vertical){
			foreach (widget; widgets)
				_minHeight += widget.minHeight;
		}
		return _minHeight;
	}

	override @property uint minHeight(uint val){
		return minHeight;
	}

	override @property uint maxWidth(){
		if (_maxWidth != uint.max)
			return _maxWidth;
		_maxWidth = 0;
		static if (type == Type.Horizontal){
			foreach (widget; widgets){
				if (widget.maxWidth == 0)
					return _maxWidth = 0;
				_maxWidth += widget.maxWidth;
			}
		}else static if (type == Type.Vertical){
			foreach (widget; widgets)
				_maxWidth = max(widget.maxWidth, _maxWidth);
		}
		return _maxWidth;
	}

	override @property uint maxWidth(uint val){
		return maxWidth;
	}

	override @property uint maxHeight(){
		if (_maxHeight != uint.max)
			return _maxHeight;
		_maxHeight = 0;
		static if (type == Type.Horizontal){
			foreach (widget; widgets)
				_maxHeight = max(widget.maxHeight, _maxHeight);
		}else static if (type == Type.Vertical){
			foreach (widget; widgets){
				if (widget.maxHeight == 0)
					return _maxHeight = 0;
				_maxHeight += widget.maxHeight;
			}
		}
		return _maxHeight;
	}
}

alias QHorizontalLayout = QLayout!(QLayoutType.Horizontal);
alias QVerticalLayout = QLayout!(QLayoutType.Vertical);

/// A container for widgets
/// It will create virtual space, which can be scrolled, to fit larger widgets
/// in smaller spaces.
/// its maxHeight and maxWidth are equal to it's child's minimum sizes
class QContainer : QParent{
private:
	/// scroll offsets
	uint _scrollX, _scrollY;
	/// the widget being contained
	QWidget _widget;

protected:
	override void disownEvent(QWidget widget){
		if (widget != _widget)
			return;
		_widget = null;
		_scrollX = _scrollY = 0;
	}

	override bool mouseEvent(MouseEvent mouse){
		return mouseEventCall(_widget, mouse);
	}

	override bool keyboardEvent(KeyboardEvent key, bool cycle){
		return keyboardEventCall(_widget, key, cycle);
	}

	override bool resizeEvent(){
		widgetSize(_widget, width, height);
		widgetViewportAssign(_widget, _widget.width, _widget.height,
				_scrollX, _scrollY); // re-assign viewport
		return resizeEventCall(_widget);
	}

	override bool scrollEvent(){
		widgetViewportAssign(_widget, _widget.width, _widget.height,
				_scrollX, _scrollY); // re-assign viewport
		return scrollEventCall(_widget);
	}

	override bool activateEvent(bool isActive){
		return activateEventCall(_widget, isActive);
	}

	override bool timerEvent(uint msecs){
		return timerEventCall(_widget, msecs);
	}

	override bool updateEvent(){
		return updateEventCall(_widget);
	}

public:
	/// constructor
	this(){}

	override void requestResize(){
		// just resize right now, its free real estate inside container
		resizeEvent;
	}

	/// widget to contain
	@property QWidget widget(){
		return _widget;
	}
	/// ditto
	@property QWidget widget(QWidget newVal){
		if (_widget)
			disown(_widget);
		if (newVal){
			_widget = newVal;
			adopt(_widget);
			widgetPosition(_widget, 0, 0);
		}
		_scrollX = _scrollY = 0;
		requestResize;
		return _widget;
	}

	/// scrollX
	@property uint scrollX(){
		return _scrollX;
	}
	/// ditto
	@property uint scrollX(uint newVal){
		if (!_widget || _widget.width <= width)
			newVal = 0;
		else if (newVal + width > _widget.width)
			newVal = _widget.width - width;
		_scrollX = newVal;
		scrollEvent;
		return _scrollX;
	}

	/// scrollX
	@property uint scrollY(){
		return _scrollY;
	}
	/// ditto
	@property uint scrollY(uint newVal){
		if (!_widget || _widget.height <= height)
			newVal = 0;
		if (newVal + height > _widget.height)
			newVal = _widget.height - height;
		_scrollY = newVal;
		scrollEvent;
		return _scrollY;
	}

	override @property uint maxWidth(){
		if (_widget)
			return _widget.maxWidth;
		return 0;
	}
	override @property uint maxWidth(uint newVal){
		return maxWidth;
	}

	override @property uint maxHeight(){
		if (_widget)
			return _widget.maxHeight;
		return 0;
	}
	override @property uint maxHeight(uint newVal){
		return maxHeight;
	}
}

/// Terminal
class QTerminal : QContainer{
private:
	/// To actually access the terminal
	TermWrapper _termWrap;
	bool _isRunning;
	/// the key used for cycling active widget
	dchar _activeWidgetCycleKey = WIDGET_CYCLE_KEY;
	/// cursor position
	int _cursorX = -1, _cursorY = -1;

	/// Reads InputEvent and calls appropriate functions
	void _readEvent(Event event){
		if (event.type == Event.Type.HangupInterrupt){
			if (stopOnInterrupt){
				_isRunning = false;
			}else{ // otherwise read it as a Ctrl+C
				KeyboardEvent keyEvent;
				keyEvent.key = KeyboardEvent.CtrlKeys.CtrlC;
				keyboardEventCall(this, keyEvent, false);
			}
		}else if (event.type == Event.Type.Keyboard){
			keyboardEvent(event.keyboard, false);
		}else if (event.type == Event.Type.Mouse){
			mouseEvent(event.mouse);
		}else if (event.type == Event.Type.Resize){
			resizeEvent;
		}
	}

	/// writes view to _termWrap
	void _flushBuffer(){
		if (!view.height || !view.width)
			return;
		auto prev = view._buffer[0][0]; // TODO, abstract accessing VP buffer
		_termWrap.color(prev.fg, prev.bg);
		foreach (y, row; view._buffer){
			foreach (x, cell; row){
				if (!prev.colorsSame(cell)){
					_termWrap.color(cell.fg, cell.bg);
					prev = cell;
				}
				_termWrap.put(cast(uint)x, cast(uint)y, cell.c);
			}
		}
	}

protected:

	override void requestCursorPos(int x, int y){
		_cursorX = x;
		_cursorY = y;
	}

	override bool mouseEvent(MouseEvent mouse){
		if (_customMouseEvent)
			_customMouseEvent(this, mouse);
		return super.mouseEvent(mouse);
	}

	override bool keyboardEvent(KeyboardEvent key, bool cycle){
		cycle = key.state == KeyboardEvent.State.Pressed &&
			key.key == _activeWidgetCycleKey;
		if (_customKeyboardEvent)
			_customKeyboardEvent(this, key, cycle);
		return super.keyboardEvent(key, cycle);
	}

	override bool resizeEvent(){
		_height = _termWrap.height;
		_width = _termWrap.width;
		// TODO abstract this away, this should be done in Viewport
		view._buffer.length = _height;
		foreach (i, ref row; view._buffer)
			row.length = _width;

		if (_customResizeEvent)
			_customResizeEvent(this);
		super.resizeEvent;
		return true;
	}

	override bool timerEvent(uint msecs){
		if (_customTimerEvent)
			_customTimerEvent(this, msecs);
		return super.timerEvent(msecs);
	}

	override bool updateEvent(){
		if (!_requestingUpdate)
			return false;
		_requestingUpdate = false;
		_cursorX = -1;
		_cursorY = -1;
		super.updateEvent;
		// flush view._buffer to _termWrap
		_flushBuffer;
		// check if need to show/hide cursor
		if (_cursorX < 0 || _cursorY < 0){
			_termWrap.cursorVisible = false;
		}else{
			_termWrap.moveCursor(_cursorX, _cursorY);
			_termWrap.cursorVisible = true;
		}
		_termWrap.flush;
		return true;
	}

public:
	/// whether to stop UI loop on Interrupt (Ctrl+C)
	bool stopOnInterrupt = true;
	/// time to wait between timer events (milliseconds)
	ushort timerMsecs;

	final override void requestUpdate(){
		_requestingUpdate = true;
	}

	/// constructor
	this(ushort timerDuration = 500){
		// HACK: fix for issue #18 (resizing on alacritty borked)
		if (environment["TERM"] == "alacritty")
			environment["TERM"] = "xterm";
		timerMsecs = timerDuration;

		_termWrap = new TermWrapper;
		// so it can make other widgets active on mouse events
		this._isActive = true;
	}
	~this(){
		.destroy(_termWrap);
	}

	/// stops UI loop. **not instant**
	void terminate(){
		_isRunning = false;
	}

	/// starts the UI loop
	void run(){
		resizeEvent;
		updateEvent;
		_isRunning = true;
		StopWatch sw = StopWatch(AutoStart.yes);
		while (_isRunning){
			int timeout = cast(int)(timerMsecs - sw.peek.total!"msecs");
			Event event;
			while (_isRunning && _termWrap.getEvent(timeout, event) > 0){
				_readEvent(event);
				timeout = cast(int)(timerMsecs - sw.peek.total!"msecs");
				updateEvent;
			}
			if (_isRunning && sw.peek.total!"msecs" >= timerMsecs){
				timerEvent(cast(uint)sw.peek.total!"msecs");
				sw.reset;
				sw.start;
				updateEvent;
			}
		}
	}
}
