/++
	Some widgets that are included in the package.
+/
module qui.widgets;

import qui.qui;
import qui.utils;
import utils.misc;
import utils.ds;

import std.conv : to;

/// for testing only.
class ScrollTestingWidget : QWidget{
protected:
	/// text and background colors
	Color textColor, backgroundColor, emptyColor;
	/// whether to display debug info
	bool _debugInfo;

	override bool updateEvent(){
		foreach (y; viewportY .. viewportY + viewportHeight){
			moveTo(viewportX, y);
			foreach (x; viewportX .. viewportX + viewportWidth){
				write(((x+y) % 10).to!dstring[0], textColor,
					y < height && x < width ?
						backgroundColor : emptyColor);
			}
		}
		if (_debugInfo){
			moveTo(viewportX, viewportY);
			write("size, width x height:     " ~
				to!dstring(width) ~ "x" ~ to!dstring(height) ~ '|',
				DEFAULT_FG, DEFAULT_BG);
			moveTo(viewportX, viewportY+1);
			write("min size, width x height: " ~
				to!dstring(width) ~ "x" ~ to!dstring(height) ~ '|',
				DEFAULT_FG, DEFAULT_BG);
			moveTo(viewportX, viewportY+2);
			write("max size, width x height: " ~
				to!dstring(width) ~ "x" ~ to!dstring(height) ~ '|',
				DEFAULT_FG, DEFAULT_BG);
			moveTo(viewportX, viewportY+3);
			write("scroll X, Y: " ~
				to!dstring(scrollX) ~ "," ~ to!dstring(scrollY) ~ '|',
				DEFAULT_FG, DEFAULT_BG);
			moveTo(viewportX, viewportY+4);
			write("view X, Y: " ~
				to!dstring(viewportX) ~ "," ~ to!dstring(viewportY) ~
				'|', DEFAULT_FG, DEFAULT_BG);
			moveTo(viewportX, viewportY+5);
			write("view width x height: " ~
				to!dstring(viewportWidth) ~ "x" ~
				to!dstring(viewportHeight) ~ '|',
				DEFAULT_FG, DEFAULT_BG);
		}
		return true;
	}
public:
	/// constructor
	this(Color textColor = DEFAULT_FG,
			Color backgroundColor = DEFAULT_BG,
			Color emptyColor = Color.green, bool debugInfo=false){
		eventSubscribe(EventMask.Resize | EventMask.Scroll |
			EventMask.Update);
		this.textColor = textColor;
		this.backgroundColor = backgroundColor;
		this.emptyColor = emptyColor;
		this._debugInfo = debugInfo;
	}
}

/// Displays some text
///
/// doesnt handle new-line characters
class TextLabelWidget : QWidget{
private:
	/// text and background colors
	Color _fg = DEFAULT_FG, _bg = DEFAULT_BG;
	/// the text to display
	dstring _caption;
protected:
	override bool updateEvent(){
		moveTo(0,0);
		write(_caption, _fg, _bg);
		return true;
	}
public:
	/// constructor
	this(dstring caption = ""){
		eventSubscribe(EventMask.Resize | EventMask.Scroll |
			EventMask.Update);
		_caption = caption;
		height = 1;
		width = cast(uint)caption.length;
	}
	/// the text to display
	@property dstring caption(){
		return _caption;
	}
	/// ditto
	@property dstring caption(dstring newCaption){
		_caption = newCaption;
		width = cast(uint)newCaption.length;
		requestUpdate();
		return _caption;
	}
	/// text color
	@property Color textColor(){
		return _fg;
	}
	/// ditto
	@property Color textColor(Color newColor){
		_fg = newColor;
		requestUpdate();
		return _fg;
	}
	/// background color
	@property Color backColor(){
		return _bg;
	}
	/// ditto
	@property Color backColor(Color newColor){
		_bg = newColor;
		requestUpdate();
		return _bg;
	}
}

