package io.github.wly5556.s1orangeXSDK26;

import static io.github.wly5556.s1orangeXSDK26.EntryEntryAbilityActivity.PICK_IMAGES_REQUEST_CODE;

import android.app.Activity;
import android.app.UiModeManager;
import android.content.ActivityNotFoundException;
import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.ComponentName;
import android.content.ContentResolver;
import android.content.ContentValues;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.graphics.Color;
import android.media.MediaScannerConnection;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;
import android.provider.Settings;
import android.view.View;
import android.view.Window;
import android.view.WindowInsetsController;
import android.webkit.MimeTypeMap;
import android.widget.Toast;

import androidx.core.content.FileProvider;
import androidx.core.view.WindowCompat;
import androidx.core.view.WindowInsetsCompat;
import androidx.core.view.WindowInsetsControllerCompat;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.ByteArrayOutputStream;
import java.nio.channels.FileChannel;
import java.nio.charset.StandardCharsets;
import java.nio.file.StandardOpenOption;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import ohos.ace.adapter.ALog;
import ohos.ace.adapter.capability.bridge.BridgeManager;
import ohos.ace.adapter.capability.bridge.BridgePlugin;
import ohos.ace.adapter.capability.bridge.IMessageListener;
import ohos.ace.adapter.capability.bridge.IMethodResult;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

public class Bridge extends BridgePlugin implements IMessageListener, IMethodResult {

    private static final long SHARE_FILE_TTL_MS = 24L * 60 * 60 * 1000;
    private static final String SHARE_IMAGE_DIR = "shared_images";
    private static final String S1_HOST = "stage1st.com";
    private static final String S1_FORUM_PATH = "/2b/forum.php";
    private static final String S1_THREAD_PATH_PREFIX = "/2b/thread";
    private static final String PROCESS_TEXT_MIME_TYPE = "text/plain";
    private final Context context;
    private final Map<String, ComponentName> processTextComponents = new HashMap<>();
    private String processTextActionsJson = "[]";
    private static final Handler MAIN_HANDLER = new Handler(Looper.getMainLooper());

