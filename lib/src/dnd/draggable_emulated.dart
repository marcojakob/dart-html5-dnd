part of html5_dnd;

/// Event emulating dragEnter. RelatedTarget is the element the mouse entered from.
const String EMULATED_DRAG_ENTER = 'emulatedDragEnter';

/// Event emulating dragOver. This is a bit different from the HTML5 dragOver 
/// event which is fired even when the mouse is not moved. 
/// RelatedTarget is the actual element under the mouse, which might either be
/// the drag image or the same element as target. This is used to style the 
/// cursor. If no relatedTarget is supplied, the cursor is not changed.
const String EMULATED_DRAG_OVER = 'emulatedDragOver';

/// Event emulating dragLeave. RelatedTarget is the element the mouse exited to.
const String EMULATED_DRAG_LEAVE = 'emulatedDragLeave';

/// Event emulating drop.
const String EMULATED_DROP = 'emulatedDrop';


/// Subscriptions that need to be canceled on drag end.
List<StreamSubscription> _emulSubs = new List<StreamSubscription>();
/// Flag to prevent multiple widgets to handle the event.
bool _emulDragHandled = false;
/// Flag to determine if there was enough movement for it to be a drag.
bool _emulDragMoved = false;
/// The manually created drag image.
DragImage _emulDragImage;
/// Keeps track of the previous mouse target to fire dragLeave events on it.
EventTarget _emulPrevMouseTarget;

/// The element where the cursor might have been changed.
Element _emulCursorElement;
/// Saves the original cursor to be able to restore it.
String _emulCursorElementCursor;

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
List<StreamSubscription> _installEmulatedDraggable(Element element, DraggableGroup group) {
  // Subscriptions to uninstall element.
  List<StreamSubscription> subs = new List<StreamSubscription>();
  
  // Listen for mouseDown.
  subs.add(element.onMouseDown.listen((MouseEvent downEvent) {
    // Don't let more than one widget handle mouseStart and only handle left button.
    // And only handle dragStart if a valid drag start target was clicked.
    if (_emulDragHandled || downEvent.button != 0 || !_isValidDragStartTarget(
            element, downEvent.target, group.handle, group.cancel)) 
      return;
      
    // Text selections should not be a problem with emulated draggable, but it
    // seems better usability to remove text selection when dragging something.
    utils.clearTextSelections();
    
    // Set the flag to prevent other widgets from inheriting the event
    _emulDragHandled = true;
    
    downEvent.preventDefault();
    MouseEvent mouseDownEvent = downEvent;
    
    // Subscribe to mouseMove on entire document.
    _emulSubs.add(document.onMouseMove.listen((MouseEvent moveEvent) {
      if (!_emulDragMoved && _distanceMet(mouseDownEvent.page, moveEvent.page)) {
        // The drag start distance was met. Actually start the drag.
        
        // -------------------
        // Emulate DragStart
        // -------------------
        _logger.finest('emulating dragStart');
        
        _emulDragMoved = true;
        _emulateDragStart(element, group, mouseDownEvent.page, mouseDownEvent.client);
      }
      
      if (_emulDragMoved) {
        // -------------------
        // Emulate Drag  (is a bit different from the HTML5 drag event which 
        //                is fired even when the mouse is not moved)
        // -------------------
        _emulateDrag(element, group, moveEvent.target, moveEvent.page, 
            moveEvent.client);
      }
    }));
    
    
    // -------------------
    // Emulate DragEnd
    // -------------------
    _emulSubs.add(document.onMouseUp.listen((MouseEvent upEvent) {
      // Fire dragEnd and indicate that it was dropped.
      _emulateDragEnd(element, group, upEvent.target, upEvent.page, upEvent.client, 
          dropped: true);
    }));
    
    // Drag ends when escape key is hit.
    _emulSubs.add(window.onKeyDown.listen((KeyboardEvent keyboardEvent) {
      if (keyboardEvent.keyCode == KeyCode.ESC) { 
        _emulateDragEnd(element, group, keyboardEvent.target, const Point(0, 0), 
            const Point(0, 0));
      }
    }));
    
    // Drag ends when focus is lost.
    _emulSubs.add(window.onBlur.listen((Event event) {
      _emulateDragEnd(element, group, event.target, const Point(0, 0), 
          const Point(0, 0));
    }));
    
  })); // MouseDown.
  
  return subs;
}

