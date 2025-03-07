package tools.vitruv.dsls.reactions.codegen.classgenerators

import java.util.ArrayList
import org.eclipse.emf.ecore.impl.EPackageImpl
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtext.common.types.JvmVisibility
import tools.vitruv.dsls.reactions.codegen.typesbuilder.TypesBuilderExtensionProvider
import tools.vitruv.dsls.reactions.language.toplevelelements.ReactionsSegment
import tools.vitruv.extensions.dslsruntime.reactions.AbstractReactionsChangePropagationSpecification
import tools.vitruv.framework.propagation.ChangePropagationSpecification

import static extension tools.vitruv.dsls.reactions.codegen.helper.ClassNamesGenerators.*
import static extension tools.vitruv.dsls.reactions.codegen.helper.ReactionsElementsCompletionChecker.isReferenceable
import java.util.Set
import tools.vitruv.framework.change.MetamodelDescriptor

class ChangePropagationSpecificationClassGenerator extends ClassGenerator {
	final ReactionsSegment reactionsSegment;
	var JvmGenericType generatedClass;

	new(ReactionsSegment reactionsSegment, TypesBuilderExtensionProvider typesBuilderExtensionProvider) {
		super(typesBuilderExtensionProvider)
		if (!reactionsSegment.isReferenceable) {
			throw new IllegalArgumentException("incomplete");
		}
		this.reactionsSegment = reactionsSegment;
	}

	override generateEmptyClass() {
		generatedClass = reactionsSegment.toClass(
			reactionsSegment.changePropagationSpecificationClassNameGenerator.qualifiedName) [
			visibility = JvmVisibility.PUBLIC;
		];
	}

	override generateBody() {
		generatedClass => [
			superTypes += typeRef(AbstractReactionsChangePropagationSpecification);
			superTypes += typeRef(ChangePropagationSpecification);
			members += reactionsSegment.toConstructor() [
				body = '''
				super(«MetamodelDescriptor».with(«Set».of(«FOR namespaceUri : reactionsSegment.fromMetamodels.map[package.nsURI] SEPARATOR ','»"«namespaceUri»"«ENDFOR»)), 
					«MetamodelDescriptor».with(«Set».of(«FOR namespaceUri : reactionsSegment.toMetamodels.map[package.nsURI] SEPARATOR ','»"«namespaceUri»"«ENDFOR»)));'''
			]

			// register executor as change processor:
			members += reactionsSegment.toMethod("setup", typeRef(Void.TYPE)) [
				visibility = JvmVisibility.PROTECTED;
				val metamodelPackageClassQualifiedNames = new ArrayList
				metamodelPackageClassQualifiedNames +=
					(reactionsSegment.fromMetamodels + reactionsSegment.toMetamodels).map[package.class].filter [
						it !== EPackageImpl
					].map[name]
				body = '''
					«FOR metamodelPackageClassQualifiedName : metamodelPackageClassQualifiedNames»org.eclipse.emf.ecore.EPackage.Registry.INSTANCE.putIfAbsent(«
						metamodelPackageClassQualifiedName».eNS_URI, «metamodelPackageClassQualifiedName».eINSTANCE);
					«ENDFOR»
					this.addChangeMainprocessor(new «reactionsSegment.executorClassNameGenerator.qualifiedName»());
				'''
			]
		]
	}
}
