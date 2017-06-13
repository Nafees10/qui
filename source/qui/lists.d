/++
	This module contains classes that are related to data storage
+/
module qui.lists;

import qui.qui;//used for Position & Cell in Matrix
import qui.misc;
import std.file;
import std.stdio;

/// Use to manage dynamic arrays that frequently change lengths
/// 
/// Provides more functionality for arrays, like searching in arrays, removing elements...
class List(T){
private:
	T[] list;
	uinteger taken=0;
public:
	/// appends an element to the list
	void add(T dat){
		if (taken==list.length){
			list.length+=10;
		}
		taken++;
		list[taken-1] = dat;
	}
	/// appends an array to the list
	void addArray(T[] dat){
		list.length = taken;
		list ~= dat;
		taken += dat.length;
	}
	/// Changes the value of element at an index.
	/// 
	/// `dat` is the new data
	void set(uinteger index, T dat){
		list[index]=dat;
	}
	/// Removes last elements(s) starting from an index; number of elements to remove is in `count`
	void remove(uinteger index, uinteger count=1){
		integer i;
		integer till=taken-count;
		for (i=index;i<till;i++){
			list[i] = list[i+count];
		}
		list.length-=count;
		taken-=count;
	}
	/// Removes last elements(s); number of elements to remove is in `count`
	void removeLast(uinteger count = 1){
		taken -= count;
		if (list.length-taken>10){
			list.length=taken;
		}
	}
	/// shrinks the size of the list, removing last elements.
	void shrink(uinteger newSize){
		if (newSize < taken){
			list.length=newSize;
			taken = list.length;
		}
	}
	/// Inserts an array into this list
	void insert(uinteger index, T[] dat){
		integer i;
		T[] ar,ar2;
		ar=list[0..index];
		ar2=list[index..taken];
		list.length=0;
		list=ar~dat~ar2;
		taken+=dat.length;
	}
	/// Inserts an element into this list
	void insert(uinteger index, T dat){
		integer i;
		T[] ar,ar2;
		ar=list[0..index];
		ar2=list[index..taken];
		list.length=0;
		list=ar~[dat]~ar2;
		taken++;
	}
	/// Writes the list to a file.
	/// 
	/// `sp` is the line separator. In case of strings, you want it to be `"\n"`;
	void saveFile(string s, T sp){
		File f = File(s,"w");
		uinteger i;
		for (i=0;i<taken;i++){
			f.write(list[i],sp);
		}
		f.close;
	}
	/// Reads an element at an index
	T read(uinteger index){
		return list[index];
	}
	/// Read a slice from the list.
	/// 
	/// The slice is copied to avoid data in list from getting changed
	T[] readRange(uinteger index,uinteger i2){
		T[] r;
		r.length = (i2-index);
		r[0 .. r.length] = list[index .. i2];
		return r;
	}
	/// Reads the last element in list.
	T readLast(){
		return list[taken-1];
	}
	/// returns last elements in list. number of elements to return is specified in `count`
	T[] readLast(uinteger count){
		T[] r;
		r.length = count;
		r[0 .. r.length] = list[taken-count..taken];
		return r;
	}
	/// length of the list
	@property integer length(){
		return taken;
	}
	/// Exports this list into a array
	T[] toArray(){
		uinteger i;
		T[] r;
		if (taken!=-1){
			r.length=taken;
			for (i=0;i<taken;i++){//using a loop cuz simple '=' will just copy the pionter
				r[i]=list[i];
			}
		}
		return r;
	}
	/// Loads array into this list
	void loadArray(T[] dats){
		uinteger i;
		list.length=dats.length;
		taken=list.length;
		for (i=0;i<dats.length;i++){
			list[i]=dats[i];
		}
	}
	/// empties the list
	void clear(){
		list.length=0;
		taken=0;
	}
	/// Returns index of the first matching element. -1 if not found
	/// 
	/// `dat` is the element to search for
	/// `i` is the index from where to start, default is 0
	/// `forward` if true, searches in a forward direction, from lower index to higher
	integer indexOf(T dat, integer i=0, bool forward=true){
		if (forward){
			for (;i<taken;i++){
				if (list[i]==dat){break;}
				if (i==taken-1){i=-1;break;}
			}
		}else{
			for (;i>=0;i--){
				if (list[i]==dat){break;}
				if (i==0){i=-1;break;}
			}
		}
		if (taken==0){
			i=-1;
		}
		return i;
	}
}
///represents an item in a linked list. contains the item, and pointer to the next item's container
private struct LinkedItem(T){
	T data;
	LinkedItem!(T)* next = null;//mark it null to show the list has ended
}
/// A linked list, used where only reading in the forward direction is required
class LinkedList(T){
private:
	LinkedItem!(T)* firstItemPtr;
	LinkedItem!(T)* lastItemPtr;//the pointer of the last item, used for appending new items
	LinkedItem!(T)* nextReadPtr;//the pointer of the next item to be read

