module lists;

import qui;//used for Position & Cell in Matrix
import misc;
import std.file;
import std.stdio;

class List(T){
private:
	T[] list;
	uinteger taken=0;
public:
	void add(T dat){
		if (taken==list.length){
			list.length+=10;
		}
		taken++;
		list[taken-1] = dat;
	}
	void addArray(T[] dat){
		list.length = taken;
		list ~= dat;
		taken += dat.length;
	}
	void set(uinteger index, T dat){
		list[index]=dat;
	}
	void remove(uinteger index, uinteger count=1){
		integer i;
		integer till=taken-count;
		for (i=index;i<till;i++){
			list[i] = list[i+count];
		}
		list.length-=count;
		taken-=count;
	}
	void removeLast(uinteger count = 1){
		taken -= count;
		if (list.length-taken>10){
			list.length=taken;
		}
	}
	void shrink(uinteger newSize){
		list.length=newSize;
		taken = list.length;
	}
	void insert(uinteger index, T[] dat){
		integer i;
		T[] ar,ar2;
		ar=list[0..index];
		ar2=list[index..taken];
		list.length=0;
		list=ar~dat~ar2;
		taken+=dat.length;
	}
	void insert(uinteger index, T dat){
		integer i;
		T[] ar,ar2;
		ar=list[0..index];
		ar2=list[index..taken];
		list.length=0;
		list=ar~[dat]~ar2;
		taken+=dat.length;
	}
	void saveFile(string s, T sp){
		File f = File(s,"w");
		uinteger i;
		for (i=0;i<taken;i++){
			f.write(list[i],sp);
		}
		f.close;
	}
	T read(uinteger index){
		return list[index];
	}
	T[] readRange(uinteger index,uinteger i2){
		T[] r;
		r.length = (i2-index);
		r[0 .. r.length] = list[index .. i2];
		return r;
	}
	T readLast(){
		return list[taken-1];
	}
	T[] readLast(uinteger count){
		T[] r;
		r.length = count;
		r[0 .. r.length] = list[taken-count..taken];
		return r;
	}
	integer length(){
		return taken;
	}
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
	void loadArray(T[] dats){
		uinteger i;
		list.length=dats.length;
		taken=list.length;
		for (i=0;i<dats.length;i++){
			list[i]=dats[i];
		}
	}
	void clear(){
		list.length=0;
		taken=0;
	}
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

///Used in logging widgets. Holds upto certain number, after which older 
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
	void add(T dat){
		if (list.length>=maxLen){
			list.set(readFrom,dat);
			readFrom++;
		}else{
			list.add(dat);
		}
	}
	//count = 0 == read all
	T[] read(uinteger count=0){
		T[] r;
		if (count == 0){
			uinteger i;
			count = list.length;
			r.length = count;
			for (i = readFrom; i < count; i++){
				r[i] = list.read((readFrom+i)%count);
			}
		}else{
			uinteger i;
			if (count>list.length){
				count = list.length;
			}
			r.length = count;
			for (i = readFrom; i < count; i++){
				r[i] = list.read((readFrom+i)%count);
			}
		}
		return r;
	}
	T read(uinteger index){
		return list.read((index+readFrom)%list.length);
	}
	void reset(){
		list.clear;
		readFrom = 0;
	}
}

///Used to store the widget's/terminal's display in a matrix
class Matrix{
private:
	Cell[][] matrix;//read as: matrix[y][x];
	//used to write by widgets
	uinteger wX = 0, wY = 0, wXEnd = 0, wYEnd = 0;
	uinteger xPosition, yPosition;

