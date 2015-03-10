import java.rmi.RemoteException;
import java.rmi.server.UnicastRemoteObject;


public class TicTacToeRemoteImp extends UnicastRemoteObject implements TicTacToeRemote {
	
	private TicTacToe local_player;
	private TicTacToeRemote other_player;
	
	public TicTacToeRemoteImp (TicTacToe local_player) throws RemoteException {
		this.local_player = local_player;
	}

	@Override
	public void joinGame(TicTacToeRemote other_player) throws RemoteException {
		this.other_player = other_player;
		//local_player.setStatusMessage("Other player connected!");
		if (local_player.getPlayerNumber() == 0) {
			other_player.joinGame((TicTacToeRemote)this);
		}
	}

	@Override
	public void setMark(int x, int y, char mark) throws RemoteException {
		local_player.setCell(x, y, mark);	
	}
	
	public void reportMove(int x, int y, char mark) throws RemoteException {
		other_player.setMark(x, y, mark);
	}
	
	
}
