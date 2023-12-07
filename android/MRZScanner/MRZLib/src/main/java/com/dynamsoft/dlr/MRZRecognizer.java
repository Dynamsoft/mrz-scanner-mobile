package com.dynamsoft.dlr;

import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.util.Log;

import com.dynamsoft.core.ImageData;
import com.dynamsoft.dce.CameraEnhancer;
import com.dynamsoft.dce.DCECameraView;
import com.dynamsoft.dce.DCEDrawingLayer;
import com.dynamsoft.dce.DCEFrame;

import java.io.InputStream;
import java.util.concurrent.Executors;

public class MRZRecognizer extends LabelRecognizer {
    private static final String TAG = "MRZRecognizer";
    private final EnumMRZDocumentType mDocumentType;
    private MRZResultListener mMRZResultListener;

    public MRZRecognizer() throws LabelRecognizerException {
       this(EnumMRZDocumentType.DEFALUT);
    }

    public MRZRecognizer(EnumMRZDocumentType documentType) throws LabelRecognizerException {
        super();
        mDocumentType = documentType;
        initDefaultTemplate();
    }

    @Override
    protected void initDefaultModel() {
        try {
            AssetManager manager = DLRLicenseUtil.getApplication().getAssets();
            InputStream isPrototxt = manager.open("MRZ/MRZ.prototxt");
            byte[] prototxt = new byte[isPrototxt.available()];
            isPrototxt.read(prototxt);
            isPrototxt.close();

            InputStream isCharacterModel = manager.open("MRZ/MRZ.caffemodel");
            byte[] characterModel = new byte[isCharacterModel.available()];
            isCharacterModel.read(characterModel);
            isCharacterModel.close();

            InputStream isTxt = manager.open("MRZ/MRZ.txt");
            byte[] txt = new byte[isTxt.available()];
            isTxt.read(txt);
            isTxt.close();

            appendCharacterModelBuffer("MRZ", prototxt, txt, characterModel);
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    protected void initDefaultTemplate() {
        try {
            AssetManager manager = DLRLicenseUtil.getApplication().getAssets();
            String tmpName = "";
            if (mDocumentType == EnumMRZDocumentType.MDT_ALL || mDocumentType == null) {
                tmpName = "All";
            } else if (mDocumentType == EnumMRZDocumentType.MDT_PASSPORT) {
                tmpName = "Passport";
            } else if (mDocumentType == EnumMRZDocumentType.MDT_ID_CARD) {
                tmpName = "IDCard";
            } else if (mDocumentType == EnumMRZDocumentType.MDT_VISA) {
                tmpName = "Visa";
            }
            InputStream isMrzSetting = manager.open("MRZ/template_" + tmpName + ".json");
            StringBuilder sb = new StringBuilder();
            byte[] b = new byte[1024];
            for (int i; (i = isMrzSetting.read(b)) != -1; ) {
                sb.append(new String(b, 0, i));
            }
            isMrzSetting.close();
            String mrzSetting = sb.toString();
            initRuntimeSettings(mrzSetting);
        } catch (Exception e) {
            e.printStackTrace();
        }

    }

    public void setMRZResultListener(MRZResultListener listener) {
        mMRZResultListener = listener;
    }

    public MRZResult recognizeMRZFromFile(String fileName) throws LabelRecognizerException {
        DLRResult[] dlrResults = recognizeFile(fileName);
        return parseDLRResToMRZRes(dlrResults);
    }

    public MRZResult recognizeMRZFromBuffer(ImageData imageData) throws LabelRecognizerException {
        DLRResult[] dlrResults = recognizeBuffer(imageData);
        return parseDLRResToMRZRes(dlrResults);
    }

    public MRZResult recognizeMRZFromImage(Bitmap image) throws LabelRecognizerException {
        DLRResult[] dlrResults = recognizeImage(image);
        return parseDLRResToMRZRes(dlrResults);
    }

    public MRZResult recognizeMRZFileInMemory(byte[] fileBytes) throws LabelRecognizerException {
        DLRResult[] dlrResults = recognizeFileInMemory(fileBytes);
        return parseDLRResToMRZRes(dlrResults);
    }

    @Override
    public void startScanning() {
        if (executorService == null) {
            executorService = Executors.newSingleThreadExecutor();
            executorService.submit(new ImageSourceMRZRunnable(this));
        }
    }

    @Override
    public void stopScanning() {
        super.stopScanning();
    }

    private MRZResult parseDLRResToMRZRes(DLRResult[] dlrResults) {
        if (dlrResults == null || dlrResults.length == 0 || dlrResults[0].lineResults.length < 2) {
            return null;
        }
        int linesLen = dlrResults[0].lineResults.length;
        String[] rawTexts = null;
        if (dlrResults[0].lineResults[linesLen - 1].text.length() == 30) {
            //TD1, need 3 lines
            if (linesLen < 3) {
                return null;
            }
            rawTexts = new String[3];
        } else {
            rawTexts = new String[2];
        }

        //Only get last 2 or 3 lines text.
        for (int i = linesLen - rawTexts.length; i < linesLen; i++) {
            rawTexts[i - (linesLen - rawTexts.length)] = dlrResults[0].lineResults[i].text;
        }

        if (mDocumentType == EnumMRZDocumentType.MDT_PASSPORT) {
            return ParseUtil.parseTD3(rawTexts);
        } else if (mDocumentType == EnumMRZDocumentType.MDT_ID_CARD) {
            if (rawTexts.length == 3) {
                return ParseUtil.parseTD1(rawTexts);
            } else {
                return ParseUtil.parseTD2(rawTexts);
            }
        } else if (mDocumentType == EnumMRZDocumentType.MDT_VISA) {
            MRZResult mrzResult = ParseUtil.parseMRVA(rawTexts);
            if (mrzResult != null && mrzResult.isParsed) {
                return mrzResult;
            } else {
                return ParseUtil.parseMRVB(rawTexts);
            }
        } else if (mDocumentType == EnumMRZDocumentType.MDT_ALL) {
            if (rawTexts.length == 3) {
                return ParseUtil.parseTD1(rawTexts);
            } else {
                if(rawTexts[0].length() == 36) {
                    MRZResult mrzResult = ParseUtil.parseTD2(rawTexts);
                    if (mrzResult != null && mrzResult.isParsed) {
                        return mrzResult;
                    } else {
                        return ParseUtil.parseMRVB(rawTexts);
                    }
                } else if(rawTexts[0].length() == 44) {
                    MRZResult mrzResult = ParseUtil.parseTD3(rawTexts);
                    if (mrzResult != null && mrzResult.isParsed) {
                        return mrzResult;
                    } else {
                        return ParseUtil.parseMRVA(rawTexts);
                    }
                }
            }
        }
        return null;
    }

    private static class ImageSourceMRZRunnable extends ImageSourceRecognizeRunnable {
        private final MRZRecognizer mrzRecognizer;

        private ImageSourceMRZRunnable(MRZRecognizer recognizer) {
            super();
            mrzRecognizer = recognizer;
        }
        @Override
        public void run() {
            while (mrzRecognizer!=null && mrzRecognizer.executorService != null && !mrzRecognizer.executorService.isShutdown()) {
                if (mrzRecognizer.mImageSource == null) {
                    continue;
                }
                boolean ifUseDCE = mrzRecognizer.mImageSource instanceof CameraEnhancer;
                ImageData imageData = mrzRecognizer.mImageSource.getImage();
                if (imageData == null) {
                    continue;
                }
                MRZResult mrzResult = null;
                try {
                    DLRResult[] dlrResults = mrzRecognizer.recognizeBuffer(imageData);
                    mrzResult = mrzRecognizer.parseDLRResToMRZRes(dlrResults);
                    if (ifUseDCE) {
                        DCECameraView cameraView = ((CameraEnhancer) mrzRecognizer.mImageSource).getCameraView();
                        if (cameraView != null) {
                            DCEDrawingLayer layer = cameraView.getDrawingLayer(DCEDrawingLayer.DLR_LAYER_ID);
                            if (((DCEFrame) imageData).getCropRegion() != null) {
                                layer.setDrawingItems(getDrawingItems(dlrResults, ((DCEFrame) imageData).getCropRegion().left, ((DCEFrame) imageData).getCropRegion().top));
                            } else {
                                layer.setDrawingItems(getDrawingItems(dlrResults, 0, 0));
                            }
                        }
                        if (mrzRecognizer.mMRZResultListener != null) {
                            mrzRecognizer.mMRZResultListener.mrzResultCallback(((DCEFrame) imageData).getFrameId(), imageData, mrzResult);
                        }
                    } else if (mrzRecognizer.mMRZResultListener != null) {
                        mrzRecognizer.mMRZResultListener.mrzResultCallback(0, imageData, mrzResult);
                    }
                } catch (LabelRecognizerException e) {
                    Log.e("error", e.getMessage() + " " + e.getErrorCode());
                }
                if (mrzRecognizer.executorService == null || mrzRecognizer.executorService.isShutdown()) {
                    break;
                }

            }
        }
    }


}
