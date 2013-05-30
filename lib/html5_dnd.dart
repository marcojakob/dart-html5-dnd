/**
 * Helper library for native HTML5 Drag and Drop. There are [Draggable] elements 
 * that can be dropped inside [Dropzone] elements. 
 */
library html5_dnd;

import 'dart:html';
import 'dart:async';
import 'dart:collection';
import 'package:meta/meta.dart';
import 'package:js/js.dart' as js;
import 'package:logging/logging.dart';

final _logger = new Logger("html5_dnd");

/// Currently dragged element.
Draggable currentDraggable;

/**
 * Class for making an [Element] draggable.
 * 
 * ## Internet Explorer 9 ##
 * To enable Drag and Drop of elements other than links and images in Internet
 * Explorer 9 we need a workaround. The javascript file called 'dragdrop.ie9.js' 
 * must be added to the header of the application html.
 * 
 * TODO: Remove IE9 workaround when 
 * [Bug 10837](https://code.google.com/p/dart/issues/detail?id=10837) is fixed.
 */
class Draggable {
  /// The wrapped element.
  Element element;
  
  // -------------------
  // Options
  // -------------------
  /**
   * CSS class set to the draggable element during a drag. Default is 
   * 'dnd-dragging'. If null, no css class is added.
   */
  String draggingClass = 'dnd-dragging';
  
  /**
   * CSS class set to the html body tag during a drag. Default is 
   * 'dnd-drag-occurring'. If null, no CSS class is added.
   */
  String dragOccurringClass = 'dnd-drag-occurring';
  
  /**
   * Controls the feedback that the user is given during the dragenter and 
   * dragover events. When the user hovers over a target element, the browser's
   * cursor will indicate what type of operation is going to take place (e.g. a 
   * copy, a move, etc.). The effect can take on one of the following values: 
   * none, copy, link, move. Default is 'move'.
   */
  String dropEffect = 'move';
  
  /**
   * Disables the draggable if set to true.
   */
  bool disabled = false;
  
  /**
   * Function to create drag data for this draggable. The result is a map
   * with the type of data as key and the data as value. Default function 
   * returns 'text' as type with an empty String as data.
   */
  DragDataFunction dragDataFunction = (Draggable draggable) {
    return {'text': ''};
  };
  
  /**
   * Function to create a [DragImage] for this draggable. Default function
   * returns null.
   */
  DragImageFunction dragImageFunction = (Draggable draggable) {
    return null;
  };

  // -------------------
  // Events
  // -------------------
  /**
   * Fired when the user starts dragging this draggable.
   */
  Stream<DraggableEvent> get onDragStart => _onDragStart.stream;
  
  /**
   * Fired every time the mouse is moved while this draggable is being dragged.
   */
  Stream<DraggableEvent> get onDrag => _onDrag.stream;
  
  /**
   * Fired when the user releases the mouse button while dragging this 
   * draggable. Note: [onDragEnd] is called after onDrop in case there was
   * a drop.
   */
  Stream<DraggableEvent> get onDragEnd => _onDragEnd.stream;

  // -------------------
  // Private
  // -------------------
  StreamController<DraggableEvent> _onDragStart = new StreamController<DraggableEvent>();
  StreamController<DraggableEvent> _onDrag = new StreamController<DraggableEvent>();
  StreamController<DraggableEvent> _onDragEnd = new StreamController<DraggableEvent>();
  
