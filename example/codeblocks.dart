part of html5_dnd_example;

_createCodeblock(Element section, String html, String css, 
                               String dart) {
  Element codeblock = new Element.html('<div class="example-code">');
  section.parentNode.insertBefore(codeblock, section.nextNode);
  
  Element menu = new Element.html('<ul class="menu">');
  codeblock.children.add(menu);
  
  Element menuLi = new Element.tag('li');
  menu.children.add(menuLi);
  menuLi.children.addAll([
           new Element.html('<a href="#" tab="html" class="active">HTML</a>'),
           new Element.html('<a href="#" tab="css">CSS</a>'),
           new Element.html('<a href="#" tab="dart">Dart</a>')]);

  Element content = new Element.html('<div class="content"></div>');
  codeblock.children.add(content);
  
  Element htmlElement = new Element.html('<div tab="html" class="active"></div>')
  ..children.add(new Element.tag('code')..text = html.trim());
  
  Element cssElement = new Element.html('<div tab="css"></div>')
  ..children.add(new Element.tag('code')..text = css.trim());
  
  Element dartElement = new Element.html('<div tab="dart"></div>')
  ..children.add(new Element.tag('code')..text = dart.trim());
  
  content.children.addAll([htmlElement, cssElement, dartElement]);
}

codeblockDraggableAndDropzone(Element section) {
  _createCodeblock(section, 
      // HTML
      '''
<div class="trash"></div>
<img class="document" src="icons/document.png">
<img class="document" src="icons/document.png">
<img class="document" src="icons/document.png">
<img class="document" src="icons/document.png">
      ''', 
      // CSS
      '''
#draggable-dropzone .trash {
  background: url(icons/trash.png) top left no-repeat;
  /* ... */
}

#draggable-dropzone .trash.full {
  background: url(icons/trash.png) top right no-repeat;
}

#draggable-dropzone .dnd-over {
  opacity: 1;
}

#draggable-dropzone .dnd-dragging {
  opacity: 0.5;
}
      ''', 
      // Dart
      '''
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
      ''');
}


codeblockDraggingDivs(Element section) {
  _createCodeblock(section, 
      // HTML
      '''
<div class="dragme">
  Drag me!  
</div>
<div class="dropzone example-box">
  Drag here!
</div>
      ''', 
      // CSS
      '''
#dragging-divs .dnd-dragging {
  opacity: 0.5;
}

#dragging-divs .dnd-over {
  background: #d387ca;
}
      ''', 
      // Dart
      '''
  // Install draggable.
DraggableGroup dragGroup = new DraggableGroup()
..installAll(queryAll('#dragging-divs .dragme'));

// Install dropzone.
DropzoneGroup dropGroup = new DropzoneGroup()
..install(query('#dragging-divs .dropzone'))
..accept.add(dragGroup);
  ''');
}


codeblockDropEffects(Element section) {
  _createCodeblock(section, 
      // HTML
      '''
<div class="trash"></div>
<a href="#" class="move">move</a>
<a href="#" class="copy">copy</a>
<a href="#" class="link">link</a>
<a href="#" class="none">none</a>
      ''', 
      // CSS
      '''
#drop-effects .trash {
  background: url(icons/trash.png) top left no-repeat;
  opacity: 0.7;
  /* ... */
}

#drop-effects .trash.full {
  background: url(icons/trash.png) top right no-repeat;
}

#drop-effects a {
  background: url(icons/document.png) no-repeat;
  /* ... */
}

#drop-effects .dnd-over {
  opacity: 1;
}

#drop-effects .dnd-dragging {
  opacity: 0.5;
}
      ''', 
      // Dart
      '''
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
  ''');
}

codeblockDragImages(Element section) {
  _createCodeblock(section, 
      // HTML
      '''
<div class="dropzone example-box">
  Drag here!
</div>
<div class="dragme one">
  png at position [40,40]
</div>
<div class="dragme two">
  png at position [-20,-20]
</div>
<div class="dragme three">
  custom drawn canvas
</div>
<div class="dragme four">
  Always uses Polyfill
</div>
      ''', 
      // CSS
      '''
#drag-images .dnd-dragging {
  opacity: 0.5;
}

#drag-images .dnd-over {
  background: #d387ca;
}
      ''', 
      // Dart
      '''
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
  ''');
}

codeblockNestedElements(Element section) {
  _createCodeblock(section, 
      // HTML
      '''
<div class="dragme">
  Drag me!  
</div>

<div class="dropzone example-box">
  <div>
    <input value="Drag here!"></input>
    <textarea rows="5"></textarea>
    <button>Button</button>
  </div>
</div>
      ''', 
      // CSS
      '''
#nested-elements .dnd-dragging {
  opacity: 0.5;
}

#nested-elements .dragme {
  width: 64px;
  height: 64px;
  /* ... */
}
      ''', 
      // Dart
      '''
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
  textarea.appendText('\${enterLeaveCounter++} drag enter fired\n');
  textarea.scrollTop = textarea.scrollHeight;
})
..onDragOver.listen((DropzoneEvent event) {
  input.value = '\${overCounter++} drag over fired';
})
..onDragLeave.listen((DropzoneEvent event) {
  textarea.appendText('\${enterLeaveCounter++} drag leave fired\n');
  textarea.scrollTop = textarea.scrollHeight;
})
..onDrop.listen((DropzoneEvent event) {
  textarea.appendText('\${enterLeaveCounter++} drop fired\n');
  textarea.scrollTop = textarea.scrollHeight;
});
  ''');
}

