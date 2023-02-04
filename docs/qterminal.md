# QTerminal

This is a QContainer over the entire terminal.

## Properties

* `bool stopOnInterrupt` - whether to stop UI loop (run function) on hangup
	interrupt (Ctrl+C)
* `ushort timerMsecs` - amount of milliseconds between timerEvents

## Functions

* `terminate()` - Stops UI loop. It is not instant.
* `run()` - runs the UI loop.