	uinteger itemCount;//stores the total number of items
public:
	this(){
		firstItemPtr = null;
		lastItemPtr = null;
		nextReadPtr = null;
		itemCount = 0;
	}
	~this(){
		//free all the memory occupied
		clear();
	}
	///clears/resets the list. Frees all the occupied memory, & removes all items
	void clear(){
		//make sure that the list is populated
		if (firstItemPtr !is null){
			LinkedItem!(T)* nextPtr;
			for (nextReadPtr = firstItemPtr; nextReadPtr !is null; nextReadPtr = nextPtr){
				nextPtr = (*nextReadPtr).next;
				destroy(*nextReadPtr);
			}
			//reset all variables
			firstItemPtr = null;
			lastItemPtr = null;
			nextReadPtr = null;
			itemCount = 0;
		}
	}
	///adds a new item at the end of the list
	void append(T item){
		LinkedItem!(T)* ptr = new LinkedItem!(T);
		(*ptr).data = item;
		(*ptr).next = null;
		//add it to the list
		if (firstItemPtr is null){
			firstItemPtr = ptr;
			nextReadPtr = firstItemPtr;
		}else{
			(*lastItemPtr).next = ptr;
		}
		//mark this item as last
		lastItemPtr = ptr;
		//increase item count
		itemCount ++;
	}
	///removes the first item in list
	void removeFirst(){
		//make sure list is populated
		if (firstItemPtr !is null){
			LinkedItem!(T)* first;
			first = firstItemPtr;
			//mark the second item as first, if there isn't a second item, it'll automatically be marked null
			firstItemPtr = (*firstItemPtr).next;
			//if nextReadPtr is firstItemPtr, move it to next as well
			if (nextReadPtr is first){
				nextReadPtr = firstItemPtr;
			}
			//free memory occupied by first
			destroy(*first);
			//decrease count
			itemCount --;
		}
	}
	///number of items that the list is holding
	@property uinteger count(){
		return itemCount;
	}
	///resets the read position, i.e: set reading position to first item
	void resetRead(){
		nextReadPtr = firstItemPtr;
	}
	///returns pointer of next item to be read, null if there are no more items
	T* read(){
		T* r;
		if (nextReadPtr !is null){
			r = &((*nextReadPtr).data);
			//move read position
			nextReadPtr = (*nextReadPtr).next;
		}else{
			r = null;
		}
		return r;
	}
}

/// Used in logging widgets. Holds upto certain number, after which older items are removed
class LogList(T){
private:
	List!T list;
	uinteger readFrom, maxLen;
public:
	this(uinteger maxLength=100){
		list = new List!T;
		readFrom = 0;
		maxLen = maxLength;
	}
	~this(){
		delete list;
	}
	///adds an item to the log
	void add(T dat){
		if (list.length>=maxLen){
			list.set(readFrom,dat);
			readFrom++;
		}else{
			list.add(dat);
		}
	}
	///Returns array containing items, in first-added-last order
	T[] read(uinteger count=0){
		T[] r;
		if (count>list.length){
			count = list.length;
		}
		if (count > 0){
			uinteger i;
			if (count>list.length){
				count = list.length;
			}
			r.length = count;
			for (i = readFrom; i < count; i++){
				r[i] = list.read((readFrom+i)%count);
			}
		}else{
			r = null;
		}
		return r;
	}
	///resets and clears the log
	void reset(){
		list.clear;
		readFrom = 0;
	}
	///returns the max number of items that can be stored
	@property uinteger maxCapacity(){
		return maxLen;
	}
}

