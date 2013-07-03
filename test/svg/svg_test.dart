/**
 * Test for SVG elements.
 */
library svt_test;

import 'dart:html';
import 'dart:svg' as svg;

import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:logging/logging.dart';
import 'package:html5_dnd/html5_dnd.dart';

final _logger = new Logger("complex_elements_test");

main() {
  Logger.root.onRecord.listen(new PrintHandler().call);
  Logger.root.level = Level.FINEST;
  
  installSvg();
  installSvgWithin();
}

void installSvg() {
  var svgDragGroup = new DraggableGroup()
  ..install(query('#draggable-svg'));
  
  var divDragGroup = new DraggableGroup()
  ..install(query('#draggable-div'));
  
  new DropzoneGroup()
  ..install(query('#svg-dropzone'))
  ..install(query('#div-dropzone'))
  ..accept.add(svgDragGroup)
  ..accept.add(divDragGroup);
}

void installSvgWithin() {
  var svgDragGroup = new DraggableGroup()
  ..install(query('#drag-within-svg'));
  
  new DropzoneGroup()
  ..install(query('#drop-within-svg'))
  ..accept.add(svgDragGroup);
}