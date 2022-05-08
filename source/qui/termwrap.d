/++
	This module just tries to simplify arsd.terminal.d by removing some features that aren't needed (yet, at least)
+/
module qui.termwrap;

import arsd.terminal;
import std.datetime.stopwatch;
import std.conv : to;

public alias Color = arsd.terminal.Color;

/// Input events
public struct Event{
	/// Keyboard Event
	struct Keyboard{
		private this(KeyboardEvent event){
			key = event.which;
			state = event.pressed ? State.Pressed : State.Released;
		}
		//// what key was pressed
		dchar key;
		/// possible states
		enum State : ubyte{
			Pressed = 1 << 3,  // key pressed
			Released = 1 << 4 // key released
		}
		/// state
		ubyte state;
		/// Non character keys (can match against `this.key`)
		/// 
		/// copied from arsd.terminal
		enum Key : dchar{
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
		/// Ctrl+Letter keys
		enum CtrlKeys : dchar{
			CtrlA = 1,
			CtrlB = 2,
			CtrlC = 3,
			CtrlD = 4,
			CtrlE = 5,
			CtrlF = 6,
			CtrlG = 7,
			//CtrlJ = 10,
			CtrlK = 11,
			CtrlL = 12,
			CtrlM = 13,
			CtrlN = 14,
			CtrlO = 15,
			CtrlP = 16,
			CtrlQ = 17,
			CtrlR = 18,
			CtrlS = 19,
			CtrlT = 20,
			CtrlU = 21,
			CtrlV = 22,
			CtrlW = 23,
			CtrlX = 24,
			CtrlY = 25,
			CtrlZ = 26,
		}
		/// Returns: true if the key pressed is a character
		/// backspace, space, and tab are characters!
		@property bool isChar(){
			return !(key >= Key.min && key <= Key.max) && !isCtrlKey();
		}
		/// Returns: true if key is a Ctrl+Letter key
		@property bool isCtrlKey(){
			return key >= CtrlKeys.min && key <= CtrlKeys.max && key!=8 && key!=9 && key!=10;
		}
		/// Returns: a string representation of the key pressed
		@property string tostring(){
			if (isChar())
				return "{key:\'"~to!string(key)~"\', state:"~state.to!string~"}";
			if (isCtrlKey())
				return "{key:\'"~to!string(cast(CtrlKeys)key)~"\', state:"~state.to!string~"}";
			return "{key:\'"~to!string(cast(Key)key)~"\', state:"~state.to!string~"}";
		}
	}
	/// Mouse Event
	struct Mouse{
		/// Buttons
		enum Button : ubyte{
			Left 		=	0x00, /// Left mouse btn clicked
			Right 		=	0x10, /// Right mouse btn clicked
			Middle 		= 	0x20, /// Middle mouse btn clicked
			ScrollUp 	=	0x30, /// Scroll up clicked
			ScrollDown 	= 	0x40, /// Scroll Down clicked
			None 		=	0x50, /// .
		}
		/// State
		enum State : ubyte{
			Click	=	1, /// Clicked
			Release	=	1 << 1, /// Released
			Hover	=	1 << 2, /// Hovered
		}
		/// x and y position of cursor
		int x, y;
		/// button and type (press/release/hover)
		/// access this using `this.button` and `this.state`
		ubyte type;
		/// what button was clicked
		@property Button button(){
			return cast(Button)(type & 0xF0);
		}
		/// ditto
		@property Button button(Button newVal){
			type = this.state | newVal;
			return newVal;
		}
		/// State (Clicked/Released/...)
		@property State state(){
			return cast(State)(type & 0x0F);
		}
		/// ditto
		@property State state(State newVal){
			type = this.button | newVal;
			return newVal;
		}
		/// constructor
		this (Button btn, int xPos, int yPos){
			x = xPos;
			y = yPos;
			btn = button;
		}
		/// constructor, from arsd.terminal.MouseEvent
		private this(MouseEvent mouseE){
			if (mouseE.buttons & MouseEvent.Button.Left)
				this.button = this.Button.Left;
			else if (mouseE.buttons & MouseEvent.Button.Right)
				this.button = this.Button.Right;
			else if (mouseE.buttons & MouseEvent.Button.Middle)
				this.button = this.Button.Middle;
			else if (mouseE.buttons & MouseEvent.Button.ScrollUp)
				this.button = this.Button.ScrollUp;
			else if (mouseE.buttons & MouseEvent.Button.ScrollDown)
				this.button = this.Button.ScrollDown;
			else
				this.button = this.Button.None;
			if (mouseE.eventType == mouseE.Type.Clicked || mouseE.eventType == mouseE.Type.Pressed)
				this.state = State.Click;
			else if (mouseE.eventType == mouseE.Type.Released)
				this.state = State.Release;
			else
				this.state = State.Hover;
			this.x = mouseE.x;
			this.y = mouseE.y;
		}
		/// Returns: string representation of this
		@property string tostring(){
			return "{button:"~button.to!string~", state:"~state.to!string~", x:"~x.to!string~", y:"~y.to!string~"}";
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
		_input = RealTimeConsoleInput(&_term,ConsoleInputFlags.allInputEventsWithRelease | ConsoleInputFlags.raw);
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
	/// flush to terminal
	void flush(){
		_term.flush();
	}
	/// writes a character `ch` at a position `(x, y)`
	void put(int x, int y, dchar ch){
		_term.moveTo(x, y);
		_term.write(ch);
	}
	/// sets colors
	void color(Color fg, Color bg){
		_term.color(fg, bg);
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
		while (msecTimeout - cast(int)sw.peek.total!"msecs" > 0){
			if (_input.timedCheckForInput(msecTimeout - cast(int)sw.peek.total!"msecs")){
				InputEvent e = _input.nextEvent;
				if (e.type == InputEvent.Type.HangupEvent || e.type == InputEvent.Type.UserInterruptionEvent){
					event = Event(Event.Type.HangupInterrupt);
					return true;
				}
				if (e.type == InputEvent.Type.KeyboardEvent /*&& e.get!(InputEvent.Type.KeyboardEvent).pressed*/){
					event = Event(Event.Keyboard(e.get!(InputEvent.Type.KeyboardEvent)));
					// fix for issue #16 ("Escape key registered as a character event as well")
					if (event._key.key == 27)
						continue;
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