part of html5_dnd;

/// Currently dragged element.
Element currentDraggable;

/// The [DraggableGroup] the [currentDraggable] belongs to.
DraggableGroup currentDraggableGroup;

const DROP_EFFECT_NONE = 'none';
const DROP_EFFECT_COPY = 'copy';
const DROP_EFFECT_LINK = 'link';
const DROP_EFFECT_MOVE = 'move';

/**
 * Manages a group of draggables and their options and event listeners.
 */
class DraggableGroup extends Group {
  // -------------------
  // Draggable Options
  // -------------------
  /**
   * CSS class set to the html body tag during a drag. Default is 
   * 'dnd-drag-occurring'. If null, no CSS class is added.
   */
  String dragOccurringClass = 'dnd-drag-occurring';
  
  /**
   * CSS class set to the draggable element during a drag. Default is 
   * 'dnd-dragging'. If null, no css class is added.
   */
  String draggingClass = 'dnd-dragging';
  
  /**
   * CSS class set to the dropzone element when a draggable is dragged over 
   * it. Default is 'dnd-over'. If null, no css class is added.
   */
  String overClass = 'dnd-over';
  
  /**
   * Controls the feedback that the user is given during the dragenter and 
   * dragover events. When the user hovers over a target element, the browser's
   * cursor will indicate what type of operation is going to take place (e.g. a 
   * copy, a move, etc.). The effect can take on one of the following values: 
   * none, copy, link, move. Default is 'move'.
   */
  String dropEffect = DROP_EFFECT_MOVE;
  
  /**
   * [dragImageFunction] is a function to create a [DragImage] for this 
   * draggable. If it is null (the default), the drag image is created from 
   * the draggable element. 
   */
  final DragImageFunction dragImageFunction;
  
  /**
   * If [handle] is set to a value other than null, the drag is restricted to 
   * that element. It is used as query String to find a subelement of elements 
   * in this group. 
   */
  final String handle;
  
  /**
   * If [cancel] is set to a value other than null, starting a drag is prevented 
   * on specified elements. It is a used as query String to find a subelement of 
   * elements in this group. Default is 'input,textarea,button,select,option'.
   */
  final String cancel;
  
  // -------------------
  // Draggable Events
  // -------------------
  StreamController<DraggableEvent> _onDragStart;
  StreamController<DraggableEvent> _onDrag;
  StreamController<DraggableEvent> _onDragEnd;
  
  /**
   * Fired when the user starts dragging a draggable of this group.
   */
  Stream<DraggableEvent> get onDragStart {
    if (_onDragStart == null) {
      _onDragStart = new StreamController<DraggableEvent>.broadcast(sync: true, 
          onCancel: () => _onDragStart = null);
    }
    return _onDragStart.stream;
  }
  
  /**
   * Fired periodically throughout the drag operation. If drag and drop is
   * emulated, drag events are only fired when the mouse is moved.
   */
  Stream<DraggableEvent> get onDrag {
    if (_onDrag == null) {
      _onDrag = new StreamController<DraggableEvent>.broadcast(sync: true, 
          onCancel: () => _onDrag = null);
    }
    return _onDrag.stream;
  }
  
  /**
   * Fired when the user releases the mouse button while dragging a draggable. 
   * Is also fired when the user clicks the 'esc'-key or the window loses focus. 
   * For those two cases, the mouse positions of [DraggableEvent] will be null.
   * 
   * Note: dragEnd is fired after drop in case there was a drop.
   */
  Stream<DraggableEvent> get onDragEnd {
    if (_onDragEnd == null) {
      _onDragEnd = new StreamController<DraggableEvent>.broadcast(sync: true, 
          onCancel: () => _onDragEnd = null);
    }
    return _onDragEnd.stream;
  }
  
  bool _emulateDraggable = false;
  
