#pragma once
#include "DynamsoftLicense.h"

//#define DBR_LICENSE_ENABLE 1
#define LIC_MODULE_ONED					1
#define LIC_MODULE_QR					2
#define LIC_MODULE_PDF417				3
#define LIC_MODULE_DATAMATRIX			4
#define LIC_MODULE_AZTEC				5
#define LIC_MODULE_MAXICODE				6
#define LIC_MODULE_PATCHCODE			7
#define LIC_MODULE_GS1DATABAR			8
#define LIC_MODULE_GS1COMPOSITECODE		9
#define LIC_MODULE_POSTALCODE			10
#define LIC_MODULE_DOTCODE				11
#define LIC_MODULE_INTERMEDIATERESULT	12
#define LIC_MODULE_DPM					13
#define LIC_MODULE_PANORAMA				14
#define LIC_MODULE_PDFANNOTATION		15
#define LIC_MODULE_NON_STANDARD			16
#define LIC_MODULE_PHARMACODE			17

//#define LIC_MODULE_TWAIN					100
//#define LIC_MODULE_TWAIN_DIRECT			101
//#define LIC_MODULE_ICA					102
//#define LIC_MODULE_SANE					103
//#define LIC_MODULE_DIRECTSHOW				104
//#define LIC_MODULE_MEDIADEVICES			105
//#define LIC_MODULE_BMP					106
//#define LIC_MODULE_JPEG					107

#define LIC_MODULE_PDF_RASTERIZER				200
#define LIC_MODULE_PDF_Generator				201
#define LIC_MODULE_Label_Recognition			300
#define LIC_MODULE_CAMERA_ENHANCER				400
#define LIC_MODULE_SOUTH_AFRICA_DL				500
#define LIC_MODULE_NORTH_AMREICA_DL				501
#define LIC_MODULE_ICAO_VDS_NC					502
#define LIC_MODULE_AADHAAR						503
#define LIC_MODULE_MRZ							504
#define LIC_MODULE_VIN							505
#define LIC_MODULE_GS1_AI						506

#define LIC_MODULE_DOCUMENT_DETECT				600
#define LIC_MODULE_DOCUMENT_DESKEW				601
#define LIC_MODULE_DOCUMENT_IMAGE_COMPRESSION	602
#define LIC_MODULE_DOCUMENT_IMAGE_ENHANCED		603

#define PRODUCT_DBR 0
#define PRODUCT_DLR 1
#define PRODUCT_DDN 2
#define PRODUCT_DCE 3
#define PRODUCT_DCP 4

typedef int(*AuthSendCb)(const char* URL, void *pUser, char *resultstr, int *httpcode);

typedef int(*UploadSendCb)(const char* URL, const char* data, void *pUser, char *resultstr, int *httpcode);
#ifdef __cplusplus
extern "C" {
#endif
	//LIC_API int DC_IsModuleInvalid(int module,int version);
	LIC_API int DC_UploadResult(int product, const int code[32]);
	LIC_API int DC_PreSave(int product, const int code[32],const char* name);
	LIC_API int DC_DelPreSave(const char* name);
	LIC_API void DC_SetArg(const char* filePath, const char* randomuuid, const char* deviceuuid, const char* appID, AuthSendCb _authcb, UploadSendCb _uploadcb, void* pUserData);
	LIC_API int DC_IsInstanceMode(int module);
	LIC_API int DC_RegisterInstance(int num, void* ptr); 
	LIC_API int DC_LogOutInstance(void* ptr);
	LIC_API void testSecret(char*);
	LIC_API void DC_SetWorkDir(const char* filePath);
	LIC_API int DC_IsModuleInvalidEx(int module, int version,char* result);
	LIC_API int DC_IsModuleInvalidEx2(int licenseversion,int module,const char* product,int version, char* result);
	LIC_API int DC_GetLicenseIter();
	LIC_API int DC_IsExistProduct( int product);
	LIC_API int DC_SetClientRemark(const char* json);
	LIC_API int DC_GetRemainInstanceCount();
	LIC_API int DC_CheckModuleLimit(int module);

	LIC_API int DC_InitLicense(const char* pLicense, char errorMsgBuffer[], const int errorMsgBufferLen);
	LIC_API int DC_SetDeviceFriendlyName(const char* name);
	LIC_API int DC_SetMaxConcurrentInstanceCount(int countForThisDevice);
	LIC_API int DC_GetDeviceUUID(int uuidGenerationMethod, char uuidBuffer[], const int uuidbufferLen);
	LIC_API int DC_SetLicenseCachePath(const char* directoryPath);
	LIC_API int DC_GetLicenseError(char* errStr,int length);
#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
namespace dynamsoft
{
	namespace license
	{
		class LIC_API CLicenseManagerEx :public CLicenseManager
		{
		public:
			static int IsModuleInvalid(int module, int version);
			static int UploadResult(int product, const int code[32]);
			static void SetArg(const char* filePath, const char* randomuuid, const char* deviceuuid, const char* appID, AuthSendCb _authcb, UploadSendCb _uploadcb, void* pUserData);
			static int IsInstanceMode(int module);
			//static int ChangeInstanceNum(int num, void* ptr);
			static int InitLicenseFromDLSString(const char* licenseInfo,const char* clientuuid);
			static int GetDlsString(char* licenseString, int *length,char uuid[36]);
		};
	}
}
#endif