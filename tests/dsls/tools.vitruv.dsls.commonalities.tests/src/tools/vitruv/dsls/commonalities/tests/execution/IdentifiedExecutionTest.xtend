package tools.vitruv.dsls.commonalities.tests.execution

import org.junit.jupiter.api.^extension.ExtendWith
import org.eclipse.xtext.testing.extensions.InjectionExtension
import org.eclipse.xtext.testing.InjectWith
import org.junit.jupiter.api.Test
import javax.inject.Inject
import tools.vitruv.testutils.TestProject
import java.nio.file.Path
import tools.vitruv.testutils.VitruvApplicationTest
import org.junit.jupiter.api.TestInstance
import org.junit.jupiter.api.BeforeAll
import org.eclipse.xtend.lib.annotations.Accessors
import org.junit.jupiter.api.DisplayName
import static tools.vitruv.testutils.metamodels.AllElementTypesCreators.aet
import static tools.vitruv.testutils.metamodels.AllElementTypes2Creators.aet2
import static tools.vitruv.testutils.metamodels.UmlMockupCreators.uml
import static tools.vitruv.testutils.metamodels.PcmMockupCreators.pcm
import static org.hamcrest.MatcherAssert.assertThat
import static tools.vitruv.testutils.matchers.ModelMatchers.contains
import static tools.vitruv.testutils.matchers.ModelMatchers.ignoringFeatures
import uml_mockup.UPackage
import pcm_mockup.Repository
import static tools.vitruv.testutils.matchers.ModelMatchers.doesNotExist
import allElementTypes.Root
import allElementTypes2.Root2
import tools.vitruv.dsls.commonalities.tests.CommonalitiesLanguageInjectorProvider
import tools.vitruv.dsls.commonalities.tests.util.TestCommonalitiesGenerator
import static extension tools.vitruv.testutils.metamodels.TestMetamodelsPathFactory.allElementTypes2
import static extension tools.vitruv.testutils.metamodels.TestMetamodelsPathFactory.allElementTypes
import static extension tools.vitruv.testutils.metamodels.TestMetamodelsPathFactory.uml_mockup
import static extension tools.vitruv.testutils.metamodels.TestMetamodelsPathFactory.pcm_mockup

@ExtendWith(InjectionExtension)
@InjectWith(CommonalitiesLanguageInjectorProvider)
@TestInstance(PER_CLASS)
@DisplayName('executing simple commonalities')
class IdentifiedExecutionTest extends VitruvApplicationTest {
	@Accessors(PROTECTED_GETTER)
	@Inject TestCommonalitiesGenerator generator
	
	@BeforeAll
	def void generate(@TestProject(variant = "commonalities") Path testProject) {
		generator.generate(testProject,
			'Identified.commonality' -> '''
				import "http://tools.vitruv.testutils.metamodels.allElementTypes" as AllElementTypes
				import "http://tools.vitruv.testutils.metamodels.allElementTypes2" as AllElementTypes2
				import "http://tools.vitruv.testutils.metamodels.pcm_mockup" as PcmMockup
				import "http://tools.vitruv.testutils.metamodels.uml_mockup" as UmlMockup
				
				concept test
				
				commonality Identified {
					with AllElementTypes:(Root in Resource)
					with AllElementTypes2:(Root2 in Resource)
					with PcmMockup:(Repository in Resource)
					with UmlMockup:(UPackage in Resource)
				
					has id {
						= AllElementTypes:Root.id
						= AllElementTypes2:Root2.id2
						= PcmMockup:Repository.name
						= UmlMockup:UPackage.name
						-> AllElementTypes:Resource.name
						-> AllElementTypes2:Resource.name
						-> PcmMockup:Resource.name
						-> UmlMockup:Resource.name
					}
				
					has number {
						= AllElementTypes:Root.singleValuedEAttribute
						= AllElementTypes2:Root2.singleValuedEAttribute2
					}
				
					has numberList {
						= AllElementTypes:Root.multiValuedEAttribute
						= AllElementTypes2:Root2.multiValuedEAttribute2
					}
				
					has sub referencing test:SubIdentified {
						= AllElementTypes:Root.multiValuedContainmentEReference
						= AllElementTypes2:Root2.multiValuedContainmentEReference2
						= PcmMockup:Repository.components
						= UmlMockup:UPackage.classes
					}
				}
			''',
			'SubIdentified.commonality' -> '''
				import "http://tools.vitruv.testutils.metamodels.allElementTypes" as AllElementTypes
				import "http://tools.vitruv.testutils.metamodels.allElementTypes2" as AllElementTypes2
				import "http://tools.vitruv.testutils.metamodels.pcm_mockup" as PcmMockup
				import "http://tools.vitruv.testutils.metamodels.uml_mockup" as UmlMockup
				
				concept test
				
				commonality SubIdentified {
					with AllElementTypes:NonRoot
					with AllElementTypes2:NonRoot2
					with PcmMockup:Component
					with UmlMockup:UClass
				
					has name {
						= AllElementTypes:NonRoot.id
						= AllElementTypes2:NonRoot2.id2
						= PcmMockup:Component.name
						= UmlMockup:UClass.name
					}
				}			
			'''
		)
	}
	
