/**
 * Helper library for reordering of HTML elements with native HTML5 Drag and
 * Drop.
 */
library html5_dnd.sortable;

import 'dart:html';
import 'dart:async';
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';

import '../../html5_dnd.dart';
import '../utils.dart' as utils;

final _logger = new Logger("html5_dnd.sortable");

/// The currently shown placeholder. 
_Placeholder _currentPlaceholder;

/// Flag indicating that draggable was dropped on a valid sortable target.
bool _dropped = false;

/**
 * Manages a group of sortables and their options and event listeners.
 * 
 * A sortable element is at the same time a draggable and a dropzone element. 
 * Sortable elements can be dragged to either other sortables or to dropzones. 
 * A sortable can accept other draggable elements that are not sortables.
 */
class SortableGroup extends DraggableGroup implements DropzoneGroup {
  // -------------------
  // Sortable Options
  // -------------------
  /**
   * CSS class set on the placeholder element. Default is 'dnd-placeholder'. If 
   * null, no css class is added.
   */
  String placeholderClass = 'dnd-placeholder';
  
  /**
   * If true, forces placeholders to have the computed size of the dragged
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
  StreamController<SortableEvent> _onSortUpdate;
  
  /**
   * Returns the stream of sort update events. This event is triggered when the 
   * user stopped sorting and the DOM position has changed. If the user aborts 
   * the drag or drops the element at the same position, no event is fired.
   */
  Stream<SortableEvent> get onSortUpdate {
    if (_onSortUpdate == null) {
      _onSortUpdate = new StreamController<SortableEvent>.broadcast(sync: true, 
          onCancel: () => _onSortUpdate = null);
    }
    return _onSortUpdate.stream;
  }
  
  // -------------------
  // Dropzone Options (forwarded to _dropzoneGroup)
  // -------------------
  Set<DraggableGroup> get accept => _dropzoneGroup.accept;
  set accept(Set<DraggableGroup> accept) => _dropzoneGroup.accept = accept;
  
  // -------------------
  // Dropzone Events (forwarded to _dropzoneGroup)
  // -------------------
  Stream<DropzoneEvent> get onDragEnter => _dropzoneGroup.onDragEnter;
  Stream<DropzoneEvent> get onDragOver => _dropzoneGroup.onDragOver;
  Stream<DropzoneEvent> get onDragLeave => _dropzoneGroup.onDragLeave;
  Stream<DropzoneEvent> get onDrop => _dropzoneGroup.onDrop;
  
  // -------------------
  // Private Properties
  // -------------------
  final DropzoneGroup _dropzoneGroup;
  
  /// Subscriptions that need to be canceled on drag end.
  List<StreamSubscription> _sortableSubs = new List<StreamSubscription>();
  
  /// Subscription if an element of this group is entered. Only canceld when the
  /// last element of this group is removed.
  StreamSubscription _dragEnterSub;
  
  /**
   * Constructor.
   * 
   * [dragImageFunction] is a function to create a [DragImage] for this 
   * draggable. If it is null (the default), the drag image is created from 
   * the draggable element. 
   * 
   * If [handle] is set to a value other than null, it is used as query String
   * to find a subelement of elements in this group. The drag is then 
   * restricted to that subelement.
   * 
   * If [cancel] is set to a value other than null, starting a drag is prevented 
   * on specified elements. It is a used as query String to find a subelement of 
   * elements in this group. Default is 'input,textarea,button,select,option'.
   */
  SortableGroup({DragImageFunction dragImageFunction: null, String handle: null, 
      String cancel: 'input,textarea,button,select,option'}) :
    _dropzoneGroup = new DropzoneGroup(),
    super(dragImageFunction: dragImageFunction, handle: handle, cancel: cancel) {
    
    // Disable overClass by default for sortable as we're usually only over the 
    // placeholder and not over a dropzone. Same for draggingClass as the 
    // dragged element is replaced by the placeholder and thus not visible.
    draggingClass = null;
    overClass = null; 
  }
      