/**
 * Emulates a drag start by manually creating a drag image.
 */
void _emulateDragStart(Element element, DraggableGroup group, 
                       Point mousePagePosition, Point mouseClientPosition) {
  
  if (group.dragImageFunction != null) {
    _emulDragImage = group.dragImageFunction(element);
  } else {
    // No custom dragImage provided --> manually create it.
    _logger.finest('Manually creating drag image from current drag element.');
    _emulDragImage = new DragImage._forDraggable(element, mousePagePosition);
  }
  // Add drag image.
  _emulDragImage._addEmulatedDragImage(element);
  
  group._handleDragStart(element, mousePagePosition, mouseClientPosition);
}

/**
 * Emulates a drag by updating the drag image position.
 */
void _emulateDrag(Element element, DraggableGroup group, EventTarget target, 
                  Point mousePagePosition, Point mouseClientPosition) {
  _emulDragImage._updateEmulatedDragImagePosition(mousePagePosition);
  
  group._handleDrag(element, mousePagePosition, mouseClientPosition);
  
  // -------------------
  // Fire Dropzone events (DragEnter, DragOver, DragLeave)
  // -------------------
  if (target != null) {
    _dispatchDropzoneEvents(element, target, mousePagePosition, 
        mouseClientPosition, changeCursor: true);
  }
}

/**
 * Emulates a drag end by removing the drag image.
 * 
 * If [dropped] is true, a drop event is fired before the dragEnd.
 */
void _emulateDragEnd(Element element, DraggableGroup group, EventTarget target,
                  Point mousePagePosition, Point mouseClientPosition, 
                  {bool dropped: false}) {

  if (_emulDragMoved) {
    _logger.finest('emulating dragEnd');
    _emulDragImage._removeEumlatedDragImage();
    
    if (dropped) {
      // Fire the drop event.
      EventTarget realTarget = _getRealTarget(target, mouseClientPosition);
      
      realTarget.dispatchEvent(_createEmulatedMouseEvent(EMULATED_DROP, null, 
                                                         mousePagePosition, mouseClientPosition));  
    }
    
    group._handleDragEnd(element, mousePagePosition, mouseClientPosition);
  }
  
  // Restore cursor.
  _restoreCursor();
  
  // Cancel all subscriptions that were added when drag started.
  _emulSubs.forEach((StreamSubscription s) => s.cancel());
  _emulSubs.clear();
  
  // Reset variables.
  _emulDragHandled = false;
  _emulDragMoved = false;
  _emulDragImage = null;
  _emulPrevMouseTarget = null;
}

/**
 * Fires the dropzone events (DragEnter, DragOver, and DragLeave).
 * If an event occurs on the [dragImageElement] it is forwarded to the element
 * underneath.
 * 
 * If [changeCursor] is true, the appropriate cursor is set.
 */
