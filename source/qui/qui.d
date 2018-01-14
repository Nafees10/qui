/++
	This module contains most of the functions you'll need.
	All the 'base' classes, like QWidget are defined in this.
+/
module qui.qui;

import arsd.terminal;
import std.stdio;
import utils.baseconv;
import utils.lists;
import utils.misc;
import std.conv : to;

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
	/// Returns: a string representation of MouseClick, in JSON
	string stringof(){
		return "{button:"~to!string(mouseButton)~",x:"~to!string(x)~",y:"~to!string(y)~"}";
	}
}

///Key press event, keyboardEvent function is called with this
///
///A note: backspace (`\b`) and enter (`\n`) are not included in KeyPress.NonCharKey
struct KeyPress{
	dchar key;/// stores which key was pressed

	/// Returns true if the key was a character.
	/// 
	/// A note: Enter/Return ('\n') is not included in KeyPress.NonCharKey
	bool isChar(){
		return !(key >= NonCharKey.min && key <= NonCharKey.max);
	}
	/// Types of non-character keys
	enum NonCharKey{
		Escape = 0x1b + 0xF0000,
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
	/// Returns: a string representation of KeyPress, in JSON
	string stringof(){
		if (isChar){
			return "{key:"~cast(char)key~'}';
		}
		return "{key:\""~to!string(cast(NonCharKey)key)~"\"}";
	}
}

/// A 24 bit, RGB, color
/// 
/// `r` represents amount of red, `g` is green, and `b` is blue.
/// the `a` is ignored
public import arsd.terminal : RGB;

/// Used to store position for widgets
struct Position{
	uinteger x, y;
	/// Returns: a string representation of Position
	string stirngof(){
		return "{x:"~to!string(x)~",y:"~to!string(y)~"}";
	}
}

/// To store size for widgets
/// 
/// zero in min/max means no limit
struct Size{
	private{
		uinteger w, h;
		bool hasChanged = false; /// specifies if has been changed.
	}
	/// returns whether the size was changed since the last time this property was read
	@property bool sizeChanged(){
		if (hasChanged){
			hasChanged = false;
			return true;
		}else{
			return false;
		}
	}
	/// width
	@property uinteger width(){
		return w;
	}
	/// width
	@property uinteger width(uinteger newWidth){
		hasChanged = true;
		if (minWidth > 0 && newWidth < minWidth){
			return w = minWidth;
		}else if (maxWidth > 0 && newWidth > maxWidth){
			return w = maxWidth;
		}else{
			return w = newWidth;
		}
	}
	/// height
	@property uinteger height(){
		return h;
	}
	/// height
	@property uinteger height(uinteger newHeight){
		hasChanged = true;
		if (minHeight > 0 && newHeight < minHeight){
			return h = minHeight;
		}else if (maxHeight > 0 && newHeight > maxHeight){
			return h = maxHeight;
		}else{
			return h = newHeight;
		}
	}
	/// minimun width & height. These are "applied" automatically when setting value using `width` or `height`
	uinteger minWidth = 0, minHeight = 0;
	/// maximum width & height. These are "applied" automatically when setting value using `width` or `height`
	uinteger maxWidth = 0, maxHeight = 0;
	/// Returns: a string representation of KeyPress, in JSON
	string stringof(){
		return "{width:"~to!string(w)~",height:"~to!string(height)~
			",minWidth:"~to!string(minWidth)~",maxWidth:"~to!string(maxWidth)~
				",minHeight:"~to!string(minHeight)~",maxHeight:"~to!string(maxHeight)~"}";
	}
}

/// mouseEvent function
alias MouseEventFuction = void delegate(MouseClick);
///keyboardEvent function
alias KeyboardEventFunction = void delegate(KeyPress);
/// resizeEvent function
alias ResizeEventFunction = void delegate(Size);
/// activateEvent function
alias ActivateEventFunction = void delegate(bool);


/// Base class for all widgets, including layouts and QTerminal
///
/// Use this as parent-class for new widgets
abstract class QWidget{
protected:
	///specifies position of this widget
	Position widgetPosition;
	///size of this widget
	Size widgetSize;
	///caption of this widget, it's up to the widget how to use this, TextLabelWidget shows this as the text
	string widgetCaption;
	///whether this widget should be drawn or not
	bool widgetShow = true;
	///to specify if this widget needs to be updated or not, mark this as true when the widget has changed
	bool widgetNeedsUpdate = true;
	/// specifies that how much height (in horizontal layout) or width (in vertical) is given to this widget.
	/// The ratio of all widgets is added up and height/width for each widget is then calculated using this
	uinteger widgetSizeRatio = 1;
	/// specifies whether this widget should receive the Tab key press, default is false, and should only be changed to true
	/// if only required, for example, in text editors
	bool widgetWantsTab = false;
	/// specifies whether the widget wants input, mouse or keyboard, or both
	bool widgetWantsInput = false;
	/// specifies if the widget needs to show the cursor
	bool widgetShowCursor = false;
	/// the interface used to "talk" to the terminal, for example, to change the cursor position etc
	QTermInterface termInterface;
	
