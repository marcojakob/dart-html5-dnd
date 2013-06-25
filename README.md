HTML5 Drag and Drop for Dart
================

Helper library to simplify **HTML5 Drag and Drop** in Dart.

## Features ##
* Make any HTML Element `draggable`.
* Create `dropzone`s and connect them with `draggable`s.
* Rearrange elements with `sortable` (similar to jQuery UI Sortable).
* Same functionality and API for IE9+, Firefox, Chrome and Safari.
* Uses fast native HTML5 Drag and Drop of the browser whenever possible.
* For browsers that do not support some features, the behaviour is emulated.
  This is the case for IE9 and partly for IE10 (when custom drag images are 
  used).

## Demo ##
See [HTML5 Drag and Drop in action](http://edu.makery.ch/projects/dart-html5-drag-and-drop) (with code examples).

All examples are also available in the `example` directory on GitHub.

## Installation ##

### 1. Add Dependency ###
Add the folowing to your **pubspec.yaml** and run **pub install**
```yaml
	dependencies:
	  html5_dnd: any
```

### 2. Import ###
Import the `html5_dnd` library in your Dart code. If you're using the Sortable 
functionality, also add `html5_sortable`.

```dart
import 'package:html5_dnd/html5_dnd.dart';
import 'package:html5_dnd/html5_sortable.dart';

// ...
```

### 3. Use it ###
See the demo page above or the `example` directory to see how to use it. There 
are also plenty of comments in the code if you're interested in some finer 
details.


## Thanks and Contributions ##
I'd like to thank the people who kindly helped me with their answers or put 
some tutorial or code examples online. They've already contributed to this 
project.

If you'd like to contribute, you're welcome to report issues or 
[fork](https://help.github.com/articles/fork-a-repo) my 
[repository on GitHub](https://github.com/marcojakob/dart-html5-dnd).


## License ##
The MIT License (MIT)