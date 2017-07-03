/++
	This module contains most of the functions you'll need.
	All the 'base' classes, like QWidget are defined in this.
	There are some classes, like List, that are defined in 
	other modules.
+/
module qui.qui;

import utils.misc;
import utils.lists;
import utils.baseconv;//used for hexadecimal colors
import std.stdio;//used by QTheme.themeToFile
import arsd.terminal;

///Mouse Click, or Ms Wheel scroll event
///
///The mouseEvent function is called with this.
struct MouseClick{
	///Types of buttons
	enum Button{
		Left,/// Left mouse button
		ScrollUp,/// MS wheel was scrolled up
		ScrollDown,/// MS wheel was scrolled down
		Right,/// Right mouse button was pressed
	}
	///Stores which button was pressed
	Button mouseButton;
	/// the x-axis of mouse cursor, 0 means left-most
	uinteger x;
	/// the y-axis of mouse cursor, 0 means top-most
	uinteger y;
}

///Key press event, keyboardEvent function is called with this
///
///A note: backspace (`\b`) and enter (`\n`) are not included in KeyPress.NonCharKey
struct KeyPress{
	dchar key;/// stores which key was pressed
	
	/// Returns true if the key was a character.
	/// 
	/// A note: backspace (`\b`) and enter (`\n`) are not included in KeyPress.NonCharKey
	bool isChar(){
		return !(key >= NonCharKey.min && key <= NonCharKey.max);
	}
	/// Types of non-character keys
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

/// A 24 bit, RGB, color
/// 
/// `r` represents amount of red, `g` is green, and `b` is blue.
/// the `a` is ignored
alias RGBColor = RGB;

/// Used to store position for widgets
struct Position{
	uinteger x, y;
}

/// To store size for widgets
/// 
/// zero in min/max means no limit
struct Size{
	uinteger width, height;
	uinteger minHeight = 0, minWidth = 0;
	uinteger maxHeight = 0, maxWidth = 0;
}

/// mouseEvent function
alias MouseEventFuction = void delegate(MouseClick);
///keyboardEvent function
alias KeyboardEventFunction = void delegate(KeyPress);


/// Base class for all widgets, including layouts and QTerminal
///
/// Use this as parent-class for new widgets
abstract class QWidget{
protected:
	///specifies position of this widget
	Position widgetPosition;
	///size of this widget
	Size widgetSize;
	///caption of this widget, it's up to the widget how to use this, progressbarWidget shows this inside the bar...
	string widgetCaption;
	///whether this widget should be drawn or not
	bool widgetShow = true;
	///to specify if this widget needs to be updated or not, mark this as true when the widget has changed
	bool needsUpdate = true;
	///specifies name of this widget. must be unique, as it is used to identify widgets in theme
	string widgetName = null;
	/// specifies that how much height (in horizontal layout) or width (in vertical) is given to this widget.
	/// The ratio of all widgets is added up and height/width for each widget is then calculated using this
	uinteger widgetSizeRatio = 1;
	
	///The theme that is currently used
	///
	///The widget is free to modify the theme
	QTheme widgetTheme;
	
	/// Called by widget when a redraw is needed, but no redraw is scheduled
	/// 
	/// In other words: call this function using (or it'll cause a segfault):
	/// ```
	/// if (forceUpdate !is null){
	/// 	forceUpdate();
	/// }
	/// ``` 
	/// when an update is needed, but it's not sure if an update will be called.
	/// Update is automatically called after mouseEvent and keyboardEvent
	bool delegate() forceUpdate;
	
	/// Called by widgets (usually keyboard-input-taking) to position the cursor
	/// 
	/// It can only be called if the widget is active (i.e selected), in non-active widgets, it's null;
	void delegate(uinteger x, uinteger y) cursorPos;
	
	/// custom mouse event, if not null, it should be called before doing anything else in mouseEvent.
	/// 
	/// Like:
	/// ```
	/// override void mouseEvent(MouseClick mouse){
	/// 	super.mouseEvent(mouse);
	/// 	// rest of the code here
	/// }
	/// ```
	MouseEventFuction customMouseEvent;
	
