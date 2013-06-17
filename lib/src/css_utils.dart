/// Some CSS helper functions.
library html5_dnd.css_utils;

import 'dart:html';

/**
 * Get the left offset of [element] relative to the document.
 */
num getLeftOffset(Element element) {
  return element.getBoundingClientRect().left + window.pageXOffset 
      - document.documentElement.client.left;
}

/**
 * Get the top offset of [element] relative to the document.
 */
num getTopOffset(Element element) {
  return element.getBoundingClientRect().top + window.pageYOffset 
      - document.documentElement.client.top;
}

int getAbsoluteLeft(Element element) {
  int absoluteLeft = element.offsetLeft;
  while (element.offsetParent != null) {
    element = element.offsetParent;
    absoluteLeft += element.offsetLeft - element.scrollLeft;
  }
  return absoluteLeft;
}

int getAbsoluteTop(Element element) {
  int absoluteTop = element.offsetTop;
  while (element.offsetParent != null) {
    element = element.offsetParent;
    absoluteTop += element.offsetTop - element.scrollTop;
  }
  return absoluteTop;
}

Point getMousePosition(MouseEvent event) {
  num x = 0;
  num y = 0;
  if (event.page.x != 0 || event.page.y != 0) {
    x = event.page.x;
    y = event.page.y;
  } else if (event.client.x != 0 || event.client.y != 0) {
    x = event.client.x + document.body.scrollLeft + document.documentElement.scrollLeft;
    y = event.client.y + document.body.scrollTop + document.documentElement.scrollTop;
  }
  
  return new Point(x.round(), y.round());
}