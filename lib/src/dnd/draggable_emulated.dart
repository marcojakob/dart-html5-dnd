part of html5_dnd;

/// Event emulating dragEnter. RelatedTarget is the element the mouse entered from.
const String EMULATED_DRAG_ENTER = 'emulatedDragEnter';

/// Event emulating dragOver. This is a bit different from the HTML5 dragOver 
/// event which is fired even when the mouse is not moved. 
/// RelatedTarget is the actual element under the mouse, which might either be
/// the drag image or the same element as target.
const String EMULATED_DRAG_OVER = 'emulatedDragOver';

/// Event emulating dragLeave. RelatedTarget is the element the mouse exited to.
const String EMULATED_DRAG_LEAVE = 'emulatedDragLeave';

/// Event emulating drop.
const String EMULATED_DROP = 'emulatedDrop';


// Subscriptions that need to be canceled on drag end.
StreamSubscription _subMouseMove;

bool _emulDragStarted = false;
DragImage _emulDragImage;

EventTarget _emulPrevMouseTarget;

Element _emulPrevCursorElement;
String _emulPrevCursorElementCursor;

/**
 * Installs emulated draggable behaviour for browsers that do not (completely) 
 * support HTML5 drag and drop events (IE9 and IE10). MouseDown, mouseMove
 * and mouseUp events are listened to and translated to HTML5 drag and drop
 * events.
 * 
 * The mouseMove and mouseUp event are not set on the element, but on the 
 * entire document. The reason is that the user may move the mouse wildly and 
 * quickly, and he might leave the dragged element behind. If the mousemove 
 * and mouseup functions were defined on the dragged element, the user would 
 * now lose control because the mouse is not over the element any more.
 */
// http://www.quirksmode.org/js/dragdrop.html
// http://aktuell.de.selfhtml.org/artikel/javascript/draganddrop/
List<StreamSubscription> _installEmulatedDraggable(Element element, DraggableGroup group) {
  
  List<StreamSubscription> subs = new List<StreamSubscription>();
  
  Element elementHandle = element;
  // If requested, use handle.
  if (group.handle != null) {
    elementHandle = element.query(group.handle);
  }
  
  // Listen for mouseDown.
  subs.add(elementHandle.onMouseDown.listen((MouseEvent downEvent) {
    // Don't let more than one widget handle mouseStart and only handle left button.
    if (_subMouseMove != null || downEvent.button != 0) return; 
    
    downEvent.preventDefault();
    MouseEvent mouseDownEvent = downEvent;
    
    // Subscribe to mouseMove on entire document.
    _subMouseMove = document.onMouseMove.listen((MouseEvent moveEvent) {
      if (!_emulDragStarted 
          && _dragStartMouseDistanceMet(mouseDownEvent.page, moveEvent.page)) {
        // -------------------
        // Emulate DragStart
        // -------------------
        _emulateDragStart(element, group, mouseDownEvent);
      }
      
      if (_emulDragStarted) {
        // -------------------
        // Emulate Drag  (is a bit different from the HTML5 drag event which 
        //                is fired even when the mouse is not moved)
        // -------------------
        _emulateDrag(element, group, moveEvent);
        
        // -------------------
        // Fire Dropzone events (DragEnter, DragOver, DragLeave)
        // -------------------
        _fireEventsForDropzone(moveEvent);
      }
    });
    
    // -------------------
    // Emulate DragEnd
    // -------------------
    _emulateDragEnd(element, group);
    
  })); // MouseDown.
  
  return subs;
}

void _emulateDragStart(Element element, DraggableGroup group, MouseEvent mouseDownEvent) {
  _logger.finest('emulated dragStart');
  
  _emulDragStarted = true;
  
  if (group.dragImageFunction != null) {
    _emulDragImage = group.dragImageFunction(element);
  } else {
    // No custom dragImage provided --> manually create it.
    _logger.finest('Manually creating drag image from current drag element.');
    _emulDragImage = new DragImage._forDraggable(element, mouseDownEvent.page);
  }
  // Add drag image.
  _emulDragImage._addEmulatedDragImage(element);
  
  group._handleDragStart(element, mouseDownEvent);
}

void _emulateDrag(Element element, DraggableGroup group, MouseEvent moveEvent) {
  _emulDragImage._updateEmulatedDragImagePosition(moveEvent.page);
  
  group._handleDrag(element, moveEvent);
}