  /**
   * Creates a draggable with the specified [element].
   * 
   * If [handle] is set to a value other than null, the drag is restricted to 
   * the specified subelement of [element].
   */
  Draggable(this.element, {String handle: null}) {
    // Enable native dragging.
    element.attributes['draggable'] = 'true';
    _enableIE9drag();

    // If requested, use handle.
    bool isHandle = false;    
    if (handle != null) {
      element.query(handle)
        ..onMouseDown.listen((_) {
          _logger.finest('handle onMouseDown');
          isHandle = true;
        })
        ..onMouseUp.listen((_) {
          _logger.finest('handle onMouseUp');
          isHandle = false;
        });
    }
    
    // Drag Start.
    element.onDragStart.listen((MouseEvent mouseEvent) {
      if (disabled || (handle != null && !isHandle)) {
        mouseEvent.preventDefault();
        return;
      }
      _logger.finest('onDragStart');
      // In Firefox it is possible to start selection outside of a draggable,
      // then drag entire selection. This leads to strange behavior, so we 
      // deactivate selection here.
      if (window.getSelection().rangeCount > 0) {
        window.getSelection().removeAllRanges();
      }
      
      isHandle = false;
      currentDraggable = this;
      
      // Add CSS classes
      if (draggingClass != null) {
        // Defer adding the dragging class until the end of the event loop.
        // This makes sure that the style is not applied to the drag image.
        Timer.run(() {
          _addCssClass(element, draggingClass);
        });
      }
      if (dragOccurringClass != null) {
        _addCssClass(document.body, dragOccurringClass);
      }
      
      // The allowed 'type of drag'. 
      // Unfortunately, in Firefox and IE, multiple allowed effects (like 'all'
      // or 'copyMove') do not work. They will not show the correct cursor when
      // the actual dataTransfer.dropEffect is set in onDragOver. Thus, only 
      // the values 'move', 'copy', 'link', and 'none' should be used.
      mouseEvent.dataTransfer.effectAllowed = dropEffect;
      
      Map<String, String> dragData = dragDataFunction(this);
      if (dragData != null) {
        dragData.forEach((String type, String data) {
          mouseEvent.dataTransfer.setData(type, data);
        });
      }
      
      DragImage dragImage = dragImageFunction(this);
      if (dragImage != null) {
        mouseEvent.dataTransfer.setDragImage(dragImage.image, dragImage.xOffset, 
            dragImage.yOffset);
      }
      
      if (_onDragStart.hasListener && !_onDragStart.isPaused 
          && !_onDragStart.isClosed) {
        _onDragStart.add(new DraggableEvent(this, mouseEvent));
      }
    });
    
    // Drag.
    element.onDrag.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled) return;
      
      // Just forward.
      if (_onDrag.hasListener && !_onDrag.isPaused 
          && !_onDrag.isClosed) {
        _onDrag.add(new DraggableEvent(this, mouseEvent));
      }
    });
    
    // Drag End.
    element.onDragEnd.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled) return;
      _logger.finest('onDragEnd');
      
      // Remove CSS classes.
      if (draggingClass != null) {
        _removeCssClass(element, draggingClass);
      }
      if (dragOccurringClass != null) {
        _removeCssClass(document.body, dragOccurringClass);
      }
      
      if (_onDragEnd.hasListener && !_onDragEnd.isPaused 
          && !_onDragEnd.isClosed) {
        _onDragEnd.add(new DraggableEvent(this, mouseEvent));
      }
      
      currentDraggable = null;
    });
  }
  
  /**
   * Workaround to enable Drag and Drop of elements other than links and images 
   * in Internet Explorer 9.
   */
  void _enableIE9drag() {
    if (element.draggable == null) {
      // HTML5 draggable support is not available --> try to use workaround.
      _logger.finest('Draggable is null, installing IE9 dragDrop() workaround');
      
      element.onSelectStart.listen((MouseEvent mouseEvent) {
        if (disabled) return;
        _logger.finest('IE9 Workaround: onSelectStart');
        
        // Prevent selection of text.
        mouseEvent.preventDefault();
        
        try {
          // Call 'dragDrop()' on element via javascript function.
          js.context.callDragDrop(element);
        } on NoSuchMethodError {
          _logger.severe('JavaScript method "callDragDrop" not found. Please' 
              + ' load the file "dragdrop.ie9.js" with your application html.');
        } catch(e) {
          _logger.severe('Calling dragDrop() as a workaround for IE9 failed: ' 
              + e.toString());
        }
      });
    }
  }
}

/**
 * Class for making an [Element] to a dropzone for [Draggable]s.
 */