	/// custom mouse event, if not null, it should be called before doing anything else in mouseEvent.
	/// 
	/// Like:
	/// ```
	/// override void mouseEvent(MouseClick mouse){
	/// 	super.mouseEvent(mouse);
	/// 	// rest of the code for mouse event here
	/// }
	/// ```
	MouseEventFuction customMouseEvent;
	
	/// custom keyboard event, if not null, it should be called before doing anything else in keyboardEvent.
	/// 
	/// Like:
	/// ```
	/// override void keyboardEvent(KeyPress key){
	/// 	super.keyboardEvent(key);
	/// 	// rest of the code for keyboard event here
	/// }
	/// ```
	KeyboardEventFunction customKeyboardEvent;

	/// custom resize event, if not null, it should be called before doing anything else in resize().
	/// 
	/// Like:
	/// ```
	/// override void resize(){
	/// 	super.resize();
	/// 	// rest of the code for resize here
	/// }
	/// ```
	ResizeEventFunction customResizeEvent;

	/// custom onActivate event, if not null, it should be called before doing anything else in activateEvent
	/// 
	/// Like:
	/// ```
	/// override void activateEvent(){
	/// 	super.activateEvent();
	/// 	// rest of the code for resize here
	/// }
	/// ```
	ActivateEventFunction customActivateEvent;
public:
	/// Called by owner when mouse is clicked with cursor on this widget.
	/// 
	/// Must be inherited like:
	/// ```
	/// 	override void mouseEvent(MouseClick mouse){
	/// 		super.mouseEvent(mouse);
	/// 		// code to handle this event here
	/// 	}
	/// ```
	/// `forceUpdate` is not required in this. if `forceUpdate` is called in this, it will have no effect
	void mouseEvent(MouseClick mouse){
		if (customMouseEvent !is null){
			customMouseEvent(mouse);
		}
	}
	
	/// Called by owner when key is pressed and this widget is active.
	/// 
	/// Must be inherited like:
	/// ```
	/// 	override void keyboardEvent(KeyPress key){
	/// 		super.keyboardEvent(key);
	/// 		// code to handle this event here
	/// 	}
	/// ```
	/// `forceUpdate` is not required in this. if `forceUpdate` is called in this, it will have no effect
	void keyboardEvent(KeyPress key){
		if (customKeyboardEvent !is null){
			customKeyboardEvent(key);
		}
	}

	/// called by owner after the widget is resized.
	/// 
	/// Must be inherited, only if inherited, like:
	/// ```
	/// 	override void resizeEvent(){
	/// 		super.resizeEvent(key);
	/// 		// code to handle this event here
	/// 	}
	/// ```
	/// `forceUpdate` is not required in this. if `forceUpdate` is called in this, it will have no effect
	void resizeEvent(){
		if (customResizeEvent !is null){
			customResizeEvent(widgetSize);
		}
		needsUpdate = true;
	}

