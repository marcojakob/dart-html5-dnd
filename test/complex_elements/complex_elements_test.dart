/**
 * Test for sorting complex nested elements.
 */
library complex_elements_test;

import 'dart:html';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:html5_dnd/html5_dnd.dart';

final _logger = new Logger("complex_elements_test");

main() {
  initLogging();
  
  installDragAndDrop();
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

void installDragAndDrop() {
  SortableGroup sortGroup = new SortableGroup()
  ..installAll(queryAll('.group'))
  ..onSortUpdate.listen((SortableEvent event) {
    int originalIndex = event.originalPosition.index;
    int newIndex = event.newPosition.index;
    
    _logger.fine('sortable completed with originalIndex=$originalIndex, newIndex=$newIndex');
  });
}