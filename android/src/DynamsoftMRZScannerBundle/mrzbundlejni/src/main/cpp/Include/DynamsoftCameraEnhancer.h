
#define DCE_OK 0
#define DCE_LICENSE_INVALID -10001
#define DCE_LICENSE_EXPIRED -10002
#define DCE_NOT_EXIST_CAMERA_MODULE -10003
#define DCE_NOT_FOUND_FILE -10004
#define DCE_FILE_FORMAT_ERROR -10005

#ifdef __EMSCRIPTEN__
#include <emscripten/emscripten.h>
#define DCE_EXPORT EMSCRIPTEN_KEEPALIVE
#elif !defined(_WIN32) && !defined(_WIN64)
#define DCE_EXPORT __attribute__((visibility("default")))
#else 
#define DCE_EXPORT
#endif


#define DCE_VERSION "4.2.20"


//enum ImagePixelFormat
//{
//	/**0:Black, 1:White */
//	IPF_BINARY = 0,
//
//	/**0:White, 1:Black */
//	IPF_BINARYINVERTED,
//
//	/**8bit gray */
//	IPF_GRAYSCALED,
//
//	/**NV21 */
//	IPF_NV21,
//
//	/**16bit with RGB channel order stored in memory from high to low address*/
//	IPF_RGB_565,
//
//	/**16bit with RGB channel order stored in memory from high to low address*/
//	IPF_RGB_555,
//
//	/**24bit with RGB channel order stored in memory from high to low address*/
//	IPF_RGB_888,
//
//	/**32bit with ARGB channel order stored in memory from high to low address*/
//	IPF_ARGB_8888,
//
//	/**48bit with RGB channel order stored in memory from high to low address*/
//	IPF_RGB_161616,
//
//	/**64bit with ARGB channel order stored in memory from high to low address*/
//	IPF_ARGB_16161616,
//
//	/**32bit with ABGR channel order stored in memory from high to low address*/
//	IPF_ABGR_8888,
//
//	/**64bit with ABGR channel order stored in memory from high to low address*/
//	IPF_ABGR_16161616,
//
//	/**24bit with BGR channel order stored in memory from high to low address*/
//	IPF_BGR_888
//
//};


typedef int(*AuthSendCb)(const char* URL, void *pUser, char *resultstr, int *httpcode);

typedef int(*UploadSendCb)(const char* URL, const char* data, void *pUser, char *resultstr, int *httpcode);

//struct ImageData
//{
//	unsigned char* data;
//	int width;
//	int height;
//	int stride;
//	int format;
//	int id;
//};
#ifdef __cplusplus
/** . */
extern "C" {
#endif // endif of __cplusplus.
	DCE_EXPORT void* DCE_CreateInstance();
	DCE_EXPORT void DCE_DestroyInstance(void* dce);
	DCE_EXPORT int DCE_LoadParamJson(void* dce, const char* filePath);
	DCE_EXPORT int DCE_LoadParamJsonString(void* dce, const char* configstr);
	DCE_EXPORT void DCE_SetCurrentFrameData(void* dce, unsigned char *data, int width, int height, int stride, int frameId, int format);
	DCE_EXPORT void DCE_SetSensorValue(void* dce, float v);
	DCE_EXPORT bool DCE_IsNeedFocus(void* dce, bool isFocusing);
	DCE_EXPORT bool DCE_IsNeedZoom(void* dce, int original_w, int original_h);
	DCE_EXPORT bool DCE_IsNeedFilter(void* dce, bool isFocusing);

	DCE_EXPORT int DCE_Upload(void* dce, int _time);
	DCE_EXPORT int DCE_IsValidLicense(void* dce);
	DCE_EXPORT const char* DCE_GetVersion();
#ifdef __cplusplus
}
#endif // endif of __cplusplus.


#ifdef __cplusplus
namespace DCE
{
class DCE_EXPORT CameraEnhancerAlgorithm
{

public:
	CameraEnhancerAlgorithm();
	~CameraEnhancerAlgorithm();

	static const char* Getversion();
	//int AppendOneFrame(unsigned char *data, int width, int height, int stride, int frameId,int format, bool isActivelyFocusing, double SensordeltaValue);

	//ImageData* AcquireLastImage(bool synchro);

	//void FreeData(ImageData** data);

	int LoadParamJson(const char* filePath);
	int LoadParamJsonString(const char* configstr);

	int SetCurrentFrameData(unsigned char *data, int width, int height, int stride, int frameId, int format);
	void SetSensorValue(float _v);
	bool IsNeedFocus(bool isFocusing);
	bool IsNeedZoom(int original_w, int original_h);
	bool IsNeedFilter(bool isFocusing);

	int Upload(int _time);
	int IsValidLicense();
	//int IsValidLocalLicense();

	void GetClarity(unsigned char* pBuff, int width, int height, int stride, int bitcount, float wr, float hr, int grayThreshold, int& c);

private:
	//filter
	void GetClarity(unsigned char* pBuff, int width, int height, int stride, int bitcount, int& c1, int& c2);

	//bool IsNeedZoomForQueue(ImageData *ImgData, int original_w, int original_h);
	bool IsNeedZoom(unsigned char *data, int width, int height, int original_w, int original_h);


	bool IsNeedDecode(bool isFocusing);

	bool ClarityFocus();

	bool EndClarityFocus();

	int graySort(unsigned char *data, int width, int height,int stride);

	bool meanClarityCmp(int id, int c);
	//autoZoom
	int crop_yuv (unsigned char* data, unsigned char* dst, int width, int height,
              int goalwidth, int goalheight);

	int cropDataY(unsigned char *data, unsigned char *dst, int width, int height,
              int goalwidth, int goalheight);

	int binaryzationThreshold(unsigned char *data,int original_w,int original_h, int frame_w, int frame_h);

	bool countCmp(unsigned char *dataSmall,unsigned  char *dataBig, int small_width, int small_height, 
			int big_width, int big_height, int threshold);


private:

	int left, right, top, bottom;
	int left2, right2, top2, bottom2;
	bool bCal;

	bool existClarityShark;
	int m_clarityArr[8];

	int m_last_c1;
	int m_last_c2;
	int lastDelta;
	int lastGrayIndex;

	unsigned char* m_curData;
	int m_curWidth;
	int m_curHeight;
	int m_curStride;
	int m_curFormat;
	int m_curClarity1;
	int m_curClarity2;
	bool m_curIsFocusing;
	float m_curSensorValue;
	bool m_bCal;
	int m_curFrameid;



	int m_licenseResult;
	//std::condition_variable m_cond;
	//std::mutex m_lock;
	//std::vector<ImageData*> m_frameQueue;
	//ImageData
};
}
#endif
