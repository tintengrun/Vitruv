package tools.vitruv.framework.change.description.impl

import java.util.ArrayList
import java.util.Collections
import java.util.Iterator
import java.util.List
import java.util.Set
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.InternalEObject
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.emf.ecore.util.EcoreUtil
import tools.vitruv.framework.change.description.TransactionalChange
import tools.vitruv.framework.change.echange.EChange
import tools.vitruv.framework.change.echange.eobject.CreateEObject
import tools.vitruv.framework.change.echange.eobject.DeleteEObject
import tools.vitruv.framework.change.echange.eobject.EObjectAddedEChange
import tools.vitruv.framework.change.echange.eobject.EObjectExistenceEChange
import tools.vitruv.framework.change.echange.eobject.EObjectSubtractedEChange
import tools.vitruv.framework.change.echange.feature.FeatureEChange
import tools.vitruv.framework.change.echange.feature.UnsetFeature
import tools.vitruv.framework.change.echange.feature.attribute.InsertEAttributeValue
import tools.vitruv.framework.change.echange.feature.attribute.RemoveEAttributeValue
import tools.vitruv.framework.change.echange.feature.attribute.ReplaceSingleValuedEAttribute
import tools.vitruv.framework.change.echange.feature.attribute.UpdateAttributeEChange
import tools.vitruv.framework.change.echange.feature.reference.AdditiveReferenceEChange
import tools.vitruv.framework.change.echange.feature.reference.InsertEReference
import tools.vitruv.framework.change.echange.feature.reference.RemoveEReference
import tools.vitruv.framework.change.echange.feature.reference.ReplaceSingleValuedEReference
import tools.vitruv.framework.change.echange.feature.reference.SubtractiveReferenceEChange
import tools.vitruv.framework.change.echange.id.IdResolver
import tools.vitruv.framework.change.echange.root.InsertRootEObject
import tools.vitruv.framework.change.echange.root.RemoveRootEObject
import tools.vitruv.framework.change.echange.root.RootEChange
import tools.vitruv.framework.change.interaction.UserInteractionBase

import static com.google.common.base.Preconditions.checkNotNull

import static extension edu.kit.ipd.sdq.commons.util.java.lang.IterableUtil.mapFixed
import static extension tools.vitruv.framework.change.echange.resolve.EChangeResolverAndApplicator.*

class TransactionalChangeImpl implements TransactionalChange {
	var List<? extends EChange> eChanges
	val List<UserInteractionBase> userInteractions = new ArrayList()

	new(Iterable<? extends EChange> eChanges) {
		this.eChanges = checkNotNull(eChanges, "eChanges").toList
	}
	
	override getEChanges() {
		return Collections.unmodifiableList(eChanges)
	}

	override containsConcreteChange() {
		return !eChanges.empty
	}
	
	private static def getChangedURI(EChange eChange) {
		switch(eChange) {
			FeatureEChange<?, ?>: eChange.affectedEObject?.objectUri
			EObjectExistenceEChange<?>: eChange.affectedEObject?.objectUri
			RootEChange: URI.createURI(eChange.uri)
		}
	}
	
	override getChangedURIs() {
		eChanges.map[changedURI].filterNull.toSet
	}

