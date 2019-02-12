/++
	Some widgets that are included in the package.
+/
module qui.widgets;

import qui.qui;
import qui.utils;
import utils.misc;
import utils.lists;

/// Displays some text
///
/// And it can't handle new-line characters
///
/// If the text doesn't fit in width, it will move left-right
class TextLabelWidget : QWidget{
private:
	/// number of chars not displayed on left
	uinteger xOffset = 0;
	/// max xOffset
	uinteger maxXOffset;
	/// the text to display
	string _caption;
	/// if in the last timerEvent, xOffset was increased
	bool increasedXOffset = true;

	/// whether this widget needs to update or not
	bool needsUpdate = true;

	/// calculates the maxXOffset, and changes xOffset if it's above it
	void calculateMaxXOffset(){
		if (_caption.length <= size.width){
			maxXOffset = 0;
			xOffset = 0;
		}else{
			maxXOffset = _caption.length - _size.width;
			if (xOffset > maxXOffset)
				xOffset = maxXOffset;
		}
	}
protected:
	override protected void timerEvent(){
		super.timerEvent;
		if (maxXOffset > 0){
			if (xOffset == maxXOffset){
				xOffset --;
				increasedXOffset = false;
			}else if (xOffset == 0){
				xOffset ++;
				increasedXOffset = true;
			}else if (increasedXOffset)
				xOffset ++;
			else
				xOffset --;
			// request update
			if (_termInterface)
				_termInterface.requestUpdate(this);
			needsUpdate = true;
		}
	}
	
	override protected void resizeEvent(Size size){
		super.resizeEvent(size);
		needsUpdate = true;
		calculateMaxXOffset;
	}
	
	override protected void update(bool force=false){
		if (needsUpdate || force){
			needsUpdate = false;
			_termInterface.write(cast(char[])_caption.scrollHorizontal(xOffset, _size.width), textColor, backgroundColor);
		}
	}

public:
	/// text and background colors
	Color textColor, backgroundColor;
	/// constructor
	this(string newCaption = ""){
		this.caption = newCaption;
		textColor = DEFAULT_FG;
		backgroundColor = DEFAULT_BG;
		this._size.maxHeight = 1;
	}

	/// the text to display
	@property string caption(){
		return _caption;
	}
	/// ditto
	@property string caption(string newCaption){
		_caption = newCaption;
		calculateMaxXOffset;
		// request update
		if (_termInterface)
			_termInterface.requestUpdate(this);
		needsUpdate = true;
		return _caption;
	}
}

/// Displays a left-to-right progress bar.
/// 
/// Can also display text (just like TextLabelWidget)
class ProgressbarWidget : TextLabelWidget{
private:
	uinteger _max, _progress;
protected:
	override protected void update(bool force=false){
		if (needsUpdate || force){
			needsUpdate = false;
			// if caption fits in width, center align it
			string text;
			if (_caption.length < _size.width)
				text = centerAlignText(_caption, _size.width);
			else
				text = _caption.scrollHorizontal(xOffset, _size.width);
			// number of chars to be colored in barColor
			uinteger fillCharCount = (_progress * _size.width) / _max;
			// line number on which the caption will be written
			uinteger captionLineNumber = this._size.height / 2;
			for (uinteger i = 0; i < this._size.height; i ++){
				if (i == captionLineNumber){
					_termInterface.write(cast(char[])text[0 .. fillCharCount], backgroundColor, barColor);
					_termInterface.write(cast(char[])text[fillCharCount .. text.length], barColor, backgroundColor);
				}else{
					if (fillCharCount)
						_termInterface.fillLine(' ', backgroundColor, barColor, fillCharCount+1);
					if (fillCharCount < this._size.width)
						_termInterface.fillLine(' ', barColor, backgroundColor);
				}
			}
			// write till _progress
			_termInterface.write(cast(char[])text[0 .. fillCharCount], backgroundColor, barColor);
			// write the empty bar
			_termInterface.write(cast(char[])text[fillCharCount .. text.length], barColor, backgroundColor);
		}
	}
public:
	/// background color, and bar's color
	Color backgroundColor, barColor;
	this(uinteger max = 100, uinteger progress = 0){
		_caption = null;
		this.max = max;
		this.progress = progress;
		// no max height limit on this one
		this._size.maxHeight = 0;

		barColor = DEFAULT_FG;
		backgroundColor = DEFAULT_BG;
	}
	/// The 'total', or the max-progress. getter
	@property uinteger max(){
		return _max;
	}
	/// The 'total' or the max-progress. setter
	@property uinteger max(uinteger newMax){
		_max = newMax;
		if (_termInterface)
			_termInterface.requestUpdate(this);
		needsUpdate = true;
		return _max;
	}
	/// the amount of progress. getter
	@property uinteger progress(){
		return _progress;
	}
	/// the amount of progress. setter
	@property uinteger progress(uinteger newProgress){
		_progress = newProgress;
		if (_termInterface)
			_termInterface.requestUpdate(this);
		needsUpdate = true;
		return _progress;
	}
}

