#pragma once
#ifndef __DYNAMSOFT_LABEL_RECOGNITION_EX_H__
#define __DYNAMSOFT_LABEL_RECOGNITION_EX_H__
#include "DynamsoftLabelRecognizer.h"

typedef int(*AuthSendCb)(const char* URL, void *pUser, char *resultstr, int *httpcode);

typedef int(*UploadSendCb)(const char* URL, const char* data, void *pUser, char *resultstr, int *httpcode);

#ifdef __cplusplus
/** . */
extern "C" {
#endif // endif of __cplusplus.
	DLR_API void CreateCombineResultsInstance(void** pCombineTextResultsInstance, int size);
	DLR_API void CombineResults(void* pCombineTextResultsInstance, void* pTextSingleRowRecognizer, char** pOutput, int& iCombinationConfidence);
	DLR_API void FreeCombinedResults(char** pOutput);
	DLR_API void DestroyCombineResultsInstance(void** pCombineTextResultsInstance);

	DLR_API int DLR_CreateParameters(void* dcvParam, const char* templateName, char* errorMsgBuffer = NULL, int bufferLength = 0);
	DLR_API int DLR_ReadTaskSetting(void* dcvParam, void* taskSettingParam, int& errorCode, void** taskSetting);
	DLR_API void* DLR_CreateTaskAlgEntity();
	DLR_API void DLR_CreateTargetRoiDefConditionFilter(void* filter);
	DLR_API int DLR_AppendConfusableCharactersBuffer(const char* dataName, const char* charsDataBuffer, int bufferLen);
	DLR_API int DLR_AppendOverlappingCharactersBuffer(const char* dataName, const char* charsDataBuffer, int bufferLen);
	DLR_API int DLR_AppendDictionaryBuffer(const char* dictName, const char* dataBuffer, int dataLength);

#ifdef __cplusplus
}
#endif //endif of __cplusplus

#ifdef __cplusplus
class LabelRecognizerInner;
namespace dynamsoft
{
	namespace dlr
	{
		class DLR_API CLabelRecognizer
		{
		protected:
			LabelRecognizerInner * m_DLRInner;

		public:
			CLabelRecognizer();

			~CLabelRecognizer();


			int SetCharacterModelDefaultPath(const char* modelPath,
				char errorMsgBuffer[] = NULL, const int errorMsgBufferLen = 0);

			int InitSettings(const char* content, char errorMsgBuffer[] = NULL, int errorMsgBufferLen = 0);
			int InitSettingsFromFile(const char* filePath, char errorMsgBuffer[] = NULL, int errorMsgBufferLen = 0);

			char* OutputSettings(const char* templateName, int* pErrorCode = NULL);
			int OutputSettingsToFile(const char* templateName, const char* outputFilePath);

			int GetSimplifiedSettings(SimplifiedLabelRecognizerSettings* pSettings);
			int UpdateSettings(const SimplifiedLabelRecognizerSettings* pSettings, char errorMsgBuffer[] = NULL, const int errorMsgBufferLen = 0);
			void ResetSettings();


			int SetModeArgument(const char *pModesName, const int index, const char *pArgumentName, const char *pArgumentValue, char errorMsgBuffer[] = NULL, const int errorMsgBufferLen = 0);
			int GetModeArgument(const char *pModesName, const int index, const char *pArgumentName, char valueBuffer[], const int valueBufferLen, char errorMsgBuffer[] = NULL, const int errorMsgBufferLen = 0);

			CRecognizedTextLinesResult* Recognize(const char* fileName, const char* templateName = "");
			CRecognizedTextLinesResult* Recognize(unsigned char* pFileBytes, int fileSize, const char* templateName = "");
			CRecognizedTextLinesResult* Recognize(const CImageData* pImageData, const char* templateName = "");
			/**
			 * Returns the version info of the SDK.
			 *
			 * @return The version info string.
			 *
			 */
			static const char* GetVersion();
			static void FreeString(char* content);
		private:
			CLabelRecognizer(const CLabelRecognizer& r);
			CLabelRecognizer& operator=(const CLabelRecognizer& r);
		};
	}
}

using namespace dynamsoft::dlr;
using namespace dynamsoft;

class DLR_API CLabelRecognizerEx : public CLabelRecognizer
{
public:
	/**
	* @{
	*
	* Default constructor
	*
	*/

	CLabelRecognizerEx();

	/**
	* Destructor
	*
	*/

	~CLabelRecognizerEx();

	static void AppendCaffeModelBuffer(const char* name,
		const char* prototxtBuffer, int prototxtLen,
		const char* txtBuffer, int txtLen,
		const char* caffeModelBuffer, int modelLen);
	//static void EraseAllCaffeModels();
	//static void EraseCaffeModelByName(const char* name);
	//static int InitLicenseFromDLSInfo(const char* licenseInfo, const char* DLSuuid, const char* clientuuid, int licenseType);
	//static int IsExistDLSModule(int mod);
//#if defined(ANDROID) || defined(IOS)
//	static void SetArg(const char* filePath, const char* randomuuid, const char* deviceuuid, const char* appID, AuthSendCb _authcb, UploadSendCb _uploadcb, void* pUserData);
//#endif
	
private:


	CLabelRecognizerEx(const CLabelRecognizerEx& r);

	CLabelRecognizerEx& operator = (const CLabelRecognizerEx& r);

};
#endif
#endif