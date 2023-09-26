/++
	Some widgets that are included in the package.
+/
module qui.widgets;

import qui.qui;
import utils.misc;
import utils.ds;

import std.conv : to;
import std.algorithm : max;
debug import std.stdio;

/// for testing only.
class ScrollTestingWidget : QWidget{
protected:
	/// whether to display debug info
	bool _debugInfo;

	override bool adoptEvent(bool adopted){
		if (!adopted)
			return false;
		resize;
		return true;
	}

	override bool scrollEvent(){
		update;
		return true;
	}

	override bool resizeEvent(){
		update;
		return true;
	}

	override bool updateEvent(){
		foreach (y; view.y .. view.y + view.height){
			view.moveTo(view.x, y);
			foreach (x; view.x .. view.x + view.width)
				view.write(((x+y) % 10).to!dstring[0]);
		}
		if (!_debugInfo)
			return true;
		view.moveTo(view.x, view.y);
		view.write("size, width x height:     " ~
			to!dstring(width) ~ "x" ~ to!dstring(height) ~ '|');

		view.moveTo(view.x, view.y + 1);
		view.write("view X, Y: " ~
			to!dstring(view.x) ~ "," ~ to!dstring(view.y) ~ '|');

		view.moveTo(view.x, view.y + 2);
		view.write("view width x height: " ~
			to!dstring(view.width) ~ "x" ~ to!dstring(view.height) ~ '|');
		return true;
	}
public:
	/// constructor
	this(bool debugInfo = false,
			Color textColor = Color.Default, Color backgroundColor = Color.Default){
		_debugInfo = debugInfo;
	}
}

/// Displays some text
///
/// doesnt handle new-line characters
class TextLabelWidget : QWidget{
private:
	/// text and background colors
	Color _fg = Color.Default, _bg = Color.Default;
	/// the text to display
	dstring _caption;
protected:

	override bool adoptEvent(bool adopted){
		if (!adopted)
			return false;
		resize;
		return true;
	}

	override bool scrollEvent(){
		update;
		return true;
	}

	override bool resizeEvent(){
		update;
		return true;
	}

	override bool updateEvent(){
		view.moveTo(view.x, view.y);
		if (view.x > _caption.length)
			view.fillLine(' ', _fg, _bg);
		else
			view.write(_caption[view.x .. $], _fg, _bg);
		return true;
	}
public:
	/// constructor
	this(dstring caption = ""){
		_caption = caption;
		_maxHeight = 1;
		_maxWidth = cast(uint)caption.length;
		_minWidth = _maxWidth;
	}

	/// the text to display
	@property dstring caption(){
		return _caption;
	}
	/// ditto
	@property dstring caption(dstring newCaption){
		_caption = newCaption;
		_maxWidth = cast(uint)caption.length;
		_minWidth = _maxWidth;
		update;
		return _caption;
	}

	/// text color
	@property Color textColor(){
		return _fg;
	}
	/// ditto
	@property Color textColor(Color newColor){
		_fg = newColor;
		update;
		return _fg;
	}

	/// background color
	@property Color backColor(){
		return _bg;
	}
	/// ditto
	@property Color backColor(Color newColor){
		_bg = newColor;
		update;
		return _bg;
	}

	override @property uint minWidth(){
		return cast(uint)_caption.length;
	}
	override @property uint maxWidth(){
		return cast(uint)_caption.length;
	}
	override @property uint minHeight(){
		return 1;
	}
	override @property uint maxHeight(){
		return 1;
	}
}

/// To get single-line input from keyboard
class EditLineWidget : QWidget{
private:
	/// text that's been input-ed
	dchar[] _text;
	/// position of cursor. Next write happens at `_text[_x]`,
	/// next deletion happens at `_text[_x - 1]`
	uint _x;
	/// Foreground and background colors
	Color _fg = Color.Default, _bg = Color.Default;

protected:
	/// moves cursor to left by n characters
	void cursorMoveLeft(uint n = 1){
		if (n > _x)
			_x = 0;
		else
			_x -= n;
	}

	/// moves cursor to right by n characters
	void cursorMoveRight(uint n = 1){
		_x += n;
		if (_x > _text.length)
			_x = cast(uint)_text.length;
	}

	/// does backspace at current cursor position
	void cursorBackspace(){
		if (_x == 0)
			return;
		if (_x < _text.length){
			foreach (i; _x .. _text.length)
				_text[i - 1] = _text[i];
		}
		if (_text.length)
			_text = _text[0 .. $ - 1];
		_x --;
	}

