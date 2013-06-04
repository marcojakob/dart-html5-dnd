/*
 * Workaround to enable dragging elements other than links and images in
 * Internet Explorer 9.
 * May be called from dart passing a dart Element.
 */
function callDragDrop(el) {
  el.dragDrop();
}

/*
 * Detects whether the browser supports the "setDragImage" function of HTML5
 * Drag and Drop.
 */
function supportsSetDragImage() {
  var testVar = window.DataTransfer || window.Clipboard;  // Clipboard is for Chrome
  return "setDragImage" in testVar.prototype;
}

/*
 * Detects Internet Explorer (including IE10).
 */
function isInternetExplorer() {
  return /*@cc_on!@*/!1;  // [Boolean]
}