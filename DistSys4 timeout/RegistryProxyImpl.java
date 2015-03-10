import java.rmi.*;
import java.rmi.server.*;
import java.rmi.registry.*;
import java.util.*;

/**
 * This class provides the same functionality as an RMI registry. Instances of this class
 * may be bound to an RMI registry and serve as a middle-man. The reason this is useful is
 * that an RMI registry doesn't allow non-local objects to bind to it, whereas instances of
 * this class do.
 */
public class RegistryProxyImpl extends UnicastRemoteObject implements RegistryProxy
{
	/** A hash table used to store remote object references to objects that are "bound" to this "registry" */
	private Hashtable objects;

  	public RegistryProxyImpl() throws RemoteException {
		objects = new Hashtable();
	}

	public synchronized void bind(String name, Remote object) throws RemoteException, AlreadyBoundException {
		if(objects.get(name) != null)
			throw new AlreadyBoundException();
		else
			objects.put(name, object);
	}
	
	public synchronized Remote lookup(String name) throws RemoteException, NotBoundException {
		Remote obj = (Remote)objects.get(name);
		if(obj == null)
			throw new NotBoundException();
		else
			return obj;
	}

	public synchronized void unbind(String name) throws RemoteException, NotBoundException {
		if(!objects.containsKey(name))
			throw new NotBoundException();
		else
			objects.remove(name);
	}

	public synchronized void rebind(String name, Remote object) throws RemoteException {
		objects.put(name, object);
	}
	
	public synchronized String[] list() throws RemoteException {
		Set keySet = objects.keySet();
		String[] result = new String[keySet.size()];
		int c = 0;
		for(Iterator i = keySet.iterator(); i.hasNext(); c++)
			result[c] = (String)i.next();
		return result;
	}
}
