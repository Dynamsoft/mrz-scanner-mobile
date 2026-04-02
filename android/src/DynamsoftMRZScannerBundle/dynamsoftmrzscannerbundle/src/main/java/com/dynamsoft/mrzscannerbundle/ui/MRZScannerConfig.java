package com.dynamsoft.mrzscannerbundle.ui;

import com.dynamsoft.dce.EnumCameraPosition;
import com.dynamsoft.utility.CrossVerificationCriteria;

import java.io.Serializable;
public class MRZScannerConfig implements Serializable {
	private String license;
	private boolean isTorchButtonVisible = true;
    private boolean isFormatSelectorVisible = true;
	private boolean isBeepEnabled;
    private boolean isBeepButtonVisible = true;
	private boolean isVibrateEnabled;
    private boolean isVibrateButtonVisible = true;
	private boolean isCloseButtonVisible = true;
	private EnumDocumentType documentType = EnumDocumentType.DT_ALL;
	private boolean guideFrameVisible = true;
	private boolean isCameraToggleButtonVisible = true;
    private boolean returnOriginalImage = false;
    private boolean returnDocumentImage = true;
    private boolean returnPortraitImage = true;
    private int frameWindow = 5;
    private int minConsistentFrames = 2;
    private int minDocumentAreaRatio = 2;

	int cameraPosition = EnumCameraPosition.CP_BACK;

	private String templateFile;

	float zoomFactor = 1f;

	public boolean isCloseButtonVisible() {
		return isCloseButtonVisible;
	}

	public void setCloseButtonVisible(boolean closeButtonVisible) {
		isCloseButtonVisible = closeButtonVisible;
	}

	public boolean isBeepEnabled() {
		return isBeepEnabled;
	}

	public void setBeepEnabled(boolean beepEnabled) {
		isBeepEnabled = beepEnabled;
	}

	public boolean isVibrateEnabled() {
		return isVibrateEnabled;
	}

	public void setVibrateEnabled(boolean vibrateEnabled) {
		isVibrateEnabled = vibrateEnabled;
	}

	public boolean isTorchButtonVisible() {
		return isTorchButtonVisible;
	}

	public void setTorchButtonVisible(boolean torchButtonVisible) {
		isTorchButtonVisible = torchButtonVisible;
	}

	public String getLicense() {
		return license;
	}

	public void setLicense(String license) {
		this.license = license;
	}

	public EnumDocumentType getDocumentType() {
		return documentType;
	}

	public void setDocumentType(EnumDocumentType documentType) {
		this.documentType = documentType;
	}

	public boolean isGuideFrameVisible() {
		return guideFrameVisible;
	}

	public void setGuideFrameVisible(boolean guideFrameVisible) {
		this.guideFrameVisible = guideFrameVisible;
	}

	public String getTemplateFile() {
		return templateFile;
	}

	public void setTemplateFile(String templateFile) {
		this.templateFile = templateFile;
	}

	public boolean isCameraToggleButtonVisible() {
		return isCameraToggleButtonVisible;
	}

	public void setCameraToggleButtonVisible(boolean cameraToggleButtonVisible) {
		isCameraToggleButtonVisible = cameraToggleButtonVisible;
	}

    //Newly Added in 3.4.1000
    public boolean isReturnDocumentImage() {
        return returnDocumentImage;
    }

    //Newly Added in 3.4.1000
    public void setReturnDocumentImage(boolean returnDocumentImage) {
        this.returnDocumentImage = returnDocumentImage;
    }

    //Newly Added in 3.4.1000
    public boolean isReturnOriginalImage() {
        return returnOriginalImage;
    }

    //Newly Added in 3.4.1000
    public void setReturnOriginalImage(boolean returnOriginalImage) {
        this.returnOriginalImage = returnOriginalImage;
    }

    //Newly Added in 3.4.1000
    public boolean isReturnPortraitImage() {
        return returnPortraitImage;
    }

    //Newly Added in 3.4.1000
    public void setReturnPortraitImage(boolean returnPortraitImage) {
        this.returnPortraitImage = returnPortraitImage;
    }

    //Newly Added in 3.4.1000
    public void setBeepButtonVisible(boolean isVisible) {
        this.isBeepButtonVisible = isVisible;
    }

    //Newly Added in 3.4.1000
    public boolean isBeepButtonVisible() {
        return isBeepButtonVisible;
    }

    //Newly Added in 3.4.1000
    public void setVibrateButtonVisible(boolean isVisible) {
        this.isVibrateButtonVisible = isVisible;
    }

    //Newly Added in 3.4.1000
    public boolean isVibrateButtonVisible() {
        return isVibrateButtonVisible;
    }

    //Newly Added in 3.4.1000
    public void setFormatSelectorVisible(boolean isVisible) {
        this.isFormatSelectorVisible = isVisible;
    }

    //Newly Added in 3.4.1000
    public boolean isFormatSelectorVisible() {
        return isFormatSelectorVisible;
    }

    //For Test
    void setCriteria(CrossVerificationCriteria criteria) {
        this.frameWindow = criteria.getFrameWindow();
        this.minConsistentFrames = criteria.getMinConsistentFrames();
    }

    //For Test
    CrossVerificationCriteria getCriteria() {
        return new CrossVerificationCriteria(frameWindow, minConsistentFrames);
    }

    //For Test
    int getMinDocumentAreaRatio() {
        return minDocumentAreaRatio;
    }

    //For Test
    void setMinDocumentAreaRatio(int minDocumentAreaRatio) {
        this.minDocumentAreaRatio = minDocumentAreaRatio;
    }
}
