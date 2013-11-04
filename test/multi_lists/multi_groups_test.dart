library multi_groups_test;

import 'dart:html';

import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:html5_dnd/html5_dnd.dart';

final _logger = new Logger("multi_groups_test");

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