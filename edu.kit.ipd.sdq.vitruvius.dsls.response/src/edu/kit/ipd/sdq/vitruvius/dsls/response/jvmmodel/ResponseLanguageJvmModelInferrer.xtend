/*
 * generated by Xtext 2.9.0
 */
package edu.kit.ipd.sdq.vitruvius.dsls.response.jvmmodel

import com.google.inject.Inject
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.CodeBlock
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.CompareBlock
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.Response
import java.util.ArrayList
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.common.types.JvmFormalParameter
import org.eclipse.xtext.common.types.JvmGenericType
import org.eclipse.xtext.common.types.JvmTypeReference
import org.eclipse.xtext.common.types.JvmVisibility
import org.eclipse.xtext.xbase.jvmmodel.AbstractModelInferrer
import org.eclipse.xtext.xbase.jvmmodel.IJvmDeclaredTypeAcceptor
import org.eclipse.xtext.xbase.jvmmodel.JvmTypesBuilder

import static edu.kit.ipd.sdq.vitruvius.dsls.response.generator.ResponseLanguageGeneratorConstants.*

import static extension edu.kit.ipd.sdq.vitruvius.dsls.response.helper.EChangeHelper.*
import static extension edu.kit.ipd.sdq.vitruvius.dsls.response.helper.ResponseLanguageHelper.*
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.Trigger
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.TargetModel
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.CorrespondenceSourceDeterminationBlock
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.UpdatedModel
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.ModelChange
import edu.kit.ipd.sdq.vitruvius.dsls.response.responseLanguage.ConcreteModelElementChange
import java.util.List

/**
 * <p>Infers a JVM model for the Xtend code blocks of the response file model.</p> 
 *
 * <p>The resulting classes are not to be persisted but only to be used for content assist purposes.</p>
 * 
 * @author Heiko Klare     
 */
class ResponseLanguageJvmModelInferrer extends AbstractModelInferrer {

	@Inject extension JvmTypesBuilder
	
	def dispatch void infer(CorrespondenceSourceDeterminationBlock correspondenceSourceBlock, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		if (isPreIndexingPhase) {
			return;
		}
		val response = correspondenceSourceBlock.containingResponse;
		val methodParameters = createResponseParameters(response,correspondenceSourceBlock, false);
		
		acceptor.accept(response.toClass("ResponseHelperSourceCorrespondence")) [
			members += correspondenceSourceBlock.toMethod(RESPONSE_APPLY_METHOD_NAME, typeRef(EObject)) [applyMethod |
				applyMethod.parameters += methodParameters
				applyMethod.body = correspondenceSourceBlock.object];
			it.makeClassStatic(response)
		]
	}
	
	
	def dispatch void infer(CodeBlock codeBlock, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		if (isPreIndexingPhase) {
			return;
		}
		val response = codeBlock.containingResponse;
		val methodParameters = createResponseParameters(response, codeBlock, true);
		
		acceptor.accept(response.toClass("ResponseHelper" + RESPONSE_APPLY_METHOD_NAME.toFirstUpper)) [
			members += codeBlock.toMethod(RESPONSE_APPLY_METHOD_NAME, typeRef(Void.TYPE)) [applyMethod |
				applyMethod.parameters += methodParameters
				applyMethod.body = codeBlock.code]
			it.makeClassStatic(response)
		]
	}
		
	def dispatch void infer(CompareBlock compareBlock, IJvmDeclaredTypeAcceptor acceptor, boolean isPreIndexingPhase) {
		if (isPreIndexingPhase) {
			return;
		}
		val response = compareBlock.containingResponse;
		val methodParameters = createResponseParameters(response, compareBlock, response.effects.targetModel instanceof UpdatedModel)
		
		acceptor.accept(response.toClass("ResponseHelper" +  PER_MODEL_PRECONDITION_METHOD_NAME.toFirstUpper)) [
			members += compareBlock.toMethod(PER_MODEL_PRECONDITION_METHOD_NAME, typeRef(Boolean.TYPE)) [applyMethod |
				applyMethod.parameters += methodParameters
				applyMethod.body = compareBlock.code]
			it.makeClassStatic(response)
		]
	}
	
	private def createResponseParameters(Response response, EObject blockContext, boolean includeAffectedModel) {
		val methodParameters = <JvmFormalParameter>newArrayList();
		if (response?.trigger != null) {
			methodParameters += generateChangeParameters(response?.trigger, blockContext);	
		}
		if (includeAffectedModel && response?.effects?.targetModel?.rootModelElement != null) {
			methodParameters += generateAffectedModelParameters(response?.effects?.targetModel, blockContext);
		}
		return methodParameters;
	}

	private def dispatch Iterable<JvmFormalParameter> generateChangeParameters(Trigger event, EObject parameterContext) {
		return #[];
	}

	private def dispatch Iterable<JvmFormalParameter> generateChangeParameters(ModelChange event, EObject parameterContext) {
		var eChange = event.generateEChange();
		if (eChange == null) {
			return #[];
		}
		var List<String> changeTypeParameters = <String>newArrayList;
		if (event instanceof ConcreteModelElementChange) {
			changeTypeParameters = #[getGenericTypeParameterFQNOfChange(eChange, event.changedObject)]			
		}
		val changeParameter = parameterContext.generateChangeParameter(eChange.instanceTypeName, changeTypeParameters);
		if (changeParameter != null) {
			return #[changeParameter];
		}
	}
	
	private def Iterable<JvmFormalParameter> generateAffectedModelParameters(TargetModel targetModel, EObject parameterContext) {
		if (targetModel?.rootModelElement?.modelElement != null) {
			return #[parameterContext.generateAffectedModelParameter(targetModel.rootModelElement.modelElement.instanceTypeName)];
		}
		return #[];
	}
	
	private def void makeClassStatic(JvmGenericType type, EObject context) {
		type.members += context.toConstructor [
			visibility = JvmVisibility::PRIVATE
			body = ''''''
			documentation = "Private constructor since this class is static"
		]
	}
	
	private def generateAffectedModelParameter(EObject context, String affectedModelClassName) {
		generateParameter(context, AFFECTED_MODEL_PARAMETER_NAME, affectedModelClassName);
	}
	
	private def generateChangeParameter(EObject context, String changeClassName, String... typeParameterClassNames) {
		generateParameter(context, CHANGE_PARAMETER_NAME, changeClassName, typeParameterClassNames);
	}
	
	private def generateParameter(EObject context, String parameterName, String parameterClassName, String... typeParameterClassNames) {
		if (parameterClassName.nullOrEmpty) {
			return null;
		}
		val typeParameters = new ArrayList<JvmTypeReference>(typeParameterClassNames.size);
		for (typeParameterClassName : typeParameterClassNames) {
			typeParameters.add(typeRef(typeParameterClassName));	
		}		
		val changeType = typeRef(parameterClassName, typeParameters)
		return context.toParameter(parameterName, changeType);
	}
	
}