  /**
   * Constructor to create a [DraggableGroup].
   * 
   * [dragImageFunction] is a function to create a [DragImage] for this 
   * draggable. If it is null (the default), the drag image is created from 
   * the draggable element. 
   * 
   * If [handle] is set to a value other than null, the drag is restricted to 
   * that element. It is used as query String to find a subelement of elements 
   * in this group. 
   * 
   * If [cancel] is set to a value other than null, starting a drag is prevented 
   * on specified elements. It is a used as query String to find a subelement of 
   * elements in this group. Default is 'input,textarea,button,select,option'.
   */
   DraggableGroup({this.dragImageFunction, this.handle, 
      this.cancel: 'input,textarea,button,select,option'}) {
    // Must emulate if either browser does not support HTML5 draggable 
    // (IE9) or there is a custom drag image and browser does not support
    // setDragImage (IE10).
    if(!html5.supportsDraggable 
        || (dragImageFunction != null && !html5.supportsSetDragImage)) {
      _logger.finest('Browser does not (completely) support HTML5 draggable.');
      _emulateDraggable = true;
    } else {
      _logger.finest('Browser does support HTML5 draggable.');
      _emulateDraggable = false;
    }
  }
  
  /**
   * Installs draggable behaviour on [element] and registers it in this group.
   */
  void install(Element element) {
    super.install(element);
    
    List<StreamSubscription> subs = new List<StreamSubscription>();
    
    if (_emulateDraggable || element is svg.SvgElement) {
      _logger.finest('installing as emulated draggable');
      subs.addAll(_installEmulatedDraggable(element, this));
    } else {
      _logger.finest('installing as draggable');
      subs.addAll(_installDraggable(element, this));
    }
    
    // Install touch events if enabled and supported.
    if (_useTouchEvents()) {
      _logger.finest('installing touch support');
      subs.addAll(_installTouchEvents(element, this));
    }
    
    installedElements[element].addAll(subs);
  }
  
  /**
   * Common method to handle dragStart events. 
   * 
   * Adds the CSS classes and fires dragStart event.
   */
  void _handleDragStart(Element element, Point mousePagePosition, Point mouseClientPosition) {
    _logger.finest('handleDragStart');
    
    currentDraggable = element;
    currentDraggableGroup = this;
    
    // Add CSS classes
    if (draggingClass != null) {
      // Defer adding the dragging class until the end of the event loop.
      // This makes sure that the style is not applied to the drag image.
      Timer.run(() {
        // Test if we're actually still dragging.
        if (currentDraggable != null) {
          element.classes.add(draggingClass);
        }
      });
    }
    if (dragOccurringClass != null) {
      document.body.classes.add(dragOccurringClass);
    }
    
    if (_onDragStart != null) {
      _onDragStart.add(new DraggableEvent(element, mousePagePosition, mouseClientPosition));
    }
  }
  
  /**
   * Common method to handle drag events.
   * 
   * Fires drag event.
   */
  void _handleDrag(Element element, Point mousePagePosition, Point mouseClientPosition) {
    if (_onDrag != null) {
      _onDrag.add(new DraggableEvent(element, mousePagePosition, mouseClientPosition));
    }
  }
  
  /**
   * Common method to handle dragEnd events.
   * 
   * Removes CSS classes and fires dragEnd event.
   */
  void _handleDragEnd(Element element, Point mousePagePosition, 
                      Point mouseClientPosition) {
    _logger.finest('handleDragEnd');
    
    // Remove CSS classes.
    if (draggingClass != null) {
      element.classes.remove(draggingClass);
    }
    if (dragOccurringClass != null) {
      document.body.classes.remove(dragOccurringClass);
    }
    
    if (_onDragEnd != null) {
      _onDragEnd.add(new DraggableEvent(element, mousePagePosition, 
          mouseClientPosition));
    }
    
    // Reset variables.
    currentDraggable = null;
    currentDraggableGroup = null;
  }
}