/// To get single-line input from keyboard
class EditLineWidget : QWidget{
private:
	/// text that's been input-ed
	char[] _text;
	/// position of cursor
	uinteger _x;
	/// how many chars wont be displayed on left
	uinteger _scrollX;
	/// stores whether the widget needs update or not
	bool needsUpdate = true;

	/// called to fix _scrollX and _x when input is changed or _x is changed
	void reScroll(){
		adjustScrollingOffset(_x, _size.width, _text.length, _scrollX);
	}
protected:
	/// override resize to re-scroll
	override void resizeEvent(Size size){
		super.resizeEvent(size);
		needsUpdate = true;
		reScroll;
	}
	override void mouseEvent(MouseEvent mouse){
		super.mouseEvent(mouse);
		if (mouse.button == MouseEvent.Button.Left){
			_x = mouse.x + _scrollX;
		}
		needsUpdate = true;
		reScroll;
	}
	override void keyboardEvent(KeyboardEvent key){
		super.keyboardEvent(key);
		if (key.isChar){
			//insert that key
			if (key.charKey == '\b'){
				//backspace
				if (_x > 0){
					if (_x == _text.length){
						_text.length --;
					}else{
						_text = _text.deleteElement(_x-1);
					}
					_x --;
				}
			}else if (key.charKey != '\n'){
				if (_x == _text.length){
					//insert at end
					_text ~= cast(char)key.charKey;
				}else{
					_text = _text.insertElement([cast(char)key.charKey], _x);
				}
				_x ++;
			}
		}else{
			if (key.key == Key.arrowLeft && _x > 0){
				_x --;
			}else if (key.key == Key.arrowRight && _x < _text.length){
				_x ++;
			}else if (key.key == Key.del && _x < _text.length){
				_text = _text.deleteElement(_x);
			}
		}
		needsUpdate = true;
		reScroll;
	}
	override void update(bool force=false){
		if (needsUpdate || force){
			needsUpdate = false;
			_termInterface.write(this._text.scrollHorizontal(cast(integer)_scrollX, _size.width), textColor, backgroundColor);
			// set cursor position
			_termInterface.setCursorPos(this, _x - _scrollX, 0);
		}
	}
public:
	/// background, text, caption, and caption's background colors
	Color backgroundColor, textColor;
	this(string text = ""){
		this._text = cast(char[])text.dup;
		//specify min/max
		_size.minHeight = 1;
		_size.maxHeight = 1;
		// don't want tab key by default
		_wantsTab = false;
		// and input too, obvious
		_wantsInput = true;

		textColor = DEFAULT_FG;
		backgroundColor = DEFAULT_BG;
	}

	///The text that has been input-ed.
	@property string text(){
		return cast(string)_text.dup;
	}
	///The text that has been input-ed.
	@property string text(string newText){
		_text = cast(char[])newText.dup;
		// request update
		if (_termInterface)
			_termInterface.requestUpdate(this);
		return cast(string)newText;
	}
}