	override resolveAndApply(ResourceSet resourceSet) {
		//val idResolver = IdResolver.create(resourceSet)
		val idResolver = IdResolver.get(resourceSet)
		
		val resolvedChanges = new ArrayList<EChange>()
		var numChangesBefore = Integer.MAX_VALUE
		val remainingChanges = new ArrayList<EChange>(eChanges)
		while (numChangesBefore > remainingChanges.size) {
			System.out.println("NEW BATCH: " + numChangesBefore + " / " + remainingChanges.size)
			numChangesBefore = remainingChanges.size
			val changeIt = remainingChanges.iterator
			while (changeIt.hasNext) {
				val eChange = changeIt.next
				
//				var resolved = false
//				val resolvedChange = 
				try {
					val resolvedChange = eChange.resolveBefore(idResolver)
//					resolved = true
					resolvedChange.applyForward(idResolver)
					resolvedChanges.add(resolvedChange)
					changeIt.remove
//					resolvedChange
				} catch (Exception e) {
					// ignore
					//System.out.println(e.message)
					e.printStackTrace
//					null
				}
//				if (resolved) {
//					resolvedChange.applyForward(idResolver)
//					resolvedChanges.add(resolvedChange)
//					changeIt.remove
//				}
			}
		}
		if (!remainingChanges.isEmpty) {
			//throw new IllegalStateException("Not all changes could be resolved and applied! Remaining: " + remainingChanges.size)
			// NOTE: instead of throwing an exception we issue warnings so that we can deal with temporary inconsistencies (i.e., conflicting deltas) in views due to, e.g., not yet known/fixed feature interactions.
			System.out.println("WARNING: The following " + remainingChanges.size + " changes could not be resolved and were not applied!")
			for (EChange change : remainingChanges) {
				System.out.println("CHANGE: " + change)
			}
		}
		return new TransactionalChangeImpl(resolvedChanges)
		
//		val resolvedChanges = eChanges.mapFixed[
//			val resolvedChange = resolveBefore(idResolver)
//			resolvedChange.applyForward(idResolver)
//			resolvedChange
//		]
//		return new TransactionalChangeImpl(resolvedChanges)
	}

	override unresolve() {
		val unresolvedChanges = EChanges.mapFixed[it.unresolve()]
		return new TransactionalChangeImpl(unresolvedChanges)
	}
	
	override getAffectedEObjects() {
		eChanges.flatMap[it.affectedEObjects].toSet
	}
	
	override getAffectedAndReferencedEObjects() {
		eChanges.flatMap[it.affectedAndReferencedEObjects].toSet
	}

	private static def getAffectedEObjects(EChange eChange) {
		switch (eChange) {
			FeatureEChange<?, ?>: Set.of(eChange.affectedEObject)
			EObjectExistenceEChange<?>: Set.of(eChange.affectedEObject)
			InsertRootEObject<?>: Set.of(eChange.newValue)
			RemoveRootEObject<?>: Set.of(eChange.oldValue)
		}
	}
	
	private static def getAffectedAndReferencedEObjects(EChange eChange) {
		switch (eChange) {
			UpdateAttributeEChange<?>: Set.of(eChange.affectedEObject)
			ReplaceSingleValuedEReference<?, ?>:
				setOfNotNull(eChange.affectedEObject, eChange.oldValue, eChange.newValue)
			InsertEReference<?, ?>: Set.of(eChange.affectedEObject, eChange.newValue)
			RemoveEReference<?, ?>: Set.of(eChange.affectedEObject, eChange.oldValue)
			EObjectExistenceEChange<?>: Set.of(eChange.affectedEObject)
			InsertRootEObject<?>: Set.of(eChange.newValue)
			RemoveRootEObject<?>: Set.of(eChange.oldValue)
		}
	}
	
	override getUserInteractions() {
		return userInteractions
	}

	override setUserInteractions(Iterable<UserInteractionBase> userInteractions) {
		checkNotNull(userInteractions, "Interactions must not be null")
		this.userInteractions.clear()
		this.userInteractions += userInteractions
	}
	
	def protected getClonedEChanges() {
		eChanges.mapFixed[EcoreUtil.copy(it)]
	}
		
	override TransactionalChangeImpl copy() {
		new TransactionalChangeImpl(clonedEChanges)
	}

	override equals(Object obj) {
		if (obj === this) true
		else if (obj === null) false
		else if (obj instanceof TransactionalChange) {
			eChanges == obj.EChanges
		} 
		else false
	}
	
	override hashCode() {
		eChanges.hashCode()
	}

