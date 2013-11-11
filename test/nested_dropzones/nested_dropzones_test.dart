/**
 * Test for nested dropzones.
 */
library nested_dropzones_test;

import 'dart:html';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:html5_dnd/html5_dnd.dart';

final _logger = new Logger("nested_dropzones_test");

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
  // Install draggables.
  DraggableGroup dragGroup1 = new DraggableGroup()
  ..installAll(querySelectorAll('.draggable1'));
  
  DraggableGroup dragGroup2 = new DraggableGroup()
  ..installAll(querySelectorAll('.draggable2'));
  
  // Install dropzones.
  DropzoneGroup dropGroup1 = new DropzoneGroup()
  ..install(querySelector('.container'))
  ..accept.add(dragGroup1)
  ..onDrop.listen((DropzoneEvent event) {
    event.dropzone.querySelector('span').text = '!!dropped!!';
  });
  
  DropzoneGroup dropGroup2 = new DropzoneGroup()
  ..install(querySelector('.child'))
  ..accept.add(dragGroup2)
  ..onDrop.listen((DropzoneEvent event) {
    event.dropzone.querySelector('span').text = '!!dropped!!';
  });
}