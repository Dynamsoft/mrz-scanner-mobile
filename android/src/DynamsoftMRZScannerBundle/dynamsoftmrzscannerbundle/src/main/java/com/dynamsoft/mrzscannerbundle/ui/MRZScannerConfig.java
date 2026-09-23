package com.dynamsoft.mrzscannerbundle.ui;

import com.dynamsoft.dce.EnumCameraPosition;
import com.dynamsoft.utility.CrossVerificationCriteria;

import java.io.Serializable;

public class MRZScannerConfig implements Serializable {
    private static final long serialVersionUID = 1L; // Never change: saved-state configs from older builds must still read.
    private String license;
    private String templateFile;
    private EnumDocumentType documentType = EnumDocumentType.DT_ALL;
    private boolean isTorchButtonVisible = true;
    private boolean isFormatSelectorVisible = true;
    private boolean isBeepEnabled;
    private boolean isBeepButtonVisible = true;
    private boolean isVibrateEnabled;
    private boolean isVibrateButtonVisible = true;
    private boolean isCloseButtonVisible = true;
    private boolean guideFrameVisible = true;
    private boolean isCameraToggleButtonVisible = true;
    private boolean cameraPermissionPromptEnabled = true;
    private boolean returnOriginalImage = false;
    private boolean returnDocumentImage = true;
    private boolean returnPortraitImage = true;
    private int frameWindow = 5;
    private int minConsistentFrames = 2;
    private int minDocumentAreaRatio = 2;

    int cameraPosition = EnumCameraPosition.CP_BACK;
    float zoomFactor = 1f;

    public String getLicense() { return license; }

    public void setLicense(String license) { this.license = license; }

    public String getTemplateFile() { return templateFile; }

    public void setTemplateFile(String templateFile) { this.templateFile = templateFile; }

    public EnumDocumentType getDocumentType() { return documentType; }

    public void setDocumentType(EnumDocumentType documentType) { this.documentType = documentType; }

    public boolean isCloseButtonVisible() { return isCloseButtonVisible; }

    public void setCloseButtonVisible(boolean closeButtonVisible) { isCloseButtonVisible = closeButtonVisible; }

    public boolean isBeepEnabled() { return isBeepEnabled; }

    public void setBeepEnabled(boolean beepEnabled) { isBeepEnabled = beepEnabled; }

    public boolean isVibrateEnabled() { return isVibrateEnabled; }

    public void setVibrateEnabled(boolean vibrateEnabled) { isVibrateEnabled = vibrateEnabled; }

    public boolean isTorchButtonVisible() { return isTorchButtonVisible; }

    public void setTorchButtonVisible(boolean torchButtonVisible) { isTorchButtonVisible = torchButtonVisible; }

    public boolean isGuideFrameVisible() { return guideFrameVisible; }

    public void setGuideFrameVisible(boolean guideFrameVisible) { this.guideFrameVisible = guideFrameVisible; }

    public boolean isCameraToggleButtonVisible() { return isCameraToggleButtonVisible; }

    public void setCameraToggleButtonVisible(boolean cameraToggleButtonVisible) { isCameraToggleButtonVisible = cameraToggleButtonVisible; }

    // --- Added in 3.4.1000 ---

    public boolean isReturnDocumentImage() { return returnDocumentImage; }

    public void setReturnDocumentImage(boolean returnDocumentImage) { this.returnDocumentImage = returnDocumentImage; }

    public boolean isReturnOriginalImage() { return returnOriginalImage; }

    public void setReturnOriginalImage(boolean returnOriginalImage) { this.returnOriginalImage = returnOriginalImage; }

    public boolean isReturnPortraitImage() { return returnPortraitImage; }

    public void setReturnPortraitImage(boolean returnPortraitImage) { this.returnPortraitImage = returnPortraitImage; }

    public boolean isBeepButtonVisible() { return isBeepButtonVisible; }

    public void setBeepButtonVisible(boolean isVisible) { this.isBeepButtonVisible = isVisible; }

    public boolean isVibrateButtonVisible() { return isVibrateButtonVisible; }

    public void setVibrateButtonVisible(boolean isVisible) { this.isVibrateButtonVisible = isVisible; }

    public boolean isFormatSelectorVisible() { return isFormatSelectorVisible; }

    public void setFormatSelectorVisible(boolean isVisible) { this.isFormatSelectorVisible = isVisible; }

    // --- Added in 3.6.2000 ---

    /**
     * Whether a denied camera shows a dialog offering to grant or open Settings before reporting.
     * Either way the denial arrives as {@link MRZScanResult.EnumErrorCode#EC_CAMERA_PERMISSION_DENIED}
     * or {@link MRZScanResult.EnumErrorCode#EC_CAMERA_PERMISSION_RESTRICTED} and the camera never starts.
     */
    public boolean isCameraPermissionPromptEnabled() { return cameraPermissionPromptEnabled; }

    public void setCameraPermissionPromptEnabled(boolean cameraPermissionPromptEnabled) { this.cameraPermissionPromptEnabled = cameraPermissionPromptEnabled; }

    // --- Package-private tuning hooks, for tests ---

    void setCriteria(CrossVerificationCriteria criteria) {
        this.frameWindow = criteria.getFrameWindow();
        this.minConsistentFrames = criteria.getMinConsistentFrames();
    }

    CrossVerificationCriteria getCriteria() { return new CrossVerificationCriteria(frameWindow, minConsistentFrames); }

    int getMinDocumentAreaRatio() { return minDocumentAreaRatio; }

    void setMinDocumentAreaRatio(int minDocumentAreaRatio) { this.minDocumentAreaRatio = minDocumentAreaRatio; }
}
