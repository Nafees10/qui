module demo;
version(demo){
	import qui.qui;
	import qui.widgets;
	import std.conv : to;
	import std.path;
	import std.file : thisExePath;
	import utils.misc : fileToArray;
	
	void main (){
		QTerminal term = new QTerminal(QLayout.Type.Horizontal);

		LogWidget log = new LogWidget();

		ScrollContainer mainScroll = new ScrollContainer();
		mainScroll.scrollOnMouseWheel = true;
		mainScroll.scrollOnPageUpDown = true;
		mainScroll.onKeyboardEvent = delegate(QWidget, KeyboardEvent key, bool){
			log.add("mainScroll->keyboard called");
			return false;
		};

		QLayout mainLayout = new QLayout(QLayout.Type.Vertical);

		SplitterWidget split = new SplitterWidget();
		split.color = Color.blue;

		ScrollContainer subScroll = new ScrollContainer();
		subScroll.scrollOnPageUpDown = true;
		subScroll.scrollOnMouseWheel = true;
		subScroll.onKeyboardEvent = delegate(QWidget, KeyboardEvent key, bool){
			log.add("subScroll->keyboard called");
			return false;
		};

		ScrollTestingWidget subTest = new ScrollTestingWidget();
		subTest.height = 50;
		subTest.width = 70;

		subScroll.setWidget(subTest);

		mainLayout.addWidget([split, subScroll]);
		mainLayout.height = 50;
		
		mainScroll.setWidget(mainLayout);

		term.addWidget(mainScroll);

		term.addWidget(log);

		term.run();
		.destroy(term); 
	}
}