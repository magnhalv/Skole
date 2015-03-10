import java.rmi.*;
import java.util.*;
import javax.swing.table.*;

/**
 * Data model specifying the contents of the
 * resource table in the GUI.
 */
public class ResourceTableModel extends AbstractTableModel
{
	/** The names of the columns in the table */
	private String columnNames[] = {"Resource", "Lock owner"};
	/** The resources displayed in the table */
	private ArrayList resources;

	/**
	 * Creates a new resource table data model.
	 * @param resources		The resources that the table should display.
	 */
	public ResourceTableModel(ArrayList resources) {
		this.resources = resources;
	}

	/**
	 * Updates the contents of this data model.
	 * @param resources		The new list of resources to display.
	 */
	public void updateResourceList(ArrayList resources) {
		this.resources = resources;
		fireTableDataChanged();
	}

	/**
	 * Gets the name of the specified column.
	 * @param col	The index of the column.
	 * @return		The name of the column with index col.
	 */
	public String getColumnName(int col) { 
        return columnNames[col].toString(); 
    }

	/**
	 * Gets the number of rows in the table.
	 * @return	The number of resources in the table.
	 */
    public int getRowCount() {
		return resources.size();
	}
    
	/**
	 * Gets the number of columns in the table.
	 * @return	The number of columns in the table.
	 */
	public int getColumnCount() {
		return columnNames.length;
	}
    
	/**
	 * Gets an object specifying the contents of the specified table cell.
	 * @param row	The row index of the cell.
	 * @param col	The column index of the cell.
	 * @return		A string specifying the contents of the given cell.
	 */
	public Object getValueAt(int row, int col) { 
		if(col == 0)
			return ""+row;
		else if(col == 1) {
			Integer lockOwner = ((Resource)resources.get(row)).getLockOwner();
			if(lockOwner == null)
				return "None";
			else
				return lockOwner.toString();
		}
		else
			return "";
    }

	/**
	 * Checks if a specified table cell is editable.
	 * @param row	The row index of the cell.
	 * @param col	The column index of the cell.
	 * @return		Overridden to always return false.
	 */
	public boolean isCellEditable(int row, int col) {
		return false;
	}
}
