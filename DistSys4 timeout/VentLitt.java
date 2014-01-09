public class VentLitt
{
	public static void main(String[] args) {
		long wait = 100;
		if(args.length > 0)
			wait = new Long(args[0]).longValue();
		try	{
			Thread.sleep(wait);
		} catch (InterruptedException ie)	{}
	}
}
