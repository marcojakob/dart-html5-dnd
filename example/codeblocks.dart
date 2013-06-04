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
Element dragElement = query('#dragging-divs .dragme');
new Draggable(dragElement);

var dropElement = query('#dragging-divs .dropzone');
new Dropzone(dropElement)
  ..acceptDraggables.add(dragElement);
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
Element dragme = query('#nested-elements .dragme');
Element dropzone = query('#nested-elements .dropzone');
TextAreaElement textarea = query('#nested-elements .dropzone textarea');
InputElement input = query('#nested-elements .dropzone input');
input.value = 'Drag here!';

new Draggable(dragme);

int enterLeaveCounter = 1;
int overCounter = 1;
new Dropzone(dropzone)
  ..acceptDraggables.add(dragme)
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
var items = queryAll('#sortable-list li');

new Sortable(items)
  ..onSortableComplete.listen((SortableResult result) {
    // do something when user sorted the elements...
  });
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
var items = queryAll('#sortable-grid li');

new Sortable(items);
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
var items = queryAll('#sortable-list-exclude li:not(.disabled)');

new Sortable(items);
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
var items = queryAll('#sortable-list-handles li');

new Sortable(items, handle: 'span');
  ''');
}

codeblockSortableListConnected(Element section) {
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
#sortable-list-connected .dnd-placeholder {
  border: 1px dashed #CCC;
  background: none;  
}

#sortable-list-connected {
  overflow: hidden;
}

#sortable-list-connected li {
  cursor: move;
}

#sortable-list-connected .list1 {
  float: left;
  width: 150px;
}

#sortable-list-connected .list2 {
  float: right;
  width: 150px;
}
      ''', 
      // Dart
      '''
var items = queryAll('#sortable-list-connected li');

new Sortable(items);
  ''');
}