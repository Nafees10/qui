module lists;

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

class LogList{
private:
	List!string list;
	uinteger readFrom, maxLen;
public:
	this(uinteger maxLength=100){
		list = new List!string;
		readFrom = 0;
		maxLen = maxLength;
	}
	~this(){
		delete list;
	}
	void add(string msg){
		if (list.length>=maxLen){
			list.set(readFrom,msg);
			readFrom++;
		}else{
			list.add(msg);
		}
	}
	//count = 0 == read all
	string[] read(uinteger count=0){
		string[] r;
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
	void reset(){
		list.clear;
		readFrom = 0;
	}
}