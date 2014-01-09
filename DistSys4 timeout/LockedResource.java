/**
 * Data structure describing the location
 * and ID of a resource in the distributed
 * transaction system.
 */
public class LockedResource
{
	/** The server where the resource is located */
	public Server location;
	/** The ID of the server where the resource is located */
	public int locationId;
	/** The ID of the resource */
	public int resourceId;

	/**
	 * Creates a new LockedResource object.
	 * @param location		The server where the resource is located.
	 * @param locationId	The ID of the server where the resource is located.
	 * @param resourceId	The ID of the resource.
	 */
	public LockedResource(Server location, int locationId, int resourceId) {
		this.location = location;
		this.locationId = locationId;
		this.resourceId = resourceId;
	}

	/**
	 * Checks whether or not two LockedResource objects represent the same resource.
	 * @param o		The LockedResource to compare this LockedResource with.
	 * @return		Whether or not the two objects represent the same resource.
	 */
	public boolean equals(Object o) {
		LockedResource lr = (LockedResource) o;
		return (lr.resourceId == resourceId && lr.locationId == locationId);
	}
}
