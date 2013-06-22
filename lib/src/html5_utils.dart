/// Some HTML5 helper functions.
library html5_dnd.html5_utils;

import 'dart:html';
import 'package:logging/logging.dart';

final _logger = new Logger("html5_dnd.html5_utils");

bool _supportsDraggable;
bool _supportsSetDragImage;
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
    _logger.finest('Browser support for HTML5 draggable: $_supportsDraggable.');
  }
  return _supportsDraggable;
}

/**
 * Returns true if the browser supports "setDragImage" of HTML5 Drag and Drop.
 * IE9 and IE10 will return false.
 */
bool get supportsSetDragImage {
  if (_supportsSetDragImage == null) {
    // TODO: We should do feature detection instead of browser detection here
    // but there currently is no way in Dart.
    // TODO: Keep an eye on IE11.
    
    // Detect Internet Explorer (which does not support HTML5 setDragImage).
    if (isInternetExplorer) {
      _supportsSetDragImage = false;
    } else {
      _supportsSetDragImage = true;
    }
    _logger.finest('Browser support for HTML5 setDragImage: $_supportsSetDragImage.');
  }
  return _supportsSetDragImage;
}

/**
 * Returns true if the current browser is Internet Explorer.
 */
bool get isInternetExplorer {
  if (_isInternetExplorer == null) {
    _isInternetExplorer = window.navigator.appName == 'Microsoft Internet Explorer';
  }
  return _isInternetExplorer;
}