	private static def getObjectUri(EObject object) {
		val objectResource = object.eResource
		if (objectResource !== null) {
			objectResource.URI
		} else if (object.eIsProxy) {
			// being an InternalEObject is effectively enforced by EMF, so the cast is fine
			val proxyURI = (object as InternalEObject).eProxyURI
			if (proxyURI !== null && proxyURI.segmentCount > 0) {
				proxyURI.trimFragment // remove fragment to get resource URI
			} else null
		} else null
	}
	
	def private static <T> Set<T> setOfNotNull(T element) {
		element !== null ? Set.of(element) : emptySet
	}
	
	def private static <T> Set<T> setOfNotNull(T element1, T element2) {
		if (element1 === null) setOfNotNull(element2)
		else if (element2 === null) Set.of(element1)
		else Set.of(element1, element2)
	}
	
	def private static <T> Set<T> setOfNotNull(T element1, T element2, T element3) {
		if (element1 === null) setOfNotNull(element2, element3)
		else if (element2 === null) setOfNotNull(element1, element3)
		else if (element3 === null) Set.of(element1, element2)
		else Set.of(element1, element2, element3)
	}

    override String toString() {
    	if (eChanges.isEmpty) '''«class.simpleName» (empty)'''
		else '''
			«class.simpleName»: [
				«FOR eChange : eChanges»
					«eChange.stringRepresetation»
				«ENDFOR»
			]
			'''
    }
    
    private def getStringRepresetation(EChange change) {
    	switch (change) {
    		InsertRootEObject<?>: '''insert «change.newValueString» at «change.uri» (index «change.index»)'''
    		RemoveRootEObject<?>: '''remove «change.oldValueString» from «change.uri» (index «change.index»)'''
    		CreateEObject<?>: '''create «change.affectedObjectString»'''
    		DeleteEObject<?>: '''delete «change.affectedObjectString»'''
    		UnsetFeature<?, ?>: '''«change.affectedFeatureString» = «'\u2205' /* empty set */»'''
    		ReplaceSingleValuedEAttribute<?, ?>:
    			'''«change.affectedFeatureString» = «change.newValue» (was «change.oldValue»)'''
    		ReplaceSingleValuedEReference<?, ?>: 
    			'''«change.affectedFeatureString» = «change.newValueString» (was «change.oldValueString»)'''
    		InsertEAttributeValue<?, ?>:
	    		'''«change.affectedFeatureString» += «change.newValue» (index «change.index»)'''
	    	InsertEReference<?, ?>:
	    		'''«change.affectedFeatureString» += «change.newValueString» (index «change.index»)'''
	    	RemoveEAttributeValue<?, ?>:
		    	'''«change.affectedFeatureString» -= «change.oldValue» (index «change.index»)'''
		    RemoveEReference<?, ?>:
		    	'''«change.affectedFeatureString» -= «change.oldValueString» (index «change.index»)'''
    	}
    }
    
	def private getNewValueString(EObjectAddedEChange<?> change) {
		formatValueString(change.newValue, change.newValueID)
	}
	
	def private getOldValueString(EObjectSubtractedEChange<?> change) {
		formatValueString(change.oldValue, change.oldValueID)
	}
	
	def private getAffectedObjectString(EObjectExistenceEChange<?> change) {
		formatValueString(change.affectedEObject, change.affectedEObjectID)
	}
	
	def private getAffectedObjectString(FeatureEChange<?, ?> change) {
		formatValueString(change.affectedEObject, change.affectedEObjectID)
	}
	
	def private getAffectedFeatureString(FeatureEChange<?, ?> change) {
		'''«change.affectedObjectString».«change.affectedFeature.name»'''
	}
	
	def private newValueString(AdditiveReferenceEChange<?, ?> change) {
		formatValueString(change.newValue, change.newValueID)
	}
	
	def private oldValueString(SubtractiveReferenceEChange<?, ?> change) {
		formatValueString(change.oldValue, change.oldValueID)
	}
	
	def private formatValueString(Object value, String id) {
		if (value !== null) {
			'''«value» (id=«id»)'''
		} else {
			'''id=«id»'''
		}
	}

}