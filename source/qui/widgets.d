/++
	Some widgets that are included in the package.
	
	
+/
module qui.widgets;

import qui.qui;
import utils.misc;
import utils.lists;

/// To contain another widget in "margins"
/// 
/// set margins using the `marginLeft/Right/Top/Bottom` properties, or simply using `margin` - default margins are zero
/// set the character to write in margin using `marginCharTop/Bottom/Left/Right` or just `marginChar` - default is space character
class ContainerWidget : QWidget{
private:
	QWidget childWidget; // the widget to be "contained"
	bool childWidgetIsActive;
	uinteger mTop, mBottom, mLeft, mRight; // margins
	char mCharTop, mCharBottom, mCharLeft, mCharRight;

	/// called by `update` to draw margins
	void drawMargins(Matrix display){
		char[] emptyLine;
		// top
		emptyLine.length = widgetSize.width;
		emptyLine[] = mCharTop;
		display.moveTo(0, 0);
		for (uinteger i = 0; i < mTop; i ++){
			display.write(emptyLine, textColor, backgroundColor);
		}
		// bottom
		emptyLine[] = mCharBottom;
		display.moveTo(0, widgetSize.height - mBottom);
		for (uinteger i = 0; i < mBottom; i ++){
			display.write(emptyLine, textColor, backgroundColor);
		}
		//left
		emptyLine.length = mLeft;
		emptyLine[] = mCharLeft;
		for (uinteger i = 0, count = widgetSize.height-(mTop+mBottom); i < count; i ++){
			display.moveTo(0, mTop+i);
			display.write(emptyLine, textColor, backgroundColor);
		}
		// right
		emptyLine.length = mRight;
		emptyLine[] = mCharRight;
		for (uinteger i = 0, count = widgetSize.height-(mTop+mBottom); i < count; i ++){
			display.moveTo(widgetSize.width-(mRight), mTop+i);
			display.write(emptyLine, textColor, backgroundColor);
		}
	}
	/// called by margin-changing-properties to calculate new minHeight & minWidth to fit the widget in
	void calculateMinSize(){
		// first minHeight
		uinteger minHeight = (childWidget !is null ? childWidget.size.minHeight : 0) + mTop + mBottom;
		if (widgetSize.minHeight < minHeight){
			widgetSize.minHeight = minHeight;
		}
		// then width
		uinteger minWidth = (childWidget !is null ? childWidget.size.minWidth : 0) + mLeft + mRight;
		if (widgetSize.minWidth < minWidth){
			widgetSize.minWidth = minWidth;
		}
	}
public:
	/// background and text colors
	RGB backgroundColor, textColor;
	this (){
		textColor = DEFAULT_TEXT_COLOR;
		backgroundColor = DEFAULT_BACK_COLOR;
		marginChar = ' ';
		margin = 0;
		// this widget doesnt want input, but it's child-widget may want, but child widget is registered separately, so 
		// this widget does not want input
		widgetWantsInput = false;
	}

	override bool update(Matrix display){
		if (needsUpdate || (childWidget !is null && childWidget.visible && childWidget.needsUpdate)){
			// then the widget
			Matrix wDisplay = new Matrix(childWidget.size.width, childWidget.size.height);
			if (childWidget.update(wDisplay)){
				display.insert(wDisplay, mLeft, mTop);
			}
			.destroy(wDisplay);
			// draw the margins, only if "this" widget needs update, meaning: only if it resized or something messed up margins
			if (needsUpdate){
				drawMargins(display);
				needsUpdate = false;
			}

			return true;
		}else{
			return false;
		}
	}

	override public void resizeEvent(){
		super.resizeEvent();
		// resize and reposition childWidget if any
		if (childWidget !is null){
			childWidget.size.width = widgetSize.width - (mLeft + mRight);
			childWidget.size.height = widgetSize.height - (mTop + mBottom);
			childWidget.resizeEvent();

			childWidget.position.x = this.position.x + mLeft;
			childWidget.position.y = this.position.y + mTop;
		}
	}

