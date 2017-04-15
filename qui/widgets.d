module widgets;

import qui;
import misc;
import lists;

///name: `text-label`; Displays some text (caption)
class TextLabelWidget : QWidget{
private:
	RGBColor textColor, bgColor;
public:
	this(string wCaption = ""){
		widgetName = "text-label";
		widgetCaption = wCaption;
	}

	void updateColors(){
		if (&widgetTheme && widgetTheme.hasColors(name,["background","text"])){
			textColor = widgetTheme.getColor(name, "text");
			bgColor = widgetTheme.getColor(name, "background");
		}else{
			//use default values
			textColor = hexToColor("00FF00");
			bgColor = hexToColor("000000");
		}
	}

	bool update(ref Matrix display){
		if (needsUpdate && widgetShow){
			//redraw text
			display.write(cast(char[])widgetCaption, textColor, bgColor);
			needsUpdate = false;
			return true;
		}else{
			return false;
		}
	}
	void onClick(MouseClick mouse){}
	void onKeyPress(KeyPress key){}
}

///name: `progressbar`; Displays a left-to-right progressbar, with some text inside (optional)
class ProgressbarWidget : QWidget{
private:
	uinteger max, done;
	uinteger fillCells;
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
		fillCells = ratioToRaw(complete, max, widgetSize.width);
	}

	void updateColors(){
		if (&widgetTheme && widgetTheme.hasColors(name, ["background", "bar", "text"])){
			bgColor = widgetTheme.getColor(name, "background");
			barColor = widgetTheme.getColor(name, "bar");
			textColor = widgetTheme.getColor(name, "text");
		}else{
			bgColor = hexToColor("A6A6A6");
			barColor = hexToColor("00FF00");
			textColor = hexToColor("000000");
		}
	}

	bool update(ref Matrix display){
		bool r = false;
		if (needsUpdate){
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
			needsUpdate = false;
		}
		return r;
	}
	void onClick(MouseClick mouse){}
	void onKeyPress(KeyPress key){}

	@property uinteger total(){
		return max;
	}
	@property uinteger total(uinteger newTotal){
		needsUpdate = true;
		fillCells = ratioToRaw(done, newTotal, widgetSize.width);
		max = newTotal;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return max;
	}

	@property uinteger progress(){
		return done;
	}
	@property uinteger progress(uinteger newProgress){
		needsUpdate = true;
		fillCells = ratioToRaw(newProgress, total, widgetSize.width);
		done = newProgress;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return done;
	}
}

