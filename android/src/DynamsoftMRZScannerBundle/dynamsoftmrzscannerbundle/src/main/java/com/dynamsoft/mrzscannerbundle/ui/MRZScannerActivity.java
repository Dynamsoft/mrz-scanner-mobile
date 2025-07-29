package com.dynamsoft.mrzscannerbundle.ui;

import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.os.Bundle;
import android.os.PersistableBundle;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;

import androidx.activity.result.contract.ActivityResultContract;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;

import com.dynamsoft.core.basic_structures.CompletionListener;
import com.dynamsoft.core.basic_structures.EnumCapturedResultItemType;
import com.dynamsoft.cvr.CaptureVisionRouter;
import com.dynamsoft.cvr.CaptureVisionRouterException;
import com.dynamsoft.cvr.CapturedResultReceiver;
import com.dynamsoft.dce.CameraEnhancer;
import com.dynamsoft.dce.CameraEnhancerException;
import com.dynamsoft.dce.CameraView;
import com.dynamsoft.dce.DrawingLayer;
import com.dynamsoft.dce.EnumCameraPosition;
import com.dynamsoft.dce.EnumEnhancerFeatures;
import com.dynamsoft.dce.Feedback;
import com.dynamsoft.dce.utils.PermissionUtil;
import com.dynamsoft.dcp.EnumValidationStatus;
import com.dynamsoft.dcp.ParsedResult;
import com.dynamsoft.dcp.ParsedResultItem;
import com.dynamsoft.dlr.RecognizedTextLinesResult;
import com.dynamsoft.license.LicenseManager;
import com.dynamsoft.mrzscannerbundle.R;
import com.dynamsoft.utility.MultiFrameResultCrossFilter;

import java.util.HashMap;

public class MRZScannerActivity extends AppCompatActivity {
    public final static String EXTRA_SCANNER_CONFIG = "scanner_config";
    public final static String EXTRA_STATUS_CODE = "extra_status_code";
    public final static String EXTRA_ERROR_CODE = "extra_error_code";
    public final static String EXTRA_ERROR_STRING = "extra_error_string";
    public final static String EXTRA_RESULT = "extra_result";
    public final static String EXTRA_DOC_TYPE = "extra_doc_type";
    public final static String EXTRA_NATIONALITY = "extra_nationality";
    public final static String EXTRA_ISSUING_STATE = "extra_issuing_state";
    public final static String EXTRA_NUMBER = "extra_number";

    private static final String KEY_CONFIG = "CONFIG";

