import java.util.regex.Pattern;

/*
 * This solution is based on the assumption that the 
 * input numbers could be larger than 9 (E.g.
 * 123*3.). Thus making regexes the simplest way to solve it. 
 */


public class Converter {
	
	private Pattern f_one;
	private Pattern f_two;
	private Pattern f_three;
	private Pattern f_four;
	
	//Regexes for the different valid formats. 
	private final String format_one = "[0-9]+\\z";
	private final String format_two = "[0-9]+\\+[0-9]+\\z";
	private final String format_three = "[0-9]+\\+[0-9]+\\+[0-9]+\\z";
	private final String format_four = "[0-9]+\\*[0-9]+\\z";
	
	public Converter () {
		//Must compile the regexes.
		f_one = Pattern.compile(format_one);
		f_two = Pattern.compile(format_two);
		f_three = Pattern.compile(format_three);
		f_four = Pattern.compile(format_four);
		
	}
	/**
	 * 
	 * @param Simple formated string for prescription.
	 * @return A string that provides a more readable format for prescription. Or a copy of the input string if the
	 * format is invalid. 
	 */
	public String convert (String text) {
		
		//Match the regexes with the input string. The longest regexes must be checked first. 
		if(f_three.matcher(text).matches()){
			return text.charAt(0) + " enheter morgen, " + text.charAt(2) + " enheter formiddag, " 
					+ text.charAt(4) + " enheter kveld";
		}
		else if (f_two.matcher(text).matches()){
			return text.charAt(0) + " enheter morgen, " + text.charAt(2) + " enheter kveld";
		}
		else if (f_four.matcher(text).matches()){
			return text.charAt(0) + " enheter " + text.charAt(2) + " ganger om dagen";
		}
		else if (f_one.matcher(text).matches())  {
			return text.charAt(0) + " enheter om dagen";
		}
		//If all fail, return input string. 
		else return text;
		
	}
}


