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

        // Snapshot once: each unit is null until its first callback, and onPause clears them from the main thread.
        ScaledColourImageUnit scaled = scaledColourImageUnit;
        LocalizedTextLinesUnit localized = localizedTextLinesUnit;
        RecognizedTextLinesUnit recognized = recognizedTextLinesUnit;
        DetectedQuadsUnit quads = detectedQuadsUnit;
        DeskewedImageUnit deskewed = deskewedImageUnit;

        Quadrilateral precisePhotoLocation = null;
        if (returnPortraitImage && scaled != null && localized != null && recognized != null
                && quads != null && deskewed != null && quads.getCount() > 0
                // Without a high-confidence portrait zone we return no portrait at all.
                && hasHighConfidencePortraitZone(localized)) {
            precisePhotoLocation = idProcessor.findPortraitZone(scaled, localized, recognized, quads, deskewed);
        }

        if (returnPortraitImage && precisePhotoLocation != null && quadItem != null) {
            if (!isPortraitValid(precisePhotoLocation, quadItem.getLocation())) {
                return;
            }
        }

        ParsedResult parsedResult = result.getParsedResult();
        ParsedResultItem[] items = parsedResult == null ? null : parsedResult.getItems();
        // Guard the index, not just the result: an empty items array is possible here.
        ParsedResultItem parsedResultItem = (items == null || items.length == 0) ? null : items[0];
        MRZData mrzData = MRZData.fromParsedResultItem(parsedResultItem);

        MRZScanResult scanResult = new MRZScanResult();
        scanResult.mrzData = mrzData;

        if (returnOriginalImage) {
            scanResult.imageInstances[mrzData != null ? MRZScanResult.TYPE_MRZ_ORIGINAL : MRZScanResult.TYPE_OTHER_ORIGINAL] =
                    MRZScannerActivity.nativeGetWrapImageDataInstance(getIntermediateResultManager(), result.getOriginalImageHashId());
        }
        if (returnDocumentImage && quadItem != null) {
            scanResult.imageInstances[mrzData != null ? MRZScanResult.TYPE_MRZ_DOCUMENT : MRZScanResult.TYPE_OTHER_DOCUMENT] =
                    MRZScannerActivity.nativeGetDeskewedWrapImageDataInstance(getIntermediateResultManager(), result.getOriginalImageHashId(), flatten(quadItem.getLocation()));
        }
        if (returnPortraitImage && precisePhotoLocation != null) {
            scanResult.imageInstances[MRZScanResult.TYPE_PORTRAIT] =
                    MRZScannerActivity.nativeGetDeskewedWrapImageDataInstance(getIntermediateResultManager(), result.getOriginalImageHashId(), flatten(precisePhotoLocation));
        }

        if (scanResult.mrzData != null) {
            mrzScanResultReceiver.onMRZDataReceived(scanResult);
        } else {
            mrzScanResultReceiver.onNoMRZPageReceived(scanResult);
        }
    }

    private static boolean hasHighConfidencePortraitZone(LocalizedTextLinesUnit unit) {
        for (int i = 0; i < unit.getAuxiliaryRegionElementsCount(); i++) {
            if (unit.getAuxiliaryRegionElement(i).getName().equals("PortraitZone")
                    && unit.getAuxiliaryRegionElement(i).getConfidence() > 60) {
                return true;
            }
        }
        return false;
    }

    /// Area guarded against zero: the original divided by it unchecked.
    private static boolean isPortraitValid(Quadrilateral portrait, Quadrilateral docRegion) {
        if (portrait.getArea() <= 0 || docRegion.getArea() / portrait.getArea() < 3) return false;
        for (int i = 0; i < portrait.points.length; i++) {
            if (!docRegion.isPointInQuadrilateral(portrait.points[i])) return false;
        }
        return true;
    }

    /// Frees the last frame's full-resolution buffers, which would else outlive the scan.
    void releaseIntermediateUnits() {
        scaledColourImageUnit = null;
        localizedTextLinesUnit = null;
        recognizedTextLinesUnit = null;
        detectedQuadsUnit = null;
        deskewedImageUnit = null;
    }

    /// Corner points as the flat int[8] {x0,y0,x1,y1,...} the JNI layer expects.
    private static int[] flatten(Quadrilateral quad) {
        int[] points = new int[quad.points.length * 2];
        for (int i = 0; i < quad.points.length; i++) {
            points[i * 2] = quad.points[i].x;
            points[i * 2 + 1] = quad.points[i].y;
        }
        return points;
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
        // Localized text lines mean MRZ-shaped text, a far tighter signal than a raw quad.
        mrzScanResultReceiver.onTextLineActivity(unit.getCount() > 0);
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

    public void setReturnOriginalImage(boolean returnOriginalImage) {
        this.returnOriginalImage = returnOriginalImage;
    }

    public void setReturnDocumentImage(boolean returnDocumentImage) {
        this.returnDocumentImage = returnDocumentImage;
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

    public interface MRZScanResultReceiver {
        /// Per frame; true when the frame localized text lines. Drives the MRZ-search spinner.
        default void onTextLineActivity(boolean textLineLocalized) {
        }

        /// MRZData recognized. TYPE_MRZ_DOCUMENT is 0 unless returnDocumentImage; TYPE_PORTRAIT may be 0.
        default void onMRZDataReceived(@NonNull MRZScanResult scanResult) {
        }

        /// No MRZData, but a non-MRZ page was detected. Same slot caveats as above.
        default void onNoMRZPageReceived(@NonNull MRZScanResult scanResult) {
        }
    }
}
