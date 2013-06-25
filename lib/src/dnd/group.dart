part of html5_dnd;

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