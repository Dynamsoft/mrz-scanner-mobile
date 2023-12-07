package com.dynamsoft.dlr;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

class ParseUtil {
    private static final String ID_TD1_LINE1_REGEX = "[ACI][A-Z<]([A-Z<]{3})([A-Z0-9<]{9})[0-9][A-Z0-9<]{15}";
    private static final String ID_TD1_LINE2_REGEX = "(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([MF<])(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([A-Z<]{3})[A-Z0-9<]{11}[0-9]";
    private static final String ID_TD1_LINE3_REGEX = "([A-Z<]*)";

    private static final String ID_TD2_LINE1_REGEX = "[ACI][A-Z<]([A-Z<]{3})([A-Z<]*)";
    private static final String ID_TD2_LINE2_REGEX = "([A-Z0-9<]{9})[0-9]([A-Z<]{3})(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([MF<])(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9][A-Z0-9<]{7}[0-9]";

    private static final String PASSPORT_LINE1_REGEX = "P[A-Z<]([A-Z<]{3})([A-Z<]*)";
    private static final String PASSPORT_LINE2_REGEX = "([A-Z0-9<]{9})[0-9]([A-Z<]{3})(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([MF<])(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([A-Z0-9<]{14})[0-9<][0-9]";

    private static final String MRVB_LINE1_REGEX = "V[A-Z<]([A-Z<]{3})([A-Z<]*)";
    private static final String MRVB_LINE2_REGEX = "([A-Z0-9<]{9})[0-9]([A-Z<]{3})(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([MF<])(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9][A-Z0-9<]{8}";

    private static final String MRVA_LINE1_REGEX = "V[A-Z<]([A-Z<]{3})([A-Z<]*)";
    private static final String MRVA_LINE2_REGEX = "([A-Z0-9<]{9})[0-9]([A-Z<]{3})(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9]([MF<])(([0-9]{2})(0[0-9]|1[0-2])(0[1-9]|[1-2][0-9]|3[0-1]))[0-9][A-Z0-9<]{16}";
    
    public static MRZResult parseTD1(String[] lineTexts) {
        if (lineTexts == null || lineTexts.length != 3) {
            return null;
        }

        MRZResult mrzResult = new MRZResult();
        if (!lineTexts[0].matches(ID_TD1_LINE1_REGEX) || !lineTexts[1].matches(ID_TD1_LINE2_REGEX) || !lineTexts[2].matches(ID_TD1_LINE3_REGEX)) {
            if (lineTexts[0].matches(ID_TD1_LINE3_REGEX) && lineTexts[1].matches(ID_TD1_LINE2_REGEX) && lineTexts[2].matches(ID_TD1_LINE3_REGEX)) {
                lineTexts = new String[]{lineTexts[2], lineTexts[1], lineTexts[0]};
            } else {
                mrzResult.isParsed = false;
                mrzResult.mrzText = lineTexts[0] + "\n" + lineTexts[1] + "\n" + lineTexts[2];
                return mrzResult;
            }
        }
        mrzResult.mrzText = lineTexts[0] + "\n" + lineTexts[1] + "\n" + lineTexts[2];

        mrzResult.isParsed = true;
        mrzResult.isVerified = true;

        mrzResult.docType = "identity";

        //line1
        Pattern pattern = Pattern.compile(ID_TD1_LINE1_REGEX);
        Matcher matcher = pattern.matcher(lineTexts[0]);
        if (matcher.find()) {
            mrzResult.issuer = matcher.group(1).replace("<","");
            mrzResult.docId = matcher.group(2).replace("<","");
            if (!verifyString( matcher.group(2), lineTexts[0].charAt(14))) {
                mrzResult.isVerified = false;
            }
        } else {
            return null;
        }

        //line2
        pattern = Pattern.compile(ID_TD1_LINE2_REGEX);
        matcher = pattern.matcher(lineTexts[1]);
        if (matcher.find()) {
            mrzResult.dateOfBirth = matcher.group(2) + "-" + matcher.group(3) + "-" + matcher.group(4);
            if (!verifyString(matcher.group(1), lineTexts[1].charAt(6))) {
                //check digital of birth date
                mrzResult.isVerified = false;
            }
            mrzResult.gender = matcher.group(5).replace('<','U');

            mrzResult.dateOfExpiration = matcher.group(7) + "-" + matcher.group(8) + "-" + matcher.group(9);
            if (!verifyString(matcher.group(6), lineTexts[1].charAt(14))) {
                //check digital of expiration date
                mrzResult.isVerified = false;
            }

            mrzResult.nationality = matcher.group(10).replace("<","");

            if (!verifyString(lineTexts[0].substring(5) + lineTexts[1].substring(0, 7) + lineTexts[1].substring(8, 15) + lineTexts[1].substring(18, 29), lineTexts[1].charAt(29))) {
                //check digital of all
                mrzResult.isVerified = false;
            }

        } else {
            return null;
        }

        //line3
        pattern = Pattern.compile(ID_TD1_LINE3_REGEX);
        matcher = pattern.matcher(lineTexts[2]);
        if (matcher.find()) {
            String name = lineTexts[2];
            int sep_pos = name.indexOf("<<");
            if (sep_pos == -1) {
                mrzResult.surname = "";
                mrzResult.givenName = name.replace('<', ' ');
            } else {
                mrzResult.surname = name.substring(0, sep_pos).replace('<', ' ');
                mrzResult.givenName = name.substring(sep_pos + 2).replace('<', ' ');
                if(mrzResult.givenName.trim().isEmpty()) {
                    mrzResult.givenName = mrzResult.surname;
                    mrzResult.surname = "";
                }
            }
        } else {
            return null;
        }
        return mrzResult;
    }

