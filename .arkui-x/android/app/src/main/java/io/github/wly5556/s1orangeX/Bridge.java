package io.github.wly5556.s1orangeX;

import static io.github.wly5556.s1orangeX.EntryEntryAbilityActivity.PICK_IMAGES_REQUEST_CODE;

import android.content.ActivityNotFoundException;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.MediaStore;
import android.view.View;
import android.view.Window;
import android.view.inputmethod.InputMethodManager;
import android.webkit.MimeTypeMap;
import android.widget.Toast;

import androidx.core.content.FileProvider;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.channels.FileChannel;
import java.nio.file.Files;
import java.nio.file.StandardOpenOption;

import ohos.ace.adapter.ALog;
import ohos.ace.adapter.capability.bridge.BridgeManager;
import ohos.ace.adapter.capability.bridge.BridgePlugin;
import ohos.ace.adapter.capability.bridge.IMessageListener;
import ohos.ace.adapter.capability.bridge.IMethodResult;

public class Bridge extends BridgePlugin implements IMessageListener, IMethodResult {

    private final Context context;

    Bridge(Context context, String name, BridgeManager bridgeManager) {
        super(context, name, bridgeManager);
        this.context = context;
        setMethodResultListener(this);
        setMessageListener(this);
    }

    public void openInBrowser(String url) {
        try {
            Intent intent = new Intent(Intent.ACTION_VIEW, Uri.parse(url));
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            intent.addCategory(Intent.CATEGORY_BROWSABLE);
            Intent chooserIntent = Intent.createChooser(intent, "打开方式");
            context.startActivity(chooserIntent);
        } catch (Exception e) {
            ALog.w("Failed to open URL: ", e.getMessage());
        }
    }

    public void copyTextToClipboard(String text) {
        ClipboardManager clipboardManager = (ClipboardManager) context.getSystemService(Context.CLIPBOARD_SERVICE);
        if (clipboardManager != null) {
            ClipData clipData = ClipData.newPlainText("text_label", text);
            clipboardManager.setPrimaryClip(clipData);
        }
    }

    public void shareText(String text) {
        Intent sendIntent = new Intent();
        sendIntent.setAction(Intent.ACTION_SEND);
        sendIntent.putExtra(Intent.EXTRA_TEXT, text);
        sendIntent.setType("text/plain");

        Intent shareIntent = Intent.createChooser(sendIntent, null);
        shareIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        try {
            context.startActivity(shareIntent);
        } catch (ActivityNotFoundException e) {
            ALog.w("ShareUtils", "No application can handle sharing");
        }
    }

    public void shareImage(String path, String ext) {
        File internalFile = new File(path);
        if (!internalFile.exists()) {
            return;
        }
        File externalCacheDir = context.getExternalCacheDir();
        if (externalCacheDir == null) {
            return;
        }
        File sharedFile = new File(externalCacheDir, internalFile.getName() + '.' + ext);

        try {
            try (FileChannel source = new FileInputStream(internalFile).getChannel();
                 FileChannel destination = new FileOutputStream(sharedFile).getChannel()) {
                destination.transferFrom(source, 0, source.size());
            }

            String authority = context.getPackageName() + ".fileprovider";
            Uri contentUri = FileProvider.getUriForFile(context, authority, sharedFile);

            Intent shareIntent = new Intent(Intent.ACTION_SEND);
            shareIntent.setType("image/*");
            shareIntent.putExtra(Intent.EXTRA_STREAM, contentUri);

            shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

            context.startActivity(Intent.createChooser(shareIntent, "分享图片"));

        } catch (IOException e) {
            showToast("分享时出现异常");
        }
    }

    public void setWindowSystemBarProperties(boolean isDarkFont) {
        if (!(context instanceof android.app.Activity)) {
            return;
        }
        Window window = ((android.app.Activity) context).getWindow();
        window.setStatusBarColor(Color.TRANSPARENT);
        View decorView = window.getDecorView();
        int flags = decorView.getSystemUiVisibility();
        if (isDarkFont) {
            flags |= View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
        } else {
            flags &= ~View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR;
        }
        decorView.setSystemUiVisibility(flags);
    }

