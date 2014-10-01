import javax.swing.*;
import javax.swing.event.ListSelectionEvent;
import javax.swing.event.ListSelectionListener;
import javax.swing.table.DefaultTableCellRenderer;
import java.awt.*;
import java.lang.invoke.MethodHandles.Lookup;
import java.rmi.Naming;
import java.rmi.RemoteException;

/**
 * A Tic Tac Toe application.
 * Currently this is a stand-alone application where
 * players take alternating turns using the same computer.
 *
 * The task is to transform it to a networking application using RMI.
 */
public class TicTacToe extends JFrame implements ListSelectionListener
{
    private static final int BOARD_SIZE = 15;
    private final BoardModel boardModel;
    private final JTable board;
    private final JLabel statusLabel = new JLabel();
    private final char playerMarks[] = { 'X', 'O' };
    private int player_number;
    private int currentPlayer= 0; // Player to set the next mark.
    private TicTacToeRemote this_player;

    public static void main(String args[])
    {
        new TicTacToe(args[0], args[1]);
    }

    public TicTacToe(String address, String isServer)
    {
        super("TDT4190: Tic Tac Toe");

        boardModel = new BoardModel(BOARD_SIZE);
        board = new JTable(boardModel);
        board.setFont(board.getFont().deriveFont(25.0f));
        board.setRowHeight(30);
        board.setCellSelectionEnabled(true);
        for (int i = 0; i < board.getColumnCount(); i++)
            board.getColumnModel().getColumn(i).setPreferredWidth(30);
        board.setGridColor(Color.BLACK);
        board.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        DefaultTableCellRenderer dtcl= new DefaultTableCellRenderer();
        dtcl.setHorizontalAlignment(SwingConstants.CENTER);
        board.setDefaultRenderer(Object.class, dtcl);
        board.getSelectionModel().addListSelectionListener(this);
        board.getColumnModel().getSelectionModel().addListSelectionListener(this);

        statusLabel.setPreferredSize(new Dimension(statusLabel.getPreferredSize().width, 40));
        statusLabel.setHorizontalAlignment(SwingConstants.CENTER);

        Container contentPane = getContentPane();
        contentPane.setLayout(new BorderLayout());
        contentPane.add(board, BorderLayout.CENTER);
        contentPane.add(statusLabel, BorderLayout.SOUTH);
        pack();

        setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);

        int centerX = (int)(Toolkit.getDefaultToolkit().getScreenSize().getWidth() - getSize().width) / 2;
        int centerY = (int)(Toolkit.getDefaultToolkit().getScreenSize().getHeight() - getSize().height) / 2;
        setLocation(centerX, centerY);
        setVisible(true);
        
        String url= "rmi://" + address + "/TicTacToe";
        
        
        
        if (isServer.equals("yes")) {
        	try {
        		player_number = 0;
        		this_player = new TicTacToeRemoteImp(this);
        		setStatusMessage("Trying to set up server.");
        		Naming.bind(url, this_player);
        		setStatusMessage("Server online.");
        	}
        	catch (Exception e) {
        		setStatusMessage("Failed to initialize server");
        	}
        }
        else {
    		try {
    			player_number = 1;
    			this_player = new TicTacToeRemoteImp(this);
    			setStatusMessage("Trying join server.");
    			((TicTacToeRemote)Naming.lookup(url)).joinGame(this_player);
    			setStatusMessage("Connected to server.");
    		} catch (Exception e2) {
    			setStatusMessage("Could not connect to server!");
    		}

        }
    }

    void setStatusMessage(String status)
    {
        statusLabel.setText(status);
    }

    /**
     * This has to be modified. Currently the application is stand-alone so
     * both players have to use the same computer.
     *
     * When completed, marks from the first player originates from a ListSelectionEvent
     * and is then sent to the second player. And marks from the second player is received
     * and added to the board of the first player.
     */
    public void valueChanged(ListSelectionEvent e)
    {
    	setStatusMessage("VALUE CHANGED");
        if (e.getValueIsAdjusting())
            return;
        int x = board.getSelectedColumn();
        int y = board.getSelectedRow();
        if (x == -1 || y == -1 || !boardModel.isEmpty(x, y) || currentPlayer != player_number) {
        	return;
        }
        if (boardModel.setCell(x, y, playerMarks[player_number]))
            setStatusMessage("Player " + playerMarks[player_number] + " won!");
        try {
			this_player.reportMove(x, y, playerMarks[player_number]);
		} catch (RemoteException e1) {
			// TODO Auto-generated catch block
			e1.printStackTrace();
		}
        currentPlayer= 1 - currentPlayer; // The next turn is by the other player.
    }
    
    public void setCell(int x, int y, char mark) {
    	 if (boardModel.setCell(x, y, playerMarks[1 - player_number]))
             setStatusMessage("Player " + playerMarks[1 - player_number] + " won!");
    	 currentPlayer= 1 - currentPlayer;
    }
    
    public int getPlayerNumber () {
    	return player_number;
    }
}
