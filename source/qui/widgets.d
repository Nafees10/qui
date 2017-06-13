/++
	Some widgets that are included in the package.
	
	
+/
module qui.widgets;

import qui.qui;
import utils.misc;
import utils.lists;

///Displays some text
///
///And it can't handle new-line characters
///
///Name in theme: 'text-label';
class TextLabelWidget : QWidget{
private:
	RGBColor textColor, bgColor;
public:
	this(string wCaption = ""){
		widgetName = "text-label";
		widgetCaption = wCaption;
	}

	override void updateColors(){
		if (&widgetTheme && widgetTheme.hasColors(name,["background","text"])){
			textColor = widgetTheme.getColor(name, "text");
			bgColor = widgetTheme.getColor(name, "background");
		}else{
			//use default values
			textColor = hexToColor("00FF00");
			bgColor = hexToColor("000000");
		}
	}

	override bool update(ref Matrix display){
		if (needsUpdate){
			needsUpdate = false;
			//redraw text
			display.write(cast(char[])widgetCaption, textColor, bgColor);
			return true;
		}else{
			return false;
		}
	}
}

/// Displays a left-to-right progress bar.
/// 
/// If caption is set, it is displayed in the middle of the widget
/// 
/// Name in theme: 'progressbar';
class ProgressbarWidget : QWidget{
private:
	uinteger max, done;
	RGBColor bgColor, barColor, textColor;
	void writeBarLine(ref Matrix display, uinteger filled, char[] bar){
		display.write(bar[0 .. filled], textColor, barColor);
		display.write(bar[filled .. bar.length], textColor, bgColor);
	}
public:
	this(uinteger totalAmount = 100, uinteger complete = 0){
		widgetName = "progressbar";
		widgetCaption = null;
		max = totalAmount;
		done = complete;
	}

	override void updateColors(){
		needsUpdate = true;
		if (&widgetTheme && widgetTheme.hasColors(name, ["background", "bar", "text"])){
			bgColor = widgetTheme.getColor(name, "background");
			barColor = widgetTheme.getColor(name, "bar");
			textColor = widgetTheme.getColor(name, "text");
		}else{
			bgColor = hexToColor("A6A6A6");
			barColor = hexToColor("00FF00");
			textColor = hexToColor("000000");
		}
		if (forceUpdate !is null){
			forceUpdate();
		}
	}

	override bool update(ref Matrix display){
		bool r = false;
		if (needsUpdate){
			needsUpdate = false;
			r = true;
			uinteger filled = ratioToRaw(done, max, widgetSize.width);
			char[] bar;
			bar.length = widgetSize.width;
			bar[0 .. bar.length] = ' ';
			if (widgetCaption != null){
				//write the caption too!
				uinteger middle = widgetSize.height/2;
				for (uinteger i = 0; i < widgetSize.height; i++){
					if (i == middle){
						bar = centerAlignText(cast(char[])caption, widgetSize.width);
						writeBarLine(display, filled, bar);
						bar[0 .. bar.length] = ' ';
						continue;
					}else{
						writeBarLine(display, filled, bar);
					}
				}
			}else{
				for (uinteger i = 0; i < widgetSize.height; i++){
					writeBarLine(display, filled, bar);
				}
			}
		}
		return r;
	}
	/// The 'total', or the max-progress. getter
	@property uinteger total(){
		return max;
	}
	/// The 'total' or the max-progress. setter
	@property uinteger total(uinteger newTotal){
		needsUpdate = true;
		max = newTotal;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return max;
	}
	/// the amount of progress. getter
	@property uinteger progress(){
		return done;
	}
	/// the amount of progress. setter
	@property uinteger progress(uinteger newProgress){
		needsUpdate = true;
		done = newProgress;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return done;
	}
}

