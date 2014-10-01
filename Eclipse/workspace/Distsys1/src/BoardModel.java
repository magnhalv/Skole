import javax.swing.event.TableModelEvent;
import javax.swing.event.TableModelListener;
import javax.swing.table.TableModel;
import java.util.ArrayList;
import java.util.List;

/**
 *  This class contains the board data represented as a two dimensional
 *  array of Cell. Each Cell can contain a single char (e.g. X or O).
 */
final class BoardModel implements TableModel
{
    private final Cell boardCells[][];
    private final List<TableModelListener> listeners = new ArrayList<TableModelListener>();

    BoardModel(int boardSize)
    {
        boardCells = new Cell[boardSize][];
        for (int x = 0; x < boardSize; x++) {
            boardCells[x] = new Cell[boardSize];
            for (int y = 0; y < boardSize; y++)
                boardCells[x][y] = new Cell();
        }

    }

    /**
     * Does (x,y) have a mark already?
     * @param x X coordinate of cell to check
     * @param y Y coordinate of cell to check
     * @return true if the cell is empty, otherwise false.
     */
    boolean isEmpty(int x, int y)
    {
        return boardCells[x][y].isEmpty();
    }

    /**
     * Set a cell to contain a given mark and return true of this gives 5 in a row.
     * @param x X coordinate of cell to update
     * @param y Y coordinate of cell to update
     * @param mark Mark to assign to (x,y)
     * @return true if the new mark resulted in 5 in a row, false otherwise.
     */
    boolean setCell(int x, int y, char mark)
    {
        boardCells[x][y].setContents(mark);
        TableModelEvent event = new TableModelEvent(this, y, y, x);
        for (TableModelListener listener : listeners)
            listener.tableChanged(event);

        // Check if this new mark gave 5 in a row
        return checkHorizontal(x, y) || checkVertical(x, y) || checkDiagonalUp(x, y) || checkDiagonalDown(x, y);
    }

    /**
     *  Check if (x,y) is part of a horizontal 5 in a row.
     *  @param x X coordinate of cell to check
     *  @param y Y coordinate of cell to check
     *  @return true if there are 5 in a row including (x,y)
     */
    private boolean checkHorizontal(int x, int y)
    {
        // Find the minimum and maximum x values for this y which have the same mark
        int minX= x;
        while (minX > 0 && boardCells[minX-1][y].equals(boardCells[x][y]))
            minX--;
        int maxX= x;
        while ((maxX+1) < boardCells.length && boardCells[maxX+1][y].equals(boardCells[x][y]))
            maxX++;
        // If the difference is larger than 4, we have 5 in a row
        return maxX - minX >= 4;
    }

    /**
     *  Check if (x,y) is part of a vertical 5 in a row.
     *  @param x X coordinate of cell to check
     *  @param y Y coordinate of cell to check
     *  @return true if there are 5 in a row including (x,y)
     */
    private boolean checkVertical(int x, int y)
    {
        // Find the minimum and maximum y values for this x which have the same mark
        int minY= y;
        while (minY > 0 && boardCells[x][minY-1].equals(boardCells[x][y]))
            minY--;
        int maxY= y;
        while ((maxY+1) < boardCells.length && boardCells[x][maxY+1].equals(boardCells[x][y]))
            maxY++;
        // If the difference is larger than 4, we have 5 in a row
        return maxY - minY >= 4;

    }

    /**
     *  Check if (x,y) is part of a diagonal 5 in a row. Only checks
     *  diagonals going from bottom left to upper right.
     *  @param x X coordinate of cell to check
     *  @param y Y coordinate of cell to check
     *  @return true if there are 5 in a row including (x,y)
     */
    private boolean checkDiagonalUp(int x, int y)
    {
        // Find the minimum and maximum x and y values which have the same mark
        int minX= x;
        int minY= y;
        while (minX > 0 && minY > 0 && boardCells[minX-1][minY-1].equals(boardCells[x][y])) {
            minX--;
            minY--;
        }
        int maxX= x;
        int maxY= y;
        while ((maxX+1) < boardCells.length && (maxY+1) < boardCells.length &&
                boardCells[maxX+1][maxY+1].equals(boardCells[x][y])) {
            maxX++;
            maxY++;
        }
        // If the difference is larger than 4, we have 5 in a row
        // We only have to check X (or Y) as the difference is the same for both
        return maxX - minX >= 4;
    }

    /**
     *  Check if (x,y) is part of a diagonal 5 in a row. Only checks
     *  diagonals going from upper left to bottom right.
     *  @param x X coordinate of cell to check
     *  @param y Y coordinate of cell to check
     *  @return true if there are 5 in a row including (x,y)
     */
    private boolean checkDiagonalDown(int x, int y)
    {
        // Find the minimum and maximum x and y values which have the same mark
        int minX= x;
        int maxY= y;
        while (minX > 0 && (maxY+1) < boardCells.length &&
                boardCells[minX-1][maxY+1].equals(boardCells[x][y])) {
            minX--;
            maxY++;
        }
        int maxX= x;
        int minY= y;
        while ((maxX+1) < boardCells.length && minY < 0 &&
                boardCells[maxX+1][minY-1].equals(boardCells[x][y])) {
            maxX++;
            minY--;
        }
        // If the difference is larger than 4, we have 5 in a row
        // We only have to check X (or Y) as the difference is the same for both
        return maxX - minX >= 4;
    }

    // Below is the implementation of the TableModel interface.

    public int getRowCount()
    {
        return boardCells.length;
    }

    public int getColumnCount()
    {
        return boardCells.length;
    }

    public String getColumnName(int columnIndex)
    {
        return String.valueOf(columnIndex + 1);
    }

    public Class<?> getColumnClass(int columnIndex)
    {
        return Object.class;
    }

    public boolean isCellEditable(int rowIndex, int columnIndex)
    {
        return false;
    }

    public Object getValueAt(int rowIndex, int columnIndex)
    {
        return boardCells[columnIndex][rowIndex];
    }

    public void setValueAt(Object aValue, int rowIndex, int columnIndex)
    {
    }

    public void addTableModelListener(TableModelListener l)
    {
        listeners.add(l);
    }

    public void removeTableModelListener(TableModelListener l)
    {
        listeners.remove(l);
    }

    /**
     *  Class representing a single cell in the board.
     */
    final class Cell
    {
        private char contents= ' ';

        void setContents(char contents)
        {
            this.contents = contents;
        }

        boolean isEmpty()
        {
            return contents == ' ';
        }

        public String toString()
        {
            return String.valueOf(contents);
        }

        public boolean equals(Object obj)
        {
            return obj instanceof Cell &&
                   contents == ((Cell) obj).contents;
        }
    }
}