  /**
   * Installs sortable behaviour on [element] and registers it in this group.
   */
  @override
  void install(Element element) {
    _logger.finest('installing as sortable');
    // Sortable elements are at the same time draggables (superclass) and dropzones.
    
    // Install draggable behaviour.
    super.install(element);
    
    // Install dropzone behaviour.
    _dropzoneGroup.install(element);
    
    // Only install listeners once per SortableGroup.
    if (installedElements.length == 1) {
      _logger.finest('first element in this sortable group installed, add listeners');
      
      _listenToDragEnter();
    }
  }
  
  void _listenToDragEnter() {
    _dragEnterSub = onDragEnter.listen((DropzoneEvent event) {
      _logger.finest('dragEnter');
        
      // Test if there already is a placeholder.
      if (_currentPlaceholder == null) {
        _currentPlaceholder = new _Placeholder(currentDraggable, 
            currentDraggableGroup);
      }
      
      // The first time this group is enterered during a drag, drop and 
      // dragEnd listeners are installed.
      if (_sortableSubs.isEmpty) {
        _listenToDrop();
        _listenToDragEnd(currentDraggableGroup);
      }
        
      // Show the placeholder for the entered dropzone.
      _currentPlaceholder.showPlaceholder(event.dropzone, this);
    });
  }
  
  void _listenToDrop() {
    _sortableSubs.add(onDrop.listen((DropzoneEvent event) {
      _logger.finest('drop');
      if (_currentPlaceholder != null) {
        // Just set dropped to true and let dragEnd handle it.
        _dropped = true;
      }
    }));
  }
  
  void _listenToDragEnd(DraggableGroup group) {
    // Clean up on dragEnd.
    _sortableSubs.add(group.onDragEnd.listen((_) {
      _logger.finest('dragEnd');
      
      // Cancel subscriptions.
      _sortableSubs.forEach((StreamSubscription s) => s.cancel());
      _sortableSubs.clear();
      
      // Hide placeholder if one is currently shown.
      if (_currentPlaceholder != null) {
        _currentPlaceholder.hidePlaceholder(dropped: _dropped);
      }
      
      // Reset dropped.
      _dropped = false;
    }));
  }
  
