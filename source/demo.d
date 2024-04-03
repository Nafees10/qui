module demo;
version(demo){
	import qui.qui,
				 qui.widgets;

	import std.stdio;

	void main (){
		QTerminal term = new QTerminal;
		term.widget = new ScrollTestingWidget(true);
		term.widget.heightConstraint(80);

		term.run;
		.destroy(term);
	}
}