	/// called by QTerminal right after this widget is activated, or de-activated, i.e: is made activeWidget, or un-made activeWidget
	/// 
	/// Must be inherited, only if inherited, like:
	/// ```
	/// 	override void activateEvent(){
	/// 		super.activateEvent(key);
	/// 		// code to handle this event here
	/// 	}
	/// ```
	/// `forceUpdate` is not required in this. if `forceUpdate` is called in this, it will have no effect
	void activateEvent(bool isActive){
		if (customActivateEvent){
			customActivateEvent(isActive);
		}
	}

	/// Returns: whether the widget is receiving the Tab key press or not
	@property bool wantsTab(){
		return widgetWantsTab;
	}
	
	/// Returns: whether the widget wants input
	@property bool wantsInput(){
		return widgetWantsInput;
	}

	/// Returns: whether the widget needs to show a cursor, only considered when this widget is active
	@property bool showCursor(){
		return widgetShowCursor;
	}
	
	/// Called by owner to update.
	/// 
	/// Return false if no need to update, and true if an update is required, and the new display in `display` Matrix
	abstract bool update(Matrix display);
	
	//event properties
	/// use to change the custom mouse event
	@property MouseEventFuction onMouseEvent(MouseEventFuction func){
		return customMouseEvent = func;
	}
	/// use to change the custom keyboard event
	@property KeyboardEventFunction onKeyboardEvent(KeyboardEventFunction func){
		return customKeyboardEvent = func;
	}
	/// use to change the custom resize event
	@property ResizeEventFunction onResizeEvent(ResizeEventFunction func){
		return customResizeEvent = func;
	}
	/// use to change the custom activate event
	@property ActivateEventFunction onActivateEvent(ActivateEventFunction func){
		return customActivateEvent = func;
	}
	
	
	//properties:

	/// needsUpdate - whether the widget needs to update or not
	@property bool needsUpdate(){
		widgetNeedsUpdate = (this.size.sizeChanged ? true : widgetNeedsUpdate);
		return widgetNeedsUpdate;
	}

	/// needsUpdate - whether the widget needs to update or not
	@property bool needsUpdate(bool newVal){
		size.sizeChanged; // to mark sizeChanged false
		return widgetNeedsUpdate = newVal;
	}
	
	/// caption of the widget. getter
	@property string caption(){
		return widgetCaption;
	}
	/// caption of the widget. setter
	@property string caption(string newCaption){
		needsUpdate = true;
		widgetCaption = newCaption;
		// force an update
		termInterface.forceUpdate();
		return widgetCaption;
	}
	
	/// position of the widget. getter
	@property ref Position position(){
		return widgetPosition;
	}
	/// position of the widget. setter
	@property ref Position position(Position newPosition){
		widgetPosition = newPosition;
		// force an update
		termInterface.forceUpdate();
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
		// force an update
		termInterface.forceUpdate();
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
		// force an update
		termInterface.forceUpdate();
		return widgetShow;
	}
	
	/// called by owner to set the `termInterface`, which widget uses to call some functions on terminal
	/// 
	/// **Should __NEVER__ be called from outside, only the owner should call this**
	@property QTermInterface setTermInterface(QTermInterface newInterface){
		termInterface = newInterface;
		// register itself
		termInterface.registerWidget(this);
		return termInterface;
	}
	/// size of the widget. getter
	@property ref Size size(){
		return widgetSize;
	}
	/// size of the widget. setter
	@property ref Size size(Size newSize){
		return widgetSize = newSize;
	}
}

/// Layout type
enum LayoutDisplayType{
	Vertical,
	Horizontal,
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
	// stores the layout type, horizontal or vertical
	LayoutDisplayType layoutType;
	// stores whether an update is in progress
	bool isUpdating = false;
	
