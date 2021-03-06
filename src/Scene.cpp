#include "Scene.h"



/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Scene::Scene
//
//	Comments : Default Constructor
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	01/02/06	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
Scene::Scene()
{
    head = NULL;
    tail = NULL;
	numPrimitives = 0;
	printViewFactors = true;
	printParticles   = true;
	particleCount    = 0;  
	particleBoundingBoxLow.set(9e9,9e9,9e9,9e9);
	particleBoundingBoxHigh.set(-9e9,-9e9,-9e9,-9e9);
	calcVFInferse=true;
}

//Note put a deconstructor: see free Scene

#pragma mark readScene

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Scene::readScene
//
//	Comments : The function for reading an xml NDRay project file and creating the scene
//
//	Arguments : filename is a c string that holds the file name of the xml project file
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	23/01/10	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
void Scene::readScene(const char* filename)
{
	TiXmlDocument doc(filename);
	bool didLoadOk = doc.LoadFile();
	if(didLoadOk) {
		TiXmlHandle docHandle( &doc );
		
		TiXmlElement *settings = docHandle.FirstChild( "project" ).FirstChild( "settings" ).ToElement();
		TiXmlElement *geometry = docHandle.FirstChild( "project" ).FirstChild( "geometry" ).ToElement();

		this->loadSettings( settings );
		this->loadGeometry( geometry );
	} else {
		printf("Failed to load file \"%s\"\n", filename);
	}
	
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Scene::loadSettings
//
//	Comments : Parses the project settings from the <settings> xml block
//
//	Arguments : settings is a pointer to a TiXmlElement representing the <settings> block.
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	23/01/10	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
bool Scene::loadSettings( TiXmlElement *settings )
{
	TiXmlElement *child = settings->FirstChild()->ToElement();
	
	//For each element in the <settings> block
	for( child; child; child=child->NextSiblingElement())
	{
		string typeStr = child->ValueStr();
		if(typeStr.compare(kGlobalRayDensity) == 0) 
		{
			child->QueryValueAttribute(kValue,&globalRayDensity);
		} 
		else if(typeStr.compare(kDescription) == 0) 
		{
			sceneDescription = string(child->GetText());
		}
		else if(typeStr.compare(kPrintViewFactors) == 0) 
		{
			printViewFactors = bool(child->GetText());
		}
		else if(typeStr.compare(kPrintParticles) == 0) 
		{
			printParticles = bool(child->GetText());
		}
	}
	
	return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Scene::loadGeometry
//
//	Comments : Is the higher level handler for the primitives stored in the <geometry> xml block. It 
//			   will determine what type of primitive is specified, create the primitive object, extract
//			   any unique attributes than pass it on for parsing of the generic primitive properties
//
//	Arguments : geometry is pointer to a TiXmlElement which contains the <geometry> block.
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	23/01/10	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
bool Scene::loadGeometry( TiXmlElement *geometry )
{
	TiXmlElement *primitive = geometry->FirstChild()->ToElement();
	int objectID = 0;
	
	//For each <primitive> block
	for( primitive; primitive; primitive=primitive->NextSiblingElement() )
	{
		string prType = "";
		
		bool willAnalyse = true;
		bool isBounding = false;
		
		if(primitive->Attribute( "type") != NULL) {
			prType = primitive->Attribute("type");
		}
		
		if(primitive->Attribute("isBounding") != NULL) {
			string isBoundingStr = primitive->Attribute("isBounding");
			isBounding = (isBoundingStr.compare("true") == 0);
		}
		
		if(primitive->Attribute("analyse") != NULL) {
			string analyseStr = primitive->Attribute("analyse");
			willAnalyse = (analyseStr.compare("true") == 0);
		}

        if(willAnalyse) activePrimitives.push_back(objectID);
		
		if(prType.compare("cylinderSurface") == 0 || prType.compare("taperedCylinderSurface") == 0) {
			Primitive *cylinder;
			float smallRadius;
			primitive->FirstChildElement( "smallRadius" )->QueryValueAttribute( "value", &smallRadius );
            
            // Handle whether to use a faster primitive based on its type i.e cone, cylinder, frustum
            
			if(smallRadius == 1.0) {
                cylinder = new CylinderSurface(objectID);
            } else {
                cylinder = new TaperedCylinderSurface(objectID, smallRadius);
            }
            
			
			cylinder->setWillAnalyse(willAnalyse);
			cylinder->setIsBounding(isBounding);
			
			this->initPrimitive( primitive, *cylinder);

			this->addObject( *cylinder );
			
		} else if(prType.compare( "annulus" ) == 0) {
			
			float smallRadius, largeRadius;
			primitive->FirstChildElement( "smallRadius" )->QueryValueAttribute( "value", &smallRadius );
			primitive->FirstChildElement( "largeRadius" )->QueryValueAttribute( "value", &largeRadius );
			
			//Assumes largeRaidus and smallRadius are defined and correct
			Annulus *annulus = new Annulus(objectID, largeRadius, smallRadius);
			
			annulus->setWillAnalyse(willAnalyse);
			annulus->setIsBounding(isBounding);

			this->initPrimitive( primitive, *annulus);
			
			this->addObject( *annulus );
			
		}
		else if(prType.compare( "rectangle" ) == 0) {
			
			Rectangle *rectangle = new Rectangle(objectID);
			
			rectangle->setWillAnalyse(willAnalyse);

			this->initPrimitive( primitive, *rectangle);
			
			this->addObject( *rectangle );

		}
		else if(prType.compare( "disc" ) == 0) {
			
			Disc *disc = new Disc(objectID);
			
			disc->setWillAnalyse(willAnalyse);

			this->initPrimitive( primitive, *disc);
			
			this->addObject( *disc );
			
		} else if(prType.compare( "sphere" ) == 0) {
			
			Sphere *sphere = new Sphere(objectID);
			
			sphere->setWillAnalyse(willAnalyse);
			sphere->setIsBounding(isBounding);
			
			this->initPrimitive( primitive, *sphere);
			
			this->addObject( *sphere );
			
			particleCount++;
			
			particleBoundingBoxLow._x=min(particleBoundingBoxLow._x,sphere->center._x);
			particleBoundingBoxLow._y=min(particleBoundingBoxLow._y,sphere->center._y);
			particleBoundingBoxLow._z=min(particleBoundingBoxLow._z,sphere->center._z);

			particleBoundingBoxHigh._x=max(particleBoundingBoxHigh._x,sphere->center._x);
			particleBoundingBoxHigh._y=max(particleBoundingBoxHigh._y,sphere->center._y);
			particleBoundingBoxHigh._z=max(particleBoundingBoxHigh._z,sphere->center._z);
			
		} else if(prType.compare( "triangle" ) == 0) {
            Triangle *triangle = new Triangle(objectID);
            
            triangle->setWillAnalyse(willAnalyse);

            // Get the verticies
            /*
            AB = B - A     (3D Point)
            AC = C - A     (3D Point)
             
             N = AB x AC
             nd =  A.N
             
             U = AC x N / |N|^2
             Ud = -U.A
             
             V = N x AB / |N|^2
             Vd = -V.A
            
            */
            float Ax, Ay, Az, Bx, By, Bz, Cx, Cy, Cz;
            
            
            TiXmlElement *A = primitive->FirstChild( "A" )->ToElement();
            
            A->QueryValueAttribute( "x", &Ax );
            A->QueryValueAttribute( "y", &Ay );
            A->QueryValueAttribute( "z", &Az );

            TiXmlElement *B = primitive->FirstChild( "B" )->ToElement();
            
            B->QueryValueAttribute( "x", &Bx );
            B->QueryValueAttribute( "y", &By );
            B->QueryValueAttribute( "z", &Bz );

            TiXmlElement *C = primitive->FirstChild( "C" )->ToElement();
            
            C->QueryValueAttribute( "x", &Cx );
            C->QueryValueAttribute( "y", &Cy );
            C->QueryValueAttribute( "z", &Cz );

            
            triangle->Ax = Ax;
            triangle->Ay = Ay;
            triangle->Az = Az;
            
            float ABx = Bx - Ax;
            float ABy = By - Ay;
            float ABz = Bz - Az;
            
            
            float ACx = Cx - Ax;
            float ACy = Cy - Ay;
            float ACz = Cz - Az;
            
            triangle->ABx = ABx;
            triangle->ABy = ABy;
            triangle->ABz = ABz;
            
            triangle->BCx = Cx - Bx;
            triangle->BCy = Cy - By;
            triangle->BCz = Cz - Bz;
            
            triangle->nx = ABy*ACz - ABz*ACy;
            triangle->ny = ABz*ACx - ABx*ACz;
            triangle->nz = ABx*ACy - ABy*ACx;
            triangle->nd = triangle->nx*Ax + triangle->ny*Ay + triangle->nz*Az;
            
            float mgN = sqrtf(triangle->nx*triangle->nx + triangle->ny*triangle->ny + triangle->nz*triangle->nz);
            float mgNsq = mgN*mgN;
        
            triangle->Aw = 1.0f/mgN;
            
            triangle->ux = (ACy*triangle->nz - ACz*triangle->ny)/mgNsq;
            triangle->uy = (ACz*triangle->nx - ACx*triangle->nz)/mgNsq;
            triangle->uz = (ACx*triangle->ny - ACy*triangle->nx)/mgNsq;
            triangle->ud = -triangle->ux*Ax - triangle->uy*Ay - triangle->uz*Az;
            
            triangle->vx = (triangle->ny*ABz -  triangle->nz*ABy)/mgNsq;
            triangle->vy = (triangle->nz*ABx - triangle->nx*ABz)/mgNsq;
            triangle->vz = (triangle->nx*ABy - triangle->ny*ABx)/mgNsq;
            triangle->vd = -triangle->vx*Ax - triangle->vy*Ay - triangle->vz*Az;

            
            this->initPrimitive( primitive, *triangle);

			this->addObject( *triangle );
        } else if(prType.compare( "fasttriangle" ) == 0) {
            fastTriangle *fTriangle = new fastTriangle(objectID);
            
            fTriangle->setWillAnalyse(willAnalyse);
            
            float Ax, Ay, Az, Bx, By, Bz, Cx, Cy, Cz;
            
            
            TiXmlElement *A = primitive->FirstChild( "A" )->ToElement();
            
            A->QueryValueAttribute( "x", &Ax );
            A->QueryValueAttribute( "y", &Ay );
            A->QueryValueAttribute( "z", &Az );
            
            TiXmlElement *B = primitive->FirstChild( "B" )->ToElement();
            
            B->QueryValueAttribute( "x", &Bx );
            B->QueryValueAttribute( "y", &By );
            B->QueryValueAttribute( "z", &Bz );
            
            TiXmlElement *C = primitive->FirstChild( "C" )->ToElement();
            
            C->QueryValueAttribute( "x", &Cx );
            C->QueryValueAttribute( "y", &Cy );
            C->QueryValueAttribute( "z", &Cz );
            
            
            float ACx = Cx - Ax;
            float ACy = Cy - Ay;
            float ACz = Cz - Az;
            
            float ABx = Bx - Ax;
            float ABy = By - Ay;
            float ABz = Bz - Az;
            
            fTriangle->cx = (Ax + Bx + Cx)/3.0f;
            fTriangle->cy = (Ay + By + Cy)/3.0f;
            fTriangle->cz = (Az + Bz + Cz)/3.0f;
            
            fTriangle->nx = ABy*ACz - ABz*ACy;
            fTriangle->ny = ABz*ACx - ABx*ACz;
            fTriangle->nz = ABx*ACy - ABy*ACx;
            fTriangle->nd = fTriangle->nx*Ax + fTriangle->ny*Ay + fTriangle->nz*Az;
            
            float mgN = sqrtf(fTriangle->nx*fTriangle->nx + fTriangle->ny*fTriangle->ny + fTriangle->nz*fTriangle->nz);
            float mgNsq = mgN*mgN;
            
            fTriangle->cw = 1.0f/mgN;
            
            fTriangle->ux = (ACy*fTriangle->nz - ACz*fTriangle->ny)/mgNsq;
            fTriangle->uy = (ACz*fTriangle->nx - ACx*fTriangle->nz)/mgNsq;
            fTriangle->uz = (ACx*fTriangle->ny - ACy*fTriangle->nx)/mgNsq;
            fTriangle->ud = -fTriangle->ux*Ax - fTriangle->uy*Ay - fTriangle->uz*Az;
            
            fTriangle->vx = (fTriangle->ny*ABz - fTriangle->nz*ABy)/mgNsq;
            fTriangle->vy = (fTriangle->nz*ABx - fTriangle->nx*ABz)/mgNsq;
            fTriangle->vz = (fTriangle->nx*ABy - fTriangle->ny*ABx)/mgNsq;
            fTriangle->vd = -fTriangle->vx*Ax - fTriangle->vy*Ay - fTriangle->vz*Az;
            
            this->initPrimitive( primitive, *fTriangle);
            
			this->addObject( *fTriangle );

        }
		

		objectID++;
	}
	return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Scene::initPrimitive
//
//	Comments : Parsers all the attributes common to all primitives and applies them to the primitive 
//			   object
//
//	Arguments : xmlElement is a pointer to a TiXmlElement representing the <primitive> block.
//				primative is a reference to a ScnObject to which the parsed attributes will be applied.
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	23/01/10	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
bool Scene::initPrimitive( TiXmlElement *xmlElement, Primitive &primitive )
{
	if(!(xmlElement->FirstChild())) {
		return true;
	}
	TiXmlElement *child = xmlElement->FirstChild()->ToElement();
	bool foundRayDensity = false;
	// For each child in a <primitive> block
	for( child; child; child=child->NextSiblingElement())
	{
		string typeStr = child->ValueStr();

		//Should be done in the order of scale, rotate, translate
		if(typeStr.compare("rayDensity") == 0) 
		{
			int rayDensity;
			child->Attribute( "value", &rayDensity);
			primitive.setRayDensity(rayDensity);
			foundRayDensity = true;	
		}
		else if(typeStr.compare("translation") == 0) 
		{
			float xTrans, yTrans, zTrans;
			
			child->QueryValueAttribute( "x", &xTrans );
			child->QueryValueAttribute( "y", &yTrans );
			child->QueryValueAttribute( "z", &zTrans );
			
			primitive.translate(Vector(xTrans,yTrans,zTrans));
		} 
		else if(typeStr.compare("scale") == 0) 
		{
			float xScale, yScale, zScale;
			
			child->QueryValueAttribute( "x", &xScale );
			child->QueryValueAttribute( "y", &yScale );
			child->QueryValueAttribute( "z", &zScale );
			
			primitive.scale(xScale,yScale,zScale);
		} 
		else if(typeStr.compare("rotate") == 0) 
		{
			float degRot, xAxis, yAxis, zAxis;
			
			child->QueryValueAttribute( "degrees", &degRot );
			child->QueryValueAttribute( "x", &xAxis );
			child->QueryValueAttribute( "y", &yAxis );
			child->QueryValueAttribute( "z", &zAxis );
			
			primitive.rotate(degRot, Vector(xAxis,yAxis,zAxis));
		}
		else if(typeStr.compare("globalID") == 0) 
		{
			int globalID;
			
			child->QueryValueAttribute( "id", &globalID );
			
			primitive.globalID = globalID;
		}
	}
	
	//Set the scene defaults if no specific attributes were found
	if(!foundRayDensity) {
		primitive.setRayDensity(globalRayDensity);
	}

	return true;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Scene::addObject
//
//	Comments : Adds an object to the system to be analysed
//
//	Arguments: so is the object to be added to the current system
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	01/02/06	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
bool Scene::addObject(Primitive &so)
{

    if(head == NULL)
    {
        head = &so;
        tail = &so;
		numPrimitives++;
        return true;
    }
    else
    {
        tail->setNext(so);
        tail = &so;
		numPrimitives++;
        return true;
    }
	
	return false;

}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Scene::getObject
//
//	Comments : Returns a pointer to a scene object with a given ID
//
//	Arguments: iden is the ID of the scene object to return
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	01/02/06	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
Primitive* Scene::getObject(int obID) //is this function used?
{
    for(Primitive *so = head; so != NULL; so = so->next)
    {
        if(so->getID() == obID)
            return so;
    }
	return NULL;
}

float Scene::getNumPrimitives()
{
	return numPrimitives;
}


/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Scene::setCalculation
//
//	Comments : Routine to apply a number of settings
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	28/08/18	StefanRadl		Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
void Scene::setCalculation(bool calcInv, int inputSwitch, int outputSwitch)
{
	calcVFInferse = calcInv;
	cout << "calcVFInferse: " << calcVFInferse << endl
		 << "inputSwitch: " << inputSwitch << endl
		 << "outputSwitch: " << outputSwitch
		 << endl;
	return;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Scene::findViewFactors
//
//	Comments : Driver routine to find to process each object and calculate the view factor matrix
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	01/02/06	Trevor Walker	Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
void Scene::findViewFactors()
{
	int currSurf = 1;

	vfm        = new VFMatrix(numPrimitives);
	vfmInverse = new VFMatrix(numPrimitives); //inverse view factors. useful if analyze from plane
	
	struct timeval startTime, endTime;
	
	for(Primitive* pobj = head; pobj != NULL; pobj = pobj->next)
	{
		cout << "Processing Object " << currSurf 
		     << " (with globalID: " << pobj->globalID << ")"
		    << " of " << numPrimitives << endl;

		gettimeofday(&startTime, NULL);
		
		if(pobj->willAnalyse()) 
		{
		    //Perform  calculateion
			pobj->traceFactors(head, vfm);
			
			if(calcVFInferse)
			{
				pobj->invertViewFactors(head,vfm,vfmInverse);
			//Invert viewfactor for ease
#if VERBOSE_1 
			std::cout << "inverting VFMatrix for object with ID " 
                      << pobj->getID() 
                      << ", and area = "
                      << pobj->surfaceArea()
                      << endl;
#endif
		    }

		}
		
		gettimeofday(&endTime, NULL);
		float t = (1000*(endTime.tv_sec-startTime.tv_sec)+(endTime.tv_usec-startTime.tv_usec)/1000);
		
		std::cout << "Time " << t << " ms" << endl;
		
		currSurf++;
	}
	
	if(printViewFactors)
	{
	    vfm->print(string("vfMatrix.txt"), 6);
		if(calcVFInferse)
			vfmInverse->print(string("vfMatrixInverted.txt"), 6);
	}
	
	if(printParticles)
	{
	    printParticlesToFile(string("rayFactor.liggghts"), 6);
	}	
    return;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//	Scene::printParticles
//
//	Comments : Will write particle information (including view factors) in LIGGGHTS format for first object
//
//	Date		Developer		Action
/////////////////////////////////////////////////////////////////////////////////////////////////////////
//	12/08/18	Stefan Radl     Created
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////
void Scene::printParticlesToFile(string filename, int precision)
{
	ofstream out(filename.c_str());
	out.precision(precision);
	
	//Print the top row
    out << "ITEM: TIMESTEP" << endl;
    out << "0" << endl;
    out << "ITEM: NUMBER OF ATOMS" << endl;
    out << particleCount << endl;
    out << "ITEM: BOX BOUNDS pp pp pp" << endl;
    out << particleBoundingBoxLow._x << " " << particleBoundingBoxHigh._x  << endl;
    out << particleBoundingBoxLow._y << " " << particleBoundingBoxHigh._y  << endl;
    out << particleBoundingBoxLow._z << " " << particleBoundingBoxHigh._z  << endl;
    out << "ITEM: ATOMS id type x y z radius isActive";
    
    //Iterate active primitives and write header
    for (std::vector<int>::iterator it = activePrimitives.begin(); it != activePrimitives.end(); ++it)
	{
        out << " vf_" << getObject(*it)->globalID ;
		if(calcVFInferse)
			out << " vfInverse_" << getObject(*it)->globalID;
	}
    out << endl;

    int j = 0;
	for(Primitive* pobj = head; pobj != NULL; pobj = pobj->next)
	{
	    if(pobj->globalID>=0) //only do for particles that have a global ID
	    {
            out << pobj->globalID << " 1 ";
		    out << std::scientific;
            out << pobj->center._x << " "
                << pobj->center._y << " "
                << pobj->center._z << " ";
            out << pobj->scaleVector._x << " ";
			bool isActive=false;
            for (std::vector<int>::iterator it = activePrimitives.begin(); it != activePrimitives.end(); ++it)
			{
				if(*it==j) isActive=true;
			}
			out << isActive << " ";
            for (std::vector<int>::iterator it = activePrimitives.begin(); it != activePrimitives.end(); ++it)
			{
                out << vfm->getViewFactor(*it, j) << " ";
				if(calcVFInferse)
					out << vfmInverse->getViewFactor(*it, j) << " ";
			}
		    out << endl;
		    out << std::fixed;	    
	    }
	    j++;
	}
	out.close();

}
