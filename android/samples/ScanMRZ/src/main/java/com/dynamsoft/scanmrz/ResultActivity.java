package com.dynamsoft.scanmrz;

import android.Manifest;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Bundle;
import android.provider.Settings;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.style.ImageSpan;
import android.text.style.UnderlineSpan;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.fragment.app.Fragment;
import androidx.viewpager2.adapter.FragmentStateAdapter;
import androidx.viewpager2.widget.ViewPager2;

import com.dynamsoft.core.basic_structures.CoreException;
import com.dynamsoft.core.basic_structures.ImageData;
import com.dynamsoft.dcp.EnumValidationStatus;
import com.dynamsoft.mrzscannerbundle.ui.EnumDocumentSide;
import com.dynamsoft.mrzscannerbundle.ui.MRZData;
import com.dynamsoft.mrzscannerbundle.ui.MRZScanResult;
import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;

import java.util.Locale;

public class ResultActivity extends AppCompatActivity {
    public static final int REQUEST_CODE = 1024;

    public static final String EXTRA_RESULT = "RESULT";
    public static final String EXTRA_ACTION = "ACTION";
    public static final int ACTION_RESCAN = 0;
    public static final int ACTION_RETURN_HOME = 1;

    /** True while this screen is showing a camera-permission denial rather than a result. */
    private boolean isShowingCameraPermissionError = false;

    @Override
    protected void onResume() {
        super.onResume();
        // They may have just granted access in Settings, so don't leave a stale denial up.
        if (isShowingCameraPermissionError && hasCameraPermission()) {
            setResult(RESULT_OK, getIntent().putExtra(EXTRA_ACTION, ACTION_RESCAN));
            finish();
        }
    }

