/**
 * A collection of globally available constants
 * and static methods.
 */
public class Globals
{
	// The four "constants" below may be changed by data in the input file.

	/** The number of milliseconds to wait for a lock before a timeout is declared */
	public static long TIMEOUT_INTERVAL = 0; // Timeouts disabled
	/** Whether or not to use edge chasing to detect deadlocks */
	public static boolean PROBING_ENABLED = true;
	/** The number of local resources on each server */
	public static int NOF_RESOURCES_PER_SERVER = 10;
	/** The file to write output to (a suffix describing server ID will be added) */
	public static String OUTPUT_FILE_PREFIX = "output";

	/** The maximum number of transactions any server may execute */
	public static final int MAX_NOF_TRANSACTIONS_PER_SERVER = 1000;
	/** The minimum number of resources involved in any transaction */
	public static final int MIN_NOF_ACCESSES_PER_TRANSACTION = 3;
	/** The maximum number of resources involved in any transaction */
	public static final int MAX_NOF_ACCESSES_PER_TRANSACTION = 10;
	/** The maximum time spent processing a resource during a transaction */
	public static final long MAX_PROCESSING_TIME = 100;
	/** The minimum time spent processing a resource during a transaction */
	public static final long MIN_PROCESSING_TIME = 20;
	/** The maximum interval between the end of a transaction and the arrival of a new one at a server */
	public static final long MAX_ARRIVAL_WAIT = 300;
	/** The minimum interval between the end of a transaction and the arrival of a new one at a server */
	public static final long MIN_ARRIVAL_WAIT = 50;

	/**
	 * Returns a random integer number in the range [min, max].
	 * @param min	The lower bound of the range interval.
	 * @param max	The upper bound of the range interval.
	 * @return		A random integer number in the range [min, max].
	 */
	public static int random(int min, int max) {
		return min+(int)(Math.random()*(max-min+1));
	}

	/**
	 * Returns a random long integer number in the range [min, max].
	 * @param min	The lower bound of the range interval.
	 * @param max	The upper bound of the range interval.
	 * @return		A random long integer number in the range [min, max].
	 */
	public static long random(long min, long max) {
		return min+(long)(Math.random()*(max-min+1));
	}

	/**
	 * Sleeps a random amount of time in the range [min, max] milliseconds.
	 * @param min	The lower bound of the range interval.
	 * @param max	The upper bound of the range interval.
	 */
	public static void randomSleep(long min, long max) {
		try	{
			Thread.sleep(random(min, max));
		} catch (InterruptedException ie) {}
	}
}
