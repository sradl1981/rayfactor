#include <stdlib.h>
#include <iostream>
#include <fstream>
#include <string>
#include <time.h>
#include <omp.h>
#include "tinyxml.h"

#include "RayfactorConstants.h"

#include "Scene.h"


using namespace std;

int main (int argc, char ** argv) {
    int noThreads = 0;
    
    if(argc > 1) {
        Primitive::numThreads = atol(argv[1]);
        std::cout << "Using " << Primitive::numThreads << " OpenMp threads" << std::endl;
    } else {
        Primitive::numThreads = 0;
    }
    
	Scene scene;

    bool standardInputFile=false;
	bool calcVFInferse=true;
	string xmlpath = "input.xml";
    if(argc>2)
    {
        if(argc<4)
        {
            printf("ERROR: you MUST specify an input file name after '-f'. \n");            
            exit (1);
        }
        if (strcmp(argv[2],"-f") == 0)
        {
            xmlpath.assign(argv[3]);
            printf("...using input file '%s'\n", xmlpath.c_str());  
        }
        else
            standardInputFile=true;
    }
	if(argc>4)
	{
		if (strcmp(argv[4],"-noInverse") == 0)
			calcVFInferse=false;
	}
	
    if(standardInputFile)
        printf("will use input.xml as the input file.\n");

	scene.readScene(xmlpath.c_str());
	scene.setCalculation(calcVFInferse,-1,-2);
	struct timeval startTime, endTime;
	
	gettimeofday(&startTime, NULL);
	scene.findViewFactors();
	gettimeofday(&endTime, NULL);
	
	double t = (1000*(endTime.tv_sec-startTime.tv_sec)+(endTime.tv_usec-startTime.tv_usec)/1000);
	
	ofstream out;
	out.open("time.txt");
	out.precision(5);
	
	out <<  t << " ms" << endl;
	out <<  t/1000. << " seconds" << endl;
	out << t/(1000.*60.) << " minutes" << endl;
	out << t/(1000.*3600.) << " hours" << endl;
	out.close();
}
