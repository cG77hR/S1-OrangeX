package io.github.wly5556.s1orangeX;

import android.app.Activity;
import android.content.ClipData;
import android.content.Context;
import android.content.Intent;
import android.content.res.Configuration;
import android.net.Uri;
import android.os.Bundle;
import android.view.View;
import android.webkit.MimeTypeMap;
import android.widget.Toast;
import android.util.Log;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.lang.reflect.Field;
import java.util.ArrayList;

import ohos.stage.ability.adapter.StageActivity;


/**
 * Example ace activity class, which will load ArkUI-X ability instance.
 * StageActivity is provided by ArkUI-X
 *
 * @see <a href=
 * "https://gitee.com/arkui-x/docs/blob/master/zh-cn/application-dev/tutorial/how-to-integrate-arkui-into-android.md">
 * to build android library</a>
 */
public class EntryEntryAbilityActivity extends StageActivity {

    private Bridge bridgeInstance = null;

    private Bridge getBridgeInstance() {
        if (bridgeInstance == null) {
            bridgeInstance = new Bridge(this, "Bridge", getBridgeManager());
        }
        return bridgeInstance;
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        super.onConfigurationChanged(newConfig);
        int currentNightMode = newConfig.uiMode & Configuration.UI_MODE_NIGHT_MASK;
        getBridgeInstance().callMethod("onUiModeChanged", currentNightMode == Configuration.UI_MODE_NIGHT_YES);
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        View rootView = findViewById(android.R.id.content);
        rootView.setOnApplyWindowInsetsListener((v, insets) -> {
            int statusBarInset = insets.getSystemWindowInsetTop();
            int navigationBarInset = insets.getSystemWindowInsetBottom();
            getBridgeInstance().callMethod("onWindowInsetsListener", statusBarInset, navigationBarInset);
            return insets;
        });
        setInstanceName("io.github.wly5556.s1orangeX:entry:EntryAbility:");
        super.onCreate(savedInstanceState);
    }

    public static final int PICK_IMAGES_REQUEST_CODE = 1001;

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == PICK_IMAGES_REQUEST_CODE && resultCode == RESULT_OK) {
            if (data != null) {
                ArrayList<Uri> selectedImageUris = new ArrayList<>();
                ClipData clipData = data.getClipData();
                if (clipData != null) {
                    int count = clipData.getItemCount();
                    for (int i = 0; i < count; i++) {
                        selectedImageUris.add(clipData.getItemAt(i).getUri());
                    }
                } else if (data.getData() != null) {
                    selectedImageUris.add(data.getData());
                }
                new Thread(() -> {
                    final ArrayList<String> cachedPaths = new ArrayList<>();

                    for (Uri uri : selectedImageUris) {
                        InputStream inputStream = null;
                        FileOutputStream outputStream = null;
                        try {
                            inputStream = getContentResolver().openInputStream(uri);
                            if (inputStream == null) continue;
                            File tempFile = File.createTempFile("temp_image",
                                    '.' + MimeTypeMap.getSingleton().getExtensionFromMimeType(
                                            getContentResolver().getType(uri)
                                    ), getCacheDir());
                            tempFile.deleteOnExit();
                            outputStream = new FileOutputStream(tempFile);
                            byte[] buffer = new byte[4096];
                            int bytesRead;
                            while ((bytesRead = inputStream.read(buffer)) != -1) {
                                outputStream.write(buffer, 0, bytesRead);
                            }
                            cachedPaths.add(tempFile.getAbsolutePath());
                        } catch (IOException e) {
                            e.printStackTrace();
                        } finally {
                            try {
                                if (inputStream != null) inputStream.close();
                                if (outputStream != null) outputStream.close();
                            } catch (IOException e) {
                                e.printStackTrace();
                            }
                        }
                    }
                    runOnUiThread(() -> {
                        getBridgeInstance().callMethod("onPhotoPickerResult", cachedPaths.toArray());
                    });
                }).start();
            }
        }
    }
}
