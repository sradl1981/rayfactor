
#include "VFMatrix.h"

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	VFMatrix::VFMatrix
//
//	Comments : Constructor for the VFMatrix Object, it creates and initialises an n x n array of floats
//			   to record the system's view factors.
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	01/02/06	Trevor Walker	Created
//	22/05/10	Trevor Walker	Added nested loop to set initial view factors to 0
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////

VFMatrix::VFMatrix(int nS)
{
	noObjects = nS;
	vfm = new float*[noObjects];
	for(int i = 0; i < noObjects; i++)
	{
		vfm[i] = new float[noObjects];
		for(int j = 0; j < noObjects; j++)
		{
			vfm[i][j] = 0;
		}
	}
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	VFMatrix::~VFMatrix
//
//	Comments : Destructor for the VFMatrix Object, it deletes the systems view factor array.
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	01/02/06	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////

VFMatrix::~VFMatrix()
{
	// Do I need to delete all the pointers to pointer?
	delete vfm;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	VFMatrix::getNoObjects
//
//	Comments : Returns the number of objects recorded in the VFMatrix object 
//			   (For an n x n array it returns n)   
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	01/02/06	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////

int VFMatrix::getNoObjects()
{
	return noObjects;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	VFMatrix::getViewFactor
//
//	Comments : Returns the view factor from the object in row r to the object in column c
//
//	Arguments :		r is the row of the view factor matrix (object the view factor is from)
//			        c is the column of the view factor matrix (object the view factor is to)
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	01/02/06	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////

float VFMatrix::getViewFactor(int r, int c)
{
	return vfm[r][c];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	VFMatrix::setViewFactor
//
//	Comments : Sets the view factor from the object in row r to the object in row c.
//
//	Arguments :	vF is the view factor from object r to object c
//				r is the row of the object the view factor is from
//				c is the row of the object the view factor is to
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	01/02/06	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////

void VFMatrix::setViewFactor(float vF, int r, int c)
{
	vfm[r][c] = vF;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	VFMatrix::print
//
//	Comments : Prints the view factor matrix into a text file called output.txt in the executable 
//			   directory. It prints into a comma delimited file.
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	01/02/06	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////

void VFMatrix::print(string outName, int precision)
{
	ofstream out(outName.c_str());
	out.precision(precision);
	
	//Print the top row
	out << "Object";
	for(int z = 0; z < noObjects; z++)
	{
		out << "," << z+1;
	}
	
	out << endl;

	for(int i = 0; i < noObjects; i++)
	{
		out << i+1;
		out << std::scientific;
		for(int j = 0; j < noObjects; j++)
		{
			out << "," << (float)vfm[i][j];
		}
		out << endl;
		out << std::fixed;
	}
	out.close();
}
