package com.dynamsoft.mrzscannerbundle.ui;

import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.dynamsoft.core.basic_structures.EnumCrossVerificationStatus;
import com.dynamsoft.core.basic_structures.Quadrilateral;
import com.dynamsoft.core.intermediate_results.IntermediateResultExtraInfo;
import com.dynamsoft.core.intermediate_results.ScaledColourImageUnit;
import com.dynamsoft.cvr.CaptureVisionRouter;
import com.dynamsoft.cvr.CaptureVisionRouterException;
import com.dynamsoft.cvr.CapturedResult;
import com.dynamsoft.cvr.CapturedResultReceiver;
import com.dynamsoft.cvr.intermediate_results.IntermediateResultReceiver;
import com.dynamsoft.dcp.ParsedResult;
import com.dynamsoft.dcp.ParsedResultItem;
import com.dynamsoft.ddn.DetectedQuadResultItem;
import com.dynamsoft.ddn.ProcessedDocumentResult;
import com.dynamsoft.ddn.intermediate_results.DeskewedImageUnit;
import com.dynamsoft.ddn.intermediate_results.DetectedQuadsUnit;
import com.dynamsoft.diu.IdentityProcessor;
import com.dynamsoft.dlr.intermediate_results.LocalizedTextLinesUnit;
import com.dynamsoft.dlr.intermediate_results.RecognizedTextLinesUnit;

class MRZScanner extends CaptureVisionRouter implements CapturedResultReceiver, IntermediateResultReceiver {
    private static final String TAG = "MRZScanner";
    private boolean returnOriginalImage = true;
    private boolean returnDocumentImage = true;
    private boolean returnPortraitImage = true;
    private final IdentityProcessor idProcessor = new IdentityProcessor();
    @NonNull
    private MRZScanResultReceiver mrzScanResultReceiver = new MRZScanResultReceiver() {
    };

    static {
        System.loadLibrary("DynamsoftMRZScannerBundleJni");
    }

    public MRZScanner() {
        super();
        try {
            initSettingsFromFile("mrzscanner-mobile-templates.json");
        } catch (CaptureVisionRouterException e) {
            e.printStackTrace();
        }
        addResultReceiver(this);
        getIntermediateResultManager().addResultReceiver(this);
    }

    @Override
    public void onCapturedResultReceived(@NonNull CapturedResult result) {
        DetectedQuadResultItem quadItem = null;
        ProcessedDocumentResult documentResult = result.getProcessedDocumentResult();
        if (documentResult != null && documentResult.getDetectedQuadResultItems().length > 0) {
            if (documentResult.getDetectedQuadResultItems()[0].getCrossVerificationStatus() != EnumCrossVerificationStatus.CVS_FAILED) {
                quadItem = documentResult.getDetectedQuadResultItems()[0];
            }
        }
        if(returnDocumentImage && quadItem == null) {
            return;
        }

        Quadrilateral precisePhotoLocation = null;
        if (returnPortraitImage) {
            int highConfidencePortraitZoneIndex = -1;
            if(localizedTextLinesUnit.getAuxiliaryRegionElementsCount() > 0) {
                for(int i = 0; i < localizedTextLinesUnit.getAuxiliaryRegionElementsCount(); i++) {
                    if(localizedTextLinesUnit.getAuxiliaryRegionElement(i).getName().equals("PortraitZone")) {
                        if(localizedTextLinesUnit.getAuxiliaryRegionElement(i).getConfidence() > 60) {
                            highConfidencePortraitZoneIndex = i;
                            break;
                        }
                    }
                }
            }
            // If there is no high confidence portrait zone, we will not return portrait image,
            // and we will not run the identity processor to find a less precise portrait zone.
            int detectedQuadsCount = detectedQuadsUnit == null ? 0 : detectedQuadsUnit.getCount();
            if (highConfidencePortraitZoneIndex != -1 && detectedQuadsCount > 0) {
                precisePhotoLocation = idProcessor.findPortraitZone(scaledColourImageUnit, localizedTextLinesUnit,
                        recognizedTextLinesUnit, detectedQuadsUnit, deskewedImageUnit);
            } /*else {precisePhotoLocation = null}*/
        }

        if (returnPortraitImage && precisePhotoLocation != null && quadItem != null) {
            Quadrilateral docRegion = quadItem.getLocation();
            boolean isValid = docRegion.isPointInQuadrilateral(precisePhotoLocation.points[0])
                    && docRegion.isPointInQuadrilateral(precisePhotoLocation.points[1])
                    && docRegion.isPointInQuadrilateral(precisePhotoLocation.points[2])
                    && docRegion.isPointInQuadrilateral(precisePhotoLocation.points[3])
                    && docRegion.getArea() / precisePhotoLocation.getArea() >= 3;
            if (!isValid) {
                return;
            }
        }


        ParsedResult parsedResult = result.getParsedResult();
        ParsedResultItem parsedResultItem = parsedResult == null ? null : parsedResult.getItems()[0];
        MRZData mrzData = MRZData.fromParsedResultItem(parsedResultItem);

        MRZScanResult scanResult = new MRZScanResult();
        Log.e(TAG, "onCapturedResultReceived: "+scanResult);
        scanResult.mrzData = mrzData;

        if (returnOriginalImage) {
            long originalInstance = MRZScannerActivity.nativeGetWrapImageDataInstance(getIntermediateResultManager(), result.getOriginalImageHashId());
            if (mrzData != null) {
                scanResult.mrzPageOriginalImageInstance = originalInstance;
            } else {
                scanResult.anotherPageOriginalImageInstance = originalInstance;
            }
        }
        if (returnDocumentImage && quadItem != null) {
            int[] points = new int[quadItem.getLocation().points.length * 2];
            for (int i = 0; i < quadItem.getLocation().points.length; i++) {
                points[i * 2] = quadItem.getLocation().points[i].x;
                points[i * 2 + 1] = quadItem.getLocation().points[i].y;
            }
            long docInstance = MRZScannerActivity.nativeGetDeskewedWrapImageDataInstance(getIntermediateResultManager(), result.getOriginalImageHashId(), points);
            if (mrzData != null) {
                scanResult.mrzPageDocumentImageInstance = docInstance;
            } else {
                scanResult.anotherPageDocumentImageInstance = docInstance;
            }
        }

        if (returnPortraitImage && precisePhotoLocation != null) {
            int[] points = new int[precisePhotoLocation.points.length * 2];
            for (int i = 0; i < precisePhotoLocation.points.length; i++) {
                points[i * 2] = precisePhotoLocation.points[i].x;
                points[i * 2 + 1] = precisePhotoLocation.points[i].y;
            }
            scanResult.portraitImageInstance = MRZScannerActivity.nativeGetDeskewedWrapImageDataInstance(getIntermediateResultManager(), result.getOriginalImageHashId(), points);
        }

        if (scanResult.mrzData != null) {
            mrzScanResultReceiver.onMRZDataReceived(scanResult);
        } else {
            mrzScanResultReceiver.onNoMRZPageReceived(scanResult);
        }

    }


