module demo;
version(demo){
	import qui.qui;
	import qui.widgets;
	
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
	public:
		this(){
			term = new QTerminal(QLayout.Type.Horizontal);
			term.addWidget([label, progressBar]);
			label.caption = "Progress bar: increases/decreases every 1/2 second. 1 2 3 4 5 6 7 8 9 10 9 8 7 6 5 4 3 2 1";
			progressBar.max = 10;
			progressBar.progress = 0;
			progressBar.onTimerEvent = delegate(QWidget caller){
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
			};
			term.registerWidget([label, progressBar]);
		}
		void run(){
			term.run;
		}
	}
}