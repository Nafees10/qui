module main;

import qui;
import widgets;
import core.thread;
import std.concurrency;

__gshared ProgressbarWidget pBar;

void main(string[] args){
	TextLabelWidget label = new TextLabelWidget;
	label.caption = "Caption";
	label.sizeRatio = 1;
	QTerminal term = new QTerminal("Title");

	pBar = new ProgressbarWidget(200, 0);
	pBar.sizeRatio = 1;

	term.addWidget(label);
	term.addWidget(pBar);
	pBar.caption = "Potato!";

	spawn(&increment);

	term.run;

	delete term;
	delete label;
	delete pBar;
}

void increment(){
	while (pBar.progress < pBar.total){
		Thread.sleep(dur!"msecs"(125));
		if (pBar.total - pBar.progress < 8){
			pBar.progress = pBar.total;
		}else{
			pBar.progress = pBar.progress + 8;
		}
	}
}