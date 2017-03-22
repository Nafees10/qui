module qui;

import misc;
import lists;
import arsd.terminal;

//MouseClick event
struct MousePosition{
	enum Button{
		Left,
		ScrollUp,
		ScrollDown,
		Right
	}
	Button mouseButton;
	int x;
	int y;
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

//Vertical Alignment for layout
enum HorizontalAlign{
	Top,
	Auto,
	Fill,
	Bottom
}

enum VerticalAlign{
	Left,
	Auto,
	Fill,
	Right
}
///To specify alignment in QWidget
union Align{
	VerticalAlign vAlign;
	HorizontalAlign hAlign;
}

//Position
struct Position{
	int x, y;
}
struct Size{
	uinteger width, height;
	uinteger maxWidth, maxHeight;
	uinteger minWidth, minHeight;
}
//Cell (these will make up the entire terminal display)
struct Cell{
	char c;
	RGBColor textColor;
	RGBColor bgColor;
}


//base class for all widgets, including layouts
abstract class QWidget{
private:
	Position widgetPosition;
	Size widgetSize;
	string widgetCaption;
	bool widgetShow = true;

	//so Widget can call update
	QLayout* owner;
public:
	//constructor, to define owner and ownerTerminal
	this(QLayout* ownerLayout){
		owner = ownerLayout;
	}
	//called by owner when mouse is clicked with cursor on widget
	abstract void onClick(MousePosition cursorPos);
	///called by owner when widget is selected and a key is pressed
	abstract void onKeyPress(KeyPress key);
	///Called by owner when the terminal is updating, use this to update the widget
	abstract void update(ref Matrix display);

	//properties:
	@property string caption(){
		return widgetCaption;
	}
	@property string caption(string newCaption){
		return widgetCaption = newCaption;
	}

	@property Position position(){
		return widgetPosition;
	}
	@property Position position(Position newPosition){
		return widgetPosition = newPosition;
	}

	@property Size size(){
		return widgetSize;
	}
	@property Size size(Size newSize){
		return widgetSize = newSize;
	}
}

//to contain widgets in an order
class QLayout : QWidget{
private:
	QWidget[] widgetList;
	QWidget* activeWidget;
	QTerminal* ownerTerminal;
	QLayout* ownerLayout;
	LayoutDisplayType layoutType;
public:
	enum LayoutDisplayType{
		Vertical,
		Horizontal,
	}
	this(LayoutDisplayType type, QLayout* owner = null){
		super(owner);
		layoutType = type;
	}

	void addWidget(QWidget widget){
		if (layoutType == LayoutDisplayType.Vertical){

		}else if (layoutType == LayoutDisplayType.Horizontal){

		}
	}

	void onClick(MousePosition cursorPos){
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
			if (cursorPos.x >= p.x && cursorPos.x < p.x + s.width){
				//check y-axis
				if (cursorPos.y >= p.y && cursorPos.y < p.y + s.height){
					//then this is the widget
					//mark this widget as active
					activeWidget = &widget;
					//and call onClick
					widget.onClick(cursorPos);
					break;
				}
			}
		}
	}
	void onKeyPress(KeyPress key){
		//check active widget, call onKeyPress
		if (activeWidget !is null){
			activeWidget.onKeyPress(key);
		}
	}
	void update(ref Matrix display){

	}
}

class QTerminal : QLayout{
private:
	Terminal terminal;
	RealTimeConsoleInput input;
	bool isRunning = false;
	//QWidget[] widgetList;
public:
	this(string caption = "QUI Text User Interface", LayoutDisplayType displayType = LayoutDisplayType.Vertical){
		super(displayType, null);
		//create terminal & input
		terminal = Terminal(ConsoleOutputType.cellular);
		input = RealTimeConsoleInput(&terminal, ConsoleInputFlags.allInputEvents);
		//init vars
		widgetSize.height = terminal.height;
		widgetSize.width = terminal.width;
		widgetCaption = caption;
		//set caption
		terminal.setTitle(widgetCaption);
	}
	~this(){
		terminal.clear;
	}

	void run(){
		InputEvent event;
		isRunning = true;
		while (isRunning){
			event = input.nextEvent;
			//check event type
			if (event.type == event.Type.KeyboardEvent){
				KeyPress kPress;
				kPress.key = event.get!(event.Type.KeyboardEvent).which;
				this.onKeyPress(kPress);
			}else if (event.type == event.Type.MouseEvent){
				MouseEvent mEvent = event.get!(event.Type.MouseEvent);
				if (mEvent.buttons != MouseEvent.Button.None){
					MousePosition mPos;
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
					this.onClick(mPos);
				}
			}else if (event.type == event.Type.SizeChangedEvent){
				this.update;
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
	void update(){
		terminal.flush;
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
private uinteger percentToRaw(uinteger percent, uinteger total){
	uinteger r;
	r = cast(uinteger)((cast(float)percent/cast(float)100)*total);
	return r;
}