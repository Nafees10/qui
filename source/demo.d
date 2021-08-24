module demo;
version(demo){
	import qui.qui;
	import qui.widgets;
	import std.conv : to;
	import std.path;
	import std.file : thisExePath;
	import utils.misc :fileToArray;
	
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
			label = new TextLabelWidget("this is a label widget. To show single line text.");
			edit = new EditLineWidget("EditLineWidget, one line text editor: ");
			hLayout = new QLayout(QLayout.Type.Horizontal);
			memo = new MemoWidget();
			log = new LogWidget();
			
			// show README.md in memo
			{
				string[] lines = fileToArray(dirName(thisExePath)~dirSeparator~"README.md");
				foreach (line; lines){
					memo.lines.append(line.to!dstring);
				}
			}

			term.setActiveWidgetCycleKey('`'); // '`' key will be used for moving between active widgets
			term.terminateOnHangup = false; // do not close/terminate when Ctrl+C is pressed

			// put all widgets in the order they are to appear in terminal
			hLayout.addWidget([memo, log]);
			term.addWidget([label, edit, hLayout]);

			term.onKeyboardEvent = delegate(QWidget caller, KeyboardEvent key){
				log.add(to!dstring("Terminal Keyboard Event: "~key.tostring));
				if (!key.pressed)
					return false; // do nothing on key release
				// Ctrl+L is for toggling log shown/hidden, Ctrl+E to make EditLine active widget
				if (key.isCtrlKey){
					if (key.key == KeyboardEvent.CtrlKeys.CtrlL){
						log.show = !log.show;
						log.add("log "~to!dstring(log.show ? "shown" : "hidden"));
					}else if (key.key == KeyboardEvent.CtrlKeys.CtrlE){
						log.add("jump to the EditLine");
						term.activateWidget(edit);
					}
				}
				// Escape to exit
				if (key.key == Key.Escape)
					term.terminate;
				return false;
			};

			// just print these events to log
			memo.onActivateEvent = delegate(QWidget, bool isActive){
				log.add(to!dstring("Memo is now "~(isActive?"active":"inactive")));
				return false;
			};
			edit.onActivateEvent = delegate(QWidget, bool isActive){
				log.add(to!dstring("EditLine is now "~(isActive?"active":"inactive")));
				return false;
			};
			term.onMouseEvent = delegate(QWidget, MouseEvent mouse){
				log.add(to!dstring("Terminal MouseEvent: "~mouse.tostring));
				return false;
			};
		}
		~this(){
			// destroy all widgets
			.destroy(term);
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