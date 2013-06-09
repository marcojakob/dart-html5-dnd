part of html5_sortable;

/**
 * Manages a group of sortables and their options and event listeners.
 * 
 * A sortable element is at the same time a draggable and a dropzone element. 
 * Sortable elements can be dragged to either other sortables or to dropzones. 
 * A sortable can accept other draggable elements that are not sortables.
 */
class SortableGroup extends DraggableGroup {
  // -------------------
  // Sortable Options
  // -------------------
  /**
   * CSS class set on the placeholder element. Default is 'dnd-placeholder'. If 
   * null, no css class is added.
   */
  String placeholderClass = 'dnd-placeholder';
  
  /**
   * If true, forces the placeholder to have the computed size of the dragged
   * element. Default is true.
   * 
   * **Note:** Placeholders should have at least the size of the dragged 
   * element. If smaller, the mouse might already be outside of the placeholder 
   * when the drag is started. This leads to a bad user experience.
   */
  bool forcePlaceholderSize = true;
  
  /**
   * Must be set to true for sortable grids. This ensures that different sized
   * items in grids are handled correctly.
   */
  bool isGrid = false;
  
  // -------------------
  // Sortable Events
  // -------------------
  StreamController<SortableEvent> _onSortableComplete;
  
  /**
   * Returns the stream of completed sortable drag-and-drop events.
   * If the user aborted the drag, no event is fired.
   */
  Stream<SortableEvent> get onSortableComplete {
    if (_onSortableComplete == null) {
      _onSortableComplete = new StreamController<SortableEvent>.broadcast(sync: true, 
          onCancel: () => _onSortableComplete = null);
    }
    return _onSortableComplete.stream;
  }
  
  // -------------------
  // Dropzone Options (forwarded to _dropzoneGroup)
  // -------------------
  Set<DraggableGroup> get accept => _dropzoneGroup.accept;
  set accept(Set<DraggableGroup> accept) => _dropzoneGroup.accept = accept;
  
  // -------------------
  // Private Properties
  // -------------------
  final DropzoneGroup _dropzoneGroup;
  
  /// Subscription on dropzone dragEnter (one for the entire sortable group).
  StreamSubscription _dragEnterSub;
  /// Subscription on draggable dragStart (one for the entire sortable group).
  StreamSubscription _dragStartSub;
  
  /**
   * Constructor.
   * 
   * If [handle] is set to a value other than null, it is used as query String
   * to find a subelement of [element]. The drag is then restricted that 
   * subelement. 
   */
  SortableGroup({String handle}) :
    _dropzoneGroup = new DropzoneGroup(),
    super(handle: handle);
    
  
  /**
   * Installs sortable behaviour on [element] and registers it in this group.
   */
  void install(Element element) {
    super.install(element);
    
    // Sortable elements are at the same time draggables (superclass) and dropzones.
    _dropzoneGroup.install(element);
    
    // Only install listeners once per SortableGroup.
    if (installedElements.length == 1) {
      // Create placeholder on dragStart
      _dragStartSub = onDragStart.listen((DraggableEvent event) {
        _logger.finest('onDragStart');
        
        _currentPlaceholder = new _Placeholder(event.draggable, this, this);
      });
      
      // Show placeholder when an item of this group is entered.
      _dragEnterSub = _dropzoneGroup.onDragEnter.listen((DropzoneEvent event) {
        _logger.finest('onDragEnter');
        
        // Test if there already is a placeholder.
        if (_currentPlaceholder == null) {
          _currentPlaceholder = new _Placeholder(event.draggable, 
              currentDraggableGroup, this);
        }
        
        // Show a placeholder for the entered dropzone.
        _currentPlaceholder.showPlaceholder(event.dropzone, this);
      });
    }
  }
  
