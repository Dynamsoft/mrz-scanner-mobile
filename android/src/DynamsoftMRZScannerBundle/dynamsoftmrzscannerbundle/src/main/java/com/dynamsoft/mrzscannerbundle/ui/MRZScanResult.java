package com.dynamsoft.mrzscannerbundle.ui;

import static com.dynamsoft.mrzscannerbundle.ui.MRZScanResult.EnumResultStatus.RS_CANCELED;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScanResult.EnumResultStatus.RS_EXCEPTION;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScanResult.EnumResultStatus.RS_FINISHED;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity.EXTRA_DOC_TYPE;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity.EXTRA_ERROR_CODE;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity.EXTRA_ERROR_STRING;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity.EXTRA_ISSUING_STATE;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity.EXTRA_NATIONALITY;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity.EXTRA_NUMBER;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity.EXTRA_RESULT;
import static com.dynamsoft.mrzscannerbundle.ui.MRZScannerActivity.EXTRA_STATUS_CODE;

import android.content.Intent;

import androidx.annotation.IntDef;

import java.util.Calendar;
import java.util.HashMap;
public final class MRZScanResult {
    @EnumResultStatus
    private int resultStatus;
    private int errorCode;
    private String errorString;
    private MRZData mrzData;

    @IntDef(value = {RS_FINISHED, RS_CANCELED, RS_EXCEPTION})
    public @interface EnumResultStatus {
        int RS_FINISHED = 0;
        int RS_CANCELED = 1;
        int RS_EXCEPTION = 2;
    }

    public MRZScanResult(int resultCode, Intent data) {
        if (data != null) {
            resultStatus = data.getIntExtra(EXTRA_STATUS_CODE, 0);
            errorCode = data.getIntExtra(EXTRA_ERROR_CODE, 0);
            errorString = data.getStringExtra(EXTRA_ERROR_STRING);
            mrzData = intentToMRZData(data);
        }
    }

    public MRZData getData() {
        return mrzData;
    }

    @EnumResultStatus
    public int getResultStatus() {
        return resultStatus;
    }

    public int getErrorCode() {
        return errorCode;
    }

    public String getErrorString() {
        return errorString;
    }

    private MRZData intentToMRZData(Intent intent) {
        String docType = intent.getStringExtra(EXTRA_DOC_TYPE);
        String nationality = intent.getStringExtra(EXTRA_NATIONALITY);
        String issuingState = intent.getStringExtra(EXTRA_ISSUING_STATE);
        String documentNumber = intent.getStringExtra(EXTRA_NUMBER);

        HashMap<String, String> map = (HashMap<String, String>) intent.getSerializableExtra(EXTRA_RESULT);
        if (map == null) {
            return null;
        }

        String firstName = map.get("secondaryIdentifier") == null ? "" : map.get("secondaryIdentifier");
        String lastName = map.get("primaryIdentifier") == null ? "" : " " + map.get("primaryIdentifier");
        String sex = map.get("sex");

        String dateOfExpire = (Integer.parseInt(map.get("expiryYear")) + 2000) + "-" + map.get("expiryMonth") + "-" + map.get("expiryDay");

        Calendar calendar = Calendar.getInstance();
        int currentYear = calendar.get(Calendar.YEAR);
        int currentMonth = calendar.get(Calendar.MONTH) + 1;
        int currentDay = calendar.get(Calendar.DAY_OF_MONTH);

        int birthYear = 0, birthMonth = 0, birthDay = 0;
        try {
            birthYear = Integer.parseInt(map.get("birthYear"));
        } catch (Exception ignore) {
        }
        try {
            birthMonth = Integer.parseInt(map.get("birthMonth"));
        } catch (Exception ignore) {
        }
        try {
            birthDay = Integer.parseInt(map.get("birthDay"));
        } catch (Exception ignore) {
        }

        // Age information is not directly obtained from the MRZ but you can calculate it based on the date of birth.
        birthYear += 1900;
        int birthNumber = birthYear * 10000 + birthMonth * 100 + birthDay;
        int currentDayNumber = currentYear * 10000 + currentMonth * 100 + currentDay;
        int age = (currentDayNumber - birthNumber) / 10000;
        if (age >= 100) {
            age -= 100;
            birthYear += 100;
        }
        String dateOfBirth = birthYear + "-" + map.get("birthMonth") + "-" + map.get("birthDay");

        String line1 = map.get("line1") == null ? "" : map.get("line1");
        String line2 = map.get("line2") == null ? "" : map.get("line2");
        String line3 = map.get("line3") == null ? "" : map.get("line3");
        String mrzText = (line1 + "\n" + line2 + "\n" + line3).trim();

        return new MRZData(firstName, lastName, sex, issuingState, nationality, dateOfBirth, dateOfExpire,
                documentNumber, age, mrzText, docType);
    }
}
