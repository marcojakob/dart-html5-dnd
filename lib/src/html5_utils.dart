/// Some HTML5 helper functions.
library html5_dnd.html5_utils;

import 'dart:html';
import 'package:js/js.dart' as js;
import 'package:logging/logging.dart';

final _logger = new Logger("html5_dnd.html5_utils");

bool _supportsDraggable;
bool _supportsSetDragImage;
bool _supportsPointerEvents;
bool _isInternetExplorer;

/**
 * Calculates the index of the Element [element] in its parent. If there is no
 * parent, null is returned.
 */
int getElementIndexInParent(Element element) {
  if (element.parent == null) {
    return null;
  }
  int index = 0;
  var previous = element.previousElementSibling;
  while (previous != null) {
    index++;
    previous = previous.previousElementSibling;
  }
  return index;
}

/**
 * Returns true if the HTML5 Draggable Element is supported. 
 * IE9 will return false.
 */
bool get supportsDraggable {
  if (_supportsDraggable == null) {
    _supportsDraggable = new Element.tag('span').draggable != null;
  }
  return _supportsDraggable;
}

/**
 * Returns true if the browser supports "setDragImage" of HTML5 Drag and Drop.
 * IE9 and IE10 will return false.
 */
bool get supportsSetDragImage {
  if (_supportsSetDragImage == null) {
    try {
      // Call via javascript function.
      _supportsSetDragImage = js.context.supportsSetDragImage();
    } on NoSuchMethodError {
      _logger.severe('JavaScript method "supportsSetDragImage()" not found. Please load the file "dnd.polyfill.js" in your application html.');
      _supportsSetDragImage = false;
    } catch(e) {
      _logger.severe('Calling "supportsSetDragImage()" via JavaScript failed: ' 
          + e.toString());
      _supportsSetDragImage = false;
    }
  }
  return _supportsSetDragImage;
}

/**
 * Returns true if the CSS property 'pointer-events' is supported by the 
 * browser (detection technique from Modernizr). IE9 and IE10 will return false.
 */
bool get supportsPointerEvents {
  if (_supportsPointerEvents == null) {
    Element el = new Element.tag('span');
    el.style.cssText = 'pointer-events:auto';
    _supportsPointerEvents = el.style.pointerEvents == 'auto';
  }
  return _supportsPointerEvents;
}

/**
 * Returns true if the browser is internet explorer.
 */
bool get isInternetExplorer {
  if (_isInternetExplorer == null) {
    try {
      // Call via javascript function.
      _isInternetExplorer = js.context.isInternetExplorer();
    } on NoSuchMethodError {
      _logger.severe('JavaScript method "isInternetExplorer()" not found. Please' 
          + ' load the file "dnd.polyfill.js" in your application html.');
      _lazyIsInternetExplorer = false;
    } catch(e) {
      _logger.severe('Calling "isInternetExplorer()" via JavaScript failed: ' 
          + e.toString());
      _isInternetExplorer = false;
    }
  }
  return _isInternetExplorer;
}