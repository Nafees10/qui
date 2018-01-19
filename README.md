## QUI
QUI is a Text User Interface library for the [D Language](http://dlang.org/).  
It is based on [adamdruppe's arsd.terminal](https://github.com/adamdruppe/arsd/blob/master/terminal.d).  

---

### Features:
1. Widget-based - each widget controls a specfic part of the terminal display, one buggy widget won't mess with the whole terminal.
2. Easy to get started with
3. Event-based
4. Support for mouse events
5. Most, if not all, of the code is commented - Separate docs can be found in docs/ directory

---

### Some examples:
LogWidget and EditLineWidget, being used to input stuff and display it:
```
import qui.qui;
import qui.widgets;
void main(){
	App appInstance = new App;
	appInstance.run();
	.destroy(appInstance);
}
class App{
private:
	QTerminal term;
	LogWidget log;
	EditLineWidget edit;
public:
	this(){
		term = new QTerminal("LogWidget and EditLineWidget",LayoutDisplayType.Vertical);
		log = new LogWidget;
		edit = new EditLineWidget("type something here: ");
		// arrange them:
		term.addWidget([log,edit]);
		// set up event handlers
		edit.onKeyboardEvent = &editKeyboardEvent;
		// set up colors
		log.backgroundColor = hexToColor("FFFFFF");
		log.textColor = hexToColor("000000");
		// editLine input colors
		edit.textColor = hexToColor("000000");
		edit.backgroundColor = hexToColor("BFBFBF");
		// editLine caption colors
		edit.captionBackgroundColor = hexToColor("FFFFFF");
		edit.captionTextColor = hexToColor("000000");
	}
	~this(){
		// clean up everyting
		.destroy(term);
		.destroy(log);
		.destroy(edit);
	}
	/// starts the UI
	void run(){
		term.run();
	}
	// event handler for catching Enter key
	void editKeyboardEvent(KeyPress key){
		if (cast(char)key.key == '\n'){
			log.add("Entered: "~edit.text);
			edit.text = "";
		}
	}
}
```
The result will be something like:
![alt text](http://imgur.com/vpokN5Ql.png "Screenshot")