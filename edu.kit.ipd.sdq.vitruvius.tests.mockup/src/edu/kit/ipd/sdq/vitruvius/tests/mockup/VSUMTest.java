package edu.kit.ipd.sdq.vitruvius.tests.mockup;

import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertTrue;

import java.io.IOException;
import java.util.Collections;
import java.util.Iterator;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.junit.Test;

import pcm_mockup.Component;
import pcm_mockup.Interface;
import pcm_mockup.Pcm_mockupFactory;
import pcm_mockup.Repository;
import edu.kit.ipd.sdq.vitruvius.framework.contracts.datatypes.ModelInstance;
import edu.kit.ipd.sdq.vitruvius.framework.contracts.datatypes.VURI;
import edu.kit.ipd.sdq.vitruvius.framework.metarepository.MetaRepositoryImpl;
import edu.kit.ipd.sdq.vitruvius.framework.vsum.VSUMImpl;
import edu.kit.ipd.sdq.vitruvius.tests.util.TestUtil;

public class VSUMTest extends MetaRepositoryTest {
    protected static final String PCM_INSTANCE_URI = "MockupProject/model/My.pcm_mockup";
    protected static final String UML_INSTANCE_URI = "MockupProject/model/My.uml_mockup";
    private static final String PCM_INSTANCE_TO_CREATE_URI = TestUtil.PROJECT_URI + "/model/NewPCMInstance.pcm_mockup";

    @Override
    @Test
    public void testAll() {
        testMetaRepositoryVSUMAndModelInstancesCreation();
    }

    @Test
    public void testVSUMAddGetChangeAndSaveModel() {
        // create VSUM
        VSUMImpl vsum = this.testMetaRepositoryAndVSUMCreation();

        // create test model
        VURI vuri = VURI.getInstance(PCM_INSTANCE_TO_CREATE_URI);
        ModelInstance mi = vsum.getAndLoadModelInstanceOriginal(vuri);
        Repository repo = Pcm_mockupFactory.eINSTANCE.createRepository();
        mi.getResource().getContents().clear();
        mi.getResource().getContents().add(repo);
        vsum.saveModelInstanceOriginal(vuri);
        Component component = Pcm_mockupFactory.eINSTANCE.createComponent();
        repo.getComponents().add(component);

        // save test model
        vsum.saveModelInstanceOriginal(vuri);

        // this is fine, the component is contained in the resource
        assertTrue("Resource of component is null", null != component.eResource());
        // causes a unload and a load of the model
        mi = vsum.getAndLoadModelInstanceOriginal(vuri);

        // not fine anymore: component is not contained in the resource and it is a proxy
        boolean isProxy = component.eIsProxy();
        Resource resource = component.eResource();
        // resolve the eObject in the new resource
        component = (Component) EcoreUtil.resolve(component, mi.getResource());
        isProxy = component.eIsProxy();
        resource = component.eResource();
        assertTrue("Resource of component is null", null != resource);
        assertTrue("Component is a proxy", !isProxy);

        assertTrue("Resource of model instance is null", null != mi.getResource());
    }

    @Test
    public void testVUMResourceIsChangedExternally() throws IOException {
        // same as above
        VSUMImpl vsum = this.testMetaRepositoryAndVSUMCreation();

        // create test model
        VURI vuri = VURI.getInstance(PCM_INSTANCE_TO_CREATE_URI);
        ModelInstance mi = vsum.getAndLoadModelInstanceOriginal(vuri);
        Repository repo = Pcm_mockupFactory.eINSTANCE.createRepository();
        mi.getResource().getContents().clear();
        mi.getResource().getContents().add(repo);
        Component component = Pcm_mockupFactory.eINSTANCE.createComponent();
        repo.getComponents().add(component);
        vsum.saveModelInstanceOriginal(vuri);
        // simulate external change
        changeTestModelExternally(vuri);

        // the interface should not be in the model instance (before the reload)
        Interface foundMockInterface = findInterfaceInModelInstance(mi);
        assertTrue("interface should not be in the model instance with uri: " + vuri.getEMFUri() + " and resource: "
                + mi.getResource(), null == foundMockInterface);

        // the interface should be in the model now.
        mi = vsum.getAndLoadModelInstanceOriginal(vuri);
        foundMockInterface = findInterfaceInModelInstance(mi);

        assertTrue(
                "no interface found in the model instance with uri: " + vuri.getEMFUri() + " and resource: "
                        + mi.getResource(), null != foundMockInterface);
    }