codeblockSortableList(Element section) {
  _createCodeblock(section, 
      // HTML
      '''
<ul class="example-box">
  <li>Item 1</li>
  <li>Item 2</li>
  <li>Item 3</li>
  <li class="higher">Item 4</li>
  <li>Item 5</li>
  <li class="higher">Item 6</li>
</ul>
      ''', 
      // CSS
      '''
#sortable-list .dnd-placeholder {
  border: 1px dashed #CCC;
  background: none;  
}

#sortable-list li {
  cursor: move;
}
      ''', 
      // Dart
      '''
SortableGroup sortGroup = new SortableGroup()
..installAll(queryAll('#sortable-list li'))
..onSortUpdate.listen((SortableEvent event) {
  // do something when user sorted the elements...
});

// Only accept elements from this section.
sortGroup.accept.add(sortGroup);
  ''');
}

codeblockSortableGrid(Element section) {
  _createCodeblock(section, 
      // HTML
      '''
<ul class="example-box grid">
  <li>Item 1</li>
  <li>Item 2</li>
  <li>Item 3</li>
  <li>Item 4</li>
  <li class="wider">Item 5</li>
  <li>Item 6</li>
  <li class="higher">Item 7</li>
  <li>Item 8</li>
</ul>
      ''', 
      // CSS
      '''
#sortable-grid .dnd-placeholder {
  border: 1px dashed #CCC;
  background: none;  
}

#sortable-grid li {
  cursor: move;
}
      ''', 
      // Dart
      '''
SortableGroup sortGroup = new SortableGroup()
..installAll(queryAll('#sortable-grid li'))
..isGrid = true;

// Only accept elements from this section.
sortGroup.accept.add(sortGroup);
  ''');
}

codeblockSortableListExclude(Element section) {
  _createCodeblock(section, 
      // HTML
      '''
<ul class="example-box">
  <li>Item 1</li>
  <li>Item 2</li>
  <li>Item 3</li>
  <li class="disabled">Item 4</li>
  <li class="disabled">Item 5</li>
  <li class="disabled">Item 6</li>
</ul>
      ''', 
      // CSS
      '''
#sortable-list-exclude .dnd-placeholder {
  border: 1px dashed #CCC;
  background: none;  
}

#sortable-list-exclude li:not(.disabled) {
  cursor: move;
}
      ''', 
      // Dart
      '''
SortableGroup sortGroup = new SortableGroup()
..installAll(queryAll('#sortable-list-exclude li:not(.disabled)'));

// Only accept elements from this section.
sortGroup.accept.add(sortGroup);
  ''');
}

codeblockSortableListHandles(Element section) {
  _createCodeblock(section, 
      // HTML
      '''
<ul class="example-box">
  <li><span>::</span> Item 1</li>
  <li><span>::</span> Item 2</li>
  <li><span>::</span> Item 3</li>
  <li><span>::</span> Item 4</li>
  <li><span>::</span> Item 5</li>
  <li><span>::</span> Item 6</li>
</ul>
      ''', 
      // CSS
      '''
#sortable-list-handles .dnd-placeholder {
  border: 1px dashed #CCC;
  background: none;  
}

#sortable-list-handles span {
  cursor: move;
}
      ''', 
      // Dart
      '''
SortableGroup sortGroup = new SortableGroup(handle: 'span')
..installAll(queryAll('#sortable-list-handles li'));

// Only accept elements from this section.
sortGroup.accept.add(sortGroup);
  ''');
}

codeblockSortableTwoGroups(Element section) {
  _createCodeblock(section, 
      // HTML
      '''
<ul class="example-box list1">
  <li>Item 1</li>
  <li>Item 2</li>
  <li>Item 3</li>
  <li>Item 4</li>
  <li>Item 5</li>
  <li>Item 6</li>
</ul>
<ul class="example-box list2">
  <li class="other">Item 1</li>
  <li class="other">Item 2</li>
  <li class="other">Item 3</li>
  <li class="other">Item 4</li>
  <li class="other">Item 5</li>
  <li class="other">Item 6</li>
</ul>
      ''', 
      // CSS
      '''
#sortable-two-groups .dnd-placeholder {
  border: 1px dashed #CCC;
  background: none;  
}

#sortable-two-groups .dnd-dragging {
  opacity: 0.5;
}

#sortable-two-groups li {
  cursor: move;
}

#sortable-two-groups .group1 {
  float: left;
  width: 150px;
}

#sortable-two-groups .group2 {
  float: right;
  width: 150px;
}
      ''', 
      // Dart
      '''
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
  ''');
}

codeblockDraggableSortable(Element section) {
  _createCodeblock(section, 
      // HTML
      '''
<ul class="example-box group1">
  <li>Item 1</li>
  <li>Item 2</li>
  <li>Item 3</li>
  <li>Item 4</li>
  <li>Item 5</li>
  <li>Item 6</li>
</ul>
<ul class="example-box group2">
  <li class="empty">Empty list!</li>
</ul>
      ''', 
      // CSS
      '''
#draggable-sortable {
  height: 250px;
}

#draggable-sortable .dnd-placeholder {
  border: 1px dashed #CCC;
  background: none;  
}

#draggable-sortable .dnd-dragging {
  opacity: 0.5;
}

#draggable-sortable .dnd-over {
  background: #d387ca;
}

#draggable-sortable .group1 li {
  cursor: move;
}

#draggable-sortable .group1 {
  float: left;
  width: 150px;
}

#draggable-sortable .group2 {
  float: right;
  width: 150px;
}

#draggable-sortable .group2 .empty {
  border: 1px dashed #CCC;
  color: #333;
}
      ''', 
      // Dart
      '''
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
  ''');
}