/// To get single-line input from keyboard
/// 
/// Name in theme: 'editline';
class EditLineWidget : QWidget{
private:
	char[] inputText;
	uinteger cursorX;
	uinteger scrollX = 0;//amount of chars that won't be displayed because of not enough space
	RGBColor bgColor, textColor, captionTextColor, captionBgColor;
public:
	this(string wCaption = "", string inputTxt = ""){
		widgetName = "editLine";
		inputText = cast(char[])inputTxt;
		widgetCaption = wCaption;
		//specify min/max
		widgetSize.minWidth = 1;
		widgetSize.minHeight = 1;
		widgetSize.maxHeight = 1;
	}
	override void updateColors(){
		needsUpdate = true;
		if (&widgetTheme && widgetTheme.hasColors(name, ["background", "caption-text", "text"])){
			bgColor = widgetTheme.getColor(name, "background");
			textColor = widgetTheme.getColor(name, "text");
			captionTextColor = widgetTheme.getColor(name, "captionText");
			captionBgColor = widgetTheme.getColor(name, "captionBackground");
		}else{
			bgColor = hexToColor("404040");
			textColor = hexToColor("00FF00");
			captionTextColor = textColor;
			captionBgColor = hexToColor("000000");
		}
		if (forceUpdate !is null){
			forceUpdate();
		}
	}
	override bool update(ref Matrix display){
		bool r = false;
		if (needsUpdate){
			needsUpdate = false;
			r = true;
			//make sure there's enough space
			if (display.width > widgetCaption.length){
				//draw the caption
				display.write(cast(char[])widgetCaption, captionTextColor, captionBgColor);
				//draw the inputText
				uinteger width = display.width - widgetCaption.length;
				if (width >= inputText.length){
					//draw it as it is
					display.write(inputText, textColor, bgColor);
				}else{
					//draw scrolled
					if (scrollX + width > inputText.length){
						display.write(inputText[scrollX .. inputText.length], textColor, bgColor);
					}else{
						display.write(inputText[scrollX .. scrollX + width], textColor, bgColor);
					}
				}
				//fill the left with bgColor
				if (widgetCaption.length + inputText.length < widgetSize.width){
					char[] tmp;
					tmp.length = widgetSize.width - (inputText.length + widgetCaption.length);
					tmp[0 .. tmp.length] = ' ';
					display.write(tmp, textColor, bgColor);
				}
				//set cursor pos, if can
				if (cursorPos !is null){
					cursorPos(widgetPosition.x + widgetCaption.length + (cursorX - scrollX), widgetPosition.y);
				}
			}else{
				widgetShow = false;
				r = false;
			}
		}
		return r;
	}

	override void mouseEvent(MouseClick mouse){
		super.mouseEvent(mouse);
		if (mouse.mouseButton == mouse.Button.Left){
			needsUpdate = true;
			//move cursor to that pos
			uinteger tmp = widgetPosition.x + widgetCaption.length;
			if (mouse.x > tmp && mouse.x < tmp + inputText.length){
				cursorX = mouse.x - (widgetPosition.x + widgetCaption.length + scrollX);
			}
		}
	}
	override void keyboardEvent(KeyPress key){
		super.keyboardEvent(key);
		if (key.isChar){
			needsUpdate = true;
			//insert that key
			if (key.key != '\b' && key.key != '\n'){
				if (cursorX == inputText.length){
					//insert at end
					inputText ~= cast(char)key.key;
				}else{
					inputText = inputText.insertElement([cast(char)key.key], cursorX);
				}
				cursorX ++;
			}else if (key.key == '\b'){
				//backspace
				if (cursorX > 0){
					if (cursorX == inputText.length){
						inputText.length --;
					}else{
						inputText = inputText.deleteElement(cursorX-1);
					}
					cursorX --;
				}
			}
			//check if has to modify scrollX
			if (widgetSize.width < widgetCaption.length + inputText.length){
				scrollX = (widgetCaption.length + inputText.length) - widgetSize.width;
			}else if (scrollX > 0){
				scrollX = 0;
			}
		}else{
			if (key.key == key.NonCharKey.LeftArrow || key.key == key.NonCharKey.UpArrow){
				if (cursorX > 0){
					needsUpdate = true;
					cursorX --;
					if (scrollX > cursorX){
						scrollX = cursorX;
					}
				}
			}else if (key.key == key.NonCharKey.RightArrow || key.key == key.NonCharKey.DownArrow){
				if (cursorX < inputText.length){
					needsUpdate = true;
					cursorX ++;
					if (cursorX == widgetSize.width - widgetCaption.length && inputText.length > cursorX){
						scrollX = inputText.length - (widgetSize.width - widgetCaption.length);
					}
				}
			}
		}
		//set cursor pos, if can
		if (cursorPos !is null){
			cursorPos(widgetPosition.x + widgetCaption.length + (cursorX - scrollX), widgetPosition.y);
		}
	}
	///The text that has been input-ed.
	@property string text(){
		return cast(string)inputText;
	}
	///The text that has been input-ed.
	@property string text(string newText){
		inputText = cast(char[])newText;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return cast(string)inputText;
	}
}

