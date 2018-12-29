/++
	Contains functions that might be useful in making new widgets, 
	like for formatting text.
+/
module qui.utils;

import utils.baseconv;
import utils.misc;
import std.conv : to;
import arsd.terminal : RGB;

/// To scroll a line, by an xOffset
/// 
/// Can be used to scroll to right, or to left (by making xOffset negative).  
/// Can also be used to fill an empty line with empty space (`' '`) to make it fill width, if `line.length < width`
/// 
/// Arguments:
/// * `line` is the full line  
/// * `xOffset` is the number of characters scrolled right  
/// * `width` is the number of characters that are to be displayed
/// 
/// Returns: the text that should be displayed
string scrollHorizontal(string line, integer xOffset, uinteger width){
	char[] r;
	if (xOffset == 0){
		// in case it has to do nothing, 
		r = cast(char[])line[0 .. width > line.length ? line.length : width].dup;
	}else if (xOffset > 0){
		// only do something if it's not scrolled too far for the line to be even displayed
		if (xOffset < line.length){
			r = cast(char[])line[xOffset .. line.length].dup;
		}
	}else if (xOffset < 0){
		// only do something if it's not scrolled too far for the line to be even displayed
		if (cast(integer)(line.length) + xOffset > 0){
			r.length = xOffset * -1;
			r[] = ' ';
			r = r ~ cast(char[])line.dup;
		}
	}
	if (r.length < width){
		uinteger filledLength = r.length;
		r.length = width;
		r[filledLength .. r.length] = ' ';
	}else if (r.length > width){
		r.length = width;
	}
	return cast(string)r;
}
/// 
unittest{
	assert("0123456789".scrollHorizontal(5, 2) == "56");
	assert("0123456789".scrollHorizontal(0,10) == "0123456789");
	assert("0123456789".scrollHorizontal(10,4) == "    ");
	assert("0123456789".scrollHorizontal(-5,4) == "    ");
	assert("0123456789".scrollHorizontal(-5,6) == "     0");
	assert("0123456789".scrollHorizontal(-1,11) == " 0123456789");
	assert("0123456789".scrollHorizontal(-5,10) == "     01234");

}

/// Center-aligns text
/// 
/// If `text.length > width`, the exceeding characters are removed
/// 
/// Returns: the text center aligned in a string
string centerAlignText(string text, uinteger width, char fill = ' '){
	char[] r;
	if (text.length < width){
		r.length = width;
		uinteger offset = (width - text.length)/2;
		r[0 .. offset] = fill;
		r[offset .. offset+text.length][] = text;
		r[offset+text.length .. r.length] = fill;
	}else{
		r = cast(char[])text[0 .. width].dup;
	}
	return cast(string)r;
}
///
unittest{
	assert("qwr".centerAlignText(7) == "  qwr  ");
}

/// To calculate size of widgets using their sizeRatio
uinteger ratioToRaw(uinteger selectedRatio, uinteger ratioTotal, uinteger total){
	uinteger r;
	r = cast(uinteger)((cast(float)selectedRatio/cast(float)ratioTotal)*total);
	return r;
}

/// Converts hex color code to RGB
/// 
/// Returns: the color in `arsd.terminal.RGB`
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

/// Converts `arsd.terminal.RGB` to hex color code
/// 
/// Returns: the hex color code in string
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