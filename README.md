HTML5 Drag and Drop for Dart
================

Helper library to simplify **Native HTML5 Drag and Drop** in Dart.

## Features ##
* Make any HTML Element `Draggable`.
* Create `Dropzone`s and connect them with `Draggable`s.
* Sortable (similar to jQuery UI Sortable).
* Uses fast native HTML5 Drag and Drop of the browser.
* Same functionality and API for IE9+, Firefox, Chrome. (Safari and Opera have 
  not been tested yet, let me know if it works). 

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

### 2. Add Polyfill JavaScript ###
To make HTML5 Drag and Drop work in Internet Explorer include the following 
JavaScript file inside the `<head>` of your application's HTML like so:
```html
<script type="text/javascript" src="packages/html5_dnd/dnd.polyfill.js"></script>
```

### 3. Import ###
Import the `html5_dnd` library in your Dart code. If your using the Sortable 
functionality, also 
add `html5_sortable`.

```dart
import 'package:html5_dnd/html5_dnd.dart';
import 'package:html5_dnd/html5_sortable.dart';

// ...
```

### 4. Use it ###
See the demo page above or the `example` directory to see how to use it. There 
are also plenty of Dart Doc comments in the code for some additional details.


## Thanks and Contributions ##
I'd like to thank the people who kindly helped me with their answers or put 
some tutorial or code examples online. They've already contributed to this 
project.

If you'd like to contribute, you're welcome to file issues or 
[fork](https://help.github.com/articles/fork-a-repo) my 
[repository on GitHub](https://github.com/marcojakob/dart-html5-dnd).


## License ##
The MIT License (MIT)