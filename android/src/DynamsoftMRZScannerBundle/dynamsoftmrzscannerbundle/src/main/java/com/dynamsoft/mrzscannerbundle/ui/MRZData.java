package com.dynamsoft.mrzscannerbundle.ui;

import androidx.annotation.Nullable;

import com.dynamsoft.dcp.EnumValidationStatus;
import com.dynamsoft.dcp.ParsedResultItem;

import java.io.Serializable;
import java.util.Calendar;
import java.util.HashMap;

public class MRZData implements Serializable {
    private static final long serialVersionUID = 1L; // Never change: results parceled by older builds must still read.
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

    /// Validation status by DCP raw field name; null for instances deserialized from older versions.
    @Nullable
    HashMap<String, Integer> fieldValidation;

    /// Which raw key held the document number, so getFieldValidationStatus finds the right one.
    @Nullable
    String documentNumberRawKey;

    public MRZData() {
    }

    public String getFirstName() { return firstName; }

    public String getLastName() { return lastName; }

    public String getSex() { return sex; }

    public String getIssuingState() { return issuingState; }

    public String getNationality() { return nationality; }

    public String getDateOfBirth() { return dateOfBirth; }

    public String getDateOfExpire() { return dateOfExpire; }

    public String getDocumentType() { return documentType; }

    public String getDocumentNumber() { return documentNumber; }

    public int getAge() { return age; }

    public String getMrzText() { return mrzText; }

    public String getIssuingStateRaw() { return issuingStateRaw; }

    public String getNationalityRaw() { return nationalityRaw; }

    @Nullable
    public String getOptionalData1() { return optionalData1; }

    @Nullable
    public String getOptionalData2() { return optionalData2; }

    @Nullable
    public String getPersonalNumber() { return personalNumber; }

    /// Friendly field name -> the DCP raw key, or the keys a composite takes the worst of.
    private static final HashMap<String, String[]> RAW_KEYS = new HashMap<>();

    static {
        RAW_KEYS.put("firstName", new String[]{"secondaryIdentifier"});
        RAW_KEYS.put("lastName", new String[]{"primaryIdentifier"});
        RAW_KEYS.put("sex", new String[]{"sex"});
        RAW_KEYS.put("nationality", new String[]{"nationality"});
        RAW_KEYS.put("issuingState", new String[]{"issuingState"});
        RAW_KEYS.put("optionalData1", new String[]{"optionalData1"});
        RAW_KEYS.put("optionalData2", new String[]{"optionalData2"});
        RAW_KEYS.put("personalNumber", new String[]{"personalNumber"});
        RAW_KEYS.put("dateOfBirth", new String[]{"dateOfBirth", "birthYear", "birthMonth", "birthDay"});
        RAW_KEYS.put("dateOfExpire", new String[]{"dateOfExpiry", "expiryYear", "expiryMonth", "expiryDay"});
        RAW_KEYS.put("mrzText", new String[]{"line1", "line2", "line3"});
    }

    /// DCP status by friendly field name; composites take worst-of, unknown and pre-3.6.2000 give VS_NONE.
    public int getFieldValidationStatus(String fieldName) {
        if (fieldValidation == null || fieldName == null) return EnumValidationStatus.VS_NONE;
        // documentNumber's raw key varies by MRZ format, so it is resolved per scan.
        String[] keys = "documentNumber".equals(fieldName)
                ? (documentNumberRawKey == null ? new String[0] : new String[]{documentNumberRawKey})
                : RAW_KEYS.get(fieldName);
        if (keys == null) return EnumValidationStatus.VS_NONE;

        boolean anySucceeded = false;
        for (String key : keys) {
            Integer status = fieldValidation.get(key);
            if (status == null) continue;
            if (status == EnumValidationStatus.VS_FAILED) return EnumValidationStatus.VS_FAILED;
            if (status == EnumValidationStatus.VS_SUCCEEDED) anySucceeded = true;
        }
        return anySucceeded ? EnumValidationStatus.VS_SUCCEEDED : EnumValidationStatus.VS_NONE;
    }

