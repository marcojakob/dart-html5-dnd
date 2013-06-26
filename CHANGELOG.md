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

## Version 0.3.0 (2013-06-25) ##
* Completely emulating drag and drop in IE9 and partly in IE10 (when custom drag
  images are used): 
  	* The workaround with calling dragDrop() on IE did not work 
  	  reliably and was slow. Also, we could not have the drag image under the 
  	  mouse cursor as events would not be forwarded to element underneath.
    * No javascript file is needed any more and the dependency on js-interop
      has been removed.
    * Emulation works by listening to mouseDown, mouseUp and mouseMove events 
      and translating them to the HTML5 dragStart, drag, dragEnd, dragEnter,
      dragOver, dragLeave and drop events.
* More stable handling of nested elements. Instead of keeping track of
  dragOverElements in a list, the related target of the event is used to
  determine if it is an event that happened on the main element or bubbled
  up from child elements.
  
## Version 0.3.1 (2013-06-26) ##
* Touch Event support (Issue #3): Uses touchStart, touchMove, and touchEnd 
  events to emulate HTML5 drag and drop behaviour.
* Reorganized some parts. Now only html5_dnd.dart needs to be imported and 
  sortable is imported automatically. If some functionality like sortable isn't 
  used, Dart's treeshaking will make sure no unnecessary code is added.
* Add extended usage documentation to readme.