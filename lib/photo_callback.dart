library photo_callback;

import 'package:flutter/material.dart';
import 'package:photo/src/delegate/badge_delegate.dart';
import 'package:photo/src/delegate/checkbox_builder_delegate.dart';
import 'package:photo/src/delegate/loading_delegate.dart';
import 'package:photo/src/delegate/sort_delegate.dart';
import 'package:photo/src/entity/options.dart';
import 'package:photo/src/provider/i18n_provider.dart';
import 'package:photo/src/ui/dialog/not_permission_dialog.dart';
import 'package:photo/src/ui/photo_app.dart';
import 'package:photo_manager/photo_manager.dart';

export 'package:photo/src/delegate/badge_delegate.dart';
export 'package:photo/src/delegate/checkbox_builder_delegate.dart';
export 'package:photo/src/delegate/loading_delegate.dart';
export 'package:photo/src/delegate/sort_delegate.dart';
export 'package:photo/src/entity/options.dart' show PickType;
export 'package:photo/src/provider/i18n_provider.dart'
    show I18NCustomProvider, I18nProvider, CNProvider, ENProvider;

class PhotoPickerCallback {
  static PhotoPickerCallback _instance;

  PhotoPickerCallback._();

  factory PhotoPickerCallback() {
    _instance ??= PhotoPickerCallback._();
    return _instance;
  }

  static const String rootRouteName = "photo_picker_image";

  /// 没有授予权限的时候,会开启一个dialog去帮助用户去应用设置页面开启权限
  /// 确定开启设置页面,取消关闭弹窗,无论选择什么,返回值都是null
  ///
  ///
  /// 当用户给予权限后
  ///
  ///   当用户确定时,返回一个图片[AssetEntity]列表
  ///
  ///   当用户取消时返回一个空数组
  ///
  ///   [photoPathList] 一旦设置 则 [pickType]参数无效
  ///
  ///   [pickedAssetList] 已选择的asset
  ///
  /// 关于参数可以查看readme文档介绍
  ///
  /// if user not grand permission, then return null and show a dialog to help user open setting.
  /// sure is open setting cancel ,cancel to dismiss dialog, return null
  ///
  /// when user give permission.
  ///
  ///   when user sure , return a [AssetEntity] of [List]
  ///
  ///   when user cancel selected,result is empty list
  ///
  ///   when [photoPathList] is not null , [pickType] invalid
  ///
  ///   [pickedAssetList]: The results of the last selection can be passed in for easy secondary selection.
  ///
  /// params see readme.md

  static void pickAssetWithCallback(
      {@required BuildContext context,
      int rowCount = 4,
      int maxImageSelected = 9,
      int maxVideoSelected = 2,
      double padding = 0.5,
      double itemRadio = 1.0,
      Color themeColor,
      Color dividerColor,
      Color textColor,
      Color textSubtitleColor,
      Color disableColor,
      Color enabledColor,
      int thumbSize = 64,
      I18nProvider provider = I18nProvider.english,
      SortDelegate sortDelegate,
      bool showManagePhotos = false,
      CheckBoxBuilderDelegate checkBoxBuilderDelegate,
      LoadingDelegate loadingDelegate,
      PickType pickType = PickType.all,
      BadgeDelegate badgeDelegate = const DefaultBadgeDelegate(),
      List<AssetPathEntity> photoPathList,
      List<AssetEntity> pickedAssetList,
      Widget cancelWidget,
      Function onAssetsSelected,
      Widget subtitleWidgetArrow,
      Widget managePhotosWidget,
      Widget downloadingIcloudWidget,
      Function onAssetsVideoLimit,
      Function onAssetsImageLimit,
      Function onExit,
      bool exitOnSelected = false}) {
    assert(provider != null, "provider must be not null");
    assert(context != null, "context must be not null");
    assert(pickType != null, "pickType must be not null");

    themeColor ??= Theme.of(context)?.primaryColor ?? Colors.black;
    dividerColor ??= Theme.of(context)?.dividerColor ?? Colors.grey;
    disableColor ??= Theme.of(context)?.disabledColor ?? Colors.grey;
    textColor ??= Colors.white;

    sortDelegate ??= SortDelegate.common;
    checkBoxBuilderDelegate ??= DefaultCheckBoxBuilderDelegate();

    loadingDelegate ??= DefaultLoadingDelegate();

    var options = Options(
        rowCount: rowCount,
        dividerColor: dividerColor,
        maxVideoSelected: maxVideoSelected,
        maxImageSelected: maxImageSelected,
        itemRadio: itemRadio,
        padding: padding,
        disableColor: disableColor,
        textColor: textColor,
        themeColor: themeColor,
        thumbSize: thumbSize,
        sortDelegate: sortDelegate,
        checkBoxBuilderDelegate: checkBoxBuilderDelegate,
        loadingDelegate: loadingDelegate,
        badgeDelegate: badgeDelegate,
        pickType: pickType,
        cancelWidget: cancelWidget,
        textSubtitleColor: textSubtitleColor,
        subtitleWidgetArrow: subtitleWidgetArrow,
        enabledColor: enabledColor,
        showManagePhotos: showManagePhotos,
        managePhotosWidget: managePhotosWidget,
        downloadingIcloudWidget: downloadingIcloudWidget,
        onExit: onExit);

    PhotoPickerCallback()._pickAsset(
        context,
        options,
        provider,
        photoPathList,
        pickedAssetList,
        onAssetsSelected,
        onAssetsVideoLimit,
        onAssetsImageLimit,
        exitOnSelected);
  }

  void _pickAsset(
      BuildContext context,
      Options options,
      I18nProvider provider,
      List<AssetPathEntity> photoList,
      List<AssetEntity> pickedAssetList,
      Function onAssetsSelected,
      Function onAssetsVideoLimit,
      Function onAssetsImageLimit,
      bool exitOnSelected) async {
    var requestPermission = await PhotoManager.requestPermission();
    if (requestPermission != true) {
      var result = await showDialog(
        context: context,
        builder: (ctx) => NotPermissionDialog(
          provider.getNotPermissionText(options),
        ),
      );
      if (result == true) {
        PhotoManager.openSetting();
      }
      return null;
    }

    return _openGalleryContentPage(
        context,
        options,
        provider,
        photoList,
        pickedAssetList,
        onAssetsSelected,
        onAssetsVideoLimit,
        onAssetsImageLimit,
        exitOnSelected);
  }

  void _openGalleryContentPage(
      BuildContext context,
      Options options,
      I18nProvider provider,
      List<AssetPathEntity> photoList,
      List<AssetEntity> pickedAssetList,
      Function onAssetsSelected,
      Function onAssetsVideoLimit,
      Function onAssetsImageLimit,
      bool exitOnSelected) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (ctx) => PhotoApp(
          options: options,
          provider: provider,
          photoList: photoList,
          pickedAssetList: pickedAssetList,
          onAssetsSelected: onAssetsSelected,
          onAssetsImageLimit: onAssetsImageLimit,
          onAssetsVideoLimit: onAssetsVideoLimit,
          exitOnselected: exitOnSelected,
        ),
      ),
    );
  }
}
