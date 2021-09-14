module demo;
version(demo){
	import qui.qui;
	import qui.widgets;
	import std.conv : to;
	import std.path;
	import std.file : thisExePath;
	import utils.misc : fileToArray;
	
	void main (){
		QTerminal term = new QTerminal();
		TextLabelWidget label = new TextLabelWidget("Hello World!");
		ScrollTestingWidget test = new ScrollTestingWidget(Color.black, Color.white);
		label.backgroundColor = Color.blue;
		label.textColor = Color.red;
		term.fillColor = Color.green;
		label.height = 1;
		term.addWidget([label, test]);
		term.run();
		.destroy(term); 
	}
}