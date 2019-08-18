## QUI
QUI is a widget based Text User Interface library for the [D Language](http://dlang.org/).  
_(uses termbox under the hood.)_

---

## Features
1. Widget-based
1. Easy to add more widgets
2. Easy to get started with (`source/demo.d` explains how to use most of it)
3. Event-based
4. Timer Events
4. Support for mouse events 
5. Most, if not all, of the code is commented
---

## Setting it up

To use qui in your dub package, add this to `dub.json` dependencies:  
`"qui": "~>0.2.1"`  
or to `dub.sdl`:  
`dependency "qui" version="~>0.2.1"`

---

## Getting Started
Documentation for this package can be found [here](https://qui.dpldocs.info/qui.html).
### Building demo
The included demo configuration (`source/demo.d`) demonstrates the usage of all the included widgets. To build it, run the following:  
```
dub fetch qui
dub --build=release --config=demo qui
```
This will run the demo program.