	/// overriding to change termInterface of child-widget too
	override public @property QTermInterface setTermInterface(QTermInterface newInterface) {
		auto r = super.setTermInterface(newInterface);
		childWidget.setTermInterface (termInterface);
		return r;
	}
	// properties
	/// the widget to be contained
	@property QWidget widget(){
		return childWidget;
	}
	/// the widget to be contained
	@property QWidget widget(QWidget newVal){
		childWidget = newVal;
		childWidget.setTermInterface = termInterface;
		return childWidget;
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
	/// to change value of all margins
	@property uinteger margin(uinteger newVal){
		mTop = newVal;
		mBottom = newVal;
		mLeft = newVal;
		mRight = newVal;
		calculateMinSize;
		return newVal;
	}
	/// the char that is written in space occupied by top margin
	@property char marginCharTop(){
		return mCharTop;
	}
	/// the char that is written in space occupied by top margin
	@property char marginCharTop(char newVal){
		needsUpdate = true;
		return mCharTop = newVal;
	}
	/// the char that is written in space occupied by bottom margin
	@property char marginCharBottom(){
		return mCharBottom;
	}
	/// the char that is written in space occupied by bottom margin
	@property char marginCharBottom(char newVal){
		needsUpdate = true;
		return mCharBottom = newVal;
	}
	/// the char that is written in space occupied by left margin
	@property char marginCharLeft(){
		return mCharLeft;
	}
	/// the char that is written in space occupied by left margin
	@property char marginCharLeft(char newVal){
		needsUpdate = true;
		return mCharLeft = newVal;
	}
	/// the char that is written in space occupied by top margin
	@property char marginCharRight(){
		return mCharRight;
	}
	/// the char that is written in space occupied by top margin
	@property char marginCharRight(char newVal){
		needsUpdate = true;
		return mCharRight = newVal;
	}
	/// to set the character written in each margin (top, bottom, left, & right)
	@property char marginChar(char newVal){
		needsUpdate = true;
		mCharTop = newVal;
		mCharBottom = newVal;
		mCharLeft = newVal;
		mCharRight = newVal;
		return newVal;
	}
}

///Displays some text
///
///And it can't handle new-line characters
class TextLabelWidget : QWidget{
public:
	/// text and background colors
	RGB textColor, backgroundColor;
	this(string wCaption = ""){
		widgetCaption = wCaption;

		textColor = DEFAULT_TEXT_COLOR;
		backgroundColor = DEFAULT_BACK_COLOR;
	}
	
	override bool update(Matrix display){
		if (needsUpdate){
			display.write(cast(char[])widgetCaption, textColor, backgroundColor);
			needsUpdate = false;
			return true;
		}else{
			return false;
		}
	}
}

/// Displays a left-to-right progress bar.
class ProgressbarWidget : QWidget{
private:
	uinteger max, done;
public:
	/// background color, and bar's color
	RGB backgroundColor, barColor;
	this(uinteger totalAmount = 100, uinteger complete = 0){
		widgetCaption = null;
		max = totalAmount;
		done = complete;

		barColor = DEFAULT_TEXT_COLOR;
		backgroundColor = DEFAULT_BACK_COLOR;
	}
	