List<StreamSubscription> _installDraggable(Element element, DraggableGroup group) {
  List<StreamSubscription> subs = new List<StreamSubscription>();
  
  // Test if user starts drag on a valid element.
  bool validDragStartTarget = false;
  subs.add(element.onMouseDown.listen((MouseEvent mouseEvent) {
    _logger.finest('mouseDown');
    validDragStartTarget = _isValidDragStartTarget(element, mouseEvent.target, group.handle, group.cancel);
    
    if (validDragStartTarget) {
      // Enable native dragging.
      element.attributes['draggable'] = 'true';
      
      // Remove all text selections. Selections can otherwise lead to strange
      // behaviour when present on dragStart.
      html5.clearTextSelections();
      
      // Remove draggable attribute on mouse up (anywhere on document).
      StreamSubscription upSub;
      upSub = document.onMouseUp.listen((MouseEvent upEvent) {
        element.attributes.remove('draggable');
        upSub.cancel();
      });
    } else {
      // Disable native dragging.
      element.attributes.remove('draggable');
    }
  }));
  
  // -------------------
  // DragStart
  // -------------------
  subs.add(element.onDragStart.listen((MouseEvent mouseEvent) {
    // Only handle dragStart if a valid drag start target was clicked before.
    if (!validDragStartTarget) return;
    _logger.finest('dragStart');
    
    // In Firefox it is possible to start selection outside of a draggable,
    // then drag entire selection. This leads to strange behavior, so we 
    // deactivate selection here.
    if (window.getSelection().rangeCount > 0) {
      window.getSelection().removeAllRanges();
    }

    // The allowed 'type of drag'. 
    // Unfortunately, in Firefox and IE, multiple allowed effects (like 'all'
    // or 'copyMove') do not work. They will not show the correct cursor when
    // the actual dataTransfer.dropEffect is set in onDragOver. Thus, only 
    // the values 'move', 'copy', 'link', and 'none' should be used.
    mouseEvent.dataTransfer.effectAllowed = group.dropEffect;
    
    // Set some dummy data (Firefox needs this).
    mouseEvent.dataTransfer.setData('Text', '');
    
    if (group.dragImageFunction != null) {
      DragImage dragImage = group.dragImageFunction(element);
      mouseEvent.dataTransfer.setDragImage(dragImage.element, dragImage.x, 
          dragImage.y);
    }
    
    group._handleDragStart(element, mouseEvent.page, mouseEvent.client);
  }));
  
  // -------------------
  // Drag
  // -------------------
  subs.add(element.onDrag.listen((MouseEvent mouseEvent) {
    // Do nothing if no element of this dnd is dragged.
    if (currentDraggable == null) return;
    
    group._handleDrag(element, mouseEvent.page, mouseEvent.client);
  }));
  
  // -------------------
  // DragEnd
  // -------------------
  subs.add(element.onDragEnd.listen((MouseEvent mouseEvent) {
    // Do nothing if no element of this dnd is dragged.
    if (currentDraggable == null) return;
    
    _logger.finest('dragEnd');

    group._handleDragEnd(element, mouseEvent.page, mouseEvent.client);
    
    // Reset variables.
    validDragStartTarget = false;
    _lastDragEnterTarget = null;
    
    // Remove the (possibly) added draggable attribute.
    element.attributes.remove('draggable');
  }));
  
  return subs;
}

/**
 * Tests if [target] is a valid place to start a drag. If [handle] is
 * provided, drag can only start on one or many handles. If [cancel] is 
 * provided, drag cannot be started on those elements.
 * 
 * [handle] and [cancel] are both query strings used to get query for a 
 * subelement of [element]. 
 */
bool _isValidDragStartTarget(Element element, EventTarget target, 
                             String handle, String cancel) {
  if (handle != null) {
    List<Element> handles = element.queryAll(handle);
    if (!handles.contains(target)) {
      return false;
    }
  }
  
  if (cancel != null) {
    List<Element> cancels = element.queryAll(cancel);
    if (cancels.contains(target)) {
      return false;
    }
  }
  
  return true;
}