///name: 'editLine'; To take single-line input
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
	void updateColors(){
		if (&widgetTheme && widgetTheme.hasColors(name, ["background", "captionText", "text"])){
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
	}
	bool update(ref Matrix display){
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
						debug{
							import std.stdio;
							writeln("scrollX: ",scrollX,";inputText.length: ",inputText.length,";width: ",width);//readln;
						}
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

	void onClick(MouseClick mouse){
		if (mouse.mouseButton == mouse.Button.Left){
			//move cursor to that pos
			uinteger tmp = widgetPosition.x + widgetCaption.length;
			if (mouse.x > tmp && mouse.x < tmp + inputText.length){
				cursorX = mouse.x - (widgetPosition.x + widgetCaption.length + scrollX);
			}
		}
	}
	void onKeyPress(KeyPress key){
		if (key.isChar){
			//insert that key
			if (key.key != '\b' && key.key != '\n'){
				if (cursorX == inputText.length){
					//insert at end
					inputText ~= cast(char)key.key;
				}else{
					inputText = inputText.insertArray([cast(char)key.key], cursorX);
				}
				cursorX ++;
			}else if (key.key == '\b'){
				//backspace
				if (cursorX > 0){
					if (cursorX == inputText.length){
						inputText.length --;
					}else{
						inputText = inputText.deleteArray(cursorX-1);
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
					cursorX --;
					if (scrollX > cursorX){
						scrollX = cursorX;
					}
				}
			}else if (key.key == key.NonCharKey.RightArrow || key.key == key.NonCharKey.DownArrow){
				if (cursorX < inputText.length){
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
	///returns text that was entered
	@property string text(){
		return cast(string)inputText;
	}
	///modify the entered text
	@property string text(string newText){
		inputText = cast(char[])newText;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return cast(string)inputText;
	}
}

///name: 'memo'; Use to display/edit 1+ lines, something like a simple text editor
class MemoWidget : QWidget{
private:
	List!string widgetLines;
	uinteger scrollX, scrollY;
	uinteger cursorX, cursorY;
	RGBColor bgColor, textColor;
public:
	this(){
		widgetName = "memo";
		widgetLines = new List!string;
		scrollX, scrollY = 0;
		cursorX, cursorY = 0;
	}
	~this(){
		delete widgetLines;
	}

	void updateColors(){
		if (&widgetTheme && widgetTheme.hasColors(name, ["background", "text"])){
			bgColor = widgetTheme.getColor(name, "background");
			textColor = widgetTheme.getColor(name, "text");
		}else{
			bgColor = hexToColor("404040");
			textColor = hexToColor("00FF00");
		}
	}

	bool update(ref Matrix display){
		bool r = false;
		if (needsUpdate){
			needsUpdate = false;
			r = true;
			//check if there's lines to be displayed
			uinteger count = widgetLines.length;
			char[] emptyLine;
			emptyLine.length = widgetSize.width;
			emptyLine[0 .. emptyLine.length] = ' ';
			if (count > 0){
				//write lines to memo
				char[] line;
				for (uinteger i = scrollY; i < count; i++){
					//echo current line
					line = cast(char[])widgetLines.read(i);
					//check if the line doesn't fit in
					uinteger displayWidth = scrollX+widgetSize.width;
					if (line.length > displayWidth){
						//write the partial line
						display.write(line[scrollX .. displayWidth], textColor, bgColor);
					}else{
						if (line.length == displayWidth){
							display.write(line[scrollX .. displayWidth], textColor, bgColor);
						}else{
							display.write(line[scrollX .. line.length], textColor, bgColor);
							//fill empty space
							display.write(emptyLine[0 .. widgetSize.width - line.length], textColor, bgColor);
						}
					}
					//check if is at end
					if (i-scrollY >= widgetSize.height){
						break;
					}
				}
				//put the cursor at correct position, if possible
				if (cursorPos !is null){
					//check if cursor is at a position that's possible
					if (count > cursorY && widgetLines.read(cursorY).length > cursorX){
						cursorPos(cursorX - scrollX, cursorY - scrollY);
					}
				}
			}
		}
		return r;
	}

	void onClick(MouseClick mouse){
		if (mouse.mouseButton == mouse.Button.Left){
			//get relative mouse position
			uinteger x, y;
			x = mouse.x - scrollX;
			y = mouse.y - scrollY;

			if (cursorY >= widgetLines.length){
				cursorY = widgetLines.length-1;
			}
			if (cursorX >= widgetLines.read(cursorY)){
				cursorX = widgetLines.read(cursorY).length-1;
			}
			//update cursor on screen
			if (cursorPos !is null){
				cursorPos(cursorX, cursorY);
			}
		}else if (mouse.mouseButton == mouse.Button.ScrollDown){
			//scroll down, i.e scrollY ++;
			if (scrollY < widgetLines.length+(widgetSize.height-2)){
				scrollY += 3;
			}
		}else if (mouse.mouseButton == mouse.Button.ScrollUp){
			//scroll up, i.e ScrollY --;
			if (scrollY > 0){
				if (scrollY < 3){
					scrollY = 0;
				}else{
					scrollY -= 3;
				}
			}
		}

	}

	void onKeyPress(KeyPress key){

	}

	///returns a list of lines in memo
	@property List!string lines(){
		return widgetLines;
	}
	///modify the lines in memo, be sure to delete the previous lines, or memory-leak... And be sure to not to put \n in a line
	@property List!string lines(List!string newLines){
		return widgetLines = newLines;
	}
}