part of html5_dnd;

/**
 * Manages a group of dropzones and their options and event listeners.
 */
class DropzoneGroup extends Group {
  // -------------------
  // Dropzone Options
  // -------------------
  /**
   * Specifies which draggable groups it accepts. If no [accept] are 
   * specified, this group will accept all draggables.
   */
  Set<DraggableGroup> accept = new Set<DraggableGroup>();
  
  // -------------------
  // Dropzone Events
  // -------------------
  StreamController<DropzoneEvent> _onDragEnter;
  StreamController<DropzoneEvent> _onDragOver;
  StreamController<DropzoneEvent> _onDragLeave;
  StreamController<DropzoneEvent> _onDrop;
  
  /**
   * Fired when the mouse is first moved over this dropzone while dragging the 
   * current drag element.
   */
  Stream<DropzoneEvent> get onDragEnter {
    if (_onDragEnter == null) {
      _onDragEnter = new StreamController<DropzoneEvent>.broadcast(sync: true, 
          onCancel: () => _onDragEnter = null);
    }
    return _onDragEnter.stream;
  }
  
  /**
   * Fired as the mouse is moved over this dropzone when a drag of is occuring. 
   */
  Stream<DropzoneEvent> get onDragOver {
    if (_onDragOver == null) {
      _onDragOver = new StreamController<DropzoneEvent>.broadcast(sync: true, 
          onCancel: () => _onDragOver = null);
    }
    return _onDragOver.stream;
  }
  
  /**
   * Fired when the mouse leaves the dropzone element while dragging.
   */
  Stream<DropzoneEvent> get onDragLeave {
    if (_onDragLeave == null) {
      _onDragLeave = new StreamController<DropzoneEvent>.broadcast(sync: true, 
          onCancel: () => _onDragLeave = null);
    }
    return _onDragLeave.stream;
  }
  
  /**
   * Fired at the end of the drag operation when the draggable is dropped
   * inside this dropzone.
   */
  Stream<DropzoneEvent> get onDrop {
    if (_onDrop == null) {
      _onDrop = new StreamController<DropzoneEvent>.broadcast(sync: true, 
          onCancel: () => _onDrop = null);
    }
    return _onDrop.stream;
  }
  
  
  /**
   * Installs dropzone behaviour on [element] and registers it in this group.
   */
  void install(Element element) {
    super.install(element);
    
    List<StreamSubscription> subs = new List<StreamSubscription>();
    
    // Install as HTML5 dropzone for all browsers except IE9.
    if (html5.supportsDraggable) {
      subs.addAll(_installDropzone(element, this));
    }
    
    // Install as emulated dropzone for IE9 and IE10.
    if (!html5.supportsSetDragImage) {
      subs.addAll(_installEmulatedDropzone(element, this));
    }
    
    installedElements[element].addAll(subs);
  }
  
  void _handleDragEnter(Element element, Point mousePagePosition, 
                        Point mouseClientPosition, EventTarget target) {
    _logger.finest('handleDragEnter');
    
    if (currentDraggableGroup.overClass != null) {
      String overClass = currentDraggableGroup.overClass;
      element.classes.add(overClass);
      
      // Make sure overClass is removed when drag ended. Is necessary 
      // because if drag is aborted (e.g. with esc-key), no dragLeave or
      // drop event is fired on the dropzone.
      StreamSubscription dragEndSub;
      dragEndSub = currentDraggableGroup.onDragEnd.listen((_) {
        element.classes.remove(overClass);
        dragEndSub.cancel();
      });
    }
    
    if (_onDragEnter != null) {
      _onDragEnter.add(new DropzoneEvent(currentDraggable, 
          element, mousePagePosition, mouseClientPosition));
    }
  }
  
  void _handleDragOver(Element element, Point mousePagePosition, Point mouseClientPosition) {
    if (_onDragOver != null) {
      _onDragOver.add(new DropzoneEvent(currentDraggable, element, 
          mousePagePosition, mouseClientPosition));
    }
  }
  
  void _handleDragLeave(Element element, Point mousePagePosition, 
                        Point mouseClientPosition, EventTarget target,
                        EventTarget relatedTarget) {
    _logger.finest('handleDragLeave');
    
    if (currentDraggableGroup.overClass != null) {
      element.classes.remove(currentDraggableGroup.overClass);
    }
    
    if (_onDragLeave != null) {
      _onDragLeave.add(new DropzoneEvent(currentDraggable, element,
          mousePagePosition, mouseClientPosition));
    }
  }
  
  void _handleDrop(Element element, Point mousePagePosition, Point mouseClientPosition) {
    _logger.finest('handleDrop');
    
    if (_onDrop != null) {
      _onDrop.add(new DropzoneEvent(currentDraggable, element, 
          mousePagePosition, mouseClientPosition));
    }
  }
  
  /**
   * Returns true if an element of [currentDraggableGroup] should be accepted 
   * by this dropzone.
   */
  bool _draggableAccepted() {
    return accept == null || accept.isEmpty 
        || accept.contains(currentDraggableGroup);
  }
  
  /**
   * Returns true if the [currentDraggableGroup.dropEffect] is one of 'copy', 
   * 'link', or 'move'. Drop effect 'none' (or any invalid drop effect) will 
   * not allow drop.
   */
  bool _dropAllowed() {
    String dropEffect = currentDraggableGroup.dropEffect;
    return dropEffect == DraggableGroup.DROP_EFFECT_COPY
        || dropEffect == DraggableGroup.DROP_EFFECT_LINK
        || dropEffect == DraggableGroup.DROP_EFFECT_MOVE;
  }
}

