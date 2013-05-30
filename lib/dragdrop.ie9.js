/*
 * Workaround to enable drag-and-drop elements other than links and images in
 * Internet Explorer 9.
 * The callDragDrop() function can be called from dart passing a dart Element.
 */
function callDragDrop(el) {
  el.dragDrop();
}