module demo;
version(demo){
	import qui.qui;
	import qui.widgets;
	import std.conv : to;
	import std.path;
	import std.file : thisExePath;
	import utils.misc;
	
	void main (){
		App appInstance = new App();
		appInstance.run();
		// not doing this causes an exception
		.destroy (appInstance);
	}
	/// the app
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
		/// constructor
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
			{
				string[] lines = fileToArray(dirName(thisExePath)~dirSeparator~"README.md");
				foreach (line; lines){
					memo.lines.append(line.to!dstring);
				}
			}
			memo.wantsTab = false;
			split.size.maxWidth = 1;
			split.color = Color.white;

			// put all widgets in the order they are to appear in terminal
			term.addWidget([label, /*edit,*/ progressBar, hLayout]);

			// set some properties
			label.caption = "this is a label widget. To show single line text. Below is a progress bar:";
			progressBar.caption = "this is the progress bar";
			progressBar.size.maxHeight = 1;
			progressBar.max = 10;
			progressBar.progress = 0;

			// and this is how timerEvent can be used
			progressBar.onTimerEvent = delegate(QWidget caller, uinteger msecs){
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
				return false;
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
		/// run the app
		void run(){
			term.timerMsecs = 1000;
			term.run;
		}
	}
}