/// To get single-line input from keyboard
class EditLineWidget : QWidget{
private:
	/// text that's been input-ed
	dchar[] _text;
	/// position of cursor
	uint _x;
	/// Foreground and background colors
	Color _fg = DEFAULT_FG, _bg = DEFAULT_BG;
protected:
	/// override resize to re-scroll
	override bool resizeEvent(){
		requestUpdate();
		return true;
	}
	override bool mouseEvent(MouseEvent mouse){
		if (mouse.button == MouseEvent.Button.Left &&
		mouse.state == MouseEvent.State.Click)
			_x = mouse.x;
		requestUpdate();
		return true;
	}
	override bool keyboardEvent(KeyboardEvent key, bool cycle){
		if (cycle)
			return false;
		if (key.key == '\b'){ // backspace
			if (_x > 0){
				if (_x < _text.length)
					_text[_x - 1 .. $ - 1] = _text[_x .. $];
				_text.length --;
				_x --;
			}
		}else if (key.key == Key.Delete){ // delete
			if (_x < _text.length){
				_text[_x .. $ - 1] = _text[_x + 1 .. $];
				_text.length --;
			}
		}else if (key.key == Key.LeftArrow){ // <-
			_x = _x - (1 * (_x > 0));
		}else if (key.key == Key.RightArrow){ // ->
			_x = _x + (1 * (_x < _text.length));
		}else if (key.isChar && key.key != '\n'){ // insert character
			if (_x == _text.length)
				_text ~= key.key;
			else
				_text = _text[0 .. _x] ~ key.key ~ _text[_x .. $];
		}
		requestUpdate();
		return true;
	}
	override bool updateEvent(){
		moveTo(0,0);
		write(cast(dstring)_text, _fg, _bg);
		requestCursorPos(_x, 0);
		return true;
	}
public:
	/// constructor
	this(dstring text = ""){
		eventSubscribe(EventMask.Resize | EventMask.Scroll |
			EventMask.MousePress | EventMask.KeyboardPress |
			EventMask.Update);
		this._text = cast(dchar[])text.dup;
		height = 1;
	}

	///The text that has been input-ed.
	@property dstring text(){
		return cast(dstring)_text.dup;
	}
	///The text that has been input-ed.
	@property dstring text(dstring newText){
		_text = cast(dchar[])newText.dup;
		// request update
		requestUpdate();
		return cast(dstring)newText;
	}

	/// text color
	@property Color textColor(){
		return _fg;
	}
	/// ditto
	@property Color textColor(Color newColor){
		_fg = newColor;
		requestUpdate();
		return _fg;
	}

