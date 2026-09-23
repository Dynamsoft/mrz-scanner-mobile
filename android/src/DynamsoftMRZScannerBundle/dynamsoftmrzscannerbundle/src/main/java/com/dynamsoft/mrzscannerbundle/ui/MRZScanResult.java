package com.dynamsoft.mrzscannerbundle.ui;

import static com.dynamsoft.mrzscannerbundle.ui.MRZScanResult.EnumResultStatus.RS_CANCELED;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScanResult.EnumResultStatus.RS_EXCEPTION;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScanResult.EnumResultStatus.RS_FINISHED;

import android.os.Parcel;
import android.os.Parcelable;

import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;

import androidx.annotation.IntDef;
import androidx.annotation.Nullable;
import androidx.annotation.RestrictTo;

import com.dynamsoft.core.basic_structures.ImageData;

public final class MRZScanResult implements Parcelable {
    final static String EXTRA = "MRZScanResult";

    // Eager load, else a result unparceled on a fresh process hits native before the shim loads (issue #30).
    static {
        System.loadLibrary("DynamsoftMRZScannerBundleJni");
    }

    /// Index into {@link #imageInstances}, the parcel order, and the {@code type} for {@link #_getImageInstance}. Do not reorder.
    static final int TYPE_MRZ_ORIGINAL = 0;
    static final int TYPE_MRZ_DOCUMENT = 1;
    static final int TYPE_OTHER_ORIGINAL = 2;
    static final int TYPE_OTHER_DOCUMENT = 3;
    static final int TYPE_PORTRAIT = 4;
    private static final int TYPE_COUNT = 5;

    @EnumResultStatus
    int resultStatus;
    int errorCode;
    String errorString;
    MRZData mrzData;
    /// Native WrapImageData pointers, indexed by the TYPE_* constants above. 0 means absent.
    final long[] imageInstances = new long[TYPE_COUNT];
    /// Lazily materialized ImageData per slot; allocated on first use.
    transient ImageData[] cachedImages;

    @IntDef(value = {RS_FINISHED, RS_CANCELED, RS_EXCEPTION})
    public @interface EnumResultStatus {
        int RS_FINISHED = 0;
        int RS_CANCELED = 1;
        int RS_EXCEPTION = 2;
    }

    /**
     * Error codes owned by this bundle, reported via {@link #getErrorCode()} with
     * {@link EnumResultStatus#RS_EXCEPTION}. Capture Vision's own codes are all {@code <= 0}, so the
     * positive 1000-1999 range is reserved here and matches iOS; the sign tells the two apart.
     */
    @Retention(RetentionPolicy.SOURCE)
    @IntDef(value = {EnumErrorCode.EC_CAMERA_PERMISSION_DENIED,
            EnumErrorCode.EC_CAMERA_PERMISSION_RESTRICTED})
    public @interface EnumErrorCode {
        /// Denied but still grantable — by a fresh in-app request, or via Settings once permanent.
        int EC_CAMERA_PERMISSION_DENIED = 1001;

        /// Withheld by device policy; the user cannot grant it, so Settings would be a dead end.
        int EC_CAMERA_PERMISSION_RESTRICTED = 1002;
    }

    public MRZScanResult() {
    }

    private MRZScanResult(Parcel in) {
        resultStatus = in.readInt();
        errorCode = in.readInt();
        errorString = in.readString();
        mrzData = (MRZData) in.readSerializable();
        // Read as bare longs in TYPE_* order, matching writeToParcel.
        for (int type = 0; type < TYPE_COUNT; type++) {
            imageInstances[type] = in.readLong();
        }

        // Retain on read, not write: the framework may parcel an Intent more often than it unparcels (issue #64).
        retainAllImageInstances();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeInt(resultStatus);
        dest.writeInt(errorCode);
        dest.writeString(errorString);
        dest.writeSerializable(mrzData);
        for (long instance : imageInstances) {
            dest.writeLong(instance);
        }

        // No retain here — the unparceled peer takes its own in the Parcel constructor (issue #64).
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
        return imageOfType(documentSide == EnumDocumentSide.DS_MRZ ? TYPE_MRZ_DOCUMENT : TYPE_OTHER_DOCUMENT);
    }

    @Nullable
    public ImageData getOriginalImage(EnumDocumentSide documentSide) {
        return imageOfType(documentSide == EnumDocumentSide.DS_MRZ ? TYPE_MRZ_ORIGINAL : TYPE_OTHER_ORIGINAL);
    }

    @Nullable
    public ImageData getPortraitImage() {
        return imageOfType(TYPE_PORTRAIT);
    }

    /// Materializes the image for one slot on first access and caches it.
    @Nullable
    private ImageData imageOfType(int type) {
        if (imageInstances[type] == 0) {
            return null;
        }
        if (cachedImages == null) {
            cachedImages = new ImageData[TYPE_COUNT];
        }
        if (cachedImages[type] == null) {
            cachedImages[type] = nativeGetImageData(imageInstances[type]);
        }
        return cachedImages[type];
    }

    @RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
    public long _getImageInstance(int type) {
        return type >= 0 && type < TYPE_COUNT ? imageInstances[type] : 0;
    }

    @RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
    public void retainAllImageInstances() {
        for (long instance : imageInstances) {
            if (instance != 0) nativeRetainImageData(instance);
        }
    }

    /// Drops and forgets every native instance; idempotent, so a later call or finalize() is a no-op.
    @RestrictTo(RestrictTo.Scope.LIBRARY_GROUP)
    public void releaseAllImageInstances() {
        for (int type = 0; type < TYPE_COUNT; type++) {
            if (imageInstances[type] != 0) {
                nativeReleaseImageData(imageInstances[type]);
                imageInstances[type] = 0;
            }
        }
        cachedImages = null;
    }

    @Override
    protected void finalize() throws Throwable {
        super.finalize();
        releaseAllImageInstances();
    }

    static native ImageData nativeGetImageData(long instance);

    static native void nativeRetainImageData(long instance);

    static native void nativeReleaseImageData(long instance);
}
