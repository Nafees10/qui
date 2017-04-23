module qui.misc;

import qui.qui;
import std.stdio;

///These names are easier to understand
alias integer = ptrdiff_t;
alias uinteger = size_t;


string[] fileToArray(string fname){
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
}

bool arrayToFile(string fname,string[] array){
	bool r = true;
	import std.stdio;
	File f = File(fname,"w");
	uinteger i;
	for (i=0;i<array.length;i++){
		f.write(array[i],'\n');
	}
	f.close;
	return r;
}

T[] deleteArray(T)(T[] dat, uinteger pos, uinteger count=1){
	T[] ar1, ar2;
	ar1 = dat[0..pos];
	ar2 = dat[pos+count..dat.length];
	return ar1~ar2;
}

T[] insertArray(T)(T[] dat, T[] ins, uinteger pos){
	T[] ar1, ar2;
	ar1 = dat[0..pos];
	ar2 = dat[pos..dat.length];
	return ar1~ins~ar2;
}
