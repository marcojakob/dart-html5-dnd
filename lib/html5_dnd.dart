/**
 * Helper library for native HTML5 Drag and Drop. There are [Draggable] elements 
 * that can be dropped inside [Dropzone] elements. 
 */
library html5_dnd;

import 'dart:html';
import 'dart:async';
import 'dart:collection';
import 'dart:svg' as svg;
import 'package:meta/meta.dart';
import 'package:js/js.dart' as js;
import 'package:logging/logging.dart';

import 'package:html5_dnd/src/css_utils.dart' as css;
import 'package:html5_dnd/src/html5_utils.dart' as html5;

final _logger = new Logger("html5_dnd");

/// Currently dragged element.
Draggable currentDraggable;

/**
 * Class for making an [Element] draggable.
 * 
 * ## Internet Explorer 9 ##
 * To enable Drag and Drop of elements other than links and images in Internet
 * Explorer 9 we need a workaround. The javascript file called 'dragdrop.ie9.js' 
 * must be added to the header of the application html.
 * 
 * TODO: Remove IE9 workaround when 
 * [Bug 10837](https://code.google.com/p/dart/issues/detail?id=10837) is fixed.
 */
class Draggable {
  /// The wrapped element.
  Element element;
  
  // -------------------
  // Options
  // -------------------
  /**
   * CSS class set to the draggable element during a drag. Default is 
   * 'dnd-dragging'. If null, no css class is added.
   */
  String draggingClass = 'dnd-dragging';
  
  /**
   * CSS class set to the html body tag during a drag. Default is 
   * 'dnd-drag-occurring'. If null, no CSS class is added.
   */
  String dragOccurringClass = 'dnd-drag-occurring';
  
  /**
   * Controls the feedback that the user is given during the dragenter and 
   * dragover events. When the user hovers over a target element, the browser's
   * cursor will indicate what type of operation is going to take place (e.g. a 
   * copy, a move, etc.). The effect can take on one of the following values: 
   * none, copy, link, move. Default is 'move'.
   */
  String dropEffect = 'move';
  
  /**
   * Disables the draggable if set to true.
   */
  bool disabled = false;
  
  /**
   * Function to create drag data for this draggable. The result is a map
   * with the type of data as key and the data as value. Default function 
   * returns 'text' as type with an empty String as data.
   */
  DragDataFunction dragDataFunction = (Draggable draggable) {
    return {'text': ''};
  };
  
  /**
   * Function to create a [DragImage] for this draggable. Default function
   * returns null.
   */
  DragImageFunction dragImageFunction = (Draggable draggable) {
    return null;
  };
  
  /**
   * If set to true, a custom drag image is drawn even if the browser supports
   * the setting a custom drag image. The polyfill is a bit slower but allows
   * opacity settings on [DragImage] to have an effect.
   */
  bool alwaysUseDragImagePolyfill = false;

  // -------------------
  // Events
  // -------------------
  /**
   * Fired when the user starts dragging this draggable.
   */
  Stream<DraggableEvent> get onDragStart => _onDragStart.stream;
  
  /**
   * Fired every time the mouse is moved while this draggable is being dragged.
   */
  Stream<DraggableEvent> get onDrag => _onDrag.stream;
  
  /**
   * Fired when the user releases the mouse button while dragging this 
   * draggable. Note: [onDragEnd] is called after onDrop in case there was
   * a drop.
   */
  Stream<DraggableEvent> get onDragEnd => _onDragEnd.stream;

  // -------------------
  // Private
  // -------------------
  StreamController<DraggableEvent> _onDragStart = new StreamController<DraggableEvent>();
  StreamController<DraggableEvent> _onDrag = new StreamController<DraggableEvent>();
  StreamController<DraggableEvent> _onDragEnd = new StreamController<DraggableEvent>();
  
