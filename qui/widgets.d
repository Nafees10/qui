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
		widgetSize.width = caption.length;
		widgetSize.height = 1;
		return widgetCaption = caption;
	}
}

class ProgressbarWidget : QWidget{
private:
	uinteger max, done;
	uinteger fillCells;
	Direction barDirection;
public:
	enum Direction{
		Forward, Backward
	}
	this(Direction d, uinteger totalAmount, uinteger complete){
		barDirection = d;
		max = totalAmount;
		complete = done;
		fillCells = ratioToRaw(complete, max, widgetSize.width);
		//set max height
		widgetSize.maxHeight = 1;
	}
	bool update(ref Matrix display){
		bool r;

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
		fillCells = ratioToRaw(newProgress, newTotal, widgetSize.width);
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