    @Test
    public void testLoadVSUMRepeadly() {
        VSUMImpl vsum = this.testMetaRepositoryAndVSUMCreation();

        VURI vuri = VURI.getInstance(PCM_INSTANCE_TO_CREATE_URI);
        ModelInstance mi = vsum.getAndLoadModelInstanceOriginal(vuri);
        Repository repo = Pcm_mockupFactory.eINSTANCE.createRepository();
        mi.getResource().getContents().clear();
        mi.getResource().getContents().add(repo);
        Component component = Pcm_mockupFactory.eINSTANCE.createComponent();
        repo.getComponents().add(component);
        vsum.saveModelInstanceOriginal(vuri);
        Interface mockIf = Pcm_mockupFactory.eINSTANCE.createInterface();
        repo.getInterfaces().add(mockIf);
        vsum.saveModelInstanceOriginal(vuri);
        ModelInstance interfaceMi = vsum.getAndLoadModelInstanceOriginal(mi.getURI());
        Interface foundInterface = findInterfaceInModelInstance(interfaceMi);
        assertTrue("The interface in " + foundInterface + " in the model instance: " + mi + " has no resource",
                null != foundInterface.eResource());

        ModelInstance compMi = vsum.getAndLoadModelInstanceOriginal(mi.getURI());
        Component foundComponent = findComponentInModelInstance(compMi);

        assertTrue("The component " + foundComponent + " in the model instance: " + mi + " has no resource",
                null != foundComponent.eResource());
        assertTrue("The interface " + foundInterface + " in the model instance: " + mi + " has no resource",
                null != foundInterface.eResource());

    }

    private Component findComponentInModelInstance(final ModelInstance compMi) {
        return findEObjectInModelInstance(compMi, Component.class);
    }

    private Interface findInterfaceInModelInstance(final ModelInstance mi) {
        return findEObjectInModelInstance(mi, Interface.class);
    }

    private <T> T findEObjectInModelInstance(final ModelInstance mi, final Class<T> classToLookFor) {
        Iterator<EObject> iterator = mi.getResource().getAllContents();
        while (iterator.hasNext()) {
            EObject eObject = iterator.next();
            if (classToLookFor.isInstance(eObject)) {
                return classToLookFor.cast(eObject);
            }
        }
        return null;
    }

    private void changeTestModelExternally(final VURI vuri) throws IOException {
        // simulate external change. For example a change that is done by a user.
        // in this case we add an interface to the resource.
        ResourceSet extResourceSet = new ResourceSetImpl();
        Resource extRes = extResourceSet.createResource(vuri.getEMFUri());
        extRes.load(Collections.EMPTY_MAP);
        Interface mockIf = Pcm_mockupFactory.eINSTANCE.createInterface();
        Repository repo = (Repository) extRes.getContents().get(0);
        repo.getInterfaces().add(mockIf);
        extRes.save(Collections.EMPTY_MAP);
    }

    protected VSUMImpl testMetaRepositoryVSUMAndModelInstancesCreation() {
        VSUMImpl vsum = testMetaRepositoryAndVSUMCreation();
        testInstanceCreation(vsum);
        return vsum;
    }

    protected VSUMImpl testMetaRepositoryAndVSUMCreation() {
        return testMetaRepositoryAndVSUMCreation(PCM_MM_URI, PCM_FILE_EXT, UML_MM_URI, UML_FILE_EXT);
    }

    private VSUMImpl testMetaRepositoryAndVSUMCreation(final String mm1URIString, final String fileExt1,
            final String mm2URIString, final String fileExt2) {
        MetaRepositoryImpl metaRepository = testMetaRepository();
        testAddMapping(metaRepository, mm1URIString, fileExt1, mm2URIString, fileExt2);
        return testVSUMCreation(metaRepository);
    }

    protected VSUMImpl testVSUMCreation(final MetaRepositoryImpl metaRepository) {
        VSUMImpl vsum = TestUtil.createVSUM(metaRepository);
        return vsum;
    }

    protected void testInstanceCreation(final VSUMImpl vsum) {
        testInstanceCreation(PCM_INSTANCE_URI, UML_INSTANCE_URI, vsum);
    }

    private void testInstanceCreation(final String model1URIString, final String model2URIString, final VSUMImpl vsum) {
        VURI model1URI = VURI.getInstance(model1URIString);
        VURI model2URI = VURI.getInstance(model2URIString);
        ModelInstance model1 = vsum.getAndLoadModelInstanceOriginal(model1URI);
        ModelInstance model2 = vsum.getAndLoadModelInstanceOriginal(model2URI);
        EList<EObject> contents1 = model1.getResource().getContents();
        assertNotNull(contents1);
        EObject root1 = contents1.get(0);
        assertNotNull(root1);
        EList<EObject> contents2 = model2.getResource().getContents();
        assertNotNull(contents2);
        EObject root2 = contents2.get(0);
        assertNotNull(root2);
    }
}
