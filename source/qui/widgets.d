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
	
	override protected void update(){
		if (needsUpdate){
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
	override protected void update(){
		if (needsUpdate){
			needsUpdate = false;
			// if caption fits in width, center align it
			string text;
			if (_caption.length < _size.width)
				text = centerAlignText(_caption, _size.width);
			else
				text = _caption.scrollHorizontal(xOffset, _size.width);
			// number of chars to be colored in barColor
			uinteger fillCharCount = (_progress * _size.width) / _max;
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

	/// called to fix _scrollX and _x when input is changed or _x is changed
	void reScroll(){
		adjustScrollingOffset(_x, _size.width, _scrollX);
	}
protected:
	/// override resize to re-scroll
	override void resizeEvent(Size size){
		super.resizeEvent(size);
		reScroll;
	}
	override void mouseEvent(MouseEvent mouse){
		super.mouseEvent(mouse);
		if (mouse.button == MouseEvent.Button.Left){
			_x = mouse.x + _scrollX;
		}
		reScroll;
	}
	override void keyboardEvent(KeyboardEvent key){
		super.keyboardEvent(key);
		if (key.isChar){
			//insert that key
			if (key.key == '\b'){
				//backspace
				if (_x > 0){
					if (_x == _text.length){
						_text.length --;
					}else{
						_text = _text.deleteElement(_x-1);
					}
					_x --;
				}
			}else if (key.key != '\n'){
				if (_x == _text.length){
					//insert at end
					_text ~= cast(char)key.key;
				}else{
					_text = _text.insertElement([cast(char)key.key], _x);
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
		reScroll;
	}
	override void update(){
		_termInterface.write(cast(char[])(cast(string)this._text).scrollHorizontal(cast(integer)_scrollX, _size.width), textColor, backgroundColor);
		// set cursor position
		_termInterface.setCursorPos(this, _x - _scrollX, 0);
	}
public:
	/// background, text, caption, and caption's background colors
	Color backgroundColor, textColor;
	this(string text = ""){
		this.text = text;
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
/*
/// Can be used as a simple text editor, or to just display text
class MemoWidget : QWidget{
private:
	List!string widgetLines;
	uinteger scrollX, scrollY;
	uinteger cursorX, cursorY;
	bool writeProtected = false;
	// used by widget itseld to recalculate scrolling
	void reScroll(){
		//calculate scrollY first
		scrollY = 0;
		// scrollY + widgetSize.height  -->  last visible line+1
		if (cursorY >= scrollY + widgetSize.height || cursorY < scrollY){
			scrollY = (cursorY - widgetSize.height) + 1;
		}
		//now time for scrollX
		//check if is within length of line
		uinteger len = readLine(cursorY).length;
		if (cursorX > len){
			cursorX = len;
		}
		//now calculate scrollX, if it needs to be increased
		if (scrollX + widgetSize.width < cursorX || scrollX + widgetSize.width >= cursorX){
			if (cursorX < widgetSize.width){
				scrollX = 0;
			}else{
				scrollX = cursorX - widgetSize.width;
			}
		}
	}
	// used by widget itself to set cursor
	void setCursor(){
		termInterface.setCursorPos(
			Position(
				cursorX - scrollX, // x
				cursorY - scrollY //  y
				),
			this);
	}
	// used by widget itself to move cursor
	void moveCursor(uinteger x, uinteger y){
		cursorX = x;
		cursorY = y;
		
		if (cursorY > lineCount){
			cursorY = lineCount-1;
		}
		if (cursorX > readLine(cursorY).length){
			cursorX = readLine(cursorY).length;
		}
	}
	/// Reads a line from widgetLines
	string readLine(uinteger index){
		if (index == widgetLines.length){
			return "";
		}
		return widgetLines.read(index);
	}
	/// overwrites a line
	void overwriteLine(uinteger index, string line){
		if (index == widgetLines.length){
			widgetLines.add(line);
		}else{
			widgetLines.set(index,line);
		}
	}
	/// deletes a line
	void removeLine(uinteger index){
		if (index < widgetLines.length){
			widgetLines.remove(index);
		}
	}
	/// inserts a line
	void insertLine(uinteger index, string line){
		if (index == widgetLines.length){
			widgetLines.add(line);
		}else{
			widgetLines.insert(index, line);
		}
	}
	/// adds a line
	void addLine(string line){
		widgetLines.add(line);
	}
	/// returns lines count
	@property uinteger lineCount(){
		return widgetLines.length+1;
	}
public:
	// background and text colors
	RGB backgroundColor, textColor;
	this(bool readOnly = false){
		widgetLines = new List!string;
		scrollX = 0;
		scrollY = 0;
		cursorX = 0;
		cursorY = 0;
		writeProtected = readOnly;//cause if readOnly, then writeProtected = true also

		// this widget wants Tab key
		widgetWantsTab = true;
		// and input too, obviously
		widgetWantsInput = true;
		// and the cursor should be visible
		widgetShowCursor = true;

		textColor = DEFAULT_TEXT_COLOR;
		backgroundColor = DEFAULT_BACK_COLOR;
	}
	~this(){
		.destroy(widgetLines);
	}
	
	override bool update(Matrix display){
		bool r = false;
		if (needsUpdate){
			r = true;
			//check if there's lines to be displayed
			uinteger count = lineCount;
			if (count > 0){
				//write lines to memo
				char[] line;
				for (uinteger i = scrollY; i < count; i++){
					//echo current line
					line = cast(char[])readLine(i);
					//fit the line into screen, i.e check if only a part of it will be displayed
					if (line.length >= widgetSize.width+scrollX){
						//display only partial line
						display.write(line[scrollX .. scrollX + widgetSize.width], textColor, backgroundColor);
					}else{
						//either the line is small enough to fit, or 0-length
						if (line.length <= scrollX || line.length == 0){
							//just write the bgColor
							display.fillLine(' ', textColor, backgroundColor);
						}else{
							display.write(line[scrollX .. line.length], textColor, backgroundColor);
							//write the bgColor
							display.fillLine(' ',textColor,backgroundColor);
						}
					}
					//check if is at end
					if (i-scrollY >= widgetSize.height){
						break;
					}
				}
				//fill empty space with emptyLine
				display.fillMatrix(' ',textColor,backgroundColor);
			}
			needsUpdate = false;
		}
		setCursor();
		return r;
	}
	
	override void mouseEvent(MouseClick mouse){
		super.mouseEvent(mouse);
		//calculate mouse position, relative to scroll
		mouse.x = mouse.x + scrollX;
		mouse.y = mouse.y + scrollY;
		if (mouse.mouseButton == mouse.Button.Left){
			needsUpdate = true;
			moveCursor(mouse.x, mouse.y);
		}else if (mouse.mouseButton == mouse.Button.ScrollDown){
			if (cursorY+1 < lineCount){
				needsUpdate = true;
				moveCursor(cursorX, cursorY + 4);
				reScroll();
			}
		}else if (mouse.mouseButton == mouse.Button.ScrollUp){
			if (cursorY > 0){
				needsUpdate = true;
				if (cursorY < 4){
					moveCursor(cursorX, 0);
				}else{
					moveCursor(cursorX, cursorY - 4);
				}
				reScroll();
			}
		}
	}
	
	override void keyboardEvent(KeyPress key){
		super.keyboardEvent(key);
		if (key.isChar){
			if (!writeProtected){
				needsUpdate = true;
				string currentLine = readLine(cursorY);
				//check if backspace
				if (key.key == '\b'){
					//make sure that it's not the first line, first line cannot be removed
					if (cursorY > 0){
						//check if has to remove a '\n'
						if (cursorX == 0){
							cursorY --;
							//if line's not empty, append it to previous line
							cursorX = readLine(cursorY).length;
							if (currentLine != ""){
								//else, append this line to previous
								overwriteLine(cursorY, readLine(cursorY)~currentLine);
							}
							removeLine(cursorY+1);
						}else{
							overwriteLine(cursorY, cast(string)deleteElement(cast(char[])currentLine,cursorX-1));
							cursorX --;
						}
					}else if (cursorX > 0){
						overwriteLine(cursorY, cast(string)deleteElement(cast(char[])currentLine,cursorX-1));
						cursorX --;
					}
					
				}else if (key.key == '\n'){
					//insert a newline
					//if is at end, just add it
					bool atEnd = false;
					if (cursorY >= lineCount - 1){
						atEnd = true;
					}
					if (cursorX == readLine(cursorY).length){
						if (atEnd){
							widgetLines.add("");
						}else{
							insertLine(cursorY + 1,"");
						}
					}else{
						string[2] line;
						line[0] = readLine(cursorY);
						line[1] = line[0][cursorX .. line[0].length];
						line[0] = line[0][0 .. cursorX];
						overwriteLine(cursorY, line[0]);
						if (atEnd){
							widgetLines.add(line[1]);
						}else{
							insertLine(cursorY + 1, line[1]);
						}
					}
					cursorY ++;
					cursorX = 0;
				}else if (key.key == '\t'){
					//convert it to 4 spaces
					overwriteLine(cursorY, cast(string)insertElement(cast(char[])currentLine,cast(char[])"    ",cursorX));
					cursorX += 4;
				}else{
					//insert that char
					overwriteLine(cursorY, cast(string)insertElement(cast(char[])currentLine,[cast(char)key.key],cursorX));
					cursorX ++;
				}
			}
		}else{
			if (key.key == key.NonCharKey.Delete){
				needsUpdate = true;
				//check if is deleting \n
				if (cursorX == readLine(cursorY).length && cursorY+1 < lineCount){
					//merge next line with this one
					char[] line = cast(char[])readLine(cursorY)~readLine(cursorY+1);
					overwriteLine(cursorY, cast(string)line);
					//remove next line
					removeLine(cursorY+1);
				}else if (cursorX < readLine(cursorY).length){
					char[] line = cast(char[])readLine(cursorY);
					line = line.deleteElement(cursorX);
					overwriteLine(cursorY, cast(string)line);
				}
			}else if (key.key == key.NonCharKey.DownArrow){
				if (cursorY+1 < lineCount){
					needsUpdate = true;
					cursorY ++;
				}
			}else if (key.key == key.NonCharKey.UpArrow){
				if (cursorY > 0){
					needsUpdate = true;
					cursorY --;
				}
			}else if (key.key == key.NonCharKey.LeftArrow){
				if ((cursorY >= 0 && cursorX > 0) || (cursorY > 0 && cursorX == 0)){
					needsUpdate = true;
					if (cursorX == 0){
						cursorY --;
						cursorX = readLine(cursorY).length;
					}else{
						cursorX --;
					}
				}
			}else if (key.key == key.NonCharKey.RightArrow){
				needsUpdate = true;
				if (cursorX == readLine(cursorY).length){
					if (cursorY+1 < lineCount){
						cursorX = 0;
						cursorY ++;
						scrollX = 0;
					}
				}else{
					cursorX ++;
				}
			}
		}
		// I'll use this this time not to move the cursor, but to fix the cursor position
		moveCursor(cursorX,cursorY);
		reScroll();
	}
	
	///returns a list of lines in memo
	///
	///To modify the content, just modify it in the returned list
	///
	///class `List` is defined in `utils.lists.d`
	@property List!string lines(){
		return widgetLines;
	}
	///Returns true if memo's contents cannot be modified, by user
	@property bool readOnly(){
		return writeProtected;
	}
	///sets whether to allow modifying of contents (false) or not (true)
	@property bool readOnly(bool newPermission){
		writeProtected = newPermission;
		// force an update
		termInterface.forceUpdate();
		return writeProtected;
	}
}

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