	// recalculates the size of every widget inside layout
	void recalculateWidgetsSize(LayoutDisplayType T)(QWidget[] widgets, uinteger totalSpace, uinteger totalRatio){
		static if (T != LayoutDisplayType.Horizontal && T != LayoutDisplayType.Vertical){
			assert(false);
		}
		bool repeat;
		do{
			repeat = false;
			foreach(i, widget; widgets){
				if (widget.visible){
					// calculate width or height
					uinteger newSpace = ratioToRaw(widget.sizeRatio, totalRatio, totalSpace);
					uinteger calculatedSpace = newSpace;
					//apply size
					static if (T == LayoutDisplayType.Horizontal){
						widget.size.height = widgetSize.height;
						widget.size.width = newSpace;
						newSpace = widget.size.width;
					}else{
						widget.size.width = widgetSize.width;
						widget.size.height = newSpace;
						newSpace = widget.size.height;
					}
					if (newSpace != calculatedSpace){
						totalRatio -= widget.sizeRatio;
						totalSpace -= newSpace;
						widgets = widgets.dup.deleteElement(i);
						repeat = true;
						break;
					}
					// check if there's enough space to contain that widget
					if (newSpace > totalSpace){
						newSpace = 0;
						widget.visible = false;
					}
				}
			}
		} while (repeat);
	}
	/// calculates and assigns widgets positions based on their sizes
	void recalculateWidgetsPosition(LayoutDisplayType T)(QWidget[] widgets){
		static if (T != LayoutDisplayType.Horizontal && T != LayoutDisplayType.Vertical){
			assert(false);
		}
		uinteger previousSpace = (T == LayoutDisplayType.Horizontal ? widgetPosition.x : widgetPosition.y);
		uinteger fixedPoint = (T == LayoutDisplayType.Horizontal ? widgetPosition.y : widgetPosition.x);
		foreach(widget; widgets){
			if (widget.visible){
				static if (T == LayoutDisplayType.Horizontal){
					widget.position.y = widgetPosition.y;
					widget.position.x = previousSpace;
					previousSpace += widget.size.width;
				}else{
					widget.position.x = widgetPosition.x;
					widget.position.y = previousSpace;
					previousSpace += widget.size.height;
				}
			}
		}
	}
	
public:
	this(LayoutDisplayType type){
		layoutType = type;
		widgetWantsInput = false;
	}
	
	/// adds (appends) a widget to the widgetList, and makes space for it
	/// 
	/// If there a widget is too large, it's marked as not visible
	void addWidget(QWidget widget){
		widget.setTermInterface = termInterface;
		//add it to array
		widgetList ~= widget;
		//recalculate all widget's size to adjust
		resizeEvent();
	}
	/// adds (appends) widgets to the widgetList, and makes space for them
	/// 
	/// If there a widget is too large, it's marked as not visible
	void addWidget(QWidget[] widgets){
		foreach(widget; widgets){
			widget.setTermInterface = termInterface;
		}
		// add to array
		widgetList ~= widgets.dup;
		//resize
		resizeEvent();
	}
	
