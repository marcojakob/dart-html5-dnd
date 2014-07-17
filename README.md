# HTML5 Drag and Drop for Dart

***

## Note: This library is not maintained any more.

* Use the [Dart drag and drop](http://code.makery.ch/library/dart-drag-and-drop/) library instead (better, without HTML5).
* Read the details about why I chose [Drag and Drop without HTML5](http://code.makery.ch/blog/drag-and-drop-without-html5/)

***


## Deprecated stuff...


## Features

* Make any HTML Element `draggable`.
* Create `dropzones` and connect them with `draggables`.
* Rearrange elements with `sortables` (similar to jQuery UI Sortable).
* Support for `touch events` on touch screen devices.
* Same functionality and API for IE9+, Firefox, Chrome and Safari.
* Uses fast native HTML5 Drag and Drop of the browser whenever possible.
* For browsers that do not support some features, the behaviour is emulated.
  This is the case for IE9 and partly for IE10 (when custom drag images are 
  used).


## Usage

See the demo page above or the `example` directory to see some live examples 
with code.

In general, to make drag and drop work, we will have to do two things:

1. Create draggables by installing HTML elements in a `DraggableGroup`.
2. Create dropzones by installing HTML elements in a `DropzoneGroup`.

To make elements sortable it's even easier: Create sortables by installing HTML
elements in a `SortableGroup`. The `SortableGroup` will make the installed 
elements both into draggables and dropzones and thus creates sortable behaviour.


### Disable Touch Support

There is a global property called `enableTouchEvents` which is `true` by 
default. This means that touch events are automatically enabled on devices that 
support it. If touch support should not be used even on touch devices, set this 
flag to `false`. 


### Draggables

Any HTML element can be made draggable. First we'll have to create a 
`DraggableGroup` that manages draggable elements. The `DraggableGroup` holds
all options for dragging and provides event streams we can listen to.

This is how a `DraggableGroup` is created. With `install(...)` or 
`installAll(...)` elements are made draggable and registered in the group.

```dart
// Creating a DraggableGroup and installing some elements.
DraggableGroup dragGroup = new DraggableGroup();
dragGroup.installAll(queryAll('.my-draggables'));
```

With `uninstall(...)` or `uninstallAll(...)` draggables can be removed from 
the group and the draggable behaviour is uninstalled.


#### Draggable Options

The `DraggableGroup` has three constructor options:

* The `dragImageFunction` is used to provide a custom `DragImage`. If no 
  `dragImageFunction` is supplied, the drag image is created from the HTML 
  element of the draggable.
* If a `handle` is provided, it is used as query String to find subelements of 
  draggable elements. The drag is then restricted to those elements.
* If `cancel` is provided, it is used as query String to find a subelement of 
  drabbable elements. The drag is then prevented on those elements.
  The default is 'input,textarea,button,select,option'.

```dart
// Create a custom drag image from a png.
ImageElement png = new ImageElement(src: 'icons/smiley-happy.png');
DragImage img = new DragImage(png, 0, 0);

// Always return the same DragImage here. We could also create a different image 
// for each draggable.
DragImageFunction imageFunction = (Element draggable) {
  return img;
};

// Create DraggableGroup with custom drag image and a handle.
DraggableGroup dragGroupHandle = new DraggableGroup(
    dragImageFunction: imageFunction, handle: '.my-handle');
    
// Create DraggableGroup with a cancel query String.
DraggableGroup dragGroupCancel = new DraggableGroup(
    cancel: 'textarea, button, .no-drag');
```

Other options of the `DraggableGroup`:

```dart
DraggableGroup dragGroup = new DraggableGroup();

// CSS class set to html body during drag.
dragGroup.dragOccurringClass = 'dnd-drag-occurring';

// CSS class set to the draggable element during drag.
dragGroup.draggingClass = 'dnd-dragging';

// CSS class set to the dropzone when a draggable is dragged over it.
dragGroup.overClass = 'dnd-over';

// Changes mouse cursor when this draggable is dragged over a draggable.
dragGroup.dropEffect = DROP_EFFECT_COPY; 
```

#### Draggable Events

We can listen to `dragStart`, `drag`, and `dragEnd` events of a 
`DraggableGroup`.

```dart 
DraggableGroup dragGroup = new DraggableGroup();

dragGroup.onDragStart.listen((DraggableEvent event) => print('drag started'));
dragGroup.onDrag.listen((DraggableEvent event) => print('dragging'));
dragGroup.onDragEnd.listen((DraggableEvent event) => print('drag ended'));
```


### Dropzones

Any HTML element can be made to a dropzone. Similar to how draggables are 
created, we create a dropzones:

```dart
// Creating a DropzoneGroup and installing some elements.
DropzoneGroup dropGroup = new DropzoneGroup();
dropGroup.installAll(queryAll('.my-dropzones'));
```

#### Dropzone Options

The `DropzoneGroup` has an option to specify which `DraggableGroup`s it accepts.
If no accept group is specified, the `DropzoneGroup` will accept all draggables.

```dart
DraggableGroup dragGroup = new DraggableGroup();
// ... install some draggable elements ...

DropzoneGroup dropGroup = new DropzoneGroup();
// ... install some dropzone elements ...

// Make dropGroup only accept draggables from dragGroup.
dropGroup.accept.add(dragGroup);
```

#### Dropzone Events

We can listen to `dragEnter`, `dragOver`, `dragLeave`, and `drop` events of a 
`DropzoneGroup`.

```dart 
DropzoneGroup dropGroup = new DropzoneGroup();

dropGroup.onDragEnter.listen((DropzoneEvent event) => print('drag entered'));
dropGroup.onDragOver.listen((DropzoneEvent event) => print('dragging over'));
dropGroup.onDragLeave.listen((DropzoneEvent event) => print('drag left'));
dropGroup.onDrop.listen((DropzoneEvent event) => print('dropped inside'));
```


### Sortables

For reordering of HTML elements we can use sortables. 

```dart
// Creating a SortableGroup and installing some elements.
SortableGroup sortGroup = new SortableGroup();
sortGroup.installAll(queryAll('.my-sortables'));
```

Note: All sortables are at the same time draggables and dropzones. This means 
we can set all options of `DraggableGroup` and `DropzoneGroup` on sortables and
listen to all their events.


#### Sortable Options

In addition to the inherited `DraggableGroup` and `DropzoneGroup` options, 
`SortableGroup` has the following options:

```dart
SortableGroup sortGroup = new SortableGroup();

// CSS class set to placeholder element. 
sortGroup.placeholderClass = 'dnd-placeholder';

// If true, forces the placeholder to have the computed size of the dragged element.
sortGroup.forcePlaceholderSize = true;

// Must be set to true for sortable grids. This ensures that different sized
// items in grids are handled correctly.
sortGroup.isGrid = false;
```

#### Sortable Events

Next to the inherited `DraggableGroup` and `DropzoneGroup` events 
`SortableGroup` has one additional event:

```dart 
SortableGroup sortGroup = new SortableGroup();

sortGroup.onSortUpdate.listen((SortableEvent event) => print('elements were sorted'));
```


## Thanks and Contributions

I'd like to thank the people who kindly helped me with their answers or put 
some tutorial or code examples online. They've indirectly contributed to this 
project.

If you'd like to contribute, you're welcome to report issues or 
[fork](https://help.github.com/articles/fork-a-repo) my 
[repository on GitHub](https://github.com/marcojakob/dart-html5-dnd).



## License

The MIT License (MIT)