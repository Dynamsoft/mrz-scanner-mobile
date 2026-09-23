package com.dynamsoft.mrzscannerbundle.ui;

import android.Manifest;
import android.app.admin.DevicePolicyManager;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.widget.ImageView;

import androidx.activity.OnBackPressedCallback;
import androidx.activity.result.contract.ActivityResultContract;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;

import com.dynamsoft.core.basic_structures.CompletionListener;
import com.dynamsoft.core.basic_structures.DSRect;
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
import com.dynamsoft.license.LicenseManager;
import com.dynamsoft.mrzscannerbundle.R;
import com.dynamsoft.utility.MultiFrameResultCrossFilter;

import java.util.Arrays;
import java.util.List;

public class MRZScannerActivity extends AppCompatActivity {
    public final static String EXTRA_SCANNER_CONFIG = "scanner_config";
    private static final String KEY_CONFIG = "CONFIG";
    private static final String TAG = "MRZScannerActivity";

    private static final String TPL_ALL = "ReadPassportAndId";
    private static final String TPL_ID = "ReadId";
    private static final String TPL_PASSPORT = "ReadPassport";

    static {
        System.loadLibrary("DynamsoftMRZScannerBundleJni");
    }

    private CameraEnhancer mCamera;
    private CameraView mCameraView;
    private final MRZScanner mScanner = new MRZScanner();
    private String mCurrentTemplate = TPL_ALL;
    private MRZScannerConfig configuration;
    private CaptureVisionRouterException exceptionWhenConfigCvr;

    private ViewGroup mGuideFrame;
    private ViewGroup mTip;
    private ImageView mSpinner;
    private ImageView mFlipPrompt;

    private volatile MRZScanResult mergeResult = null;
    private volatile boolean isMrzScanned = false;

    /// Decides the way out offered and the code reported; only DENIAL_POLICY reports RESTRICTED.
    private static final int DENIAL_RETRYABLE = 0;
    private static final int DENIAL_SETTINGS = 1;
    private static final int DENIAL_POLICY = 2;

