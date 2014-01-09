import java.awt.*;
import javax.swing.*;

/**
 * A component used to output textual information.
 */
public class OutputArea extends JPanel
{
	/** The headline of this output area */
	private JLabel headline;
	/** TextArea containing outputted information */
	private TextArea textArea;

	/**
	 * Creates a new output area.
	 * @param title		The headline of the area.
	 */
	public OutputArea(String title) {
		headline = new JLabel(title);
		textArea = new TextArea();
		setLayout(new BorderLayout());
		add(headline, BorderLayout.NORTH);
		add(textArea, BorderLayout.CENTER);
	}

	/**
	 * Outputs a text string, with a newline added at the end, to this output area.
	 * @param s		The information to display.
	 */
	public void println(String s) {
		print(s+"\n");
	}

	/**
	 * Outputs a text string to this output area.
	 * @param s		The information to display.
	 */
	public void print(String s) {
		textArea.append(s);
	}
}