	/// does delete at current cursor position
	void cursorDelete(){
		if (_x >= _text.length)
			return;
		_text[_x .. $ - 1] = _text[_x + 1 .. $];
		_text.length --;
	}

	/// Writes a character at current cursor position
	void cursorInsert(dchar key){
		if (_x == _text.length)
			_text ~= key;
		else
			_text = _text[0 .. _x] ~ key ~ _text[_x .. $];
		cursorMoveRight;
	}

	/// Ensures cursor position is valid, if not, fixes it
	void cursorCorrect(){
		if (_x > _text.length)
			_x = cast(uint)text.length;
	}

	override bool activateEvent(bool isActive){
		if (!isActive)
			return false;
		cursorPos(_x, 0);
		update;
		return true;
	}

	override bool adoptEvent(bool adopted){
		if (!adopted)
			return false;
		resize;
		return true;
	}

	override bool resizeEvent(){
		update;
		return true;
	}

	override bool scrollEvent(){
		update;
		return true;
	}

	override bool mouseEvent(MouseEvent mouse){
		if (mouse.button != MouseEvent.Button.Left ||
				mouse.state != MouseEvent.State.Click)
			return false;
		_x = mouse.x;
		cursorCorrect;
		update;
		return true;
	}

	override bool keyboardEvent(KeyboardEvent key, bool cycle){
		if (cycle || key.key == '\n')
			return false;
		if (!key.isChar){
			switch (key.key){
				case Key.Delete:
					cursorDelete; break;
				case Key.LeftArrow:
					cursorMoveLeft; break;
				case Key.RightArrow:
					cursorMoveRight; break;
				default:
					break;
			}
		}else{
			switch (key.key){
				case '\b':
					cursorBackspace; break;
				default:
					cursorInsert(key.key);
			}
		}
		update;
		return true;
	}

	override bool updateEvent(){
		view.moveTo(view.x, view.y);
		if (view.x < _text.length)
			view.write(cast(dstring)_text[view.x .. $], _fg, _bg);
		view.fillLine(' ', _fg, _bg);
		cursorPos(_x, 0);
		return true;
	}
public:
	/// constructor
	this(dstring text = ""){
		this._text = cast(dchar[])text.dup;
		_maxHeight = 1;
	}

	/// text
	@property dstring text(){
		return cast(dstring)_text.dup;
	}
	/// ditto
	@property dstring text(dstring newText){
		_text = cast(dchar[])newText.dup;
		update;
		return cast(dstring)newText;
	}

	override @property bool wantsFocus() const {
		return true;
	}

	/// text color
	@property Color textColor(){
		return _fg;
	}
	/// ditto
	@property Color textColor(Color newColor){
		_fg = newColor;
		update;
		return _fg;
	}

	/// background color
	@property Color backColor(){
		return _bg;
	}
	/// ditto
	@property Color backColor(Color newColor){
		_bg = newColor;
		update;
		return _bg;
	}

	override @property uint minWidth(){
		return cast(uint)_text.length;
	}
	override @property uint maxHeight(){
		return 1;
	}
}

/// a Memo Widget, mutli line readonly text
class MemoWidget : QWidget{
private:
	/// text buffer
	dstring[] _lines;
	/// Colors
	Color _fg = Color.Default, _bg = Color.Default;

	/// updates minimum/maximum width/height based on _lines
	void _size(){
		uint w = uint.max;
		foreach (line; _lines)
			w = max(w, cast(uint)line.length);
		_minWidth = _maxWidth = w;
		_minHeight = _maxHeight = cast(uint)_lines.length;
	}

protected:
	override bool activateEvent(bool isActive){
		if (isActive)
			update;
		return true;
	}

	override bool adoptEvent(bool adopted){
		if (adopted)
			update;
		return true;
	}

	override bool resizeEvent(){
		update;
		return true;
	}

	override bool scrollEvent(){
		update;
		return true;
	}

	override bool mouseEvent(MouseEvent){
		// we dont do that here
		return false;
	}

	override bool keyboardEvent(KeyboardEvent, bool){
		// we dont do that here either
		return false;
	}

	override bool updateEvent(){
		uint vw = view.width, vh = view.height,
				 vx = view.x, vy = view.y;
		foreach (y; vy .. vy + vh){
			view.moveTo(vx, y);
			if (y >= _lines.length || _lines[y].length < vx){
				view.fillLine(' ', _fg, _bg);
				continue;
			}
			dstring line = _lines[y][vx .. $];
			view.write(line, _fg, _bg);
			if (line.length < vw)
				view.fillLine(' ', _fg, _bg);
			//cursorPos(-1, -1);
		}
		return true;
	}

public:
	/// constructor
	this(dstring[] buffer = null){
		_lines = buffer.dup;
		_size;
	}

