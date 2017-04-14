module main;

import qui;
import widgets;
import core.thread;
import std.concurrency;

__gshared ProgressbarWidget pBar;
__gshared QTerminal term;

void main(string[] args){
	term = new QTerminal("Title");

	TextLabelWidget label = new TextLabelWidget;
	label.caption = "Caption";
	label.sizeRatio = 1;


	pBar = new ProgressbarWidget(200, 0);
	pBar.sizeRatio = 1;
	pBar.caption = "Potato!";

	term.addWidget(label);
	term.addWidget(pBar);

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
		term.updateDisplay();
	}
}