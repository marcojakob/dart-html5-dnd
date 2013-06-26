part of html5_dnd;

/**
 * Installs emulated dropzone behaviour for browsers that do not (completely)
 * support HTML5 drag and drop events (IE9 and IE10).
 * 
 * Listens to the custom emulated events fired by the emulated draggable.
 */
List<StreamSubscription> _installEmulatedDropzone(Element element, DropzoneGroup group) {
  List<StreamSubscription> subs = new List<StreamSubscription>();
  
  bool draggableAccepted = false;
  
  // -------------------
  // Emulate DragEnter
  // -------------------
  subs.add(element.on[EMULATED_DRAG_ENTER].listen((MouseEvent mouseEvent) {
    // Test if this dropzone accepts the current draggable.
    draggableAccepted = group._draggableAccepted();
    if (!draggableAccepted) return;
    
    _logger.finest('emulated dragEnter');
    
    // Only continue if the event is a real event generated for the main 
    // element and not bubbled up by any of its children. 
    if (_isMainEvent(element, mouseEvent.relatedTarget)) {
      // screenX and screenY were abused as pageX and pageY! TODO: Wait for #11452 to be fixed.
      Point mousePagePosition = mouseEvent.screen;
      group._handleDragEnter(element, mousePagePosition, mouseEvent.client, mouseEvent.target);
    }
  }));
  
  // -------------------
  // Emulate DragOver
  // -------------------
  subs.add(element.on[EMULATED_DRAG_OVER].listen((MouseEvent mouseEvent) {
    if (!draggableAccepted) return;
    
    // Related target is the actual element under the mouse.
    if (mouseEvent.relatedTarget != null && mouseEvent.relatedTarget is Element) {
      Element elementUnderMouse = mouseEvent.relatedTarget;
      
      // Set a new cursor (old cursor will be restored by EmulatedDraggableGroup)
      switch(currentDraggableGroup.dropEffect) {
        case DROP_EFFECT_MOVE:
          elementUnderMouse.style.cursor = 'move';
          break;
        case DROP_EFFECT_COPY:
          elementUnderMouse.style.cursor = 'copy';
          break;
        case DROP_EFFECT_LINK:
          elementUnderMouse.style.cursor = 'alias';
          break;
        default:
          elementUnderMouse.style.cursor = 'no-drop';
      }
    }
    
    // screenX and screenY were abused as pageX and pageY! TODO: Wait for #11452 to be fixed.
    Point mousePagePosition = mouseEvent.screen;
    group._handleDragOver(element, mousePagePosition, mouseEvent.client);
  }));
  
  // -------------------
  // Emulate DragLeave
  // -------------------
  subs.add(element.on[EMULATED_DRAG_LEAVE].listen((MouseEvent mouseEvent) {
    if (!draggableAccepted) return;
    
    _logger.finest('emulated dragLeave');
    
    // Only continue if the event is a real event generated for the main 
    // element and not bubbled up by any of its children. 
    if (_isMainEvent(element, mouseEvent.relatedTarget)) {
      // screenX and screenY were abused as pageX and pageY! TODO: Wait for #11452 to be fixed.
      Point mousePagePosition = mouseEvent.screen;
      group._handleDragLeave(element, mousePagePosition, mouseEvent.client,
          mouseEvent.target, mouseEvent.relatedTarget);
    }
  }));
  
  // -------------------
  // Emulate Drop
  // -------------------
  subs.add(element.on[EMULATED_DROP].listen((MouseEvent mouseEvent) {
    if (!draggableAccepted || !group._dropAllowed()) return;
    
    _logger.finest('emulated drop');
    
    // screenX and screenY were abused as pageX and pageY! TODO: Wait for #11452 to be fixed.
    Point mousePagePosition = mouseEvent.screen;
    group._handleDrop(element, mousePagePosition, mouseEvent.client);
  }));
  
  return subs;
}

/**
 * Returns true if either [target1] is an ancestor of [target2] or 
 * [target2] is a an ancestor of [target1].
 */
bool _areAncestors(EventTarget target1, EventTarget target2) {
  if (target1 is! Element || target2 is! Element) return false;
  
  return target1.contains(target2) || target2.contains(target1);
}