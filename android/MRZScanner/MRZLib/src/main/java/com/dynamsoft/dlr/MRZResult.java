package com.dynamsoft.dlr;

public class MRZResult {
    public String docId;
    public String docType;
    public String nationality;
    public String issuer;
    public String dateOfBirth;
    public String dateOfExpiration;
    public String gender;
    public String surname;
    public String givenName;
    public boolean isParsed;
    public boolean isVerified;
    public String mrzText;

    @Override
    public String toString() {
        return "MRZResult{" +
                "DocId='" + docId + '\'' +
                ", DocType=" + docType +
                ", Nationality='" + nationality + '\'' +
                ", Issuer='" + issuer + '\'' +
                ", Birth='" + dateOfBirth + '\'' +
                ", Expiration='" + dateOfExpiration + '\'' +
                ", Gender='" + gender + '\'' +
                ", Surname='" + surname + '\'' +
                ", GivenName='" + givenName + '\'' +
                ", IsParsed=" + isParsed +
                ", IsVerified=" + isVerified +
                ", MrzText='" + mrzText + '\'' +
                '}';
    }
}
