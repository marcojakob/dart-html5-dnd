/// Some HTML5 helper functions.
library html5_dnd.utils;

import 'dart:html';
import 'package:logging/logging.dart';
import 'dart:svg' as svg;

final _logger = new Logger("html5_dnd.utils");

/**
 * Calculates the index of the Element [element] in its parent. If there is no
 * parent, null is returned.
 */
int getElementIndexInParent(Element element) {
  if (element.parent == null) {
    return null;
  }
  int index = 0;
  var previous = element.previousElementSibling;
  while (previous != null) {
    index++;
    previous = previous.previousElementSibling;
  }
  return index;
}

/**
 * Removes all text selections from the HTML document, including selections
 * in active textarea or active input element.
 */
void clearTextSelections() {
  window.getSelection().removeAllRanges();
  var activeElement = document.activeElement;
  if (activeElement is TextAreaElement) {
    activeElement.setSelectionRange(0, 0);
  } else if (activeElement is InputElement) {
    activeElement.setSelectionRange(0, 0);
  }
}

/**
 * The return value is true if [otherNode] is a descendant of [node], or [node] 
 * itself. Otherwise the return value is false.
 * 
 * Special handling of [SvgElement]s is needed because IE9 does not support
 * the [Node.contains] method on [SvgElement]s.
 */
bool contains(Node node, Node otherNode) {
  if (node is svg.SvgElement) {
    return _svgContains(node, otherNode);
  } else {
    return node.contains(otherNode);
  }
}

/**
 * Alternative to [Node.contains] for [SvgElement]s because IE9 does not support
 * [Node.contains] for [SvgElement]s.
 */
bool _svgContains(svg.SvgElement node, Node otherNode) {
  if (otherNode == node) {
    return true;
  } else {
    return node.children.any((e) => _svgContains(e, otherNode));
  }
}

/**
 * Get the offset of [element] relative to the document.
 */
Point pageOffset(Element element) {
  Rect rect = element.getBoundingClientRect();
  return new Point(
      rect.left + window.pageXOffset - document.documentElement.client.left, 
      rect.top + window.pageYOffset - document.documentElement.client.top);
}

/**
 * Returns the offset of [element] relative to the visible browser area.
 * 
 * Warning: Doesn't seem to return same result in all browsers.
 */
//Point clientOffset(Element element) {
//  int absoluteLeft = element.offsetLeft;
//  int absoluteTop = element.offsetTop;
//  while (element.offsetParent != null) {
//    element = element.offsetParent;
//    absoluteLeft += element.offsetLeft - element.scrollLeft;
//    absoluteTop += element.offsetTop - element.scrollTop;
//  }
//  return new Point(absoluteLeft, absoluteTop);
//}

