//
// Created by Allen on 2025/11/3.
//

#include "Include/DynamsoftCore.h"
#include "set"
#include <atomic>
#include <mutex>

using namespace dynamsoft::basic_structures;


class WrapImageData {
public:
    explicit WrapImageData(const CImageData *imageData) {
        if (imageData == nullptr) return;
        pImageData = new CImageData(imageData->GetBytesLength(), imageData->GetBytes(),
                                    imageData->GetWidth(), imageData->GetHeight(), imageData->GetStride(),
                                    imageData->GetImagePixelFormat(), imageData->GetOrientation(), imageData->GetImageTag());
    }

    ~WrapImageData() {
        if (pImageData == nullptr) return;
        delete pImageData;
    }

    void retain();

    void release();

    CImageData *getImageData();
private:
    std::atomic<int> count{0};
    CImageData *pImageData = nullptr;
    static std::set<WrapImageData *> g_wrapImageDataSet;
    static std::mutex g_mutex;
};

extern "C" const unsigned char* getImageDataFromWrapImageData(WrapImageData* wrapImageData, int& bytesLength, int& width, int& height, int& stride, int& orientation, int& format);
extern "C" void releaseWrapImageData(WrapImageData* wrapImageData);