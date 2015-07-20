package edu.kit.ipd.sdq.vitruvius.framework.model.monitor.jamopputil;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EAttribute;
import org.eclipse.emf.ecore.EClass;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;
import org.emftext.language.java.classifiers.Class;
import org.emftext.language.java.classifiers.ConcreteClassifier;
import org.emftext.language.java.classifiers.Interface;
import org.emftext.language.java.commons.NamedElement;
import org.emftext.language.java.containers.CompilationUnit;
import org.emftext.language.java.containers.ContainersFactory;
import org.emftext.language.java.containers.Package;
import org.emftext.language.java.imports.Import;
import org.emftext.language.java.members.Field;
import org.emftext.language.java.members.Method;
import org.emftext.language.java.modifiers.Modifier;
import org.emftext.language.java.parameters.Parameter;
import org.emftext.language.java.types.TypeReference;
import org.emftext.language.java.types.TypedElement;

import edu.kit.ipd.sdq.vitruvius.framework.meta.change.EChange;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.attribute.AttributeFactory;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.attribute.UpdateSingleValuedEAttribute;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.reference.containment.ContainmentFactory;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.reference.containment.CreateNonRootEObjectInList;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.reference.containment.DeleteNonRootEObjectInList;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.feature.reference.containment.ReplaceNonRootEObjectSingle;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.object.CreateRootEObject;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.object.DeleteRootEObject;
import edu.kit.ipd.sdq.vitruvius.framework.meta.change.object.ObjectFactory;

// TODO are those EChanges correct?
public class JaMoPPChangeBuildHelper {

    private static final String NAME_ATTRIBUTE = "name";

    private static <T extends NamedElement> EChange createRenameChange(final T originalEObject, final T renamedEObject) {
        final UpdateSingleValuedEAttribute<String> updateEAttribute = AttributeFactory.eINSTANCE
                .createUpdateSingleValuedEAttribute();
        updateEAttribute.setOldAffectedEObject(originalEObject);
        updateEAttribute.setNewAffectedEObject(renamedEObject);
        final EClass eClass = originalEObject.eClass();
        final EAttribute nameAttribute = (EAttribute) eClass.getEStructuralFeature(NAME_ATTRIBUTE);
        updateEAttribute.setAffectedFeature(nameAttribute);
        final String oldName = originalEObject.getName();
        final String newName = renamedEObject.getName();
        updateEAttribute.setOldValue(oldName);
        updateEAttribute.setNewValue(newName);
        return updateEAttribute;
    }

    public static EChange createRenameMethodChange(final Method originalMethod, final Method renamedMethod) {
        return createRenameChange(originalMethod, renamedMethod);
    }

    public static EChange createRenameParameterChange(final Parameter originalParameter, final Parameter renamedParameter) {
        return createRenameChange(originalParameter, renamedParameter);
    }

    public static EChange createRenameFieldChange(final Field originalField, final Field renamedField) {
        return createRenameChange(originalField, renamedField);
    }

    public static EChange createRenameClassChange(final Class originalClass, final Class renamedClass) {
        return createRenameChange(originalClass, renamedClass);
    }

    public static EChange createRenameInterfaceChange(final Interface originalInterface, final Interface renamedInterface) {
        return createRenameChange(originalInterface, renamedInterface);
    }

    /**
     * @param originalMethod
     * @param changedMethod
     * @return
     *
     * @throws IllegalStateException
     *             if new return type is unknown
     */
    public static EChange createChangeMethodReturnTypeChange(final Method originalMethod, final Method changedMethod) {
        return createChangeTypeChange(originalMethod, changedMethod);
    }

    public static EChange createChangeFieldTypeChange(final Field originalField, final Field changedField) {
        return createChangeTypeChange(originalField, changedField);
    }

