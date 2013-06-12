part of html5_dnd;

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
   * CSS class set to the dropzone [element] when a draggable is dragged over 
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
  String dropEffect = 'move';
  
  /**
   * Function to create drag data for this draggable. The result is a map
   * with the type of data as key and the data as value. Default function 
   * returns 'text' as type with an empty String as data.
   */
  DragDataFunction dragDataFunction = (Element draggable) {
    return {'text': ''};
  };
  
  /**
   * Function to create a [DragImage] for this draggable. Default function
   * returns null.
   */
  DragImageFunction dragImageFunction = (Element draggable) {
    return null;
  };
  
  /**
   * If set to true, a custom drag image is drawn even if the browser supports
   * the setting a custom drag image. The polyfill is a bit slower but allows
   * opacity settings on [DragImage] to have an effect.
   */
  bool alwaysUseDragImagePolyfill = false;
  
  // -------------------
  // Draggable Events
  // -------------------
  StreamController<DraggableEvent> _onDragStart;
  StreamController<DraggableEvent> _onDrag;
  StreamController<DraggableEvent> _onDragEnd;
  
  /**
   * Fired when the user starts dragging this draggable.
   */
  Stream<DraggableEvent> get onDragStart {
    if (_onDragStart == null) {
      _onDragStart = new StreamController<DraggableEvent>.broadcast(sync: true, 
          onCancel: () => _onDragStart = null);
    }
    return _onDragStart.stream;
  }
  
  /**
   * Fired every time the mouse is moved while this draggable is being dragged.
   */
  Stream<DraggableEvent> get onDrag {
    if (_onDrag == null) {
      _onDrag = new StreamController<DraggableEvent>.broadcast(sync: true, 
          onCancel: () => _onDrag = null);
    }
    return _onDrag.stream;
  }
  
  /**
   * Fired when the user releases the mouse button while dragging this 
   * draggable. Note: [onDragEnd] is called after onDrop in case there was
   * a drop.
   */
  Stream<DraggableEvent> get onDragEnd {
    if (_onDragEnd == null) {
      _onDragEnd = new StreamController<DraggableEvent>.broadcast(sync: true, 
          onCancel: () => _onDragEnd = null);
    }
    return _onDragEnd.stream;
  }

  /// Query String to restrict drag to a subelement of this groups elements.
  final String _handle;
  
  /**
   * Constructor.
   * 
   * If [handle] is set to a value other than null, it is used as query String
   * to find a subelement of elements in this group. The drag is then 
   * restricted to that subelement.
   */
  DraggableGroup({String handle}) : this._handle = handle;
  
  /**
   * Installs draggable behaviour on [element] and registers it in this group.
   * 
   * ## Internet Explorer 9 ##
   * To enable Drag and Drop of elements other than links and images in Internet
   * Explorer 9 we need a workaround. The javascript file called 'dragdrop.ie9.js' 
   * must be added to the header of the application html.
   * 
   * TODO: Remove IE9 workaround when 
   * [Bug 10837](https://code.google.com/p/dart/issues/detail?id=10837) is fixed.
   */
  void install(Element element) {
    super.install(element);
    List<StreamSubscription> subs = new List<StreamSubscription>();
    
    // Enable native dragging.
    element.attributes['draggable'] = 'true';
    if (!html5.supportsDraggable) {
      // HTML5 draggable support is not available --> try to use workaround.
      _logger.finest('Draggable is not supported, installing draggable polyfill');
      subs.add(_polyfillDraggable(element));
    }
    
    DragImage dragImage;
    bool usingDragImagePolyfill = false;
    StreamSubscription polyfillDragOverSubscription;
    
    
    // If requested, use handle.
    bool isHandle = false;
    if (_handle != null) {
      Element handleElement = element.query(_handle);    
      
      if (handleElement != null) {
        subs.add(handleElement.onMouseDown.listen((_) {
          _logger.finest('handle onMouseDown');
          isHandle = true;
        }));
        subs.add(handleElement.onMouseUp.listen((_) {
          _logger.finest('handle onMouseUp');
          isHandle = false;
        }));
      }
    }
    
    // -------------------
    // Drag Start
    // -------------------
    subs.add(element.onDragStart.listen((MouseEvent mouseEvent) {
      if (_handle != null && !isHandle) {
        mouseEvent.preventDefault();
        return;
      }
      _logger.finest('onDragStart');
      // In Firefox it is possible to start selection outside of a draggable,
      // then drag entire selection. This leads to strange behavior, so we 
      // deactivate selection here.
      if (window.getSelection().rangeCount > 0) {
        window.getSelection().removeAllRanges();
      }
      
      isHandle = false;
      currentDraggable = element;
      currentDraggableGroup = this;
      
      // Add CSS classes
      if (draggingClass != null) {
        // Defer adding the dragging class until the end of the event loop.
        // This makes sure that the style is not applied to the drag image.
        Timer.run(() {
          element.classes.add(draggingClass);
        });
      }
      if (dragOccurringClass != null) {
        document.body.classes.add(dragOccurringClass);
      }
      
      // The allowed 'type of drag'. 
      // Unfortunately, in Firefox and IE, multiple allowed effects (like 'all'
      // or 'copyMove') do not work. They will not show the correct cursor when
      // the actual dataTransfer.dropEffect is set in onDragOver. Thus, only 
      // the values 'move', 'copy', 'link', and 'none' should be used.
      mouseEvent.dataTransfer.effectAllowed = dropEffect;
      
      Map<String, String> dragData = dragDataFunction(element);
      if (dragData != null) {
        dragData.forEach((String type, String data) {
          mouseEvent.dataTransfer.setData(type, data);
        });
      }
      
      dragImage = dragImageFunction(element);
      if (dragImage != null) {
        if (alwaysUseDragImagePolyfill || !html5.supportsSetDragImage) {
          usingDragImagePolyfill = true;
          // Install the polyfill.
          polyfillDragOverSubscription = _polyfillSetDragImage(element, 
              mouseEvent, dragImage);
          
        } else {
          mouseEvent.dataTransfer.setDragImage(dragImage.image, dragImage.x, 
              dragImage.y);
        }
      }
      
      if (_onDragStart != null) {
        _onDragStart.add(new DraggableEvent(element, mouseEvent));
      }
    }));
    
    // -------------------
    // Drag
    // -------------------
    subs.add(element.onDrag.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null) return;
      
      if (_onDrag != null) {
        _onDrag.add(new DraggableEvent(element, mouseEvent));
      }
    }));
    
    // -------------------
    // Drag End
    // -------------------
    subs.add(element.onDragEnd.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null) return;
      _logger.finest('onDragEnd');
      
      // Remove CSS classes.
      if (draggingClass != null) {
        element.classes.remove(draggingClass);
      }
      if (dragOccurringClass != null) {
        document.body.classes.remove(dragOccurringClass);
      }
      
      // Remove drag image if polyfill was used.
      if (usingDragImagePolyfill) {
        dragImage.polyfill.remove();
        polyfillDragOverSubscription.cancel();
      }
      
      if (_onDragEnd != null) {
        _onDragEnd.add(new DraggableEvent(element, mouseEvent));
      }
      
      // Reset variables.
      currentDraggable = null;
      currentDraggableGroup = null;
      currentDragOverElements.clear();
      dragImage = null;
      usingDragImagePolyfill = false;
      polyfillDragOverSubscription = null;
    }));
    
    installedElements[element].addAll(subs);
  }
  
  /**
   * Workaround to enable Drag and Drop of elements other than links and images 
   * in Internet Explorer 9.
   */
  StreamSubscription _polyfillDraggable(Element element) {
    return element.onSelectStart.listen((MouseEvent mouseEvent) {
      _logger.finest('Draggable Polyfill: onSelectStart');
      
      // Prevent selection of text.
      mouseEvent.preventDefault();
      
      try {
        // Call 'dragDrop()' on element via javascript function.
        js.context.callDragDrop(element);
      } on NoSuchMethodError {
        _logger.severe('JavaScript method "callDragDrop" not found. Please' 
            + ' load the file "dnd.polyfill.js" in your application html.');
      } catch(e) {
        _logger.severe('Calling "dragDrop()" polyfill via JavaScript failed: ' 
            + e.toString());
      }
    });
  }

  /**
   * Installs the polyfill for 'setDragImage'. Instead of the native drag image
   * an image is drawn and manually moved around.
   * 
   * The [StreamSubscription] of document.onDragOver event is returned and 
   * should be canceled when the drag ended.
   */
  StreamSubscription _polyfillSetDragImage(Element element, MouseEvent mouseEvent, 
                                           DragImage dragImage) {
    _preventDefaultDragImage(element, mouseEvent);
    
    // Manually add the drag image polyfill with absolute position.
    document.body.children.add(dragImage.polyfill);
    dragImage.polyfill.style.position = 'absolute';
    dragImage.polyfill.style.visibility = 'hidden';
    
    // Because of a Firefox Bug https://bugzilla.mozilla.org/show_bug.cgi?id=505521
    // we can't use onDrag event of the dragged element because the mouse events
    // x-coordinates are always 0.
    return document.onDragOver.listen((MouseEvent docMouseEvent) {
      // Manually set the position.
      Point mousePosition = css.getMousePosition(docMouseEvent);
      dragImage.polyfill.style.left = '${(mousePosition.x - dragImage.x)}px';
      dragImage.polyfill.style.top = '${(mousePosition.y - dragImage.y)}px';
      dragImage.polyfill.style.visibility = 'visible';
    });
  }

  /**
   * Prevents browser from drawing of standard drag image.
   */
  void _preventDefaultDragImage(Element element, MouseEvent mouseEvent) {
    if (html5.supportsSetDragImage) {
      // Set drag image to 
      mouseEvent.dataTransfer.setDragImage(
          new ImageElement(src: DragImage.EMPTY), 0, 0);
    } else {
      // To force the browser not to display the default drag image, which is the 
      // html element beeing dragged, we must set display to 'none'. Visibility 
      // 'hidden' won't work (IE drags a white box). To still keep the space
      // of the display='none' element, we create a clone as a temporary 
      // replacement.
      Element tempReplacement = element.clone(true);
      String display = element.style.display;
      element.parent.insertBefore(tempReplacement, element);
      element.style.display = 'none';
      
      Timer.run(() {
        // At the end of the event loop, show original element again and remove 
        // temporary replacement.
        element.style.display = display;
        tempReplacement.remove();
      });
    }
  }
}