    private CameraEnhancer mCamera;
    private CameraView mCameraView;
    private Button btnToggle;
    private Button btnTorch;
    private CaptureVisionRouter mRouter;
    private boolean succeed = false;
    private String mCurrentTemplate = "ReadPassportAndId";
    private MRZScannerConfig configuration;
    private String number;
    private CaptureVisionRouterException exceptionWhenConfigCvr;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_mrzscanner);
        PermissionUtil.requestCameraPermission(this);

        boolean isLight = (getResources().getConfiguration().uiMode & Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_NO;
        WindowInsetsControllerCompat wic = new WindowInsetsControllerCompat(getWindow(), getWindow().getDecorView());
        wic.setAppearanceLightStatusBars(isLight);
        wic.setAppearanceLightNavigationBars(isLight);

        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return WindowInsetsCompat.CONSUMED;
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
                if (!isSuccess) {
                    error.printStackTrace();
                }
            });
        }
        btnToggle = findViewById(R.id.btn_toggle);
        btnTorch = findViewById(R.id.btn_torch);
        initTorchButton();
        initToggleButton();

        ImageView closeButton = findViewById(R.id.iv_back);
        closeButton.setVisibility(configuration.isCloseButtonVisible() ? View.VISIBLE : View.GONE);
        closeButton.setOnClickListener((v) -> {
            resultOK(MRZScanResult.EnumResultStatus.RS_CANCELED, null);
            finish();
        });

        ImageView guideFrame = findViewById(R.id.iv_guide_frame);
        guideFrame.setVisibility(configuration.isGuideFrameVisible() ? View.VISIBLE : View.GONE);

        initCamera();
        initCVR();
        try {
            configCVR();
        } catch (CaptureVisionRouterException e) {
            exceptionWhenConfigCvr = e;
        }
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState, @NonNull PersistableBundle outPersistentState) {
        super.onSaveInstanceState(outState, outPersistentState);
        outState.putSerializable(KEY_CONFIG, configuration);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        mCamera.setZoomFactorChangeListener(null);
    }

    private void initCamera() {
        mCameraView = findViewById(R.id.dce_camera_view);
        // CameraEnhancer is the class for controlling the camera and obtaining high-quality video input.
        mCamera = new CameraEnhancer(mCameraView, this);

        mCamera.selectCamera(configuration.cameraPosition);
        // Enable the frame filter feature. It will improve the accuracy of the MRZ scanning.
        try {
            mCamera.enableEnhancedFeatures(EnumEnhancerFeatures.EF_FRAME_FILTER);
        } catch (CameraEnhancerException e) {
            e.printStackTrace();
        }
        mCamera.setZoomFactor(configuration.zoomFactor);
        mCamera.setZoomFactorChangeListener(factor-> configuration.zoomFactor = factor);
    }
    private void initCVR() {
        mRouter = new CaptureVisionRouter();
        // Enable the multi-frame cross verification feature. It will improve the accuracy of the MRZ scanning.
        MultiFrameResultCrossFilter filter = new MultiFrameResultCrossFilter();
        filter.enableResultCrossVerification(EnumCapturedResultItemType.CRIT_TEXT_LINE, true);
        mRouter.addResultFilter(filter);


        mRouter.addResultReceiver(new CapturedResultReceiver() {

            // Implement this method to receive raw MRZ recognized results. It includes the string only.
            @Override
            public void onRecognizedTextLinesReceived(@NonNull RecognizedTextLinesResult result) {
            }

            // Implement this method to receive parsed MRZ results. It includes the detailed information.
            @Override
            public void onParsedResultsReceived(@NonNull ParsedResult result) {
                if (!succeed) {
                    onParsedResultReceived(result);
                }
            }
        });
    }

    private void configCVR() throws CaptureVisionRouterException {
        mRouter.setInput(mCamera);

        if (configuration.getTemplateFile() != null && !configuration.getTemplateFile().isEmpty()) {
            String template = configuration.getTemplateFile();
            mCurrentTemplate = "";
            if (template.startsWith("{") || template.startsWith("[")) {
                mRouter.initSettings(template);
            } else {
                mRouter.initSettingsFromFile(template);
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
    }

    private void turnOnTorch() {
        mCamera.turnOnTorch();
        btnTorch.setBackground(ContextCompat.getDrawable(this, R.drawable.icon_flash_on));
    }

    private void turnOffTorch() {
        mCamera.turnOffTorch();
        btnTorch.setBackground(ContextCompat.getDrawable(this, R.drawable.icon_flash_off));
    }

    private void initTorchButton() {
        btnTorch.setVisibility(configuration.isTorchButtonVisible() ? View.VISIBLE : View.GONE);
        btnTorch.setOnClickListener(v -> {
            if (!configuration.isTorchOn) {
                turnOnTorch();
                configuration.isTorchOn = true;
            } else {
                turnOffTorch();
                configuration.isTorchOn = false;
            }
        });
    }

    private void resetToggleButton(int margin) {
        ViewGroup.MarginLayoutParams params = (ViewGroup.MarginLayoutParams) btnToggle.getLayoutParams();
        params.setMarginStart(margin);
        btnToggle.setLayoutParams(params);
    }

    public int dpToPx(int dp) {
        float density = getResources().getDisplayMetrics().density;
        return Math.round(dp * density);
    }

    private void initToggleButton() {
        btnToggle.setVisibility(configuration.isCameraToggleButtonVisible() ? View.VISIBLE : View.GONE);
        if (!configuration.isTorchButtonVisible() && configuration.isCameraToggleButtonVisible()) {
            resetToggleButton(0);
        }
        btnToggle.setOnClickListener(v -> {
            configuration.cameraPosition = (configuration.cameraPosition + 1) % 2;
            mCamera.selectCamera(configuration.cameraPosition);
            if (configuration.isTorchButtonVisible()) {
                boolean useBackCam = configuration.cameraPosition == EnumCameraPosition.CP_BACK;
                btnTorch.setVisibility(useBackCam ? View.VISIBLE : View.GONE);
                resetToggleButton(useBackCam ? dpToPx(50) : 0);
                if (!useBackCam) {
                    configuration.isTorchOn = false;
                    turnOffTorch();
                }
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (exceptionWhenConfigCvr != null) {
            resultError(exceptionWhenConfigCvr.getErrorCode(), exceptionWhenConfigCvr.getMessage());
            finish();
            return;
        }

        mCamera.open();
        // Start capturing.
        // The template name is a string specified in the template file.
        // In this sample we can use "ReadPassportAndId", "ReadId" and "ReadPassport".
        // Here the template name is what the user selected on the UI.
        // The completion listener is implemented below. It calls back when the capturing is successful or failed.
        mRouter.startCapturing(mCurrentTemplate, new CompletionListener() {
            @Override
            public void onSuccess() {
            }

            // If failed, it shows an error message that describes the reasons.
            // License error can be one of the reason of a failure. Besure that you have a valid license when starting capturing.
            @Override
            public void onFailure(int errorCode, String errorString) {
                runOnUiThread(() -> {
                    resultError(errorCode, errorString);
                    finish();
                });
            }
        });
    }

    @Override
    protected void onPause() {
        super.onPause();
        succeed = false;
        mCamera.close();
        mRouter.stopCapturing();
    }

    @Override
    protected void onStop() {
        // DrawingItem in this sample is the green quadrilateral that highlights the recognized text.
        // Clear the DrawingItem before you leave the camera page.
        mCameraView.getDrawingLayer(DrawingLayer.DLR_LAYER_ID).clearDrawingItems();
        super.onStop();
    }

    @Override
    public void onBackPressed() {
        resultOK(MRZScanResult.EnumResultStatus.RS_CANCELED, null);
        super.onBackPressed();
    }

    private void onParsedResultReceived(ParsedResult result) {
        // If failed to parse the MRZ, the following code shows the recognized text on the view.
        if (result.getItems().length != 0) {
            if (formerFilter(result.getItems()[0])) {
                if (configuration.isBeepEnabled()) {
                    Feedback.beep();
                }
                if (configuration.isVibrateEnabled()) {
                    Feedback.vibrate();
                }
                succeed = true;
                resultOK(MRZScanResult.EnumResultStatus.RS_FINISHED, result.getItems()[0]);
                finish();
            }
        }
    }

    private boolean formerFilter(ParsedResultItem item) {
        HashMap<String, String> entry = item.getParsedFields();

        number = entry.get("passportNumber") == null ? entry.get("documentNumber") == null
                ? entry.get("longDocumentNumber") == null ? "" : entry.get("longDocumentNumber") :
                entry.get("documentNumber") : entry.get("passportNumber");

        return number != null &&
                entry.get("sex") != null &&
                entry.get("issuingState") != null &&
                entry.get("nationality") != null &&
                entry.get("dateOfBirth") != null &&
                entry.get("dateOfExpiry") != null && getValid(item);
    }

    private void resultOK(int statusCode, ParsedResultItem item) {
        Intent intent = new Intent();
        intent.putExtra(EXTRA_STATUS_CODE, statusCode);
        if (item != null) {
            intent.putExtra(EXTRA_DOC_TYPE, item.getCodeType());
            intent.putExtra(EXTRA_NATIONALITY, item.getFieldRawValue("nationality"));
            intent.putExtra(EXTRA_ISSUING_STATE, item.getFieldRawValue("issuingState"));
            intent.putExtra(EXTRA_NUMBER, number);
            intent.putExtra(EXTRA_RESULT, item.getParsedFields());
        }
        setResult(RESULT_OK, intent);
    }

    private boolean getValid(ParsedResultItem item) {
        boolean isValid;
        if (item.getCodeType().equals("MRTD_TD1_ID")) {
            isValid = item.getFieldValidationStatus("line1") != EnumValidationStatus.VS_FAILED
                    && item.getFieldValidationStatus("line2") != EnumValidationStatus.VS_FAILED
                    && item.getFieldValidationStatus("line3") != EnumValidationStatus.VS_FAILED;
        } else {
            isValid = item.getFieldValidationStatus("line1") != EnumValidationStatus.VS_FAILED
                    && item.getFieldValidationStatus("line2") != EnumValidationStatus.VS_FAILED;
        }
        return isValid;
    }

    private void resultError(int errorCode, String errorString) {
        Intent intent = new Intent();
        intent.putExtra(EXTRA_STATUS_CODE, MRZScanResult.EnumResultStatus.RS_EXCEPTION);
        intent.putExtra(EXTRA_ERROR_CODE, errorCode);
        intent.putExtra(EXTRA_ERROR_STRING, errorString);
        setResult(RESULT_OK, intent);
    }

    public static final class ResultContract extends ActivityResultContract<MRZScannerConfig, MRZScanResult> {

        @NonNull
        @Override
        public Intent createIntent(@NonNull Context context, MRZScannerConfig mrzScannerConfig) {
            Intent intent = new Intent(context, MRZScannerActivity.class);
            intent.putExtra(MRZScannerActivity.EXTRA_SCANNER_CONFIG, mrzScannerConfig);
            return intent;
        }

        @Override
        public MRZScanResult parseResult(int resultCode, @Nullable Intent intent) {
            return new MRZScanResult(resultCode, intent);
        }
    }
}
