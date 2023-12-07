package com.dynamsoft.dlrsample.mrzscanner.ui.main;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.lifecycle.ViewModelProvider;

import androidx.fragment.app.Fragment;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.dynamsoft.dlr.MRZResult;
import com.dynamsoft.dlrsample.mrzscanner.R;


public class ResultFragment extends Fragment {
    private static final String TAG = "ResultFragment";
    private MainViewModel mViewModel;
    private RecyclerView resultsRecyclerView;
    private final String[] mrzResultStrings = new String[12];

    public static ResultFragment newInstance() {
        return new ResultFragment();
    }

    @Nullable
    @Override
    public View onCreateView(@NonNull LayoutInflater inflater,
                             @Nullable ViewGroup container,
                             @Nullable Bundle savedInstanceState) {
        mViewModel = new ViewModelProvider(requireActivity()).get(MainViewModel.class);
        mViewModel.currentFragmentFlag.setValue(MainViewModel.RESULT_FRAGMENT);
        return inflater.inflate(R.layout.result_fragment, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        resultsRecyclerView = view.findViewById(R.id.rv_results_list);
        resultsRecyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

        MRZResult mrzResult = mViewModel.mrzResult;
        mrzResultStrings[0] = "Document Type : __" + mrzResult.docType;
        mrzResultStrings[1] = "Issuing State : __" + mrzResult.issuer;
        mrzResultStrings[2] = "Surname : __" + mrzResult.surname;
        mrzResultStrings[3] = "Given Name : __" + mrzResult.givenName;
        mrzResultStrings[4] = "Passport Number : __" + mrzResult.docId;
        mrzResultStrings[5] = "Nationality : __" + mrzResult.nationality;
        mrzResultStrings[6] = "Date of Birth(YY-MM-DD) : __" + mrzResult.dateOfBirth;
        mrzResultStrings[7] = "Gender : __" + mrzResult.gender;
        mrzResultStrings[8] = "Date of Expiry(YY-MM-DD) : __" + mrzResult.dateOfExpiration;
        mrzResultStrings[9] = "Is Parsed : __" + mrzResult.isParsed;
        mrzResultStrings[10] = "Is Verified : __" + mrzResult.isVerified;
        mrzResultStrings[11] = "MRZ Text : __" + mrzResult.mrzText;

        ResultAdapter resultAdapter = new ResultAdapter(mrzResultStrings);
        resultsRecyclerView.setAdapter(resultAdapter);
        resultAdapter.notifyDataSetChanged();
    }
}
