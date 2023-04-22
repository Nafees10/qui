module demo;
version(demo){
	import qui.qui;
	import qui.widgets;
	import std.conv : to;
	import std.path;
	import std.stdio;
	import std.file : thisExePath;
	import utils.misc : fileToArray;

	void main (){
		QTerminal term = new QTerminal;
		term.widget = new ScrollTestingWidget(true);
		term.widget.heightConstraint(80);

		term.run;
		.destroy(term);
	}
}
