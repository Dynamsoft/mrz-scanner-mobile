package com.dynamsoft.mrzscannerbundle.ui;

import static com.dynamsoft.mrzscannerbundle.ui.MRZScanResult.EnumResultStatus.RS_CANCELED;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScanResult.EnumResultStatus.RS_EXCEPTION;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScanResult.EnumResultStatus.RS_FINISHED;

import android.os.Parcel;
import android.os.Parcelable;

import androidx.annotation.IntDef;
import androidx.annotation.Nullable;
import androidx.annotation.RestrictTo;

import com.dynamsoft.core.basic_structures.ImageData;

public final class MRZScanResult implements Parcelable {
    final static String EXTRA = "MRZScanResult";

    @EnumResultStatus
    int resultStatus;
    int errorCode;
    String errorString;
    MRZData mrzData;
    long mrzPageOriginalImageInstance;
    long mrzPageDocumentImageInstance;
    long anotherPageOriginalImageInstance;
    long anotherPageDocumentImageInstance;
    long portraitImageInstance;
    transient ImageData primaryOriginalImage;
    transient ImageData primaryDocumentImage;
    transient ImageData secondaryOriginalImage;
    transient ImageData secondaryDocumentImage;
    transient ImageData portraitImage;


    @IntDef(value = {RS_FINISHED, RS_CANCELED, RS_EXCEPTION})
    public @interface EnumResultStatus {
        int RS_FINISHED = 0;
        int RS_CANCELED = 1;
        int RS_EXCEPTION = 2;
    }

    public MRZScanResult() {
    }

    private MRZScanResult(Parcel in) {
        resultStatus = in.readInt();
        errorCode = in.readInt();
        errorString = in.readString();
        mrzData = (MRZData) in.readSerializable();
        mrzPageOriginalImageInstance = in.readLong();
        mrzPageDocumentImageInstance = in.readLong();
        anotherPageOriginalImageInstance = in.readLong();
        anotherPageDocumentImageInstance = in.readLong();
        portraitImageInstance = in.readLong();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeInt(resultStatus);
        dest.writeInt(errorCode);
        dest.writeString(errorString);
        dest.writeSerializable(mrzData);
        dest.writeLong(mrzPageOriginalImageInstance);
        dest.writeLong(mrzPageDocumentImageInstance);
        dest.writeLong(anotherPageOriginalImageInstance);
        dest.writeLong(anotherPageDocumentImageInstance);
        dest.writeLong(portraitImageInstance);

        retainAllImageInstances();
    }

    @Override
    public int describeContents() {
        return 0;
    }

    public static final Creator<MRZScanResult> CREATOR = new Creator<>() {
        @Override
        public MRZScanResult createFromParcel(Parcel in) {
            return new MRZScanResult(in);
        }

        @Override
        public MRZScanResult[] newArray(int size) {
            return new MRZScanResult[size];
        }
    };


    public MRZData getData() {
        return mrzData;
    }

    @EnumResultStatus
    public int getResultStatus() {
        return resultStatus;
    }

    public int getErrorCode() {
        return errorCode;
    }

    public String getErrorString() {
        return errorString;
    }

    @Nullable
    public ImageData getDocumentImage(EnumDocumentSide documentSide) {
        if(documentSide == EnumDocumentSide.DS_MRZ) {
            return getPrimaryDocumentImage();
        } else {
            return getSecondaryDocumentImage();
        }
    }

    @Nullable
    public ImageData getOriginalImage(EnumDocumentSide documentSide) {
        if(documentSide == EnumDocumentSide.DS_MRZ) {
            return getPrimaryOriginalImage();
        } else {
            return getSecondaryOriginalImage();
        }
    }

    @Nullable
    private ImageData getPrimaryOriginalImage() {
        if (mrzPageOriginalImageInstance == 0) {
            return null;
        }
        if (primaryOriginalImage == null) {
            primaryOriginalImage = nativeGetImageData(mrzPageOriginalImageInstance);
        }
        return primaryOriginalImage;
    }

    @Nullable
    private ImageData getPrimaryDocumentImage() {
        if (mrzPageDocumentImageInstance == 0) {
            return null;
        }
        if (primaryDocumentImage == null) {
            primaryDocumentImage = nativeGetImageData(mrzPageDocumentImageInstance);
        }
        return primaryDocumentImage;
    }

    @Nullable
    private ImageData getSecondaryOriginalImage() {
        if (anotherPageOriginalImageInstance == 0) {
            return null;
        }
        if (secondaryOriginalImage == null) {
            secondaryOriginalImage = nativeGetImageData(anotherPageOriginalImageInstance);
        }
        return secondaryOriginalImage;
    }

    @Nullable
    private ImageData getSecondaryDocumentImage() {
        if (anotherPageDocumentImageInstance == 0) {
            return null;
        }
        if (secondaryDocumentImage == null) {
            secondaryDocumentImage = nativeGetImageData(anotherPageDocumentImageInstance);
        }
        return secondaryDocumentImage;
    }

    @Nullable
    public ImageData getPortraitImage() {
        if (portraitImageInstance == 0) {
            return null;
        }
        if (portraitImage == null) {
            portraitImage = nativeGetImageData(portraitImageInstance);
        }
        return portraitImage;
    }


    @RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
    public long _getImageInstance(int type) {
        switch (type) {
            case 0:
                return mrzPageOriginalImageInstance;
            case 1:
                return mrzPageDocumentImageInstance;
            case 2:
                return anotherPageOriginalImageInstance;
            case 3:
                return anotherPageDocumentImageInstance;
            case 4:
                return portraitImageInstance;
            default:
                return 0;
        }
    }

    @RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
    public void retainAllImageInstances() {
        nativeRetainImageData(mrzPageOriginalImageInstance);
        nativeRetainImageData(mrzPageDocumentImageInstance);
        nativeRetainImageData(portraitImageInstance);
        nativeRetainImageData(anotherPageOriginalImageInstance);
        nativeRetainImageData(anotherPageDocumentImageInstance);
    }

    @Override
    protected void finalize() throws Throwable {
        super.finalize();
        if (mrzPageOriginalImageInstance != 0) {
            nativeReleaseImageData(mrzPageOriginalImageInstance);
            mrzPageOriginalImageInstance = 0;
        }
        if (mrzPageDocumentImageInstance != 0) {
            nativeReleaseImageData(mrzPageDocumentImageInstance);
            mrzPageDocumentImageInstance = 0;
        }
        if (portraitImageInstance != 0) {
            nativeReleaseImageData(portraitImageInstance);
            portraitImageInstance = 0;
        }
        if (anotherPageOriginalImageInstance != 0) {
            nativeReleaseImageData(anotherPageOriginalImageInstance);
            anotherPageOriginalImageInstance = 0;
        }
        if (anotherPageDocumentImageInstance != 0) {
            nativeReleaseImageData(anotherPageDocumentImageInstance);
            anotherPageDocumentImageInstance = 0;
        }
    }

    static native ImageData nativeGetImageData(long instance);

    static native void nativeRetainImageData(long instance);

    static native void nativeReleaseImageData(long instance);
}
