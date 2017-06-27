package tools.vitruv.framework.versioning.impl

import java.util.ArrayList
import java.util.Collection
import java.util.Collections
import java.util.HashMap
import java.util.List
import java.util.Map
import java.util.function.Function
import java.util.stream.Collectors
import org.apache.log4j.Level
import org.apache.log4j.Logger
import tools.vitruv.framework.change.description.TransactionalChange
import tools.vitruv.framework.change.recording.AtomicEmfChangeRecorder
import tools.vitruv.framework.change.recording.impl.AtomicEmfChangeRecorderImpl
import tools.vitruv.framework.util.datatypes.VURI
import tools.vitruv.framework.versioning.SourceTargetPair
import tools.vitruv.framework.versioning.SourceTargetRecorder
import tools.vitruv.framework.vsum.InternalVirtualModel
import tools.vitruv.framework.versioning.commit.ChangeMatch
import tools.vitruv.framework.versioning.commit.CommitFactory

class SourceTargetRecorderImpl implements SourceTargetRecorder {
	static extension Logger = Logger::getLogger(SourceTargetRecorderImpl)

	val Collection<SourceTargetPair> sourceTargetPairs
	val InternalVirtualModel virtualModel
	val Map<VURI, AtomicEmfChangeRecorder> pathsToRecorders
	val Map<VURI, List<ChangeMatch>> changesMatches
	val boolean unresolveRecordedChanges

	new(InternalVirtualModel virtualModel) {
		this(virtualModel, true)
	}

	new(InternalVirtualModel virtualModel, boolean unresolveRecordedChanges) {
		changesMatches = new HashMap
		pathsToRecorders = new HashMap
		sourceTargetPairs = new ArrayList
		this.virtualModel = virtualModel
		this.unresolveRecordedChanges = unresolveRecordedChanges

		// TODO PS Remove Level::DEBUG
		level = Level::DEBUG
	}

	override void recordOriginalAndCorrespondentChanges(VURI orignal, Collection<VURI> targets) {
		val List<ChangeMatch> matches = new ArrayList
		changesMatches.put(orignal, matches)
		targets.forEach[addPathToRecorded]
		sourceTargetPairs.add(new SourceTargetPairImpl(orignal, targets))
	}

	override update(VURI vuri, TransactionalChange change) {
		sourceTargetPairs.filter[change.URI == source].forEach [ pair |
			val targetToCorrespondentChanges = pair.targets.stream.collect(Collectors::toMap(Function::identity, [
				getChanges
			]))
			val match = CommitFactory::eINSTANCE.createChangeMatch
			match.originalChange = change
			match.originalVURI = pair.source
			match.targetToCorrespondentChanges = targetToCorrespondentChanges
			debug('''New match added: «match»''')
			changesMatches.get(vuri).add(match)
		]
	}

	override getChangeMatches(VURI source) {
		changesMatches.get(source)
	}

	def void addPathToRecorded(VURI resourceVuri) {
		if (pathsToRecorders.containsKey(resourceVuri))
			throw new IllegalStateException('''VURI«resourceVuri» has already been observed''')
		val recorder = new AtomicEmfChangeRecorderImpl(unresolveRecordedChanges)
		pathsToRecorders.put(resourceVuri, recorder)
		recorder.startRecordingOn(resourceVuri, false)
	}

	def List<TransactionalChange> getChanges(VURI vuri) {
		val changes = new ArrayList<TransactionalChange>
		val recorder = pathsToRecorders.get(vuri)
		virtualModel.executeCommand [|
			changes += recorder.endRecording
			return null
		]
		recorder.startRecordingOn(vuri, true)
		changes
	}

	private def startRecordingOn(AtomicEmfChangeRecorder recorder, VURI vuri, boolean restart) {
		debug('''«if (restart) "Restart" else "Start"» recording on VURI «vuri»''')
		val modelInstance = virtualModel.getModelInstance(vuri)
		recorder.beginRecording(vuri, Collections::singleton(modelInstance.resource))
	}
}
