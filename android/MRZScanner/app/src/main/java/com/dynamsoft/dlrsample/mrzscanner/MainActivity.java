package com.dynamsoft.dlrsample.mrzscanner;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;

import android.content.res.Configuration;
import android.os.Bundle;
import android.view.MenuItem;
import android.view.OrientationEventListener;
import android.widget.Toast;

import com.dynamsoft.core.CoreException;
import com.dynamsoft.core.LicenseManager;
import com.dynamsoft.core.LicenseVerificationListener;
import com.dynamsoft.dlrsample.mrzscanner.ui.main.ScanFragment;
import com.dynamsoft.dlrsample.mrzscanner.ui.main.MainViewModel;


public class MainActivity extends AppCompatActivity {
    private MainViewModel mViewModel;
    private OrientationEventListener mOrientationListener;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.main_activity);
        mViewModel = new ViewModelProvider(this).get(MainViewModel.class);

        //Change toolbar title on different fragments
        mViewModel.currentFragmentFlag.observe(this, flag -> {
            if (flag == MainViewModel.SCAN_FRAGMENT) {
                getSupportActionBar().setTitle("MRZ Scanner");
                getSupportActionBar().setDisplayHomeAsUpEnabled(false);
            } else if (flag == MainViewModel.RESULT_FRAGMENT) {
                getSupportActionBar().setTitle("MRZ Result");
                getSupportActionBar().setDisplayHomeAsUpEnabled(true);
            }
        });

        //Set default device orientation.
        mViewModel.deviceOrientation.setValue(Configuration.ORIENTATION_PORTRAIT);

        if (savedInstanceState == null) {
            LicenseManager.initLicense("DLS2eyJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSJ9", this, new LicenseVerificationListener() {
                @Override
                public void licenseVerificationCallback(boolean isSuccess, CoreException error) {
                    if (!isSuccess) {
                        error.printStackTrace();
                        MainActivity.this.runOnUiThread(new Runnable() {
                            @Override
                            public void run() {
                                Toast ts = Toast.makeText(getBaseContext(), "error:" + error.getErrorCode() + " " + error.getMessage(), Toast.LENGTH_LONG);
                                ts.show();
                            }
                        });
                    }
                }
            });

            getSupportFragmentManager().beginTransaction()
                    .add(R.id.container, ScanFragment.newInstance())
                    .commit();
        }
    }

    @Override
    public void onConfigurationChanged(@NonNull Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        mViewModel.deviceOrientation.setValue(newConfig.orientation);
    }

    @Override
    protected void onResume() {
        super.onResume();
    }

    @Override
    protected void onPause() {
        super.onPause();
    }

    @Override
    public boolean onOptionsItemSelected(@NonNull MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            onBackPressed();
        }
        return super.onOptionsItemSelected(item);
    }

}