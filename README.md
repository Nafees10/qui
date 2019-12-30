# QUI

QUI is a widget based Text User Interface library for the [D Language](http://dlang.org/).

---

## Features

1. Widget-based
1. Easy to add more widgets
1. Easy to get started with (`source/demo.d` explains how to use most of it)
1. Event-based
1. Timer Events
1. Support for mouse events
1. Most, if not all, of the code is commented

---

## Setting it up

To use qui in your dub package, run this in your dub package's directory:  
`dub add qui`

---

## Getting Started

All the widgets are contained in `qui.widgets`, and the base classes are in `qui.qui`.  
Documentation for this package can be found [here](https://qui.dpldocs.info/qui.html).

### Building demo

The included demo configuration (`source/demo.d`) demonstrates the usage of all the included widgets. To build it, run the following:

```bash
dub fetch qui
dub --build=release --config=demo qui
```

This will run the demo program.

---

## License
QUI is licensed under the MIT license - see [LICENSE](LICENSE).  
It also uses [Adam D. Ruppe](https://github.com/adamdruppe)'s [terminal.d](https://github.com/adamdruppe/arsd/blob/master/terminal.d) which is licensed under the Boost License - see `source/arsd/LICENSE`