module main;

import qui;
import widgets;

void main(string[] args){
	TextLabelWidget label = new TextLabelWidget;
	label.caption = "Caption";
	label.sizeRatio = 1;
	QTerminal term = new QTerminal("Title");
	//term.addWidget(label);

	ProgressbarWidget pBar = new ProgressbarWidget(ProgressbarWidget.Direction.Backward, 200, 40);
	term.addWidget(pBar);

	term.run;

	delete term;
	delete label;
}

