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
		ScrollTestingWidget test = new ScrollTestingWidget(Color.black, Color.white, Color.green, false);
		QLayout scrollingLayout = new QLayout(QLayout.Type.Vertical);
		scrollingLayout.addWidget([label, test]);
		ScrollContainer sContainer = new ScrollContainer(scrollingLayout);
		sContainer.scrollOnMouseWheel = true;
		sContainer.scrollOnPageUpDown = true;
		test.height = 100;
		label.backColor = Color.blue;
		label.textColor = Color.green;
		term.fillColor = Color.black;
		label.height = 1;
		term.addWidget(sContainer);
		term.run();
		.destroy(term); 
	}
}