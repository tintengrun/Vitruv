package edu.kit.ipd.sdq.vitruvius.dsls.response.tests.simpleChangesTests

import org.eclipse.emf.ecore.EObject

class SimpleChangesTestsUtils {
	static def findTypeInContainmentHierarchy(EObject startElement, Class<? extends EObject> searchedContainerType) {
		var EObject currentObject = startElement;
		while (!searchedContainerType.isInstance(currentObject) && currentObject != null) {
			currentObject = currentObject.eContainer();
		}
		return currentObject;
	}
}