/// Can be used as a simple text editor, or to just display text
/// 
/// Name in theme: 'memo';
class MemoWidget : QWidget{
private:
	List!string widgetLines;
	uinteger scrollX, scrollY;
	uinteger cursorX, cursorY;
	RGBColor bgColor, textColor;
	bool writeProtected = false;
	// used by widget itseld to recalculate scrolling
	void reScroll(){
		//calculate scrollY first
		if ((scrollY + widgetSize.height < cursorY || scrollY + widgetSize.height >= cursorY) && cursorY != 0){
			if (cursorY <= widgetSize.height/2){
				scrollY = 0;
			}else{
				scrollY = cursorY - (widgetSize.height/2);
			}
		}
		//now time for scrollX
		//check if is within length of line
		uinteger len = widgetLines.read(cursorY).length;
		if (cursorX > len){
			cursorX = len;
		}
		//now calculate scrollX, if it needs to be increased
		if (/*cursorX > widgetSize.width &&*/(scrollX + widgetSize.width < cursorX || scrollX + widgetSize.width >= cursorX)){
			if (cursorX <= widgetSize.width/2){
				scrollX = 0;
			}else{
				scrollX = cursorX - (widgetSize.width/2);
			}
		}
	}
	// used by widget itself to set cursor
	void setCursor(){
		//put the cursor at correct position, if possible
		if (cursorPos !is null){
			//check if cursor is at a position that's possible
			if (widgetLines.length >= cursorY && widgetLines.read(cursorY).length >= cursorX){
				cursorPos((cursorX - scrollX)+widgetPosition.x, (cursorY - scrollY)+widgetPosition.y);
			}
		}
	}
	// used by widget itself to move cursor
	void moveCursor(uinteger x, uinteger y){
		cursorX = x;
		cursorY = y;
		
		if (cursorY >= widgetLines.length){
			cursorY = widgetLines.length-1;
		}
		if (cursorX >= widgetLines.read(cursorY).length){
			cursorX = widgetLines.read(cursorY).length;
		}
	}
public:
	this(bool readOnly = false){
		widgetName = "memo";
		widgetLines = new List!string;
		scrollX, scrollY = 0;
		cursorX, cursorY = 0;
		writeProtected = readOnly;//cause if readOnly, then writeProtected = true also
	}
	~this(){
		delete widgetLines;
	}

	override void updateColors(){
		needsUpdate = true;
		if (&widgetTheme && widgetTheme.hasColors(name, ["background", "text"])){
			bgColor = widgetTheme.getColor(name, "background");
			textColor = widgetTheme.getColor(name, "text");
		}else{
			bgColor = hexToColor("404040");
			textColor = hexToColor("00FF00");
		}
		if (forceUpdate !is null){
			forceUpdate();
		}
	}