    private static final int REQUEST_CAMERA_PERMISSION = 0x4D5A;
    private static final String PERMISSION_PREFS = "com.dynamsoft.mrzscannerbundle.permissions";
    private static final String KEY_CAMERA_REQUESTED = "cameraPermissionRequested";
    /// True while a request is in flight, so onResume doesn't mistake the prompt for a refusal.
    private boolean isAwaitingPermissionResult = false;
    private AlertDialog permissionDialog;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_mrzscanner);
        requestCameraPermissionIfNeeded();

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
        // assert is a no-op on Android, so this has to be a real check.
        if (configuration == null) throw new IllegalStateException("MRZScannerConfig missing from the launch Intent; use ResultContract.");

        // Trial license; needs a network connection. Request an extension at
        // https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=android
        if (configuration.getLicense() != null) {
            LicenseManager.initLicense(configuration.getLicense(), (isSuccess, error) -> {
                if (isSuccess) return;
                // A bad license is terminal: this was logged only, so the scanner just never scanned.
                Log.e(TAG, "InitLicense failed. ", error);
                runOnUiThread(() -> resultError(-1, error == null ? "License verification failed" : error.getMessage()));
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

    private interface ToggleAction {
        void onToggled(boolean selected);
    }

    /// Wires one top-bar toggle: visibility, initial state, and a click reporting the new value.
    private void bindToggle(View bar, int viewId, boolean visible, boolean selected, ToggleAction action) {
        ImageView button = bar.findViewById(viewId);
        button.setVisibility(visible ? View.VISIBLE : View.GONE);
        button.setSelected(selected);
        button.setOnClickListener(v -> {
            boolean next = !button.isSelected();
            action.onToggled(next);
            button.setSelected(next);
        });
    }

    private void initView() {
        mGuideFrame = findViewById(R.id.iv_guide_frame);
        mTip = findViewById(R.id.tv_tip);
        mSpinner = findViewById(R.id.iv_scanner_spinner);
        mFlipPrompt = findViewById(R.id.iv_flip_prompt);

        View topBar = findViewById(R.id.top_bar);
        ImageView closeButton = topBar.findViewById(R.id.iv_close);
        closeButton.setVisibility(configuration.isCloseButtonVisible() ? View.VISIBLE : View.GONE);
        closeButton.setOnClickListener((v) -> getOnBackPressedDispatcher().onBackPressed());

        bindToggle(topBar, R.id.iv_toggle_flashlight, configuration.isTorchButtonVisible(), false,
                on -> { if (on) mCamera.turnOnTorch(); else mCamera.turnOffTorch(); });
        bindToggle(topBar, R.id.iv_toggle_camera, configuration.isCameraToggleButtonVisible(), false,
                on -> mCamera.selectCamera(on ? EnumCameraPosition.CP_FRONT : EnumCameraPosition.CP_BACK));
        bindToggle(topBar, R.id.iv_toggle_audio, configuration.isBeepButtonVisible(),
                configuration.isBeepEnabled(), configuration::setBeepEnabled);
        bindToggle(topBar, R.id.iv_toggle_vibrate, configuration.isVibrateButtonVisible(),
                configuration.isVibrateEnabled(), configuration::setVibrateEnabled);

        // Groups are [flashlight][camera] | divider | [audio][vibrate]; drop it when either side is empty.
        if ((!configuration.isTorchButtonVisible() && !configuration.isCameraToggleButtonVisible())
                || (!configuration.isBeepButtonVisible() && !configuration.isVibrateButtonVisible())) {
            topBar.findViewById(R.id.divider).setVisibility(View.GONE);
        }

        // INVISIBLE not GONE: overlays anchor to the frame, and a GONE tip never fires the transition callback (issue #63).
        int guideVisibility = configuration.isGuideFrameVisible() ? View.VISIBLE : View.INVISIBLE;
        mGuideFrame.setVisibility(guideVisibility);
        mTip.setVisibility(guideVisibility);
    }

    // Need to be called after configCVR
    private void initBottomSelector() {
        BottomBarSelector bottomSelector = findViewById(R.id.bottom_bar);
        List<String> templateNames = Arrays.asList(mScanner.getTemplateNames());
        if (!templateNames.containsAll(Arrays.asList(TPL_ALL, TPL_PASSPORT, TPL_ID))) {
            bottomSelector.setVisibility(View.GONE);
            return;
        }

        bottomSelector.setVisibility(configuration.isFormatSelectorVisible() ? View.VISIBLE : View.GONE);

        // Use stable keys, not UI labels.
        bottomSelector.selectItem(configuration.getDocumentType() == EnumDocumentType.DT_ID ? BottomBarSelector.KEY_ID :
                configuration.getDocumentType() == EnumDocumentType.DT_PASSPORT ? BottomBarSelector.KEY_PASSPORT : BottomBarSelector.KEY_BOTH);

        bottomSelector.addOnSelectedItemChangedListener(key -> {
            String template = BottomBarSelector.KEY_ID.equals(key) ? TPL_ID
                    : BottomBarSelector.KEY_PASSPORT.equals(key) ? TPL_PASSPORT : TPL_ALL;
            try {
                mScanner.switchCapturingTemplate(template);
            } catch (Exception e) {
                Log.e(TAG, "Failed to switch capturing template: " + key, e);
            }
        });
    }

    private void initCamera() {
        mCameraView = findViewById(R.id.dce_camera_view);
        mCameraView.getDrawingLayer(DrawingLayer.DLR_LAYER_ID).setVisible(false);
        mCameraView.getDrawingLayer(DrawingLayer.DDN_LAYER_ID).setVisible(false);
        mCameraView.setScanRegionMaskVisible(false);

        // CameraEnhancer is the class for controlling the camera and obtaining high-quality video input.
        mCamera = new CameraEnhancer(mCameraView, this);
        mCamera.setColourChannelUsageType(EnumColourChannelUsageType.CCUT_FULL_CHANNEL);
        mGuideFrame.addOnLayoutChangeListener((v, l, t, r, b, ol, ot, or, ob) -> applyScanRegionToDCE());

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
            }
        });
    }

    private void updateSpinner(boolean present) {
        if (present) {
            CustomAnimator.startScannerSpinner(mSpinner);
        } else {
            CustomAnimator.stopScannerSpinner(mSpinner);
        }
    }

    /// A hidden frame keeps its geometry, so scan the whole preview instead of an invisible box (issue #63).
    private void applyScanRegionToDCE() {
        if (mCamera == null || mCameraView == null) return;
        if (mCameraView.getWidth() == 0 || mCameraView.getHeight() == 0) return;

        DSRect region;
        if (configuration.isGuideFrameVisible()) {
            if (mGuideFrame.getWidth() == 0 || mGuideFrame.getHeight() == 0) return;

            int[] guideLoc = new int[2];
            mGuideFrame.getLocationOnScreen(guideLoc);
            int[] cameraLoc = new int[2];
            mCameraView.getLocationOnScreen(cameraLoc);

            float left = (float) (guideLoc[0] - cameraLoc[0]) / mCameraView.getWidth();
            float top = (float) (guideLoc[1] - cameraLoc[1]) / mCameraView.getHeight();
            float right = left + (float) mGuideFrame.getWidth() / mCameraView.getWidth();
            float bottom = top + (float) mGuideFrame.getHeight() / mCameraView.getHeight();
            region = new DSRect(left, top, right, bottom, true);
        } else {
            region = new DSRect(0f, 0f, 1f, 1f, true);
        }

        try {
            mCamera.setScanRegion(region);
        } catch (CameraEnhancerException e) {
            Log.e(TAG, "setScanRegion failed", e);
        }
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
            public void onTextLineActivity(boolean textLineLocalized) {
                // Spinner tracks per-frame text-line localization; suppressed once MRZ is confirmed.
                if (isMrzScanned) return;
                runOnUiThread(() -> updateSpinner(textLineLocalized));
            }

            @Override
            public void onMRZDataReceived(@NonNull MRZScanResult scanResult) {
                // This callback may be invoked on a worker thread. MRZScanner guarantees mrzData here.
                boolean isNewMRZData = mergeResult == null || !scanResult.mrzData.mrzText.equals(mergeResult.mrzData.mrzText);
                boolean hasPortrait = scanResult.imageInstances[MRZScanResult.TYPE_PORTRAIT] != 0;
                if (mergeResult == null) { // The first MRZData received, start timeout
                    makeFeedback(configuration);
                    CustomAnimator.runOnMainThreadDelayed(5000, () -> {
                        // The activity may have finished during the 5s wait, so its views may be gone.
                        View noPortraitTip = findViewById(R.id.tv_no_portrait_tip);
                        if (noPortraitTip == null || mergeResult == null) return;
                        CustomAnimator.showTip(mTip, 5, 0, null);
                        CustomAnimator.showNoPortraitTip(findViewById(R.id.no_portrait_tip_container));
                        noPortraitTip.setOnClickListener(v -> {
                            if (mergeResult != null) resultOK(mergeResult);
                        });
                    });
                } else if (mergeResult.mrzData.mrzText != null && !mergeResult.mrzData.mrzText.equals(scanResult.mrzData.mrzText)) {
                    makeFeedback(configuration); // A different MRZData received, reset timeout
                }

                // Free the superseded frame's buffers now instead of leaving them to the finalizer (issue #64).
                if (mergeResult != null && mergeResult != scanResult) {
                    mergeResult.releaseAllImageInstances();
                }
                mergeResult = scanResult;

                if (!configuration.isReturnPortraitImage() || hasPortrait) {
                    // Stop capturing on the worker thread, then finish on the UI thread.
                    mScanner.stopCapturing();
                    runOnUiThread(() -> finishWithSuccessTip(
                            configuration.isReturnPortraitImage() ? 20 : 22, true));
                } else { // returnPortraitImage is on but no portrait was found yet
                    // UI work: show guidance and disable selector.
                    runOnUiThread(() -> {
                        //Only animate on a new MRZData, otherwise it may be too frequent and annoying.
                        if (!isNewMRZData) return;
                        isMrzScanned = true;
                        CustomAnimator.stopScannerSpinner(mSpinner);
                        boolean needsFlip = !mergeResult.mrzData.documentType.equals("MRTD_TD3_PASSPORT");
                        CustomAnimator.sequence()
                                // The only returnWhite = true path: the scanner stays up for the other side.
                                .then(next -> CustomAnimator.showGuideTextZoneAnimate(mGuideFrame, true, next::run))
                                .then(next -> CustomAnimator.showTip(mTip, needsFlip ? 21 : 4, 0, next::run))
                                .then(() -> {
                                    if (needsFlip) {
                                        CustomAnimator.startFlipAnimation(mFlipPrompt);
                                    }
                                })
                                .start();
                        findViewById(R.id.bottom_bar).setEnabled(false);
                    });
                }
            }

            @Override
            public void onNoMRZPageReceived(@NonNull MRZScanResult scanResult) {
                // This callback may be invoked on a worker thread; MRZScanner sends only mrzData-less results here.
                // Both early returns discard this result, so free its buffers here (issue #64).
                if (mergeResult == null
                        || (configuration.isReturnPortraitImage()
                            && scanResult.imageInstances[MRZScanResult.TYPE_PORTRAIT] == 0)) {
                    scanResult.releaseAllImageInstances();
                    return;
                }

                // scanResult's C++ objects pass to mergeResult, so retain to bump the reference count.
                scanResult.retainAllImageInstances();

                // Merge results on the worker thread.
                for (int type : new int[]{MRZScanResult.TYPE_PORTRAIT,
                        MRZScanResult.TYPE_OTHER_ORIGINAL, MRZScanResult.TYPE_OTHER_DOCUMENT}) {
                    mergeResult.imageInstances[type] = scanResult.imageInstances[type];
                }

                mScanner.stopCapturing();
                makeFeedback(configuration); // Provide feedback ASAP; it doesn't touch UI.
                runOnUiThread(() -> finishWithSuccessTip(3, false));
            }
        });
    }

    /// Shared tail of both finishing paths; returnWhite = false holds the border green to handover.
    private void finishWithSuccessTip(int tipIndex, boolean feedback) {
        isMrzScanned = true;
        CustomAnimator.stopFlipAnimation(mFlipPrompt);
        CustomAnimator.stopScannerSpinner(mSpinner);
        if (feedback) makeFeedback(configuration);
        CustomAnimator.sequence()
                .then(next -> CustomAnimator.showGuideTextZoneAnimate(mGuideFrame, false, next::run))
                .then(next -> CustomAnimator.showTip(mTip, tipIndex, 300, next::run))
                .then(() -> {
                    if (mergeResult != null) { // May be assigned to null in handleOnBackPressed().
                        resultOK(mergeResult);
                    }
                })
                .start();
    }

    private void configCVR() throws CaptureVisionRouterException {
        mScanner.setInput(mCamera);

        String template = configuration.getTemplateFile();
        if (template != null && !template.isEmpty()) {
            mCurrentTemplate = "";
            if (template.startsWith("{") || template.startsWith("[")) {
                mScanner.initSettings(template);
            } else {
                mScanner.initSettingsFromFile(template);
            }
        } else if (configuration.getDocumentType() != null) {
            mCurrentTemplate = configuration.getDocumentType() == EnumDocumentType.DT_ID ? TPL_ID
                    : configuration.getDocumentType() == EnumDocumentType.DT_PASSPORT ? TPL_PASSPORT : TPL_ALL;
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

        // Checked separately: the permission can read as granted while policy blocks the hardware.
        if (isCameraDisabledByPolicy()) {
            handleCameraPermissionDenied(DENIAL_POLICY);
            return;
        }

        if (!isCameraPermissionGranted()) {
            // Opening without permission leaves a blank preview and reports nothing; wait or refuse.
            if (!isAwaitingPermissionResult) {
                handleCameraPermissionDenied(currentDenialState());
            }
            return;
        }
        startCapture();
    }

    private void startCapture() {
        isMrzScanned = false;
        findViewById(R.id.bottom_bar).setEnabled(true); // Disabled once an MRZ lands; re-arm on every resume.
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

    private boolean isCameraPermissionGranted() {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED;
    }

    private void requestCameraPermissionIfNeeded() {
        if (isCameraPermissionGranted()) {
            return;
        }
        getSharedPreferences(PERMISSION_PREFS, Context.MODE_PRIVATE)
                .edit().putBoolean(KEY_CAMERA_REQUESTED, true).apply();
        isAwaitingPermissionResult = true;
        ActivityCompat.requestPermissions(
                this, new String[]{Manifest.permission.CAMERA}, REQUEST_CAMERA_PERMISSION);
    }

    /// The persisted flag separates "never asked" from "permanently refused"; the rationale API cannot.
    private boolean isCameraPermissionPermanentlyDenied() {
        SharedPreferences prefs = getSharedPreferences(PERMISSION_PREFS, Context.MODE_PRIVATE);
        return prefs.getBoolean(KEY_CAMERA_REQUESTED, false)
                && !ActivityCompat.shouldShowRequestPermissionRationale(
                        this, Manifest.permission.CAMERA);
    }

    /// Administrator-disabled camera — the Android counterpart of iOS's .restricted.
    private boolean isCameraDisabledByPolicy() {
        DevicePolicyManager dpm =
                (DevicePolicyManager) getSystemService(Context.DEVICE_POLICY_SERVICE);
        return dpm != null && dpm.getCameraDisabled(null);
    }

    private int currentDenialState() {
        return isCameraPermissionPermanentlyDenied() ? DENIAL_SETTINGS : DENIAL_RETRYABLE;
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions,
                                           @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
        if (requestCode != REQUEST_CAMERA_PERMISSION) {
            return;
        }
        isAwaitingPermissionResult = false;
        if (isCameraPermissionGranted()) {
            startCapture();
        } else {
            handleCameraPermissionDenied(currentDenialState());
        }
    }

    /// Offers a dialog before reporting so integrators get a usable flow; the config flag suppresses it.
    private void handleCameraPermissionDenied(int denialState) {
        if (configuration != null && !configuration.isCameraPermissionPromptEnabled()) {
            reportCameraPermissionDenied(denialState);
            return;
        }
        showCameraPermissionDialog(denialState);
    }

    private void showCameraPermissionDialog(int denialState) {
        // onResume can run twice for one refusal; without this guard the dialog would stack.
        if (permissionDialog != null && permissionDialog.isShowing()) {
            return;
        }
        AlertDialog.Builder builder = new AlertDialog.Builder(this)
                .setTitle(R.string.camera_permission_title)
                .setMessage(cameraPermissionMessage(denialState))
                .setCancelable(false);

        if (denialState == DENIAL_RETRYABLE) {
            // Still re-askable, so the user can grant it without leaving the app.
            builder.setPositiveButton(R.string.camera_permission_allow, (dialog, which) -> {
                dialog.dismiss();
                requestCameraPermissionIfNeeded();
            });
        } else if (denialState == DENIAL_SETTINGS) {
            builder.setPositiveButton(R.string.camera_permission_settings, (dialog, which) -> {
                dialog.dismiss();
                openAppSettings();
                // No report: the activity survives the trip, so onResume starts the camera in place.
            });
        }
        // DENIAL_POLICY gets no positive action, but still shows: it is the only guaranteed explanation.
        builder.setNegativeButton(android.R.string.cancel, (dialog, which) -> {
            dialog.dismiss();
            reportCameraPermissionDenied(denialState);
        });

        permissionDialog = builder.create();
        permissionDialog.show();
    }

    /// Same task, so backing out of Settings returns here and onResume acts on the change.
    private void openAppSettings() {
        startActivity(new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", getPackageName(), null)));
    }

    private void reportCameraPermissionDenied(int denialState) {
        int errorCode = denialState == DENIAL_POLICY
                ? MRZScanResult.EnumErrorCode.EC_CAMERA_PERMISSION_RESTRICTED
                : MRZScanResult.EnumErrorCode.EC_CAMERA_PERMISSION_DENIED;
        resultError(errorCode, cameraPermissionMessage(denialState));
    }

    /// Both denied states report EC_CAMERA_PERMISSION_DENIED, matching iOS; only the message differs.
    private String cameraPermissionMessage(int denialState) {
        if (denialState == DENIAL_POLICY) return getString(R.string.camera_permission_restricted);
        if (denialState == DENIAL_SETTINGS) return getString(R.string.camera_permission_denied);
        return getString(R.string.camera_permission_required);
    }

    @Override
    protected void onPause() {
        super.onPause();
        mCamera.close();
        mScanner.stopCapturing();
        mScanner.releaseIntermediateUnits();
        CustomAnimator.stopFlipAnimation(mFlipPrompt);
        CustomAnimator.stopScannerSpinner(mSpinner);

        // Clear the green quadrilateral highlighting recognized text before leaving the camera page.
        mCameraView.getDrawingLayer(DrawingLayer.DLR_LAYER_ID).clearDrawingItems();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        mCamera.setZoomFactorChangeListener(null);
        // Static handler, so a pending tip or no-portrait post would outlive this activity.
        CustomAnimator.cancelPendingPosts();
        // Non-cancelable dialog: dismiss explicitly or it leaks its window.
        if (permissionDialog != null && permissionDialog.isShowing()) {
            permissionDialog.dismiss();
        }
        permissionDialog = null;
        if (mergeResult != null) {
            mergeResult.releaseAllImageInstances();
            mergeResult = null;
        }
    }

    /// Hands a result back to the caller and closes the scanner.
    private void deliver(@NonNull MRZScanResult scanResult) {
        Intent intent = new Intent();
        intent.putExtra(MRZScanResult.EXTRA, scanResult);
        setResult(RESULT_OK, intent);
        finish();
    }

    private void resultOK(@NonNull MRZScanResult scanResult) {
        mergeResult = null; // Help GC recycle the result, especially the image instances.
        deliver(scanResult);
    }

    private void resultError(int errorCode, String errorString) {
        MRZScanResult scanResult = new MRZScanResult();
        scanResult.resultStatus = MRZScanResult.EnumResultStatus.RS_EXCEPTION;
        scanResult.errorCode = errorCode;
        scanResult.errorString = errorString;
        deliver(scanResult);
    }

    private void resultCanceled() {
        MRZScanResult scanResult = new MRZScanResult();
        scanResult.resultStatus = MRZScanResult.EnumResultStatus.RS_CANCELED;
        deliver(scanResult);
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
            }
            return intent.getParcelableExtra(MRZScanResult.EXTRA);
        }
    }
}
