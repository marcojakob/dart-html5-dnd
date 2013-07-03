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
  
  installDragAndDrop();
}

void installDragAndDrop() {
  var svgDrag = new DraggableGroup(
      dragImageFunction: (Element draggable) {
        var element = new svg.SvgElement.tag('svg')
            ..attributes = {
                            'width': '100',
                            'height': '100'
            }
            ..append(draggable.clone(true));
        return new DragImage(element, 0, 0);
      }
  );
  svgDrag.install(query("#svgRect"));
  
  var divDrag = new DraggableGroup();
  divDrag.install(query("#div"));
  
  var drop = new DropzoneGroup();
  drop.installAll(queryAll(".dropzone"));
  drop.accept.add(svgDrag);
  drop.accept.add(divDrag);
}