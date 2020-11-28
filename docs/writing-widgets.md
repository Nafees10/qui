# Writing QUI widgets

This guide will help you understand how to write QUI widgets.

# QWidget properties

These properties can be overrided to alter behaviour of parent widget, or the widget:

## QWidget parent;
This stores the parent widget. This property is only valid after `initialize()` has been called.

## bool isActive;
Returns whether this widget is active or not. Read only.

## bool wantsTab;
Returns if a widget wants tab key as keyboard input. If this is active widget, and this is true, tab key will 
not cause active widget cycling, but will instead be considered a keyboard input. Escape key will have to be 
used to active widget cycling.

## bool wantsInput;
should return true if a widget needs keyboard and mouse input. If this is false, those events will not be called 
and this widget cannot become active. To change it's value, change `protected bool _wantsInput;` instead of just
 overriding it.

## Position cursorPosition;
The position of cursor to be displayed on terminal. This is only considered if this widget is active.  
In case the cursor should not be displayed, this should return `Position(-1, -1)`;

## uinteger sizeRatio;
QUI sizes widget using a "ratio" system. For example, in a Horizontal layout, if two widget have _sizeRatio's 
of `1`, they will each occupy 50% of the horizonal space.  
Modifying this will call `QWidget.requestResize()` so that before next update, widgets' sizes are adjusted again.

## bool show;
This can be safely changed to false if the widget has to be hidden. But be aware that a widget with `show=false`
can not become an activeWidget and thus cannot receive input.  
Modifying this will call `QWidget.requestResize()` so that before next update, widgets' sizes are adjusted again.
  
A parent widget may also set this to false in case there is not enough space to draw this widget.

## Size size;
This stores the `width` and `height` along with `minWidth`, `minHeight`, `maxWidth`, & `maxHeight`.  
If this is modified, be sure to call `QWidget.requestResize()` or the the new size will confuse everything.

# Events

See `events.md` for documentation on events and custom event handlers.

# Drawing on Terminal

The `update()` delegate of a widget is called by it's parent widget each time the widget should re-draw 
itself. The parent widget only calls this function if the widget has previously called `this.requestUpdate`.  

Keep in mind that the widget should not draw outside of the `update()` delegate as that can cause issues 
like segfaults, for example if it hasn't been initialized yet.  

All drawing on terminal is done through the `Display` class, an instance of this class is stored as 
`protected Display _display;` in each widget.  

This allows each widget to draw over a rectangular area assigned to it by the parent widget.  

This class provides several functions for drawing to terminal:  

## cursor [getter/setter]
This property can be used to read or change the position of cursor (where the next character will be written).  
All positions/coordinates are relative to top left corner of widget (0,0).

## write (dstring str, Color fg, Color bg)
This will set the foreground color to fg, background color to bg, and start writing `str`. If it doesnt fit in 
current line, it will start at x=0 of next line. If there are no more lines left, the rest of string will not 
be written.

## write(dstring)
This will keep the previous foreground and background colors, and write a string, same as above.  
  
However, you might want to avoid this, or at least call `_display.colors(..)` right at start of `update()` 
because if you do not change the colors, any writing will be done in the colors of last widget whose 
`update()` was called.

## fill(dchar c, Color fg, Color bg)
This will start at cursor position, and fill the rest of area of the widget with the character `c`.

## fillLine(dchar c, Color fg, Color bg, uinteger max=0)
If `max=0`, this will start at cursor, and fill the rest of line with `c`.
If `max!=0`, and there are more characters in line after cursor, it will only fill `max` number of cells, and move cursor there.