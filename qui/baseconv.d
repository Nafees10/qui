module baseconv;

import std.math;
import misc;

private uinteger toDenary(ushort fromBase, ubyte[] dat){
	uinteger r = 0, i = 0;
	foreach_reverse(cur; dat){
		r += pow(fromBase,i)*cur;
		i++;
	}
	return r;
}

private ubyte[] fromDenary(ushort toBase, uinteger dat){
	ubyte rem;
	ubyte[] r;
	while (dat>0){
		rem = cast(ubyte)dat%toBase;
		dat = (dat-rem)/toBase;
		r = [rem]~r;
	}
	
	return r;
}

private string toFormat(ubyte[] ar, char[] rep){
	uinteger i;
	char[] r;
	r.length = ar.length;
	for (i=0; i<ar.length; i++){
		r[i] = rep[ar[i]];
	}
	return cast(string)r;
}

private ubyte[] fromFormat(string ar, char[] rep){
	uinteger i;
	ubyte[] r;
	r.length = ar.length;
	for (i=0; i<ar.length; i++){
		r[i] = cast(ubyte)strSearch(cast(string)rep, ar[i]);
	}
	return r;
}

private uinteger strSearch(string s, char ss){
	uinteger i;
	for (i=0; i<s.length; i++){
		if (s[i]==ss){
			break;
		}
	}
	if (i>=s.length){
		i = -1;
	}
	return i;
}
//exported functions:
char[] denToChar(uinteger den){
	return cast(char[])fromDenary(256,den);
}

uinteger charToDen(char[] ch){
	return toDenary(256,cast(ubyte[])ch);
}

uinteger hexToDen(string hex){
	ubyte[] buffer;
	buffer = fromFormat(hex,cast(char[])"0123456789ABCDEF");
	return toDenary(16,buffer);
}

string denToHex(uinteger den){
	ubyte[] buffer;
	return toFormat(fromDenary(16,den),cast(char[])"0123456789ABCDEF");
}

import arsd.terminal;

RGB hexToColor(string hex){
	RGB r;
	r.r = cast(ubyte)hexToDen(hex[0..2]);
	r.g = cast(ubyte)hexToDen(hex[2..4]);
	r.b = cast(ubyte)hexToDen(hex[4..6]);
	return r;
}