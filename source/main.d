module main;

import qui;
import widgets;
import core.thread;
import std.concurrency;

__gshared QTerminal term;

void main(string[] args){
	term = new QTerminal("Title",QTerminal.LayoutDisplayType.Horizontal);

	ButtonWidget btn = new ButtonWidget();
	btn.caption = "Click here";

	term.addWidget(btn);

	term.run;

	delete term;
	delete btn;
}