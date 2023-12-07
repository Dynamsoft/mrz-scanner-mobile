package com.dynamsoft.dlr;

import com.dynamsoft.core.ImageData;

public interface MRZResultListener {
    void mrzResultCallback(int frameId, ImageData imgData, MRZResult result);
}