    private static EChange createChangeTypeChange(final TypedElement original, final TypedElement changed) {
        final ReplaceNonRootEObjectSingle<TypeReference> updateEReference = ContainmentFactory.eINSTANCE.createReplaceNonRootEObjectSingle();
        updateEReference.setOldAffectedEObject(original);
        updateEReference.setNewAffectedEObject(changed);
        final EReference typeReference = original.getTypeReference().eContainmentFeature();
        updateEReference.setAffectedFeature(typeReference);
        updateEReference.setOldValue(original.getTypeReference());
        updateEReference.setNewValue(changed.getTypeReference());
        return updateEReference;
    }

    private static EChange createChangeSuperClassChange(final Class changedClass, final TypeReference superClass) {
        final ReplaceNonRootEObjectSingle<TypeReference> updateEReference = ContainmentFactory.eINSTANCE.createReplaceNonRootEObjectSingle();
        updateEReference.setOldAffectedEObject(changedClass);
        updateEReference.setNewAffectedEObject(superClass.eContainer());
        final EReference superClassReference = superClass.eContainmentFeature();
        updateEReference.setAffectedFeature(superClassReference);
        updateEReference.setOldValue((TypeReference) changedClass.eGet(superClassReference));
        updateEReference.setNewValue(superClass);
        return updateEReference;
    }

    private static EChange createAddSuperTypeChange(final ConcreteClassifier originalBase, final TypeReference superType) {
        return createAddNonRootEObjectInListChange(superType, originalBase);
    }

    public static EChange createAddClassChange(final Class newClass, final CompilationUnit beforeChange) {
        return createAddNonRootEObjectInListChange(newClass, beforeChange);
    }

    public static EChange createRemovedClassChange(final Class removedClass, final CompilationUnit afterChange) {
        return createDeleteNonRootEObjectInListChange(removedClass, afterChange);
    }

    public static EChange createCreateInterfaceChange(final Interface newInterface, final CompilationUnit beforeChange) {
        return createAddNonRootEObjectInListChange(newInterface, beforeChange);
    }

    public static EChange createRemovedInterfaceChange(final Interface removedInterface, final CompilationUnit afterChange) {
        return createDeleteNonRootEObjectInListChange(removedInterface, afterChange);
    }

    public static EChange createAddImportChange(final Import imp, final CompilationUnit beforeChange) {
        return createAddNonRootEObjectInListChange(imp, beforeChange);
    }

    public static EChange createRemoveImportChange(final Import imp, final CompilationUnit afterChange) {
        return createDeleteNonRootEObjectInListChange(imp, afterChange);
    }

    public static EChange createAddMethodChange(final Method newMethod, final ConcreteClassifier beforeChange) {
        return createAddNonRootEObjectInListChange(newMethod, beforeChange);
    }

    public static EChange createRemoveMethodChange(final Method deletedMethod, final ConcreteClassifier afterChange) {
        return createDeleteNonRootEObjectInListChange(deletedMethod, afterChange);
    }

    public static EChange createAddParameterChange(final Parameter newParameter, final Method beforeChange) {
        return createAddNonRootEObjectInListChange(newParameter, beforeChange);
    }

    public static EChange createRemoveParameterChange(final Parameter oldParameter, final Method afterChange) {
        return createDeleteNonRootEObjectInListChange(oldParameter, afterChange);
    }

    public static EChange createAddModifierChange(final Modifier newModifier, final EObject beforeChange) {
        return createAddNonRootEObjectInListChange(newModifier, beforeChange);
    }

    public static EChange createRemoveModifierChange(final Modifier oldModifier, final EObject afterChange) {
        return createDeleteNonRootEObjectInListChange(oldModifier, afterChange);
    }

    public static EChange createAddFieldChange(final Field field, final ConcreteClassifier beforeChange) {
        return createAddNonRootEObjectInListChange(field, beforeChange);
    }

    public static EChange createRemoveFieldChange(final Field field, final ConcreteClassifier afterChange) {
        return createDeleteNonRootEObjectInListChange(field, afterChange);
    }

