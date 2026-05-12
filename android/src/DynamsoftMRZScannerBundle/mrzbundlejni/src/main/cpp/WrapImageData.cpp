//
// Created by Allen on 2025/11/3.
//

#include "WrapImageData.h"

std::set<WrapImageData *> WrapImageData::g_wrapImageDataSet;
std::mutex WrapImageData::g_mutex;

void WrapImageData::retain() {
    std::lock_guard<std::mutex> lock(g_mutex);
    if (count == 0) {
        g_wrapImageDataSet.insert(this);
    }
    count++;
}

void WrapImageData::release() {
    std::lock_guard<std::mutex> lock(g_mutex);
    count--;
    if (count <= 0) {
        if(g_wrapImageDataSet.count(this) > 0) {
            g_wrapImageDataSet.erase(this);
            delete this;
            return;
        }
    }
}

CImageData *WrapImageData::getImageData() {
    return pImageData;
}

const unsigned char * getImageDataFromWrapImageData(WrapImageData* wrapImageData, int &bytesLength, int &width, int &height, int &stride, int &orientation, int &format) {
    if (wrapImageData == nullptr) {
        return nullptr;
    }
    bytesLength = (int) wrapImageData->getImageData()->GetBytesLength();
    width = wrapImageData->getImageData()->GetWidth();
    height = wrapImageData->getImageData()->GetHeight();
    stride = wrapImageData->getImageData()->GetStride();
    orientation = wrapImageData->getImageData()->GetOrientation();
    format = (int) wrapImageData->getImageData()->GetImagePixelFormat();
    return wrapImageData->getImageData()->GetBytes();
}

void releaseWrapImageData(WrapImageData* wrapImageData) {
    wrapImageData->release();
}