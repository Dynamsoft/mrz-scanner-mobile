package com.dynamsoft.mrzscannerbundle.ui.utils;

import android.content.Context;
import android.graphics.Point;
import android.view.ViewTreeObserver;

import androidx.annotation.NonNull;

import com.dynamsoft.dce.CameraEnhancer;
import com.dynamsoft.dce.CameraView;
import com.dynamsoft.dce.EnumCameraPosition;
import com.dynamsoft.mrzscannerbundle.ui.MRZScannerConfig;

public class ViewUtil {
    public static int dpToPx(float dp, Context context) {
        float density = context.getResources().getDisplayMetrics().density;
        return Math.round(dp * density);
    }

    public static void configCameraViewButton(@NonNull CameraEnhancer camera, @NonNull MRZScannerConfig config) {
        CameraView cameraView = camera.getCameraView();
        if(cameraView == null) {
            return;
        }
        boolean torchButtonVisible = config.isTorchButtonVisible();
        boolean cameraToggleButtonVisible = config.isCameraToggleButtonVisible();
        Runnable runnable = () -> {
            int cameraViewWidth = cameraView.getWidth();
            int cameraViewHeight = cameraView.getHeight();
            int defaultBtnHalfSize = dpToPx(22.5f, cameraView.getContext());
            int defaultBtnSize = dpToPx(45f, cameraView.getContext());
            int defaultMargin = dpToPx(25f, cameraView.getContext());
            int defaultMarginBottom = cameraView.getHeight() / 8;
            Point centerBtnLeftTopPt = new Point(cameraViewWidth / 2 - defaultBtnHalfSize, cameraViewHeight - defaultMarginBottom - defaultBtnSize);
            Point leftBtnLeftTopPt = new Point(cameraViewWidth / 2 - defaultBtnSize - defaultMargin, cameraViewHeight - defaultMarginBottom - defaultBtnSize);
            Point rightBtnLeftTopPt = new Point(cameraViewWidth / 2 + defaultMargin, cameraViewHeight - defaultMarginBottom - defaultBtnSize);
            if (camera.getCameraPosition() == EnumCameraPosition.CP_BACK) {
                if (torchButtonVisible && cameraToggleButtonVisible) {
                    cameraView.setTorchButton(leftBtnLeftTopPt);
                    cameraView.setCameraToggleButton(rightBtnLeftTopPt);
                } else if (torchButtonVisible) {
                    cameraView.setTorchButton(centerBtnLeftTopPt);
                } else if (cameraToggleButtonVisible) {
                    cameraView.setCameraToggleButton(centerBtnLeftTopPt);
                }
                cameraView.setTorchButtonVisible(torchButtonVisible);
                cameraView.setCameraToggleButtonVisible(cameraToggleButtonVisible);
            } else {
                if (cameraToggleButtonVisible) {
                    cameraView.setCameraToggleButton(centerBtnLeftTopPt);
                }
                cameraView.setTorchButtonVisible(false);
                cameraView.setCameraToggleButtonVisible(cameraToggleButtonVisible);
            }
        };
        if (cameraView.getWidth() == 0 || cameraView.getHeight() == 0) {
            cameraView.getViewTreeObserver().addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
                @Override
                public void onGlobalLayout() {
                    runnable.run();
                    cameraView.getViewTreeObserver().removeOnGlobalLayoutListener(this);
                }
            });
        } else {
            runnable.run();
        }
    }
}
