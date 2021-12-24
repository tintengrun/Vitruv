package tools.vitruv.framework.vsum.views.impl

import tools.vitruv.framework.vsum.views.selection.BasicViewSelector
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.util.EcoreUtil
import java.nio.file.Files
import java.nio.file.Path
import static extension com.google.common.base.Preconditions.checkNotNull
import static com.google.common.base.Preconditions.checkArgument
import tools.vitruv.framework.vsum.views.ChangeableViewSource
import tools.vitruv.framework.vsum.views.selection.impl.ViewSelectionImpl
import static extension edu.kit.ipd.sdq.commons.util.org.eclipse.emf.common.util.URIUtil.isPathmap

/**
 * A basic view type that allows creating views based on a basic element-wise selection mechanism.
 */
class BasicViewType extends AbstractViewType<BasicViewSelector> {

	new(String name) {
		super(name)
	}

	override createSelector(ChangeableViewSource viewSource) {
		return new BasicViewSelector(this, viewSource, viewSource.viewSourceModels.map[contents.head].filterNull.toList)
	}

	override createView(BasicViewSelector selector) {
		checkArgument(selector.viewType === this, "cannot create view with selector for different view type")
		return new BasicModelView(selector.viewType, selector.viewSource, new ViewSelectionImpl(selector))
	}

	override updateView(ModifiableView view) {
		view.modifyContents [ viewResourceSet |
			viewResourceSet.resources.forEach[unload]
			viewResourceSet.resources.clear
			val viewSources = view.viewSource.viewSourceModels
			for (var i = 0; i < viewSources.size; i++) {
				val resource = viewSources.get(i)
				if (view.selection.selectedElements.contains(resource.contents.head)) {
					if (resource.URI.fileExtension == "uml" && !resource.URI.isPathmap) {
						resource.copyUmlModel(viewResourceSet)
					} else {
						resource.copyModel(viewResourceSet)
					}
				}
			}
		]
	}

	/**
	 * NOTE: This is a hack, because {@link EcoreUtil#copyAll} does not work for UML models.
	 * This is due to the fact that the UML metamodel uses some weird manually and partly derived
	 * collections, which are not properly handled by the ordinary {@link EcoreUtil$Copier}.
	 * For example, the {@linkplain InterfaceRealization.clients} are a set of manually added
	 * elements combined with the {@linkplain InterfaceRealization.implementingClassifier}, which,
	 * in turn, is just the {@code eContainer} of the interface realization. The copier copies
	 * this implementing classifier reference although it is automatically inferred by the metamodel
	 * implementation, such that after the copy process the {@linkplain InterfaceRelization.clients}
	 * reference contains the according element twice. This happens at different places in the
	 * UML models.
	 * To circumvent the issue, we store the UML model to a temporary resource and reload it,
	 * because save/load properly handles the situation not covered by the copier. 
	 */
	// TODO HK Provide an appropriate temporary resource instead of the current magic file
	private def void copyUmlModel(Resource originalResource, ResourceSet newResourceSet) {
		val originalURI = originalResource.URI
		val tempURI = originalURI.trimFileExtension.appendSegment("save." + originalURI.fileExtension)
		originalResource.URI = tempURI
		originalResource.save(null)
		originalResource.URI = originalURI
		val viewResource = newResourceSet.getResource(tempURI, true)
		viewResource.URI = originalURI
		Files.delete(Path.of(org.eclipse.emf.common.util.URI.decode(tempURI.path)))
	}

	private def void copyModel(Resource originalResource, ResourceSet newResourceSet) {
		val viewResource = newResourceSet.resourceFactoryRegistry?.getFactory(originalResource.URI)?.createResource(
			originalResource.URI).checkNotNull('''Cannot create view resource: «originalResource.URI»''')
		viewResource.contents.addAll(EcoreUtil.copyAll(originalResource.contents))
		newResourceSet.resources += viewResource
	}

}