List<StreamSubscription> _installDropzone(Element element, DropzoneGroup group) {
  List<StreamSubscription> subs = new List<StreamSubscription>();
  
  bool draggableAccepted = false;
  
  // -------------------
  // DragEnter
  // -------------------
  subs.add(element.onDragEnter.listen((MouseEvent mouseEvent) {
    // Do nothing if no element of this dnd is dragged.
    if (currentDraggable == null) return;
    
    // Firefox fires too many dragEnter events. This condition fixes it. 
    // Actually, according to W3C spec, a dragEnter event should not have a 
    // related target at all
    if (mouseEvent.target == mouseEvent.relatedTarget) return;
    
    // Necessary for IE?
    mouseEvent.preventDefault();
    
    _logger.finest('dragEnter');
    
    // Related target (the element dragged from) is the last entered element.
    var relatedTarget = _lastDragEnterTarget;
    
    // Save current target.
    _lastDragEnterTarget = mouseEvent.target;
    
    // Only continue if the event is a real event generated for the main 
    // element and not bubbled up by any of its children. 
    if (_isMainEvent(element, relatedTarget)) {
      // Test if this dropzone accepts the current draggable.
      draggableAccepted = group._draggableAccepted();
      if (draggableAccepted) {
        mouseEvent.dataTransfer.dropEffect = currentDraggableGroup.dropEffect;
      } else {
        mouseEvent.dataTransfer.dropEffect = 'none';
        return; // Return here as drop is not accepted.
      }
      
      group._handleDragEnter(element, mouseEvent.page, mouseEvent.client, 
          mouseEvent.target);
    } 
  }));
  
  // -------------------
  // DragOver
  // -------------------
  subs.add(element.onDragOver.listen((MouseEvent mouseEvent) {
    // Do nothing if no element of this dnd is dragged.
    if (currentDraggable == null) return;
    
    if (draggableAccepted) {
      mouseEvent.dataTransfer.dropEffect = currentDraggableGroup.dropEffect;
    } else {
      mouseEvent.dataTransfer.dropEffect = 'none';
      return; // Return here as drop is not accepted.
    }

    // This is necessary to allow us to drop.
    mouseEvent.preventDefault();
    
    group._handleDragOver(element, mouseEvent.page, mouseEvent.client);
  }));
  
  // -------------------
  // DragLeave
  // -------------------
  subs.add(element.onDragLeave.listen((MouseEvent mouseEvent) {
    // Do nothing if no element of this dnd is dragged.
    if (currentDraggable == null || !draggableAccepted) return;
    
    // Firefox fires too many dragLeave events. This condition fixes it. 
    // Actually, according to W3C spec, a dragLeave event should not have a 
    // related target at all
    if (mouseEvent.target == mouseEvent.relatedTarget) return;
    
    _logger.finest('dragLeave');
    
    // Related target (the element dragged to) is the last entered element.
    var relatedTarget;
    if (mouseEvent.target != _lastDragEnterTarget) {
      relatedTarget = _lastDragEnterTarget;
    } else {
      // The mouse left the main element. When this happens, there is no 
      // dragEnter event before the dragLeave because the entered element would
      // be null or an element outside of the main element.
      relatedTarget = null;      
    }
    
    // Only continue if the event is a real event generated for the main 
    // element and not bubbled up by any of its children. 
    if (_isMainEvent(element, relatedTarget)) {
      // Main element was left so reset the targets.
      _lastDragEnterTarget = null;
      
      group._handleDragLeave(element, mouseEvent.page, mouseEvent.client,
          mouseEvent.target, mouseEvent.relatedTarget);
    }
  }));
  
  // -------------------
  // Drop
  // -------------------
  subs.add(element.onDrop.listen((MouseEvent mouseEvent) {
    // Do nothing if no element of this dnd is dragged.
    if (currentDraggable == null || !draggableAccepted) return;
    
    _logger.finest('drop');
    
    // Stops browsers from redirecting.
    mouseEvent.preventDefault(); 
    
    group._handleDrop(element, mouseEvent.page, mouseEvent.client);
  }));
  
  return subs;
}


// As dragEnter and dragLeave events do not have the relatedTarget property set, 
// we keep track of the last target the user entered and use this as related target.
EventTarget _lastDragEnterTarget;

/**
 * Returns true if the mouse event with [relatedTarget] is actually a real event
 * generated for [mainElement] and not bubbled up by any of its children. 
 * 
 * This is used to filter dragEnter, dragLeave, mouseOver, mouseOut events:
 * * For dragEnter and mouseOver the [relatedTarget] must be the element the
 *   mouse entered from. 
 * * For dragLeave and mouseOut the [relatedTarget] must be the element the 
 *   mouse entered to.
 */
bool _isMainEvent(Element mainElement, EventTarget relatedTarget) {
  return (relatedTarget == null 
      || (relatedTarget != mainElement && !mainElement.contains(relatedTarget)));
}

/**
 * Event for dropzone elements.
 */
class DropzoneEvent {
  Element draggable;
  Element dropzone;
  
  /// The mouse position relative to the whole document.
  Point mousePagePosition;
  
  /// The mouse position relative to the upper left edge of the browser window.
  Point mouseClientPosition;
  
  DropzoneEvent(this.draggable, this.dropzone, this.mousePagePosition, 
      this.mouseClientPosition);
}
