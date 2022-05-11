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

		QLayout mainLayout = new QLayout(QLayout.Type.Vertical);

		SplitterWidget split = new SplitterWidget();
		split.color = Color.blue;

		ScrollContainer subScroll = new ScrollContainer();
		subScroll.scrollOnPageUpDown = true;
		subScroll.scrollOnMouseWheel = true;

		ScrollTestingWidget subTest = new ScrollTestingWidget(DEFAULT_FG, DEFAULT_BG,
			Color.green, true);
		subTest.height = 50;
		subTest.width = 70;

		subScroll.setWidget(subTest);

		mainLayout.addWidget([subScroll, split]);
		mainLayout.height = 50;
		
		mainScroll.setWidget(mainLayout);

		term.addWidget(mainScroll);

		term.addWidget(log);

		mainLayout.onScrollEvent = delegate(QWidget){
			log.add(subScroll.width.to!string ~ 'x' ~ subScroll.height.to!string);
			return false;
		};

		term.run();
		.destroy(term); 
	}
}