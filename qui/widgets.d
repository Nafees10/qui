module widgets;

import qui;
import misc;
import lists;

class TextLabelWidget : QWidget{
public:
	this(string caption = ""){
		widgetCaption = caption;
	}
	bool update(ref Matrix display){
		if (needsUpdate && widgetShow){
			//redraw text
			display.write(cast(char[])widgetCaption, hexToColor("00FF00"), hexToColor("000000"));
			needsUpdate = false;
			return true;
		}else{
			return false;
		}
	}
	void onClick(MouseClick mouse){
		
	}
	void onKeyPress(KeyPress key){
		
	}
	override @property string caption(string caption){
		needsUpdate = true;
		return widgetCaption = caption;
	}
}

class ProgressbarWidget : QWidget{
private:
	uinteger max, done;
	uinteger fillCells;
	Direction barDirection;
	RGBColor bgColor, barColor;
public:
	enum Direction{
		Forward, Backward
	}
	this(Direction d, uinteger totalAmount = 100, uinteger complete = 0){
		barDirection = d;
		max = totalAmount;
		done = complete;
		fillCells = ratioToRaw(complete, max, widgetSize.width);
		//set max height
		widgetSize.maxHeight = 1;
		//set colors
		bgColor = hexToColor("000000");
		barColor = hexToColor("00FF00");
	}
	bool update(ref Matrix display){
		bool r = false;
		if (needsUpdate){
			r = true;
			uinteger filled = ratioToRaw(done, max, widgetSize.width);
			char[] bar;
			bar.length = widgetSize.width;
			if (barDirection == Direction.Forward){
				bar[0 .. filled] = '-';
				if (filled < widgetSize.width){
					bar[filled] = '>';
					bar[filled+1 .. bar.length] = ' ';
				}
			}else if (barDirection == Direction.Backward){
				uinteger from = bar.length-filled;
				bar[0 .. from] = ' ';
				bar[from] = '<';
				bar[from+1 .. bar.length] = '-';
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

	@property Direction direction(){
		return barDirection;
	}
	@property Direction direction(Direction newDirection){
		needsUpdate = true;
		return barDirection = newDirection;
	}
}