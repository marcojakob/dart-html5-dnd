library multi_groups_test;

import 'dart:html';

import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:logging/logging.dart';
import 'package:html5_dnd/html5_dnd.dart';

final _logger = new Logger("multi_groups_test");

main() {
  Logger.root.onRecord.listen(new PrintHandler().call);
  Logger.root.level = Level.FINEST;
  
  installDragAndDrop();
}

void installDragAndDrop() {
  SortableGroup groupA = new SortableGroup()
  ..installAll(queryAll('#group-a-sort li'))
  ..forcePlaceholderSize = false
  ..onSortUpdate.listen((SortableEvent event) {
    if (event.originalGroup != event.newGroup) {
      event.originalGroup.uninstall(event.draggable);
      event.newGroup.install(event.draggable);
    }
  });
  
  SortableGroup groupB = new SortableGroup()
  ..installAll(queryAll('#group-b-sort li'))
  ..forcePlaceholderSize = false
  ..onSortUpdate.listen((SortableEvent event) {
    if (event.originalGroup != event.newGroup) {
      event.originalGroup.uninstall(event.draggable);
      event.newGroup.install(event.draggable);
    }
  });
  
  DraggableGroup groupC = new DraggableGroup()
  ..installAll(queryAll('#group-c-drag li'));
  
  groupA.accept.add(groupB);
  groupB.accept.addAll([groupA, groupB, groupC]);
}