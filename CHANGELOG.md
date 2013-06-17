Changelog
================

## Version 0.1.0 (2013-06-05) ##
* First Version.

## Version 0.2.0 (2013-06-10) ##
* Changed API to using groups of Draggables/Dropzones/Sortables. Now options 
  and event listeners are set on a group instead of individual elements.
* Ability to install/uninstall elements. Adds/Removes event subscriptions on 
  an element.
* SortableEvent now carries information about the original group of the 
  dragged element and the new group it was dragged to. This enables 
  uninstalling in the previous group and installing in the new group.
* Other minor improvements in Sortable.

## Version 0.2.1 (2013-06-17) ##
* Fix Issue #6: Bug in Firefox when dragging over nested elements
* Fix Issue #1: overClass (.dnd-over) stays after drag ended
* Fix Issue #4: Support any HTML Element as drag image
* Fix Issue #5: Always use Drag Image Polyfill for IE9 drags