/*
 * generated by Xtext 2.9.0
 */
package edu.kit.ipd.sdq.vitruvius.dsls.response.ui.outline

import org.eclipse.xtext.ui.editor.outline.impl.DefaultOutlineTreeProvider
import org.eclipse.xtext.ui.editor.outline.impl.DocumentRootNode
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.ResponseFile
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.MetamodelImport
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.Response
import static extension edu.kit.ipd.sdq.vitruvius.dsls.response.generator.ResponseLanguageGeneratorUtils.*;
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.Trigger
import static extension edu.kit.ipd.sdq.vitruvius.dsls.response.helper.EChangeHelper.*;
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.CompareBlock
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.CodeBlock
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.Effects
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.ResponseLanguagePackage
import org.eclipse.xtext.ui.editor.outline.impl.EStructuralFeatureNode
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.TargetModel
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.ConcreteModelElementChange

/**
 * Ouline structure defintion for a response file.
 *
 * @author Heiko Klare
 */
class ResponseLanguageOutlineTreeProvider extends DefaultOutlineTreeProvider {
	protected def void _createChildren(DocumentRootNode root, ResponseFile responseFile) {
		val importsNode = createEStructuralFeatureNode(root, responseFile, 
			ResponseLanguagePackage.Literals.RESPONSE_FILE__METAMODEL_IMPORTS,
			imageDispatcher.invoke(responseFile), "imports", false);
		for (imp : responseFile.metamodelImports) {
			createChildren(importsNode, imp);
		}
		val responsesNode = createEStructuralFeatureNode(root, responseFile, 
			ResponseLanguagePackage.Literals.RESPONSE_FILE__RESPONSES,
			imageDispatcher.invoke(responseFile), "responses", false);
		for (response : responseFile.responses) {
			createChildren(responsesNode, response);
		}
	}
	
	protected def void _createChildren(EStructuralFeatureNode parentNode, MetamodelImport imp) {
		val importNode = createEObjectNode(parentNode, imp);
		createEStructuralFeatureNode(importNode,
			imp, ResponseLanguagePackage.Literals.METAMODEL_IMPORT__PACKAGE,
			imageDispatcher.invoke(imp.package),
			imp.package.name, true);
	}
	
	protected def void _createChildren(EStructuralFeatureNode parentNode, Response response) {
		val responseNode = createEObjectNode(parentNode, response);
		if (response.documentation != null) {
			createEStructuralFeatureNode(responseNode, response,
				ResponseLanguagePackage.Literals.RESPONSE__DOCUMENTATION,
				imageDispatcher.invoke(response.documentation),
				"Documentation", true);
		}
		val triggerNode = createEStructuralFeatureNode(responseNode, response, 
			ResponseLanguagePackage.Literals.RESPONSE__TRIGGER,
			imageDispatcher.invoke(response.trigger), "Trigger", false);
		createChildren(triggerNode, response.trigger);
		val effectsNode = createEStructuralFeatureNode(responseNode, response, 
			ResponseLanguagePackage.Literals.RESPONSE__EFFECTS,
			imageDispatcher.invoke(response.effects), "Effects", false);
		createChildren(effectsNode, response.effects);
	}
	
	protected def void _createChildren(EStructuralFeatureNode parentNode, Trigger trigger) {
		createEObjectNode(parentNode, trigger);
	}
	
	protected def void _createChildren(EStructuralFeatureNode parentNode, ConcreteModelElementChange event) {
		createEObjectNode(parentNode, event);
		if (event.changedObject != null) {
			createEObjectNode(parentNode, event.changedObject.element);
			if (event.changedObject.feature != null) {
				createEObjectNode(parentNode, event.changedObject.feature);
			}
		}
	}
	
	protected def void _createChildren(EStructuralFeatureNode parentNode, Effects effects) {
		if (effects.targetModel?.rootModelElement != null) {
			val affectedModelNode = createEStructuralFeatureNode(parentNode, effects, 
				ResponseLanguagePackage.Literals.EFFECTS__TARGET_MODEL,
				imageDispatcher.invoke(effects.targetModel), "Target model", effects.targetModel.rootModelElement?.modelElement == null);
			createChildren(affectedModelNode, effects.targetModel);
		}
		if (effects.perModelPrecondition != null) {
			createChildren(parentNode, effects.perModelPrecondition);
		}
		createChildren(parentNode, effects.codeBlock);
	}
	
	protected def void _createChildren(EStructuralFeatureNode parentNode, TargetModel targetModel) {
		if (targetModel.rootModelElement.modelElement!= null) {
			createEObjectNode(parentNode, targetModel.rootModelElement.modelElement);
		}
	}
	
	protected def void _createChildren(EStructuralFeatureNode parentNode, CompareBlock compareBlock) {
		createEObjectNode(parentNode, compareBlock);
	}
	
	protected def void _createChildren(EStructuralFeatureNode parentNode, CodeBlock codeBlock) {
		createEObjectNode(parentNode, codeBlock);
	}
	
	protected def Object _text(MetamodelImport imp) {
		return imp?.name;
	}
	
	protected def Object _text(Response response) {
		if (response.trigger != null) {
			return response.responseName.replace("ResponseTo", "");
		}
		return "No response trigger specified";
	}
	
	protected def Object _text(Trigger trigger) {
		return "There is no outline for this trigger";
	}
	
	protected def Object _text(ConcreteModelElementChange event) {
		if (event.changedObject?.element != null) {
			return event.generateEChange()?.name;
		} else {
			return "No changed element specified"
		}
	}
	
	protected def Object _text(CompareBlock compareBlock) {
		return "Per-Model Precondition Block"
	}
	
	protected def Object _text(CodeBlock codeBlock) {
		return "Execution Block"
	}
	
	protected def boolean _isLeaf(CompareBlock compareBlock) {
		return true;
	}
	
	protected def boolean _isLeaf(CodeBlock codeBlock) {
		return true;
	}
	
	protected def boolean _isLeaf(TargetModel targetModel) {
		return true;
	}
	
	protected def boolean _isLeaf(ConcreteModelElementChange event) {
		return true;
	}
	
}