  /**
   * Creates a draggable with the specified [element].
   * 
   * If [handle] is set to a value other than null, the drag is restricted to 
   * the specified subelement of [element].
   */
  Draggable(this.element, {String handle: null}) {
    // Enable native dragging.
    element.attributes['draggable'] = 'true';
    if (!html5.supportsDraggable) {
      // HTML5 draggable support is not available --> try to use workaround.
      _logger.finest('Draggable is not supported, installing draggable polyfill');
      _polyfillDraggable();
    }
    
    DragImage dragImage;
    bool usingDragImagePolyfill = false;
    StreamSubscription polyfillDragOverSubscription;

    // If requested, use handle.
    bool isHandle = false;    
    if (handle != null) {
      element.query(handle)
        ..onMouseDown.listen((_) {
          _logger.finest('handle onMouseDown');
          isHandle = true;
        })
        ..onMouseUp.listen((_) {
          _logger.finest('handle onMouseUp');
          isHandle = false;
        });
    }
    
    // Drag Start.
    element.onDragStart.listen((MouseEvent mouseEvent) {
      if (disabled || (handle != null && !isHandle)) {
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
      currentDraggable = this;
      
      // Add CSS classes
      if (draggingClass != null) {
        // Defer adding the dragging class until the end of the event loop.
        // This makes sure that the style is not applied to the drag image.
        Timer.run(() {
          css.addCssClass(element, draggingClass);
        });
      }
      if (dragOccurringClass != null) {
        css.addCssClass(document.body, dragOccurringClass);
      }
      
      // The allowed 'type of drag'. 
      // Unfortunately, in Firefox and IE, multiple allowed effects (like 'all'
      // or 'copyMove') do not work. They will not show the correct cursor when
      // the actual dataTransfer.dropEffect is set in onDragOver. Thus, only 
      // the values 'move', 'copy', 'link', and 'none' should be used.
      mouseEvent.dataTransfer.effectAllowed = dropEffect;
      
      Map<String, String> dragData = dragDataFunction(this);
      if (dragData != null) {
        dragData.forEach((String type, String data) {
          mouseEvent.dataTransfer.setData(type, data);
        });
      }
      
      dragImage = dragImageFunction(this);
      if (dragImage != null) {
        if (alwaysUseDragImagePolyfill || !html5.supportsSetDragImage) {
          usingDragImagePolyfill = true;
          // Install the polyfill.
          polyfillDragOverSubscription = _polyfillSetDragImage(mouseEvent, dragImage);
          
        } else {
          mouseEvent.dataTransfer.setDragImage(dragImage.image, dragImage.x, 
              dragImage.y);
        }
      }
      
      if (_onDragStart.hasListener && !_onDragStart.isPaused 
          && !_onDragStart.isClosed) {
        _onDragStart.add(new DraggableEvent(this, mouseEvent));
      }
    });
    
    // Drag.
    element.onDrag.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled) return;
      
      if (_onDrag.hasListener && !_onDrag.isPaused 
          && !_onDrag.isClosed) {
        _onDrag.add(new DraggableEvent(this, mouseEvent));
      }
    });
    
    // Drag End.
    element.onDragEnd.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled) return;
      _logger.finest('onDragEnd');
      
      // Remove CSS classes.
      if (draggingClass != null) {
        css.removeCssClass(element, draggingClass);
      }
      if (dragOccurringClass != null) {
        css.removeCssClass(document.body, dragOccurringClass);
      }
      
      // Remove drag image if polyfill was used.
      if (usingDragImagePolyfill) {
        dragImage.polyfill.remove();
        polyfillDragOverSubscription.cancel();
      }
      
      if (_onDragEnd.hasListener && !_onDragEnd.isPaused 
          && !_onDragEnd.isClosed) {
        _onDragEnd.add(new DraggableEvent(this, mouseEvent));
      }
      
      currentDraggable = null;
      dragImage = null;
      usingDragImagePolyfill = false;
      polyfillDragOverSubscription = null;
    });
  }
  
  /**
   * Workaround to enable Drag and Drop of elements other than links and images 
   * in Internet Explorer 9.
   */
  void _polyfillDraggable() {
    element.onSelectStart.listen((MouseEvent mouseEvent) {
      if (disabled) return;
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
  StreamSubscription _polyfillSetDragImage(MouseEvent mouseEvent, DragImage dragImage) {
    _preventDefaultDragImage(mouseEvent);
    
    // Manually add the drag image polyfill with absolute position.
    document.body.children.add(dragImage.polyfill);
    dragImage.polyfill.style.position = 'absolute';
    dragImage.polyfill.style.visibility = 'hidden';
    
    // Because of a Firefox Bug https://bugzilla.mozilla.org/show_bug.cgi?id=505521
    // we can't use onDrag event of the dragged element because the mouse events
    // x-coordinates are always 0.
    StreamSubscription subscription = document.onDragOver.listen((MouseEvent docMouseEvent) {
      // Manually set the position.
      Point mousePosition = css.getMousePosition(docMouseEvent);
      dragImage.polyfill.style.left = '${(mousePosition.x - dragImage.x)}px';
      dragImage.polyfill.style.top = '${(mousePosition.y - dragImage.y)}px';
      dragImage.polyfill.style.visibility = 'visible';
    });
    
    return subscription;
  }
  
  /**
   * Prevents browser from drawing of standard drag image.
   */
  void _preventDefaultDragImage(MouseEvent mouseEvent) {
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

/**
 * Class for making an [Element] to a dropzone for [Draggable]s.
 */
class Dropzone {
  /// The wrapped dropzone element.
  Element element;
  
  // ----------
  // Options
  // ----------
  /**
   * CSS class set to the [element] when a draggable is dragged over this
   * dropzone. Default is 'dnd-over'. If null, no css class is added.
   */
  String overClass = 'dnd-over';
  
  /**
   * Disables the dropzone if set to true.
   */
  bool disabled = false;
  
  /**
   * List of all [Draggable] elements that this dropzone accepts. 
   * If the list is empty, all draggables are accepted.
   */
  Set<Element> acceptDraggables = new Set<Element>();
  
  // ----------
  // Events
  // ----------
  StreamController<DropzoneEvent> _onDragEnter = new StreamController<DropzoneEvent>();
  StreamController<DropzoneEvent> _onDragOver = new StreamController<DropzoneEvent>();
  StreamController<DropzoneEvent> _onDragLeave = new StreamController<DropzoneEvent>();
  StreamController<DropzoneEvent> _onDrop = new StreamController<DropzoneEvent>();
  
  /**
   * Fired when the mouse is first moved over this dropzone while dragging the 
   * current drag element.
   */
  Stream<DropzoneEvent> get onDragEnter => _onDragEnter.stream;
  
  /**
   * Fired as the mouse is moved over this dropzone when a drag of is occuring. 
   */
  Stream<DropzoneEvent> get onDragOver => _onDragOver.stream;
  
  /**
   * Fired when the mouse leaves the dropzone element while dragging.
   */
  Stream<DropzoneEvent> get onDragLeave => _onDragLeave.stream;
  
  /**
   * Fired at the end of the drag operation when the draggable is dropped
   * inside this dropzone.
   */
  Stream<DropzoneEvent> get onDrop => _onDrop.stream;
  
  
  // ----------
  // Private properties
  // ----------
  
  // Keep track of [Element]s where dragEnter or dragLeave has been fired on.
  // This is necessary as a dragEnter or dragLeave event is not only fired
  // on the [dropzoneElement] but also on its children. Now, whenever the 
  // [dragOverElements] is empty we know the dragEnter or dragLeave event
  // was fired on the real [dropzoneElement].
  Set<Element> _dragOverElements = new Set<Element>();
  
  /**
   * Creates a dropzone with the specified [element].
   */
  Dropzone(this.element) {
    bool dropAccept = false;
    
    // Drag Enter.
    element.onDragEnter.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled) return;
      
      // Necessary for IE?
      mouseEvent.preventDefault();
      
      // Test if this dropzone accepts the drop of the current draggable.
      dropAccept = acceptDraggables.isEmpty 
          || acceptDraggables.contains(currentDraggable.element);
      if (dropAccept) {
        mouseEvent.dataTransfer.dropEffect = currentDraggable.dropEffect;
      } else {
        mouseEvent.dataTransfer.dropEffect = 'none';
        return; // Return here as drop is not accepted.
      }
      
      // Only handle dropzone element itself and not any of its children.
      if (_dragOverElements.length == 0) {
        
        if (overClass != null) {
          css.addCssClass(element, overClass);
        }
            
        if (_onDragEnter.hasListener && !_onDragEnter.isPaused 
            && !_onDragEnter.isClosed) {
          _onDragEnter.add(new DropzoneEvent(currentDraggable, this, mouseEvent));
        }
      }
      
      _dragOverElements.add(mouseEvent.target);
      _logger.finest('onDragEnter {dragOverElements.length: ${_dragOverElements.length}}');
    });
    
    // Drag Over.
    element.onDragOver.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled) return;
      
      if (dropAccept) {
        mouseEvent.dataTransfer.dropEffect = currentDraggable.dropEffect;
      } else {
        mouseEvent.dataTransfer.dropEffect = 'none';
        return; // Return here as drop is not accepted.
      }

      // This is necessary to allow us to drop.
      mouseEvent.preventDefault();
      
      if (_onDragOver.hasListener && !_onDragOver.isPaused 
          && !_onDragOver.isClosed) {
        _onDragOver.add(new DropzoneEvent(currentDraggable, this, mouseEvent));
      }
    });
    
    // Drag Leave.
    element.onDragLeave.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled || !dropAccept) return;
      
      // Firefox fires too many onDragLeave events. This condition fixes it. 
      if (mouseEvent.target != mouseEvent.relatedTarget) {
        _dragOverElements.remove(mouseEvent.target);
      }
      
      _logger.finest('onDragLeave {dragOverElements.length: ${_dragOverElements.length}}');
      
      // Only handle on dropzone element and not on any of its children.
      if (_dragOverElements.length == 0) {
        if (overClass != null) {
          css.removeCssClass(element, overClass);
        }
        
        if (_onDragLeave.hasListener && !_onDragLeave.isPaused 
            && !_onDragLeave.isClosed) {
          _onDragLeave.add(new DropzoneEvent(currentDraggable, this, 
              mouseEvent));
        }
      }
    });
    
    // Drop.
    element.onDrop.listen((MouseEvent mouseEvent) {
      // Do nothing if no element of this dnd is dragged.
      if (currentDraggable == null || disabled) return;
      _logger.finest('onDrop');
      
      // Stops browsers from redirecting.
      mouseEvent.preventDefault(); 
      
      if (overClass != null) {
        css.removeCssClass(element, overClass);
      }
      
      if (_onDrop.hasListener && !_onDrop.isPaused 
          && !_onDrop.isClosed) {
        _onDrop.add(new DropzoneEvent(currentDraggable, this, mouseEvent));
      }
      
      // Clear variables used during the drag.
      _dragOverElements.clear();
      dropAccept = false;
    });
  }
  
  /**
   * Resets the dropzone. Might be necessary if the drop zone is dynamically
   * added/removed during a drag.
   */
  void resetDragOverElements() {
    _dragOverElements.clear();
  }
}

typedef Map<String, String> DragDataFunction(Draggable draggable);

typedef DragImage DragImageFunction(Draggable draggable);

/**
 * Event for [Draggable]s.
 */
class DraggableEvent {
  Draggable draggable;
  MouseEvent mouseEvent;
  
  DraggableEvent(this.draggable, this.mouseEvent);
}

/**
 * Event for [Dropzone]s.
 */
class DropzoneEvent {
  Draggable draggable;
  Dropzone dropzone;
  MouseEvent mouseEvent;
  
  DropzoneEvent(this.draggable, this.dropzone, this.mouseEvent);
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