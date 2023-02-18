# QUI
QUI is a Text User Interface library for the [D Language](http://dlang.org/).

---

## Features

1. OOP based
1. Support for Mouse events
1. Abstracted scrolling
1. Tries to optimise drawing

---

## Setting it up
To use qui in your dub package, run this in your dub package's directory:
```bash
dub add qui
```

---

## Getting Started
Some built in widgets are contained in `qui.widgets`, and the base classes are
in `qui.qui`.

You should also read through `docs/*.md` for a quick start on how to use and
write new widgets.

### Building demo
The included demo configuration (`source/demo.d`) demonstrates the usage of
some of the included widgets. To build & run it, run the following:
```bash
dub fetch qui
dub run qui -b=release -c=quidemo
```

---

## Documentation
See `docs/` for documentation on how to use qui and how to write widgets.

Additionally, you could also see `source/qui/widgets.d` and see some existing
widgets, this can be helpful in writing new widgets.

---

## Known Issues
See the issues tab.

---

## `TODO` for upcoming versions
See issues marked as `enhancement`.

---

## License
QUI is licensed under the MIT license - see [LICENSE](LICENSE).  

QUI uses [Adam D. Ruppe](https://github.com/adamdruppe)'s
[terminal.d](https://github.com/adamdruppe/arsd/blob/master/terminal.d) which
is licensed under the Boost License - see `source/arsd/LICENSE`.