	/// custom keyboard event, if not null, it should be called before doing anything else in keyboardEvent.
	/// 
	/// Like:
	/// ```
	/// override void keyboardEvent(KeyPress key){
	/// 	super.keyboardEvent(key);
	/// 	// rest of the code here
	/// }
	/// ```
	KeyboardEventFunction customKeyboardEvent;
public:
	/// Called by owner when mouse is clicked with cursor on this widget.
	/// 
	/// `forceUpdate` is not required after this
	void mouseEvent(MouseClick mouse){
		if (customMouseEvent !is null){
			customMouseEvent(mouse);
		}
	}
	
	/// Called by owner when key is pressed and this widget is active.
	/// 
	/// `forceUpdate` is not required after this
	void keyboardEvent(KeyPress key){
		if (customKeyboardEvent !is null){
			customKeyboardEvent(key);
		}
	}
	
	/// Called by owner to update.
	/// 
	/// Return false if no need to update, and true if an update is required, and the new display in `display` Matrix
	abstract bool update(ref Matrix display);///return true to indicate that it has to be redrawn, else, make changes in display
	
	/// Called by owner to indicate that widget has to 're-fetch' colors from the theme.
	abstract void updateColors();
	
	//event properties
	/// use to change the custom mouse event
	@property MouseEventFuction onMouseEvent(MouseEventFuction func){
		return customMouseEvent = func;
	}
	/// use to change the custom keyboard event
	@property KeyboardEventFunction onKeyboardEvent(KeyboardEventFunction func){
		return customKeyboardEvent = func;
	}
	
	
	//properties:
	
	/// The name of the widget. Read-only, cannot be modified
	@property string name(){
		return widgetName;
	}
	
	/// caption of the widget. getter
	@property string caption(){
		return widgetCaption;
	}
	/// caption of the widget. setter
	@property string caption(string newCaption){
		needsUpdate = true;
		widgetCaption = newCaption;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return widgetCaption;
	}
	
	/// position of the widget. getter
	@property Position position(){
		return widgetPosition;
	}
	/// position of the widget. setter
	@property Position position(Position newPosition){
		widgetPosition = newPosition;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return widgetPosition;
	}
	
	/// size (width/height) of the widget. getter
	@property uinteger sizeRatio(){
		return widgetSizeRatio;
	}
	/// size (width/height) of the widget. setter
	@property uinteger sizeRatio(uinteger newRatio){
		needsUpdate = true;
		widgetSizeRatio = newRatio;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return widgetSizeRatio;
	}
	
	/// visibility of the widget. getter
	@property bool visible(){
		return widgetShow;
	}
	/// visibility of the widget. setter
	@property bool visible(bool visibility){
		needsUpdate = true;
		widgetShow = visibility;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return widgetShow;
	}
	
	/// theme of the widget. getter
	@property QTheme theme(){
		return widgetTheme;
	}
	/// theme of the widget. setter
	@property QTheme theme(QTheme newTheme){
		needsUpdate = true;
		widgetTheme = newTheme;
		if (forceUpdate !is null){
			forceUpdate();
		}
		return widgetTheme;
	}
	
	/// called by owner to set the `forceUpdate` function, which is used to force an update immediately.
	@property bool delegate() onForceUpdate(bool delegate() newOnForceUpdate){
		return forceUpdate = newOnForceUpdate;
	}
	/// called by the owner to set the `cursorPos` function, which is used to position the cursor on the terminal.
	@property void delegate(uinteger, uinteger) onCursorPosition(void delegate(uinteger, uinteger) newOnCursorPos){
		return cursorPos = newOnCursorPos;
	}
	/// size of the widget. getter
	@property Size size(){
		return widgetSize;
	}
	/// size of the widget. setter
	@property  Size size(Size newSize){
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
			widgetSize = newSize;
			if (forceUpdate !is null){
				forceUpdate();
			}
			return widgetSize;
		}
	}
}

///Used to place widgets in an order (i.e vertical or horizontal)
///
///The QTerminal is also a layout, basically.
///
///Name in theme: 'layout';
class QLayout : QWidget{
private:
	// array of all the widgets that have been added to this layout
	QWidget[] widgetList;
	// contains reference to the active widget, null if no active widget
	QWidget activeWidget;
	// stores the layout type, horizontal or vertical
	LayoutDisplayType layoutType;
	
	// background color
	RGBColor bgColor;
	// foreground color
	RGBColor textColor;
	// stores whether an update is in progress
	bool isUpdating = false;
	
