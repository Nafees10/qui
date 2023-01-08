/++
	Contains functions that might be useful in making new widgets,
	like for formatting text.
+/
module qui.utils;

import qui.qui;

import utils.misc;
import std.conv : to;

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
dstring scrollHorizontal(dstring line, int xOffset, uint width, dchar spaceChar = ' '){
	dchar[] r;
	r.length = width;
	r[] = spaceChar;
	for (uint i = xOffset < 0 ? -xOffset : 0; i + xOffset < line.length && i < width; i ++)
		r[i] = line[i + xOffset];
	return cast(dstring)r;
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

/// ditto
dchar[] scrollHorizontal(dchar[] line, int xOffset, uint width){
	return cast(dchar[])(cast(dstring)line).scrollHorizontal(xOffset, width);
}
/// ditto
char[] scrollHorizontal(char[] line, int xOffset, uint width){
	return cast(char[])(cast(dstring)line).scrollHorizontal(xOffset, width);
}

/// Adjusts offset (aka _scrollX or _scrollY) in scrolling so the selected character is visible TODO: FIX THIS
///
/// Arguemnts:
/// * `selected` is the character on which the cursor is. If it's >lineWidth, `selected=lineWidth`
/// * `size` is the width/height (depending on if it's horizontal or vertical scrolling) of the space where the line is to be displayed
/// * `offset` is the variable storing the offset (_xOffset or _yOffset)
void adjustScrollingOffset(ref uint selected, uint size, uint lineWidth, ref uint offset){
	// if selected is outside size, it shouldn't be
	if (selected > lineWidth)
		selected = lineWidth;
	// range of characters' index that's visible (1 is inclusive, 2 is not)
	uint visible1, visible2;
	visible1 = offset;
	visible2 = offset + size;
	if (selected < visible1 || selected >= visible2){
		if (selected < visible1){
			// scroll back
			offset = selected;
		}else if (selected >= visible2){
			// scroll ahead
			offset = selected+1 - size;
		}
	}
}

/// Center-aligns text
///
/// If `text.length > width`, the exceeding characters are removed
///
/// Returns: the text center aligned in a string
dstring centerAlignText(dstring text, uint width, dchar fill = ' '){
	dchar[] r;
	r.length = width;
	if (text.length < width){
		uint offset = (width - cast(uint)text.length)/2;
		r[0 .. offset] = fill;
		r[offset .. offset+text.length][] = text;
		r[offset+text.length .. r.length] = fill;
	}else
		r[] = text[0 .. r.length];
	return cast(dstring)r;
}
///
unittest{
	assert("qwr".centerAlignText(7) == "  qwr  ");
	assert("qwerty".centerAlignText(6) == "qwerty");
	assert("qwerty".centerAlignText(5) == "qwert");
}

/// Returns: size after considering minimum and maximum allowed
///
/// if `min==0`, it is ignored. if `max==0`, it is ignored
uint getLimitedSize(uint calculated, uint min, uint max){
	if (min && calculated < min)
		return min;
	if (max && calculated > max)
		return max;
	return calculated;
}
