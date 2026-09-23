package com.dynamsoft.scanmrz;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.dynamsoft.core.basic_structures.CoreException;
import com.dynamsoft.core.basic_structures.ImageData;

import java.io.ByteArrayOutputStream;

public class ImagesFragment extends Fragment {

    private static final String ARG_IMAGE_1 = "image1";
    private static final String ARG_IMAGE_2 = "image2";

    // Balances fidelity against the ~1 MB Binder cap on a saved-state Bundle.
    private static final int JPEG_QUALITY = 85;

    // Further hedge against that cap — 1024 px keeps each image under ~100 KB.
    private static final int MAX_DIMENSION_PX = 1024;

    // Required — FragmentManager recreates fragments by reflection, from setArguments.
    public ImagesFragment() {
        super();
    }

    @NonNull
    public static ImagesFragment newInstance(@Nullable ImageData imageData1, @Nullable ImageData imageData2) {
        ImagesFragment fragment = new ImagesFragment();
        Bundle args = new Bundle();
        byte[] bytes1 = encode(imageData1);
        byte[] bytes2 = encode(imageData2);
        if (bytes1 != null) args.putByteArray(ARG_IMAGE_1, bytes1);
        if (bytes2 != null) args.putByteArray(ARG_IMAGE_2, bytes2);
        fragment.setArguments(args);
        return fragment;
    }

    @Nullable
    private static byte[] encode(@Nullable ImageData imageData) {
        if (imageData == null) return null;
        try {
            Bitmap bmp = downscaleIfNeeded(imageData.toBitmap());
            ByteArrayOutputStream out = new ByteArrayOutputStream();
            bmp.compress(Bitmap.CompressFormat.JPEG, JPEG_QUALITY, out);
            return out.toByteArray();
        } catch (CoreException ignored) {
            return null;
        }
    }

    @NonNull
    private static Bitmap downscaleIfNeeded(@NonNull Bitmap src) {
        int w = src.getWidth();
        int h = src.getHeight();
        int max = Math.max(w, h);
        if (max <= MAX_DIMENSION_PX) return src;
        float scale = (float) MAX_DIMENSION_PX / max;
        return Bitmap.createScaledBitmap(src, Math.round(w * scale), Math.round(h * scale), true);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater,
                             @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        LinearLayout root = new LinearLayout(requireContext());
        root.setLayoutParams(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
        ));
        root.setOrientation(LinearLayout.HORIZONTAL);
        root.setGravity(Gravity.CENTER_VERTICAL);
        root.setBaselineAligned(false);
        root.setClipToPadding(false);
        root.setClipChildren(false);
        return root;
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        Bundle args = getArguments();
        if (args == null) return;
        LinearLayout root = (LinearLayout) view;
        byte[] bytes1 = args.getByteArray(ARG_IMAGE_1);
        byte[] bytes2 = args.getByteArray(ARG_IMAGE_2);

        addImageView(root, bytes1);
        if (bytes1 != null && bytes2 != null) {
            // 16dp spacer between the two images
            root.addView(new View(requireContext()),
                    new LinearLayout.LayoutParams(
                            (int) (16 * getResources().getDisplayMetrics().density),
                            ViewGroup.LayoutParams.MATCH_PARENT));
        }
        addImageView(root, bytes2);
    }

    private void addImageView(@NonNull LinearLayout root, @Nullable byte[] bytes) {
        if (bytes == null) return;
        Bitmap bmp = BitmapFactory.decodeByteArray(bytes, 0, bytes.length);
        if (bmp == null) return;
        ImageView iv = new ImageView(requireContext());
        LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(
                0, ViewGroup.LayoutParams.MATCH_PARENT, 1f);
        iv.setLayoutParams(lp);
        iv.setScaleType(ImageView.ScaleType.FIT_CENTER);
        iv.setAdjustViewBounds(true);
        iv.setImageBitmap(bmp);
        root.addView(iv);
    }
}
