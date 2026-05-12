package com.dynamsoft.mrzscannerbundle.ui;

import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.view.Window;
import android.widget.ImageView;

import androidx.activity.OnBackPressedCallback;
import androidx.activity.result.contract.ActivityResultContract;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;

import com.dynamsoft.core.basic_structures.CompletionListener;
import com.dynamsoft.core.basic_structures.EnumCapturedResultItemType;
import com.dynamsoft.core.basic_structures.EnumColourChannelUsageType;
import com.dynamsoft.cvr.CaptureVisionRouterException;
import com.dynamsoft.cvr.SimplifiedCaptureVisionSettings;
import com.dynamsoft.cvr.intermediate_results.IntermediateResultManager;
import com.dynamsoft.dce.CameraEnhancer;
import com.dynamsoft.dce.CameraEnhancerException;
import com.dynamsoft.dce.CameraView;
import com.dynamsoft.dce.DrawingLayer;
import com.dynamsoft.dce.EnumCameraPosition;
import com.dynamsoft.dce.EnumCameraState;
import com.dynamsoft.dce.EnumEnhancerFeatures;
import com.dynamsoft.dce.Feedback;
import com.dynamsoft.dce.utils.PermissionUtil;
import com.dynamsoft.license.LicenseManager;
import com.dynamsoft.mrzscannerbundle.R;
import com.dynamsoft.utility.MultiFrameResultCrossFilter;

import java.util.Arrays;
import java.util.List;

public class MRZScannerActivity extends AppCompatActivity {
    public final static String EXTRA_SCANNER_CONFIG = "scanner_config";
    private static final String KEY_CONFIG = "CONFIG";
    private static final String TAG = "MRZScannerActivity";

    static {
        System.loadLibrary("DynamsoftMRZScannerBundleJni");
    }

    private CameraEnhancer mCamera;
    private CameraView mCameraView;
    private final MRZScanner mScanner = new MRZScanner();
    private String mCurrentTemplate = "ReadPassportAndId";
    private MRZScannerConfig configuration;
    private CaptureVisionRouterException exceptionWhenConfigCvr;