	/// background color
	@property Color backColor(){
		return _bg;
	}
	/// ditto
	@property Color backColor(Color newColor){
		_bg = newColor;
		requestUpdate();
		return _bg;
	}
}
/*
/// Can be used as a simple text editor, or to just display text
class MemoWidget : QWidget{
private:
	List!dstring _lines;
	/// how many characters/lines are skipped
	uint _scrollX, _scrollY;
	/// whether the cursor is, relative to line#0 character#0
	uint _cursorX, _cursorY;
	/// whether the text in it will be editable
	bool _enableEditing = true;
	/// used by widget itself to recalculate scrolling
	void reScroll(){
		// _scrollY
		adjustScrollingOffset(_cursorY, this.height, lineCount, _scrollY);
		// _scrollX
		adjustScrollingOffset(_cursorX, this.width, cast(uint)readLine(_cursorY).length, _scrollX);
	}
	/// used by widget itself to move cursor
	void moveCursor(uint x, uint y){
		_cursorX = x;
		_cursorY = y;
		
		if (_cursorY > lineCount)
			_cursorY = lineCount-1;
		if (_cursorX > readLine(_cursorY).length)
			_cursorX = cast(uint)readLine(_cursorY).length;
	}
	/// Reads a line from widgetLines
	dstring readLine(uint index){
		if (index >= _lines.length)
			return "";
		return _lines.read(index);
	}
	/// overwrites a line
	void overwriteLine(uint index, dstring line){
		if (index == _lines.length)
			_lines.append(line);
		else
			_lines.set(index,line);
		
	}
	/// deletes a line
	void removeLine(uint index){
		if (index < _lines.length)
			_lines.remove(index);
	}
	/// inserts a line
	void insertLine(uint index, dstring line){
		if (index == _lines.length)
			_lines.append(line);
		else
			_lines.insert(index, line);
	}
	/// adds a line
	void addLine(dstring line){
		_lines.append(line);
	}
	/// returns lines count
	@property uint lineCount(){
		return cast(uint)_lines.length+1;
	}
protected:
	override void updateEvent(){
		const uint count = lineCount;
		if (count > 0){
			//write lines to memo
			for (uint i = _scrollY; i < count && _display.cursor.y < this.height; i++){
				_display.write(readLine(i).scrollHorizontal(_scrollX, this.width), 
					textColor, backgroundColor);
			}
		}
		_display.fill(' ', textColor, backgroundColor);
		// cursor position, in case this is active
		_cursorPosition = Position(_cursorX - _scrollX, _cursorY - _scrollY);
	}

	override void resizeEvent(){
		requestUpdate();
		reScroll();
	}
	
	override void mouseEvent(MouseEvent mouse){
		//calculate mouse position, relative to scroll
		mouse.x = mouse.x + cast(int)_scrollX;
		mouse.y = mouse.y + cast(int)_scrollY;
		if (mouse.button == mouse.Button.Left){
			requestUpdate();
			moveCursor(mouse.x, mouse.y);
		}else if (mouse.button == mouse.Button.ScrollDown){
			if (_cursorY+1 < lineCount){
				requestUpdate();
				moveCursor(_cursorX, _cursorY + 4);
				reScroll();
			}
		}else if (mouse.button == mouse.Button.ScrollUp){
			if (_cursorY > 0){
				requestUpdate();
				if (_cursorY < 4){
					moveCursor(_cursorX, 0);
				}else{
					moveCursor(_cursorX, _cursorY - 4);
				}
				reScroll();
			}
		}
	}
	// too big of a mess to be dealt with right now, TODO try to make this shorter
	override void keyboardEvent(KeyboardEvent key){
		if (key.isChar){
			if (_enableEditing){
				requestUpdate();
				dstring currentLine = readLine(_cursorY);
				//check if backspace
				if (key.key == '\b'){
					//make sure that it's not the first line, first line cannot be removed
					if (_cursorY > 0){
						//check if has to remove a '\n'
						if (_cursorX == 0){
							_cursorY --;
							//if line's not empty, append it to previous line
							_cursorX = cast(uint)readLine(_cursorY).length;
							if (currentLine != ""){
								//else, append this line to previous
								overwriteLine(_cursorY, readLine(_cursorY)~currentLine);
							}
							removeLine(_cursorY+1);
						}else{
							overwriteLine(_cursorY, cast(dstring)deleteElement(cast(dchar[])currentLine,_cursorX-1));
							_cursorX --;
						}
					}else if (_cursorX > 0){
						overwriteLine(_cursorY, cast(dstring)deleteElement(cast(dchar[])currentLine,_cursorX-1));
						_cursorX --;
					}
					
				}else if (key.key == '\n'){
					//insert a newline
					if (_cursorX == readLine(_cursorY).length){
						if (_cursorY >= lineCount - 1){
							_lines.append("");
						}else{
							insertLine(_cursorY + 1,"");
						}
					}else{
						dstring[2] line;
						line[0] = readLine(_cursorY);
						line[1] = line[0][_cursorX .. line[0].length];
						line[0] = line[0][0 .. _cursorX];
						overwriteLine(_cursorY, line[0]);
						if (_cursorY >= lineCount - 1){
							_lines.append(line[1]);
						}else{
							insertLine(_cursorY + 1, line[1]);
						}
					}
					_cursorY ++;
					_cursorX = 0;
				}else if (key.key == '\t'){
					//convert it to 4 spaces
					overwriteLine(_cursorY, cast(dstring)insertElement(cast(dchar[])currentLine,cast(dchar[])"    ",_cursorX));
					_cursorX += 4;
				}else{
					//insert that char
					overwriteLine(_cursorY, cast(dstring)insertElement(cast(dchar[])currentLine,[cast(dchar)key.key],_cursorX));
					_cursorX ++;
				}
			}
		}else{
			if (key.key == Key.Delete && _enableEditing){
				requestUpdate();
				//check if is deleting \n
				if (_cursorX == readLine(_cursorY).length && _cursorY+1 < lineCount){
					//merge next line with this one
					dchar[] line = cast(dchar[])readLine(_cursorY)~readLine(_cursorY+1);
					overwriteLine(_cursorY, cast(dstring)line);
					//remove next line
					removeLine(_cursorY+1);
				}else if (_cursorX < readLine(_cursorY).length){
					dchar[] line = cast(dchar[])readLine(_cursorY);
					line = line.deleteElement(_cursorX);
					overwriteLine(_cursorY, cast(dstring)line);
				}
			}else if (key.key == Key.DownArrow){
				if (_cursorY+1 < lineCount){
					requestUpdate();
					_cursorY ++;
				}
			}else if (key.key == Key.UpArrow){
				if (_cursorY > 0){
					requestUpdate();
					_cursorY --;
				}
			}else if (key.key == Key.LeftArrow){
				if ((_cursorY >= 0 && _cursorX > 0) || (_cursorY > 0 && _cursorX == 0)){
					requestUpdate();
					if (_cursorX == 0){
						_cursorY --;
						_cursorX = cast(uint)readLine(_cursorY).length;
					}else{
						_cursorX --;
					}
				}
			}else if (key.key == Key.RightArrow){
				requestUpdate();
				if (_cursorX == readLine(_cursorY).length){
					if (_cursorY+1 < lineCount){
						_cursorX = 0;
						_cursorY ++;
						_scrollX = 0;
					}
				}else{
					_cursorX ++;
				}
			}
		}
		// I'll use this this time not to move the cursor, but to fix the cursor position
		moveCursor(_cursorX,_cursorY);
		reScroll();
	}
public:
	/// background and text colors
	Color backgroundColor, textColor;
	/// constructor
	this(bool allowEditing = true){
		_lines = new List!dstring;
		_scrollX = 0;
		_scrollY = 0;
		_cursorX = 0;
		_cursorY = 0;
		eventSubscribe(EventMask.Initialize | EventMask.MouseAll | EventMask.KeyboardPress |
		EventMask.Resize | EventMask.Update);

		textColor = DEFAULT_FG;
		backgroundColor = DEFAULT_BG;
	}
	~this(){
		.destroy(_lines);
	}
	
	///returns a list of lines in memo
	///
	///To modify the content, just modify it in the returned list
	///
	///class `List` is defined in `utils.lists.d`
	@property List!dstring lines(){
		return _lines;
	}
}*/

