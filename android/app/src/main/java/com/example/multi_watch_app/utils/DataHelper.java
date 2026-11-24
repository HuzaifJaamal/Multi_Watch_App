package com.example.multi_watch_app.utils;

import android.app.Activity;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import com.veepoo.protocol.VPOperateManager;
import com.veepoo.protocol.listener.base.IBleWriteResponse;
import com.veepoo.protocol.multi_lead.data.EcgMultiLeadDetectResult;
import com.veepoo.protocol.multi_lead.data.EcgMultiLeadDetectState;
import com.veepoo.protocol.multi_lead.data.EcgMultiLeadPreInfo;
import com.veepoo.protocol.multi_lead.enums.ELeadFlag;
import com.veepoo.protocol.multi_lead.listener.IECGMultiLeadDetectListener;
import com.veepoo.protocol.listener.data.IHeartDataListener;
import com.veepoo.protocol.model.datas.HeartData;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import io.flutter.plugin.common.EventChannel;

public class DataHelper {

    private static final String TAG = "DataHelper";

    private final Activity activity;
    private EventChannel.EventSink ecgEventSink;
    private final ExecutorService ecgExecutor = Executors.newSingleThreadExecutor();


    public DataHelper(Activity activity) {
        this.activity = activity;
    }

    /* ---------------- EventSink ---------------- */

    public void setEcgEventSink(EventChannel.EventSink sink) {
        this.ecgEventSink = sink;
    }

    /* ---------------- WriteResponse ---------------- */

    public static class WriteResponse implements IBleWriteResponse {
        @Override
        public void onResponse(int code) {
            Log.d(TAG, "Write response: " + code);
        }
    }

    private final IBleWriteResponse writeResponse = new WriteResponse();

    /* ---------------- Start ECG ---------------- */

    public void startEcgDetection() {

        VPOperateManager.getInstance()
                .startMultiLeadDetectECG(writeResponse, true,
                        new IECGMultiLeadDetectListener() {

                            @Override
                            public void onEcgDetectSuccess() {
                                Log.d(TAG, "ECG detect success");
                            }

                            @Override
                            public void onEcgDetectPreInfoChange(EcgMultiLeadPreInfo info) {
                                Log.d(TAG, "PreInfo: " + info);
                            }

                            @Override
                            public void onEcgDetectStateChange(EcgMultiLeadDetectState state) {
                                sendStateToFlutter(state);
                                Log.d(TAG, "State: " + state);
                            }

                            @Override
                            public void onDiseaseDiagnosisResults(EcgMultiLeadDetectResult result) {
                                Log.d(TAG, "Result: " + result);
                            }

                            @Override
                            public void onEcgDetectFail() {
                                Log.e(TAG, "ECG detect failed");
                            }

                            @Override
                            public void onEcgADCChange(
                                    ELeadFlag leadFlag,
                                    int[] data,
                                    int gain,
                                    int packNum
                            ) {
                                sendEcgData(leadFlag, data);
                            }
                        });
    }

    /* ---------------- Start Heart Rate ---------------- */

    public void startHeartDetection() {

        VPOperateManager.getInstance()
                .startDetectHeart(
                        writeResponse,
                        new IHeartDataListener() {

                            @Override
                            public void onDataChange(HeartData heart) {

                                Log.d(TAG, "Heart: " + heart.toString());

                                sendHeartData(heart);

                            }
                        });

    }

    /* ---------------- Send Data ---------------- */

    private void sendStateToFlutter(EcgMultiLeadDetectState state) {
        if (ecgEventSink == null) return;

        Map<String, Object> map = new HashMap<>();
        map.put("type", "state");
        map.put("leadFlag", state.getLeadFlag());
        map.put("leadI", state.getLeadI());
        map.put("progress", state.getProgress());
        map.put("heart", state.getHeart());
        map.put("hrv", state.getHrv());
        map.put("qt", state.getQt());

        new Handler(Looper.getMainLooper()).post(() -> {
            try {
                ecgEventSink.success(map);
            } catch (Exception e) {
                Log.e(TAG, "State send error", e);
            }
        });
    }

    private void sendEcgData(ELeadFlag leadFlag, int[] data) {
        if (ecgEventSink == null) return;

        ecgExecutor.execute(() -> {
            List<Integer> list = new ArrayList<>(data.length);
            for (int v : data) list.add(v);

            Map<String, Object> map = new HashMap<>();
            map.put("lead", leadFlag.toString());
            map.put("data", list);

            new Handler(Looper.getMainLooper()).post(() -> {
                try {
                    ecgEventSink.success(map);
                } catch (Exception e) {
                    Log.e(TAG, "ECG stream error", e);
                }
            });
        });
    }

    private void sendHeartData(HeartData heart) {

        if (ecgEventSink == null) return;


        Map<String, Object> map = new HashMap<>();

        map.put("type", "heart");

        // Heart rate value
        map.put("heartRate", heart.getData());

        // Status
        map.put("heartStatus",
                heart.getHeartStatus() != null
                        ? heart.getHeartStatus().toString()
                        : "unknown"
        );


        new Handler(Looper.getMainLooper()).post(() -> {

            try {

                ecgEventSink.success(map);

            } catch (Exception e) {

                Log.e(TAG, "Heart send error", e);

            }

        });
    }

    /* ---------------- Stop / Dispose ---------------- */

    public void stopEcg() {
        VPOperateManager.getInstance().stopMultiLeadDetectECG(writeResponse);
    }

    public void dispose() {
        ecgEventSink = null;
        ecgExecutor.shutdownNow();
    }
}
