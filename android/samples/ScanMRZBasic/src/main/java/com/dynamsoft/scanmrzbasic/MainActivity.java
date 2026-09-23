package com.dynamsoft.scanmrzbasic;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.activity.EdgeToEdge;
import androidx.activity.result.ActivityResultLauncher;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.dynamsoft.core.basic_structures.CoreException;
import com.dynamsoft.core.basic_structures.ImageData;
import com.dynamsoft.dcp.EnumValidationStatus;
import com.dynamsoft.mrzscannerbundle.ui.MRZData;
import com.dynamsoft.mrzscannerbundle.ui.MRZScanResult;
import com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity;
import com.dynamsoft.mrzscannerbundle.ui.MRZScannerConfig;

/** Scans an MRZ and renders the result on this one screen; see ScanMRZ for the fuller app. */
public class MainActivity extends AppCompatActivity {

    private final MRZScannerConfig config = new MRZScannerConfig();
    private ActivityResultLauncher<MRZScannerConfig> launcher;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_main);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets bars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(bars.left, bars.top, bars.right, bars.bottom);
            return insets;
        });

        // A trial license, so it needs a network connection. Request your own at
        // https://www.dynamsoft.com/customer/license/trialLicense?product=mrz&utm_source=samples&package=android
        config.setLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9");

        // The scanner is its own activity, so results arrive via the Activity Result API.
        launcher = registerForActivityResult(
                new MRZScannerActivity.ResultContract(), this::showResult);

        findViewById(R.id.btn_scan).setOnClickListener(v -> launcher.launch(config));
    }

    /** Renders one of the three result statuses the scanner can come back with. */
    private void showResult(MRZScanResult result) {
        TextView tvStatus = findViewById(R.id.tv_status);
        View resultPanel = findViewById(R.id.result_panel);

        if (result.getResultStatus() == MRZScanResult.EnumResultStatus.RS_CANCELED) {
            // The user closed the scanner. There is no data and nothing went wrong.
            tvStatus.setText(R.string.scan_canceled);
            tvStatus.setVisibility(View.VISIBLE);
            resultPanel.setVisibility(View.GONE);
            return;
        }

        if (result.getResultStatus() == MRZScanResult.EnumResultStatus.RS_EXCEPTION) {
            // The scanner handles permission itself, so a denial arrives as an error string.
            tvStatus.setText(result.getErrorString());
            tvStatus.setVisibility(View.VISIBLE);
            resultPanel.setVisibility(View.GONE);
            return;
        }

        // A finished scan normally carries data, but guard it rather than assume.
        MRZData data = result.getData();
        if (data == null) {
            tvStatus.setText(R.string.scan_no_data);
            tvStatus.setVisibility(View.VISIBLE);
            resultPanel.setVisibility(View.GONE);
            return;
        }

        tvStatus.setVisibility(View.GONE);
        resultPanel.setVisibility(View.VISIBLE);

        // Validation is per field, so a joined full name is flagged when either half fails.
        int firstNameStatus = data.getFieldValidationStatus("firstName");
        int nameStatus = firstNameStatus == EnumValidationStatus.VS_FAILED
                ? firstNameStatus
                : data.getFieldValidationStatus("lastName");
        String fullName = (data.getFirstName() + " " + data.getLastName()).trim();

        applyField(findViewById(R.id.tv_full_name), fullName, nameStatus);
        applyField(findViewById(R.id.tv_doc_number), data.getDocumentNumber(),
                data.getFieldValidationStatus("documentNumber"));
        applyField(findViewById(R.id.tv_nationality), data.getNationality(),
                data.getFieldValidationStatus("nationality"));
        applyField(findViewById(R.id.tv_date_of_birth), data.getDateOfBirth(),
                data.getFieldValidationStatus("dateOfBirth"));
        applyField(findViewById(R.id.tv_date_of_expiry), data.getDateOfExpire(),
                data.getFieldValidationStatus("dateOfExpire"));
        // The document type comes from the MRZ layout itself, so it has no check digit.
        applyField(findViewById(R.id.tv_doc_type), data.getDocumentType(),
                EnumValidationStatus.VS_NONE);
        applyField(findViewById(R.id.tv_raw_mrz), data.getMrzText(),
                data.getFieldValidationStatus("mrzText"));

        showPortrait(result.getPortraitImage());
    }

    /** The portrait is returned by default, but is null when none could be cropped. */
    private void showPortrait(ImageData portrait) {
        ImageView ivPortrait = findViewById(R.id.iv_portrait);
        ivPortrait.setVisibility(View.GONE);
        if (portrait == null) {
            return;
        }
        try {
            ivPortrait.setImageBitmap(portrait.toBitmap());
            ivPortrait.setVisibility(View.VISIBLE);
        } catch (CoreException ignored) {
        }
    }

    /** Shows {@code value}, or "N/A" when empty; amber when it fails its check digit. */
    private void applyField(TextView tv, String value, int status) {
        boolean failed = status == EnumValidationStatus.VS_FAILED;
        tv.setText(value == null || value.isEmpty() ? "N/A" : value);
        tv.setTextColor(ContextCompat.getColor(this,
                failed ? R.color.warning_amber : R.color.white));
    }
}
