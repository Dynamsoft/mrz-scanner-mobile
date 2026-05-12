package com.dynamsoft.scanmrz;

import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.activity.result.ActivityResultLauncher;
import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.fragment.app.Fragment;
import androidx.viewpager2.adapter.FragmentStateAdapter;
import androidx.viewpager2.widget.ViewPager2;

import com.dynamsoft.core.basic_structures.CoreException;
import com.dynamsoft.core.basic_structures.ImageData;
import com.dynamsoft.mrzscannerbundle.ui.EnumDocumentSide;
import com.dynamsoft.mrzscannerbundle.ui.MRZData;
import com.dynamsoft.mrzscannerbundle.ui.MRZScanResult;
import com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity;
import com.dynamsoft.mrzscannerbundle.ui.MRZScannerConfig;
import com.google.android.material.tabs.TabLayout;
import com.google.android.material.tabs.TabLayoutMediator;

public class ResultActivity extends AppCompatActivity {
    public static final int REQUEST_CODE = 1024;

    public static final String EXTRA_RESULT = "RESULT";
    public static final String EXTRA_ACTION = "ACTION";
    public static final int ACTION_RESCAN = 0;
    public static final int ACTION_RETURN_HOME = 1;
    private ActivityResultLauncher<MRZScannerConfig> launcher;


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
            return;
        }

        findViewById(R.id.result_view).setVisibility(View.VISIBLE);
        findViewById(R.id.no_result_view).setVisibility(View.GONE);
        MRZData data = result.getData();
        String genderText = data.getSex().substring(0,1).toUpperCase() + data.getSex().substring(1).toLowerCase();


        //Main Info
        TextView tvFullName = findViewById(R.id.tv_full_name);
        tvFullName.setText(data.getFirstName() + " " + data.getLastName());
        TextView tvGenderAndAge = findViewById(R.id.tv_gender_and_age);
        tvGenderAndAge.setText(genderText + ", " + data.getAge() + " years old");
        TextView tvExpiry = findViewById(R.id.tv_expiry);
        tvExpiry.setText("Expiry: " + data.getDateOfExpire());

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
        TextView tvGivenName = findViewById(R.id.tv_given_name);
        tvGivenName.setText(data.getFirstName());
        TextView tvSurname = findViewById(R.id.tv_surname);
        tvSurname.setText(data.getLastName());
        TextView tvDateOfBirth = findViewById(R.id.tv_date_of_birth);
        tvDateOfBirth.setText(data.getDateOfBirth());
        TextView tvGender = findViewById(R.id.tv_gender);
        tvGender.setText(genderText);
        TextView tvNationality = findViewById(R.id.tv_nationality);
        tvNationality.setText(data.getNationality());

        //Document Info
        TextView tvDocType = findViewById(R.id.tv_doc_type);
        switch (data.getDocumentType()) {
            case "MRTD_TD1_ID":
                tvDocType.setText("ID (TD1)");
                break;
            case "MRTD_TD2_ID":
                tvDocType.setText("ID (TD2)");
                break;
            case "MRTD_TD3_PASSPORT":
                tvDocType.setText("Passport (TD3)");
                break;
        }

        TextView tvDocNumber = findViewById(R.id.tv_doc_number);
        tvDocNumber.setText(data.getDocumentNumber());
        TextView tvExpiryDate = findViewById(R.id.tv_expiry_date);
        tvExpiryDate.setText(data.getDateOfExpire());

        //Raw MRZ Text
        TextView tvRawMRZ = findViewById(R.id.tv_raw_mrz);
        tvRawMRZ.setText(data.getMrzText());
    }

    private void showImages(MRZScanResult result) {
        ImageData mrzSideDocumentImage = result.getDocumentImage(EnumDocumentSide.DS_MRZ); //Nullable
        ImageData oppositeSideDocumentImage = result.getDocumentImage(EnumDocumentSide.DS_OPPOSITE); //Nullable

        ImageData mrzSideOriginalImage = result.getOriginalImage(EnumDocumentSide.DS_MRZ); //Nullable
        ImageData oppositeSideOriginalImage = result.getOriginalImage(EnumDocumentSide.DS_OPPOSITE); //Nullable

        TabLayout tabImages = findViewById(R.id.tab_images);
        ViewPager2 vpImages = findViewById(R.id.vp_images);

        if(mrzSideOriginalImage == null && mrzSideDocumentImage == null) {
            //The config in MainActivity does not set returnOriginalImage = true, so the original image is not returned by default,
            // so the original images are not displayed in the result page, and there is no need to switch tabs.
            // If you want to display the original images, you can go to MainActivity and set config.setReturnOriginalImage(true);
            tabImages.setVisibility(View.GONE);
        }


        if(mrzSideDocumentImage == null && mrzSideOriginalImage == null) {
            tabImages.setVisibility(View.GONE);
            vpImages.setVisibility(View.GONE);
            return;
        } else {
            tabImages.setVisibility(View.VISIBLE);
            vpImages.setVisibility(View.VISIBLE);
        }

        vpImages.setAdapter(new FragmentStateAdapter(this) {
            @NonNull
            @Override
            public Fragment createFragment(int position) {
                if (position == 0 && mrzSideDocumentImage != null) {
                    return ImagesFragment.newInstance(mrzSideDocumentImage, oppositeSideDocumentImage);
                } else {
                    return ImagesFragment.newInstance(mrzSideOriginalImage, oppositeSideOriginalImage);
                }
            }

            @Override
            public int getItemCount() {
                if(mrzSideDocumentImage != null && mrzSideOriginalImage != null) {
                    return 2;
                } else {
                    return 1;
                }
            }
        });

        if(mrzSideOriginalImage != null || oppositeSideOriginalImage != null) {
            new TabLayoutMediator(tabImages, vpImages, (tab, position) -> {
                if (position == 0 && mrzSideDocumentImage != null) {
                    tab.setText("Processed");
                } else {
                    tab.setText("Original");
                }
            }).attach();
        }
    }
}