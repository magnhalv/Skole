import java.rmi.*;
import java.rmi.server.*;
import java.rmi.registry.*;

/**
 * This interface specifies the functionality implemented by the RegistryProxyImpl class.
 * @see RegistryProxyImpl
 */
public interface RegistryProxy extends Remote
{
	public void bind(String name, Remote object) throws RemoteException, AlreadyBoundException;

	public void unbind(String name) throws RemoteException, NotBoundException;

	public Remote lookup(String name) throws RemoteException, NotBoundException;

	public void rebind(String name, Remote object) throws RemoteException;

	public String[] list() throws RemoteException;
}