	//stores whether the terminal needs updating or not
	bool updateNeeded = false;
public:
	this(uinteger width, uinteger height, Cell fill){
		//set matrix size
		matrix.length = height;
		//set width:
		for (uinteger i = 0; i < matrix.length; i++){
			matrix[i].length = width;
			matrix[i][0 .. width] = fill;
		}
	}
	///Clear the matrix, and put fill in every cell
	void clear(Cell fill){
		for (uinteger row = 0; row < matrix.length; row++){
			matrix[row][0 .. matrix[row].length] = fill;
		}
	}
	///Change size of the matrix, width and height
	bool changeSize(uinteger width, uinteger height, Cell fill){
		//make sure width & size are at least 1
		bool r = true;
		if (width == 0 || height == 0){
			r = false;
		}
		if (r){
			matrix.length = height;
			for (uinteger i = 0; i < matrix.length; i++){
				matrix[i].length = width;
				matrix[i][0 .. width] = fill;
			}
		}
		return r;
	}
	//Set write limits, so a widget cannot write outside it's rectangle
	void setWriteLimits(uinteger startX, uinteger startY, uinteger width, uinteger height){
		wX = startX;
		wY = startY;
		xPosition = wX;
		yPosition = wY;
		wXEnd = width-wX;
		wYEnd = height-wY;
	}
	///used to write to matrix, call Matrix.setWriteLimits before this
	void write(char[] c, RGBColor textColor, RGBColor bgColor){
		uinteger i;
		for (i = 0; xPosition <= wXEnd && yPosition <= wYEnd && i < c.length; xPosition++){
			if (xPosition >= wXEnd){
				//move to next row
				yPosition++;
				xPosition = wX;
			}
			//check if no more space left
			if (xPosition == wXEnd && yPosition >= wYEnd){
				//no more space left
				break;
			}
			matrix[yPosition][xPosition].c = c[i];
			matrix[yPosition][xPosition].bgColor = bgColor;
			matrix[yPosition][xPosition].textColor = textColor;
			i++;
		}
		updateNeeded = true;
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
	///read a cell from the matrix
	Cell read(uinteger x, uinteger y){
		return matrix[y][x];
	}
	///read a complete row from matrix
	Cell[] readRow(uinteger y){
		return matrix[y][];
	}
	///returns whether terminal needs to be updated
	@property bool hasChanged(){
		return updateNeeded;
	}
	///insert a matrix into this one at a position
	bool insert(Matrix toInsert, uinteger x, uinteger y){
		uinteger width, height;
		height = toInsert.height;
		width = toInsert.width;
		bool r = true;
		if (height + y > this.height || width + x > this.width){
			r = false;
		}else{
			uinteger row = 0;
			uinteger endAtRow = height;
			for (;row<endAtRow; row++){
				matrix[y + row][x .. x+width] = toInsert.readRow(row);
			}
			updateNeeded = true;
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
	void flushToTerminal(QTerminal* terminal){
		if (updateNeeded){
			//first clear everything:
			terminal.clear;
			uinteger row = 0, col = 0, rowEnd = matrix.length-1, colEnd = matrix[0].length-1;
			uinteger writeFrom = 0;
			RGBColor prevBgColor, prevTextColor;
			//set initial colors
			prevBgColor = matrix[row][col].bgColor;
			prevTextColor = matrix[row][col].textColor;
			char[] toWrite;
			toWrite.length = width;
			terminal.setColors(prevTextColor, prevBgColor);
			//copy first row's chars
			for (uinteger i = 0; i < width; i++){
				toWrite[i] = matrix[row][i].c;
			}
			for (; row <= rowEnd && col <= colEnd; col++){
				//check if has to move to next row
				if (col >= colEnd){
					//write remaining row to terminal
					if (writeFrom < col){
						terminal.writeChars(toWrite[writeFrom .. col+1]);
					}
					//move to next row
					writeFrom = 0;
					col = 0;
					row++;
					if (row > rowEnd){
						break;
					}
					//copy row's chars
					for (uinteger i = 0; i < width; i++){
						toWrite[i] = matrix[row][i].c;
					}
					terminal.moveTo(cast(int)col, cast(int)row);
				}
				//check if colors have changed, if yes, write chars
				if (matrix[row][col].bgColor != prevBgColor || matrix[row][col].textColor != prevTextColor){
					//write previous chars
					if (writeFrom < col){
						terminal.writeChars(toWrite[writeFrom .. col]);
					}
					writeFrom = col;
					//update colors
					prevBgColor = matrix[row][col].bgColor;
					prevTextColor = matrix[row][col].textColor;
					terminal.setColors(prevTextColor, prevBgColor);
				}
				//check if is at end, then write remaining chars
				if (row == rowEnd && col == colEnd){
					//set colors, could be different
					if (writeFrom < col){
						terminal.writeChars(toWrite[writeFrom .. col]);
					}
					terminal.setColors(matrix[row][col].textColor, matrix[row][col].bgColor);
					terminal.writeChars(matrix[row][col].c);
				}
			}
			updateNeeded = false;
			terminal.flush;
		}
	}
}