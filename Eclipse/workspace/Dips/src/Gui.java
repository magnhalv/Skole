import java.awt.BorderLayout;
import java.awt.GridBagLayout;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;

import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JTextField;
import javax.swing.WindowConstants;

/*
 * Simple GUI that takes text as input, and convert the text
 * using the Converter class. 
 */

public class Gui implements ActionListener {
	
	JFrame frame;
	JTextField text_field;
	JButton button;
	Converter converter;
	
	public Gui () {
		converter = new Converter();
		frame = new JFrame();
		text_field = new JTextField("Insert text.", 20);
		button = new JButton("Convert");
		button.addActionListener(this);
		frame.add(text_field, BorderLayout.CENTER);
		frame.add(button, BorderLayout.EAST);
		frame.setSize(400, 70);
		frame.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
		frame.setVisible(true);
		
	}
	
	@Override
	public void actionPerformed(ActionEvent arg0) {
		text_field.setText(converter.convert(text_field.getText()));
		
	}

	public static void main(String[] args) {
		//TestConverter tester = new TestConverter();
		//tester.run_test();
		Gui gui = new Gui();
	}
}