	override bool update(Matrix display){
		bool r = false;
		if (needsUpdate){
			r = true;
			uinteger filled = ratioToRaw(done, max, widgetSize.width);
			char[] bar;
			bar.length = widgetSize.width;
			bar[0 .. bar.length] = ' ';
			for (uinteger i = 0; i < widgetSize.height; i++){
				display.write(bar[0 .. filled], barColor, barColor);
				display.write(bar[filled .. bar.length], barColor, backgroundColor);
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
		// force an update
		termInterface.forceUpdate();
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
		// force an update
		termInterface.forceUpdate();
		return done;
	}
}

/// To get single-line input from keyboard
class EditLineWidget : QWidget{
private:
	char[] inputText;
	uinteger cursorX;
	uinteger scrollX = 0;//amount of chars that won't be displayed because of not enough space
	
	void reScroll(){
		//check if is within length of line
		if (cursorX > inputText.length){
			cursorX = inputText.length;
		}
		uinteger w = widgetSize.width - widgetCaption.length;
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
		termInterface.setCursorPos(
			Position(
				(cursorX - scrollX)+widgetCaption.length, // x
				0), // y
			this);
	}
	///shortens caption if too long
	void shortenCaption(){
		if (widgetSize.width - widgetCaption.length < 4){
			widgetCaption.length = widgetSize.width - 4;
		}
	}
public:
	/// background, text, caption, and caption's background colors
	RGB backgroundColor, textColor, captionTextColor, captionBackgroundColor;
	this(string wCaption = "", string inputTxt = ""){
		inputText = cast(char[])inputTxt;
		widgetCaption = wCaption;
		shortenCaption;
		//specify min/max
		widgetSize.minWidth = 1;
		widgetSize.minHeight = 1;
		widgetSize.maxHeight = 1;
		// this widget wants Tab key
		widgetWantsTab = true;
		// and input too, obvious
		widgetWantsInput = true;
		// and needs to show the cursor too
		widgetShowCursor = true;

		textColor = DEFAULT_TEXT_COLOR;
		backgroundColor = DEFAULT_BACK_COLOR;
		captionTextColor = DEFAULT_TEXT_COLOR;
		captionBackgroundColor = DEFAULT_BACK_COLOR;
	}

	override bool update(Matrix display){
		bool r = false;
		if (needsUpdate){
			r = true;
			//make sure there's enough space
			if (widgetSize.width > widgetCaption.length){
				//draw the caption
				display.write(cast(char[])widgetCaption, captionTextColor, captionBackgroundColor);
				//draw the inputText
				uinteger width = widgetSize.width - widgetCaption.length;
				//fit the line into screen, i.e check if only a part of it will be displayed
				if (inputText.length >= width+scrollX){
					//display only partial line
					display.write(inputText[scrollX .. scrollX + width], textColor, backgroundColor);
				}else{
					char[] emptyLine;
					emptyLine.length = width;
					emptyLine[] = ' ';
					//either the line is small enough to fit, or 0-length
					if (inputText.length <= scrollX || inputText.length == 0){
						//just write the bgColor
						display.write(emptyLine, textColor, backgroundColor);
					}else{
						display.write(inputText[scrollX .. inputText.length], textColor, backgroundColor);
						//write the bgColor
						display.write(emptyLine[inputText.length - scrollX .. emptyLine.length], textColor, backgroundColor);
					}
				}
			}else{
				// be sad, there's not enough space to draw
				if (this.widgetSize.width >= 2){
					display.write(cast(char[])":(", textColor, backgroundColor);
				}
			}
			needsUpdate = false;
		}
		setCursor();
		return r;
	}
	
	override void mouseEvent(MouseClick mouse){
		super.mouseEvent(mouse);
		if (mouse.mouseButton == mouse.Button.Left){
			needsUpdate = true;
			//move cursor to that pos
			if (mouse.x > widgetCaption.length && mouse.x < widgetCaption.length + inputText.length){
				cursorX = mouse.x - (widgetCaption.length + scrollX);
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
		// force an update
		termInterface.forceUpdate();
		return cast(string)inputText;
	}
	/// caption of the widget. setter
	override @property string caption(string newCaption){
		needsUpdate = true;
		widgetCaption = newCaption;
		shortenCaption;
		// force an update
		termInterface.forceUpdate();
		return widgetCaption;
	}
	/// override resize to shorten caption
	override void resizeEvent(){
		super.resizeEvent;
		shortenCaption;
	}
}

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
		if (cursorY > scrollY + widgetSize.height || cursorY < scrollY){
			scrollY = cursorY - widgetSize.height + 1;
		}
		//now time for scrollX
		//check if is within length of line
		uinteger len = readLine(cursorY).length;
		if (cursorX > len){
			cursorX = len;
		}
		//now calculate scrollX, if it needs to be increased
		if (scrollX + widgetSize.width < cursorX || scrollX + widgetSize.width >= cursorX){
			if (cursorX <= widgetSize.width){
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
			if (cursorY < lineCount){
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
				if (cursorX == readLine(cursorY).length && cursorY < lineCount-1){
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
					if (cursorY < lineCount){
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
}