    Bridge(Context context, String name, BridgeManager bridgeManager) {
        super(context, name, bridgeManager);
        this.context = context;
        setMethodResultListener(this);
        setMessageListener(this);
        refreshProcessTextActions();
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

    public void openAppOpenByDefaultSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.S) {
            showToast("您的Android版本低于12，无需专门设置即可跳转");
            return;
        }
        try {
            Intent intent = new Intent(Settings.ACTION_APP_OPEN_BY_DEFAULT_SETTINGS);
            intent.setData(Uri.parse("package:" + context.getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        } catch (ActivityNotFoundException e) {
            Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
            intent.setData(Uri.parse("package:" + context.getPackageName()));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        }
    }

    public void openS1Like(String href) {
        callMethod("opens1like", href);
    }

    public void openS1LikeFromIntent(Intent intent) {
        String href = resolveS1LikeFromIntent(intent);
        if (href != null) {
            openS1Like(href);
        }
    }

    private String resolveS1LikeFromIntent(Intent intent) {
        if (intent == null) {
            return null;
        }
        if (!Intent.ACTION_VIEW.equals(intent.getAction())) {
            return null;
        }
        Uri data = intent.getData();
        if (data == null) {
            return null;
        }
        if (!"https".equalsIgnoreCase(data.getScheme()) || !S1_HOST.equalsIgnoreCase(data.getHost())) {
            return null;
        }
        String path = data.getPath();
        if (path == null) {
            return null;
        }
        boolean forumLink = S1_FORUM_PATH.equals(path) && data.getEncodedQuery() != null;
        boolean threadLink = path.startsWith(S1_THREAD_PATH_PREFIX);
        if (forumLink || threadLink) {
            return data.toString();
        }
        return null;
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

    public void refreshProcessTextActions() {
        PackageManager packageManager = context.getPackageManager();
        Intent queryIntent = new Intent(Intent.ACTION_PROCESS_TEXT);
        queryIntent.setType(PROCESS_TEXT_MIME_TYPE);

        List<ResolveInfo> resolveInfos = queryProcessTextActivities(packageManager, queryIntent);
        JSONArray actions = new JSONArray();
        Map<String, ComponentName> components = new HashMap<>();

        for (ResolveInfo resolveInfo : resolveInfos) {
            ActivityInfo activityInfo = resolveInfo.activityInfo;
            if (activityInfo == null ||
                    (!activityInfo.exported && !context.getPackageName().equals(activityInfo.packageName))) {
                continue;
            }
            CharSequence label = resolveInfo.loadLabel(packageManager);
            if (label == null || label.length() == 0) {
                continue;
            }
            String id = activityInfo.packageName + "/" + activityInfo.name;
            ComponentName componentName = new ComponentName(activityInfo.packageName, activityInfo.name);
            try {
                JSONObject action = new JSONObject();
                action.put("id", id);
                action.put("label", label.toString());
                actions.put(action);
                components.put(id, componentName);
            } catch (JSONException e) {
                ALog.w("Bridge", "Failed to pack process text action: " + e.getMessage());
            }
        }

        processTextComponents.clear();
        processTextComponents.putAll(components);
        processTextActionsJson = actions.toString();
    }

    public String getProcessTextActions() {
        return processTextActionsJson;
    }

    public void dispatchProcessTextActions() {
        callMethod("onProcessTextActions", processTextActionsJson);
    }

    public void processSelectedText(String actionId, String text) {
        ComponentName componentName = processTextComponents.get(actionId);
        if (componentName == null) {
            refreshProcessTextActions();
            componentName = processTextComponents.get(actionId);
        }
        if (componentName == null) {
            return;
        }

        Intent intent = new Intent(Intent.ACTION_PROCESS_TEXT);
        intent.setType(PROCESS_TEXT_MIME_TYPE);
        intent.setComponent(componentName);
        intent.putExtra(Intent.EXTRA_PROCESS_TEXT, text);
        intent.putExtra(Intent.EXTRA_PROCESS_TEXT_READONLY, true);
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

        try {
            context.startActivity(intent);
        } catch (ActivityNotFoundException | SecurityException e) {
            showToast("无法处理选中文本");
            ALog.w("Bridge", "Failed to process selected text: " + e.getMessage());
        }
    }

    @SuppressWarnings("deprecation")
    private List<ResolveInfo> queryProcessTextActivities(PackageManager packageManager, Intent queryIntent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            return packageManager.queryIntentActivities(
                    queryIntent,
                    PackageManager.ResolveInfoFlags.of(0)
            );
        }
        return packageManager.queryIntentActivities(queryIntent, 0);
    }

    public void shareImage(String path, String ext) {
        File internalFile = new File(path);
        if (!internalFile.exists()) return;

        File externalCacheDir = context.getExternalCacheDir();
        if (externalCacheDir == null) return;

        File shareDir = new File(externalCacheDir, SHARE_IMAGE_DIR);
        if (!shareDir.exists() && !shareDir.mkdirs()) return;

        cleanupExpiredShareFiles(shareDir);

        String sharedName = ensureExtension(internalFile.getName(), ext);
        File sharedFile = new File(shareDir, sharedName);

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

            shareIntent.setClipData(ClipData.newUri(context.getContentResolver(), "shared_image", contentUri));

            Intent chooser = Intent.createChooser(shareIntent, "分享图片");
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);

            context.startActivity(chooser);

        } catch (IOException e) {
            showToast("分享时出现异常");
        }
    }

    private static String ensureExtension(String filename, String ext) {
        if (ext == null || ext.trim().isEmpty()) {
            return filename;
        }
        String normalized = ext.trim().toLowerCase().replaceFirst("^\\.+", "");
        if (filename.toLowerCase().endsWith("." + normalized)) {
            return filename;
        }
        return filename + '.' + normalized;
    }

    private static void cleanupExpiredShareFiles(File shareDir) {
        File[] shareFiles = shareDir.listFiles();
        if (shareFiles == null) {
            return;
        }
        long now = System.currentTimeMillis();
        for (File shareFile : shareFiles) {
            if (!shareFile.isFile()) {
                continue;
            }
            long age = now - shareFile.lastModified();
            if (age <= SHARE_FILE_TTL_MS) {
                continue;
            }
            if (!shareFile.delete()) {
                ALog.w("Bridge", "Failed to delete expired shared file: " + shareFile.getAbsolutePath());
            }
        }
    }

    public void setWindowSystemBarProperties(boolean isDarkFont) {
        if (!(context instanceof android.app.Activity)) {
            return;
        }
        Window window = ((android.app.Activity) context).getWindow();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            WindowInsetsController controller = window.getInsetsController();
            if (controller != null) {
                controller.setSystemBarsAppearance(
                        isDarkFont ?
                                WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS : 0,
                        WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS
                );
            }
        } else {
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
    }

    public void hideSoftKeyboard() {
        if (!(context instanceof android.app.Activity)) {
            return;
        }
        Activity activity = (Activity) context;
        WindowInsetsControllerCompat controller = WindowCompat.getInsetsController(activity.getWindow(), activity.getWindow().getDecorView());
        controller.hide(WindowInsetsCompat.Type.ime());
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
        MAIN_HANDLER.post(() ->
                Toast.makeText(
                        context.getApplicationContext(),
                        text,
                        Toast.LENGTH_SHORT
                ).show());
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

    public String readTextFromUri(String uriString) {
        try (InputStream inputStream = context.getContentResolver().openInputStream(Uri.parse(uriString));
             ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {
            if (inputStream == null) {
                return "";
            }
            byte[] buffer = new byte[8192];
            int length;
            while ((length = inputStream.read(buffer)) != -1) {
                outputStream.write(buffer, 0, length);
            }
            return outputStream.toString(StandardCharsets.UTF_8.name());
        } catch (Exception e) {
            ALog.w("Bridge", "Failed to read text from uri: " + e.getMessage());
            return "";
        }
    }

    public void setNightMode(Integer mode) {
        // ArkUI-X侧切换到深色模式后调用，使得ArkUI-X框架内侧能把配色（如文字）切换到对应模式
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            MAIN_HANDLER.post(() -> {
                Map<Integer, Integer> modeMap = new HashMap<>();
                modeMap.put(-1, UiModeManager.MODE_NIGHT_AUTO);
                modeMap.put(0, UiModeManager.MODE_NIGHT_YES);
                modeMap.put(1, UiModeManager.MODE_NIGHT_NO);
                if (modeMap.containsKey(mode)) {
                    UiModeManager uim = (UiModeManager) context.getSystemService(Context.UI_MODE_SERVICE);
                    uim.setApplicationNightMode(modeMap.get(mode));
                }
            });
        } else {
            // ArkUI-X的StageActivity继承自Activity，而不是AppCompatActivity，是否有办法
            // 使得AppCompatDelegate.setDefaultNightMode能正常起效？
        }
    }

    private int statusBarInset;
    private int navigationBarInset;
    private int keyboardInset;

    public void setWindowInset(int statusBarInset, int navigationBarInset, int keyboardInset) {
        this.statusBarInset = statusBarInset;
        this.navigationBarInset = navigationBarInset;
        this.keyboardInset = keyboardInset;
    }

    public int[] getWindowInset() {
        return new int[]{statusBarInset, navigationBarInset, keyboardInset};
    }

    public int getSdkInt() {
        return Build.VERSION.SDK_INT;
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
