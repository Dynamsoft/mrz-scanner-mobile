#pragma once
//#include <iostream>
//#include <string>
#include <vector>
#include <algorithm>
#include <cmath>
#include <numeric>

#include "DynamsoftCaptureVisionRouter.h"

#ifdef ANDROID
	#define FINDPHOTO_API __attribute__((visibility("default")))
#else
	#ifdef FINDPHOTO_DLL_EXPORTS
		#define FINDPHOTO_API __declspec(dllexport)
	#else
		#define FINDPHOTO_API __declspec(dllimport)
	#endif 
#endif


using namespace std;
using namespace dynamsoft::license;
using namespace dynamsoft::cvr;
using namespace dynamsoft::dbr;
using namespace dynamsoft::basic_structures;
using namespace dynamsoft::dlr::intermediate_results;
using namespace dynamsoft::ddn::intermediate_results;

extern "C" FINDPHOTO_API bool FindPreciseDocumentPortraitQuad(const CScaledColourImageUnit* scaledColorImgUnit, const CLocalizedTextLinesUnit* DLRResultUnit, const CRecognizedTextLinesUnit* RecognizedTextLinesUnit, const CDetectedQuadsUnit* DDNResultUnit, const CDeskewedImageUnit* deskewedImageUnit, CQuadrilateral& resultPhotoQuad);
