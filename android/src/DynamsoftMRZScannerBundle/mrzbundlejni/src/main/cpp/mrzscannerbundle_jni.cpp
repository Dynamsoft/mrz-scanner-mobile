#include <jni.h>
#include "Include/DynamsoftCore.h"
#include "Include/DynamsoftUtility.h"
#include "WrapImageData.h"

using namespace dynamsoft::intermediate_results;
using namespace dynamsoft::basic_structures;
using namespace dynamsoft::cvr;
using namespace dynamsoft::ddn;
using namespace dynamsoft::ddn::intermediate_results;
using namespace dynamsoft::dlr::intermediate_results;
using namespace dynamsoft::utility;

//#include "android/log.h"
//#define LOG_TAG "Dynamsoft JNI"
//#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
//#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)

extern "C"
JNIEXPORT jlong JNICALL
Java_com_dynamsoft_mrzscannerbundle_ui_MRZScannerActivity_nativeGetWrapImageDataInstance(JNIEnv *env, jclass clazz, jobject ir_manager, jstring image_hash_id) {
    if (ir_manager == nullptr || image_hash_id == nullptr) {
        return 0;
    }
    jclass clsIRM = env->FindClass("com/dynamsoft/cvr/intermediate_results/IntermediateResultManager");
    jfieldID id = env->GetFieldID(clsIRM, "mInstance", "J");
    jlong instance = env->GetLongField(ir_manager, id);
    if (instance == 0) {
        return 0;
    }
    auto pManager = (CIntermediateResultManager *) instance;
    auto pHashId = env->GetStringUTFChars(image_hash_id, nullptr);
    auto pImage = pManager->GetOriginalImage(pHashId);
    env->ReleaseStringUTFChars(image_hash_id, pHashId);
    env->DeleteLocalRef(clsIRM);
    if (pImage == nullptr) {
        return 0;
    }
    auto wrapImage = new WrapImageData(pImage);
    wrapImage->retain();
    return (jlong) wrapImage;
}

extern "C"
JNIEXPORT jlong JNICALL
Java_com_dynamsoft_mrzscannerbundle_ui_MRZScannerActivity_nativeGetDeskewedWrapImageDataInstance(JNIEnv *env, jclass clazz, jobject ir_manager, jstring image_hash_id,
                                                                                                 jintArray points) {
    if (ir_manager == nullptr || image_hash_id == nullptr || points == nullptr || env->GetArrayLength(points) != 8) {
        return 0;
    }
    jclass clsIRM = env->FindClass("com/dynamsoft/cvr/intermediate_results/IntermediateResultManager");
    jfieldID id = env->GetFieldID(clsIRM, "mInstance", "J");
    jlong instance = env->GetLongField(ir_manager, id);
    if (instance == 0) {
        return 0;
    }
    auto pManager = (CIntermediateResultManager *) instance;
    auto pHashId = env->GetStringUTFChars(image_hash_id, nullptr);
    auto pImage = pManager->GetOriginalImage(pHashId);
    env->ReleaseStringUTFChars(image_hash_id, pHashId);
    env->DeleteLocalRef(clsIRM);
    if (pImage == nullptr) {
        return 0;
    }
    auto pPoints = (int *) env->GetIntArrayElements(points, nullptr);
    CQuadrilateral croppedQuad;
    for (int i = 0; i < 4; i++) {
        croppedQuad.points[i][0] = pPoints[i * 2];
        croppedQuad.points[i][1] = pPoints[i * 2 + 1];
    }
    env->ReleaseIntArrayElements(points, pPoints, JNI_ABORT);
    auto processor = new CImageProcessor();
    int errorCode = 0;
    auto pCroppedImage = processor->CropAndDeskewImage(pImage, croppedQuad, 0, 0, 0, &errorCode);
    delete processor;
    if (errorCode != 0 || pCroppedImage == nullptr) {
        return 0;
    }
    auto wrapImage = new WrapImageData(pCroppedImage);
    wrapImage->retain();
    return (jlong) wrapImage;
}

extern "C"
JNIEXPORT jobject JNICALL
Java_com_dynamsoft_mrzscannerbundle_ui_MRZScanResult_nativeGetImageData(JNIEnv *env, jclass clazz, jlong instance) {
    if (instance == 0) {
        return nullptr;
    }
    auto wrapImage = (WrapImageData *) instance;
    auto image = wrapImage->getImageData();
    jclass clsImageData = env->FindClass("com/dynamsoft/core/basic_structures/ImageData");
    jmethodID initImageData = env->GetMethodID(clsImageData, "<init>", "([BIIIIILcom/dynamsoft/core/basic_structures/ImageTag;)V");
    jbyteArray jbytes = env->NewByteArray((jint) image->GetBytesLength());
    env->SetByteArrayRegion(jbytes, 0, (jint) image->GetBytesLength(), (jbyte *) image->GetBytes());
    jobject jImageData = env->NewObject(clsImageData, initImageData,
                                        jbytes, image->GetWidth(), image->GetHeight(), image->GetStride(), (int) image->GetImagePixelFormat(),
                                        image->GetOrientation(), (jobject) nullptr);
    env->DeleteLocalRef(jbytes);
    env->DeleteLocalRef(clsImageData);
    return jImageData;
}

extern "C"
JNIEXPORT void JNICALL
Java_com_dynamsoft_mrzscannerbundle_ui_MRZScanResult_nativeReleaseImageData(JNIEnv *env, jclass clazz, jlong instance) {
    if (instance == 0) {
        return;
    }
    auto wrapImage = (WrapImageData *) instance;
    wrapImage->release();
}
extern "C"
JNIEXPORT void JNICALL
Java_com_dynamsoft_mrzscannerbundle_ui_MRZScanResult_nativeRetainImageData(JNIEnv *env, jclass clazz, jlong instance) {
    if (instance == 0) {
        return;
    }
    auto wrapImage = (WrapImageData *) instance;
    wrapImage->retain();
}