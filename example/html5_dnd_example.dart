library html5_dnd_example;

import 'dart:html';

import 'dart:async';
import 'package:logging_handlers/logging_handlers_shared.dart';
import 'package:logging/logging.dart';
import 'package:html5_dnd/html5_dnd.dart';
import 'package:html5_dnd/html5_sortable.dart';

part 'codeblocks.dart';

main() {
  // Uncomment to enable logging.
//  Logger.root.onRecord.listen(new PrintHandler().call);
//  Logger.root.level = Level.FINEST;
  
  // Drag and Drop
  sectionDraggableAndDropzone();
  sectionDraggingDivs();
  sectionDropEffects();
  sectionDragImages();
  sectionNestedElements();
  
  // Sortable
  sectionSortableList();
  sectionSortableGrid();
  sectionSortableListExclude();
  sectionSortableListHandles();
  sectionSortableTwoGroups();
  sectionDraggableSortable();
  
  installCodeblockTabs();
}

installCodeblockTabs() {
  codeblockDraggableAndDropzone(query('#draggable-dropzone'));
  codeblockDraggingDivs(query('#dragging-divs'));
  codeblockDropEffects(query('#drop-effects'));
  codeblockDragImages(query('#drag-images'));
  codeblockNestedElements(query('#nested-elements'));
  codeblockSortableList(query('#sortable-list'));
  codeblockSortableGrid(query('#sortable-grid'));
  codeblockSortableListExclude(query('#sortable-list-exclude'));
  codeblockSortableListHandles(query('#sortable-list-handles'));
  codeblockSortableTwoGroups(query('#sortable-two-groups'));
  codeblockDraggableSortable(query('#draggable-sortable'));
  
  List<AnchorElement> tabLinks = queryAll('.example-code .menu li a');
  for (AnchorElement link in tabLinks) {
    link.onClick.listen((MouseEvent event) {
      event.preventDefault();
      
      Element exampleCodeParent = link.parent.parent.parent;
      
      // Remove active class on all menu and content tabs.
      exampleCodeParent.queryAll('[tab]').forEach((Element e) {
        e.classes.remove('active');
      });

      // Add active class.
      String currentTab = link.attributes['tab'];
      link.classes.add('active');
      exampleCodeParent.query('.content [tab="$currentTab"]').classes.add('active');
    });  
  }
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
  ..install(query('#drop-effects .move'))
  ..dropEffect = 'move';
  
  DraggableGroup dragGroupCopy = new DraggableGroup()
  ..install(query('#drop-effects .copy'))
  ..dropEffect = 'copy';
  
  DraggableGroup dragGroupLink = new DraggableGroup()
  ..install(query('#drop-effects .link'))
  ..dropEffect = 'link';
  
  DraggableGroup dragGroupNone = new DraggableGroup()
  ..install(query('#drop-effects .none'))
  ..dropEffect = 'none';
  
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
  DraggableGroup dragGroupOne = new DraggableGroup()
  ..install(query('#drag-images .one'))
  ..dragImageFunction = (Element draggable) {
    return new DragImage(png, 40, 40);
  };
  
  DraggableGroup dragGroupTwo = new DraggableGroup()
  ..install(query('#drag-images .two'))
  ..dragImageFunction = (Element draggable) {
    return new DragImage(png, -20, -20);
  };
  
  DraggableGroup dragGroupThree = new DraggableGroup()
  ..install(query('#drag-images .three'))
  ..dragImageFunction = (Element draggable) {
    return new DragImage(canvasImage, 0, 0);
  };
  
  DraggableGroup dragGroupFour = new DraggableGroup()
  ..install(query('#drag-images .four'))
  ..alwaysUseDragImagePolyfill = true
  ..dragImageFunction = (Element draggable) {
    return new DragImage(canvasImage, 0, 0);
  };
  
  // Install dropzone.
  DropzoneGroup dropGroup = new DropzoneGroup()
  ..install(query('#drag-images .dropzone'))
  ..accept.addAll([dragGroupOne, dragGroupTwo, dragGroupThree, dragGroupFour]);
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
  ..installAll(queryAll('#sortable-grid li'))
  ..isGrid = true;
  
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
  
  SortableGroup sortGroup2 = new SortableGroup()
  ..installAll(queryAll('#sortable-two-groups .group2 li'))
  ..dragImageFunction = (Element draggable) {
    return new DragImage(png, 0, 0);
  }
  ..onSortUpdate.listen((SortableEvent event) {
    event.originalGroup.uninstall(event.draggable);
    event.newGroup.install(event.draggable);
  });
  
  // Only accept elements from this section.
  sortGroup1.accept.addAll([sortGroup1, sortGroup2]);
  sortGroup2.accept.addAll([sortGroup1, sortGroup2]);
}

sectionDraggableSortable() {
  DraggableGroup dragGroup = new DraggableGroup()
  ..installAll(queryAll('#draggable-sortable .group1 li'));

  // Create sortable group with initially no installed elements.
  SortableGroup sortGroup = new SortableGroup()
  ..onSortUpdate.listen((SortableEvent event) {
    event.originalGroup.uninstall(event.draggable);
    event.newGroup.install(event.draggable);
  });
  sortGroup.accept.addAll([dragGroup, sortGroup]);
  
  LIElement emptyItem = query('#draggable-sortable .group2 .empty');
  
  // Install an empty item as a dropzone no element is in the list.
  DropzoneGroup emptyListDropzone = new DropzoneGroup()
  ..install(emptyItem)
  ..accept.add(dragGroup)
  ..onDrop.listen((DropzoneEvent event) {
    // Hide empty item.
    emptyItem.style.display = 'none';
    
    // Uninstall in old group and install in new group.
    dragGroup.uninstall(event.draggable);
    event.draggable.remove();
    sortGroup.install(event.draggable);
    query('#draggable-sortable .group2').children.add(event.draggable);
  });
}