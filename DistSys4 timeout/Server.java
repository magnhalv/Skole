import java.rmi.*;
import java.util.*;

/**
 * Remote interface specifying the functionality
 * of a server in the distributed transaction system.
 */
public interface Server extends Remote {
	/**
	 * Get the unique ID of this server.
	 * @return	The ID of this server.
	 */
	public int getServerId() throws RemoteException;

	/**
	 * Called to notify this server that a new server has connected to the system.
	 * @param s	The server that arrived.
	 */
	public void newServerConnected(Server s) throws RemoteException;

	/**
	 * Called to notify this server that a server has disconnected from the system.
	 * @param disconnectedId	The ID of the server that left.
	 * @param messengerId		The ID of the server that first discovered that that server had left.
	 */
	public void serverDisconnected(int disconnectedId, int messengerId) throws RemoteException;

	/**
	 * Asks this server to give the lock of a local resource to the specified transaction.
	 * This method blocks until the lock has been acquired.
	 * @param lockerId			The ID of the transaction that wants the lock.
	 * @param resourceID		The ID of the resource whose lock the transaction wants.
	 * @return	Whether or not the lock was acquired.
	 */
	public boolean lockResource(int lockerId, int resourceId) throws RemoteException;

	/**
	 * Asks this server to release the lock of a local resource currently locked by the specified transaction.
	 * @param lockerId			The ID of the transaction that owns the lock and wants to release it.
	 * @param resourceID		The ID of the resource whose lock the transaction wants to release.
	 * @return	Whether or not the lock could be released.
	 */
	public boolean releaseLock(int lockerId, int resourceId) throws RemoteException;

	/**
	 * Gets the current owner of the lock of a local resource.
	 * @param resourceID	The ID of the resource in question.
	 * @return				An Integer containing the ID of the lock owner, or null if the resource is unlocked.
	 */
	public Integer getLockOwner(int resourceId) throws RemoteException;

	/**
	 * Called by another server to ask this server to start its transactions.
	 */
	public void startTransactions() throws RemoteException;
}
