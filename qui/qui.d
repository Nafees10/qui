module qui;

import misc;
import lists;
import baseconv;//used for hexadecimal colors
import arsd.terminal;

//MouseClick event
struct MouseClick{
	enum Button{
		Left,
		ScrollUp,
		ScrollDown,
		Right,
		None ///Indicates that mouse was moved, not clicked
	}
	Button mouseButton;
	uinteger x;
	uinteger y;
}

//Key press event
struct KeyPress{
	dchar key;
	bool isChar(){
		return !(key >= NonCharKey.min && key <= NonCharKey.max);
	}
	enum NonCharKey{
		escape = 0x1b + 0xF0000,
		F1 = 0x70 + 0xF0000,
		F2 = 0x71 + 0xF0000,
		F3 = 0x72 + 0xF0000,
		F4 = 0x73 + 0xF0000,
		F5 = 0x74 + 0xF0000,
		F6 = 0x75 + 0xF0000,
		F7 = 0x76 + 0xF0000,
		F8 = 0x77 + 0xF0000,
		F9 = 0x78 + 0xF0000,
		F10 = 0x79 + 0xF0000,
		F11 = 0x7A + 0xF0000,
		F12 = 0x7B + 0xF0000,
		LeftArrow = 0x25 + 0xF0000,
		RightArrow = 0x27 + 0xF0000,
		UpArrow = 0x26 + 0xF0000,
		DownArrow = 0x28 + 0xF0000,
		Insert = 0x2d + 0xF0000,
		Delete = 0x2e + 0xF0000,
		Home = 0x24 + 0xF0000,
		End = 0x23 + 0xF0000,
		PageUp = 0x21 + 0xF0000,
		PageDown = 0x22 + 0xF0000,
	}
}

//same as termial.RGB, but using this, no need to `import terminal;` just for one struct
alias RGBColor = RGB;

//Position
struct Position{
	uinteger x, y;
}
//Size for widgets
struct Size{
	uinteger width, height;
	uinteger minHeight = 0, minWidth = 0;//0 = no limit
	uinteger maxHeight = 0, maxWidth = 0;
}
//Cell (these will make up the entire terminal display)
struct Cell{
	char c;
	RGBColor textColor;
	RGBColor bgColor;
}


//base class for all widgets, including layouts
abstract class QWidget{
protected:
	Position widgetPosition;
	Size widgetSize;
	string widgetCaption;
	bool widgetShow = true;
	bool needsUpdate = true;

	uinteger widgetSizeRatio = 1;
public:
	///called by owner when mouse is clicked with cursor on this widget
	abstract void onClick(MouseClick mouse);
	///called by owner when widget is selected and a key is pressed
	abstract void onKeyPress(KeyPress key);
	///called when the owner is redrawing, return false if no need to redraw
	abstract bool update(ref Matrix display);///return true to indicate that it has to be redrawn, else, make changes in display

	//properties:
	@property string caption(){
		return widgetCaption;
	}
	@property string caption(string newCaption){
		needsUpdate = true;
		return widgetCaption = newCaption;
	}

	@property Position position(){
		return widgetPosition;
	}
	@property Position position(Position newPosition){
		return widgetPosition = newPosition;
	}

	@property uinteger sizeRatio(){
		return widgetSizeRatio;
	}
	@property uinteger sizeRatio(uinteger newRatio){
		needsUpdate = true;
		return widgetSizeRatio = newRatio;
	}

	@property bool visible(){
		return widgetShow;
	}
	@property bool visible(bool visibility){
		return widgetShow = visibility;
	}

	@property Size size(){
		return widgetSize;
	}
	@property Size size(Size newSize){
		//check if height or width < min
		if (newSize.minWidth > 0 && newSize.width < newSize.minWidth){
			return widgetSize;
		}else if (newSize.maxWidth > 0 && newSize.width > newSize.maxWidth){
			return widgetSize;
		}else if (newSize.minHeight > 0 && newSize.height < newSize.minHeight){
			return widgetSize;
		}else if (newSize.maxHeight > 0 && newSize.height > newSize.maxHeight){
			return widgetSize;
		}else{
			needsUpdate = true;
			return widgetSize = newSize;
		}
	}
}

//to contain widgets in an order
class QLayout : QWidget{
private:
	QWidget[] widgetList;
	QWidget* activeWidget;
	LayoutDisplayType layoutType;

	RGBColor backColor;
	RGBColor foreColor;
	Cell emptySpace;
	/* Just a note: Layouts do not use these variables inherited from QWidget:
	 * widgetCaption
	 * needsUpdate
	 * 
	 * They have no caption, and needsUpdate is determined by child widgets
	*/