void _dispatchDropzoneEvents(Element element, EventTarget mouseEventTarget, 
                             Point mousePagePosition, Point mouseClientPosition, 
                             {changeCursor: false}) {
  
  // Determine the actual target that should receive the event.
  EventTarget realTarget = _getRealTarget(mouseEventTarget, mouseClientPosition);
  
  if (_emulPrevMouseTarget == realTarget) {
    // Mouse was moved on the same element --> fire dragOver.
    if (changeCursor) {
      _setNoDropCursor(mouseEventTarget);
    }
    realTarget.dispatchEvent(
        _createEmulatedMouseEvent(EMULATED_DRAG_OVER, mouseEventTarget, 
                                  mousePagePosition, mouseClientPosition));
    
  } else {
    // Mouse entered a new element --> fire dragEnter.
    realTarget.dispatchEvent(
        _createEmulatedMouseEvent(EMULATED_DRAG_ENTER, _emulPrevMouseTarget, 
                                  mousePagePosition, mouseClientPosition));
    
    if (_emulPrevMouseTarget != null) {
      // Mouse left the previous element --> fire dragLeave.
      _emulPrevMouseTarget.dispatchEvent(
          _createEmulatedMouseEvent(EMULATED_DRAG_LEAVE, realTarget, 
                                    mousePagePosition, mouseClientPosition));
    }
    
    // Also fire the first dragOver event for the new element.
    if (changeCursor) {
      _setNoDropCursor(mouseEventTarget, force: true);
    }
    realTarget.dispatchEvent(
        _createEmulatedMouseEvent(EMULATED_DRAG_OVER, mouseEventTarget, 
                                  mousePagePosition, mouseClientPosition));
    
    _emulPrevMouseTarget = realTarget;
  }
}

/**
 * Detects if the mouse has been moved enough to start the dragging.
 */
bool _distanceMet(Point startPoint, Point endPoint) {
  return math.max(
      (startPoint.x - endPoint.x).abs(),
      (startPoint.y - endPoint.y).abs()
  ) >= 1;
}

/**
 * Sets the cursor on [target] to 'no-drop'. The original cursor on the 
 * previous element is restored.
 * If [target] is the same as [_emulCursorElement], the cursor is only
 * set if [force] is true. 
 */
void _setNoDropCursor(EventTarget target, {bool force: false}) {
  if (!force && target == _emulCursorElement) return;
  
  _restoreCursor();
  
  if (target is Element) {
    // Set 'no-drop' as cursor.
    _emulCursorElementCursor = target.style.cursor;
    target.style.cursor = 'no-drop';
    _emulCursorElement = target;
  }
}

/**
 * Removes 'no-drop' cursor on [_emulCursorElement] and set it to its
 * original value.
 */
void _restoreCursor() {
  if (_emulCursorElement != null) {
    if (_emulCursorElementCursor != null) {
      _emulCursorElement.style.cursor = _emulCursorElementCursor;
    } else {
      _emulCursorElement.style.removeProperty('cursor');
    }
    _emulCursorElement = null;
    _emulCursorElementCursor = null;
  }
}

/**
 * Returns the actual target where events should be fired on. If the mouse is
 * over the drag image, the element below is returned, otherwise, the [target]
 * itself is returend.
 */
EventTarget _getRealTarget(EventTarget target, Point mouseClientPosition) {
  EventTarget realTarget = target;
  
  if (utils.contains(_emulDragImage.element, target)) {
    // Forward events on the drag image to element underneath.
    _emulDragImage.element.style.visibility = 'hidden';
    realTarget = document.elementFromPoint(mouseClientPosition.x, 
        mouseClientPosition.y);
    _emulDragImage.element.style.visibility = 'visible';
  }
  
  return realTarget;
}

/**
 * Creates a new [MouseEvent] of type [type].
 * 
 * **Important!** There is currently no way to set the event's pageX and pageY
 * property. Because we need this, we abuse screenX and screenY for the pageX
 * and pageY property!
 * TODO: Fix this once https://code.google.com/p/dart/issues/detail?id=11452
 * is fixed!!
 */
MouseEvent _createEmulatedMouseEvent(String type, EventTarget relatedTarget, 
                                     Point mousePagePosition, Point mouseClientPosition) {
  return new MouseEvent(type, view: window, detail: 1, 
      // !! Dangerous workaround start!!
      screenX: mousePagePosition.x, screenY: mousePagePosition.y, 
      // !! Dangerous workaround end!!
      clientX: mouseClientPosition.x, clientY: mouseClientPosition.y, 
      button: 0, canBubble: true, cancelable: true, 
      ctrlKey: false, altKey: false, shiftKey: false, 
      metaKey: false, relatedTarget: relatedTarget);
}
