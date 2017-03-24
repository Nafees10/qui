module main;

import qui;
import widgets;

void main(string[] args){
	TextLabelWidget label = new TextLabelWidget;
	label.caption = "Caption";
	label.sizeRatio = 1;
	QTerminal term = new QTerminal("Title");
	term.addWidget(label);

	term.run;

	delete term;
	delete label;
}

