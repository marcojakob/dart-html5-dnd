/**
 * Helper library for native HTML5 Drag and Drop. There are draggable elements 
 * that can be dropped inside dropzone elements. 
 */
library html5_dnd;

import 'dart:html';
import 'dart:async';
import 'dart:math' as math;
import 'dart:svg' as svg;
import 'package:logging/logging.dart';

import 'src/utils.dart' as utils;

export 'src/sortable/sortable.dart';

part 'src/dnd/group.dart';
part 'src/dnd/draggable.dart';
part 'src/dnd/draggable_emulated.dart';
part 'src/dnd/dropzone.dart';
part 'src/dnd/dropzone_emulated.dart';
part 'src/touch/touch.dart';

final _logger = new Logger("html5_dnd");

/**
 * If this property is set to true, touch events are enabled on devices that 
 * support it. 
 * 
 * Default is true.
 */
bool enableTouchEvents = true;


// -------------------
// Feature Detection
// -------------------
bool _usesTouchEvents;
bool _supportsDraggable;
bool _supportsSetDragImage;
bool _isInternetExplorer;

/** 
 * Returns true if touch events are enabled and the current device supports it.
 */
bool usesTouchEvents() {
  if (_usesTouchEvents == null) {
    _usesTouchEvents = enableTouchEvents && TouchEvent.supported;
    _logger.finest('Using touch events: $_usesTouchEvents.');
  }
  return _usesTouchEvents;
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