	/// Recalculates size and position for all visible widgets
	/// If a widget is too large to fit in, it's visibility is marked false
	override void resizeEvent(){
		//disable update during size change, saves CPU and time
		super.resizeEvent();
		isUpdating = true;
		uinteger ratioTotal;
		foreach(w; widgetList){
			if (w.visible()){
				ratioTotal += w.sizeRatio;
			}
		}
		if (layoutType == LayoutDisplayType.Horizontal){
			recalculateWidgetsSize!(LayoutDisplayType.Horizontal)(widgetList, widgetSize.width, ratioTotal);
			recalculateWidgetsPosition!(LayoutDisplayType.Horizontal)(widgetList);
		}else{
			recalculateWidgetsSize!(LayoutDisplayType.Vertical)(widgetList, widgetSize.height, ratioTotal);
			recalculateWidgetsPosition!(LayoutDisplayType.Vertical)(widgetList);
		}
		foreach (widget; widgetList){
			widget.resizeEvent;
		}
		isUpdating = false;
	}
	override bool update(Matrix display){
		bool updated = false;
		//check if already updating, case yes, return false
		if (!isUpdating){
			isUpdating = true;
			//go through all widgets, check if they need update, update them
			Matrix wDisplay = new Matrix(1,1);
			foreach(widget; widgetList){
				if (widget.visible){
					wDisplay.changeSize(widget.size.width, widget.size.height);
					wDisplay.resetWritePosition();
					if (widget.update(wDisplay)){
						display.insert(wDisplay, widget.position.x - this.position.x,
							widget.position.y - this.position.y);
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

	// override setTermInterface to change it for all child widgets as well
	/// 
	/// **Should __NEVER__ be called from outside, only the owner should call this**
	override public @property QTermInterface setTermInterface(QTermInterface newInterface){
		// change it for itself
		auto r = super.setTermInterface(newInterface);
		// change it for all child widgets
		foreach(widget; widgetList){
			widget.setTermInterface = termInterface;
		}
		// register itself
		termInterface.registerWidget(this);
		return r;
	}
}

/// Provides interface to the QTerminal for widgets
struct QTermInterface{
	/// the terminal to provide interface to
	private QTerminal term;
	/// constructor
	this (QTerminal terminal){
		term = terminal;
	}
	/// called to set position of the cursor
	/// 
	/// Returns: true on success, false on failure, probably because caller isnt activeWidget
	bool setCursorPos(Position cursorPos, QWidget callerWidget){
		if (term)
			return term.setCursorPos(cursorPos.x, cursorPos.y, callerWidget);
		return false;
	}
	/// used to set "hotkey", so each a key is pressed, a specific widget's keyboardEvent will be triggered
	/// 
	/// Returns: true on success, false on failure, probably because the key is already registered
	bool setKeyHandler(KeyPress key, QWidget handlerWidget){
		if (term)
			return term.registerKeyHandler(key, handlerWidget);
		return false;
	}
	/// registers a new widget with the terminal. For a widget to be active, it must be registered first
	void registerWidget(QWidget newWidget){
		if (term)
			term.registerWidget(newWidget);
	}
	/// forces an update of the terminal, only widgets that need update will be updated.
	/// 
	/// Returns: true if at least one widget was updated, otherwise, false
	bool forceUpdate(){
		if (term)
			return term.updateDisplay;
		return false;
	}
	/// Returns: true if a widget is active widget
	bool isActiveWidget(QWidget widget){
		if (term){
			return term.isActiveWidget(widget);
		}
		return false;
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
	/// the Matrix in which all the terminal's content lives
	Matrix termDisplay;
	/// stores the position of the mouse cursor
	Position cursorPos;
	/// used to terminate the run-loop
	bool isRunning = false;
	/// array containing registered widgets
	QWidget[] registeredWidgets;
	/// stores the index of the active widget, which is in `registeredWidgets`, <0 if none
	integer activeWidgetIndex = -1;
	// contains reference to the active widget, null if no active widget
	QWidget activeWidget;
	/// stores list of keys and widgets that will catch their KeyPress event
	QWidget[KeyPress] keysToCatch;
	/// colors
	RGB textColor, bgColor;

	/// Called by QTermInterface to position the cursor, only the activeWidget can change the cursorPos
	/// 
	/// Returns: true on success, false on failure
	bool setCursorPos(uinteger x, uinteger y, QWidget callerWidget){
		if (activeWidget && callerWidget == activeWidget){
			cursorPos.x = activeWidget.position.x + x;
			cursorPos.y = activeWidget.position.y + y;
			return true;
		}
		return false;
	}

	/// registers a key with a widget, so regardless of activeWidget, that widget will catch that key's KeyPress event
	/// 
	/// Returns:  true on success, false on failure, which can occur because that key is already registered
	bool registerKeyHandler(KeyPress key, QWidget widget){
		if (key in keysToCatch){
			return false;
		}else{
			keysToCatch[key] = widget;
			return true;
		}
	}

	/// registers a new widget with the terminal. For a widget to be active, it must be registered first
	void registerWidget(QWidget newWidget){
		registeredWidgets ~= newWidget;
	}

	/// Returns: true if a widget is active widget
	bool isActiveWidget(QWidget widget){
		if (activeWidget && widget == activeWidget){
			return true;
		}
		return false;
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
	void setColors(RGB textColor, RGB bgColor){
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
	/// Use this instead of `update` to forcefully update the terminal
	/// 
	/// returns true if at least one widget was updated, false if nothing was updated
	bool updateDisplay(){
		if (isRunning && !isUpdating){
			bool r = update(termDisplay);
			if (r){
				terminal.moveTo(0, 0);
				termDisplay.flushToTerminal(this);
			}
			//set cursor position
			if (activeWidget && activeWidget.showCursor){
				terminal.moveTo(cast(int)cursorPos.x, cast(int)cursorPos.y);
				terminal.showCursor();
			}else{
				terminal.hideCursor();
			}
			return r;
		}else{
			return false;
		}
	}
public:
	this(string caption = "QUI Text User Interface", LayoutDisplayType displayType = LayoutDisplayType.Vertical){
		super(displayType);
		//create terminal & input
		terminal = Terminal(ConsoleOutputType.cellular);
		input = RealTimeConsoleInput(&terminal, ConsoleInputFlags.allInputEvents);
		terminal.showCursor();
		//init vars
		termInterface = QTermInterface(this);
		widgetSize.height = terminal.height;
		widgetSize.width = terminal.width;
		widgetCaption = caption;
		//set caption
		terminal.setTitle(widgetCaption);
		//create display matrix
		termDisplay = new Matrix(widgetSize.width, widgetSize.height);
		termDisplay.setColors(textColor, bgColor);
	}
	~this(){
		terminal.clear;
		delete termDisplay;
	}
	
	override public void addWidget(QWidget widget){
		super.addWidget(widget);
		widget.setTermInterface = termInterface;
	}
	override public void addWidget(QWidget[] widgets){
		super.addWidget(widgets);
		foreach (widget; widgets){
			widget.setTermInterface = termInterface;
		}
	}
	
	override public void mouseEvent(MouseClick mouse){
		super.mouseEvent(mouse);
		QWidget lastActiveWidget = activeWidget;
		activeWidget = null;
		activeWidgetIndex = -1;
		foreach (i, widget; registeredWidgets){
			if (widget.visible && widget.wantsInput){
				Position p = widget.position;
				Size s = widget.size;
				//check x-axis
				if (mouse.x >= p.x && mouse.x < p.x + s.width){
					//check y-axis
					if (mouse.y >= p.y && mouse.y < p.y + s.height){
						//mark this widget as active
						activeWidget = widget;
						activeWidgetIndex = i;
						// make mouse position relative to widget position, not 0:0
						mouse.x = mouse.x - activeWidget.position.x;
						mouse.y = mouse.y - activeWidget.position.y;
						//call mouseEvent
						widget.mouseEvent(mouse);
						break;
					}
				}
			}
		}
		if (activeWidget != lastActiveWidget){
			if (lastActiveWidget){
				lastActiveWidget.activateEvent(false);
			}
			if (activeWidget){
				activeWidget.activateEvent(true);
			}
		}
	}

	override public void keyboardEvent(KeyPress key){
		super.keyboardEvent(key);
		// check if the activeWidget wants Tab, otherwise, if is Tab, make the next widget active
		if (key.key == KeyPress.NonCharKey.Escape || (key.key == '\t' && (activeWidgetIndex < 0 || !activeWidget.wantsTab))){
			QWidget lastActiveWidget = activeWidget;
			// make the next widget active
			if (registeredWidgets.length > 0){
				activeWidgetIndex ++;
				if (activeWidgetIndex > registeredWidgets.length){
					activeWidgetIndex = 0;
				}
				// see if it wants input, case no, switch to some other widget
				for (;activeWidgetIndex < registeredWidgets.length; activeWidgetIndex ++){
					if (registeredWidgets[activeWidgetIndex].wantsInput && registeredWidgets[activeWidgetIndex].visible){
						break;
					}
				}
				if (activeWidgetIndex < registeredWidgets.length){
					activeWidget = registeredWidgets[activeWidgetIndex];
				}else{
					activeWidget = null;
					activeWidgetIndex = -1;
				}
			}else{
				activeWidgetIndex = -1;
				activeWidget = null;
			}
			if (activeWidget != lastActiveWidget){
				if (lastActiveWidget){
					lastActiveWidget.activateEvent(false);
				}
				if (activeWidget){
					activeWidget.activateEvent(true);
				}
			}
		}else if (key in keysToCatch){
			// this is a registered key, only a specific widget catches it
			keysToCatch[key].keyboardEvent(key);
		}else if (activeWidget !is null){
			activeWidget.keyboardEvent (key);
		}
	}

	
	/// starts the UI loop
	void run(){
		InputEvent event;
		isRunning = true;
		//resize all widgets
		resizeEvent();
		//draw the whole thing
		updateDisplay();
		while (isRunning){
			event = input.nextEvent;
			//check event type
			if (event.type == event.Type.KeyboardEvent){
				// prevent any updates during event, the update will be done at end
				isUpdating = true;
				KeyPress kPress;
				kPress.key = event.get!(event.Type.KeyboardEvent).which;
				this.keyboardEvent(kPress);
				// now it can update
				isUpdating = false;
				updateDisplay;
			}else if (event.type == event.Type.MouseEvent){
				// prevent any updates during event, the update will be done at end
				isUpdating = true;
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
				// now it can update
				isUpdating = false;
				updateDisplay;
			}else if (event.type == event.Type.SizeChangedEvent){
				//change matrix size
				termDisplay.changeSize(cast(uinteger)terminal.width, cast(uinteger)terminal.height);
				termDisplay.setColors(textColor, bgColor);
				//update self size
				terminal.updateSize;
				widgetSize.height = terminal.height;
				widgetSize.width = terminal.width;
				this.clear;
				//call size change on all widgets
				resizeEvent();
				updateDisplay;
			}else if (event.type == event.Type.UserInterruptionEvent || event.type == event.Type.HangupEvent){
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
	
	///returns true if UI loop is running
	@property bool running(){
		return isRunning;
	}
}

/// Used to manage the characters on the terminal
class Matrix{
private:
	struct Display{
		uinteger x, y;
		RGB bgColor, textColor;
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
	void write(char[] c, RGB textColor, RGB bgColor){
		//get available cells
		uinteger cells = (matrixHeight - yPosition) * matrixWidth;// first get the whole area
		cells -= xPosition;//subtract partial-lines
		if (c.length > cells){
			c = c[0 .. cells];
		}
		if (c.length > 0){
			uinteger toAdd = xPosition + (yPosition * matrixWidth);
			Display disp;
			disp.bgColor = bgColor;
			disp.textColor = textColor;
			for (uinteger i = 0, readFrom = 0, end = c.length+1; i < end; i ++){
				if ((i+toAdd)%matrixWidth == 0 || i == c.length){
					//line ended, append it
					disp.x = (readFrom+toAdd)%matrixWidth;
					disp.y = (readFrom+toAdd)/matrixWidth;
					disp.content = c[readFrom .. i].dup;
					if (disp.content != null){
						toUpdate.append(disp);
						readFrom = i;
					}
				}
			}
			// update x and y positions
			xPosition = (c.length+toAdd)%matrixWidth;
			yPosition = (c.length+toAdd)/matrixWidth;
		}
	}
	/// Changes the matrix's colors. Must be called before any writing has taken place
	void setColors(RGB textColor, RGB bgColor){
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
		if (x < matrixWidth && y < matrixHeight){
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
		Display[] newMatrix = toInsert.toArray.dup;
		// go through the new Displays and increae their x and y, and append them
		foreach (disp; newMatrix){
			disp.y += y;
			disp.x += x;
			
			toUpdate.append(disp);
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

///Converts hex color code to RGB
RGB hexToColor(string hex){
	RGB r;
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
	RGB c;
	c.r = 10;
	c.g = 15;
	c.b = 0;
	assert("0A0F00".hexToColor == c);
}

///Converts RGB to hex color code
string colorToHex(RGB col){
	uinteger den;
	den = col.b;
	den += col.g*256;
	den += col.r*65536;
	return denaryToHex(den);
}
///
unittest{
	RGB c;
	c.r = 10;
	c.g = 8;
	c.b = 12;
	assert(c.colorToHex == "A080C");
}