  /**
   * Uninstalls sortable behaviour on [element] and removes it from this group.
   * All [StreamSubscription]s that were added with install are canceled.
   */
  void uninstall(Element element) {
    super.uninstall(element);
      
    _dropzoneGroup.uninstall(element);
      
    if (installedElements.isEmpty) {
      // Last sortable of this group was uninstalled --> cancel subscriptions.
      _dragStartSub.cancel();
      _dragStartSub = null;
      _dragEnterSub.cancel();
      _dragEnterSub = null;
    }
  }
}

/**
 * Defines a position of an element in its [parent].
 */
class Position {
  Element parent;
  int index;
  
  Position(this.parent, this.index);
  
  /**
   * Inserts the specified [element] as a child of [parent] at [index].
   */
  void insert(Element element) {
    parent.children.insert(index, element);
  }

  @override
  int get hashCode {
    int result = 17;
    result = 37 * result + parent.hashCode;
    result = 37 * result + index.hashCode;
    return result;
  }

  @override
  bool operator ==(other) {
    if (identical(other, this)) return true;
    return (other is Position
        && other.parent == parent 
        && other.index == index);
  }
}

/**
 * Result used to carry information about a completed sortable drag-and-drop 
 * operation. The [draggable] was moved and has the [newPosition]. Also provides 
 * info about the [originalPosition].
 */
class SortableEvent {
  Element draggable;
  Position originalPosition;
  Position newPosition;
  
  SortableEvent(this.draggable, this.originalPosition, this.newPosition);
}

/**
 * Handles replacing of a dropzone with a placeholder.
 */
class _Placeholder {
  /// The draggable that this placeholder is for.
  final Element draggable;
  
  /// Current group of the placeholder.
  SortableGroup placeholderGroup;
  
  /// The group of the draggable element before dragging. Is different than 
  /// [placeholderGroup] if element has been dragged from a different group
  /// into this sortable.
  DraggableGroup originalGroup;
  
  /// Position of the draggable element before dragging.
  Position _originalPosition;
  
  /// Current Position of the placeholder.
  Position _placeholderPosition;
  
  /// The placeholder element.
  Element _placeholderElement;
  
  /// Flag to tell whether this dropzone was dropped.
  bool _dropped = false;
  
  StreamSubscription _dropzoneOverSub; 
  StreamSubscription _dropzoneDropSub; 
  StreamSubscription _placeholderDropSub;
  StreamSubscription _placeholderOverSub;
  StreamSubscription _draggableEndSub;
  
  /**
   * Creates a new placeholder for the specified [draggable].
   */
  _Placeholder(this.draggable, this.originalGroup, this.placeholderGroup) {
    // Save original position of draggable for later.
    _originalPosition = new Position(draggable.parent,
        html5.getElementIndexInParent(draggable));
    
    _createPlaceholderElement();
  }
  
  void _createPlaceholderElement() {
    _logger.finest('creating new placeholder');
    _placeholderElement = new Element.tag(draggable.tagName);
    if (placeholderGroup.placeholderClass != null) {
      _placeholderElement.classes.add(placeholderGroup.placeholderClass);
    }
    
    if (placeholderGroup.forcePlaceholderSize) {
      // Placeholder receives the computed size from the dragged element.
      _placeholderElement.style.height = draggable.getComputedStyle().height; 
      _placeholderElement.style.width = draggable.getComputedStyle().width;
    }
    
    // Listen for drops inside placeholder.
    _placeholderDropSub = _placeholderElement.onDrop.listen((_) {
      _logger.finest('placeholder onDrop');
      _dropped = true;
    });
    
    // Allow us to drop by preventing default.
    _placeholderOverSub = _placeholderElement.onDragOver.listen((MouseEvent mouseEvent) {
      mouseEvent.dataTransfer.dropEffect = placeholderGroup.dropEffect;
      // This is necessary to allow us to drop.
      mouseEvent.preventDefault();
      
      // When mouse is over the placeholder, we clear the drag over elements so 
      // we have a fresh start of the counter whenever any other element is entered.
      currentDragOverElements.clear();
    });
    
    // Hide placeholder on dragEnd of draggable.
    _draggableEndSub = draggable.onDragEnd.listen((MouseEvent event) {
      _logger.finest('placeholder onDragEnd');
      if (_dropped) {
        _logger.finest('placeholder was dropped -> Show draggable at new position');
        
        if (placeholderGroup != originalGroup) {
          // Draggable was dragged from a different group into this sortable.
          // Uninstall from original group and install in new group.
          originalGroup.uninstall(draggable);
          placeholderGroup.install(draggable);
        }
        
        // Hide placeholder and show draggable again at new position.
        _currentPlaceholder.hidePlaceholder();
      } else {
        // Not dropped. This means the drag ended outside of a placeholder or
        // the drag was cancelled somehow (ESC-key, ...)
        // Revert to state before dragging.
        _logger.finest('placeholder not dropped -> Revert to state before dragging');
        _currentPlaceholder.hidePlaceholder(revertToOriginal: true);
      }
      
      // Reset current placeholder.
      _currentPlaceholder = null;
      
      // Cancel all subscriptions.
      if (_dropzoneOverSub != null) {
        _dropzoneOverSub.cancel();
      }
      if (_dropzoneDropSub != null) {
        _dropzoneDropSub.cancel();
      }
      _placeholderDropSub.cancel();
      _placeholderOverSub.cancel();
      _draggableEndSub.cancel();
    });
  }
  
