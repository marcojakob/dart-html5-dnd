/**
 * Test for sorting complex nested elements.
 */
library complex_elements_test;

import 'dart:html';

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
  SortableGroup sortGroup = new SortableGroup()
  ..installAll(queryAll('.group'))
  ..onSortUpdate.listen((SortableEvent event) {
    int originalIndex = event.originalPosition.index;
    int newIndex = event.newPosition.index;
    
    _logger.fine('sortable completed with originalIndex=$originalIndex, newIndex=$newIndex');
  });
}