void _emulateDragEnd(Element element, DraggableGroup group) {
  StreamSubscription subMouseUp;
  StreamSubscription subEscKey;
  StreamSubscription subFocusLost;
  
  Function dragEndFunc = (Event event) {
    // Cancel drag end subscriptions.
    subMouseUp.cancel();
    subEscKey.cancel();
    subFocusLost.cancel();
    
    // Cancel other subscriptions.
    if (_subMouseMove!= null) {
      _subMouseMove.cancel();
      _subMouseMove = null;
    }
    
    if (_emulDragStarted) {
      _logger.finest('emulated dragEnd');
      _emulDragImage._removeEumlatedDragImage();
      
      if (event is MouseEvent) {
        group._handleDragEnd(element, event);
      } else {
        group._handleDragEnd(element);
      }
    }
    
    // Reset variables.
    _emulDragImage = null;
    _emulDragStarted = false;
    
    // Reset cursor.
    _restoreCursor();
  };
  
  subMouseUp = document.onMouseUp.listen((MouseEvent upEvent) {
    // Fire the drop event.
    EventTarget target = upEvent.target;
    if (_emulDragImage != null && target == _emulDragImage.element) {
      // Forward event on the drag image to element underneath.
      target = _getElementUnder(upEvent);
    }
    target.dispatchEvent(_newMouseEvent(upEvent, EMULATED_DROP));    
    
    dragEndFunc(upEvent);
  });
  subEscKey = window.onKeyDown.listen((KeyboardEvent keyboardEvent) {
    if (keyboardEvent.keyCode == KeyCode.ESC) { 
      dragEndFunc(keyboardEvent);
    }
  });
  subFocusLost = window.onBlur.listen((Event event) {
    dragEndFunc(event);
  });
}

/**
 * Emulates the dropzone events (DragEnter, DragOver, and DragLeave).
 * If an event occurs on the [dragImageElement] it is forwarded to the element
 * underneath.
 */
void _fireEventsForDropzone(MouseEvent mouseEvent) {
  EventTarget target = mouseEvent.target;
  if (target == _emulDragImage.element) {
    // Forward events on the drag image to element underneath.
    target = _getElementUnder(mouseEvent);
  }
  
  if (_emulPrevMouseTarget == target) {
    // Mouse was moved on the same element --> fire dragOver.
    _setNoDropCursor(mouseEvent.target);
    target.dispatchEvent(
        _newMouseEvent(mouseEvent, EMULATED_DRAG_OVER, mouseEvent.target));
  } else {
    // Mouse entered a new element --> fire dragEnter.
    target.dispatchEvent(
        _newMouseEvent(mouseEvent, EMULATED_DRAG_ENTER, _emulPrevMouseTarget));
    
    if (_emulPrevMouseTarget != null) {
      // Mouse left the previous element --> fire dragLeave.
      _emulPrevMouseTarget.dispatchEvent(
          _newMouseEvent(mouseEvent, EMULATED_DRAG_LEAVE, target));
    }
    
    // Also fire the first dragOver event for the new element.
    _setNoDropCursor(mouseEvent.target, force: true);
    target.dispatchEvent(
        _newMouseEvent(mouseEvent, EMULATED_DRAG_OVER, mouseEvent.target));
    
    _emulPrevMouseTarget = target;
  }
}

/**
 * Detects if the mouse has been moved enough to start the dragging.
 */
bool _dragStartMouseDistanceMet(Point mouseDownPagePosition, Point mousePagePosition) {
  return math.max(
      (mouseDownPagePosition.x - mousePagePosition.x).abs(),
      (mouseDownPagePosition.y - mousePagePosition.y).abs()
  ) >= 1;
}

/**
 * Sets the cursor on [target] to 'no-drop'. The original cursor on the 
 * previous element is restored.
 * If [target] is the same as [_emulPrevCursorElement], the cursor is only
 * set if [force] is true. 
 */
void _setNoDropCursor(EventTarget target, {bool force: false}) {
  if (!force && target == _emulPrevCursorElement) return;
  
  _restoreCursor();
  
  if (target is Element) {
    // Set 'no-drop' as cursor.
    _emulPrevCursorElementCursor = target.style.cursor;
    target.style.cursor = 'no-drop';
    _emulPrevCursorElement = target;
  }
}

/**
 * Removes 'no-drop' cursor on [_emulPrevCursorElement] and set it to it's
 * original value.
 */
void _restoreCursor() {
  if (_emulPrevCursorElement != null) {
    if (_emulPrevCursorElementCursor != null) {
      _emulPrevCursorElement.style.cursor = _emulPrevCursorElementCursor;
    } else {
      _emulPrevCursorElement.style.removeProperty('cursor');
    }
    _emulPrevCursorElement = null;
    _emulPrevCursorElementCursor = null;
  }
}

/**
 * Returns the element that is one layer under the element where the mouse
 * is currently over. 
 */
EventTarget _getElementUnder(MouseEvent event) {
  var target = event.target;
  if (target is Element) {
    target.style.visibility = 'hidden';
    Element elementUnder = document.elementFromPoint(event.client.x, event.client.y);
    target.style.visibility = 'visible';
    if (elementUnder != null) {
      return elementUnder;
    }
  }
  // Could not get element under --> return original target.
  return target;
}

/**
 * Creates a new event from [e] with the [newType].
 */
MouseEvent _newMouseEvent(MouseEvent e, String newType, [EventTarget relatedTarget]) {
  return new MouseEvent(newType, 
      view: e.view, detail: e.detail, screenX: e.screen.x, 
      screenY: e.screen.y, clientX: e.client.x, clientY: e.client.y, 
      button: e.button, canBubble: e.bubbles, cancelable: e.cancelable, 
      ctrlKey: e.ctrlKey, altKey: e.altKey, shiftKey: e.shiftKey, 
      metaKey: e.metaKey, 
      relatedTarget: relatedTarget);
} 