class Dropzone {
  /// The wrapped dropzone element.
  Element element;
  
  // ----------
  // Options
  // ----------
  /**
   * CSS class set to the [element] when a draggable is dragged over this
   * dropzone. Default is 'dnd-over'. If null, no css class is added.
   */
  String overClass = 'dnd-over';
  
  /**
   * Disables the dropzone if set to true.
   */
  bool disabled = false;
  
  /**
   * List of all [Draggable] elements that this dropzone accepts. 
   * If the list is empty, all draggables are accepted.
   */
  Set<Element> acceptDraggables = new Set<Element>();
  
  // ----------
  // Events
  // ----------
  StreamController<DropzoneEvent> _onDragEnter = new StreamController<DropzoneEvent>();
  StreamController<DropzoneEvent> _onDragOver = new StreamController<DropzoneEvent>();
  StreamController<DropzoneEvent> _onDragLeave = new StreamController<DropzoneEvent>();
  StreamController<DropzoneEvent> _onDrop = new StreamController<DropzoneEvent>();
  
  /**
   * Fired when the mouse is first moved over this dropzone while dragging the 
   * current drag element.
   */
  Stream<DropzoneEvent> get onDragEnter => _onDragEnter.stream;
  
  /**
   * Fired as the mouse is moved over this dropzone when a drag of is occuring. 
   */
  Stream<DropzoneEvent> get onDragOver => _onDragOver.stream;
  
  /**
   * Fired when the mouse leaves the dropzone element while dragging.
   */
  Stream<DropzoneEvent> get onDragLeave => _onDragLeave.stream;
  
  /**
   * Fired at the end of the drag operation when the draggable is dropped
   * inside this dropzone.
   */
  Stream<DropzoneEvent> get onDrop => _onDrop.stream;
  
  
  // ----------
  // Private properties
  // ----------
  
  // Keep track of [Element]s where dragEnter or dragLeave has been fired on.
  // This is necessary as a dragEnter or dragLeave event is not only fired
  // on the [dropzoneElement] but also on its children. Now, whenever the 
  // [dragOverElements] is empty we know the dragEnter or dragLeave event
  // was fired on the real [dropzoneElement].
  Set<Element> _dragOverElements = new Set<Element>();
  
  /**
   * Creates a dropzone with the specified [element].
   */
  Dropzone(this.element) {
    bool dropAccept = false;
    
    // Drag Enter.
    element.onDragEnter.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled) return;
      
      // Necessary for IE?
      mouseEvent.preventDefault();
      
      _dragOverElements.add(mouseEvent.target);
      _logger.finest('onDragEnter {dragOverElements.length: ${_dragOverElements.length}}');
      
