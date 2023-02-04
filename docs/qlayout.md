# QLayout

This is a very basic container widget, which basically acts as if the widgets
it is containing, were 1 widget.

It will either place the widgets in a horizontal or vertical order.
It attempts to best mimic the sizing properties of its child widgets combined.

To create a horizontal layout, use the `QHorizontalLayout` widget, for
vertical, use `QVerticalLayout`.

## Sizing
QLayout will attempt to size all its child widgets equally.
For example, a `QVerticalLayout` will try to divide its height equally among
it's children, and will try to set its own width to it's children. It does so
while respecting it's children's size constraints.

The sizing algorithm is somewhat simple:
```psuedocode
Assign size across common axis to all widgets

Divide size across other axis among all (remaining) widgets.

If any widget's size constraints triggered, assign it the constrained size,
reduce its size from total available size, start over from step 2.
```

## Managing Child Widgets

QLayout provides these functions for managing child widgets:

* `widgetAdd(QWidget)` - adopts and adds a widget to the end
* `bool widgetRemove(QWidget)` - disowns and removes a widget.
