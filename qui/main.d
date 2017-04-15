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
	pBar.caption = "Progress bar!";

	EditLineWidget edit = new EditLineWidget("Input here: ", "placeholder");

	term.addWidget(edit);
	term.addWidget(label);
	term.addWidget(pBar);

	//spawn(&increment);

	term.run;

	delete term;
	delete label;
	delete pBar;
	delete edit;
}
/*
void increment(){
	while (pBar.progress < pBar.total && term.running){
		if (pBar.total - pBar.progress < 8){
			pBar.progress = pBar.total;
		}else{
			pBar.progress = pBar.progress + 2;
		}
		//term.updateDisplay();
		Thread.sleep(dur!"msecs"(50));
	}
}*/