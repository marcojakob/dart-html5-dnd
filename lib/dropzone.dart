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
    
    bool dropAccept = false;
    
    // -------------------
    // Drag Enter
    // -------------------
    subs.add(element.onDragEnter.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null) return;
      
      // Necessary for IE?
      mouseEvent.preventDefault();
      
      // Test if this dropzone accepts the drop of the current draggable.
      dropAccept = accept == null || accept.isEmpty
          || accept.contains(currentDraggableGroup);
      if (dropAccept) {
        mouseEvent.dataTransfer.dropEffect = currentDraggableGroup.dropEffect;
      } else {
        mouseEvent.dataTransfer.dropEffect = 'none';
        return; // Return here as drop is not accepted.
      }
      
      _logger.finest('onDragEnter {dragOverElements.length before adding: ${currentDragOverElements.length}}');
      currentDragOverElements.add(mouseEvent.target);
      
      // Only handle dropzone element itself and not any of its children.
      if (currentDragOverElements.length == 1) {
        _logger.finest('firing onDragEnter');
        if (currentDraggableGroup.overClass != null) {
          css.addCssClass(element, currentDraggableGroup.overClass);
        }
        
        if (_onDragEnter != null) {
          _onDragEnter.add(new DropzoneEvent(currentDraggable, 
              element, mouseEvent));
        }
      }
    }));
    
    // Drag Over.
    subs.add(element.onDragOver.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null) return;
      
      if (dropAccept) {
        mouseEvent.dataTransfer.dropEffect = currentDraggableGroup.dropEffect;
      } else {
        mouseEvent.dataTransfer.dropEffect = 'none';
        return; // Return here as drop is not accepted.
      }

      // This is necessary to allow us to drop.
      mouseEvent.preventDefault();
      
      if (_onDragOver != null) {
        _onDragOver.add(new DropzoneEvent(currentDraggable, element, 
            mouseEvent));
      }
    }));
    
    // Drag Leave.
    subs.add(element.onDragLeave.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || !dropAccept) return;
      
      // Firefox fires too many onDragLeave events. This condition fixes it. 
      if (mouseEvent.target != mouseEvent.relatedTarget) {
        _logger.finest('onDragLeave {dragOverElements.length before removing: ${currentDragOverElements.length}}');
        currentDragOverElements.remove(mouseEvent.target);
      }
      
      // Only handle on dropzone element and not on any of its children.
      if (currentDragOverElements.isEmpty) {
        if (currentDraggableGroup.overClass != null) {
          css.removeCssClass(element, currentDraggableGroup.overClass);
        }
        
        if (_onDragLeave != null) {
          _onDragLeave.add(new DropzoneEvent(currentDraggable, element, 
              mouseEvent));
        }
      }
    }));
    
    // Drop.
    subs.add(element.onDrop.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || !dropAccept) return;
      _logger.finest('onDrop');
      
      // Stops browsers from redirecting.
      mouseEvent.preventDefault(); 
      
      if (currentDraggableGroup.overClass != null) {
        css.removeCssClass(element, currentDraggableGroup.overClass);
      }
      
      if (_onDrop != null) {
        _onDrop.add(new DropzoneEvent(currentDraggable, element, 
            mouseEvent));
      }
    }));
    
    installedElements[element].addAll(subs);
  }
}

/**
 * Event for dropzone elements.
 */
class DropzoneEvent {
  Element draggable;
  Element dropzone;
  MouseEvent mouseEvent;
  
  DropzoneEvent(this.draggable, this.dropzone, this.mouseEvent);
}