	// recalculates the size and position of every widget inside layout
	void recalculateWidgetsSize(){
		uinteger ratioTotal = 0;
		Size newSize;
		//calculate total ratio
		foreach (widget; widgetList){
			if (widget.visible){
				ratioTotal += widget.sizeRatio;
			}
		}
		Position newPosition;
		
		//newSpace in Horizontal is read as 'newWidth' else 'newHeight'
		uinteger newSpace = 0;
		//same as above rule applies to this var's name too
		uinteger availableSpace;
		if (layoutType == LayoutDisplayType.Horizontal){
			availableSpace = widgetSize.width;
		}else{
			availableSpace = widgetSize.height;
		}
		
		foreach(widget; widgetList){
			if (widget.visible){
				//calculate position
				if (layoutType == LayoutDisplayType.Vertical){
					// x-axis is same for all widgets in Vertical Layouts
					newPosition.x = widgetPosition.x;
					// add previous widget's height to get this widget's y position
					newPosition.y += newSpace;
				}else if (layoutType == LayoutDisplayType.Horizontal){
					// y-axis is same for all widgets in Horizontal
					newPosition.y = widgetPosition.y;
					// add previous widget's width to get this widget's x position
					newPosition.x += newSpace;
				}
				//apply position
				widget.position = newPosition;
				
				// calculate width or height
				newSpace = ratioToRaw(widget.sizeRatio, ratioTotal, availableSpace);
				//check if new height/width is within specified limits
				if (layoutType == LayoutDisplayType.Horizontal){
					if (widget.size.maxWidth > 0 && newSpace > widget.size.maxWidth){
						newSpace = widget.size.maxWidth;
					}else if (widget.size.minWidth > 0 && newSpace < widget.size.minWidth){
						newSpace = widget.size.minWidth;
					}
				}else{
					if (widget.size.maxHeight > 0 && newSpace > widget.size.maxHeight){
						newSpace = widget.size.maxHeight;
					}else if (widget.size.minHeight > 0 && newSpace < widget.size.minHeight){
						newSpace = widget.size.minHeight;
					}
				}
				// check if there's enough space to contain that widget
				if (newSpace > availableSpace){
					newSpace = 0;
					widget.visible = false;
				}else{
					// apply new size
					if (layoutType == LayoutDisplayType.Horizontal){
						newSize.width = newSpace;
						newSize.height = widgetSize.height;
					}else{
						newSize.height = newSpace;
						newSize.width = widgetSize.width;
					}
					widget.size = newSize;
				}
			}
			
		}
	}
	
public:
	/// Layout type
	enum LayoutDisplayType{
		Vertical,
		Horizontal,
	}
	this(LayoutDisplayType type){
		widgetName = "layout";
		layoutType = type;
		activeWidget = null;
	}
	
	override void updateColors(){
		needsUpdate = true;
		if (&widgetTheme && widgetTheme.hasColors(name,["background","text"])){
			bgColor = widgetTheme.getColor(name, "background");
			textColor = widgetTheme.getColor(name, "text");
		}else{
			bgColor = hexToColor("000000");
			textColor = hexToColor("00FF00");
		}
		if (forceUpdate !is null){
			forceUpdate();
		}
	}
	
	/// adds (appends) a widget to the widgetList, and makes space for it
	void addWidget(QWidget widget){
		widget.theme = widgetTheme;
		widget.updateColors();
		widget.onForceUpdate = forceUpdate;
		//add it to array
		widgetList.length++;
		widgetList[widgetList.length-1] = widget;
		//recalculate all widget's size to adjust
		recalculateWidgetsSize();
	}
	
