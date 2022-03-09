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

		ScrollContainer mainScroll = new ScrollContainer();
		QLayout mainLayout = new QLayout(QLayout.Type.Vertical);
		mainScroll.setWidget(mainLayout);
		term.addWidget(mainScroll);

		QLayout titleLayout = new QLayout(QLayout.Type.Horizontal);
		titleLayout.height = 1;
		SplitterWidget titleLeft = new SplitterWidget(), titleRight = new SplitterWidget();
		titleLeft.color = Color.blue; titleRight.color = Color.blue;
		TextLabelWidget titleLabel = new TextLabelWidget("QUI Demo");
		titleLabel.backColor = Color.blue;
		titleLayout.addWidget([titleLeft, titleLabel, titleRight]);

		mainLayout.addWidget(titleLayout);

		ScrollContainer subScroll = new ScrollContainer();
		subScroll.height = 40;
		QLayout scrollTestLayout = new QLayout(QLayout.Type.Horizontal);
		subScroll.setWidget(scrollTestLayout);
		scrollTestLayout.height = 50;
		SplitterWidget leftSpace = new SplitterWidget(), rightSpace = new SplitterWidget();
		leftSpace.color = Color.green; rightSpace.color = Color.blue;
		ScrollTestingWidget test = new ScrollTestingWidget();
		test.width = 100;
		test.height = 100;
		scrollTestLayout.addWidget([leftSpace/*, test*/, rightSpace]);

		mainLayout.addWidget(subScroll);

		//mainScroll.scrollOnMouseWheel = true;
		subScroll.scrollOnPageUpDown = true;
		subScroll.scrollOnMouseWheel = true;

		term.run();
		.destroy(term); 
	}
}