  /**
   * Shows the placeholder at the position of [dropzone].
   * 
   * Ensures that there is no flickering (going back and forth between two 
   * states) if the dropzone is bigger than the placeholder. This means that 
   * this method will only show the placeholder for a bigger dropzone if the 
   * mouse is in a safe region of the dropzone.
   */
  void showPlaceholder(Element dropzone, SortableGroup group) {
    _logger.finest('showPlaceholder');
    group = group;
    
    if (_isDropzoneHigher(dropzone) 
        || (group.isGrid && _isDropzoneWider(dropzone))) {
      _logger.finest('dropzone is bigger than placeholder, listening to onDragOver events');
      
      // There is already an dragOver subscription on a dropzone --> cancel.
      if (_dropzoneOverSub != null) {
        _dropzoneOverSub.cancel();
      }
      
      // On elements that are bigger than the dropzone we must listen to 
      // dragOver events and determine from the mouse position, whether to 
      // change placeholder position.
      _dropzoneOverSub = dropzone.onDragOver.listen((MouseEvent event) {
        _logger.finest('placeholder (dropzone) onDragOver');
        
        _showPlaceholderForBiggerDropzone(dropzone, event);
      });
      
      if (_dropzoneDropSub != null) {
        _dropzoneDropSub.cancel();
      }
      _dropzoneDropSub = dropzone.onDrop.listen((MouseEvent event) {
        _logger.finest('placeholder (dropzone) onDrop');
        _dropped = true;
      });
      
    } else {
      _logger.finest('dropzone is not bigger than placeholder, not listening to onDragOver events');
      
      Position dropzonePosition = new Position(dropzone.parent,
          html5.getElementIndexInParent(dropzone));
      _doShowPlaceholder(dropzone, dropzonePosition);
    }
  }
  
  /**
   * Hides the placeholder and shows the draggable.
   * If [revertToOriginal] is true, the draggable is shown at the 
   * [_originalPosition]. If false, it is shown at the current [_placeholderPosition].
   */
  void hidePlaceholder({bool revertToOriginal: false}) {
    _placeholderElement.remove();
    
    if (revertToOriginal) {
      _originalPosition.insert(draggable);      
    } else {
      _placeholderPosition.insert(draggable);
      
      // Fire sortable complete event
      if (_placeholderPosition != _originalPosition) {
        _logger.finest('firing onSortableComplete event');
        
        if (placeholderGroup._onSortableComplete != null) {
          placeholderGroup._onSortableComplete.add(new SortableEvent(draggable, 
              _originalPosition, _placeholderPosition));
        }
      }
    }
  }
  