typedef Map<String, String> DragDataFunction(Element draggable);

typedef DragImage DragImageFunction(Element draggable);

/**
 * Event for draggable elements.
 */
class DraggableEvent {
  Element draggable;
  MouseEvent mouseEvent;
  
  DraggableEvent(this.draggable, this.mouseEvent);
}

/**
 * A drag feedback [image] element. The [x] and [y] define where the image 
 * should appear relative to the mouse cursor.
 */
class DragImage {
  /// A small transparent gif.
  static const String EMPTY = 'data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==';
  
  final ImageElement image;
  final int x;
  final int y;
  
  /// Opacity. Only has an effect it the polyfill is used.
  String polyfillOpacity = '0.75';
  
  Element _polyfill;
  
  DragImage(this.image, this.x, this.y);
  
  /**
   * Returns the element that is used for the polyfill drag image.
   * 
   * As the drawn image might be under the cursor, we must make sure that mouse 
   * events are passed through to the element underneath. This is done by 
   * setting the CSS property 'pointer-events' to 'none'. If pointer-events are 
   * not supported (IE9 and IE10) the image is wrapped inside an SVG. See also: 
   * http://www.useragentman.com/blog/2013/04/26/clicking-through-clipped-images-using-css-pointer-events-svg-paths-and-vml/
   */
  Element get polyfill {
    if (_polyfill == null) {
      // Make sure that mouse events are forwarded to the layer below.
      if (html5.supportsPointerEvents) {
        _polyfill = image;
        _polyfill.style.pointerEvents = 'none';
      } else {
        _polyfill = _createSvgElement();
      }
      
      // Add some transparency.
      _polyfill.style.opacity = polyfillOpacity;
    }
    return _polyfill;
  }
  
  
  /**
   * Creates an SVG tag containing the [image].
   */
  Element _createSvgElement() {
    return new svg.SvgElement.svg("""
        <svg xmlns="http://www.w3.org/2000/svg"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        
        width="${image.width}"
        height="${image.height}">
        <image xlink:href="${image.src}" 
          x="0" 
          y="0" 
          width="${image.width}" 
          height="${image.height}" 
          />
        </svg>
    """)
    // Event IE9 and IE10 support pointer-events on SVGs.
    ..style.pointerEvents = 'none';
  }
}