	void recalculateWidgetsSize(){
		uinteger ratioTotal = 0;
		Size newSize;
		//calculate total ratio
		foreach (currentWidget; widgetList){
			ratioTotal += currentWidget.sizeRatio;
		}
		Position newPosition;
		uinteger newWidth = 0, newHeight = 0;
		uinteger availableWidth = widgetSize.width;
		uinteger availableHeight = widgetSize.height;
		
		if (layoutType == LayoutDisplayType.Vertical){
			//make space for new widget
			foreach(w; widgetList){
				//if a widget is not visible, skip it
				if (w.visible){
					//recalculate position
					newPosition.x = widgetPosition.x;//x axis is always same, cause this is a vertical (not horizontal) layout
					if (newHeight > 0){
						newPosition.y += newHeight+1;//add previous widget's height to get new y axis position
					}else{
						newPosition.y = 0;
					}
					w.position = newPosition;
					//recalculate height
					newHeight = ratioToRaw(w.sizeRatio, ratioTotal, availableHeight);
					if (w.size.minHeight > 0 && newHeight < w.size.minHeight){
						newHeight = w.size.minHeight;
					}else if (w.size.maxHeight > 0 && newHeight > w.size.maxHeight){
						newHeight = w.size.maxHeight;
					}
					//recalculate width
					newWidth = widgetSize.width;//default is max
					//compare with min & max
					if (w.size.minWidth > 0 && newWidth < w.size.minWidth){
						//although there isn't that much width, still assign it, that will be dealt with later
						newWidth = w.size.minWidth;
					}else if (w.size.maxWidth > 0 && newWidth > w.size.maxWidth){
						newWidth = w.size.maxWidth;
					}
					//check if there's not enough space available, then make it invisible
					if (newWidth > availableWidth || newHeight > availableHeight){
						newWidth = 0;
						newHeight = 0;
						w.visible = false;
						continue;
					}
					//apply new size
					newSize = w.size;//to get min and max values
					newSize.height = newHeight;
					newSize.width = newWidth;
					w.size = newSize;
					//now the new size has been assigned, calculate amount of space & ratios left
					availableHeight -= newHeight;
					ratioTotal -= w.sizeRatio;
				}
			}
		}else if (layoutType == LayoutDisplayType.Horizontal){
			//make space for new widget
			foreach(w; widgetList){
				//if a widget is not visible, skip it
				if (w.visible){
					//recalculate position
					newPosition.y = widgetPosition.y;//x axis is always same, cause this is a vertical (not horizontal) layout
					if (newWidth > 0){
						newPosition.x += newWidth+1;//add previous widget's height to get new y axis position
					}else{
						newPosition.x = 0;
					}
					w.position = newPosition;
					//recalculate width
					newWidth = ratioToRaw(w.sizeRatio, ratioTotal, availableWidth);
					if (w.size.minWidth > 0 && newWidth < w.size.minWidth){
						newWidth = w.size.minWidth;
					}else if (w.size.maxWidth > 0 && newWidth > w.size.maxWidth){
						newWidth = w.size.maxWidth;
					}
					//recalculate height
					newHeight = widgetSize.height;//default is max
					//compare with min & max
					if (w.size.minHeight > 0 && newHeight < w.size.minHeight){
						//although there isn't that much width, still assign it, that will be dealt with later
						newHeight = w.size.minHeight;
					}else if (w.size.maxHeight > 0 && newHeight > w.size.maxHeight){
						newHeight = w.size.maxHeight;
					}
					//check if there's not enough space available, then make it invisible
					if (newWidth > availableWidth || newHeight > availableHeight){
						newWidth = 0;
						newHeight = 0;
						w.visible = false;
						continue;
					}
					//apply new size
					newSize = w.size;//to get min and max values
					newSize.height = newHeight;
					newSize.width = newWidth;
					w.size = newSize;
					//now the new size has been assigned, calculate amount of space & ratios left
					availableHeight -= newHeight;
					ratioTotal -= w.sizeRatio;
				}
			}
		}
	}

public:
	enum LayoutDisplayType{
		Vertical,
		Horizontal,
	}
	this(LayoutDisplayType type){
		//super(owner);
		layoutType = type;
		activeWidget = null;

		emptySpace.bgColor = hexToColor("000000");
		emptySpace.textColor = hexToColor("00FF00");
		emptySpace.c = ' ';
	}

	void addWidget(QWidget widget){
		//add it to array
		widgetList.length++;
		widgetList[widgetList.length-1] = widget;
		//recalculate all widget's size to adjust
		recalculateWidgetsSize();
	}

