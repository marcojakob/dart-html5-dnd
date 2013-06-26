library html5_dnd_example;

import 'dart:html';

import 'dart:async';
import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:logging/logging.dart';
import 'package:html5_dnd/html5_dnd.dart';

main() {
  // Uncomment to enable logging.
//  Logger.root.onRecord.listen(new PrintHandler().call);
//  Logger.root.level = Level.FINEST;
  
  // Enable touch support.
  enableTouchEvents = true;
  
  // Install Drag and Drop examples.
  sectionDraggableAndDropzone();
  sectionDraggingDivs();
  sectionDropEffects();
  sectionDragImages();
  sectionNestedElements();
  
  // Install Sortable examples.
  sectionSortableList();
  sectionSortableGrid();
  sectionSortableListExclude();
  sectionSortableListHandles();
  sectionSortableTwoGroups();
}

sectionDraggableAndDropzone() {
  // Install draggables (documents).
  DraggableGroup dragGroup = new DraggableGroup()
  ..installAll(queryAll('#draggable-dropzone .document'));
  
  // Install dropzone (trash).
  DropzoneGroup dropGroup = new DropzoneGroup()
  ..install(query('#draggable-dropzone .trash'))
  ..accept.add(dragGroup)
  ..onDrop.listen((DropzoneEvent event) {
    event.draggable.remove();
    event.dropzone.classes.add('full');
  });
}

sectionDraggingDivs() {
  // Install draggable.
  DraggableGroup dragGroup = new DraggableGroup()
  ..installAll(queryAll('#dragging-divs .dragme'));
  
  // Install dropzone.
  DropzoneGroup dropGroup = new DropzoneGroup()
  ..install(query('#dragging-divs .dropzone'))
  ..accept.add(dragGroup);
}

sectionDropEffects() {
  // Install draggables.
  DraggableGroup dragGroupMove = new DraggableGroup()
  ..dropEffect = DROP_EFFECT_MOVE
  ..install(query('#drop-effects .move'));
  
  DraggableGroup dragGroupCopy = new DraggableGroup()
  ..dropEffect = DROP_EFFECT_COPY
  ..install(query('#drop-effects .copy'));
  
  DraggableGroup dragGroupLink = new DraggableGroup()
  ..dropEffect = DROP_EFFECT_LINK
  ..install(query('#drop-effects .link'));
  
  DraggableGroup dragGroupNone = new DraggableGroup()
  ..dropEffect = DROP_EFFECT_NONE
  ..install(query('#drop-effects .none'));
  
  // Install dropzone.
  DropzoneGroup dropGroup = new DropzoneGroup()
  ..install(query('#drop-effects .trash'))
  ..accept.addAll([dragGroupMove, dragGroupCopy, dragGroupLink, dragGroupNone])
  ..onDrop.listen((DropzoneEvent event) {
    event.draggable.remove();
    event.dropzone.classes.add('full');
  });
}

sectionDragImages() {
  ImageElement png = new ImageElement(src: 'icons/smiley-happy.png');
  CanvasElement canvas = new CanvasElement();
  var ctx = canvas.context2D
      ..fillStyle = "rgb(200,0,0)"
      ..fillRect(10, 10, 55, 50);
  var dataUrl = canvas.toDataUrl("image/jpeg", 0.95);
  //Create a new image element from the data URL.
  ImageElement canvasImage = new ImageElement(src: dataUrl);
  
  // Install draggables.
  DraggableGroup dragGroupOne = new DraggableGroup(
      dragImageFunction: (Element draggable) => new DragImage(png, 40, 40))
  ..install(query('#drag-images .one'));
  
  DraggableGroup dragGroupTwo = new DraggableGroup(
      dragImageFunction: (Element draggable) => new DragImage(png, -20, -20))
  ..install(query('#drag-images .two'));
  
  DraggableGroup dragGroupThree = new DraggableGroup(
      dragImageFunction: (Element draggable) => new DragImage(canvasImage, 20, 20))
  ..install(query('#drag-images .three'));
  
  // Install dropzone.
  DropzoneGroup dropGroup = new DropzoneGroup()
  ..install(query('#drag-images .dropzone'))
  ..accept.addAll([dragGroupOne, dragGroupTwo, dragGroupThree]);
}

sectionNestedElements() {
  TextAreaElement textarea = query('#nested-elements .dropzone textarea');
  InputElement input = query('#nested-elements .dropzone input');
  input.value = 'Drag here!';
  textarea.text = '';
  int enterLeaveCounter = 1;
  int overCounter = 1;
  
  // Install draggables.
  DraggableGroup dragGroup = new DraggableGroup()
  ..install(query('#nested-elements .dragme'));
  
  // Install dropzone.
  DropzoneGroup dropGroup = new DropzoneGroup()
  ..install(query('#nested-elements .dropzone'))
  ..accept.add(dragGroup)
  ..onDragEnter.listen((DropzoneEvent event) {
    textarea.appendText('${enterLeaveCounter++} drag enter fired\n');
    textarea.scrollTop = textarea.scrollHeight;
  })
  ..onDragOver.listen((DropzoneEvent event) {
    input.value = '${overCounter++} drag over fired';
  })
  ..onDragLeave.listen((DropzoneEvent event) {
    textarea.appendText('${enterLeaveCounter++} drag leave fired\n');
    textarea.scrollTop = textarea.scrollHeight;
  })
  ..onDrop.listen((DropzoneEvent event) {
    textarea.appendText('${enterLeaveCounter++} drop fired\n');
    textarea.scrollTop = textarea.scrollHeight;
  });
}

sectionSortableList() {
  SortableGroup sortGroup = new SortableGroup()
  ..installAll(queryAll('#sortable-list li'))
  ..onSortUpdate.listen((SortableEvent event) {
    // do something when user sorted the elements...
  });
  
  // Only accept elements from this section.
  sortGroup.accept.add(sortGroup);
}

sectionSortableGrid() {
  SortableGroup sortGroup = new SortableGroup()
  ..isGrid = true
  ..installAll(queryAll('#sortable-grid li'));
  
  // Only accept elements from this section.
  sortGroup.accept.add(sortGroup);
}

sectionSortableListExclude() {
  SortableGroup sortGroup = new SortableGroup()
  ..installAll(queryAll('#sortable-list-exclude li:not(.disabled)'));
  
  // Only accept elements from this section.
  sortGroup.accept.add(sortGroup);
}

sectionSortableListHandles() {
  SortableGroup sortGroup = new SortableGroup(handle: 'span')
  ..installAll(queryAll('#sortable-list-handles li'));
  
  // Only accept elements from this section.
  sortGroup.accept.add(sortGroup);
}

sectionSortableTwoGroups() {
  ImageElement png = new ImageElement(src: 'icons/smiley-happy.png');
  
  SortableGroup sortGroup1 = new SortableGroup()
  ..installAll(queryAll('#sortable-two-groups .group1 li'))
  ..onSortUpdate.listen((SortableEvent event) {
    event.originalGroup.uninstall(event.draggable);
    event.newGroup.install(event.draggable);
  });
  
  SortableGroup sortGroup2 = new SortableGroup(
      dragImageFunction: (Element draggable) => new DragImage(png, 5, 5))
  ..installAll(queryAll('#sortable-two-groups .group2 li'))
  ..onSortUpdate.listen((SortableEvent event) {
    event.originalGroup.uninstall(event.draggable);
    event.newGroup.install(event.draggable);
  });
  
  // Only accept elements from this section.
  sortGroup1.accept.addAll([sortGroup1, sortGroup2]);
  sortGroup2.accept.addAll([sortGroup1, sortGroup2]);
}