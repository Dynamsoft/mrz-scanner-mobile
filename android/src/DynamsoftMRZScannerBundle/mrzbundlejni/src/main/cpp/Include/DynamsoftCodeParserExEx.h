#pragma once
#include "DynamsoftCodeParser.h"
#include "macro.h"
#ifdef __cplusplus
extern "C" {
#endif
	DCP_API const char* DCP_GetVersion();
	DCP_API char* DCP_GetMapNameBySpecification(const char* specificationBuffer, int specificationLen);
	DCP_API void DCP_FreeString(char** str);
	DCP_API int DCP_AppendResourceBuffer(const char* name,
		const char* specificationBuffer, int specificationLen,
		const char* mapBuffer, int mapLen);
#ifdef __cplusplus
}
#endif