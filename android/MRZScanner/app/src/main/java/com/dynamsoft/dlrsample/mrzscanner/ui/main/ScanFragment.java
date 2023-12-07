package com.dynamsoft.dlrsample.mrzscanner.ui.main;

import androidx.lifecycle.ViewModelProvider;

import android.content.res.Configuration;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.dynamsoft.core.ImageData;
import com.dynamsoft.core.RegionDefinition;
import com.dynamsoft.dce.CameraEnhancer;
import com.dynamsoft.dce.CameraEnhancerException;
import com.dynamsoft.dce.DCECameraView;
import com.dynamsoft.dlr.LabelRecognizerException;
import com.dynamsoft.dlr.MRZRecognizer;
import com.dynamsoft.dlr.MRZResult;
import com.dynamsoft.dlr.MRZResultListener;
import com.dynamsoft.dlrsample.mrzscanner.R;

public class ScanFragment extends Fragment {
    private static final String TAG = "ScanFragment";
    private DCECameraView mCameraView;
    private CameraEnhancer mCamera;
    private MRZRecognizer mMRZRecognizer;
    private MainViewModel mViewModel;
    private boolean isShowing;

    public static ScanFragment newInstance() {
        return new ScanFragment();
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        initViewModel();
        return inflater.inflate(R.layout.scan_fragment, container, false);
    }


    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        mCameraView = view.findViewById(R.id.dce_camera_view);
        mCamera = new CameraEnhancer(requireActivity());
        mCamera.setCameraView(mCameraView);

        try {
            mMRZRecognizer = new MRZRecognizer();
        } catch (LabelRecognizerException e) {
            e.printStackTrace();
        }

        mMRZRecognizer.setImageSource(mCamera);
        mMRZRecognizer.setMRZResultListener(new MRZResultListener() {
            @Override
            public void mrzResultCallback(int i, ImageData imageData, MRZResult mrzResult) {
                if (mrzResult != null && !isShowing && mrzResult.isParsed) {
                    isShowing = true;
                    mViewModel.mrzResult = mrzResult;
                    requireActivity().getSupportFragmentManager()
                            .beginTransaction()
                            .add(R.id.container, ResultFragment.newInstance())
                            .addToBackStack(null)
                            .hide(ScanFragment.this)
                            .commit();
                }
            }
        });
    }

    @Override
    public void onHiddenChanged(boolean hidden) {
        super.onHiddenChanged(hidden);
        if (hidden) {
            try {
                mCamera.close();
            } catch (CameraEnhancerException e) {
                e.printStackTrace();
            }
            mMRZRecognizer.stopScanning();
        } else {
            mViewModel.currentFragmentFlag.setValue(MainViewModel.SCAN_FRAGMENT);
            isShowing = false;
            try {
                mCamera.open();
            } catch (CameraEnhancerException e) {
                e.printStackTrace();
            }
            mMRZRecognizer.startScanning();
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        if (!isShowing) {
            mMRZRecognizer.startScanning();
            try {
                mCamera.open();
            } catch (CameraEnhancerException e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        mMRZRecognizer.stopScanning();
        try {
            mCamera.close();
        } catch (CameraEnhancerException e) {
            e.printStackTrace();
        }
    }

    private void initViewModel() {
        mViewModel = new ViewModelProvider(requireActivity()).get(MainViewModel.class);
        mViewModel.currentFragmentFlag.setValue(MainViewModel.SCAN_FRAGMENT);

        //Reset the runtimeSettings of mrz recognizer when the device rotation changes.
        mViewModel.deviceOrientation.observe(getViewLifecycleOwner(), orientationValue -> {
            if(orientationValue == Configuration.ORIENTATION_PORTRAIT) {
                RegionDefinition region = new RegionDefinition(10, 43, 90, 57, 1);
                try {
                    mCamera.setScanRegion(region);
                } catch (CameraEnhancerException e) {
                    e.printStackTrace();
                }
            } else if(orientationValue == Configuration.ORIENTATION_LANDSCAPE) {
                RegionDefinition region = new RegionDefinition(20, 40, 80, 60, 1);
                try {
                    mCamera.setScanRegion(region);
                } catch (CameraEnhancerException e) {
                    e.printStackTrace();
                }
            }
        });
    }

}