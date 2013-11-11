/**
 * Test for SVG elements.
 */
library svt_test;

import 'dart:html';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:html5_dnd/html5_dnd.dart';

final _logger = new Logger("complex_elements_test");

main() {
  initLogging();
  
  installSvg();
  installSvgWithin();
}

initLogging() {
  DateFormat dateFormat = new DateFormat('yyyy.mm.dd HH:mm:ss.SSS');
  
  // Print output to console.
  Logger.root.onRecord.listen((LogRecord r) {
    print('${dateFormat.format(r.time)}\t${r.loggerName}\t[${r.level.name}]:\t${r.message}');
  });
  
  // Root logger level.
  Logger.root.level = Level.FINEST;
}

void installSvg() {
  var svgDragGroup = new DraggableGroup()
  ..install(querySelector('#draggable-svg'));
  
  var divDragGroup = new DraggableGroup()
  ..install(querySelector('#draggable-div'));
  
  new DropzoneGroup()
  ..install(querySelector('#svg-dropzone'))
  ..install(querySelector('#div-dropzone'))
  ..accept.add(svgDragGroup)
  ..accept.add(divDragGroup);
}

void installSvgWithin() {
  var svgDragGroup = new DraggableGroup()
  ..install(querySelector('#drag-within-svg'));
  
  new DropzoneGroup()
  ..install(querySelector('#drop-within-svg'))
  ..accept.add(svgDragGroup);
}