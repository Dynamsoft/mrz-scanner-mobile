#pragma once
#include "DynamsoftCaptureVisionRouter.h"

#ifdef __cplusplus
extern "C" {
#endif
	CVR_API void CVR_LoadDynamicDlls();
#ifdef __cplusplus
}

namespace dynamsoft
{
	namespace cvr
	{
		typedef struct tagDCVResources
		{
			const char** modelNameArray{ nullptr };
			int* modelInstancesCountArray{ nullptr };
			int modelNameArrayLength{ 0 };
			const char** codeSpecsArray{ nullptr };
			int codeSpecsArrayLength{ 0 };
			char reserved[64]{ 0 };

		}DCVResources;

		class CVR_API CCaptureVisionRouterEx : public CCaptureVisionRouter {
		public:
			void ContainsTask(const char* templateName, bool& hasDBR, bool& hasDLR, bool& hasDDN, bool& hasDCP);
			//Should call after all AppendParameterContent finished
			int InitParameter();
			int AppendParameterContent(const char* content);
			DCVResources ParseRequiredResources(const char* templateName);

#ifdef DM_CONSOLE_LOG
			static void SetLogLevel(int lv);
			static void OutputJsonLog();
			static void OutputCacheLog();
			static void SetLogOutputMode(int mode);
#endif
			
		};
	}
}

#endif // __cplusplus