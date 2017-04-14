module widgets;

import qui;
import misc;
import lists;

///name: `text-label`; Displays some text (caption)
class TextLabelWidget : QWidget{
private:
	RGBColor textColor, bgColor;
public:
	this(string caption = ""){
		widgetName = "text-label";
		widgetCaption = caption;
		//check if theme for this widget exists
		if (getColor){
			textColor = getColor(name, "text");
			bgColor = getColor(name, "background");
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
	void onClick(MouseClick mouse){
		//do nothing
	}
	void onKeyPress(KeyPress key){
		//do nothing
	}
}

///name: `progressbar`; Displays a left-to-right progressbar, with some text inside
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
		//set colors
		bgColor = getColor(name, "background");
		barColor = getColor(name, "bar");
		textColor = getColor(name, "text");
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
					}
					writeBarLine(display, filled, bar);
				}
			}
			//write it
			display.write(bar, barColor, bgColor);
			needsUpdate = false;
		}
		return r;
	}
	void onClick(MouseClick mouse){
		
	}
	void onKeyPress(KeyPress key){
		
	}

	@property uinteger total(){
		return max;
	}
	@property uinteger total(uinteger newTotal){
		needsUpdate = true;
		fillCells = ratioToRaw(done, newTotal, widgetSize.width);
		return max = newTotal;
	}

	@property uinteger progress(){
		return done;
	}
	@property uinteger progress(uinteger newProgress){
		needsUpdate = true;
		fillCells = ratioToRaw(newProgress, total, widgetSize.width);
		return done = newProgress;
	}
}