import static org.junit.Assert.assertEquals;

import org.junit.Test;

/*
 * Test class for the converter. 
 */

public class TestConverter {
	
	@Test
	public void run_test () {
		Converter converter = new Converter();
		
		assertEquals("4 enheter om dagen", converter.convert("4"));
		assertEquals("2 enheter morgen, 2 enheter kveld", converter.convert("2+2"));
		assertEquals("1 enheter morgen, 2 enheter formiddag, 3 enheter kveld", converter.convert("1+2+3"));
		assertEquals("2 enheter 3 ganger om dagen", converter.convert("2*3"));
		assertEquals("2*3*3", converter.convert("2*3*3"));
		assertEquals("Denne setningen skal ikke endres.", converter.convert("Denne setningen skal ikke endres."));
	}
}