	/// lines
	@property const(dstring[]) lines(){
		return _lines;
	}
	/// ditto
	@property const(dstring[]) lines(dstring[] newVal){
		_lines = newVal.dup;
		_size;
		update;
		return _lines;
	}

	/// text color
	@property Color textColor(){
		return _fg;
	}
	/// ditto
	@property Color textColor(Color newVal){
		return _fg = newVal;
	}

	/// background color
	@property Color backColor(){
		return _bg;
	}
	/// ditto
	@property Color backColor(Color newVal){
		return _bg = newVal;
	}
}

/// Displays an un-scrollable log
class LogWidget : QWidget{
private:
	/// stores the logs
	dstring[] _logs;
	/// The index in _logs where the oldest added line is
	uint _startIndex;
	/// the maximum number of logs to store
	uint _maxLogs;
	/// background and text color
	Color _bg, _fg;

	/// Returns: log at an index
	dstring log(uint index){
		if (index >= _logs.length)
			return "";
		return _logs[(index + _startIndex) % _maxLogs];
	}

	/// wrap a line, and modify str to exclude the first row
	/// Returns: the first row in wrapped lines
	dstring wrapLine(ref dstring str){
		dstring ret;
		if (str.length > width){
			ret = str[0 .. width];
			str = str[width + 1 .. $];
		}else{
			ret = str;
			str = null;
		}
		return ret;
	}

	/// Returns: height of a log (due to wrapping)
	uint logHeight(dstring str){
		if (!width)
			return 0;
		return cast(uint)(str.length + width - 1) / width;
	}
protected:
	override bool updateEvent(){
		if (!view.height || !view.width)
			return false;
		int y = view.height;
		for (int i = cast(int)_logs.length - 1; i >= 0 && y >= 0; i --){
			dstring line = _logs[i];
			immutable uint logHeight = logHeight(line);
			foreach (wrapI; y - logHeight .. y){
				dstring wrapped = wrapLine(line);
				if (wrapI < 0)
					continue;
				view.moveTo(0, wrapI);
				view.write(wrapped, _fg, _bg);
				view.fillLine(' ', textColor, backColor);
			}
			y -= logHeight;
		}
		foreach (i; 0 .. y){
			view.moveTo(0, i);
			view.fillLine(' ', _fg, _bg);
		}
		return true;
	}

	override bool resizeEvent(){
		update;
		return true;
	}

	override bool scrollEvent(){
		update;
		return true;
	}
public:
	/// constructor
	this(uint maxLogs = 100){
		_maxLogs = maxLogs;
		_startIndex = 0;
		_fg = Color.Default;
		_bg = Color.Default;
	}
	~this(){
		.destroy(_logs);
	}

	/// adds string to the log
	void add(dstring item){
		if (_logs.length > _maxLogs){
			_startIndex = (_startIndex + 1) % _maxLogs;
			_logs[_startIndex] = item;
		}else{
			_logs ~= item;
		}
		update;
	}
	/// ditto
	void add(string item){
		add(item.to!dstring);
	}

	/// clears the log
	void clear(){
		_logs.length = 0;
		_startIndex = 0;
		update;
	}

	/// text color
	@property Color textColor(){
		return _fg;
	}
	/// ditto
	@property Color textColor(Color newColor){
		_fg = newColor;
		update;
		return _fg;
	}
	/// background color
	@property Color backColor(){
		return _bg;
	}
	/// ditto
	@property Color backColor(Color newColor){
		_bg = newColor;
		update;
		return _bg;
	}
}

/// Just occupies some space. Use this to put space between widgets.
/// Allows you to set the color filled by its space
class SpacerWidget : QWidget{
private:
	Color _color;

protected:
	override bool resizeEvent(){
		update;
		return true;
	}

	override bool scrollEvent(){
		update;
		return true;
	}

	override bool updateEvent(){
		foreach (y; view.y .. view.y + view.height){
			view.moveTo(view.x, y);
			view.fillLine(' ', Color.Default, _color);
		}
		return true;
	}

public:
	/// constructor
	this(){
		_color = Color.Default;
	}

	/// color
	@property Color color(){
		return _color;
	}
	/// ditto
	@property Color color(Color newColor){
		_color = newColor;
		update;
		return _color;
	}
}
