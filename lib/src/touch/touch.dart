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
  
  Element elementHandle = element;
  // If requested, use handle.
  if (group.handle != null) {
    elementHandle = element.query(group.handle);
  }
  
  // -------------------
  // On TouchStart emulate DragStart
  // -------------------
  subs.add(elementHandle.onTouchStart.listen((TouchEvent event) {
    // Ignore the event if another widget is already being handled or if 
    // it is a multi-touch event.
    if (_emulDragHandled || event.touches.length > 1) return;
    
    _logger.finest('touchStart: emulating dragStart');
    
    event.preventDefault();
    Touch touch = event.changedTouches[0];
    
    // Set the flag to prevent other widgets from inheriting the touch event
    _emulDragHandled = true;
    
    _emulateDragStart(element, group, touch.page, touch.client);
  }));
  
  // -------------------
  // On TouchMove emulate Drag
  // -------------------
  subs.add(elementHandle.onTouchMove.listen((TouchEvent event) {
    // Ignore the event if NOT handled or if it is a multi-touch event.
    if (!_emulDragHandled || event.touches.length > 1) return;
    
    event.preventDefault();
    Touch touch = event.changedTouches[0];
    
    // The target in TouchEvent or Touch is always the element the touch 
    // originated. Get the element the finger is actually over.
    EventTarget target = document.elementFromPoint(touch.client.x, touch.client.y);
    
    // Interaction was not a click
    _emulDragMoved = true;
    
    _emulateDrag(element, group, target, touch.page, touch.client);
  }));
  
  // -------------------
  // On TochEnd emulate DragEnd
  // -------------------
  subs.add(elementHandle.onTouchEnd.listen((TouchEvent event) {
    // Ignore the event if NOT handled or if it is a multi-touch event.
    if (!_emulDragHandled || event.touches.length > 1) return;
    
    _logger.finest('touchEnd: emulating dragEnd');

    event.preventDefault();
    Touch touch = event.changedTouches[0];
    
    // The target in TouchEvent or Touch is always the element the touch 
    // originated. Get the element the finger is actually over.
    EventTarget target = document.elementFromPoint(touch.client.x, touch.client.y);
    
    _emulateDragEnd(element, group, target, touch.page, touch.client, 
        dropped: true);
  }));
  
  return subs;
}