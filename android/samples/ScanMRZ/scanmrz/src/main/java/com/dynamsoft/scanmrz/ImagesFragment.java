// `scanmrz/src/main/java/com/dynamsoft/scanmrz/ImagesFragment.java`
package com.dynamsoft.scanmrz;

import android.graphics.Bitmap;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.dynamsoft.core.basic_structures.CoreException;
import com.dynamsoft.core.basic_structures.ImageData;

public class ImagesFragment extends Fragment {

    private ImageData imageData1;
    private ImageData imageData2;

    public ImagesFragment(ImageData imageData1, ImageData imageData2) {
        super();
        this.imageData1 = imageData1;
        this.imageData2 = imageData2;
    }

    /**
     * 传入 0..N 张图片（可包含 null，会被忽略）
     * 说明：用 byte[] 放进 Bundle，避免 ImageData 不可序列化的问题。
     */
    @NonNull
    public static ImagesFragment newInstance(@Nullable ImageData imageData1, @Nullable ImageData imageData2) {
        return new ImagesFragment(imageData1, imageData2);
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull android.view.LayoutInflater inflater,
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
        LinearLayout root = (LinearLayout) view;
        ImageData[] imageDatas = new ImageData[]{imageData1, imageData2};
        for (int i = 0; i < imageDatas.length; i++) {
            ImageData imageData = imageDatas[i];
            if(imageData1 != null && imageData2 != null && i == 1) {
                // add 16dp spacing between two images
                root.addView(new View(requireContext()),
                        new LinearLayout.LayoutParams((int)(16 * getResources().getDisplayMetrics().density),
                        ViewGroup.LayoutParams.MATCH_PARENT));
            }
            if (imageData != null) {
                try {
                    Bitmap bmp = imageData.toBitmap();
                    ImageView iv = new ImageView(requireContext());
                    LinearLayout.LayoutParams lp
                            = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1f);
                    iv.setLayoutParams(lp);
                    iv.setScaleType(ImageView.ScaleType.FIT_CENTER);
                    iv.setAdjustViewBounds(true);
                    iv.setImageBitmap(bmp);
                    root.addView(iv);
                } catch (CoreException e) {
                    e.printStackTrace();
                }
            }
        }
    }
}