    private boolean hasCameraPermission() {
        return ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA)
                == PackageManager.PERMISSION_GRANTED;
    }


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_results);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        MRZScanResult scanResult = (MRZScanResult) getIntent().getParcelableExtra(EXTRA_RESULT);
        if(scanResult != null) {
            showMRZScanResult(scanResult);
        }

        findViewById(R.id.btn_rescan).setOnClickListener(v -> {
            setResult(RESULT_OK, getIntent().putExtra(EXTRA_ACTION, ACTION_RESCAN));
            finish();
        });

        findViewById(R.id.btn_return_home).setOnClickListener(v -> {
            setResult(RESULT_OK, getIntent().putExtra(EXTRA_ACTION, ACTION_RETURN_HOME));
            finish();
        });

    }

    private void showMRZScanResult(MRZScanResult result) {
        if(result.getResultStatus() == MRZScanResult.EnumResultStatus.RS_CANCELED) {
            // If the scan is canceled, we directly return to home without showing the result.
            setResult(RESULT_OK, getIntent().putExtra(EXTRA_ACTION, ACTION_RETURN_HOME));
            finish();
            return;
        }
        if(result.getResultStatus() == MRZScanResult.EnumResultStatus.RS_EXCEPTION) {
            // If the scan is failed with error, we show the error message without showing the result.
            findViewById(R.id.result_view).setVisibility(View.GONE);
            TextView tvNoResult = findViewById(R.id.no_result_view);
            tvNoResult.setVisibility(View.VISIBLE);
            tvNoResult.setText(result.getErrorString());
            showCameraPermissionAction(result.getErrorCode());
            return;
        }

        // A finished scan normally carries data, but guard it rather than assume.
        MRZData data = result.getData();
        if (data == null) {
            findViewById(R.id.result_view).setVisibility(View.GONE);
            TextView tvNoData = findViewById(R.id.no_result_view);
            tvNoData.setVisibility(View.VISIBLE);
            tvNoData.setText(R.string.scan_no_data);
            return;
        }

        findViewById(R.id.result_view).setVisibility(View.VISIBLE);
        findViewById(R.id.no_result_view).setVisibility(View.GONE);

        // Empty when unparsed; Locale.ROOT because this is an ICAO field, not localized text.
        String sexText = data.getSex();
        String genderText = sexText.isEmpty() ? "" : sexText.substring(0, 1).toUpperCase(Locale.ROOT)
                + sexText.substring(1).toLowerCase(Locale.ROOT);

        // No highlighting: tinting "gender, age" on one field's status would implicate both.
        ((TextView) findViewById(R.id.tv_full_name)).setText((data.getFirstName() + " " + data.getLastName()).trim());
        ((TextView) findViewById(R.id.tv_gender_and_age)).setText(
                genderText.isEmpty() && data.getAge() == 0
                        ? ""
                        : genderText + ", " + data.getAge() + " years old");
        ((TextView) findViewById(R.id.tv_expiry)).setText(data.getDateOfExpire().isEmpty() ? "" : "Expiry: " + data.getDateOfExpire());

        ImageView ivPortrait = findViewById(R.id.iv_portrait);
        ImageData portraitImage = result.getPortraitImage(); //Nullable
        if (portraitImage != null) {
            try {
                ivPortrait.setImageBitmap(portraitImage.toBitmap());
            } catch (CoreException ignored) {
            }
        } else {
            ivPortrait.setImageResource(R.drawable.ic_portrait_placeholder);
        }

        //Images view pager
        showImages(result);

        //Personal Info
        applyField(findViewById(R.id.tv_given_name),   data.getFirstName(),    data.getFieldValidationStatus("firstName"));
        applyField(findViewById(R.id.tv_surname),      data.getLastName(),     data.getFieldValidationStatus("lastName"));
        applyField(findViewById(R.id.tv_date_of_birth),data.getDateOfBirth(),  data.getFieldValidationStatus("dateOfBirth"));
        applyField(findViewById(R.id.tv_gender),       genderText,             data.getFieldValidationStatus("sex"));
        applyField(findViewById(R.id.tv_nationality),  data.getNationality(),  data.getFieldValidationStatus("nationality"));

        //Document Info
        TextView tvDocType = findViewById(R.id.tv_doc_type);
        String docTypeText;
        switch (data.getDocumentType() == null ? "" : data.getDocumentType()) {
            case "MRTD_TD1_ID":       docTypeText = "ID (TD1)"; break;
            case "MRTD_TD2_ID":       docTypeText = "ID (TD2)"; break;
            case "MRTD_TD3_PASSPORT": docTypeText = "Passport (TD3)"; break;
            default:                  docTypeText = ""; break;
        }
        // documentType is derived from the MRZ code type, not an independently validated field.
        applyField(tvDocType, docTypeText, EnumValidationStatus.VS_NONE);

        applyField(findViewById(R.id.tv_doc_number),   data.getDocumentNumber(),  data.getFieldValidationStatus("documentNumber"));
        applyField(findViewById(R.id.tv_expiry_date),  data.getDateOfExpire(),    data.getFieldValidationStatus("dateOfExpire"));

        // Tappable too: a line-composite failure can flag the MRZ when no single field did.
        applyField(findViewById(R.id.tv_raw_mrz), data.getMrzText(), data.getFieldValidationStatus("mrzText"));
    }

    /** Renders {@code value}, or "N/A" when empty; a VS_FAILED value is amber and tappable. */
    private void applyField(TextView tv, String value, int status) {
        boolean failed = status == EnumValidationStatus.VS_FAILED;
        boolean empty = value == null || value.isEmpty();

        String text = empty ? "N/A" : value;
        if (failed) {
            // Without the icon the value still underlines and turns amber.
            Drawable icon = ContextCompat.getDrawable(this, R.drawable.ic_error_circle);
            SpannableString spannable = new SpannableString(icon == null ? text : text + "  ￼");
            if (icon != null) {
                int iconSize = Math.round(tv.getTextSize() * 1.2f);
                icon.setBounds(0, 0, iconSize, iconSize);
                spannable.setSpan(new ImageSpan(icon, ImageSpan.ALIGN_BOTTOM),
                        spannable.length() - 1, spannable.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            }
            spannable.setSpan(new UnderlineSpan(), 0, text.length(), Spanned.SPAN_EXCLUSIVE_EXCLUSIVE);
            tv.setText(spannable);
        } else {
            tv.setText(text);
        }
        tv.setTextColor(ContextCompat.getColor(this,
                failed ? R.color.warning_amber : R.color.white));

        if (failed) {
            tv.setOnClickListener(v -> showValidationInfoDialog());
        } else {
            tv.setOnClickListener(null);
            tv.setClickable(false);
        }
    }

    /** Swaps Re-scan for Open Settings: re-scanning would only replay the declined dialog. */
    private void showCameraPermissionAction(int errorCode) {
        // RESTRICTED means device policy withholds the camera; Settings has no toggle to offer.
        if (errorCode != MRZScanResult.EnumErrorCode.EC_CAMERA_PERMISSION_DENIED) {
            return;
        }
        isShowingCameraPermissionError = true;
        findViewById(R.id.btn_rescan).setVisibility(View.GONE);
        View btnOpenSettings = findViewById(R.id.btn_open_settings);
        btnOpenSettings.setVisibility(View.VISIBLE);
        btnOpenSettings.setOnClickListener(v -> {
            Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.fromParts("package", getPackageName(), null));
            startActivity(intent);
        });
    }

    private void showValidationInfoDialog() {
        new AlertDialog.Builder(this)
                .setTitle("Field validation warning")
                .setMessage("This value doesn't match its check digit. The document may be invalid or altered.")
                .setPositiveButton("OK", null)
                .show();
    }

    private void showImages(MRZScanResult result) {
        ImageData mrzSideDocumentImage = result.getDocumentImage(EnumDocumentSide.DS_MRZ); //Nullable
        ImageData oppositeSideDocumentImage = result.getDocumentImage(EnumDocumentSide.DS_OPPOSITE); //Nullable

        ImageData mrzSideOriginalImage = result.getOriginalImage(EnumDocumentSide.DS_MRZ); //Nullable
        ImageData oppositeSideOriginalImage = result.getOriginalImage(EnumDocumentSide.DS_OPPOSITE); //Nullable

        TabLayout tabImages = findViewById(R.id.tab_images);
        ViewPager2 vpImages = findViewById(R.id.vp_images);
        TextView tvImagesHeader = findViewById(R.id.tv_images_header);

        boolean hasProcessed = mrzSideDocumentImage != null || oppositeSideDocumentImage != null;
        boolean hasOriginal = mrzSideOriginalImage != null || oppositeSideOriginalImage != null;

        if(!hasProcessed && !hasOriginal) {
            tvImagesHeader.setVisibility(View.GONE);
            tabImages.setVisibility(View.GONE);
            vpImages.setVisibility(View.GONE);
            return;
        }

        // Tabs only when there are two sets to switch between; one set gets a plain header.
        boolean showsTabs = hasProcessed && hasOriginal;
        tabImages.setVisibility(showsTabs ? View.VISIBLE : View.GONE);
        tvImagesHeader.setVisibility(showsTabs ? View.GONE : View.VISIBLE);
        tvImagesHeader.setText(hasProcessed ? "Processed Image(s)" : "Original Image(s)");
        vpImages.setVisibility(View.VISIBLE);

        vpImages.setAdapter(new FragmentStateAdapter(this) {
            @NonNull
            @Override
            public Fragment createFragment(int position) {
                // Page 0 is the processed pair when it exists, otherwise the original pair.
                if (position == 0 && hasProcessed) {
                    return ImagesFragment.newInstance(mrzSideDocumentImage, oppositeSideDocumentImage);
                } else {
                    return ImagesFragment.newInstance(mrzSideOriginalImage, oppositeSideOriginalImage);
                }
            }

            @Override
            public int getItemCount() {
                return hasProcessed && hasOriginal ? 2 : 1;
            }
        });

        if (showsTabs) {
            new TabLayoutMediator(tabImages, vpImages, (tab, position) ->
                    tab.setText(position == 0 ? "Processed" : "Original")).attach();
        }
    }
}