	override protected getChangePropagationSpecifications() {
		generator.createChangePropagationSpecifications()
	}
	
	@Test
	@DisplayName('propagates a root insertion')
	def void rootInsert() {
		resourceAt('testid'.allElementTypes2).propagate [
			contents += aet2.Root2 => [id2 = 'testid']
		]

		assertThat(resourceAt('testid'.allElementTypes2), contains(aet2.Root2 => [id2 = 'testid']))
		assertThat(resourceAt('testid'.allElementTypes), contains(aet.Root => [id = 'testid']))
		assertThat(resourceAt('testid'.pcm_mockup), 
			contains(pcm.Repository => [name = 'testid'], ignoringFeatures('id')))
		assertThat(resourceAt('testid'.uml_mockup), 
			contains(uml.Package => [name = 'testid'], ignoringFeatures('id')))
	}

	@Test
	@DisplayName('propagates root insertions in multiple resources')
	def void multiRootInsert() {
		#['first', 'second', 'third'].forEach [ name |
			resourceAt(name.allElementTypes2).propagate [
				contents += aet2.Root2 => [id2 = name]
			]
		]

		assertThat(resourceAt('first'.allElementTypes2), contains(aet2.Root2 => [id2 = 'first']))
		assertThat(resourceAt('first'.allElementTypes), contains(aet.Root => [id = 'first']))
		assertThat(resourceAt('first'.pcm_mockup),
			contains(pcm.Repository => [name = 'first'], ignoringFeatures('id')))
		assertThat(resourceAt('first'.uml_mockup),
			contains(uml.Package => [name = 'first'], ignoringFeatures('id')))

		assertThat(resourceAt('second'.allElementTypes2), contains(aet2.Root2 => [id2 = 'second']))
		assertThat(resourceAt('second'.allElementTypes), contains(aet.Root => [id = 'second']))
		assertThat(resourceAt('second'.pcm_mockup),
			contains(pcm.Repository => [name = 'second'], ignoringFeatures('id')))
		assertThat(resourceAt('second'.uml_mockup),
			contains(uml.Package => [name = 'second'], ignoringFeatures('id')))

