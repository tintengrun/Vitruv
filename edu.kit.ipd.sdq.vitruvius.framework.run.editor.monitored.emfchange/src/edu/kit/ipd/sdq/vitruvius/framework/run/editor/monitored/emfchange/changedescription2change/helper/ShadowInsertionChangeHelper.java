package edu.kit.ipd.sdq.vitruvius.framework.run.editor.monitored.emfchange.changedescription2change.helper;

import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

import org.apache.log4j.Logger;
import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.eclipse.emf.ecore.EStructuralFeature;

import edu.kit.ipd.sdq.vitruvius.framework.meta.change.EChange;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.attribute.AttributeFactory;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.attribute.UpdateSingleValuedEAttribute;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.reference.InsertNonContainmentEReference;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.reference.ReferenceFactory;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.reference.UpdateSingleValuedNonContainmentEReference;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.reference.containment.ContainmentFactory;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.reference.containment.CreateNonRootEObjectInList;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.reference.containment.CreateNonRootEObjectSingle;
import edu.kit.ipd.sdq.vitruvius.framework.run.editor.monitored.emfchange.tools.MapUtils;

/**
 * {@link ShadowInsertionChangeHelper} determines whether a given object has been inserted with
 * changes preceding the insertion, i.e. shadowed changes, and is able to create the {@link EChange}
 * objects corresponding to the shadowed changes.
 */
public final class ShadowInsertionChangeHelper {
    private static final Logger LOGGER = Logger.getLogger(ShadowInsertionChangeHelper.class);

    private Map<EObject, List<EChange>> containmentChangesCollector;
    private Map<EObject, List<EChange>> nonContainmentChangesCollector;
    private Collection<EObject> attachedObjectsCollector;

    /**
     * Sets the map into which the resulting containment-related changes are stored.
     * 
     * @param collector
     *            The containment-related result collecting map.
     */
    public void setContainmentChangeCollector(Map<EObject, List<EChange>> collector) {
        containmentChangesCollector = collector;
    }

    /**
     * Sets the map into which the resulting non-containment-related changes are stored.
     * 
     * @param collector
     *            The non-containment-related result collecting map.
     */
    public void setNonContainmentChangeCollector(Map<EObject, List<EChange>> collector) {
        nonContainmentChangesCollector = collector;
    }

    /**
     * Sets the collection into which the newly found attached objects are stored.
     * 
     * @param collector
     *            The list into which the newly found attached objects are stored.
     */
    public void setAttachedObjectCollector(Collection<EObject> collector) {
        attachedObjectsCollector = collector;
    }

    /**
     * @param eObject
     *            An {@link EObject}.
     * @return <code>true</code> iff the object has any set (i.e., non-null rsp. non-empty)
     *         attributes or references.
     */
    public static boolean isShadowInsertionObject(EObject eObject) {
        boolean adviseShadowResolution = false;
        for (EReference ref : eObject.eClass().getEAllReferences()) {
            if (isRelevantFeature(ref, eObject)) {
                adviseShadowResolution |= hasNondefaultValue(ref, eObject);
            }
        }

        for (EAttribute attr : eObject.eClass().getEAllAttributes()) {
            if (isRelevantFeature(attr, eObject)) {
                adviseShadowResolution |= hasNondefaultValue(attr, eObject);
            }
        }

        return adviseShadowResolution;
    }

    private static boolean isRelevantFeature(EStructuralFeature feature, EObject affectedObject) {
        return !feature.isDerived() && !feature.isTransient() && feature.isChangeable()
                && feature != affectedObject.eContainingFeature();
    }

    private static boolean hasNondefaultValue(EReference ref, EObject affectedObject) {
        if (ref.isMany()) {
            EList<?> refList = (EList<?>) affectedObject.eGet(ref);
            if (refList != null && !refList.isEmpty()) {
                LOGGER.trace("\tAdvising shadow resolution for " + affectedObject + " due to reference "
                        + ref.getName() + " containing " + refList);
                return true;
            }
        } else if (affectedObject.eGet(ref) != ref.getDefaultValue()) {
            LOGGER.trace("\tAdvising shadow resolution for " + affectedObject + " due to reference " + ref.getName()
                    + " containing " + affectedObject + " in " + affectedObject.eContainer());
            return true;
        }
        return false;
    }

    private static boolean hasNondefaultValue(EAttribute attr, EObject affectedObject) {
        if (affectedObject.eGet(attr) != attr.getDefaultValue()) {
            Object attrObj = affectedObject.eGet(attr);
            LOGGER.trace("\tAdvising shadow resolution for " + affectedObject + " due to attribute " + attr.getName()
                    + " pointing to " + attrObj);
            return true;
        } else {
            return false;
        }
    }

    /**
     * Recursively adds {@link EChange} objects representing shadowed changes in
     * <code>createdObject</code>.
     * 
     * @param createdObject
     *            The object carrying shadowed changes.
     */
    public void addShadowResolvingChanges(EObject createdObject) {
        addReferenceChanges(createdObject);
        addAttributeChanges(createdObject);
    }

    private static void insertCreateChange(EObject createdObject, EObject referencedObj, EReference ref,
            Map<EObject, List<EChange>> target) {
        CreateNonRootEObjectSingle<EObject> update = ContainmentFactory.eINSTANCE.createCreateNonRootEObjectSingle();
        InitializeEChange.setupUpdateEReference(update, createdObject, ref);
        InitializeEChange.setupCreateNonRootEObjectSingle(update, referencedObj);
        MapUtils.addToMap(createdObject, update, target);
    }

