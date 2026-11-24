package com.example.multi_watch_app.utils;

import android.content.Context;
import android.content.Intent;
import android.util.Log;
import android.widget.Toast;
import android.app.Activity;

import com.veepoo.protocol.VPOperateManager;
import com.veepoo.protocol.listener.base.IBleWriteResponse;

import com.veepoo.protocol.model.datas.BatteryData;
import com.veepoo.protocol.model.datas.PwdData;
import com.veepoo.protocol.model.datas.FunctionDeviceSupportData;
import com.veepoo.protocol.model.datas.FunctionSocailMsgData;

import com.veepoo.protocol.listener.data.IDeviceFuctionDataListener;
import com.veepoo.protocol.listener.data.ISocialMsgDataListener;
import com.veepoo.protocol.listener.data.ICustomSettingDataListener;
import com.veepoo.protocol.listener.data.IPwdDataListener;
import com.veepoo.protocol.listener.data.IBatteryDataListener;

import android.os.Handler;
import android.os.Looper;

public class OperatorHelper {
    private static final String TAG = "OperatorHelper";
    // 🔒 Add this line
    private static boolean verificationHandled = false;
    // ✅ Simple WriteResponse
    private static final IBleWriteResponse writeResponse = code ->
            Log.d(TAG, "Write response code: " + code);

    /**
     * Initialize device, confirm password, read battery, then go to FlutterEcgActivity
     */
    public static void startVerificationAndSync(Context context, String mac) {
        verificationHandled = false; // 🔄 reset for new connection
        VPOperateManager.getInstance().init(context);
        VPOperateManager.getInstance().setAutoConnectBTBySdk(false);

        VPOperateManager.getInstance().confirmDevicePwd(
                writeResponse,
                new IPwdDataListener() {
                    @Override
                    public void onPwdDataChange(PwdData pwdData) {
                        Log.d(TAG, "PwdData: " + pwdData.toString());
                        // 🔒 Prevent duplicate handling
                        if (verificationHandled) {
                            Log.d(TAG, "Verification already handled, ignoring duplicate callback");
                            return;
                        }
                        verificationHandled = true;

                        // ✅ Wait a bit before launching Flutter
                        Handler mainHandler = new Handler(Looper.getMainLooper());
                        mainHandler.postDelayed(() -> {
//                            Log.i(TAG, "Launching FlutterEcgMultiLeadActivity for: " + mac);
                            Toast.makeText(context, "Connected to successfully ", Toast.LENGTH_SHORT).show();
                            /*Intent intent = new Intent(context, Hello.class);
                            context.startActivity(intent);*/
                            /*Intent intent = new Intent(context, FlutterEcgMultiLeadActivity.class);
                            intent.putExtra("route", "/ecg");
                            intent.putExtra("deviceaddress", mac);
                            // 🔥 Clear previous Flutter stack
//                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

                            context.startActivity(intent);
                            // 🔥 THIS IS THE IMPORTANT LINE
                            if (context instanceof Activity) {
                                ((Activity) context).finish();
                            }*/
                        }, 1200); // Delay launch by ~1.2s
                    }
                },
                new IDeviceFuctionDataListener() {
                    @Override
                    public void onFunctionSupportDataChange(FunctionDeviceSupportData data) {
                        Log.d(TAG, "Function support: " + data.toString());
                    }
                },
                new ISocialMsgDataListener() {
                    @Override
                    public void onSocialMsgSupportDataChange(FunctionSocailMsgData data) {
                        Log.d(TAG, "SocialMsgData1: " + data.toString());
                    }

                    @Override
                    public void onSocialMsgSupportDataChange2(FunctionSocailMsgData data) {
                        Log.d(TAG, "SocialMsgData2: " + data.toString());
                    }
                },
                "0000",
                true
        );
    }
}