    public static MRZResult parseTD2(String[] lineTexts) {
        if (lineTexts == null || lineTexts.length != 2) {
            return null;
        }

        MRZResult mrzResult = new MRZResult();
        if (!lineTexts[0].matches(ID_TD2_LINE1_REGEX) || !lineTexts[1].matches(ID_TD2_LINE2_REGEX)) {
            if (lineTexts[0].matches(ID_TD2_LINE2_REGEX) && lineTexts[1].matches(ID_TD2_LINE1_REGEX)) {
                lineTexts = new String[]{lineTexts[1], lineTexts[0]};
            } else {
                mrzResult.isParsed = false;
                mrzResult.mrzText = lineTexts[0] + "\n" + lineTexts[1];
                return mrzResult;
            }
        }
        mrzResult.mrzText = lineTexts[0] + "\n" + lineTexts[1] + "\n";

        mrzResult.isParsed = true;
        mrzResult.isVerified = true;
        mrzResult.docType = "identity";

        //line1
        Pattern pattern = Pattern.compile(ID_TD2_LINE1_REGEX);
        Matcher matcher = pattern.matcher(lineTexts[0]);
        if (matcher.find()) {
            mrzResult.issuer = matcher.group(1).replace("<","");

            String name = matcher.group(2);
            int sep_pos = name.indexOf("<<");
            if (sep_pos == -1) {
                mrzResult.surname = "";
                mrzResult.givenName = name.replace('<', ' ');
            }
            else {
                mrzResult.surname = name.substring(0, sep_pos).replace('<', ' ');
                mrzResult.givenName = name.substring(sep_pos + 2).replace('<', ' ');
                if(mrzResult.givenName.trim().isEmpty()) {
                    mrzResult.givenName = mrzResult.surname;
                    mrzResult.surname = "";
                }
            }
        } else {
            return null;
        }

        //line2
        pattern = Pattern.compile(ID_TD2_LINE2_REGEX);
        matcher = pattern.matcher(lineTexts[1]);
        if (matcher.find()) {
            mrzResult.docId = matcher.group(1).replace("<","");
            if (!verifyString(matcher.group(1), lineTexts[1].charAt(9))) {
                //check digital of document number
                mrzResult.isVerified = false;
            }
            mrzResult.nationality = matcher.group(2).replace("<","");

            mrzResult.dateOfBirth = matcher.group(4) + "-" + matcher.group(5) + "-" + matcher.group(6);
            if (!verifyString(matcher.group(3), lineTexts[1].charAt(19))) {
                //check digital of birth date
                mrzResult.isVerified = false;
            }
            mrzResult.gender = matcher.group(7).replace('<','U');

            mrzResult.dateOfExpiration = matcher.group(9) + "-" + matcher.group(10) + "-" + matcher.group(11);
            if (!verifyString(matcher.group(8), lineTexts[1].charAt(27))) {
                //check digital of expiration date
                mrzResult.isVerified = false;
            }

            if (!verifyString(lineTexts[1].substring(0, 10) + lineTexts[1].substring(13, 20) + lineTexts[1].substring(21, 35), lineTexts[1].charAt(35))) {
                //check digital of all
                mrzResult.isVerified = false;
            }

        } else {
            return null;
        }
        return mrzResult;
    }