	override bool update(ref Matrix display){
		bool r = false;
		if (needsUpdate){
			needsUpdate = false;
			r = true;
			//check if there's lines to be displayed
			uinteger count = widgetLines.length, i, linesWritten = 0;
			char[] emptyLine;
			emptyLine.length = widgetSize.width;
			emptyLine[0 .. emptyLine.length] = ' ';
			if (count > 0){
				//write lines to memo
				char[] line;
				for (i = scrollY; i < count; i++){
					//echo current line
					line = cast(char[])widgetLines.read(i);
					//fit the line into screen, i.e check if only a part of it will be displayed
					if (line.length >= widgetSize.width+scrollX){
						//display only partial line
						display.write(line[scrollX .. scrollX + widgetSize.width], textColor, bgColor);
					}else{
						//either the line is small enough to fit, or 0-length
						if (line.length <= scrollX || line.length == 0){
							//just write the bgColor
							display.write(emptyLine, textColor, bgColor);
						}else{
							display.write(line[scrollX .. line.length], textColor, bgColor);
							//write the bgColor
							display.write(emptyLine[line.length - scrollX .. emptyLine.length], textColor, bgColor);
						}
					}
					linesWritten ++;
					//check if is at end
					if (i-scrollY >= widgetSize.height){
						break;
					}
				}
				//fill empty space with emptyLine
				if (linesWritten < widgetSize.height){
					count = widgetSize.height;
					for (i = linesWritten; i < count; i++){
						display.write(emptyLine,textColor, bgColor);
					}
				}
				//put the cursor at correct position, if possible
				setCursor();
			}
		}
		return r;
	}

	override void mouseEvent(MouseClick mouse){
		super.mouseEvent(mouse);
		//calculate mouse position, relative to scroll and widgetPosition
		mouse.x = (mouse.x - widgetPosition.x) + scrollX;
		mouse.y = (mouse.y - widgetPosition.y) + scrollY;
		if (mouse.mouseButton == mouse.Button.Left){
			needsUpdate = true;
			moveCursor(mouse.x, mouse.y);

		}else if (mouse.mouseButton == mouse.Button.ScrollDown){
			if (cursorY < widgetLines.length){
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
				string currentLine = widgetLines.read(cursorY);
				//check if backspace
				if (key.key == '\b'){
					//make sure that it's not the first line, first line cannot be removed
					if (cursorY > 0){
						//check if has to remove a '\n'
						if (cursorX == 0){
							cursorY --;
							//if line's not empty, append it to previous line
							cursorX = widgetLines.read(cursorY).length;
							if (currentLine != ""){
								//else, append this line to previous
								widgetLines.set(cursorY, widgetLines.read(cursorY)~currentLine);
							}
							widgetLines.remove(cursorY+1);
						}else{
							widgetLines.set(cursorY, cast(string)deleteElement(cast(char[])currentLine,cursorX-1));
							cursorX --;
						}
					}else if (cursorX > 0){
						widgetLines.set(cursorY, cast(string)deleteElement(cast(char[])currentLine,cursorX-1));
						cursorX --;
					}

				}else if (key.key == '\n'){
					//insert a newline
					//if is at end, just add it
					bool atEnd = false;
					if (cursorY >= widgetLines.length - 1){
						atEnd = true;
					}
					if (cursorX == widgetLines.read(cursorY).length){
						if (atEnd){
							widgetLines.add("");
						}else{
							widgetLines.insert(cursorY + 1,"");
						}
					}else{
						string[2] line;
						line[0] = widgetLines.read(cursorY);
						line[1] = line[0][cursorX .. line[0].length];
						line[0] = line[0][0 .. cursorX];
						widgetLines.set(cursorY, line[0]);
						if (atEnd){
							widgetLines.add(line[1]);
						}else{
							widgetLines.insert(cursorY + 1, line[1]);
						}
					}
					cursorY ++;
					cursorX = 0;
				}else if (key.key == '\t'){
					//convert it to 4 spaces
					widgetLines.set(cursorY, cast(string)insertElement(cast(char[])currentLine,cast(char[])"    ",cursorX));
					cursorX += 4;
				}else{
					//insert that char
					widgetLines.set(cursorY, cast(string)insertElement(cast(char[])currentLine,[cast(char)key.key],cursorX));
					cursorX ++;
				}
			}
		}else{
			if (key.key == key.NonCharKey.Delete){
				needsUpdate = true;
				//check if is deleting \n
				if (cursorX == widgetLines.read(cursorY).length && cursorY < widgetLines.length-1){
					//merge next line with this one
					char[] line = cast(char[])widgetLines.read(cursorY)~widgetLines.read(cursorY+1);
					widgetLines.set(cursorY, cast(string)line);
					//remove next line
					widgetLines.remove(cursorY+1);
				}else if (cursorX < widgetLines.read(cursorY).length){
					char[] line = cast(char[])widgetLines.read(cursorY);
					line = line.deleteElement(cursorX);
					widgetLines.set(cursorY, cast(string)line);
				}
			}else if (key.key == key.NonCharKey.DownArrow){
				if (cursorY < widgetLines.length-1){
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
					uinteger x, y;
					if (cursorX == 0){
						cursorY --;
						cursorX = widgetLines.read(cursorY).length;
					}else{
						cursorX --;
					}
				}
			}else if (key.key == key.NonCharKey.RightArrow){
				needsUpdate = true;
				if (cursorX == widgetLines.read(cursorY).length){
					if (cursorY < widgetLines.length-1){
						cursorX = 0;
						cursorY ++;
						scrollX = 0;

					}
				}else{
					cursorX ++;
				}
			}
		}
		reScroll();
	}