    /// MRZ date components may be "XX" or "undefined" rather than a number.
    private static int parseIntOrZero(@Nullable String value) {
        try {
            return Integer.parseInt(value);
        } catch (Exception ignore) {
            return 0;
        }
    }

    /// Raw DCP keys whose validation status is snapshotted at parse time.
    private static final String[] VALIDATED_FIELDS = {
            "line1", "line2", "line3",
            "primaryIdentifier", "secondaryIdentifier",
            "sex", "nationality", "issuingState",
            "dateOfBirth", "birthYear", "birthMonth", "birthDay",
            "dateOfExpiry", "expiryYear", "expiryMonth", "expiryDay",
            "passportNumber", "documentNumber", "longDocumentNumber",
            "personalNumber", "optionalData1", "optionalData2",
    };

    /// A failed check digit is captured per-field, not discarded; the required-field guard still drops non-MRZ frames.
    @Nullable
    static MRZData fromParsedResultItem(@Nullable ParsedResultItem item) {
        if (item == null || item.getParsedFields() == null) return null;
        HashMap<String, String> map = item.getParsedFields();

        String documentNumber = null;
        String documentNumberRawKey = null;
        for (String rawKey : new String[]{"passportNumber", "documentNumber", "longDocumentNumber"}) {
            if (map.get(rawKey) != null) {
                documentNumber = map.get(rawKey);
                documentNumberRawKey = rawKey;
                break;
            }
        }
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

        int birthYear = parseIntOrZero(map.get("birthYear")) + 1900;
        // Age is not in the MRZ but can be calculated from the date of birth.
        Calendar now = Calendar.getInstance();
        int birthNumber = birthYear * 10000
                + parseIntOrZero(map.get("birthMonth")) * 100 + parseIntOrZero(map.get("birthDay"));
        int currentDayNumber = now.get(Calendar.YEAR) * 10000
                + (now.get(Calendar.MONTH) + 1) * 100 + now.get(Calendar.DAY_OF_MONTH);
        int age = (currentDayNumber - birthNumber) / 10000;
        if (age >= 100) {
            age -= 100;
            birthYear += 100;
        }

        String line1 = map.get("line1") == null ? "" : map.get("line1");
        String line2 = map.get("line2") == null ? "" : map.get("line2");
        String line3 = map.get("line3") == null ? "" : map.get("line3");

        MRZData data = new MRZData();
        data.documentType = item.getCodeType();
        data.firstName = map.get("secondaryIdentifier") == null ? "" : map.get("secondaryIdentifier");
        data.lastName = map.get("primaryIdentifier") == null ? "" : map.get("primaryIdentifier");
        data.sex = sex;
        data.issuingState = issuingState;
        data.nationality = nationality;
        data.dateOfBirth = birthYear + "-" + map.get("birthMonth") + "-" + map.get("birthDay");
        // "XX" rather than a number is valid in an MRZ date, so this must not assume it parses.
        String expiryYear = map.get("expiryYear");
        data.dateOfExpire = (isNumeric(expiryYear) ? String.valueOf(Integer.parseInt(expiryYear) + 2000) : "XX")
                + "-" + map.get("expiryMonth") + "-" + map.get("expiryDay");
        data.documentNumber = documentNumber;
        data.age = age;
        data.mrzText = (line1 + "\n" + line2 + "\n" + line3).trim();
        data.issuingStateRaw = issuingStateRaw;
        data.nationalityRaw = nationalityRaw;
        data.optionalData1 = item.getFieldRawValue("optionalData1");
        data.optionalData2 = item.getFieldRawValue("optionalData2");
        data.personalNumber = map.get("personalNumber");
        data.documentNumberRawKey = documentNumberRawKey;

        // Boxing keeps EnumValidationStatus, a DCP-internal type, off this Serializable model.
        data.fieldValidation = new HashMap<>();
        for (String rawField : VALIDATED_FIELDS) {
            data.fieldValidation.put(rawField, item.getFieldValidationStatus(rawField));
        }
        return data;
    }

    private static boolean isNumeric(@Nullable String value) {
        if (value == null || value.isEmpty()) return false;
        for (int i = 0; i < value.length(); i++) {
            if (!Character.isDigit(value.charAt(i))) return false;
        }
        return true;
    }
}
