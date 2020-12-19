module demo;
version(demo){
	import qui.qui;
	import qui.widgets;
	import std.conv : to;
	import std.path;
	import std.file : thisExePath;
	import utils.misc : uinteger, integer, fileToArray;
	
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

			// prepare the layout in for the Memo and log
			hLayout.addWidget([memo, log]);
			{
				string[] lines = fileToArray(dirName(thisExePath)~dirSeparator~"README.md");
				foreach (line; lines){
					memo.lines.append(line.to!dstring);
				}
			}
			memo.wantsTab = false;

			// put all widgets in the order they are to appear in terminal
			term.addWidget([label, edit, progressBar, hLayout]);

			// set some properties
			label.caption = "this is a label widget. To show single line text. Below is a progress bar:";
			progressBar.caption = "this is the progress bar";
			progressBar.size.maxHeight = 1;
			progressBar.max = 10;
			progressBar.progress = 0;

			// hide progress bar on Ctrl+O
			term.onKeyboardEvent = delegate(QWidget caller, KeyboardEvent key){
				log.add(to!dstring("Terminal Keyboard Event: "~key.tostring));
				if (key.isCtrlKey){
					if (key.key == KeyboardEvent.CtrlKeys.CtrlO){
						progressBar.show = !progressBar.show;
						if (progressBar.show)
							log.add("progressbar shown");
						else
							log.add("progressbar hidden");
					}else if (key.key == KeyboardEvent.CtrlKeys.CtrlP){
						progressBar.size.maxHeight = (progressBar.size.maxHeight % 3) + 1;
						progressBar.requestResize();
						log.add("progressbar resized: "~progressBar.size.maxHeight.to!dstring);
					}else if (key.key == KeyboardEvent.CtrlKeys.CtrlL){
						log.show = !log.show;
						log.add("log "~to!dstring(log.show ? "shown" : "hidden"));
					}
				}
				return false;
			};

			// and this is how timerEvent can be used
			progressBar.onTimerEvent = delegate(QWidget caller, uinteger msecs){
				static increasing = true;
				ProgressbarWidget owner = cast(ProgressbarWidget)caller;
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
			memo.onActivateEvent = delegate(QWidget, bool isActive){
				log.add(to!dstring("Memo is now "~(isActive?"active":"inactive")));
				return false;
			};
			edit.onActivateEvent = delegate(QWidget, bool isActive){
				log.add(to!dstring("EditLine is now "~(isActive?"active":"inactive")));
				return false;
			};
			term.onMouseEvent = delegate(QWidget, MouseEvent mouse){
				log.add(to!dstring("Terminal MouseEvent: (" ~ mouse.x.to!string ~ ',' ~ mouse.y.to!string~')'));
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
		}
		/// run the app
		void run(){
			term.timerMsecs = 500;
			term.run;
		}
	}
}