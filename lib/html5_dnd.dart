/**
 * Helper library for native HTML5 Drag and Drop. There are draggable elements 
 * that can be dropped inside dropzone elements. 
 */
library html5_dnd;

import 'dart:html';
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:svg' as svg;
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';

import 'src/css_utils.dart' as css;
import 'src/html5_utils.dart' as html5;

import 'src/sortable/sortable.dart';
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
 * Default is false.
 */
bool enableTouchEvents = false;

/** 
 * Return true if touch events are enabled and the current device supports it.
 */
bool _useTouchEvents() {
  return enableTouchEvents && TouchEvent.supported;
}