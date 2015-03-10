import java.rmi.*;
import java.rmi.server.*;
import java.rmi.registry.*;
import java.io.*;

public class StartRegistry
{
	/**
	 * Starts up a new RMI registry on the local host, and binds a RegistryProxy object to it.
	 * The RegistryProxy object offers the same functionality as the registry itself, except
	 * it also allows non-local objects to bind to it.
	 *
	 * @param args	Command line parameters, the first parameter specifies the port of the RMI registry.
	 */
	public static void main(String[] args) {
		if(args.length > 0) {
			try	{
				Registry r = LocateRegistry.createRegistry(new Integer(args[0]).intValue());
				r.bind("RegistryProxy", new RegistryProxyImpl());
				System.out.println("RMI registry is now running on port "+args[0]+".");
			}
			catch (Exception re) {
				re.printStackTrace();
			}
		}
		else {
			System.out.println("You must specify a port number for this registry!");
			System.out.println("Every group has exclusive rights to port numbers");
			System.out.println("[3000+n*10, 3009+n*10] where n is your group number.");
		}
	}
}
