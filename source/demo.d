module demo;
version(demo){
	import qui.qui;
	import qui.widgets;
	import std.conv : to;
	import std.path;
	import std.file : thisExePath;
	import utils.misc : fileToArray;
	
	void main (){
		App appInstance = new App();
		appInstance.run();
		// not doing this causes an exception
		.destroy (appInstance);
	}
	
	class App{
	private:
		QTerminal term;
		ProgressbarWidget progressBar;
		TextLabelWidget label;
		EditLineWidget edit;
		MemoWidget memo;
		LogWidget log;
		QLayout hLayout;
		SplitterWidget split;
	public:
		this(){
			// construct all widgets
			term = new QTerminal(QLayout.Type.Vertical);
			progressBar = new ProgressbarWidget();
			label = new TextLabelWidget();
			edit = new EditLineWidget("EditLineWidget, one line text editor: ");
			hLayout = new QLayout(QLayout.Type.Horizontal);
			memo = new MemoWidget();
			log = new LogWidget();
			split = new SplitterWidget();

			// prepare the layout in for the Memo and log
			hLayout.addWidget([memo, split, log]);
			memo.lines.loadArray(fileToArray(dirName(thisExePath)~dirSeparator~"README.md"));
			memo.wantsTab = false;
			split.size.maxWidth = 1;
			split.color = Color.blue;

			// put all widgets in the order they are to appear in terminal
			term.addWidget([label, edit, progressBar, hLayout]);

			// register every single widget, if you don't, it'll segfault
			term.registerWidget([label, edit, progressBar, hLayout, memo, split, log]);

			// set some properties
			label.caption = "Progress bar: increases/decreases every 1/2 second. 1 2 3 4 5 6 7 8 10 9 8 7 6 5 4 3 2 1";
			progressBar.caption = "this is the progress bar";
			progressBar.size.maxHeight = 1;
			progressBar.max = 10;
			progressBar.progress = 0;

			// and this is how timerEvent can be used
			progressBar.onTimerEvent = delegate(QWidget caller){
				static increasing = true;
				// owner = caller (same thing)
				ProgressbarWidget owner = cast(ProgressbarWidget)caller;
				log.add("timer called");
				if (owner.progress >= owner.max){
					increasing = false;
				}else if (owner.progress == 0){
					increasing = true;
				}
				if (increasing)
					owner.progress = owner.progress + 1;
				else
					owner.progress = owner.progress -1;
				log.add("progress: "~to!string(owner.progress));
			};
		}
		~this(){
			// destroy all widgets
			.destroy(term);
			.destroy(progressBar);
			.destroy(label);
			.destroy(edit);
			.destroy(memo);
			.destroy(log);
			.destroy(hLayout);
			.destroy(split);
		}
		void run(){
			term.run;
		}
	}
}