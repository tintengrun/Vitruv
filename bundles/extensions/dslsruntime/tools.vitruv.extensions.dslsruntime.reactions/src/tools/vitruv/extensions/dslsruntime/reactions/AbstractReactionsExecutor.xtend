package tools.vitruv.extensions.dslsruntime.reactions

import org.apache.log4j.Logger
import tools.vitruv.extensions.dslsruntime.reactions.IReactionRealization
import tools.vitruv.framework.userinteraction.UserInteractor
import tools.vitruv.framework.change.echange.EChange
import tools.vitruv.framework.correspondence.CorrespondenceModel
import tools.vitruv.framework.propagation.ResourceAccess
import java.util.List
import tools.vitruv.framework.propagation.impl.AbstractChangePropagationSpecification
import tools.vitruv.framework.change.MetamodelDescriptor

abstract class AbstractReactionsExecutor extends AbstractChangePropagationSpecification {
	static val LOGGER = Logger.getLogger(AbstractReactionsExecutor);

	val RoutinesFacadesProvider routinesFacadesProvider;
	List<IReactionRealization> reactions;

	new(MetamodelDescriptor sourceMetamodelDescriptor, MetamodelDescriptor targetMetamodelDescriptor) {
		super(sourceMetamodelDescriptor, targetMetamodelDescriptor);
		this.reactions = newArrayList;
		this.routinesFacadesProvider = this.createRoutinesFacadesProvider();
		this.setup();
	}

	protected def getRoutinesFacadesProvider() {
		return routinesFacadesProvider;
	}

	protected def void addReaction(IReactionRealization reaction) {
		this.reactions += reaction;
	}

	override doesHandleChange(EChange change, CorrespondenceModel correspondenceModel) {
		return true
	}

	override propagateChange(EChange change, CorrespondenceModel correspondenceModel,
		ResourceAccess resourceAccess) {
		LOGGER.trace("Call relevant reactions from " + sourceMetamodelDescriptor + " to " + targetMetamodelDescriptor);
		for (reaction : reactions) {
			LOGGER.trace("Calling reaction: " + reaction.class.simpleName + " with change: " + change);
			val executionState = new ReactionExecutionState(userInteractor, correspondenceModel, resourceAccess, this);
			reaction.applyEvent(change, executionState)
		}
	}

	override setUserInteractor(UserInteractor userInteractor) {
		super.setUserInteractor(userInteractor);
		reactions = newArrayList;
		setup();
	}

	protected abstract def RoutinesFacadesProvider createRoutinesFacadesProvider();

	protected abstract def void setup();

}
