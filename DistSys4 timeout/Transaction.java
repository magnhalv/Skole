import java.rmi.*;
import java.util.*;
import java.io.*;

/**
 * A transaction in the distributed transaction system.
 * A transaction consists of a series of accesses to resources in the distributed
 * system. Two-phase locking is used. Which and how many resources to access is determined
 * randomly or by the data in the input file, if such a file is specified.
 */
public class Transaction
{
	/** The ID of this transaction */
	private int transactionId;
	/** The server executing this transaction */
	private ServerImpl owner;
	/** The resources currently locked by this transaction */
	private ArrayList lockedResources;
	/** Signalling variable used to exchange messages between different threads operating on this transaction */
	private boolean abortTransaction;
	/** The resource whose lock this transaction is currently waiting for */
	private LockedResource waitingForResource;
	/** The transaction file reader whose input specifies the contents of this transaction */
	private TransactionFileReader input;
	/** Set to true if transactions aborts due to timeout */
	private boolean timeout;
	/** Resources that needs to be reacquired after a temporary abort. */
	private ArrayList locksToBeReclaimed;
	
	private boolean reclaimLocks;

	/**
	 * Creates a new transaction object.
	 * @param transactionId		The ID of the transaction.
	 * @param owner				The server executing this transaction.
	 * @param input				The input file reader specifying the contents of this transaction.
	 *							If this parameter is null, the transaction is performed randomly.
	 */
  	public Transaction(int transactionId, ServerImpl owner, TransactionFileReader input) {
		this.transactionId = transactionId;
		this.owner = owner;
		this.input = input;
		waitingForResource = null;
		timeout = false;
	}

	/**
	 * Gets the ID of this transaction.
	 * @return	The ID of this transaction.
	 */
	public int getId() {
		return transactionId;
	}

	/**
	 * Executes this transaction. This method blocks the calling thread
	 * until the transaction has completed, which may take a while.
	 * @return	Whether or not the transaction was able to commit.
	 */
	public boolean runTransaction() {
		abortTransaction = false;
		lockedResources = new ArrayList();
		locksToBeReclaimed = new ArrayList();
		owner.println("Starting transaction "+transactionId+".", transactionId); 

		// Figure out how many resource accesses the transaction consists of.
		int nofAccesses = Globals.random(Globals.MIN_NOF_ACCESSES_PER_TRANSACTION, Globals.MAX_NOF_ACCESSES_PER_TRANSACTION);
		if(input != null) {
			// Read the number of accesses from the input file instead.
			// Expected format: NUMBER OF ACCESSES: 7
			String line = input.readLine();
			if(line == null || !line.startsWith("NUMBER OF ACCESSES: "))
				owner.unexpectedInput();
			else
				nofAccesses = new Integer(line.substring(20)).intValue();
		}
		
		// Perform the accesses
		for(int i = 0; i < nofAccesses; i++) {
			if (reclaimLocks) {
				acquireLock((LockedResource) locksToBeReclaimed.get(i));
				if (i == locksToBeReclaimed.size()-1) reclaimLocks = false;
			}
			else {
				LockedResource nextResource = getNextResource();
				//Add resource to array, in case of abort - so it can be reclaimed later.
				locksToBeReclaimed.add(nextResource);
				acquireLock(nextResource);
			}
			if(abortTransaction) {
				// Transaction should abort due to a communication failure
				abort();
				return false;
			}
			else if (timeout) {
				reclaimLocks = true;
				timeout = false;
				i = 0;
				owner.println("Transaction aborted due to timeout. Will retry in 100 milis");
				try {
					Thread.sleep(100);
				} catch (InterruptedException e) {
					// TODO Auto-generated catch block
					e.printStackTrace();
				}
			}
			else {
				owner.println("Lock claimed. Processing...", transactionId);
				processResource();
			}
		}
		commit();
		return true;
	}


	/**
	 * Processes a resource that the transaction has acquired the lock to.
	 * No actual processing is done, but some milliseconds are spent sleeping
	 * to simulate the processing.
	 */
	private void processResource() {
		// Figure out how long to "process" the resource:
		if(input == null)
			Globals.randomSleep(Globals.MIN_PROCESSING_TIME, Globals.MAX_PROCESSING_TIME);
		else {
			// Read the processing time from the input file.
			// The line should be on the format PROCESS 50-200 (signifying a processing time between 50 and 200 ms).
			String line = input.readLine();
			if(line == null || !line.startsWith("PROCESS "))
				owner.unexpectedInput();
			else {
				StringTokenizer st = new StringTokenizer(line.substring(8),"-");
				long min = new Long(st.nextToken()).longValue();
				if(!st.hasMoreTokens())
					owner.unexpectedInput();
				else {
					long max = new Long(st.nextToken()).longValue();
					Globals.randomSleep(min, max);
				}
			}
		}
	}

