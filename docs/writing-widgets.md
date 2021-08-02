# Writing QUI widgets

This guide will help you understand how to write QUI widgets.

# QWidget properties

## `public QWidget parent` _(read only)_;
This returns the parent widget. This property is only valid after `initialize()` has been called.

## `public bool isActive` _(read only)_;
Returns whether this widget is active or not. Read only.

## `public bool wantsTab`;
This should return true if the widget wants to receive tab character as input.

## `public bool wantsInput`;
should return true if a widget needs keyboard and mouse input. If this is false, those events will not be called and this widget cannot become active.

## `public Position cursorPosition`;
Return the position of cursor to be displayed on terminal. This is only considered if this widget is active.  
In case the cursor should not be displayed, this should return `Position(-1, -1)`;  

Rather than overriding this to return desired cursor position, you could store the desired value in `protected _cursorPosition`.

## `public uint sizeRatio`;
QUI sizes widget using a "ratio" system. For example, in a Horizontal layout, if two widget have _sizeRatio's 
of `1`, they will each occupy 50% of the horizonal space.  

## `public bool show`;
Whether this widget is displayed or not.  

But be aware that a widget with `show=false` can not become an activeWidget and cannot receive input.  
  
A parent widget may also set this to false in case there is not enough space to draw this widget.

## `protected Size _size`; // TODO fix this
This stores the `width` and `height` along with `minWidth`, `minHeight`, `maxWidth`, & `maxHeight`.  

Modify this through the public property function `QWidget.size = x;` so that `QWidget.requestResize()` is called.

# Events

See `events.md` for documentation on events and custom event handlers.

# Drawing on Terminal

The `update()` delegate of a widget is called by it's parent widget each time the widget should re-draw itself.
The parent widget only calls this function if the widget has previously called `this.requestUpdate`.  

Keep in mind that the widget should not draw outside of the `update()` delegate as that can cause issues like segfaults, for example if it hasn't been initialized yet.  

All drawing on terminal is done through the `Display` class, an instance of this class is stored as `protected Display _display;` in each widget.  

This allows each widget to draw over a rectangular area assigned to it by the parent widget.  

This class provides several functions for drawing to terminal:  

## `cursor` _(getter/setter)_
This property can be used to read or change the position of cursor (where the next character will be written).  
All positions/coordinates are relative to top left corner of widget (0,0).

## `colors(Color fg, Color bg)`
This will change the foreground color to fg, and background color to bg.

## `write(dstring str)`
writes `str` starting at cursor. If it doesnt fit in current line, it will start at x=0 of next line.
If there are no more lines left, the rest of string will not be written.  

Be sure to call `_display.colors` to change colors at start of `update` if you use this.

## `write (dstring str, Color fg, Color bg)`
Same as above, but changes colors first.

## `fill(dchar c, Color fg, Color bg)`
This will start at cursor position, and fill the rest of area of the widget with the character `c`.

## `fillLine(dchar c, Color fg, Color bg, uint max=0)`
If `max=0`, this will start at cursor, and fill the rest of line with `c`.  

If `max!=0`, and there are more characters in line after cursor, it will only fill `max` number of cells, and move cursor there.