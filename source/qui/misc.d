/++
	This module contains contains some misc. functions. (The name says that)
+/
module qui.misc;

import std.stdio;

//These names are easier to understand
///`integer is a `long` on 64 bit systems, and `int` on 32 bit systems
alias integer = ptrdiff_t;
///`uinteger` is a `ulong` on 64 bit systems, and `uint` on 32 bit systems
alias uinteger = size_t;

///Reads a file into an array of string
///Throws exception on failure
string[] fileToArray(string fname){
	try{
		File f = File(fname,"r");
		string[] r;
		string line;
		integer i=0;
		r.length=0;
		while (!f.eof()){
			if (i+1>=r.length){
				r.length+=5;
			}
			line=f.readln;
			if (line.length>0 && line[line.length-1]=='\n'){
				line.length--;
			}
			r[i]=line;
			i++;
		}
		f.close;
		r.length = i;
		return r;
	}catch (Exception e){
		throw e;
	}
}

/// Writes an array of string to a file
/// Throws exception on failure
void arrayToFile(string fname,string[] array){
	try{
		File f = File(fname,"w");
		uinteger i;
		for (i=0;i<array.length;i++){
			f.write(array[i],'\n');
		}
		f.close;
	}catch (Exception e){
		throw e;
	}
}

/// Removes element(s) from an array, and returns the modified array;
T[] deleteArray(T)(T[] dat, uinteger pos, uinteger count=1){
	T[] ar1, ar2;
	ar1 = dat[0..pos];
	ar2 = dat[pos+count..dat.length];
	return ar1~ar2;
}

/// Inserts an array into another array, returns the result;
T[] insertArray(T)(T[] dat, T[] ins, uinteger pos){
	T[] ar1, ar2;
	ar1 = dat[0..pos];
	ar2 = dat[pos..dat.length];
	return ar1~ins~ar2;
}