///Used to store the widget's/terminal's display in a matrix
class Matrix{
private:
	Cell[][] matrix;//read as: matrix[y][x];
	//used to write by widgets
	uinteger xPosition, yPosition;

	//stores which part was updated
	struct UpdateLocation{
		uinteger x, y;
		uinteger length;
	}
	LinkedList!UpdateLocation updateAt;

	Cell readAsStream(uinteger pos){
		return matrix[pos/width][pos%width];
	}

	char[] cellToChar(Cell[] c){
		char[] r;
		r.length = c.length;
		for (uinteger i = 0; i < c.length; i++){
			r[i] = c[i].c;
		}
		return r;
	}

	void updateChars(QTerminal terminal, uinteger x, uinteger y, uinteger length){
		uinteger readPos = (y*width)+x, i;
		Cell[] line;
		line.length = length;
		//read all content into line
		for (i = 0; i < length; i++){
			line[i] = readAsStream(readPos);
			readPos ++;
		}
		//start writing it to terminal
		terminal.moveTo(cast(int)x, cast(int)y);
		//set origin colors
		RGBColor originBgColor, originTextColor;
		originBgColor = line[0].bgColor;
		originTextColor = line[0].textColor;
		terminal.setColors(originTextColor, originBgColor);

		length --;
		uinteger writeFrom = 0;
		for (i = 0; i <= length; i++){
			//check if colors have changed, or is it end
			if (line[i].bgColor != originBgColor || line[i].textColor != originTextColor || i == length){
				if (writeFrom < i){
					terminal.setColors(originTextColor, originBgColor);
					terminal.writeChars(cellToChar(line[writeFrom .. i]));
				}
				//if is at end, write the 'last-encountered' char too
				if (i == length){
					terminal.setColors(line[i].textColor, line[i].bgColor);
					terminal.writeChars(line[i].c);
				}
			}
		}
	}
public:
	this(uinteger matrixWidth, uinteger matrixHeight, Cell fill){
		//set matrix size
		matrix.length = matrixHeight;
		//set width:
		for (uinteger i = 0; i < matrix.length; i++){
			matrix[i].length = matrixWidth;
			matrix[i][0 .. matrixWidth] = fill;
		}
		updateAt = new LinkedList!UpdateLocation;
		//set updateAt to whole Matrix
		UpdateLocation loc;
		loc.x, loc.y = 0;
		loc.length = width*height;
		updateAt.append(loc);
	}
	~this(){
		delete updateAt;
	}
	///Clear the matrix, and put fill in every cell
	void clear(Cell fill){
		for (uinteger row = 0; row < matrix.length; row++){
			matrix[row][0 .. matrix[row].length] = fill;
		}
		//set updateAt to whole Matrix
		UpdateLocation loc;
		loc.x, loc.y = 0;
		loc.length = width*height;
		updateAt.append(loc);
	}
	///Change size of the matrix, width and height
	bool changeSize(uinteger matrixWidth, uinteger matrixHeight, Cell fill){
		//make sure width & size are at least 1
		bool r = true;
		if (matrixWidth == 0 || matrixHeight == 0){
			r = false;
		}
		if (r){
			matrix.length = matrixHeight;
			for (uinteger i = 0; i < matrix.length; i++){
				matrix[i].length = matrixWidth;
				matrix[i][0 .. matrixWidth] = fill;
			}
		}
		return r;
	}
	///sets write position to (0, 0)
	void resetWritePosition(){
		xPosition = 0;
		yPosition = 0;
	}
	///used to write to matrix, call Matrix.setWriteLimits before this
	void write(char[] c, RGBColor textColor, RGBColor bgColor){
		uinteger i, xEnd, yEnd;
		xEnd = width;
		yEnd = height;
		//add it to updateAt
		UpdateLocation loc;
		loc.x = xPosition;
		loc.y = yPosition;
		loc.length = c.length;
		updateAt.append(loc);
		for (i = 0; i < c.length; xPosition++){
			if (xPosition == xEnd){
				//move to next row
				yPosition++;
				xPosition = 0;
			}
			//check if no more space left
			if (yPosition >= yEnd){
				//no more space left
				break;
			}
			matrix[yPosition][xPosition].c = c[i];
			matrix[yPosition][xPosition].bgColor = bgColor;
			matrix[yPosition][xPosition].textColor = textColor;
			i++;
		}
	}
	///changes colors for whole matrix
	void setColors(RGBColor textColor, RGBColor bgColor){
		for (uinteger i = 0; i < matrix.length; i++){
			for(uinteger j = 0; j < matrix[i].length; j++){
				matrix[i][j].textColor = textColor;
				matrix[i][j].bgColor = bgColor;
			}
		}
		//set updateAt to whole Matrix
		UpdateLocation loc;
		loc.x, loc.y = 0;
		loc.length = width*height;
		updateAt.append(loc);
	}
	///move to a different position to write
	bool moveTo(uinteger x, uinteger y){
		bool r = true;
		if (x > matrix[0].length-1 || y > matrix.length-1){
			r = false;
		}
		if (r){
			xPosition = x;
			yPosition = y;
		}
		return r;
	}
	///returns number of rows/lines in matrix
	@property uinteger height(){
		return matrix.length;
	}
	///returns number of columns in matrix
	@property uinteger width(){
		return matrix[0].length;
	}
	///returns the point ox x-axis where next write will start from
	@property uinteger writePosX(){
		return xPosition;
	}
	///returns the point ox y-axis where next write will start from
	@property uinteger writePosY(){
		return yPosition;
	}
	///read a cell from the matrix
	Cell read(uinteger x, uinteger y){
		return matrix[y][x];
	}
	///read a complete row from matrix
	Cell[] readRow(uinteger y){
		return matrix[y][];
	}
	///insert a matrix into this one at a position
	bool insert(Matrix toInsert, uinteger x, uinteger y){
		uinteger matrixWidth, matrixHeight;
		matrixHeight = toInsert.height;
		matrixWidth = toInsert.width;
		bool r = true;
		if (matrixHeight + y > this.height || matrixWidth + x > this.width){
			r = false;
		}else{
			uinteger row = 0;
			uinteger endAtRow = matrixHeight;
			for (;row<endAtRow; row++){
				matrix[y + row][x .. x+matrixWidth] = toInsert.readRow(row);
				//add this row to updateAt
				UpdateLocation loc;
				loc.x = x;
				loc.y = y+row;
				loc.length = matrixWidth;
				updateAt.append(loc);
			}
		}
		//debug{toFile("/home/nafees/Desktop/a");}
		return r;
	}
	/*debug{
		void toFile(string fname){
			File f = File(fname, "w");
			for (uinteger i = 0; i < matrix.length; i++){
				for (uinteger j = 0; j < matrix[i].length; j++){
					f.write(matrix[i][j].c);
				}
				f.write('|','\n');
			}
			f.close;
		}
	}*/
	///Write contents of matrix to a QTerminal
	void flushToTerminal(QTerminal terminal){
		//make sure that there was some change that needs to be flushed
		if (updateAt.count > 0){
			//start going through all update-needy
			uinteger i, count;
			count = updateAt.count();
			UpdateLocation* ptr;
			for (i = 0; i < count; i++){
				ptr = updateAt.read();
				if (ptr is null){
					break;
				}
				if ((*ptr).length > 0){
					updateChars(terminal, (*ptr).x, (*ptr).y, (*ptr).length);
				}
				updateAt.removeFirst();
			}
			terminal.flush();
		}
	}
}