module qui;

import misc;
import arsd.terminal;

//MouseClick event
struct MousePosition{
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
struct Color{
	ubyte r, g, b;
	//not used but required for compatibility with RGB
	ubyte a;
}


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
//To specify alignment in QWidget
union Align{
	VerticalAlign vAlign;
	HorizontalAlign hAlign;
}


//base class for all widgets, including layouts
abstract class QWidget{
private:
	uinteger x = 0, y = 0;
	uinteger width, height, maxWidth, maxHeight, minWidth, minHeight;//0 = no limit
	string captionText;

	//so Widget can send updateTerminal
	QLayout* ownerLayout;
public:
	//constructor, to define owner and ownerTerminal
	this(QLayout* layout){
		ownerLayout = layout;
	}
	//called when mouse is clicked with cursor on widget
	void onClick(MousePosition position){

	}
	//called when widget is selected and a key is pressed
	void onKeyPress(KeyPress key){

	}
	//to get X axis position of widget, property setter can be set later, as this is an abstract class
	@property uinteger positionX(){ return x; }
	//to get Y axis position of widget, property setter can be set later, as this is an abstract class
	@property uinteger positionY(){ return y; }
	@property string caption(){ return captionText; }

}

//to contain widgets in an order
class QLayout : QWidget{
private:
	QWidget[] widgetList;
	Terminal* ownerTerminal;
	QLayout* ownerLayout;
	LayoutDisplayType layoutType;
public:
	enum LayoutDisplayType{
		Vertical,
		Horizontal,
		Cellular
	}
	this(QLayout* layout, LayoutDisplayType type){
		super(layout);
		layoutType = type;
	}
	void update(/*QWidget caller*/){
		//update self

	}
	//Functions for childWidgets to call to write
	void writeChars(char[] c){
		if (ownerTerminal){

		}

	}
}

class QTerminal{
private:
	Terminal* terminal;
	RealTimeConsoleInput* input;

	QWidget[] widgetList;
	uinteger height, width;
	string captionText;
public:
	this(string caption = "QUI Text User Interface"){
		//create terminal & input
		*terminal = Terminal(ConsoleOutputType.cellular);
		*input = RealTimeConsoleInput(terminal, ConsoleInputFlags.allInputEvents);
		//init vars
		height = terminal.height;
		width = terminal.width;
		captionText = caption;
	}
	~this(){
		terminal.clear;
	}

	void writeChars(char[] c){
		terminal.write(c);
	}
	void setColors(Color textColor, Color bgColor){
		//terminal.setTrueColor(textColor, bgColor);
	}
	void update(/*QWidget caller*/){
		terminal.flush;
	}
}