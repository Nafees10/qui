/++
	Some widgets that are included in the package.
	
	
+/
module qui.widgets;

import qui.qui;
import utils.misc;
import utils.lists;

/// To contain another widget in "margins"
class ContainerWidget : QWidget{
private:
	QWidget childWidget; // the widget to be "contained"
	bool childWidgetIsActive;
	uinteger mTop, mBottom, mLeft, mRight; // margins
	char mChar;

	RGBColor bgColor, textColor; // backgrond and foreground colors
	/// called by `update` to draw margins
	void drawMargins(Matrix display){
		char[] emptyLine;
		emptyLine.length = this.size.width;
		emptyLine[] = mChar;
		// top
		display.moveTo(0, 0);
		for (uinteger i = 0; i < mTop; i ++){
			display.write(emptyLine, textColor, bgColor);
		}
		// bottom
		display.moveTo(0, this.size.height - mBottom);
		for (uinteger i = 0; i < mBottom; i ++){
			display.write(emptyLine, textColor, bgColor);
		}
		//left
		emptyLine = emptyLine[0 .. mLeft];
		for (uinteger i = 0, count = this.size.height-(mTop+mBottom); i < count; i ++){
			display.moveTo(0, mTop+i);
			display.write(emptyLine, textColor, bgColor);
		}
		// right
		emptyLine.length = mRight;
		emptyLine[] = mChar;
		for (uinteger i = 0, count = this.size.height-(mTop+mBottom); i < count; i ++){
			display.moveTo(this.size.width-(mRight+1), mTop+i);
			display.write(emptyLine, textColor, bgColor);
		}
	}
	/// called by margin-changing-properties to calculate new minHeight & minWidth to fit the widget in
	void calculateMinSize(){
		// first minHeight
		uinteger minHeight = (childWidget !is null ? childWidget.size.minHeight : 0) + mTop + mBottom;
		if (this.size.minHeight < minHeight){
			this.size.minHeight = minHeight;
		}
		// then width
		uinteger minWidth = (childWidget !is null ? childWidget.size.minWidth : 0) + mLeft + mRight;
		if (this.size.minWidth < minWidth){
			this.size.minWidth = minWidth;
		}
	}
public:
	this (){
		bgColor = hexToColor("000000");
		textColor = hexToColor("00FF00");
		mChar = ' ';
		mTop, mBottom, mLeft, mRight = 0;
	}

	override bool update(Matrix display){
		if (childWidget.needsUpdate || needsUpdate){
			// reset the childWidget's size to fill space
			childWidget.size.width = this.size.width - (mLeft + mRight);
			childWidget.size.height = this.size.height - (mTop + mBottom);
			// reset the position
			childWidget.position.x = this.position.x + mLeft;
			childWidget.position.y = this.position.y + mTop;
			// then the widget
			Matrix wDisplay = new Matrix(childWidget.size.width, childWidget.size.height);
			if (childWidget!is null && childWidget.visible && childWidget.update(wDisplay)){
				display.insert(wDisplay, mLeft, mRight);
			}
			.destroy(wDisplay);
			// draw the margins
			drawMargins(display);

			needsUpdate = false;
			return true;
		}else{
			return false;
		}
	}

	override void keyboardEvent(KeyPress key){
		super.keyboardEvent(key);
		if (childWidget !is null && childWidget.visible && childWidgetIsActive){
			childWidget.keyboardEvent(key);
		}
	}

	/// Receives the event, and hands it down to the child widget if mouse is on that widget
	override void mouseEvent(MouseClick mouse) {
		super.mouseEvent(mouse);
		// mark child widget as not-active, it'll be marked active if the mouse is on it
		childWidgetIsActive = false;
		if (childWidget !is null && childWidget.visible){
			//check x-axis
			if (mouse.x >= childWidget.position.x && mouse.x < childWidget.position.x + childWidget.size.width){
				//check y-axis
				if (mouse.y >= childWidget.position.y && mouse.y < childWidget.position.y + childWidget.size.height){
					//give access to cursor position
					childWidget.onCursorPosition = cursorPos;
					//call mouseEvent
					childWidget.mouseEvent(mouse);
					//mark this widget as active
					childWidgetIsActive = true;
				}
			}
		}
	}
	// properties
	/// the widget to be contained
	@property QWidget widget(){
		return childWidget;
	}
	/// the widget to be contained
	@property QWidget widget(QWidget newVal){
		return childWidget = newVal;
	}
	/// top margin
	@property uinteger marginTop(){
		return mTop;
	}
	/// top margin
	@property uinteger marginTop(uinteger newVal){
		mTop = newVal;
		calculateMinSize;
		return mTop;
	}
	/// bottom margin
	@property uinteger marginBottom(){
		return mBottom;
	}
	/// bottom margin
	@property uinteger marginBottom(uinteger newVal){
		mBottom = newVal;
		calculateMinSize;
		return mBottom;
	}
	/// left margin
	@property uinteger marginLeft(){
		return mLeft;
	}
	/// left margin
	@property uinteger marginLeft(uinteger newVal){
		mLeft = newVal;
		calculateMinSize;
		return mLeft;
	}
	/// right margin
	@property uinteger marginRight(){
		return mRight;
	}
	/// right margin
	@property uinteger marginRight(uinteger newVal){
		mRight = newVal;
		calculateMinSize;
		return mRight;
	}
}

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
		widgetCaption = wCaption;

		textColor = hexToColor("00FF00");
		bgColor = hexToColor("000000");
	}
	
	override bool update(Matrix display){
		if (needsUpdate){
			display.write(cast(char[])widgetCaption, textColor, bgColor);
			needsUpdate = false;
			return true;
		}else{
			return false;
		}
	}
}

