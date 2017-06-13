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