      // Only handle dropzone element itself and not any of its children.
      if (_dragOverElements.length == 1) {
        // Test if this dropzone accepts the drop of the current draggable.
        dropAccept = acceptDraggables.isEmpty 
            || acceptDraggables.contains(currentDraggable.element);
        if (dropAccept) {
          mouseEvent.dataTransfer.dropEffect = currentDraggable.dropEffect;
        } else {
          mouseEvent.dataTransfer.dropEffect = 'none';
          return; // Return here as drop is not accepted.
        }
        
        if (overClass != null) {
          _addCssClass(element, overClass);
        }
            
        if (_onDragEnter.hasListener && !_onDragEnter.isPaused 
            && !_onDragEnter.isClosed) {
          _onDragEnter.add(new DropzoneEvent(currentDraggable, this, mouseEvent));
        }
      }
    });
    
    // Drag Over.
    element.onDragOver.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled) return;
      
      if (dropAccept) {
        mouseEvent.dataTransfer.dropEffect = currentDraggable.dropEffect;
      } else {
        mouseEvent.dataTransfer.dropEffect = 'none';
        return; // Return here as drop is not accepted.
      }

      // This is necessary to allow us to drop.
      mouseEvent.preventDefault();
      
      if (_onDragOver.hasListener && !_onDragOver.isPaused 
          && !_onDragOver.isClosed) {
        _onDragOver.add(new DropzoneEvent(currentDraggable, this, mouseEvent));
      }
    });
    
    // Drag Leave.
    element.onDragLeave.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled) return;
      
      // Firefox fires too many onDragLeave events. This condition fixes it. 
      if (mouseEvent.target != mouseEvent.relatedTarget) {
        _dragOverElements.remove(mouseEvent.target);
      }
      
      _logger.finest('onDragLeave {dragOverElements.length: ${_dragOverElements.length}}');
      
      // Only handle on dropzone element and not on any of its children.
      if (_dragOverElements.length == 0) {
        if (overClass != null) {
          _removeCssClass(element, overClass);
        }
        
        if (_onDragLeave.hasListener && !_onDragLeave.isPaused 
            && !_onDragLeave.isClosed) {
          _onDragLeave.add(new DropzoneEvent(currentDraggable, this, 
              mouseEvent));
        }
      }
    });
    
    // Drop.
    element.onDrop.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled) return;
      _logger.finest('onDrop');
      
      // Stops browsers from redirecting.
      mouseEvent.preventDefault(); 
      
      if (overClass != null) {
        _removeCssClass(element, overClass);
      }
      
      if (_onDrop.hasListener && !_onDrop.isPaused 
          && !_onDrop.isClosed) {
        _onDrop.add(new DropzoneEvent(currentDraggable, this, mouseEvent));
      }
      
      // Clear variables used during the drag.
      _dragOverElements.clear();
      dropAccept = false;
    });
  }
  
  /**
   * Resets the dropzone. Might be necessary if the drop zone is dynamically
   * added/removed during a drag.
   */
  void resetDragOverElements() {
    _dragOverElements.clear();
  }
}

typedef Map<String, String> DragDataFunction(Draggable draggable);

typedef DragImage DragImageFunction(Draggable draggable);

/**
 * Event for [Draggable]s.
 */
class DraggableEvent {
  Draggable draggable;
  MouseEvent mouseEvent;
  
  DraggableEvent(this.draggable, this.mouseEvent);
}

/**
 * Event for [Dropzone]s.
 */
class DropzoneEvent {
  Draggable draggable;
  Dropzone dropzone;
  MouseEvent mouseEvent;
  
  DropzoneEvent(this.draggable, this.dropzone, this.mouseEvent);
}

/**
 * A drag feedback [image]. The [xOffset] and [yOffset] define where the image 
 * should appear relative to the mouse cursor.
 */
class DragImage {
  ImageElement image;
  int xOffset;
  int yOffset;
  
  DragImage(this.image, this.xOffset, this.yOffset);
}

/**
 * Calculates the index of the Element [element] in its parent. If there is no
 * parent, null is returned.
 */
int getElementIndexInParent(Element element) {
  if (element.parent == null) {
    return null;
  }
  int index = 0;
  var previous = element.previousElementSibling;
  while (previous != null) {
    index++;
    previous = previous.previousElementSibling;
  }
  return index;
}

/**
 * Adds the [cssClass] to the [element]. Optionally includes scoped style for
 * web components.
 */
void _addCssClass(Element element, String cssClass, {scopedStyle: false}) {
  element.classes.add(cssClass);
  
  // Workaround for scoped css inside web components.
  if (scopedStyle && element.attributes.containsKey('is')) {
    String scopedCssPrefix = '${element.attributes['is']}_';
    element.classes.add(scopedCssPrefix + cssClass);
  }
}

/**
 * Removes the [cssClass] to the [element]. Optionally removes scoped style for
 * web components.
 */
void _removeCssClass(Element element, String cssClass, {scopedStyle: false}) {
  element.classes.remove(cssClass);
  
  // Workaround for scoped css inside web components.
  if (scopedStyle && element.attributes.containsKey('is')) {
    String scopedCssPrefix = '${element.attributes['is']}_';
    element.classes.remove(scopedCssPrefix + cssClass);
  }
}