/// Displays an un-scrollable log
class LogWidget : QWidget{
private:
	/// stores the logs
	List!dstring _logs;
	/// The index in _logs where the oldest added line is
	uint _startIndex;
	/// the maximum number of lines to store
	uint _maxLines;
	/// Returns: line at an index
	dstring getLine(uint index){
		if (index >= _logs.length)
			return "";
		return _logs.read((index + _startIndex) % _maxLines);
	}
	/// wrap a line
	dstring[] wrapLine(dstring str){
		dstring[] r;
		while (str.length > 0){
			if (width > str.length){
				r ~= str;
				str = [];
			}else{
				r ~= str[0 .. width];
				str = str[width .. $];
			}
		}
		return r;
	}
protected:
	override bool updateEvent(){
		int hLeft = this.height;
		for (int i = cast(int)_logs.length-1; i >= 0; i --){
			dstring line = getLine(i);
			if (!line.length)
				continue;
			dstring[] wrappedLine = wrapLine(line);
			if (hLeft < wrappedLine.length)
				wrappedLine = wrappedLine[wrappedLine.length - hLeft .. $];
			immutable int startY = hLeft - cast(int)wrappedLine.length;
			foreach (lineno, currentLine; wrappedLine){
				moveTo(0, cast(int)lineno + startY);
				write(currentLine, textColor, backgroundColor);
				if (currentLine.length < width)
					fillLine(' ', textColor, backgroundColor);
			}
			hLeft = startY;
		}
		foreach (y; 0 .. hLeft){
			moveTo(0, y);
			fillLine(' ', textColor, backgroundColor);
		}
		return true;
	}
	
	override bool resizeEvent() {
		requestUpdate();
		return true;
	}
public:
	/// background and text color
	Color backgroundColor, textColor;
	/// constructor
	this(uint maxLen = 100){
		_maxLines = maxLen;
		_logs = new List!dstring;
		_startIndex = 0;
		eventSubscribe(EventMask.Resize | EventMask.Update);
		textColor = DEFAULT_FG;
		backgroundColor = DEFAULT_BG;
	}
	~this(){
		.destroy(_logs);
	}
	
	/// adds string to the log, and scrolls down to it.
	/// newline character is not allowed
	void add(dstring item){
		//check if needs to overwrite
		if (_logs.length > _maxLines){
			_startIndex = (_startIndex + 1) % _maxLines;
			_logs.set(_startIndex, item);
		}else
			_logs.append(item);
		requestUpdate();
	}
	/// ditto
	void add(string item){
		add(item.to!dstring);
	}

	/// clears the log
	void clear(){
		_logs.clear;
		requestUpdate();
	}
}

/// Just occupies some space. Use this to put space between widgets
class SplitterWidget : QWidget{
private:
	Color _color;
protected:
	override bool updateEvent(){
		foreach (y; viewportY .. viewportY + viewportHeight){
			moveTo(viewportX, y);
			fillLine(' ', DEFAULT_FG, _color);
		}
		return true;
	}
public:
	/// constructor
	this(){
		_color = DEFAULT_BG;
		eventSubscribe(EventMask.Scroll | EventMask.Resize |
			EventMask.Update);
	}
	/// color
	@property Color color(){
		return _color;
	}
	/// ditto
	@property Color color(Color newColor){
		_color = newColor;
		requestUpdate();
		return _color;
	}
}