		assertThat(resourceAt('third'.allElementTypes2), contains(aet2.Root2 => [id2 = 'third']))
		assertThat(resourceAt('third'.allElementTypes), contains(aet.Root => [id = 'third']))
		assertThat(resourceAt('third'.pcm_mockup),
			contains(pcm.Repository => [name = 'third'], ignoringFeatures('id')))
		assertThat(resourceAt('third'.uml_mockup),
			contains(uml.Package => [name = 'third'], ignoringFeatures('id')))
	}

	@Test
	@DisplayName('propagates root deletions in multiple resources')
	def void multiRootDelete() {
		#['first', 'second', 'third'].forEach [ name |
			resourceAt(name.allElementTypes2).propagate [
				contents += aet2.Root2 => [id2 = name]
			]
		]

		resourceAt('second'.allElementTypes).propagate [
			contents.clear()
		]
		assertThat(resourceAt('second'.allElementTypes), doesNotExist)
	// TODO Extend assertions
	}

	@Test
	@DisplayName('propagates setting the ID attribute')
	def void setIdAttribute() {
		resourceAt('startid'.allElementTypes2).propagate[contents += aet2.Root2 => [id2 = 'startid']]

		Root2.from('startid'.allElementTypes2).propagate[id2 = '1st id']
		assertThat(resourceAt('startid'.allElementTypes2), contains(aet2.Root2 => [id2 = '1st id']))
		assertThat(resourceAt('startid'.allElementTypes), contains(aet.Root => [id = '1st id']))
		assertThat(resourceAt('startid'.pcm_mockup), contains(pcm.Repository => [name = '1st id'], ignoringFeatures('id')))
		assertThat(resourceAt('startid'.uml_mockup), contains(uml.Package => [name = '1st id'], ignoringFeatures('id')))

		Root.from('startid'.allElementTypes).propagate[id = '2nd id']
		assertThat(resourceAt('startid'.allElementTypes2), contains(aet2.Root2 => [id2 = '2nd id']))
		assertThat(resourceAt('startid'.allElementTypes), contains(aet.Root => [id = '2nd id']))
		assertThat(resourceAt('startid'.pcm_mockup), contains(pcm.Repository => [name = '2nd id'], ignoringFeatures('id')))
		assertThat(resourceAt('startid'.uml_mockup), contains(uml.Package => [name = '2nd id'], ignoringFeatures('id')))

		Repository.from('startid'.pcm_mockup).propagate[name = '3th id']
		assertThat(resourceAt('startid'.allElementTypes2), contains(aet2.Root2 => [id2 = '3th id']))
		assertThat(resourceAt('startid'.allElementTypes), contains(aet.Root => [id = '3th id']))
		assertThat(resourceAt('startid'.pcm_mockup), contains(pcm.Repository => [name = '3th id'], ignoringFeatures('id')))
		assertThat(resourceAt('startid'.uml_mockup), contains(uml.Package => [name = '3th id'], ignoringFeatures('id')))

		UPackage.from('startid'.uml_mockup).propagate[name = '4th id']
		assertThat(resourceAt('startid'.allElementTypes2), contains(aet2.Root2 => [id2 = '4th id']))
		assertThat(resourceAt('startid'.allElementTypes), contains(aet.Root => [id = '4th id']))
		assertThat(resourceAt('startid'.pcm_mockup), contains(pcm.Repository => [name = '4th id'], ignoringFeatures('id')))
		assertThat(resourceAt('startid'.uml_mockup), contains(uml.Package => [name = '4th id'], ignoringFeatures('id')))
	}

	@Test
	@DisplayName('propagates setting a simple attribute')
	def void setSimpleAttribute() {
		resourceAt('test'.allElementTypes2).propagate [
			contents += aet2.Root2 => [
				singleValuedEAttribute2 = 0
				id2 = 'test'
			]

		]

		Root2.from('test'.allElementTypes2).propagate[singleValuedEAttribute2 = 1]
		assertThat(resourceAt('test'.allElementTypes2), contains(aet2.Root2 => [
			singleValuedEAttribute2 = 1
			id2 = 'test'
		]))
		assertThat(resourceAt('test'.allElementTypes), contains(aet.Root => [
			singleValuedEAttribute = 1
			id = 'test'
		]))

		Root.from('test'.allElementTypes).propagate[singleValuedEAttribute = 2]
		assertThat(resourceAt('test'.allElementTypes2), contains(aet2.Root2 => [
			singleValuedEAttribute2 = 2
			id2 = 'test'
		]))
		assertThat(resourceAt('test'.allElementTypes), contains(aet.Root => [
			singleValuedEAttribute = 2
			id = 'test'
		]))

		Root2.from('test'.allElementTypes2).propagate[singleValuedEAttribute2 = 3]
		assertThat(resourceAt('test'.allElementTypes2), contains(aet2.Root2 => [
			singleValuedEAttribute2 = 3
			id2 = 'test'
		]))
		assertThat(resourceAt('test'.allElementTypes), contains(aet.Root => [
			singleValuedEAttribute = 3
			id = 'test'
		]))

		Root.from('test'.allElementTypes).propagate[singleValuedEAttribute = 4]
		assertThat(resourceAt('test'.allElementTypes2), contains(aet2.Root2 => [
			singleValuedEAttribute2 = 4
			id2 = 'test'
		]))
		assertThat(resourceAt('test'.allElementTypes), contains(aet.Root => [
			singleValuedEAttribute = 4
			id = 'test'
		]))
	}

	@Test
	@DisplayName('propagates setting a multi-valued attribute')
	def void setMultiValue() {
		resourceAt('test'.allElementTypes2).propagate [
			contents += aet2.Root2 => [
				multiValuedEAttribute2 += #[1, 2, 3]
				id2 = 'test'
			]
		]
		assertThat(resourceAt('test'.allElementTypes2), contains(aet2.Root2 => [
			multiValuedEAttribute2 += #[1, 2, 3]
			id2 = 'test'
		]))
		assertThat(resourceAt('test'.allElementTypes), contains(aet.Root => [
			multiValuedEAttribute += #[1, 2, 3]
			id = 'test'
		]))

		Root2.from('test'.allElementTypes2).propagate[multiValuedEAttribute2 += 4]
		assertThat(resourceAt('test'.allElementTypes2), contains(aet2.Root2 => [
			multiValuedEAttribute2 += #[1, 2, 3, 4]
			id2 = 'test'
		]))
		assertThat(resourceAt('test'.allElementTypes), contains(aet.Root => [
			multiValuedEAttribute += #[1, 2, 3, 4]
			id = 'test'
		]))

		Root.from('test'.allElementTypes).propagate[multiValuedEAttribute += 5]
		assertThat(resourceAt('test'.allElementTypes2), contains(aet2.Root2 => [
			multiValuedEAttribute2 += #[1, 2, 3, 4, 5]
			id2 = 'test'
		]))
		assertThat(resourceAt('test'.allElementTypes), contains(aet.Root => [
			multiValuedEAttribute += #[1, 2, 3, 4, 5]
			id = 'test'
		]))

	/*		Vitruvius doesn’t correctly translate the changes?
	 * 		saveAndSynchronizeChanges(root2.from('test'.allElementTypes2) => [multiValuedEAttribute2 -= #[1, 3, 5]])
	 * 		assertThat(resourceAt('test'.allElementTypes2), contains(aet2.Root2 => [
	 * 			multiValuedEAttribute2 += #[2, 4]
	 * 			id2 = 'test'
	 * 		]))
	 * 		assertThat(resourceAt('test'.allElementTypes), contains(aet.Root => [
	 * 			multiValuedEAttribute += #[2, 4]
	 * 			id = 'test'
	 * 		]))

	 * 		saveAndSynchronizeChanges(Root.from('test'.allElementTypes) => [multiValuedEAttribute -= #[2]])
	 * 		assertThat(resourceAt('test'.allElementTypes2), contains(aet2.Root2 => [
	 * 			multiValuedEAttribute2 += 4
	 * 			id2 = 'test'
	 * 		]))
	 * 		assertThat(resourceAt('test'.allElementTypes), contains(aet.Root => [
	 * 			multiValuedEAttribute += 4
	 * 			id = 'test'
	 ]))*/
	}

	@Test
	@DisplayName('propagates inserting a reference')
	def void rootWithReferenceInsert() {
		resourceAt('testid'.allElementTypes2).propagate [
			contents += aet2.Root2 => [
				id2 = 'testid'
				multiValuedContainmentEReference2 += aet2.NonRoot2 => [id2 = 'testname']
			]
		]

		assertThat(resourceAt('testid'.allElementTypes2), contains(aet2.Root2 => [
			id2 = 'testid'
			multiValuedContainmentEReference2 += aet2.NonRoot2 => [id2 = 'testname']
		]))
		assertThat(resourceAt('testid'.allElementTypes), contains(aet.Root => [
			id = 'testid'
			multiValuedContainmentEReference += aet.NonRoot => [id = 'testname']
		]))
		assertThat(resourceAt('testid'.pcm_mockup), contains(pcm.Repository => [
			name = 'testid'
			components += pcm.Component => [name = 'testname']
		], ignoringFeatures('id')))
		assertThat(resourceAt('testid'.uml_mockup), contains(uml.Package => [
			name = 'testid'
			classes += uml.Class => [name = 'testname']
		], ignoringFeatures('id')))
	}

	@Test
	@DisplayName('propagates inserting multiple references')
	def void multiReferenceInsert() {
		resourceAt('testid'.allElementTypes2).propagate [
			contents += aet2.Root2 => [
				id2 = 'testid'
				multiValuedContainmentEReference2 += #[
					aet2.NonRoot2 => [id2 = 'first'],
					aet2.NonRoot2 => [id2 = 'second']
				]
			]
		]

		assertThat(resourceAt('testid'.allElementTypes2), contains(aet2.Root2 => [
			id2 = 'testid'
			multiValuedContainmentEReference2 += #[
				aet2.NonRoot2 => [id2 = 'first'],
				aet2.NonRoot2 => [id2 = 'second']
			]
		]))
		assertThat(resourceAt('testid'.allElementTypes), contains(aet.Root => [
			id = 'testid'
			multiValuedContainmentEReference += #[
				aet.NonRoot => [id = 'first'],
				aet.NonRoot => [id = 'second']
			]
		]))
		assertThat(resourceAt('testid'.pcm_mockup), contains(pcm.Repository => [
			name = 'testid'
			components += #[
				pcm.Component => [name = 'first'],
				pcm.Component => [name = 'second']
			]
		], ignoringFeatures('id')))
		assertThat(resourceAt('testid'.uml_mockup), contains(uml.Package => [
			name = 'testid'
			classes += #[
				uml.Class => [name = 'first'],
				uml.Class => [name = 'second']
			]
		], ignoringFeatures('id')))

		Repository.from('testid'.pcm_mockup).propagate [
			components += pcm.Component => [name = 'third']
		]
		assertThat(resourceAt('testid'.allElementTypes2), contains(aet2.Root2 => [
			id2 = 'testid'
			multiValuedContainmentEReference2 += #[
				aet2.NonRoot2 => [id2 = 'first'],
				aet2.NonRoot2 => [id2 = 'second'],
				aet2.NonRoot2 => [id2 = 'third']
			]
		]))
		assertThat(resourceAt('testid'.allElementTypes), contains(aet.Root => [
			id = 'testid'
			multiValuedContainmentEReference += #[
				aet.NonRoot => [id = 'first'],
				aet.NonRoot => [id = 'second'],
				aet.NonRoot => [id = 'third']
			]
		]))
		assertThat(resourceAt('testid'.pcm_mockup), contains(pcm.Repository => [
			name = 'testid'
			components += #[
				pcm.Component => [name = 'first'],
				pcm.Component => [name = 'second'],
				pcm.Component => [name = 'third']
			]
		], ignoringFeatures('id')))
		assertThat(resourceAt('testid'.uml_mockup), contains(uml.Package => [
			name = 'testid'
			classes += #[
				uml.Class => [name = 'first'],
				uml.Class => [name = 'second'],
				uml.Class => [name = 'third']
			]
		], ignoringFeatures('id')))
	}
}
