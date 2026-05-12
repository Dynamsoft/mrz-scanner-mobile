#pragma once

#if !defined(_WIN32) && !defined(_WIN64)
#define DCPD_API __attribute__((visibility("default")))
#else
#ifdef DCPD_EXPORTS
#define DCPD_API __declspec(dllexport)
#else
#define DCPD_API
#endif
#endif
#include <string>
using namespace std;

#define DCPD_VERSION						"3.0.20"


#define DCPV_OK								0
#define DCPV_FAILED							-1
//VIN
#define DCPV_VIN_DATA_INVALID				-20
//VDS
#define DCPV_VDS_NOT_VALID_TYPE				-100
#define DCPV_VDS_CANNOT_OPEN_CERTIFICATE	-101
#define DCPV_VDS_INVALID_CER				-102
#define DCPV_VDS_INVALID_SIGNATURE			-103

#define DCPV_AADHAAR_CHECK_FAILED			-200

#define DCPV_SOUTH_AFRICA_CHECK_FAILED		-300


int VerifyMRZ(const string& in, const string& verifyCode);
int VerifyVIN(const string& in, const string& verifyCode);
int VerifyLRC(const string& in, const string& verifyCode);
int VerifyVDSNC(const string& in, const string& certificationPath);
int VerifyVDSNC(const string& in, const unsigned char* cert, int cerLen);
int ConvertToString_AADHAAR_PVC(string& data, string& result);
int ConvertToString_SOUTH_AFRICA_DL(const unsigned char* data, int length, string& result);
int Test_SOUTH_AFRICA_DL(const unsigned char* data, int length, string& result);
void VDSNC_verification_for_cercode(const char * source, int sourceLen, unsigned char * cert, int cerLen, int& ret);

int convertToString_GS1_Application_Identifier(const string& in, string& out);
#ifdef __cplusplus
extern "C" {
#endif
	DCPD_API void DCPD_GS1_AI_SplitElementToJSON(const unsigned char * source, int sourceLen, char ** result, int& resultLen, int& ret);
	DCPD_API void DCPD_GS1_AI_FormatDecimalPoint(const unsigned char * source, int sourceLen, char ** result, int& resultLen, int& ret);
	DCPD_API void DCPD_GS1_AI_FormatTemperature(const unsigned char * source, int sourceLen, char ** result, int& resultLen, int& ret);
	DCPD_API void DCPD_GS1_AI_GetFullYearWithCenturyRule(const unsigned char * source, int sourceLen, char ** result, int& resultLen, int& ret);
	DCPD_API void DCPD_MRZ_TD2_compositeVerification(const char * source, int sourceLen, const char * verifyCode, int verifyCodeLen, int& ret);
	DCPD_API void DCPD_MRZ_TD3_compositeVerification(const char * source, int sourceLen, const char * verifyCode, int verifyCodeLen, int& ret);
	DCPD_API void DCPD_MRZ_verification(const char * source, int sourceLen, const char * verifyCode, int verifyCodeLen, int& ret);
	DCPD_API void DCPD_VIN_verification(const char * source, int sourceLen, const char * verifyCode, int verifyCodeLen, int& ret);
	DCPD_API void DCPD_LRC_verification(const char * source, int sourceLen, const char * verifyCode, int verifyCodeLen, int& ret);
	DCPD_API void DCPD_VDSNC_verification(const char * source, int sourceLen, const char * certificationPath, int certificationPathLen, int& ret);
	DCPD_API void DCPD_AADHAAR_PVC_ConvertToString(const unsigned char * source, int sourceLen, char ** result, int& resultLen, int& ret);
	DCPD_API void DCPD_SOUTH_AFRICA_DL_ConvertToString(const unsigned char * source, int sourceLen, char ** result, int& resultLen, int& ret);
	DCPD_API void DCPD_SOUTH_AFRICA_DL_Test(const unsigned char * source, int sourceLen, char ** result, int& resultLen, int& ret);
	DCPD_API void DCPD_VIN_getModelYear(const unsigned char * source, int sourceLen, char ** result, int& resultLen, int& ret);
	DCPD_API void DCPD_MRZ_TD1_getFieldForCompositeCheck(const unsigned char * source, int sourceLen, char ** result, int& resultLen, int& ret);
	DCPD_API void DCPD_GS1_AI_verification_numeric(const char * source, int sourceLen, const char * verifyCode, int verifyCodeLen, int& ret);
	DCPD_API void DCPD_GS1_AI_verification_character(const char * source, int sourceLen, const char * verifyCode, int verifyCodeLen, int& ret);

	DCPD_API void DCPD_freeString(char** string);
#ifndef __EMSCRIPTEN__
	//#if !defined(ANDROID) && !defined(IOS)
	DCPD_API const char* DM_GetLibVersion();
#endif
#ifdef __cplusplus
}
#endif