  /**
   * Returns true if the [dropzone]'s height is greater than this placeholder's.
   * If the placeholder hasn't been added and thus has a size of 0, false is
   * returned.
   */
  bool _isDropzoneHigher(Element dropzone) {
    return _placeholderElement.clientHeight > 0 
        && dropzone.clientHeight > _placeholderElement.clientHeight;
  }
  
  /**
   * Returns true if the [dropzone]'s width is greater than this placeholder's.
   * If the placeholder hasn't been added and thus has a size of 0, false is
   * returned.
   */
  bool _isDropzoneWider(Element dropzone) {
    return _placeholderElement.clientWidth > 0 
        && dropzone.clientWidth > _placeholderElement.clientWidth;
  }
  
  /**
   * Shows the placeholder at the position of [dropzone] ONLY if mouse is not
   * in the disabled region of the bigger [dropzone].
   */
  void _showPlaceholderForBiggerDropzone(Element dropzone, 
                                        MouseEvent event) {
    Position dropzonePosition = new Position(dropzone.parent,
        html5.getElementIndexInParent(dropzone));
    
    if (_isDropzoneHigher(dropzone)) {
      if (_isInDisabledVerticalRegion(dropzone, dropzonePosition, event)) {
        return;
      }
    }
    
    if (placeholderGroup.isGrid) {
      if (_isDropzoneWider(dropzone)) {
        if (_isInDisabledHorizontalRegion(dropzone, dropzonePosition, event)) {
          return; 
        }
      }
    }
    _logger.finest('showing placeholder for bigger dropzone');
    _doShowPlaceholder(dropzone, dropzonePosition);
  }
  
  void _doShowPlaceholder(Element dropzone, Position dropzonePosition) {
    // Show placeholder at the position of dropzone.
    _placeholderPosition = dropzonePosition;
    _logger.finest('showing placeholder at index ${_placeholderPosition.index}');
    _placeholderElement.remove(); // Might already be at a different position.
    _placeholderPosition.insert(_placeholderElement);
    
    // Make sure the draggable element is removed.
    currentDraggable.remove();
  }
  
  /**
   * Returns true if the mouse is in the disabled vertical region of the 
   * dropzone.
   */
  bool _isInDisabledVerticalRegion(Element dropzone, Position dropzonePosition, 
                                   MouseEvent event) {
    if (_placeholderPosition != null 
        && _placeholderPosition.parent == dropzonePosition.parent
        && _placeholderPosition.index > dropzonePosition.index) {
      // Current placeholder position is after the new dropzone position.
      // --> Disabled region is in the bottom part of the dropzone.
      
      // Calc the mouse position relative to the dropzone.
      num mouseRelativeTop = event.page.y - css.getTopOffset(dropzone);  
      if (mouseRelativeTop > _placeholderElement.clientHeight) {
        return true; // In disabled region.
      }
    }
    return false;
  }
  
  /**
   * Returns true if the mouse is in the disabled horizontal region of the 
   * dropzone. This check is only necessary for grids.
   */
  bool _isInDisabledHorizontalRegion(Element dropzone, Position dropzonePosition, 
                                     MouseEvent event) {
    // Calc the mouse position relative to the dropzone.
    num mouseRelativeLeft = event.page.x - css.getLeftOffset(dropzone);      
    
    if (_placeholderPosition != null 
        && _placeholderPosition.parent == dropzonePosition.parent) {
      
      if (_placeholderPosition.index > dropzonePosition.index) {
        // Current placeholder position is after the new dropzone position (with 
        // same parent) --> Disabled region is in the right part of the dropzone.
        if (mouseRelativeLeft > _placeholderElement.clientWidth) {
          return true; // In disabled region.
        }
      }
      if (_placeholderPosition.index < dropzonePosition.index) {
        // Current placeholder position is after the new dropzone position.
        // --> Disabled region is in the left part of the dropzone.
        if (mouseRelativeLeft < _placeholderElement.clientWidth) {
          return true; // In disabled region.
        }
      }
    }
    return false;
  }
}