    public static MRZResult parseTD3(String[] lineTexts) {
        if (lineTexts == null || lineTexts.length != 2) {
            return null;
        }

        MRZResult mrzResult = new MRZResult();
        if (!lineTexts[0].matches(PASSPORT_LINE1_REGEX) || !lineTexts[1].matches(PASSPORT_LINE2_REGEX)) {
            if (lineTexts[0].matches(PASSPORT_LINE2_REGEX) && lineTexts[1].matches(PASSPORT_LINE1_REGEX)) {
                lineTexts = new String[]{lineTexts[1], lineTexts[0]};
            } else {
                mrzResult.isParsed = false;
                mrzResult.mrzText = lineTexts[0] + "\n" + lineTexts[1];
                return mrzResult;
            }
        }
        mrzResult.mrzText = lineTexts[0] + "\n" + lineTexts[1] + "\n";


        mrzResult.isParsed = true;
        mrzResult.isVerified = true;
        mrzResult.docType = "passport";

        //line1
        Pattern pattern = Pattern.compile(PASSPORT_LINE1_REGEX);
        Matcher matcher = pattern.matcher(lineTexts[0]);
        if (matcher.find()) {
            mrzResult.issuer = matcher.group(1).replace("<","");
            
            String name = matcher.group(2);
            int sep_pos = name.indexOf("<<");
            if (sep_pos == -1) {
                mrzResult.surname = "";
                mrzResult.givenName = name.replace('<', ' ');
            }
            else {
                mrzResult.surname = name.substring(0, sep_pos).replace('<', ' ');
                mrzResult.givenName = name.substring(sep_pos + 2).replace('<', ' ');
                if(mrzResult.givenName.trim().isEmpty()) {
                    mrzResult.givenName = mrzResult.surname;
                    mrzResult.surname = "";
                }
            }
        } else {
            return null;
        }

        //line2
        pattern = Pattern.compile(PASSPORT_LINE2_REGEX);
        matcher = pattern.matcher(lineTexts[1]);
        if (matcher.find()) {
            mrzResult.docId = matcher.group(1).replace("<","");
            if (!verifyString(matcher.group(1), lineTexts[1].charAt(9))) {
                //check digital of document number
                mrzResult.isVerified = false;
            }
            mrzResult.nationality = matcher.group(2).replace("<","");

            mrzResult.dateOfBirth = matcher.group(4) + "-" + matcher.group(5) + "-" + matcher.group(6);
            if (!verifyString(matcher.group(3), lineTexts[1].charAt(19))) {
                //check digital of birth date
                mrzResult.isVerified = false;
            }
            mrzResult.gender = matcher.group(7).replace('<','U');

            mrzResult.dateOfExpiration = matcher.group(9) + "-" + matcher.group(10) + "-" + matcher.group(11);
            if (!verifyString(matcher.group(8), lineTexts[1].charAt(27))) {
                //check digital of expiration date
                mrzResult.isVerified = false;
            }

            if (!verifyString(matcher.group(12), lineTexts[1].charAt(42))
                    || !verifyString(lineTexts[1].substring(0, 10) + lineTexts[1].substring(13, 20) + lineTexts[1].substring(21, 43), lineTexts[1].charAt(43))) {
                //check digital of optional data and all
                mrzResult.isVerified = false;
            }

        } else {
            return null;
        }
        return mrzResult;
    }

    public static MRZResult parseMRVA(String[] lineTexts) {
        if (lineTexts == null || lineTexts.length != 2) {
            return null;
        }

        MRZResult mrzResult = new MRZResult();
        if (!lineTexts[0].matches(MRVA_LINE1_REGEX) || !lineTexts[1].matches(MRVA_LINE2_REGEX)) {
            if (lineTexts[0].matches(MRVA_LINE2_REGEX) && lineTexts[1].matches(MRVA_LINE1_REGEX)) {
                lineTexts = new String[]{lineTexts[1], lineTexts[0]};
            } else {
                mrzResult.isParsed = false;
                mrzResult.mrzText = lineTexts[0] + "\n" + lineTexts[1];
                return mrzResult;
            }
        }
        mrzResult.mrzText = lineTexts[0] + "\n" + lineTexts[1] + "\n";


        mrzResult.isParsed = true;
        mrzResult.isVerified = true;
        mrzResult.docType = "visa-a";

        //line1
        Pattern pattern = Pattern.compile(MRVA_LINE1_REGEX);
        Matcher matcher = pattern.matcher(lineTexts[0]);
        if (matcher.find()) {
            mrzResult.issuer = matcher.group(1).replace("<","");

            String name = matcher.group(2);
            int sep_pos = name.indexOf("<<");
            if (sep_pos == -1) {
                mrzResult.surname = "";
                mrzResult.givenName = name.replace('<', ' ');
            }
            else {
                mrzResult.surname = name.substring(0, sep_pos).replace('<', ' ');
                mrzResult.givenName = name.substring(sep_pos + 2).replace('<', ' ');
            }

        } else {
            return null;
        }

        //line2
        pattern = Pattern.compile(MRVA_LINE2_REGEX);
        matcher = pattern.matcher(lineTexts[1]);
        if (matcher.find()) {
            mrzResult.docId = matcher.group(1).replace("<","");
            if (!verifyString(matcher.group(1), lineTexts[1].charAt(9))) {
                //check digital of document number
                mrzResult.isVerified = false;
            }
            mrzResult.nationality = matcher.group(2).replace("<","");

            mrzResult.dateOfBirth = matcher.group(4) + "-" + matcher.group(5) + "-" + matcher.group(6);
            if (!verifyString(matcher.group(3), lineTexts[1].charAt(19))) {
                //check digital of birth date
                mrzResult.isVerified = false;
            }
            mrzResult.gender = matcher.group(7).replace('<','U');

            mrzResult.dateOfExpiration = matcher.group(9) + "-" + matcher.group(10) + "-" + matcher.group(11);
            if (!verifyString(matcher.group(8), lineTexts[1].charAt(27))) {
                //check digital of expiration date
                mrzResult.isVerified = false;
            }

        } else {
            return null;
        }
        return mrzResult;
    }

