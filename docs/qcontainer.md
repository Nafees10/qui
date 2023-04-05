# QContainer

A fancy alternative to QLayout that houses only 1 child widget, but is able to
create space to fit any size widget. Intended to be used as a base class for
creating scrollable containers.

## Properties

The following public properties are available:

* `QWidget widget` _setter/getter_ - the child widget
* `uint scrollX` _setter/getter_ - how many rows scrolled out of view
* `uint scrollY` _setter/getter_ - how many columns scrolled out of view
* `uint scrollbarVisibleForMsecs` _setter/getter_ - how many milliseconds the
	scrollbar is visible for, after scrolling

## Events

QContainer overrides all the events from QWidget, along with the `disownEvent`
from QParent.

These events just forward the events to the child class, with the exception of
resize and scroll event, which will fix the viewport for the child before
forwarding.