	///returns a list of lines in memo
	///
	///To modify the content, just modify it in the returned list
	///
	///class `List` is defined in `qui.lists.d`
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
		if (forceUpdate !is null){
			forceUpdate();
		}
		return writeProtected;
	}
}

/// Displays an un-scrollable log, that removes older lines
/// 
/// It's content cannot be modified by user.
/// 
/// Name in theme: 'log';
class LogWidget : QWidget{
private:
	LogList!string logs;

	RGBColor bgColor, textColor;

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
	this(uinteger maxLen=100){
		widgetName = "log";
		logs = new LogList!string(maxLen);
	}
	~this(){
		delete logs;
	}

	override public void updateColors(){
		needsUpdate = true;
		if (&widgetTheme && widgetTheme.hasColors(name, ["background", "text"])){
			bgColor = widgetTheme.getColor(name, "background");
			textColor = widgetTheme.getColor(name, "text");
		}else{
			bgColor = hexToColor("404040");
			textColor = hexToColor("00FF00");
		}
		if (forceUpdate !is null){
			forceUpdate();
		}
	}

	override public bool update(ref Matrix display){
		bool r = false;
		if (needsUpdate){
			needsUpdate = false;
			r = true;
			//get list of messages
			string[] messages = logs.read(logs.maxCapacity);
			//set colors
			display.setColors(textColor, bgColor);
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
				display.write(cast(char[])messages[i], textColor, bgColor);
				//add newline
				display.moveTo(0, display.writePosY+1);
			}
		}
		return r;
	}

	///adds string to the log, and scrolls down to it
	void add(string item){
		//add height
		logs.add(item);
		//update
		needsUpdate = true;
		if (forceUpdate !is null){
			forceUpdate();
		}
	}
	///clears the log
	void clear(){
		logs.reset();
		//update
		needsUpdate = true;
		if (forceUpdate !is null){
			forceUpdate();
		}
	}
}

/// A button
/// 
/// the caption is displayed inside the button
/// 
/// To receive input, set the `onMouseEvent` to set a custom mouse event
class ButtonWidget : QWidget{
private:
	RGBColor bgColor, textColor;
public:
	this(){
		widgetName = "button";
	}
	override public void updateColors(){
		if (&widgetTheme && widgetTheme.hasColors(name, ["background", "text"])){
			bgColor = widgetTheme.getColor(name, "background");
			textColor = widgetTheme.getColor(name, "text");
		}else{
			bgColor = hexToColor("00FF00");
			textColor = hexToColor("000000");
		}
	}

	override public bool update(ref Matrix display){
		bool r = false;
		if (needsUpdate){
			r = true;
			needsUpdate = false;
			char[] row;
			row.length = widgetSize.width;
			row[0 .. row.length] = ' ';
			//write the caption too!
			uinteger middle = widgetSize.height/2;
			for (uinteger i = 0; i < widgetSize.height; i++){
				if (i == middle && widgetCaption != ""){
					row = centerAlignText(cast(char[])caption, widgetSize.width);
					display.write(row, textColor, bgColor);
					row[0 .. row.length] = ' ';
					continue;
				}else{
					display.write(row, textColor, bgColor);
				}
			}
		}
		return r;
	}
}