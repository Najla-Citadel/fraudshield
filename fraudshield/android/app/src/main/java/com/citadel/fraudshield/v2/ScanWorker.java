package com.citadel.fraudshield.v2;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.work.Worker;
import androidx.work.WorkerParameters;

import java.util.List;
import java.util.Map;

/**
 * ScanWorker performs periodic background scans.
 * Converted from Kotlin CoroutineWorker to Java Worker to bypass K2 compiler bug.
 */
public class ScanWorker extends Worker {

    public ScanWorker(@NonNull Context appContext, @NonNull WorkerParameters workerParams) {
        super(appContext, workerParams);
    }

    @NonNull
    @Override
    public Result doWork() {
        Log.d("ScanWorker", "Starting periodic background scan");

        try {
            Map<String, Object> results = ScannerEngine.performFullScan(getApplicationContext());
            Object riskyApps = results.get("riskyApps");
            int riskyCount = 0;
            if (riskyApps instanceof List) {
                riskyCount = ((List<?>) riskyApps).size();
            }
            Log.d("ScanWorker", "Background scan completed. Found " + riskyCount + " risky apps.");
            return Result.success();
        } catch (Exception e) {
            Log.e("ScanWorker", "Background scan failed", e);
            return Result.retry();
        }
    }
}
