# QTerminal

This is a QContainer over the entire terminal.

## Properties

* `bool stopOnInterrupt` - whether to stop UI loop (run function) on hangup
	interrupt (Ctrl+C)
* `ushort timerMsecs` - amount of milliseconds between timerEvents
* `ushort updateMsecs` - minimum number of milliseconds to wait before a
	consecutive update event is triggered. Used as a fps limiter. Default value
	of 50 results in 20 fps.

## Functions

* `stop()` - Stops UI loop. It is not instant.
* `run()` - runs the UI loop.
