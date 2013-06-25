/**
 * Helper library for native HTML5 Drag and Drop. There are draggable elements 
 * that can be dropped inside dropzone elements. 
 */
library html5_dnd;

import 'dart:html';
import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;
import 'dart:svg' as svg;
import 'package:meta/meta.dart';
import 'package:logging/logging.dart';

import 'package:html5_dnd/src/css_utils.dart' as css;
import 'package:html5_dnd/src/html5_utils.dart' as html5;

part 'src/dnd/draggable.dart';
part 'src/dnd/draggable_emulated.dart';
part 'src/dnd/dropzone.dart';
part 'src/dnd/dropzone_emulated.dart';

final _logger = new Logger("html5_dnd");

/// Currently dragged element.
Element currentDraggable;

/// The [DraggableGroup] the [currentDraggable] belongs to.
DraggableGroup currentDraggableGroup;

/**
 * Abstract superclass for all groups containing drag and drop elements.
 */
abstract class Group {
  /// Map of all installed elements inside this group with their subscriptions.
  Map<Element, List<StreamSubscription>> installedElements = 
      new Map<Element, List<StreamSubscription>>();
  
  /**
   * Installs [element] and registers it in this group.
   */
  void install(Element element) {
    installedElements[element] = new List<StreamSubscription>();
  }
  
  /**
   * Installs all [elements] and registeres them in this group.
   */
  void installAll(List<Element> elements) {
    elements.forEach((Element e) => install(e));
  }
  
  /**
   * Uninstalls [element] and removes it from this group. All 
   * [StreamSubscription]s that were added with install are canceled.
   */
  void uninstall(Element element) {
    if (installedElements[element] != null) {
      installedElements[element].forEach((StreamSubscription s) => s.cancel());
      installedElements.remove(element);
    }
  }
  
  /**
   * Uninstalls all [elements] and removes them from this group. All 
   * [StreamSubscription]s that were added with install are canceled.
   */
  void uninstallAll(List<Element> elements) {
    elements.forEach((Element e) => uninstall(e));
  }
}