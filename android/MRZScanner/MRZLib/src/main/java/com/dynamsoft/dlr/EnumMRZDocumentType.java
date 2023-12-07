package com.dynamsoft.dlr;

public enum EnumMRZDocumentType {
    MDT_ALL(0),
    MDT_PASSPORT(1),
    MDT_ID_CARD(2),
    MDT_VISA(3);

    //Default is auto.
    public final static EnumMRZDocumentType DEFALUT = MDT_ALL;

    private int value;

    EnumMRZDocumentType(int value) {
        this.value = value;
    }

    public static EnumMRZDocumentType fromValue(int value) {
        EnumMRZDocumentType[] types = EnumMRZDocumentType.values();
        for (EnumMRZDocumentType type : types) {
            if (type.value == value) {
                return type;
            }
        }
        return null;
    }
}