  /**
   * Uninstalls sortable behaviour on [element] and removes it from this group.
   * All [StreamSubscription]s that were added with install are canceled.
   */
  void uninstall(Element element) {
    _logger.finest('uninstalling sortable');
    super.uninstall(element);
      
    _dropzoneGroup.uninstall(element);
      
    if (installedElements.isEmpty) {
      _logger.finest('last element in this sortable group uninstalled, cancel group subscriptions');
      // Last sortable of this group was uninstalled --> cancel subscriptions.
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
 * Result used to carry information about a completed sortable Drag and Drop
 * operation. The [draggable] was moved from [originalPosition] to [newPosition].
 *  
 * If the [draggable] was dragged into another group, [newGroup] is different
 * from [originalGroup]. In that case you might want to uninstall from [originalGroup]
 * and install again in [newGroup].
 */
class SortableEvent {
  Element draggable;
  Position originalPosition;
  Position newPosition;
  Group originalGroup;
  Group newGroup;
  
  SortableEvent(this.draggable, this.originalPosition, this.newPosition,
                this.originalGroup, this.newGroup);
}

/**
 * Handles replacing of a dropzone with a placeholder.
 */
class _Placeholder {
  /// The draggable that this placeholder is for.
  final Element _draggable;
  
  final String _draggableWidth;
  final String _draggableHeight;
  
  /// Position of the draggable element before dragging.
  final Position _originalPosition;
  
  /// The group of the draggable element before dragging. 
  /// Might be a [DraggableGroup] or a [SortableGroup].
  final DraggableGroup _originalGroup;
  
  /// Current Position of the placeholder.
  Position _currentPosition;
  
  /// Current group of the placeholder.
  SortableGroup _currentGroup;
  
  /// The placeholder element.
  Element placeholderElement;
    
  /// DragOver subscription used when dropzone is bigger than placeholder.
  StreamSubscription _dropzoneOverSub;
  
  /// A [DropzoneGroup] just for the placeholder to receive events from draggable.
  DropzoneGroup _placeholderDropzoneGroup;
  
  /**
   * Creates a new placeholder for the specified [draggable].
   */
  _Placeholder(Element draggable, DraggableGroup originalGroup) :
    _draggable = draggable,
    // Save draggable width and height because they are not available when 
    // draggable is removed from the DOM.
    _draggableWidth = draggable.getComputedStyle().width,
    _draggableHeight = draggable.getComputedStyle().height,
    _originalGroup = originalGroup,
    _originalPosition = new Position(draggable.parent,
        utils.getElementIndexInParent(draggable)){
    
    _createPlaceholderElement();
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
    
    if (_currentGroup == null || _currentGroup != group) {
      _currentGroup = group;
      _applyGroupProperties(group);
    }
    
    // If there is already a dragOver subscription on a dropzone --> cancel.
    if (_dropzoneOverSub != null) {
      _dropzoneOverSub.cancel();
      _dropzoneOverSub = null;
    }
    
    if (_isDropzoneHigher(dropzone) 
        || (_currentGroup.isGrid && _isDropzoneWider(dropzone))) {
      _logger.finest('dropzone is bigger than placeholder, listening to dragOver events');
      
      // On elements that are bigger than the dropzone we must listen to 
      // dragOver events and determine from the mouse position, whether to 
      // change placeholder position.
      _dropzoneOverSub = _currentGroup.onDragOver.listen((DropzoneEvent event) {
        _logger.finest('placeholder (dropzone) dragOver');
        
        _showPlaceholderForBiggerDropzone(dropzone, event.mousePagePosition);
      });
      
    } else {
      _logger.finest('dropzone is not bigger than placeholder');
      
      Position dropzonePosition = new Position(dropzone.parent,
          utils.getElementIndexInParent(dropzone));
      _doShowPlaceholder(dropzone, dropzonePosition);
    }
  }
  
  /**
   * Hides the placeholder and shows the draggable.
   * If [dropped] is true, the draggable is shown at the [_currentPosition]. 
   * If false, it is shown at the [_originalPosition].
   */
  void hidePlaceholder({bool dropped: false}) {
    // Remove placeholder element from DOM.
    placeholderElement.remove();
    placeholderElement = null;
    
    // Reset current placeholder so that no one else can call it.
    _currentPlaceholder = null;
    
    if (dropped) {
      _logger.finest('placeholder was dropped -> Show draggable at new position');
      _currentPosition.insert(_draggable);
      
      // Fire sort update event if the position has changed.
      if (_currentPosition != _originalPosition) {
        _logger.finest('firing onSortableComplete event');
        
        if (_currentGroup._onSortUpdate != null) {
          _currentGroup._onSortUpdate.add(new SortableEvent(_draggable, 
              _originalPosition, _currentPosition, _originalGroup, _currentGroup));
        }
      }
      
    } else {
      // Not dropped. This means the drag ended outside of a placeholder or
      // the drag was cancelled somehow (ESC-key, ...)
      // Revert to state before dragging.
      _logger.finest('placeholder not dropped -> Revert to state before dragging');
      _originalPosition.insert(_draggable);      
    }
    
    // Cancel all subscriptions.
    if (_dropzoneOverSub != null) {
      _dropzoneOverSub.cancel();
    }
  }
  
  /**
   * Creates the [placeholderElement].
   */
  void _createPlaceholderElement() {
    _logger.finest('creating new placeholder element');
    placeholderElement = new Element.tag(_draggable.tagName);
    
    // Create a new DropzoneGroup just for the placeholder element.
    _placeholderDropzoneGroup = new DropzoneGroup()
    ..install(placeholderElement)
    ..onDrop.listen((DropzoneEvent event) {
      _logger.finest('drop on placeholder');
      
      // Just set dropped to true and let dragEnd of sortable group handle the rest.
      _dropped = true;
    });
  }
  
  /**
   * Applies the [group]'s placeholder styling properties to the 
   * [placeholderElement].
   */
  void _applyGroupProperties(SortableGroup group) {
    if (_currentGroup.placeholderClass != null) {
      // The placeholder receives the placeholderClass CSS from its current group.
      placeholderElement.classes.add(_currentGroup.placeholderClass);
    } else {
      placeholderElement.classes.clear();
    }
    
    if (_currentGroup.forcePlaceholderSize) {
      // Placeholder receives the computed size from the dragged element.
      placeholderElement.style.width = _draggableWidth;
      placeholderElement.style.height = _draggableHeight;
    } else {
      placeholderElement.style.removeProperty('width');
      placeholderElement.style.removeProperty('height');
    }
  }
  
  /**
   * Shows the placeholder at the position of [dropzone] ONLY if mouse is not
   * in the disabled region of the bigger [dropzone].
   */
  void _showPlaceholderForBiggerDropzone(Element dropzone, 
                                         Point mousePagePosition) {
    Position dropzonePosition = new Position(dropzone.parent,
        utils.getElementIndexInParent(dropzone));
    
    if (_isDropzoneHigher(dropzone)) {
      if (_isInDisabledVerticalRegion(dropzone, dropzonePosition,
          mousePagePosition)) {
        return;
      }
    }
    
    if (_currentGroup.isGrid) {
      if (_isDropzoneWider(dropzone)) {
        if (_isInDisabledHorizontalRegion(dropzone, dropzonePosition, mousePagePosition)) {
          return; 
        }
      }
    }
    _logger.finest('showing placeholder for bigger dropzone');
    _doShowPlaceholder(dropzone, dropzonePosition);
  }
  
  /**
   * Actually shows the placeholder (with no further checks).
   */
  void _doShowPlaceholder(Element dropzone, Position dropzonePosition) {
    // Show placeholder at the position of dropzone.
    _currentPosition = dropzonePosition;
    _logger.finest('showing placeholder at index ${_currentPosition.index}');
    
    // Placeholder might already be showing at a different position --> remove it.
    placeholderElement.remove(); 
    
    // Insert in new position.
    _currentPosition.insert(placeholderElement);
    
    // Make sure the draggable element is not showing.
    _draggable.remove();
  }
  
  /**
   * Returns true if the [dropzone]'s height is greater than this placeholder's.
   * If the placeholder hasn't been added and thus has a size of 0, false is
   * returned.
   */
  bool _isDropzoneHigher(Element dropzone) {
    return placeholderElement.clientHeight > 0 
        && dropzone.clientHeight > placeholderElement.clientHeight;
  }
  
  /**
   * Returns true if the [dropzone]'s width is greater than this placeholder's.
   * If the placeholder hasn't been added and thus has a size of 0, false is
   * returned.
   */
  bool _isDropzoneWider(Element dropzone) {
    return placeholderElement.clientWidth > 0 
        && dropzone.clientWidth > placeholderElement.clientWidth;
  }
  
  /**
   * Returns true if the mouse is in the disabled vertical region of the 
   * dropzone.
   */
  bool _isInDisabledVerticalRegion(Element dropzone, Position dropzonePosition, 
                                   Point mousePagePosition) {
    if (_currentPosition != null 
        && _currentPosition.parent == dropzonePosition.parent
        && _currentPosition.index > dropzonePosition.index) {
      // Current placeholder position is after the new dropzone position.
      // --> Disabled region is in the bottom part of the dropzone.
      
      // Calc the mouse position relative to the dropzone.
      num mouseRelativeTop = mousePagePosition.y - utils.pageOffset(dropzone).y;
      if (mouseRelativeTop > placeholderElement.clientHeight) {
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
                                     Point mousePagePosition) {
    // Calc the mouse position relative to the dropzone.
    num mouseRelativeLeft = mousePagePosition.x - utils.pageOffset(dropzone).x;      
    
    if (_currentPosition != null 
        && _currentPosition.parent == dropzonePosition.parent) {
      
      if (_currentPosition.index > dropzonePosition.index) {
        // Current placeholder position is after the new dropzone position (with 
        // same parent) --> Disabled region is in the right part of the dropzone.
        if (mouseRelativeLeft > placeholderElement.clientWidth) {
          return true; // In disabled region.
        }
      }
      if (_currentPosition.index < dropzonePosition.index) {
        // Current placeholder position is after the new dropzone position.
        // --> Disabled region is in the left part of the dropzone.
        if (mouseRelativeLeft < placeholderElement.clientWidth) {
          return true; // In disabled region.
        }
      }
    }
    return false;
  }
}