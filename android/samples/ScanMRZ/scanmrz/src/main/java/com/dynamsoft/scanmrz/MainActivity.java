package com.dynamsoft.scanmrz;

import android.annotation.SuppressLint;
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

        // Initialize the license.
        // The license string here is a trial license. Note that network connection is required for this license to work.
        // You can request an extension via the following link: https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=android
        config.setLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9");
        config.setCameraToggleButtonVisible(true); //Default is true.
//        config.setReturnOriginalImage(true);// Default is false. If true, the result will contain the original image of the document (the frame where MRZ is detected).
        //config.setReturnDocumentImage(); // Default is true. If true, the result will contain the document image cropped from the original frame.
        //config.setReturnPortraitImage(); // Default is true. If true, the result will contain the portrait image cropped from the original frame.

        launcher = registerForActivityResult(new MRZScannerActivity.ResultContract(), result -> {
            /// In this sample, we pass the result to ResultActivity to show the result.
            Intent intent = new Intent(this, ResultActivity.class);
            intent.putExtra(ResultActivity.EXTRA_RESULT, result);
            startActivityForResult(intent, ResultActivity.REQUEST_CODE);
        });

        findViewById(R.id.btn_start).setOnClickListener(v -> launcher.launch(config));
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, @Nullable Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == ResultActivity.REQUEST_CODE && resultCode == RESULT_OK) {
            /// Handle the action from ResultActivity here.
            int action = data.getIntExtra(ResultActivity.EXTRA_ACTION, ResultActivity.ACTION_RETURN_HOME);
            if (action == ResultActivity.ACTION_RESCAN) {
                launcher.launch(config);
            } else if (action == ResultActivity.ACTION_RETURN_HOME) {
                // Do nothing, this activity is Home.
            }
        }
    }
}