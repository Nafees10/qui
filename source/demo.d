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
		term.widget.minHeight = 80;
		term.widget.onKeyboardEvent = (QWidget, KeyboardEvent key, bool cycle){
			if (key.key == KeyboardEvent.Key.UpArrow && term.scrollY)
				term.scrollY = term.scrollY - 1;
			else if (key.key == KeyboardEvent.Key.DownArrow)
				term.scrollY = term.scrollY + 1;
		};

		term.run;
		.destroy(term);
	}
}