    public static EChange createAddSuperInterfaceChange(final ConcreteClassifier classifierBeforeAdd, final TypeReference implementsTypeRef) {
        return createAddNonRootEObjectInListChange(implementsTypeRef, classifierBeforeAdd);
    }

    public static EChange createRemoveSuperInterfaceChange(final ConcreteClassifier classifierAfterDelete, final TypeReference implementsTypeRef) {
        return createDeleteNonRootEObjectInListChange(implementsTypeRef, classifierAfterDelete);
    }

    private static <T extends EObject> EChange createAddNonRootEObjectInListChange(final T createdEObject,
            final EObject containerBeforeAdd) {
        final CreateNonRootEObjectInList<T> createChange = ContainmentFactory.eINSTANCE.createCreateNonRootEObjectInList();
        createChange.setNewAffectedEObject(createdEObject.eContainer());
        createChange.setOldAffectedEObject(containerBeforeAdd);
        final EReference containingReference = (EReference) createdEObject.eContainingFeature();
        @SuppressWarnings("unchecked")
        final
        int index = ((EList<EObject>)createChange.getNewAffectedEObject().eGet(containingReference)).indexOf(createdEObject);
        createChange.setAffectedFeature(containingReference);
        createChange.setIndex(index);
        createChange.setNewValue(createdEObject);
        return createChange;
    }

    private static <T extends EObject> EChange createDeleteNonRootEObjectInListChange(final T deletedEObject,
            final EObject containerAfterDelete) {
        final DeleteNonRootEObjectInList<T> deleteChange = ContainmentFactory.eINSTANCE.createDeleteNonRootEObjectInList();
        deleteChange.setOldAffectedEObject(deletedEObject.eContainer());
        deleteChange.setNewAffectedEObject(containerAfterDelete);
        final EReference containingReference = (EReference) deletedEObject.eContainingFeature();
        @SuppressWarnings("unchecked")
        final
        int index = ((EList<EObject>)deleteChange.getOldAffectedEObject().eGet(containingReference)).indexOf(deletedEObject);
        deleteChange.setAffectedFeature(containingReference);
        deleteChange.setIndex(index);
        deleteChange.setOldValue(deletedEObject);
        return deleteChange;
    }

    public static EChange createCreatePackageChange(final String packageName) {
        final Package pkg = ContainersFactory.eINSTANCE.createPackage();
        pkg.setName(packageName);
        final CreateRootEObject<Package> createPackage = ObjectFactory.eINSTANCE.createCreateRootEObject();
        createPackage.setNewValue(pkg);
        return createPackage;
    }

    public static EChange createDeletePackageChange(final String packageName) {
        final Package pkg = ContainersFactory.eINSTANCE.createPackage();
        pkg.setName(packageName);
        final DeleteRootEObject<Package> deletePackage = ObjectFactory.eINSTANCE.createDeleteRootEObject();
        deletePackage.setOldValue(pkg);
        return deletePackage;
    }

    public static EChange createRenamePackageChange(final String oldPackageName, final String newPackageName) {
        final Package originalPackage = ContainersFactory.eINSTANCE.createPackage();
        originalPackage.setName(oldPackageName);
        final Package renamedPackage = ContainersFactory.eINSTANCE.createPackage();
        renamedPackage.setName(newPackageName);
        return createRenameChange(originalPackage, renamedPackage);
    }

    public static EChange[] createMoveMethodChange(final Method removedMethod, final ConcreteClassifier movedFromAfterRemove,
            final Method addedMethod, final ConcreteClassifier movedToBeforeAdd) {
        final EChange removeMethodChange = JaMoPPChangeBuildHelper.createRemoveMethodChange(removedMethod,
                movedFromAfterRemove);
        final EChange addMethodChange = JaMoPPChangeBuildHelper.createAddMethodChange(addedMethod, movedToBeforeAdd);
        return new EChange[] { removeMethodChange, addMethodChange };
    }
}