    private MRZScanResult mergeResult = null;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_mrzscanner);
        PermissionUtil.requestCameraPermission(this);

        Window window = getWindow();
        if (window != null) {
            WindowInsetsControllerCompat wic = new WindowInsetsControllerCompat(window, window.getDecorView());
            wic.setAppearanceLightStatusBars(false);
            wic.setAppearanceLightNavigationBars(false);
        }
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, 0, systemBars.right, systemBars.bottom);

            findViewById(R.id.status_bar_background).getLayoutParams().height = systemBars.top;
            return WindowInsetsCompat.CONSUMED;
        });

        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                resultCanceled();
                mergeResult = null;
            }
        });

        if (savedInstanceState != null) {
            configuration = (MRZScannerConfig) savedInstanceState.getSerializable(KEY_CONFIG);
        }

        if (configuration == null) {
            Intent requestIntent = getIntent();
            if (requestIntent != null) {
                configuration = (MRZScannerConfig) requestIntent.getSerializableExtra(EXTRA_SCANNER_CONFIG);
            }
        }
        assert configuration != null;

        // Initialize the license.
        // The license string here is a trial license. Note that network connection is required for this license to work.
        // You can request an extension via the following link: https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=android
        if (configuration.getLicense() != null) {
            LicenseManager.initLicense(configuration.getLicense(), (isSuccess, error) -> {
                if (!isSuccess && error != null) {
                    Log.e("MRZScannerActivity", "InitLicense failed. ", error);
                }
            });
        }

        initView();
        initCamera();
        initCVR();
        try {
            configCVR();
        } catch (CaptureVisionRouterException e) {
            exceptionWhenConfigCvr = e;
        }
        initBottomSelector();
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putSerializable(KEY_CONFIG, configuration);
    }

    private void initView() {
        View topBar = findViewById(R.id.top_bar);
        ImageView closeButton = topBar.findViewById(R.id.iv_close);
        closeButton.setVisibility(configuration.isCloseButtonVisible() ? View.VISIBLE : View.GONE);
        closeButton.setOnClickListener((v) -> getOnBackPressedDispatcher().onBackPressed());

        ImageView toggleFlashLight = topBar.findViewById(R.id.iv_toggle_flashlight);
        toggleFlashLight.setVisibility(configuration.isTorchButtonVisible() ? View.VISIBLE : View.GONE);
        toggleFlashLight.setOnClickListener(v -> {
            if (toggleFlashLight.isSelected()) {
                mCamera.turnOffTorch();
                toggleFlashLight.setSelected(false);
            } else {
                mCamera.turnOnTorch();
                toggleFlashLight.setSelected(true);
            }
        });

        ImageView toggleCamera = topBar.findViewById(R.id.iv_toggle_camera);
        toggleCamera.setVisibility(configuration.isCameraToggleButtonVisible() ? View.VISIBLE : View.GONE);
        toggleCamera.setOnClickListener(v -> {
            if (toggleCamera.isSelected()) {
                mCamera.selectCamera(EnumCameraPosition.CP_BACK);
                toggleCamera.setSelected(false);
            } else {
                mCamera.selectCamera(EnumCameraPosition.CP_FRONT);
                toggleCamera.setSelected(true);
            }
        });

        ImageView toggleAudio = topBar.findViewById(R.id.iv_toggle_audio);
        toggleAudio.setVisibility(configuration.isBeepButtonVisible() ? View.VISIBLE : View.GONE);
        toggleAudio.setSelected(configuration.isBeepEnabled());
        toggleAudio.setOnClickListener(v -> {
            if (toggleAudio.isSelected()) {
                configuration.setBeepEnabled(false);
                toggleAudio.setSelected(false);
            } else {
                configuration.setBeepEnabled(true);
                toggleAudio.setSelected(true);
            }
        });

        ImageView toggleVibrate = topBar.findViewById(R.id.iv_toggle_vibrate);
        toggleVibrate.setVisibility(configuration.isVibrateButtonVisible() ? View.VISIBLE : View.GONE);
        toggleVibrate.setSelected(configuration.isVibrateEnabled());
        toggleVibrate.setOnClickListener(v -> {
            if (toggleVibrate.isSelected()) {
                configuration.setVibrateEnabled(false);
                toggleVibrate.setSelected(false);
            } else {
                configuration.setVibrateEnabled(true);
                toggleVibrate.setSelected(true);
            }
        });

        if ((!configuration.isBeepButtonVisible() && !configuration.isVibrateButtonVisible()) ||
                (!configuration.isTorchButtonVisible() && !configuration.isCameraToggleButtonVisible())) {
            topBar.findViewById(R.id.divider).setVisibility(View.GONE);
        }

        if ((!configuration.isVibrateButtonVisible() && !configuration.isBeepButtonVisible()) ||
                (!configuration.isTorchButtonVisible() && !configuration.isVibrateButtonVisible())) {
            topBar.findViewById(R.id.divider).setVisibility(View.GONE);
        }

        View guideFrame = findViewById(R.id.iv_guide_frame);
        guideFrame.setVisibility(configuration.isGuideFrameVisible() ? View.VISIBLE : View.INVISIBLE);
    }

    // Need to be called after configCVR
    private void initBottomSelector() {
        String[] templateNames = mScanner.getTemplateNames();
        BottomBarSelector bottomSelector = findViewById(R.id.bottom_bar);
        if (templateNames.length < 3) {
            bottomSelector.setVisibility(View.GONE);
            return;
        }

        List<String> templateNameList = Arrays.asList(templateNames);
        if (!templateNameList.contains("ReadPassportAndId") ||
                !templateNameList.contains("ReadPassport") ||
                !templateNameList.contains("ReadId")) {
            bottomSelector.setVisibility(View.GONE);
            return;
        }

        bottomSelector.setVisibility(configuration.isFormatSelectorVisible() ? View.VISIBLE : View.GONE);

        // Use stable keys, not UI labels.
        bottomSelector.selectItem(configuration.getDocumentType() == EnumDocumentType.DT_ID ? BottomBarSelector.KEY_ID :
                configuration.getDocumentType() == EnumDocumentType.DT_PASSPORT ? BottomBarSelector.KEY_PASSPORT : BottomBarSelector.KEY_BOTH);

        bottomSelector.addOnSelectedItemChangedListener(key -> {
            try {
                switch (key) {
                    case BottomBarSelector.KEY_ID:
                        mScanner.switchCapturingTemplate("ReadId");
                        break;
                    case BottomBarSelector.KEY_BOTH:
                        mScanner.switchCapturingTemplate("ReadPassportAndId");
                        break;
                    case BottomBarSelector.KEY_PASSPORT:
                        mScanner.switchCapturingTemplate("ReadPassport");
                        break;
                }
            } catch (Exception e) {
                Log.e("MRZScannerActivity", "Failed to switch capturing template: " + key, e);
            }
        });

    }

    private void initCamera() {
        mCameraView = findViewById(R.id.dce_camera_view);
        mCameraView.getDrawingLayer(DrawingLayer.DLR_LAYER_ID).setVisible(false);
        mCameraView.getDrawingLayer(DrawingLayer.DDN_LAYER_ID).setVisible(false);

        // CameraEnhancer is the class for controlling the camera and obtaining high-quality video input.
        mCamera = new CameraEnhancer(mCameraView, this);
        mCamera.setColourChannelUsageType(EnumColourChannelUsageType.CCUT_FULL_CHANNEL);

        mCamera.selectCamera(configuration.cameraPosition);
        // Enable the frame filter feature. It will improve the accuracy of the MRZ scanning.
        try {
            mCamera.enableEnhancedFeatures(EnumEnhancerFeatures.EF_FRAME_FILTER);
        } catch (CameraEnhancerException ignore) {
        }
        mCamera.setZoomFactor(configuration.zoomFactor);
        mCamera.setZoomFactorChangeListener(factor -> configuration.zoomFactor = factor);

        mCamera.setCameraStateListener(state -> {
            if (state == EnumCameraState.OPENED) {
                configuration.cameraPosition = mCamera.getCameraPosition();
//                ViewUtil.configCameraViewButton(mCamera, configuration);
            }
        });
    }

    private void initCVR() {
        // Enable the multi-frame cross verification feature. It will improve the accuracy of the MRZ scanning.
        MultiFrameResultCrossFilter filter = new MultiFrameResultCrossFilter();
        filter.enableResultCrossVerification(EnumCapturedResultItemType.CRIT_TEXT_LINE | EnumCapturedResultItemType.CRIT_DESKEWED_IMAGE | EnumCapturedResultItemType.CRIT_DETECTED_QUAD, true);
        filter.setResultCrossVerificationCriteria(
                EnumCapturedResultItemType.CRIT_DESKEWED_IMAGE | EnumCapturedResultItemType.CRIT_DETECTED_QUAD,
                configuration.getCriteria());
        mScanner.addResultFilter(filter);

        mScanner.setReturnPortraitImage(configuration.isReturnPortraitImage());
        mScanner.setReturnDocumentImage(configuration.isReturnDocumentImage());
        mScanner.setReturnOriginalImage(configuration.isReturnOriginalImage());

        mScanner.setMRZDataReceiver(new MRZScanner.MRZScanResultReceiver() {
            @Override
            public void onMRZDataReceived(@NonNull MRZScanResult scanResult) {
                // This callback may be invoked on a worker thread.

                assert scanResult.mrzData != null;

                boolean isNewMRZData = mergeResult == null || !scanResult.mrzData.mrzText.equals(mergeResult.mrzData.mrzText);
                boolean hasPortrait = scanResult.portraitImageInstance != 0;
                if (mergeResult == null) { // The first MRZData received, start timeout
                    makeFeedback(configuration); // The first MRZData received, provide feedback if needed.
                    CustomAnimator.runOnMainThreadDelayed(5000, () -> {
                        CustomAnimator.showTip(findViewById(R.id.tv_tip), 5, 0, null);
                        CustomAnimator.showNoPortraitTip(findViewById(R.id.no_portrait_tip_container));
                        View tvNoPortrait = findViewById(R.id.tv_no_portrait_tip);
                        if(tvNoPortrait != null) {
                            tvNoPortrait.setOnClickListener(v -> resultOK(mergeResult));
                        }
                    });
                } else if(mergeResult.mrzData.mrzText != null && !mergeResult.mrzData.mrzText.equals(scanResult.mrzData.mrzText)) { // A different MRZData received, reset timeout
                    makeFeedback(configuration); // A different MRZData received, provide feedback if needed.
                }

                mergeResult = scanResult;



                if (!configuration.isReturnPortraitImage() || hasPortrait) {
                    // Stop capturing on the worker thread.
                    mScanner.stopCapturing();

                    // UI work: animations + finishing activity.
                    runOnUiThread(() -> {
                        makeFeedback(configuration); // Scanning finished, provide feedback if needed.
                        CustomAnimator.sequence()
                                .then(next -> CustomAnimator.showGuideTextZoneAnimate(findViewById(R.id.iv_guide_frame), true, next::run))
                                .then(next -> CustomAnimator.showTip(findViewById(R.id.tv_tip), configuration.isReturnPortraitImage() ? 20 : 22, 300, next::run))
                                .then(() -> {
                                    if (mergeResult != null) { // May be assigned to null in handleOnBackPressed().
                                        resultOK(mergeResult); // onMRZDataReceived
                                    }
                                })
                                .start();
                    });
                } else { //configuration.isReturnPortraitImage() && scanResult.portraitImageInstance == 0
                    // UI work: show guidance and disable selector.
                    runOnUiThread(() -> {
                        if(isNewMRZData) { //Only show the tip animation when a new MRZData is received, otherwise it may be too frequent and annoying.
                            CustomAnimator.sequence()
                                    .then(next -> CustomAnimator.showGuideTextZoneAnimate(findViewById(R.id.iv_guide_frame), true, next::run))
                                    .then(next -> CustomAnimator.showTip(findViewById(R.id.tv_tip),
                                            mergeResult.mrzData.documentType.equals("MRTD_TD3_PASSPORT") ? 4 : 21,
                                            0, next::run))
                                    .start();
                            findViewById(R.id.bottom_bar).setEnabled(false);
                        }
                    });
                }
            }

            @Override
            public void onNoMRZPageReceived(@NonNull MRZScanResult scanResult) {
                // This callback may be invoked on a worker thread.
                assert scanResult.mrzData == null;
                if (mergeResult == null) {
                    return;
                }

                if (configuration.isReturnPortraitImage() && scanResult.portraitImageInstance == 0) {
                    return;
                }


                // The C++ objects held by scanResult are handed over to mergeResult for management,
                // so retainAllImageInstances is called to increase the reference count.
                scanResult.retainAllImageInstances();

                // Merge results on the worker thread.
                mergeResult.portraitImageInstance = scanResult.portraitImageInstance;
                mergeResult.anotherPageOriginalImageInstance = scanResult.anotherPageOriginalImageInstance;
                mergeResult.anotherPageDocumentImageInstance = scanResult.anotherPageDocumentImageInstance;

                // Stop capturing on the worker thread.
                mScanner.stopCapturing();

                // Provide feedback ASAP; it doesn't touch UI.
                makeFeedback(configuration);

                // UI work: animations + finishing activity.
                runOnUiThread(() -> {
                    CustomAnimator.sequence()
                            .then(next -> CustomAnimator.showGuideTextZoneAnimate(findViewById(R.id.iv_guide_frame), true, next::run))
                            .then(next -> CustomAnimator.showTip(findViewById(R.id.tv_tip), 3, 300, next::run))
                            .then(() -> {
                                if (mergeResult != null) { // May be assigned to null in handleOnBackPressed().
                                    resultOK(mergeResult); // onNoMRZPageReceived
                                }
                            })
                            .start();
                });
            }
        });

    }

    private void configCVR() throws CaptureVisionRouterException {
        mScanner.setInput(mCamera);

        if (configuration.getTemplateFile() != null && !configuration.getTemplateFile().isEmpty()) {
            String template = configuration.getTemplateFile();
            mCurrentTemplate = "";
            if (template.startsWith("{") || template.startsWith("[")) {
                mScanner.initSettings(template);
            } else {
                mScanner.initSettingsFromFile(template);
            }
        } else {
            if (configuration.getDocumentType() != null) {
                switch (configuration.getDocumentType()) {
                    case DT_ALL:
                        mCurrentTemplate = "ReadPassportAndId";
                        break;
                    case DT_ID:
                        mCurrentTemplate = "ReadId";
                        break;
                    case DT_PASSPORT:
                        mCurrentTemplate = "ReadPassport";
                        break;
                }

            }
        }

        try {
            SimplifiedCaptureVisionSettings settings = mScanner.getSimplifiedSettings(mCurrentTemplate);
            if (settings.documentSettings != null) {
                settings.documentSettings.minQuadrilateralAreaRatio = configuration.getMinDocumentAreaRatio();
                mScanner.updateSettings(mCurrentTemplate, settings);
            }
        } catch (CaptureVisionRouterException ignore) {
        }
    }


    @Override
    protected void onResume() {
        super.onResume();
        if (exceptionWhenConfigCvr != null) {
            resultError(exceptionWhenConfigCvr.getErrorCode(), exceptionWhenConfigCvr.getMessage());
            return;
        }

        mCamera.open();
        mScanner.startCapturing(mCurrentTemplate, new CompletionListener() {
            @Override
            public void onSuccess() {
            }

            @Override
            public void onFailure(int errorCode, String errorString) {
                runOnUiThread(() -> resultError(errorCode, errorString));
            }
        });
    }

    @Override
    protected void onPause() {
        super.onPause();
        mCamera.close();
        mScanner.stopCapturing();

        // DrawingItem in this sample is the green quadrilateral that highlights the recognized text.
        // Clear the DrawingItem before you leave the camera page.
        mCameraView.getDrawingLayer(DrawingLayer.DLR_LAYER_ID).clearDrawingItems();
    }


    @Override
    protected void onDestroy() {
        super.onDestroy();
        mCamera.setZoomFactorChangeListener(null);
    }

    private void resultOK(@NonNull MRZScanResult scanResult) {
        Intent intent = new Intent();
        intent.putExtra(MRZScanResult.EXTRA, scanResult);
        setResult(RESULT_OK, intent);
        mergeResult = null; // Help GC to recycle the result in MRZScannerActivity, especially the image instances.
        finish();
    }

    private void resultError(int errorCode, String errorString) {
        Intent intent = new Intent();
        MRZScanResult scanResult = new MRZScanResult();
        scanResult.resultStatus = MRZScanResult.EnumResultStatus.RS_EXCEPTION;
        scanResult.errorCode = errorCode;
        scanResult.errorString = errorString;
        intent.putExtra(MRZScanResult.EXTRA, scanResult);
        setResult(RESULT_OK, intent);
        finish();
    }

    private void resultCanceled() {
        Intent intent = new Intent();
        MRZScanResult scanResult = new MRZScanResult();
        scanResult.resultStatus = MRZScanResult.EnumResultStatus.RS_CANCELED;
        intent.putExtra(MRZScanResult.EXTRA, scanResult);
        setResult(RESULT_OK, intent);
        finish();
    }

    private static void makeFeedback(MRZScannerConfig config) {
        if (config.isVibrateEnabled()) {
            Feedback.vibrate();
        }
        if (config.isBeepEnabled()) {
            Feedback.beep();
        }
    }

    static native long nativeGetWrapImageDataInstance(IntermediateResultManager irManager, String imageHashId);

    static native long nativeGetDeskewedWrapImageDataInstance(IntermediateResultManager irManager, String imageHashId, int[] points);


    public static final class ResultContract extends ActivityResultContract<MRZScannerConfig, MRZScanResult> {

        @NonNull
        @Override
        public Intent createIntent(@NonNull Context context, MRZScannerConfig mrzScannerConfig) {
            Intent intent = new Intent(context, MRZScannerActivity.class);
            intent.putExtra(EXTRA_SCANNER_CONFIG, mrzScannerConfig);
            return intent;
        }

        @Override
        public MRZScanResult parseResult(int resultCode, @Nullable Intent intent) {
            if (intent == null) {
                MRZScanResult scanResult = new MRZScanResult();
                scanResult.resultStatus = MRZScanResult.EnumResultStatus.RS_CANCELED;
                return scanResult;
            } else {
                MRZScanResult serializableExtra = (MRZScanResult) intent.getParcelableExtra(MRZScanResult.EXTRA);
                return serializableExtra;
            }
        }
    }
}