	override void mouseEvent(MouseClick mouse){
		super.mouseEvent(mouse);
		//check on which widget the cursor was on
		Position p;
		Size s;
		uinteger i;
		QWidget widget;
		//remove access to cursor from previous active widget
		if (activeWidget !is null){
			activeWidget.onCursorPosition = null;
		}
		for (i = 0; i < widgetList.length; i++){
			widget = widgetList[i];
			p = widget.position;
			s = widget.size;
			//check x-axis
			if (mouse.x >= p.x && mouse.x < p.x + s.width){
				//check y-axis
				if (mouse.y >= p.y && mouse.y < p.y + s.height){
					//give access to cursor position
					widget.onCursorPosition = cursorPos;
					//call mouseEvent
					widget.mouseEvent(mouse);
					//mark this widget as active
					activeWidget = widget;
					break;
				}
			}
		}
	}
	override void keyboardEvent(KeyPress key){
		super.keyboardEvent(key);
		//check active widget, call keyboardEvent
		if (activeWidget){
			activeWidget.keyboardEvent(key);
		}
	}
	override bool update(ref Matrix display){
		bool updated = false;
		//check if already updating, case yes, return false
		if (!isUpdating){
			isUpdating = true;
			//go through all widgets, check if they need update, update them
			Matrix wDisplay = new Matrix(1,1);
			foreach(widget; widgetList){
				if (widget.visible){
					wDisplay.changeSize(widget.size.width, widget.size.height);
					wDisplay.setColors(textColor, bgColor);
					wDisplay.resetWritePosition();
					if (widget.update(wDisplay)){
						display.insert(wDisplay, widget.position.x, widget.position.y);
						updated = true;
					}
					wDisplay.clear();
				}
			}
			isUpdating = false;
		}else{
			return false;
		}
		return updated;
	}
}

/// A terminal (as the name says).
/// 
/// All widgets, receives events, runs UI loop...
/// 
/// Name in theme: 'terminal';
class QTerminal : QLayout{
private:
	Terminal terminal;
	RealTimeConsoleInput input;
	Matrix termDisplay;
	
	Position cursorPos;
	
	bool isRunning = false;
public:
	this(string caption = "QUI Text User Interface", LayoutDisplayType displayType = LayoutDisplayType.Vertical){
		super(displayType);
		widgetName = "terminal";
		//create terminal & input
		terminal = Terminal(ConsoleOutputType.cellular);
		input = RealTimeConsoleInput(&terminal, ConsoleInputFlags.allInputEvents);
		terminal.showCursor();
		//init vars
		widgetSize.height = terminal.height;
		widgetSize.width = terminal.width;
		widgetCaption = caption;
		//set caption
		terminal.setTitle(widgetCaption);
		//create display matrix
		termDisplay = new Matrix(widgetSize.width, widgetSize.height);
		termDisplay.setColors(textColor, bgColor);
		//create theme
		widgetTheme = new QTheme;
	}
	~this(){
		terminal.clear;
		delete termDisplay;
	}
	
	override public void addWidget(QWidget widget) {
		super.addWidget(widget);
		widget.onForceUpdate = &updateDisplay;
	}
	
	override public void mouseEvent(MouseClick mouse) {
		super.mouseEvent(mouse);
		//check on which widget the cursor was on
		Position p;
		Size s;
		uinteger i;
		QWidget widget;
		//remove access to cursor from previous active widget
		if (activeWidget){
			activeWidget.onCursorPosition = null;
		}
		for (i = 0; i < widgetList.length; i++){
			widget = widgetList[i];
			p = widget.position;
			s = widget.size;
			//check x-axis
			if (mouse.x >= p.x && mouse.x < p.x + s.width){
				//check y-axis
				if (mouse.y >= p.y && mouse.y < p.y + s.height){
					//give access to cursor position
					widget.onCursorPosition = &setCursorPos;
					//call mouseEvent
					widget.mouseEvent(mouse);
					//mark this widget as active
					activeWidget = widget;
					break;
				}
			}
		}
	}
	
	/// Use this instead of `update` to forcefully update the terminal
	bool updateDisplay(){
		//termDisplay.clear(emptySpace);
		bool r = update(termDisplay);
		if (r){
			terminal.moveTo(0, 0);
			termDisplay.flushToTerminal(this);
		}
		//set cursor position
		terminal.moveTo(cast(int)cursorPos.x, cast(int)cursorPos.y);
		terminal.showCursor();
		return r;
	}
	