	/**
	 * Figure out what resource the transaction should access next.
	 * @return	The next resource that the transaction should try to access.
	 */
	private LockedResource getNextResource() {
		if(input == null)
			return owner.getRandomResource(lockedResources);
		else {
			// Read the next resource to be accessed from the input file
			// Expected format: ACCESS SERVER 1 RESOURCE 5 
			String line = input.readLine();
			if(line == null || !line.startsWith("ACCESS SERVER "))
				owner.unexpectedInput();
			line = line.substring(14);
			StringTokenizer st = new StringTokenizer(line, " RESOURCE ");
			int serverId = new Integer(st.nextToken()).intValue();
			if(!st.hasMoreTokens())
				owner.unexpectedInput();
			int resourceId = new Integer(st.nextToken()).intValue();
			return new LockedResource(owner.getServer(serverId), serverId, resourceId);
		}
	}

	/**
	 * Attempts to acquire the lock of the specified resource. Blocks until the
	 * lock has been acquired.
	 * @param resource	The resource whose lock should be acquired.
	 */
	public void acquireLock(LockedResource resource) {
		waitingForResource = resource;
		owner.println("Trying to claim lock of resource "+resource.resourceId+" at server "+resource.locationId, transactionId);
		try {
			if(resource.location.lockResource(transactionId, resource.resourceId)) {
				lockAcquired(resource);
			}
			else {
				timeout = true;
				//owner.println("We didn't get the lock we wanted! How can that happen?");
			}
		} catch(RemoteException re) {
			lostContact(resource);
		}
	}

	/**
	 * Called when the lock of the specified resource has been acquired.
	 * @param resource	The resource whose lock was acquired.
	 */
	private synchronized void lockAcquired(LockedResource resource) {
		lockedResources.add(resource);
		waitingForResource = null;
	}

	/**
	 * Called when the transaction lost contact with a server waiting for the lock of a resource on that server.
	 * @param resource	The resource whose lock the transaction was waiting for.
	 */
	private synchronized void lostContact(LockedResource resource) {
		waitingForResource = null;
		owner.lostContactWithServer(resource.locationId);
		abortTransaction = true;
	}

	/**
	 * Aborts this transaction, releasing all the locks held by it.
	 */
	private synchronized void abort() {
		owner.println("Aborting transaction "+transactionId+".", transactionId);
		releaseLocks();
		owner.println("Transaction "+transactionId+" aborted.", transactionId);
	}

	/**
	 * Commits this transaction, releasing all the locks held by it.
	 */
	private synchronized void commit() {
		owner.println("Committing transaction "+transactionId+".", transactionId);
		releaseLocks();
		owner.println("Transaction "+transactionId+" committed.", transactionId);
	}

	/**
	 * Called by the server executing this transaction whenever a server in the distributed
	 * system has disconnected. If the transaction is accessing any resources on the server
	 * that disconnected, the transaction aborts.
	 * @param serverId	The ID of the server that disconnected.
	 */
	public synchronized void serverDisconnected(int serverId) {
		if(lockedResources != null) {
			for(int i = 0; i < lockedResources.size(); i++) {
				if(((LockedResource)lockedResources.get(i)).locationId == serverId) {
					owner.println("Contact was lost with a server hosting a resource involved in transaction "+transactionId+". Transaction must abort.", transactionId);
					abortTransaction = true;
					return;
				}
			}
		}
	}

	/**
	 * Releases all locks held by this transaction, in the reverse order of the order they were acquired in.
	 */
	private synchronized void releaseLocks() {
		while(lockedResources.size() > 0) {
			LockedResource lr = (LockedResource)lockedResources.remove(lockedResources.size()-1);
			releaseLock(lr);
		}
		if(input != null) {
			// Scan to the end of this transaction in the input file
			String line = input.readLine();
			while(!line.equals("END OF TRANSACTION"))
				line = input.readLine();
		}
	}


	/**
	 * Releases the lock to the specified resource being held by this transaction.
	 * @param resource	The resource whose lock should be released.
	 */
	private void releaseLock(LockedResource resource) {
		try {
			if(resource.location.releaseLock(transactionId, resource.resourceId)) {
				owner.println("Unlocked resource "+resource.resourceId+" at server "+resource.locationId, transactionId);
			} else {
				owner.println("Failed to unlock resource "+resource.resourceId+" at server "+resource.locationId, transactionId);
			}
		}
		catch(RemoteException re) {
			owner.println("Failed to unlock resource "+resource.resourceId+" at server "+resource.locationId+" due to communication failure.", transactionId);
		}
	}
}
