/++
	Some widgets that are included in the package.
+/
module qui.widgets;

import qui.qui;
import utils.misc;
import utils.ds;

import std.conv : to;
debug import std.stdio;

/// for testing only.
class ScrollTestingWidget : QWidget{
protected:
	/// whether to display debug info
	bool _debugInfo;

	override bool adoptEvent(bool adopted){
		if (!adopted)
			return false;
		requestResize;
		return true;
	}

	override bool scrollEvent(){
		requestUpdate;
		return true;
	}

	override bool resizeEvent(){
		requestUpdate;
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
			Color textColor = Color.DEFAULT, Color backgroundColor = Color.DEFAULT){
		_debugInfo = debugInfo;
	}
}

/// Displays some text
///
/// doesnt handle new-line characters
class TextLabelWidget : QWidget{
private:
	/// text and background colors
	Color _fg = Color.DEFAULT, _bg = Color.DEFAULT;
	/// the text to display
	dstring _caption;
protected:

	override bool adoptEvent(bool adopted){
		if (!adopted)
			return false;
		requestResize;
		return true;
	}

	override bool scrollEvent(){
		requestUpdate;
		return true;
	}

	override bool resizeEvent(){
		requestUpdate;
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
		requestUpdate;
		return _caption;
	}

	/// text color
	@property Color textColor(){
		return _fg;
	}
	/// ditto
	@property Color textColor(Color newColor){
		_fg = newColor;
		requestUpdate;
		return _fg;
	}

	/// background color
	@property Color backColor(){
		return _bg;
	}
	/// ditto
	@property Color backColor(Color newColor){
		_bg = newColor;
		requestUpdate;
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
	Color _fg = Color.DEFAULT, _bg = Color.DEFAULT;

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
		if (_x < _text.length)
			_text[_x - 1 .. $ - 1] = _text[_x .. $];
		_text.length --;
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
	}

	/// Ensures cursor position is valid, if not, fixes it
	void cursorCorrect(){
		if (_x > _text.length)
			_x = cast(uint)text.length;
	}

	override bool adoptEvent(bool adopted){
		if (!adopted)
			return false;
		requestResize;
		return true;
	}

	override bool resizeEvent(){
		requestUpdate;
		return true;
	}

	override bool scrollEvent(){
		requestUpdate;
		return true;
	}

	override bool mouseEvent(MouseEvent mouse){
		if (mouse.button == MouseEvent.Button.Left &&
				mouse.state == MouseEvent.State.Click)
			_x = mouse.x;
		requestUpdate;
		return true;
	}

	override bool keyboardEvent(KeyboardEvent key, bool cycle){
		if (cycle || key.key == '\n')
			return false;
		switch (key.key){
			case '\b':
				cursorBackspace; break;
			case Key.Delete:
				cursorDelete; break;
			case Key.LeftArrow:
				cursorMoveLeft; break;
			case Key.RightArrow:
				cursorMoveRight; break;
			default:
				cursorInsert(key.key); break;
		}
		requestUpdate;
		return true;
	}

	override bool updateEvent(){
		view.moveTo(view.x, view.y);
		if (view.x > _text.length)
			view.fillLine(' ', _fg, _bg);
		else
			view.write(cast(dstring)_text[view.x .. $], _fg, _bg);
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
		requestUpdate;
		return cast(dstring)newText;
	}

	/// text color
	@property Color textColor(){
		return _fg;
	}
	/// ditto
	@property Color textColor(Color newColor){
		_fg = newColor;
		requestUpdate;
		return _fg;
	}

	/// background color
	@property Color backColor(){
		return _bg;
	}
	/// ditto
	@property Color backColor(Color newColor){
		_bg = newColor;
		requestUpdate;
		return _bg;
	}

	override @property uint minWidth(){
		return cast(uint)_text.length;
	}
	override @property uint maxWidth(){
		return cast(uint)_text.length;
	}
	override @property uint minHeight(){
		return 1;
	}
	override @property uint maxHeight(){
		return 1;
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
		requestUpdate;
		return true;
	}

	override bool scrollEvent(){
		requestUpdate;
		return true;
	}
public:
	/// constructor
	this(uint maxLogs = 100){
		_maxLogs = maxLogs;
		_startIndex = 0;
		_fg = Color.DEFAULT;
		_bg = Color.DEFAULT;
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
		requestUpdate;
	}
	/// ditto
	void add(string item){
		add(item.to!dstring);
	}

	/// clears the log
	void clear(){
		_logs.length = 0;
		_startIndex = 0;
		requestUpdate;
	}

	/// text color
	@property Color textColor(){
		return _fg;
	}
	/// ditto
	@property Color textColor(Color newColor){
		_fg = newColor;
		requestUpdate;
		return _fg;
	}
	/// background color
	@property Color backColor(){
		return _bg;
	}
	/// ditto
	@property Color backColor(Color newColor){
		_bg = newColor;
		requestUpdate;
		return _bg;
	}
}

/// Just occupies some space. Use this to put space between widgets.
/// Allows you to set the color filled by its space
class SplitterWidget : QWidget{
private:
	Color _color;

protected:
	override bool resizeEvent(){
		requestUpdate;
		return true;
	}

	override bool scrollEvent(){
		requestUpdate;
		return true;
	}

	override bool updateEvent(){
		foreach (y; view.y .. view.y + view.height){
			view.moveTo(view.x, y);
			view.fillLine(' ', Color.DEFAULT, _color);
		}
		return true;
	}

public:
	/// constructor
	this(){
		_color = Color.DEFAULT;
	}

	/// color
	@property Color color(){
		return _color;
	}
	/// ditto
	@property Color color(Color newColor){
		_color = newColor;
		requestUpdate;
		return _color;
	}
}