	/// starts the UI loop
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
				this.keyboardEvent(kPress);
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
					default:
						continue;
				}
				this.mouseEvent(mPos);
				updateDisplay;
			}else if (event.type == event.Type.SizeChangedEvent){
				//change matrix size
				termDisplay.changeSize(cast(uinteger)terminal.width, cast(uinteger)terminal.height);
				termDisplay.setColors(textColor, bgColor);
				//update self size
				terminal.updateSize;
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
		//in case an exception prevents it from being set to false before
		isRunning = false;
	}
	
	/// terminates the UI loop
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
	/// Called by active-widget(s?) to position the cursor
	void setCursorPos(uinteger x, uinteger y){
		cursorPos.x = x;
		cursorPos.y = y;
	}
	
	///returns true if UI loop is running
	@property bool running(){
		return isRunning;
	}
	
	//functions below are used by Matrix.flushToTerminal
	///flush changes to terminal, called by Matrix
	void flush(){
		terminal.flush;
	}
	///clear terminal, called before writing, called by Matrix
	void clear(){
		terminal.clear;
	}
	///change colors, called by Matrix
	void setColors(RGBColor textColor, RGBColor bgColor){
		terminal.setTrueColor(textColor, bgColor);
	}
	///move write-cursor to a position, called by Matrix
	void moveTo(int x, int y){
		terminal.moveTo(x, y);
	}
	///write chars to terminal, called by Matrix
	void writeChars(char[] c){
		terminal.write(c);
	}
	///write char to terminal, called by Matrix
	void writeChars(char c){
		terminal.write(c);
	}
}

///Theme class
class QTheme{
private:
	RGBColor[string][string] colors;
	RGBColor[string] globalColors;//i.e default colors
public:
	this(string themeFile = null){
		if (themeFile != null){
			loadTheme(themeFile);
		}
	}
	///returns color, provided the widgetName, and which-color (like textColor).
	///
	///if not found, returns a default color provided by theme. If that color
	///is also not found, throws exception
	RGBColor getColor(string widgetName, string which){
		if (widgetName in colors && which in colors[widgetName]){
			return colors[widgetName][which];
		}else{
			if (which in globalColors){
				return globalColors[which];
			}else{
				throw new Exception("Color "~which~" not defined (for "~widgetName~')');
			}
		}
	}
	///gets all colors for a widget.
	///
	///Throws exception if that widget has no colors defined in theme
	RGBColor[string] getColors(string widgetName){
		if (widgetName in colors){
			return colors[widgetName];
		}else{
			throw new Exception("Widget "~widgetName~" not defined");
		}
	}
	/// sets a  color for a widget
	void setColor(string widgetName, string which, RGBColor color){
		colors[widgetName][which] = color;
	}
	///sets a default value for a color
	///
	///i.e a color that is used when the color for widget is not found
	void setColor(string which, RGBColor color){
		globalColors[which] = color;
	}
	///sets all colors for a widget
	void setColors(string widgetName, RGBColor[string] widgetColors){
		colors[widgetName] = widgetColors;
	}
	///Saves current theme to a file, throws exception if failed
	bool saveTheme(string filename){
		bool r = true;
		try{
			File f = File(filename, "w");
			foreach(widgetName; colors.keys){
				foreach(colorName; colors[widgetName].keys){
					f.write(widgetName,' ',colorName,' ',colorToHex(colors[widgetName][colorName]),'\n');
				}
			}
			foreach(colorName; globalColors.keys){
				f.write("* ",colorName,' ',colorToHex(globalColors[colorName]),'\n');
			}
			f.close;
		}catch(Exception e){
			throw e;
		}
		return r;
	}
	///Loads a theme from file, throws exception if failed
	bool loadTheme(string filename){
		bool r = true;
		try{
			string[] fcontents = fileToArray(filename);
			string widgetName, colorName, colorCode, line;
			uinteger lEnd;
			for (uinteger lno = 0; lno < fcontents.length; lno++){
				line = fcontents[lno];
				uinteger readFrom = 0;
				lEnd = line.length - 1;
				for (uinteger i = 0; i < line.length; i++){
					if (line[i] == ' ' || i == lEnd){
						if (widgetName == null){
							widgetName = line[readFrom .. i];
						}
						if (colorName == null){
							colorName = line[readFrom .. i];
						}
						if (colorCode == null){
							colorCode = line[readFrom .. i];
						}
						readFrom = i+1;
					}
				}
				//add color, if any
				if (widgetName && colorName && colorCode){
					if (widgetName == "*"){
						globalColors[colorName] = hexToColor(colorCode);
					}else{
						colors[widgetName][colorName] = hexToColor(colorCode);
					}
					//clear name ...
					widgetName, colorName, colorCode = null;
				}
			}
		}catch(Exception e){
			throw e;
		}
		return r;
	}
	