typedef DragImage DragImageFunction(Element draggable);

/**
 * Event for draggable elements.
 */
class DraggableEvent {
  Element draggable;
  
  /// The mouse position relative to the whole document.
  Point mousePagePosition;
  
  /// The mouse position relative to the upper left edge of the browser window.
  Point mouseClientPosition;
  
  DraggableEvent(this.draggable, this.mousePagePosition, this.mouseClientPosition);
}

/**
 * A drag feedback image. 
 */
class DragImage {
  /// A small transparent gif.
  static const String EMPTY = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==';
  
  Element element;
  int x;
  int y;
  
  StreamSubscription _emulatedSub;
  
  /**
   * Constructor for a custom [DragImage]. 
   * 
   * The drag [element] can be an HTML img element, an HTML canvas element 
   * or any visible HTML node on the page.
   * 
   * The [x] and [y] define where the drag image should 
   * appear relative to the mouse cursor.
   */
  DragImage(this.element, this.x, this.y);
  
  /**
   * Constructor to create a [DragImage] for the [draggable]. [draggable]
   * must be visible in the DOM.
   * 
   * [mousePosition] is the mouse coordinate relative to the whole document 
   * (usually the event's page property).
   */
  DragImage._forDraggable(Element draggable, Point mousePosition) {
    // Calc the mouse position relative to the draggable.
    Point draggableOffset = css.pageOffset(draggable);
    this.x = (mousePosition.x - draggableOffset.x).round(); 
    this.y = (mousePosition.y - draggableOffset.y).round(); 
    
    // Create a clone of the draggable.
    if (draggable is ImageElement) {
      element = new ImageElement(src: draggable.src, 
          width: draggable.width, height: draggable.height);
    } else {
      element = draggable.clone(true);
      element.attributes.remove('id');
      element.style.width = draggable.getComputedStyle().width;
      element.style.height = draggable.getComputedStyle().height;
    }
    
    // Add some transparency like browsers would do for native dragging.
    element.style.opacity = '0.75';
  }
  
  /**
   * Instead of the native drag image the drag image is added to the DOM and 
   * manually moved with the mouse.
   * 
   * To update the mouse position call [_updateEmulatedDragImagePosition].
   * 
   * The provided [draggable] is used to know where in the DOM the drag image
   * can be inserted.
   */
  void _addEmulatedDragImage(Element draggable) {
    _logger.finest('Adding emulated drag image.');
    
    var parent = draggable.parentNode;
    
    // Walk parents until we find a non-SVG element. This is to handle cases
    // where we're dragging a node within an SVG document.
    while (parent is svg.SvgElement) {
      parent = parent.parentNode;
    }
    
    // Add the drag image with absolute position.
    parent.append(element);
    
    element.style.position = 'absolute';
    element.style.visibility = 'hidden';
  }

  void _removeEumlatedDragImage() {
    _logger.finest('Removing emulated drag image.');
    if (_emulatedSub != null) {
      _emulatedSub.cancel();
      _emulatedSub = null;
    }
    element.remove();
  }
  
  /**
   * Moves the emulated drag image to the new mouse position. 
   * 
   * [newMousePagePosition] is the mouse coordinate relative to the whole 
   * document.
   */
  void _updateEmulatedDragImagePosition(Point newMousePagePosition) {
    element.style.left = '${(newMousePagePosition.x - this.x)}px';
    element.style.top = '${(newMousePagePosition.y - this.y)}px';
    element.style.visibility = 'visible';
  }
  
  bool _contains(EventTarget target) {
    // If the drag image is an SvgElement, we need to do contains() differently.
    // IE9 does not support the contains() method on SVG elements.
    return element is svg.SvgElement ? _svgContains(element, target) : element.contains(target);
  }
}

bool _svgContains(Element element, EventTarget target) {
  return (target == element) ? true : element.children.any((e) => _svgContains(e, target));
}