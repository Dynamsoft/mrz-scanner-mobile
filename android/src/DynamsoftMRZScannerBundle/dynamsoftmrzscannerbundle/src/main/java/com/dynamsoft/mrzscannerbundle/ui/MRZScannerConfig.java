package com.dynamsoft.mrzscannerbundle.ui;

import java.io.Serializable;
public class MRZScannerConfig implements Serializable {
	private String license;
	private boolean isTorchButtonVisible = true;
	private boolean isBeepEnabled;
	private boolean isCloseButtonVisible = true;
	private EnumDocumentType documentType;
	private boolean guideFrameVisible = true;
	private boolean isCameraToggleButtonVisible;
	private String templateFile;

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
}