    ScaledColourImageUnit scaledColourImageUnit;
    LocalizedTextLinesUnit localizedTextLinesUnit;
    RecognizedTextLinesUnit recognizedTextLinesUnit;
    DetectedQuadsUnit detectedQuadsUnit;
    DeskewedImageUnit deskewedImageUnit;

    @Override
    public void onScaledColourImageUnitReceived(@NonNull ScaledColourImageUnit unit, IntermediateResultExtraInfo info) {
        scaledColourImageUnit = unit;
    }

    @Override
    public void onLocalizedTextLinesReceived(@NonNull LocalizedTextLinesUnit unit, IntermediateResultExtraInfo info) {
        localizedTextLinesUnit = unit;
    }

    @Override
    public void onRecognizedTextLinesReceived(@NonNull RecognizedTextLinesUnit unit, IntermediateResultExtraInfo info) {
        recognizedTextLinesUnit = unit;
    }

    @Override
    public void onDetectedQuadsReceived(@NonNull DetectedQuadsUnit unit, IntermediateResultExtraInfo info) {
        detectedQuadsUnit = unit;
    }

    @Override
    public void onDeskewedImageReceived(@NonNull DeskewedImageUnit unit, IntermediateResultExtraInfo info) {
        deskewedImageUnit = unit;
    }

    public boolean isReturnOriginalImage() {
        return returnOriginalImage;
    }

    public void setReturnOriginalImage(boolean returnOriginalImage) {
        this.returnOriginalImage = returnOriginalImage;
    }

    public boolean isReturnDocumentImage() {
        return returnDocumentImage;
    }

    public void setReturnDocumentImage(boolean returnDocumentImage) {
        this.returnDocumentImage = returnDocumentImage;
    }

    public boolean isReturnPortraitImage() {
        return returnPortraitImage;
    }

    public void setReturnPortraitImage(boolean returnPortraitImage) {
        this.returnPortraitImage = returnPortraitImage;
    }

    public void setMRZDataReceiver(@Nullable MRZScanResultReceiver mrzScanResultReceiver) {
        if (mrzScanResultReceiver == null) {
            mrzScanResultReceiver = new MRZScanResultReceiver() {
            };
        }
        this.mrzScanResultReceiver = mrzScanResultReceiver;
    }

    //return int[8] for Quad

    public interface MRZScanResultReceiver {
        default void onMRZDataReceived(@NonNull MRZScanResult scanResult) {
            // Entering this callback means MRZData has been recognized, scanResult.mrzData != null;
            // MRZ Document Image has also been detected; whether scanResult.mrzPageDocumentImageInstance is 0 depends on whether returnDocumentImage is set to true;
            // Portrait Image may or may not be detected, scanResult.portraitImageInstance may be 0
        }

        default void onNoMRZPageReceived(@NonNull MRZScanResult scanResult) {
            // Entering this callback means no MRZData has been recognized, scanResult.mrzData == null;
            // A non-MRZ Page Document Image has been detected; whether scanResult.anotherPageDocumentImageInstance is 0 depends on whether returnDocumentImage is set to true;
            // Portrait Image may or may not be detected, scanResult.portraitImageInstance may be 0
        }
    }

}