	void onClick(MouseClick mouse){
		//check on which widget the cursor was on
		Position p;
		Size s;
		uinteger i;
		QWidget widget;
		for (i = 0; i < widgetList.length; i++){
			widget = widgetList[i];
			p = widget.position;
			s = widget.size;
			//check x-axis
			if (mouse.x >= p.x && mouse.x < p.x + s.width){
				//check y-axis
				if (mouse.y >= p.y && mouse.y < p.y + s.height){
					//then this is the widget
					//mark this widget as active
					activeWidget = &widget;
					//and call onClick
					widget.onClick(mouse);
					break;
				}
			}
		}
	}
	void onKeyPress(KeyPress key){
		//check active widget, call onKeyPress
		/*if (activeWidget){
			(*activeWidget).onKeyPress(key);
		}*/
	}
	bool update(ref Matrix display){
		//go through all widgets, check if they need update, update them
		bool updated = false;
		Matrix wDisplay = new Matrix(1,1,emptySpace);
		foreach(widget; widgetList){
			if (widget.visible){
				wDisplay.changeSize(widget.size.width, widget.size.height, emptySpace);
				wDisplay.setWriteLimits(0, 0, widget.size.width, widget.size.height);//to prevent writing outside limits
				if (widget.update(wDisplay)){
					display.insert(wDisplay, widget.position.x, widget.position.y);
					updated = true;
				}
			}
		}
		return updated;
	}
}

class QTerminal : QLayout{
private:
	Terminal terminal;
	RealTimeConsoleInput input;
	Matrix termDisplay;
	bool isRunning = false;

public:
	this(string caption = "QUI Text User Interface", LayoutDisplayType displayType = LayoutDisplayType.Vertical){
		super(displayType);
		//create terminal & input
		terminal = Terminal(ConsoleOutputType.cellular);
		input = RealTimeConsoleInput(&terminal, ConsoleInputFlags.allInputEvents);
		//init vars
		widgetSize.height = terminal.height;
		widgetSize.width = terminal.width;
		widgetCaption = caption;
		//set caption
		terminal.setTitle(widgetCaption);
		//create display matrix
		termDisplay = new Matrix(widgetSize.width, widgetSize.height, emptySpace);
	}
	~this(){
		terminal.clear;
		delete termDisplay;
	}

	///Use this to update teriminal, returns true if at least 1 widget was updated, don't call update directly on terminal
	bool updateDisplay(){
		bool r = update(termDisplay);
		if (r){
			termDisplay.flushToTerminal(&this);
		}
		return r;
	}

	void run(){
		InputEvent event;
		isRunning = true;
		//draw the whole thing
		recalculateWidgetsSize;
		updateDisplay();
		while (isRunning){
			event = input.nextEvent;
			//check event type
			if (event.type == event.Type.KeyboardEvent){
				KeyPress kPress;
				kPress.key = event.get!(event.Type.KeyboardEvent).which;
				this.onKeyPress(kPress);
				updateDisplay;
			}else if (event.type == event.Type.MouseEvent){
				MouseEvent mEvent = event.get!(event.Type.MouseEvent);
				MouseClick mPos;
				mPos.x = mEvent.x;
				mPos.y = mEvent.y;
				switch (mEvent.buttons){
					case MouseEvent.Button.Left:
						mPos.mouseButton = mPos.Button.Left;
						break;
					case MouseEvent.Button.Right:
						mPos.mouseButton = mPos.Button.Right;
						break;
					case MouseEvent.Button.ScrollUp:
						mPos.mouseButton = mPos.Button.ScrollUp;
						break;
					case MouseEvent.Button.ScrollDown:
						mPos.mouseButton = mPos.Button.ScrollDown;
						break;
					case MouseEvent.Button.None:
						mPos.mouseButton = mPos.Button.None;
						break;
					default:
						continue;
				}
				this.onClick(mPos);
				updateDisplay;
			}else if (event.type == event.Type.SizeChangedEvent){
				//update self size
				widgetSize.height = terminal.height;
				widgetSize.width = terminal.width;
				//call size change on all widgets
				recalculateWidgetsSize;
				updateDisplay;
			}else if (event.type == event.Type.UserInterruptionEvent){
				//die here
				terminal.clear;
				isRunning = false;
				break;
			}
		}
	}

	void terminate(){
		isRunning = false;
	}

	//override write properties
	override @property Size size(Size newSize){
		//don't let anything modify the size
		return widgetSize;
	}
	override @property Position position(Position newPosition){
		return widgetPosition;
	}

	//functions below are used by Matrix.flushToTerminal
	void clear(){
		terminal.clear;
	}
	void setColors(RGBColor textColor, RGBColor bgColor){
		terminal.setTrueColor(textColor, bgColor);
	}
	void moveTo(int x, int y){
		terminal.moveTo(x, y);
	}
	void writeChars(char[] c){
		terminal.write(c);
	}
	void writeChars(char c){
		terminal.write(c);
	}
}

//misc functions:
uinteger ratioToRaw(uinteger selectedRatio, uinteger ratioTotal, uinteger total){
	uinteger r;
	r = cast(uinteger)((cast(float)selectedRatio/cast(float)ratioTotal)*total);
	return r;
}

RGBColor hexToColor(string hex){
	RGBColor r;
	r.r = cast(ubyte)hexToDen(hex[0..2]);
	r.g = cast(ubyte)hexToDen(hex[2..4]);
	r.b = cast(ubyte)hexToDen(hex[4..6]);
	return r;
}


/* Color standards
 * background: black, 000000
 * text: green, 00FF00
 * selected-widget: ???
*/