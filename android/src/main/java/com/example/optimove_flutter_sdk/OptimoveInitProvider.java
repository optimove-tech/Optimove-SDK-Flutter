package com.example.optimove_flutter_sdk;

import android.app.Application;
import android.content.ContentProvider;
import android.content.ContentValues;
import android.content.res.AssetManager;
import android.database.Cursor;
import android.net.Uri;
import android.util.JsonReader;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.optimove.android.Optimove;
import com.optimove.android.OptimoveConfig;

import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.UnsupportedEncodingException;
import java.util.jar.Attributes;

import io.flutter.plugin.common.PluginRegistry;

public class OptimoveInitProvider extends ContentProvider {
    private static final String TAG = OptimoveInitProvider.class.getName();
    private static final String OPTIMOVE_CREDENTIALS = "optimoveCredentials";
    private static final String OPTIMOBILE_CREDENTIALS = "optimobileCredentials";
    @Override
    public boolean onCreate() {
        OptimoveConfig.Builder  config;
        try{
            config = readConfig();
        }catch (IOException e){
            e.printStackTrace();
            return true;
        }
        if (config==null){
            Log.i(TAG, "Skipping init, no config file found...");
            return true;
        }
        Application application = (Application) getContext().getApplicationContext();
        Optimove.initialize(application,config.build());

        return false;
    }

    @Nullable
    @Override
    public Cursor query(@NonNull Uri uri, @Nullable String[] strings, @Nullable String s, @Nullable String[] strings1, @Nullable String s1) {
        return null;
    }

    @Nullable
    @Override
    public String getType(@NonNull Uri uri) {
        return null;
    }

    @Nullable
    @Override
    public Uri insert(@NonNull Uri uri, @Nullable ContentValues contentValues) {
        return null;
    }

    @Override
    public int delete(@NonNull Uri uri, @Nullable String s, @Nullable String[] strings) {
        return 0;
    }

    @Override
    public int update(@NonNull Uri uri, @Nullable ContentValues contentValues, @Nullable String s, @Nullable String[] strings) {
        return 0;
    }
    private JsonReader getConfigReader(){
        String path ="flutter_assets"+ File.separator + "optimove.json";
        AssetManager assetManager = getContext().getAssets();
        InputStream is = null;
        try {
            is = assetManager.open(path);
        } catch (IOException e) {
            e.printStackTrace();
            return null;
        }
        JsonReader reader = null;
        try {
            reader = new JsonReader(new InputStreamReader(is, "UTF-8"));

        } catch (UnsupportedEncodingException e) {
            e.printStackTrace();
            return null;
        }
        return reader;

    }
    private OptimoveConfig.Builder readConfig() throws IOException {
        String optimoveCredentials = null;
        String optimobileCredentilas = null;
        JsonReader reader = getConfigReader();
        try {
            reader.beginObject();
            while (reader.hasNext()){
                String key = reader.nextName();
                if(key.equals(OPTIMOVE_CREDENTIALS)){
                    optimoveCredentials = reader.nextString();
                }else if(key.equals(OPTIMOBILE_CREDENTIALS)){
                    optimobileCredentilas = reader.nextString();
                }else {
                    reader.skipValue();
                }
            }
            reader.endObject();
        }catch(IOException e){
            e.printStackTrace();
            return null;
        } finally {
            reader.close();
        }

      return new OptimoveConfig.Builder(optimoveCredentials,optimobileCredentilas);
    }
}

