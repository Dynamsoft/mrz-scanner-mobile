package com.dynamsoft.mrzscannerbundle.ui;

import androidx.annotation.Nullable;

import com.dynamsoft.dcp.EnumValidationStatus;
import com.dynamsoft.dcp.ParsedResultItem;

import java.io.Serializable;
import java.util.Calendar;
import java.util.HashMap;

public class MRZData implements Serializable {
    String documentType; //MRTD_TD1_ID,MRTD_TD2_ID,MRTD_TD3_PASSPORT
    String firstName;
    String lastName;
    String sex;
    String issuingState;
    String nationality;
    String dateOfBirth;
    String dateOfExpire;
    String documentNumber;
    int age;
    String mrzText;

    String issuingStateRaw;
    String nationalityRaw;
    @Nullable
    String optionalData1;
    @Nullable
    String optionalData2;
    @Nullable
    String personalNumber;

    public MRZData() {
    }

    MRZData(String firstName, String lastName, String sex,
            String issuingState, String nationality, String dateOfBirth, String dateOfExpire,
            String documentNumber, int age, String mrzText, String documentType,
            String issuingStateRaw, String nationalityRaw,
            @Nullable String optionalData1, @Nullable String optionalData2, @Nullable String personalNumber) {
        this.firstName = firstName;
        this.lastName = lastName;
        this.sex = sex;
        this.issuingState = issuingState;
        this.nationality = nationality;
        this.dateOfBirth = dateOfBirth;
        this.dateOfExpire = dateOfExpire;
        this.documentNumber = documentNumber;
        this.age = age;
        this.mrzText = mrzText;
        this.documentType = documentType;

        //Added in 3.4.1000
        this.nationalityRaw = nationalityRaw;
        this.issuingStateRaw = issuingStateRaw;
        this.optionalData1 = optionalData1;
        this.optionalData2 = optionalData2;
        this.personalNumber = personalNumber;
    }

    public String getFirstName() {
        return firstName;
    }

    public String getLastName() {
        return lastName;
    }

    public String getSex() {
        return sex;
    }

    public String getIssuingState() {
        return issuingState;
    }

    public String getNationality() {
        return nationality;
    }

    public String getDateOfBirth() {
        return dateOfBirth;
    }

    public String getDateOfExpire() {
        return dateOfExpire;
    }

    public String getDocumentType() {
        return documentType;
    }

    public String getDocumentNumber() {
        return documentNumber;
    }

    public int getAge() {
        return age;
    }

    public String getMrzText() {
        return mrzText;
    }

    public String getIssuingStateRaw() {
        return issuingStateRaw;
    }

    public String getNationalityRaw() {
        return nationalityRaw;
    }

    @Nullable
    public String getOptionalData1() {
        return optionalData1;
    }

    @Nullable
    public String getOptionalData2() {
        return optionalData2;
    }

    @Nullable
    public String getPersonalNumber() {
        return personalNumber;
    }

    @Nullable
    static MRZData fromParsedResultItem(@Nullable ParsedResultItem item) {
        if (item == null || item.getParsedFields() == null) return null;
        HashMap<String, String> map = item.getParsedFields();
        String docType = item.getCodeType();
        boolean isValid;
        if (docType.equals("MRTD_TD1_ID")) {
            isValid = item.getFieldValidationStatus("line1") != EnumValidationStatus.VS_FAILED
                    && item.getFieldValidationStatus("line2") != EnumValidationStatus.VS_FAILED
                    && item.getFieldValidationStatus("line3") != EnumValidationStatus.VS_FAILED;
        } else {
            isValid = item.getFieldValidationStatus("line1") != EnumValidationStatus.VS_FAILED
                    && item.getFieldValidationStatus("line2") != EnumValidationStatus.VS_FAILED;
        }
        if (!isValid) return null;

        String documentNumber = map.get("passportNumber") == null ? map.get("documentNumber") == null
                ? map.get("longDocumentNumber") == null ? "" : map.get("longDocumentNumber") :
                map.get("documentNumber") : map.get("passportNumber");
        String sex = map.get("sex");
        String issuingState = map.get("issuingState");
        String nationality = map.get("nationality");
        String issuingStateRaw = item.getFieldRawValue("issuingState");
        String nationalityRaw = item.getFieldRawValue("nationality");

        if (documentNumber == null || sex == null
                || issuingState == null || nationality == null
                || issuingStateRaw == null || nationalityRaw == null
                || map.get("dateOfBirth") == null || map.get("dateOfExpiry") == null) {
            return null;
        }

        String firstName = map.get("secondaryIdentifier") == null ? "" : map.get("secondaryIdentifier");
        String lastName = map.get("primaryIdentifier") == null ? "" : map.get("primaryIdentifier");

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
            //It may be "XX" or "undefined", not a number
            birthMonth = Integer.parseInt(map.get("birthMonth"));
        } catch (Exception ignore) {
        }
        try {
            //It may be "XX" or "undefined", not a number
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

        String personalNumber = map.get("personalNumber");
        String optionalData1 = item.getFieldRawValue("optionalData1");
        String optionalData2 = item.getFieldRawValue("optionalData2");

        return new MRZData(firstName, lastName, sex,
                issuingState, nationality, dateOfBirth, dateOfExpire,
                documentNumber, age, mrzText, docType,
                issuingStateRaw, nationalityRaw,
                optionalData1, optionalData2, personalNumber
        );
    }
}
