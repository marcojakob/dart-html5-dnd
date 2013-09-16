/**
 * Test for nested dropzones.
 */
library nested_dropzones_test;

import 'dart:html';

import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:logging/logging.dart';
import 'package:html5_dnd/html5_dnd.dart';

final _logger = new Logger("nested_dropzones_test");

main() {
  Logger.root.onRecord.listen(new PrintHandler().call);
  Logger.root.level = Level.FINEST;
  
  installDragAndDrop();
}

void installDragAndDrop() {
  // Install draggables.
  DraggableGroup dragGroup1 = new DraggableGroup()
  ..installAll(queryAll('.draggable1'));
  
  DraggableGroup dragGroup2 = new DraggableGroup()
  ..installAll(queryAll('.draggable2'));
  
  // Install dropzones.
  DropzoneGroup dropGroup1 = new DropzoneGroup()
  ..install(query('.container'))
  ..accept.add(dragGroup1)
  ..onDrop.listen((DropzoneEvent event) {
    event.dropzone.query('span').text = '!!dropped!!';
  });
  
  DropzoneGroup dropGroup2 = new DropzoneGroup()
  ..install(query('.child'))
  ..accept.add(dragGroup2)
  ..onDrop.listen((DropzoneEvent event) {
    event.dropzone.query('span').text = '!!dropped!!';
  });
}