    private static void insertCreateChange(EObject createdObject, EObject referencedObj, EReference ref,
            Map<EObject, List<EChange>> target, int index) {
        LOGGER.trace("\tAdding create change for reference " + ref.getName() + " containing " + referencedObj + " in "
                + referencedObj.eContainer());
        CreateNonRootEObjectInList<EObject> update = ContainmentFactory.eINSTANCE.createCreateNonRootEObjectInList();
        InitializeEChange.setupUpdateEReference(update, createdObject, ref);
        InitializeEChange.setupInsertInEList(update, referencedObj, index);
        MapUtils.addToMap(createdObject, update, target);
    }

    private static void insertUpdateEReferenceChange(EObject createdObject, EObject referencedObj, EReference ref,
            Map<EObject, List<EChange>> target) {
        LOGGER.trace("\tAdding update reference " + ref.getName() + " containing " + referencedObj);

        UpdateSingleValuedNonContainmentEReference<EObject> update = ReferenceFactory.eINSTANCE
                .createUpdateSingleValuedNonContainmentEReference();
        InitializeEChange.setupUpdateEReference(update, createdObject, ref);
        // TODO (Maybe): EChange object set up with an explicit null reference.
        InitializeEChange.setupUpdateSingleValuedNonContainmentEReference(update, null, referencedObj);

        MapUtils.addToMap(createdObject, update, target);
    }

    private static void insertListAddChange(EObject createdObject, EObject referencedObj, EReference ref,
            Map<EObject, List<EChange>> target, int index) {
        LOGGER.trace("\tAdding list add in reference " + ref.getName() + " containing " + referencedObj);

        InsertNonContainmentEReference<EObject> update = ReferenceFactory.eINSTANCE
                .createInsertNonContainmentEReference();
        InitializeEChange.setupUpdateEReference(update, createdObject, ref);
        InitializeEChange.setupInsertInEList(update, referencedObj, index);
        MapUtils.addToMap(createdObject, update, target);
    }

    private static void insertUpdateEAttributeChange(EObject createdObject, Object attributeObj, EAttribute attr,
            Map<EObject, List<EChange>> target) {
        LOGGER.trace("\tAdding attribute change in " + attr.getName() + " to " + attributeObj);

        UpdateSingleValuedEAttribute<Object> update = AttributeFactory.eINSTANCE.createUpdateSingleValuedEAttribute();
        InitializeEChange.setupUpdateEAttribute(update, createdObject, attr);
        // TODO (Maybe): EChange object set up with an explicit null reference.
        InitializeEChange.setupUpdateSingleValuedEAttribute(update, null, attributeObj);

        MapUtils.addToMap(createdObject, update, target);
    }

    private void addAttributeChanges(EObject createdObject) {
        LOGGER.trace("Adding attribute changes for: " + createdObject);

        for (EAttribute attribute : createdObject.eClass().getEAllAttributes()) {
            if (isRelevantFeature(attribute, createdObject) && hasNondefaultValue(attribute, createdObject)) {
                insertUpdateEAttributeChange(createdObject, createdObject.eGet(attribute), attribute,
                        nonContainmentChangesCollector);
            }
        }
    }

    private void addReferenceChanges(EObject createdObject) {
        LOGGER.trace("Adding reference changes for: " + createdObject);

        for (EReference ref : createdObject.eClass().getEAllReferences()) {
            addReferenceChange(ref, createdObject);
        }
    }

    private void addReferenceChange(EReference ref, EObject affectedObject) {
        if (isRelevantFeature(ref, affectedObject) && hasNondefaultValue(ref, affectedObject)) {
            if (ref.isMany()) {
                addReferenceChangeForMultiplicityMany(ref, affectedObject);
            } else {
                addReferenceChangeForMultiplicityOne(ref, affectedObject);
            }
        }
    }

    private void addReferenceChangeForMultiplicityMany(EReference ref, EObject affectedObject) {
        Map<EObject, List<EChange>> target = ref.isContainment() ? containmentChangesCollector
                : nonContainmentChangesCollector;

        EList<?> refList = (EList<?>) affectedObject.eGet(ref);
        Iterator<?> refListIt = refList.iterator();

        for (int i = 0; refListIt.hasNext(); i++) {
            EObject referencedObj = (EObject) refListIt.next();

            if (ref.isContainment()) {
                insertCreateChange(affectedObject, referencedObj, ref, target, i);
                addShadowResolvingChanges(referencedObj);
                attachedObjectsCollector.add(referencedObj);
            } else {
                insertListAddChange(affectedObject, referencedObj, ref, target, i);
            }
        }
    }

    private void addReferenceChangeForMultiplicityOne(EReference ref, EObject affectedObject) {
        Map<EObject, List<EChange>> target = ref.isContainment() ? containmentChangesCollector
                : nonContainmentChangesCollector;
        EObject referencedObj = (EObject) affectedObject.eGet(ref);

        if (ref.isContainment()) {
            insertCreateChange(affectedObject, referencedObj, ref, target);
            addShadowResolvingChanges(referencedObj);
        } else {
            insertUpdateEReferenceChange(affectedObject, referencedObj, ref, target);
        }
    }
}
