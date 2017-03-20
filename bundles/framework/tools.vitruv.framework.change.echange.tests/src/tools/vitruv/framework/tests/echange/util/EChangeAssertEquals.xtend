package tools.vitruv.framework.tests.echange.util

import tools.vitruv.framework.change.echange.EChange
import tools.vitruv.framework.change.echange.feature.attribute.ReplaceSingleValuedEAttribute
import org.junit.Assert
import tools.vitruv.framework.change.echange.feature.attribute.InsertEAttributeValue
import tools.vitruv.framework.change.echange.feature.attribute.RemoveEAttributeValue

class EChangeAssertEquals {
	def public dispatch static void assertEquals(EChange change, EChange change2) {
		Assert.assertTrue(false)
	}
	
	def public dispatch static void assertEquals(ReplaceSingleValuedEAttribute change, EChange change2) {
		var replaceChange = change2.assertIsInstanceOf(ReplaceSingleValuedEAttribute)
		Assert.assertSame(change.affectedEObject, replaceChange.affectedEObject)
		Assert.assertSame(change.affectedFeature, replaceChange.affectedFeature)
		Assert.assertEquals(change.oldValue, replaceChange.oldValue)
		Assert.assertEquals(change.newValue, replaceChange.newValue)
	}
	
	def public dispatch static void assertEquals(InsertEAttributeValue change, EChange change2) {
		var insertChange = change2.assertIsInstanceOf(InsertEAttributeValue)
		Assert.assertSame(change.affectedEObject, insertChange.affectedEObject)
		Assert.assertSame(change.affectedFeature, insertChange.affectedFeature)
		Assert.assertEquals(change.newValue, insertChange.newValue)	
	}
	
	def public dispatch static void assertEquals(RemoveEAttributeValue change, EChange change2) {
		var removeChange = change2.assertIsInstanceOf(RemoveEAttributeValue)
		Assert.assertSame(change.affectedEObject, removeChange.affectedEObject)
		Assert.assertSame(change.affectedFeature, removeChange.affectedFeature)	
		Assert.assertEquals(change.oldValue, removeChange.oldValue)	
	}
	
	def private static <T> T assertIsInstanceOf(EChange change, Class<T> type) {
		Assert.assertTrue(type.isInstance(change))
		return type.cast(change)
	}
}