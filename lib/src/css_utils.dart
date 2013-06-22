/// Some CSS helper functions.
library html5_dnd.css_utils;

import 'dart:html';

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