	///checks if theme has any color(s) for a widget
	bool hasWidget(string widgetName){
		if (widgetName in colors){
			return true;
		}else{
			return false;
		}
	}
	///checks if theme has a specific color for a specific widget
	bool hasColor(string widgetName, string colorName){
		if (widgetName in colors){
			if (colorName in colors[widgetName]){
				return true;
			}else{
				return false;
			}
		}else{
			return false;
		}
	}
	///checks if theme has specific colors for a specific widget
	bool hasColors(string widgetName, string[] colorNames){
		bool r = true;
		foreach(color; colorNames){
			if (hasColor(widgetName, color) == false){
				r = false;
				break;
			}
		}
		return r;
	}
	///checks if theme has a default color
	bool hasColor(string colorName){
		if (colorName in globalColors){
			return true;
		}else{
			return false;
		}
	}///checks if theme has default colors
	bool hasColors(string[] colorNames){
		bool r = true;
		foreach(color; colorNames){
			if (hasColor(color) == false){
				r = false;
				break;
			}
		}
		return r;
	}
}

///Used to store the widget's/terminal's display in a matrix
class Matrix{
private:
	struct Display{
		uinteger x, y;
		RGBColor bgColor, textColor;
		char[] content;
	}
	//matrix size
	uinteger matrixHeight, matrixWidth;
	//next write position
	uinteger xPosition, yPosition;

	LinkedList!Display toUpdate;

public:
	this(uinteger width, uinteger height){
		toUpdate = new LinkedList!Display;
		//set size
		matrixHeight = 1;
		matrixWidth = 1;
		if (width > 1){
			matrixWidth = width;
		}
		if (height > 1){
			matrixHeight = height;
		}
		//set write positions
		xPosition = 0;
		yPosition = 0;
	}
	~this(){
		toUpdate.destroy;
	}
	///Clear the matrix, resets write position
	void clear(){
		toUpdate.clear;
		resetWritePosition();
	}
	/// clears the matrix, resets write position, and changes matrix size
	void changeSize(uinteger width, uinteger height){
		clear;
		matrixWidth = width;
		matrixHeight = height;
		if (matrixWidth == 0){
			matrixWidth = 1;
		}
		if (matrixHeight == 0){
			matrixHeight = 1;
		}
	}
	///sets write position to (0, 0)
	void resetWritePosition(){
		xPosition = 0;
		yPosition = 0;
	}
	/// To write to terminal
	void write(char[] c, RGBColor textColor, RGBColor bgColor){
		//get available cells
		uinteger cells = matrixWidth * matrixHeight;// first get the whole area
		cells -= xPosition;//subtract partial-lines
		cells -= yPosition*matrixWidth;//subtract lines taken by yPosition
		if (c.length > cells){
			c.length = cells;
		}
		uinteger i, end;
		if (c.length > 0){
			Display disp;
			disp.y = yPosition;
			disp.x = xPosition;
			disp.bgColor = bgColor;
			disp.textColor = textColor;
			//check if xPosition > 0, then fill that row before continuing
			if (disp.x > 0){
				if (c.length > matrixWidth-disp.x){
					disp.content = c[0 .. matrixWidth-disp.x];
					//remove first few elements from c
					c = c[matrixWidth-disp.x .. c.length];

					yPosition ++;
				}else{
					disp.content = c;

					xPosition += c.length;
					if (xPosition >= matrixWidth){
						xPosition = 0;
						yPosition ++;
					}
					//empty `c`
					c.length = 0;
				}
				toUpdate.append(disp);
			}
			if (c.length > 0){
				end = c.length / matrixWidth;
				for (i = 0; i < end; i ++){
					disp.content = c[i * matrixWidth .. (i * matrixWidth) + matrixWidth];
					toUpdate.append(disp);
					disp.y ++;
				}
				//update xPosition and yPosition
				xPosition = 0;
				yPosition = disp.y;
				// check if there was a partial line at end that needs to be appended
				if (c.length % matrixWidth > 0){
					disp.content = c[c.length - ( (c.length % matrixWidth) ) .. c.length];
					toUpdate.append(disp);
					xPosition = disp.content.length;
				}
			}
		}

	}
	/// Changes the matrix's colors. Must be called before any writing has taken place
	void setColors(RGBColor textColor, RGBColor bgColor){
		toUpdate.clear;// because it's contents are going to be overwritten, so why bother waste time writing them?
		Display disp;
		disp.bgColor = bgColor;
		disp.textColor = textColor;
		disp.x = 0;
		disp.y = 0;
		disp.content.length = matrixWidth;
		disp.content[] = ' ';
		// loop and set colors
		for (uinteger i = 0; i < matrixHeight; i ++){
			toUpdate.append(disp);
			disp.y ++;
		}
	}
	///move to a different position to write
	void moveTo(uinteger x, uinteger y){
		if (x < matrixHeight && y < matrixHeight){
			xPosition = x;
			yPosition = y;
		}
	}
	///returns number of rows/lines in matrix
	@property uinteger rowCount(){
		return matrixHeight;
	}
	///returns number of columns in matrix
	@property uinteger colCount(){
		return matrixWidth;
	}
	///returns the point ox x-axis where next write will start from
	@property Position writePos(){
		Position r;
		r.x = xPosition;
		r.y = yPosition;
		return r;
	}
	/// Returns in an array, list of all changes that have to be drawn on terminal. Used by `Matrix.insert` to copy contents
	Display[] toArray(){
		return toUpdate.toArray;
	}
	///insert a matrix into this one at a position
	void insert(Matrix toInsert, uinteger x, uinteger y){
		Display[] newMatrix = toInsert.toArray;
		// go through the new Displays and increae their x and y, and append them
		for (uinteger i = 0; i < newMatrix.length; i ++){
			newMatrix[i].y += y;
			newMatrix[i].x += x;

			toUpdate.append(newMatrix[i]);
		}
	}
	///Write contents of matrix to a QTerminal
	void flushToTerminal(QTerminal terminal){
		if (toUpdate.count > 0){
			toUpdate.resetRead;
			Display* disp = toUpdate.read;
			do{
				terminal.moveTo(cast(int)(*disp).x, cast(int)(*disp).y);
				terminal.setColors((*disp).textColor, (*disp).bgColor);
				terminal.writeChars((*disp).content);

				disp = toUpdate.read;
			}while (disp !is null);
			terminal.flush();

			toUpdate.clear;
		}
	}
}

