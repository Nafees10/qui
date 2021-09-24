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
		ScrollContainer sContainer = new ScrollContainer(test);
		test.height = 100;
		label.backgroundColor = Color.blue;
		label.textColor = Color.green;
		term.fillColor = Color.black;
		label.height = 1;
		term.addWidget([label, sContainer]);
		term.onKeyboardEvent = delegate(QWidget, KeyboardEvent key){
			if (key.isChar && key.state == KeyboardEvent.State.Pressed){
				if (key.key == 'w')
					test.scrollY = test.scrollY - 1;
				else if (key.key == 's')
					test.scrollY = test.scrollY + 1;
				else if (key.key == 'a')
					test.scrollX = test.scrollX - 1;
				else if (key.key == 'd')
					test.scrollX = test.scrollX + 1;
				label.caption = [key.key];
			}
			return false;
		};
		term.run();
		.destroy(term); 
	}
}