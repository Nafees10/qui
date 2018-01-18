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
		// to put a border around everything
		ContainerWidget border;
		// because we want >1 widgets in terminal, but ContainerWidget allows only one
		QLayout mainLayout;
		// just a memo
		LogWidget logs;
		// because we want buttons to be in a vertical order, but mainLayout is horizontal
		QLayout buttonsContainer;
		// some buttons
		ButtonWidget incButton, decButton;
		// just a progress bar
		ProgressbarWidget progressBar;
	public:
		this(){
			term = new QTerminal("Dummy Caption", LayoutDisplayType.Horizontal);
			border = new ContainerWidget;
			border.margin = 2;
			border.marginChar = 'O';
			mainLayout = new QLayout(LayoutDisplayType.Horizontal);
			
			logs = new LogWidget();
			
			buttonsContainer = new QLayout(LayoutDisplayType.Vertical);
			incButton = new ButtonWidget("increase");
			decButton = new ButtonWidget("decrease");
			
			progressBar = new ProgressbarWidget(100, 50);
			
			// arrange them inside each other
			// buttons go inside the buttons container, to put them vertically
			buttonsContainer.addWidget ([incButton, decButton]);
			// then they go in order: memo:buttons:progressBar
			mainLayout.addWidget([
					logs,
					buttonsContainer,
					progressBar
				]);
			// and the whole container goes inside the form
			border.widget = mainLayout;
			term.addWidget(border);
			
			// register custom events, to handle button presses
			incButton.onMouseEvent = &increaseButtonPress;
			decButton.onMouseEvent = &decreaseButtonPres;
		}
		~this(){
			// destroy them all, or (IDK why) it causes an exception at end
			.destroy (progressBar);
			.destroy (decButton);
			.destroy (incButton);
			.destroy (buttonsContainer);
			.destroy (logs);
			.destroy (mainLayout);
			.destroy (border);
			.destroy (term);
		}
		void run(){
			term.run();
		}
		/// catch click from incButton
		void increaseButtonPress(MouseClick mouse){
			if (progressBar.progress - progressBar.total < 10){
				progressBar.progress = progressBar.total;
			}else{
				progressBar.progress = progressBar.progress + 10;
			}
			// add it to log
			logs.add("incButton pressed");
		}
		/// catch click from decButton
		void decreaseButtonPres(MouseClick mouse){
			if (progressBar.progress < 10){
				progressBar.progress = 0;
			}else{
				progressBar.progress = progressBar.progress - 10;
			}
			// add it to log
			logs.add("decButton pressed");
		}
	}
}