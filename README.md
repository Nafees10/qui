# QUI

QUI is a widget based Text User Interface library for the [D Language](http://dlang.org/).

---

## Features

1. Widget-based
1. Easy to add more widgets
1. Widgets are isolated, each widget draws in it's own "area"
1. Easy to get started with (`source/demo.d` explains how to use most of it)
1. Event-based
1. Timer Events, the timer duration can be changed
1. Support for mouse events
1. Most, if not all, of the code is commented
1. Unicode characters supported

---

## Setting it up

To use qui in your dub package, run this in your dub package's directory:  
`dub add qui`  

---

## Getting Started

All the widgets are contained in `qui.widgets`, and the base classes are in `qui.qui`.  
You should also read through `docs/*.md` for a quick start on how to use and write new widgets.

### Building demo

The included demo configuration (`source/demo.d`) demonstrates the usage of some of the included widgets. To build & run it, run the following:

```bash
dub fetch qui
dub run qui --b=release --c=quidemo
```

---

## Documentation

See `docs/` for documentation on how to use qui and how to write widgets.  

Additionally, you could also see `source/qui/widgets.d` and see some existing widgets, this can be helpful in writing new widgets.

---

## Known Issues

See the issues tab. If you came across some new issue, start a new one.

---

## TODO for upcoming versions

1. Have `QLayout` manage scrolling of long widgets instead of implementing it in each widget

---

## License
QUI is licensed under the MIT license - see [LICENSE](LICENSE).  
QUI uses [Adam D. Ruppe](https://github.com/adamdruppe)'s [terminal.d](https://github.com/adamdruppe/arsd/blob/master/terminal.d) which is licensed under the Boost License - see `source/arsd/LICENSE`.