/// Can be used as a simple text editor, or to just display text
class MemoWidget : QWidget{
private:
	List!string _lines;
	/// how many characters/lines are skipped
	uinteger _scrollX, _scrollY;
	/// whether the cursor is, relative to line#0 character#0
	uinteger _cursorX, _cursorY;
	/// whether the text in it will be editable
	bool _enableEditing = true;
	/// whether the widget needs update or not
	bool needsUpdate = true;
	/// used by widget itself to recalculate scrolling
	void reScroll(){
		// _scrollY
		adjustScrollingOffset(_cursorY, this._size.height, _lines.length, _scrollY);
		// _scrollX
		adjustScrollingOffset(_cursorX, this._size.width, readLine(_cursorX).length, _scrollX);
	}
	/// used by widget itself to move cursor
	void moveCursor(uinteger x, uinteger y){
		_cursorX = x;
		_cursorY = y;
		
		if (_cursorY > lineCount)
			_cursorY = lineCount-1;
		if (_cursorX > readLine(_cursorY).length)
			_cursorX = readLine(_cursorY).length;
	}
	/// Reads a line from widgetLines
	string readLine(uinteger index){
		if (index >= _lines.length)
			return "";
		return _lines.read(index);
	}
	/// overwrites a line
	void overwriteLine(uinteger index, string line){
		if (index == _lines.length)
			_lines.append(line);
		else
			_lines.set(index,line);
		
	}
	/// deletes a line
	void removeLine(uinteger index){
		if (index < _lines.length)
			_lines.remove(index);
	}
	/// inserts a line
	void insertLine(uinteger index, string line){
		if (index == _lines.length)
			_lines.append(line);
		else
			_lines.insert(index, line);
	}
	/// adds a line
	void addLine(string line){
		_lines.append(line);
	}
	/// returns lines count
	@property uinteger lineCount(){
		return _lines.length+1;
	}
public:
	// background and text colors
	Color backgroundColor, textColor;
	this(bool editable = true){
		_lines = new List!string;
		_scrollX = 0;
		_scrollY = 0;
		_cursorX = 0;
		_cursorY = 0;
		_enableEditing = editable; //cause if readOnly, then writeProtected = true also

		if (_enableEditing)
			_wantsTab = true;
		// and input too, obviously
		_wantsInput = true;

		textColor = DEFAULT_FG;
		backgroundColor = DEFAULT_BG;
	}
	~this(){
		.destroy(_lines);
	}
	
	override void update(bool force=false){
		if (needsUpdate || force){
			needsUpdate = false;
			uinteger count = lineCount;
			if (count > 0){
				//write lines to memo
				for (uinteger i = _scrollY, end = count < this._size.height ? count : this._size.height; i < end; i++){
					_termInterface.write(cast(char[])readLine(i).scrollHorizontal(_scrollX, this._size.width), 
						textColor, backgroundColor);
				}
			}
			_termInterface.fill(' ', textColor, backgroundColor);
		}
		if (_enableEditing)
			_termInterface.setCursorPos(this, _cursorX - _scrollX, _cursorY - _scrollY);
	}
	
