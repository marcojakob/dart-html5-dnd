part of html5_dnd;

/**
 * Touch support for HTML5 Drag and Drop.
 * 
 * Installs touch events on the specified [element]. The touch events are 
 * translated to HTML5 drag and drop events.
 * 
 * This is inspired by the javascript library jQuery UI Touch Punch
 * see http://touchpunch.furf.com/.
 */
List<StreamSubscription> _installTouchEvents(Element element, DraggableGroup group) {
  List<StreamSubscription> subs = new List<StreamSubscription>();
  
  subs.add(element.onTouchStart.listen((TouchEvent startEvent) {
    // Ignore the event if another widget is already being handled or if 
    // it is a multi-touch event.
    if (_emulDragHandled || startEvent.touches.length > 1) return;
  
    Touch startTouch = startEvent.changedTouches[0];
    // Get the element the finger is actually over.
    EventTarget startTarget = document.elementFromPoint(startTouch.client.x, startTouch.client.y);
    
    // Return if no valid drag start target was touched.
    if(!_isValidDragStartTarget(element, startTarget, group.handle, group.cancel)) return;
    
    // Set the flag to prevent other widgets from inheriting the touch event
    _emulDragHandled = true;
    
    // Remove all text selections.
    html5.clearTextSelections();
    
    _emulSubs.add(element.onTouchMove.listen((TouchEvent moveEvent) {
      // Ignore the event if it is a multi-touch event.
      if (moveEvent.touches.length > 1) return;
      
      // Prvent scrolling.
      moveEvent.preventDefault();
      
      Touch moveTouch = moveEvent.changedTouches[0];
      
      if (!_emulDragMoved && _distanceMet(startTouch.page, moveTouch.page)) {
        // The drag start distance was met. Actually start the drag.
        
        // -------------------
        // Emulate DragStart
        // -------------------
        _logger.finest('touch: emulating dragStart');
        
        _emulDragMoved = true;
        _emulateDragStart(element, group, startTouch.page, startTouch.client);
      }
      
      if (_emulDragMoved) {
        // -------------------
        // Emulate Drag
        // -------------------
        
        // Get the element the finger is actually over.
        EventTarget moveTarget = document.elementFromPoint(moveTouch.client.x, moveTouch.client.y);
        
        _emulateDrag(element, group, moveTarget, moveTouch.page, moveTouch.client);
      }
    }));
    
    // -------------------
    // Emulate DragEnd
    // -------------------
    _emulSubs.add(element.onTouchEnd.listen((TouchEvent endEvent) {
      // Ignore the event if it is a multi-touch event.
      if (endEvent.touches.length > 1) return;
      
      _logger.finest('touch: emulating dragEnd');

      endEvent.preventDefault();
      Touch endTouch = endEvent.changedTouches[0];
      
      // Get the element the finger is actually over.
      EventTarget endTarget = document.elementFromPoint(endTouch.client.x, 
          endTouch.client.y);
      
      _emulateDragEnd(element, group, endTarget, endTouch.page, endTouch.client, 
          dropped: true);
    }));
    
  })); // TouchStart.
  
  return subs;
}