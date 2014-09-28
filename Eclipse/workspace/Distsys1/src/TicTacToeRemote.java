import java.rmi.Remote;
import java.rmi.RemoteException;


public interface TicTacToeRemote extends Remote {
	
	public void joinGame (TicTacToeRemote other_player) throws RemoteException;
	
	public void setMark (int x, int y, char mark) throws RemoteException;
	
	public void reportMove(int x, int y, char mark) throws RemoteException;
	
}
