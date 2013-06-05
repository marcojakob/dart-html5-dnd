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
  sectionSortableListConnected();
  
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
  codeblockSortableListConnected(query('#sortable-list-connected'));
  
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
  List documents = queryAll('#draggable-dropzone .document');
  for (var document in documents) {
    new Draggable(document);
  }
  
  var trash = query('#draggable-dropzone .trash');
  new Dropzone(trash)
    ..acceptDraggables.addAll(documents)
    ..onDrop.listen((DropzoneEvent event) {
      event.draggable.element.remove();
      event.dropzone.element.classes.add('full');
    });
}

sectionDraggingDivs() {
  Element dragElement = query('#dragging-divs .dragme');
  new Draggable(dragElement);
  
  var dropElement = query('#dragging-divs .dropzone');
  new Dropzone(dropElement)
    ..acceptDraggables.add(dragElement);
}

sectionDropEffects() {
  Draggable move = new Draggable(query('#drop-effects .move'))
    ..dropEffect = 'move';
  Draggable copy = new Draggable(query('#drop-effects .copy'))
    ..dropEffect = 'copy';
  Draggable link = new Draggable(query('#drop-effects .link'))
    ..dropEffect = 'link';
  Draggable none = new Draggable(query('#drop-effects .none'))
    ..dropEffect = 'none';
  
  new Dropzone(query('#drop-effects .trash'))
    ..acceptDraggables.addAll([move.element, 
                               copy.element, 
                               link.element, 
                               none.element])
    ..onDrop.listen((DropzoneEvent event) {
      event.draggable.element.remove();
      event.dropzone.element.classes.add('full');
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
  
  Element dragmeOne = query('#drag-images .one');
  Element dragmeTwo= query('#drag-images .two');
  Element dragmeThree = query('#drag-images .three');
  Element dragmeFour = query('#drag-images .four');
  
  new Draggable(dragmeOne)
    ..dragImageFunction = (Draggable draggable) {
      return new DragImage(png, 40, 40);
    };
  new Draggable(dragmeTwo)
    ..dragImageFunction = (Draggable draggable) {
      return new DragImage(png, -20, -20);
    };
  new Draggable(dragmeThree)
    ..dragImageFunction = (Draggable draggable) {
      return new DragImage(canvasImage, 0, 0);
    };
  new Draggable(dragmeFour)
    ..dragImageFunction = (Draggable draggable) {
      return new DragImage(canvasImage, 0, 0);
    }
    ..alwaysUseDragImagePolyfill = true;
  

  Element dropzone = query('#drag-images .dropzone');
  new Dropzone(dropzone)
    ..acceptDraggables.addAll([dragmeOne, dragmeTwo, dragmeThree, dragmeFour]);
}

sectionNestedElements() {
  Element dragme = query('#nested-elements .dragme');
  Element dropzone = query('#nested-elements .dropzone');
  TextAreaElement textarea = query('#nested-elements .dropzone textarea');
  InputElement input = query('#nested-elements .dropzone input');
  input.value = 'Drag here!';
  textarea.text = '';
  
  new Draggable(dragme);
  
  int enterLeaveCounter = 1;
  int overCounter = 1;
  new Dropzone(dropzone)
    ..acceptDraggables.add(dragme)
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
  var items = queryAll('#sortable-list li');
  
  new Sortable(items)
    ..onSortableComplete.listen((SortableResult result) {
      // do something when user sorted the elements...
    });
}

sectionSortableGrid() {
  var items = queryAll('#sortable-grid li');
  
  new Sortable(items);
}

sectionSortableListExclude() {
  var items = queryAll('#sortable-list-exclude li:not(.disabled)');
  
  new Sortable(items);
}

sectionSortableListHandles() {
  var items = queryAll('#sortable-list-handles li');
  
  new Sortable(items, handle: 'span');
}

sectionSortableListConnected() {
  var items = queryAll('#sortable-list-connected li');
  
  new Sortable(items);
}