/// Displays a left-to-right progress bar.
/// 
/// Name in theme: 'progressbar';
class ProgressbarWidget : QWidget{
private:
	uinteger max, done;
	RGBColor bgColor, barColor;
	void writeBarLine(Matrix display, uinteger filled, char[] bar){
		display.write(bar[0 .. filled], barColor, barColor);
		display.write(bar[filled .. bar.length], barColor, bgColor);
	}
public:
	this(uinteger totalAmount = 100, uinteger complete = 0){
		widgetCaption = null;
		max = totalAmount;
		done = complete;

		bgColor = hexToColor("000000");
		barColor = hexToColor("00FF00");
	}
	
	override bool update(Matrix display){
		bool r = false;
		if (needsUpdate){
			r = true;
			uinteger filled = ratioToRaw(done, max, this.size.width);
			char[] bar;
			bar.length = this.size.width;
			bar[0 .. bar.length] = ' ';
			for (uinteger i = 0; i < this.size.height; i++){
				writeBarLine(display, filled, bar);
			}
			needsUpdate = false;
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
	
	void reScroll(){
		//check if is within length of line
		if (cursorX > inputText.length){
			cursorX = inputText.length;
		}
		uinteger w = this.size.width - widgetCaption.length;
		//now calculate scrollX, if it needs to be increased
		if ((scrollX + w < cursorX || scrollX + w >= cursorX)){
			if (cursorX <= w){
				scrollX = 0;
			}else{
				scrollX = cursorX - (w/2);
			}
		}
	}
	/// used by widget itself to set cursor
	void setCursor(){
		//put the cursor at correct position, if possible
		if (cursorPos !is null){
			//check if cursor is at a position that's possible
			if (inputText.length >= cursorX){
				cursorPos((cursorX - scrollX)+widgetPosition.x+widgetCaption.length, widgetPosition.y);
			}
		}
	}
	///shortens caption if too long
	void shortenCaption(){
		if (this.size.width - widgetCaption.length < 4){
			widgetCaption.length = this.size.width - 4;
		}
	}
public:
	this(string wCaption = "", string inputTxt = ""){
		inputText = cast(char[])inputTxt;
		widgetCaption = wCaption;
		shortenCaption;
		//specify min/max
		this.size.minWidth = 1;
		this.size.minHeight = 1;
		this.size.maxHeight = 1;

		bgColor = hexToColor("404040");
		textColor = hexToColor("00FF00");
		captionBgColor = hexToColor("000000");
		captionTextColor = hexToColor("00FF00");
	}

	override bool update(Matrix display){
		bool r = false;
		if (needsUpdate){
			r = true;
			//make sure there's enough space
			if (this.size.width > widgetCaption.length){
				//draw the caption
				display.write(cast(char[])widgetCaption, captionTextColor, captionBgColor);
				//draw the inputText
				uinteger width = this.size.width - widgetCaption.length;
				//fit the line into screen, i.e check if only a part of it will be displayed
				if (inputText.length >= width+scrollX){
					//display only partial line
					display.write(inputText[scrollX .. scrollX + width], textColor, bgColor);
				}else{
					char[] emptyLine;
					emptyLine.length = width;
					emptyLine[] = ' ';
					//either the line is small enough to fit, or 0-length
					if (inputText.length <= scrollX || inputText.length == 0){
						//just write the bgColor
						display.write(emptyLine, textColor, bgColor);
					}else{
						display.write(inputText[scrollX .. inputText.length], textColor, bgColor);
						//write the bgColor
						display.write(emptyLine[inputText.length - scrollX .. emptyLine.length], textColor, bgColor);
					}
				}
			}
			//set cursor pos, if can
			setCursor();
			needsUpdate = false;
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
		reScroll;
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
		}else{
			if (key.key == key.NonCharKey.LeftArrow && cursorX > 0){
				needsUpdate = true;
				cursorX --;
			}else if (key.key == key.NonCharKey.RightArrow && cursorX < inputText.length){
				needsUpdate = true;
				cursorX ++;
			}else if (key.key == key.NonCharKey.Delete && cursorX < inputText.length){
				inputText = inputText.deleteElement(cursorX);
			}
		}
		reScroll;
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
	/// caption of the widget. setter
	override @property string caption(string newCaption){
		needsUpdate = true;
		widgetCaption = newCaption;
		shortenCaption;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return widgetCaption;
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
		if ((scrollY + this.size.height < cursorY || scrollY + this.size.height >= cursorY) && cursorY != 0){
			if (cursorY <= this.size.height/2){
				scrollY = 0;
			}else{
				scrollY = cursorY - (this.size.height/2);
			}
		}
		//now time for scrollX
		//check if is within length of line
		uinteger len = widgetLines.read(cursorY).length;
		if (cursorX > len){
			cursorX = len;
		}
		//now calculate scrollX, if it needs to be increased
		if (/*cursorX > this.size.width &&*/(scrollX + this.size.width < cursorX || scrollX + this.size.width >= cursorX)){
			if (cursorX <= this.size.width/2){
				scrollX = 0;
			}else{
				scrollX = cursorX - (this.size.width/2);
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
		widgetLines = new List!string;
		scrollX, scrollY = 0;
		cursorX, cursorY = 0;
		writeProtected = readOnly;//cause if readOnly, then writeProtected = true also

		bgColor = hexToColor("404040");
		textColor = hexToColor("00FF00");
		// zero lines = wont work
		widgetLines.add("");
	}
	~this(){
		delete widgetLines;
	}
	
	override bool update(Matrix display){
		bool r = false;
		if (needsUpdate){
			r = true;
			//check if there's lines to be displayed
			uinteger count = widgetLines.length, i, linesWritten = 0;
			char[] emptyLine;
			emptyLine.length = this.size.width;
			emptyLine[0 .. emptyLine.length] = ' ';
			if (count > 0){
				//write lines to memo
				char[] line;
				for (i = scrollY; i < count; i++){
					//echo current line
					line = cast(char[])widgetLines.read(i);
					//fit the line into screen, i.e check if only a part of it will be displayed
					if (line.length >= this.size.width+scrollX){
						//display only partial line
						display.write(line[scrollX .. scrollX + this.size.width], textColor, bgColor);
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
					if (i-scrollY >= this.size.height){
						break;
					}
				}
				//fill empty space with emptyLine
				if (linesWritten < this.size.height){
					count = this.size.height;
					for (i = linesWritten; i < count; i++){
						display.write(emptyLine,textColor, bgColor);
					}
				}
				//put the cursor at correct position, if possible
				setCursor();
			}
			needsUpdate = false;
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
	LinkedList!string logs;
	
	uinteger max;
	
	RGBColor bgColor, textColor;
	
	uinteger stringLineCount(string s){
		uinteger width = this.size.width;
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
		uinteger width = this.size.width;
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
		max = maxLen;
		logs = new LinkedList!string;

		bgColor = hexToColor("404040");
		textColor = hexToColor("00FF00");
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
			display.setColors(textColor, bgColor);
			//determine how many of them will be displayed
			uinteger count;//right now, it's used to store number of lines used
			uinteger i;
			if (messages.length>0){
				for (i=messages.length-1; i>=0; i--){
					count += stringLineCount(messages[i]);
					if (count > this.size.height){
						messages = messages[i+1 .. messages.length];
						//try to insert part of the last message
						uinteger thisCount = stringLineCount(messages[i]);
						count -= thisCount;
						if (count < this.size.height){
							messages ~= [stripString(messages[i], this.size.height - count)];
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
		if (forceUpdate !is null){
			forceUpdate();
		}
	}
	///clears the log
	void clear(){
		logs.clear;
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
	this(string caption=""){
		widgetCaption = caption;

		bgColor = hexToColor("00FF00");
		textColor = hexToColor("000000");
	}
	
	override public bool update(Matrix display){
		bool r = false;
		if (needsUpdate){
			char[] row;
			row.length = this.size.width;
			row[0 .. row.length] = ' ';
			//write the caption too!
			uinteger middle = this.size.height/2;
			for (uinteger i = 0; i < this.size.height; i++){
				if (i == middle && widgetCaption != ""){
					row = centerAlignText(cast(char[])caption, this.size.width);
					display.write(row, textColor, bgColor);
					row[0 .. row.length] = ' ';
					continue;
				}else{
					display.write(row, textColor, bgColor);
				}
			}
			r = true;
			needsUpdate = false;
		}
		return r;
	}

	override void keyboardEvent(KeyPress key){
		super.keyboardEvent(key);
		mouseEvent(MouseClick(MouseClick.Button.Left, 0, 0));
	}
}