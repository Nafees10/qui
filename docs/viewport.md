# Viewport

Used to draw to terminal by widgets.

## Properties
* `view.width` - width of the viewport
* `view.height` - height of the viewport
* `view.x` - offset on x coordinates. This number of columns are not visible
	i.e: scrolled, or overlapping etc. Drawing only allowed at
	`view.x .. view.x + view.width`
* `view.y` - offset on y coordinates. This number of rows are not visible
	i.e: scrolled, or overlapping etc. Drawing only allowed at
	`view.y .. view.y + view.height`

## Functions
* `isWritable(x, y)` - Whether x and y are inside the limits written above.
* `moveTo(x, y)` - Move to x,y for next write. Returns true if isWritable
* `write(dchar, foreground, background)` - writes a single character with 
	colors. Returns true if written, false if outside bounds.
* `write(dstring, foreground, background)` - same but for a string.
	Returns number of characters written.
* `fillLine(dchar, foregroumd, background, max)` - fills line, starting from
	where the cursor is right now. if max is not zero, will only write maximum of 
	that number of characters. Returns number of characters written.