//misc functions:
///Center-aligns text, returns that in an char[] with width as length. The empty part filled with ' '
char[] centerAlignText(char[] text, uinteger width, char fill = ' '){
	char[] r;
	if (text.length < width){
		r.length = width;
		uinteger offset = (width - text.length)/2;
		r[0 .. offset] = fill;
		r[offset .. offset+text.length][] = text;
		r[offset+text.length .. r.length] = fill;
	}else{
		r = text[0 .. width];
	}
	return r;
}
///
unittest{
	assert((cast(char[])"qwr").centerAlignText(7) == "  qwr  ");
}

///used to calculate height/width using sizeRation
uinteger ratioToRaw(uinteger selectedRatio, uinteger ratioTotal, uinteger total){
	uinteger r;
	r = cast(uinteger)((cast(float)selectedRatio/cast(float)ratioTotal)*total);
	return r;
}

///Converts hex color code to RGBColor
RGBColor hexToColor(string hex){
	RGBColor r;
	uinteger den = hexToDenary(hex);
	//min val for red in denary = 65536
	//min val for green in denary = 256
	//the remaining value is blue
	if (den >= 65536){
		r.r = cast(ubyte)((den / 65536));
		den -= r.r*65536;
	}
	if (den >= 256){
		r.g = cast(ubyte)((den / 256));
		den -= r.g*256;
	}
	r.b = cast(ubyte)den;
	return r;
}
///
unittest{
	RGBColor c;
	c.r = 10;
	c.g = 15;
	c.b = 0;
	assert("0A0F00".hexToColor == c);
}

///Converts RGBColor to hex color code
string colorToHex(RGBColor col){
	uinteger den;
	den = col.b;
	den += col.g*256;
	den += col.r*65536;
	return denaryToHex(den);
}
///
unittest{
	RGBColor c;
	c.r = 10;
	c.g = 8;
	c.b = 12;
	assert(c.colorToHex == "A080C");
}