package com.dynamsoft.scanmrz;

import android.content.Intent;
import android.os.Bundle;

import androidx.activity.EdgeToEdge;
import androidx.activity.result.ActivityResultLauncher;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity;
import com.dynamsoft.mrzscannerbundle.ui.MRZScannerConfig;

public class MainActivity extends AppCompatActivity {

    private ActivityResultLauncher<MRZScannerConfig> launcher;
    private final MRZScannerConfig config = new MRZScannerConfig();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        // A trial license, so it needs a network connection. Request your own at
        // https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=android
        config.setLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9");

        // Every setting below is commented out at the opposite of its default — uncomment to try.

        // Restrict recognition to one document family. Default is DT_ALL, which reads both.
        // Needs: import com.dynamsoft.mrzscannerbundle.ui.EnumDocumentType;
        //config.setDocumentType(EnumDocumentType.DT_PASSPORT);
        // Your own Capture Vision template (path or inline JSON); outranks the document type.
        //config.setTemplateFile("MyTemplate.json");

        // Scanner controls. Every one of these is visible by default.
        //config.setCloseButtonVisible(false);        // Leaves no way out of the scanner.
        //config.setTorchButtonVisible(false);        // Hides the torch toggle.
        //config.setCameraToggleButtonVisible(false); // Hides the front/back camera toggle.
        //config.setBeepButtonVisible(false);         // Hides the beep toggle.
        //config.setVibrateButtonVisible(false);      // Hides the vibrate toggle.
        //config.setFormatSelectorVisible(false);     // Hides the ID / Both / Passport selector.
        //config.setGuideFrameVisible(false);         // Hides the guide frame and its prompt.

        // Both off by default; the buttons above toggle them, so this is just the opening state.
        //config.setBeepEnabled(true);
        //config.setVibrateEnabled(true);

        // Crops come back by default, the full camera frame does not.
        //config.setReturnDocumentImage(false);
        //config.setReturnPortraitImage(false);
        //config.setReturnOriginalImage(true);

        // Suppress the scanner's own permission dialog; either way it arrives as RS_EXCEPTION.
        //config.setCameraPermissionPromptEnabled(false);

        launcher = registerForActivityResult(new MRZScannerActivity.ResultContract(), result -> {
            // Hand the result to ResultActivity.
            Intent intent = new Intent(this, ResultActivity.class);
            intent.putExtra(ResultActivity.EXTRA_RESULT, result);
            startActivityForResult(intent, ResultActivity.REQUEST_CODE);
        });

        findViewById(R.id.btn_start).setOnClickListener(v -> launcher.launch(config));
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == ResultActivity.REQUEST_CODE && resultCode == RESULT_OK && data != null) {
            // Act on what ResultActivity sent back.
            int action = data.getIntExtra(ResultActivity.EXTRA_ACTION, ResultActivity.ACTION_RETURN_HOME);
            if (action == ResultActivity.ACTION_RESCAN) {
                launcher.launch(config);
            } else if (action == ResultActivity.ACTION_RETURN_HOME) {
                // Do nothing, this activity is Home.
            }
        }
    }
}