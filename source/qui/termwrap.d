/++
	This module just tries to simplify arsd.terminal.d by removing some features that aren't needed (yet, at least)
+/
module qui.termwrap;

import arsd.terminal;
import std.datetime.stopwatch;

public alias Color = arsd.terminal.Color;

/// Input events
public struct Event{
	/// Keyboard Event
	struct Keyboard{
		//// what key was pressed
		dchar key;
		/// Non character keys (can match against `this.key`)
		/// 
		/// copied from arsd.terminal
		enum Key{
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
		/// Returns: true if the key pressed is a character
		/// backspace, space, and tab are characters!
		@property bool isChar(){
			return !(key >= Key.min && key <= Key.max);
		}
	}
	/// Mouse Event
	struct Mouse{
		/// Buttons
		enum Button{
			Left, /// Left mouse btn clicked
			Right, /// Right mouse btn clicked
			Middle, /// Middle mouse btn clicked
			ScrollUp, /// Scroll up clicked
			ScrollDown, /// Scroll Down clicked
			None, /// no button pressed, mouse was hovered
		}
		/// x and y position of cursor
		int x, y;
		/// what button was clicked
		Button button;
		/// constructor
		this (Button btn, int xPos, int yPos){
			x = xPos;
			y = yPos;
			btn = button;
		}
		/// constructor, from arsd.terminal.MouseEvent
		private this(MouseEvent mouseE){
			if (mouseE.buttons == MouseEvent.Button.Left)
				this.button = this.Button.Left;
			else if (mouseE.buttons == MouseEvent.Button.Right)
				this.button = this.Button.Right;
			else if (mouseE.buttons == MouseEvent.Button.Middle)
				this.button = this.Button.Middle;
			else if (mouseE.buttons == MouseEvent.Button.ScrollUp)
				this.button = this.Button.ScrollUp;
			else if (mouseE.buttons == MouseEvent.Button.ScrollDown)
				this.button = this.Button.ScrollDown;
			else if (mouseE.buttons == MouseEvent.Button.None)
				this.button = this.Button.None;
			this.x = mouseE.x;
			this.y = mouseE.y;
		}
	}
	/// Resize event
	struct Resize{
		/// the new width and height after resize
		int width, height;
	}
	/// types of events
	enum Type{
		Keyboard, /// Keyboard event
		Mouse, /// Mouse event
		Resize, /// Resize event
		HangupInterrupt, /// terminal closed or interrupt (Ctrl+C)
	}
	/// stores the type of event
	private Type _type;
	/// union to store events
	union{
		Keyboard _key; /// stores keyboard event
		Mouse _mouse; /// stores mouse event
		Resize _resize; /// stores resize event
	}
	/// Returns: type of event
	@property Type type(){
		return _type;
	}
	/// Returns: keyboard event. Make sure you check this.type so the wrong event isn't read
	@property Keyboard keyboard(){
		return _key;
	}
	/// Returns: mouse event. Make sure you check this.type so the wrong event isn't read
	@property Mouse mouse(){
		return _mouse;
	}
	/// Returns: resize event. Make sure you check this.type so the wrong event isn't read
	@property Resize resize(){
		return _resize;
	}

	private this(Keyboard key){
		this._type = Type.Keyboard;
		this._key = key;
	}

	private this(Mouse mouse){
		this._type = Type.Mouse;
		this._mouse = mouse;
	}

	private this(Resize rsize){
		this._type = Type.Resize;
		this._resize = rsize;
	}
	/// constructor, by default, its a hangupInterrupt
	this(Type eType){
		this._type = eType;
	}
}



/// Wrapper to arsd.terminal to make it bit easier to manage
public class TermWrapper{
private:
	Terminal _term;
	RealTimeConsoleInput _input;
public:
	/// constructor
	this(){
		_term = Terminal(ConsoleOutputType.cellular);
		_input = RealTimeConsoleInput(&_term,ConsoleInputFlags.allInputEvents);
	}
	~this(){
		_term.clear;
		_term.reset;
	}
	/// Returns: width of termial
	@property int width(){
		return _term.width;
	}
	/// Returns: height of terminal
	@property int height(){
		return _term.height;
	}
	/// fills all cells with a character
	void fill(dchar ch){
		const int _w = width, _h = height;
		dchar[] line;
		line.length = _w;
		line[] = ch;
		// write line _h times
		for (uint i = 0; i < _h; i ++){
			_term.moveTo(0,i);
			_term.write(line);
		}
	}
	/// fills a rectangle with a character
	void fill(dchar ch, int x1, int x2, int y1, int y2){
		dchar[] line;
		line.length = (x2 - x1) + 1;
		line[] = ch;
		foreach(i; y1 .. y2 +1){
			_term.moveTo(x1, i);
			_term.write(line);
		}
	}
	/// flush to terminal
	void flush(){
		_term.flush();
	}
	/// writes a character `ch` at a position `(x, y)`
	void put(int x, int y, dchar ch){
		_term.moveTo(x, y);
		_term.write(ch);
	}
	/// writes a character `ch` at a position `(x, y)` with `fg` as foreground and `bg` as background color
	void put(int x, int y, dchar ch, Color fg, Color bg){
		_term.color(fg, bg);
		_term.moveTo(x, y);
		_term.write(ch);
	}
	/// sets colors
	void color(Color fg, Color bg){
		_term.color(fg, bg);
	}
	/// writes a string at position `(x, y)`
	void write(int x, int y, dstring str){
		_term.moveTo(x, y);
		_term.write(str);
	}
	/// writes a string at position `(x, y)` with `fg` as foreground and `bg` as background color
	void write(int x, int y, dstring str, Color fg, Color bg){
		_term.color(fg, bg);
		_term.moveTo(x, y);
		_term.write(str);
	}
	/// moves cursor to position
	void moveCursor(int x, int y){
		_term.moveTo(x, y);
	}
	/// Set true to show cursor, false to hide cursor
	@property bool cursorVisible(bool visibility){
		if (visibility)
			_term.showCursor;
		else
			_term.hideCursor;
		return visibility;
	}
	/// waits `msecTimeout` msecs for event to occur. Returns as soon as it occurs (or if one had occurred before calling it)
	/// 
	/// Returns: true if event occured
	bool getEvent(int msecTimeout, ref Event event){
		StopWatch sw;
		sw.start;
		while (msecTimeout - sw.peek.total!"msecs" > 0){
			if (_input.timedCheckForInput(cast(int)(msecTimeout - sw.peek.total!"msecs"))){
				InputEvent e = _input.nextEvent;
				if (e.type == InputEvent.Type.HangupEvent || e.type == InputEvent.Type.UserInterruptionEvent){
					event = Event(Event.Type.HangupInterrupt);
					return true;
				}
				if (e.type == InputEvent.Type.KeyboardEvent){
					KeyboardEvent ke = e.get!(InputEvent.Type.KeyboardEvent);
					event = Event(Event.Keyboard(ke.which));
					return true;
				}
				if (e.type == InputEvent.Type.MouseEvent){
					MouseEvent mouseE = e.get!(InputEvent.Type.MouseEvent);
					event = Event(Event.Mouse(mouseE));
					return true;
				}else if (e.type == InputEvent.Type.SizeChangedEvent){
					SizeChangedEvent resize = e.get!(InputEvent.Type.SizeChangedEvent);
					event = Event(Event.Resize(resize.newWidth, resize.newHeight));
					return true;
				}
			}
		}
		sw.stop;
		return false;
	}
}