    public void hideSoftKeyboard() {
        if (!(context instanceof android.app.Activity)) {
            return;
        }
        View currentFocus = ((android.app.Activity) context).getCurrentFocus();
        if (currentFocus != null) {
            InputMethodManager imm = (InputMethodManager) context.getSystemService(Context.INPUT_METHOD_SERVICE);
            if (imm != null) {
                imm.hideSoftInputFromWindow(currentFocus.getWindowToken(), 0);
            }
        }

    }

    public void photoViewPicker() {
        if (!(context instanceof android.app.Activity)) {
            return;
        }
        Intent intent = new Intent(Intent.ACTION_GET_CONTENT);
        intent.setType("image/*");
        intent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, true);
        ((android.app.Activity) context).startActivityForResult(intent, PICK_IMAGES_REQUEST_CODE);
    }

    public void showToast(String text) {
        Toast.makeText(context, text, Toast.LENGTH_SHORT).show();
    }

    public void copyToExternalDownload(String path, String filename) {
        File sourceFile = new File(path);
        if (!sourceFile.exists()) {
            return;
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            ContentResolver resolver = context.getContentResolver();
            ContentValues values = new ContentValues();
            values.put(MediaStore.Downloads.DISPLAY_NAME, filename);
            values.put(MediaStore.Downloads.MIME_TYPE, getMimeType(filename));
            values.put(MediaStore.Downloads.RELATIVE_PATH, Environment.DIRECTORY_DOWNLOADS);

            Uri externalUri = MediaStore.Downloads.EXTERNAL_CONTENT_URI;
            Uri fileUri = resolver.insert(externalUri, values);

            if (fileUri == null) {
                return;
            }
            try (FileChannel inChannel = new FileInputStream(sourceFile).getChannel();
                 FileChannel outChannel = ((FileOutputStream) resolver.openOutputStream(fileUri)).getChannel()) {
                inChannel.transferTo(0, inChannel.size(), outChannel);
            } catch (IOException e) {
                e.printStackTrace();
                resolver.delete(fileUri, null, null);
                showToast("保存文件时出现异常");
            }
        } else {
            File downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS);
            if (!downloadsDir.exists() && !downloadsDir.mkdirs()) {
                return;
            }

            File destFile = new File(downloadsDir, filename);
            try (FileChannel inChannel = FileChannel.open(sourceFile.toPath(), StandardOpenOption.READ);
                 FileChannel outChannel = FileChannel.open(destFile.toPath(),
                         StandardOpenOption.CREATE,
                         StandardOpenOption.WRITE,
                         StandardOpenOption.TRUNCATE_EXISTING)) {

                inChannel.transferTo(0, inChannel.size(), outChannel);
                MediaScannerConnection.scanFile(context, new String[]{destFile.getAbsolutePath()}, null, null);
            } catch (IOException e) {
                showToast("保存文件时出现异常");
            }
        }
    }

    public void moveToExternalDownload(String path, String filename) {
        try {
            copyToExternalDownload(path, filename);
            File sourceFile = new File(path);
            if (sourceFile.exists()) {
                sourceFile.delete();
            }
        } catch (Exception ignored) {
        }
    }

    private String getMimeType(String filename) {
        String type = null;
        String extension = MimeTypeMap.getFileExtensionFromUrl(filename);
        if (extension != null) {
            type = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension.toLowerCase());
        }
        if (type == null) {
            type = "application/octet-stream";
        }
        return type;
    }


    @Override
    public Object onMessage(Object o) {
        return true;
    }

    @Override
    public void onMessageResponse(Object o) {

    }

    @Override
    public void onSuccess(Object o) {

    }

    @Override
    public void onError(String s, int i, String s1) {

    }

    @Override
    public void onMethodCancel(String s) {

    }
}