	override void mouseEvent(MouseEvent mouse){
		super.mouseEvent(mouse);
		//calculate mouse position, relative to scroll
		mouse.x = mouse.x + _scrollX;
		mouse.y = mouse.y + _scrollY;
		if (mouse.button == mouse.Button.Left){
			needsUpdate = true;
			moveCursor(mouse.x, mouse.y);
		}else if (mouse.button == mouse.Button.ScrollDown){
			if (_cursorY+1 < lineCount){
				needsUpdate = true;
				moveCursor(_cursorX, _cursorY + 4);
				reScroll();
			}
		}else if (mouse.button == mouse.Button.ScrollUp){
			if (_cursorY > 0){
				needsUpdate = true;
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
		super.keyboardEvent(key);
		if (key.isChar){
			if (_enableEditing){
				needsUpdate = true;
				string currentLine = readLine(_cursorY);
				//check if backspace
				if (key.charKey == '\b'){
					//make sure that it's not the first line, first line cannot be removed
					if (_cursorY > 0){
						//check if has to remove a '\n'
						if (_cursorX == 0){
							_cursorY --;
							//if line's not empty, append it to previous line
							_cursorX = readLine(_cursorY).length;
							if (currentLine != ""){
								//else, append this line to previous
								overwriteLine(_cursorY, readLine(_cursorY)~currentLine);
							}
							removeLine(_cursorY+1);
						}else{
							overwriteLine(_cursorY, cast(string)deleteElement(cast(char[])currentLine,_cursorX-1));
							_cursorX --;
						}
					}else if (_cursorX > 0){
						overwriteLine(_cursorY, cast(string)deleteElement(cast(char[])currentLine,_cursorX-1));
						_cursorX --;
					}
					
				}else if (key.charKey == '\n'){
					//insert a newline
					if (_cursorX == readLine(_cursorY).length){
						if (_cursorY >= lineCount - 1){
							_lines.append("");
						}else{
							insertLine(_cursorY + 1,"");
						}
					}else{
						string[2] line;
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
				}else if (key.charKey == '\t'){
					//convert it to 4 spaces
					overwriteLine(_cursorY, cast(string)insertElement(cast(char[])currentLine,cast(char[])"    ",_cursorX));
					_cursorX += 4;
				}else{
					//insert that char
					overwriteLine(_cursorY, cast(string)insertElement(cast(char[])currentLine,[cast(char)key.charKey],_cursorX));
					_cursorX ++;
				}
			}
		}else{
			if (key.key == Key.del && _enableEditing){
				needsUpdate = true;
				//check if is deleting \n
				if (_cursorX == readLine(_cursorY).length && _cursorY+1 < lineCount){
					//merge next line with this one
					char[] line = cast(char[])readLine(_cursorY)~readLine(_cursorY+1);
					overwriteLine(_cursorY, cast(string)line);
					//remove next line
					removeLine(_cursorY+1);
				}else if (_cursorX < readLine(_cursorY).length){
					char[] line = cast(char[])readLine(_cursorY);
					line = line.deleteElement(_cursorX);
					overwriteLine(_cursorY, cast(string)line);
				}
			}else if (key.key == Key.arrowDown){
				if (_cursorY+1 < lineCount){
					needsUpdate = true;
					_cursorY ++;
				}
			}else if (key.key == Key.arrowUp){
				if (_cursorY > 0){
					needsUpdate = true;
					_cursorY --;
				}
			}else if (key.key == Key.arrowLeft){
				if ((_cursorY >= 0 && _cursorX > 0) || (_cursorY > 0 && _cursorX == 0)){
					needsUpdate = true;
					if (_cursorX == 0){
						_cursorY --;
						_cursorX = readLine(_cursorY).length;
					}else{
						_cursorX --;
					}
				}
			}else if (key.key == Key.arrowRight){
				needsUpdate = true;
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
	
	///returns a list of lines in memo
	///
	///To modify the content, just modify it in the returned list
	///
	///class `List` is defined in `utils.lists.d`
	@property List!string lines(){
		return _lines;
	}
	///Returns true if memo's contents cannot be modified, by user
	@property bool editable(){
		return _enableEditing;
	}
	///sets whether to allow modifying of contents (false) or not (true)
	@property bool editable(bool newPermission){
		return _enableEditing = newPermission;
	}
}
/*
/// Displays an un-scrollable log, that removes older lines
/// 
/// It's content cannot be modified by user.
class LogWidget : QWidget{
private:
	LinkedList!string logs;
	
	uinteger max;

	
	uinteger stringLineCount(string s){
		uinteger width = widgetSize.width;
		uinteger i, widthTaken = 0, count = 1;
		for (i = 0; i < s.length; i++){
			widthTaken ++;
			if (s[i] == '\n' || widthTaken >= width){
				count ++;
				widthTaken = 0;
			}
			if (widthTaken >= width){
				count ++;
			}
		}
		return count;
	}
	string stripString(string s, uinteger height){
		char[] r;
		uinteger width = widgetSize.width;
		uinteger i, widthTaken = 0, count = 1;
		for (i = 0; i < s.length; i++){
			widthTaken ++;
			if (s[i] == '\n' || widthTaken >= width){
				count ++;
				widthTaken = 0;
			}
			if (count > height){
				r.length = i;
				r[0 .. i] = s[0 .. i];
				break;
			}
		}
		return cast(string)r;
	}
public:
	/// background and text color
	RGB backgroundColor, textColor;
	this(uinteger maxLen=100){
		max = maxLen;
		logs = new LinkedList!string;

		textColor = DEFAULT_TEXT_COLOR;
		backgroundColor = DEFAULT_BACK_COLOR;
	}
	~this(){
		logs.destroy;
	}
	
	override public bool update(Matrix display){
		bool r = false;
		if (needsUpdate){
			r = true;
			//get list of messages
			string[] messages = logs.toArray;
			//messages = messages.arrayReverse;
			//set colors
			display.setColors(textColor, backgroundColor);
			//determine how many of them will be displayed
			uinteger count;//right now, it's used to store number of lines used
			uinteger i;
			if (messages.length>0){
				for (i=messages.length-1; i>=0; i--){
					count += stringLineCount(messages[i]);
					if (count > widgetSize.height){
						messages = messages[i+1 .. messages.length];
						//try to insert part of the last message
						uinteger thisCount = stringLineCount(messages[i]);
						count -= thisCount;
						if (count < widgetSize.height){
							messages ~= [stripString(messages[i], widgetSize.height - count)];
						}
						break;
					}
					if (i==0){
						break;
					}
				}
			}
			//write them
			for (i = 0; i < messages.length; i++){
				display.write(cast(char[])messages[i], textColor, backgroundColor);
				//add newline
				display.moveTo(0, display.writePos.y+1);
			}
			needsUpdate = false;
		}
		return r;
	}
	
	///adds string to the log, and scrolls down to it
	void add(string item){
		//add height
		logs.append(item);
		//check if needs to remove older items
		if (logs.count > max){
			logs.removeFirst();
		}
		//update
		needsUpdate = true;
		// force an update
		termInterface.forceUpdate();
	}
	///clears the log
	void clear(){
		logs.clear;
		//update
		needsUpdate = true;
		// force an update
		termInterface.forceUpdate();
	}
}

/// A button
/// 
/// the caption is displayed inside the button
/// 
/// To receive input, set the `onMouseEvent` to set a custom mouse event
class ButtonWidget : QWidget{
public:
	/// background, and text color, in case it's not active
	RGB backgroundColor, textColor;
	/// background, and text color, in case it's activeWidget
	RGB activeBackgroundColor, activeTextColor;
	this(string caption=""){
		widgetCaption = caption;
		widgetWantsInput = true;

		textColor = DEFAULT_TEXT_COLOR;
		backgroundColor = DEFAULT_BACK_COLOR;

		activeTextColor = DEFAULT_TEXT_COLOR;
		activeBackgroundColor = DEFAULT_BACK_COLOR;
	}
	
	override public bool update(Matrix display){
		bool r = false;
		if (needsUpdate){
			char[] row;
			row.length = widgetSize.width;
			row[0 .. row.length] = ' ';
			//write the caption too!
			uinteger middle = widgetSize.height/2;
			// the colors to use now, background, and text
			RGB bgC, tC;
			if (termInterface.isActiveWidget(this)){
				bgC = activeBackgroundColor;
				tC = activeTextColor;
			}else{
				bgC = backgroundColor;
				tC = textColor;
			}
			for (uinteger i = 0; i < widgetSize.height; i++){
				if (i == middle && widgetCaption != ""){
					row = centerAlignText(cast(char[])caption, widgetSize.width);
					display.write(row, tC, bgC);
					row[0 .. row.length] = ' ';
					continue;
				}else{
					display.write(row, tC, bgC);
				}
			}
			r = true;
			needsUpdate = false;
		}
		return r;
	}

	override public void activateEvent(bool isActive){
		super.activateEvent(isActive);
		needsUpdate = true;
	}

	override void keyboardEvent(KeyPress key){
		super.keyboardEvent(key);
		mouseEvent(MouseClick(MouseClick.Button.Left, 0, 0));
	}
}*/