    public static MRZResult parseMRVB(String[] lineTexts) {
        if (lineTexts == null || lineTexts.length != 2) {
            return null;
        }

        MRZResult mrzResult = new MRZResult();
        if (!lineTexts[0].matches(MRVB_LINE1_REGEX) || !lineTexts[1].matches(MRVB_LINE2_REGEX)) {
            if (lineTexts[0].matches(MRVB_LINE2_REGEX) && lineTexts[1].matches(MRVB_LINE1_REGEX)) {
                lineTexts = new String[]{lineTexts[1], lineTexts[0]};
            } else {
                mrzResult.isParsed = false;
                mrzResult.mrzText = lineTexts[0] + "\n" + lineTexts[1];
                return mrzResult;
            }
        }
        mrzResult.mrzText = lineTexts[0] + "\n" + lineTexts[1] + "\n";

        mrzResult.isParsed = true;
        mrzResult.isVerified = true;
        mrzResult.docType = "visa-b";

        //line1
        Pattern pattern = Pattern.compile(MRVB_LINE1_REGEX);
        Matcher matcher = pattern.matcher(lineTexts[0]);
        if (matcher.find()) {
            mrzResult.issuer = matcher.group(1).replace("<","");

            String name = matcher.group(2);
            int sep_pos = name.indexOf("<<");
            if (sep_pos == -1) {
                mrzResult.surname = "";
                mrzResult.givenName = name.replace('<', ' ');
            }
            else {
                mrzResult.surname = name.substring(0, sep_pos).replace('<', ' ');
                mrzResult.givenName = name.substring(sep_pos + 2).replace('<', ' ');
            }
        } else {
            return null;
        }

        //line2
        pattern = Pattern.compile(MRVB_LINE2_REGEX);
        matcher = pattern.matcher(lineTexts[1]);
        if (matcher.find()) {
            mrzResult.docId = matcher.group(1).replace("<","");
            if (!verifyString(matcher.group(1), lineTexts[1].charAt(9))) {
                //check digital of document number
                mrzResult.isVerified = false;
            }
            mrzResult.nationality = matcher.group(2).replace("<","");

            mrzResult.dateOfBirth = matcher.group(4) + "-" + matcher.group(5) + "-" + matcher.group(6);
            if (!verifyString(matcher.group(3), lineTexts[1].charAt(19))) {
                //check digital of birth date
                mrzResult.isVerified = false;
            }
            mrzResult.gender = matcher.group(7).replace('<','U');

            mrzResult.dateOfExpiration = matcher.group(9) + "-" + matcher.group(10) + "-" + matcher.group(11);
            if (!verifyString(matcher.group(8), lineTexts[1].charAt(27))) {
                //check digital of expiration date
                mrzResult.isVerified = false;
            }
        } else {
            return null;
        }
        return mrzResult;
    }

    private static boolean verifyString(String s, char c) {
        if (c=='<' || (c >= '0' && c <= '9')) {
            if(c=='<') {
                return compute(s) == 0;
            } else {
                return compute(s) == Integer.parseInt(String.valueOf(c));
            }
        } else {
            return false;
        }
    }

    private static int compute(String source) {
        String s = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";
        int[] w = new int[]{7, 3, 1};
        int c = 0;
        for (int i = 0; i < source.length(); i++) {
            if (source.charAt(i) == '<')
                continue;
            c += s.indexOf(source.charAt(i)) * w[i % 3];
        }
        c %= 10;
        return c;
    }
}
