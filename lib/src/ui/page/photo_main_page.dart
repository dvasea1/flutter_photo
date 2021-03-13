import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo/src/delegate/badge_delegate.dart';
import 'package:photo/src/delegate/loading_delegate.dart';
import 'package:photo/src/engine/lru_cache.dart';
import 'package:photo/src/engine/throttle.dart';
import 'package:photo/src/entity/options.dart';
import 'package:photo/src/provider/asset_provider.dart';
import 'package:photo/src/provider/config_provider.dart';
import 'package:photo/src/provider/gallery_list_provider.dart';
import 'package:photo/src/provider/i18n_provider.dart';
import 'package:photo/src/provider/selected_provider.dart';
import 'package:photo/src/ui/dialog/change_gallery_dialog.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../photo_callback.dart';

part './main/bottom_widget.dart';

part './main/image_item.dart';

class PhotoMainPage extends StatefulWidget {
  final ValueChanged<List<AssetEntity>> onClose;
  final Options options;
  final List<AssetPathEntity> photoList;
  final VoidCallback onExit;
  final VoidCallback onLimitVideo;
  final VoidCallback onLimitImages;
  final Function onInstanceEvents;

  const PhotoMainPage(
      {Key key,
      this.onClose,
      this.options,
      this.photoList,
      this.onExit,
      this.onLimitVideo,
      this.onLimitImages,
      this.onInstanceEvents})
      : super(key: key);

  @override
  _PhotoMainPageState createState() => _PhotoMainPageState();
}

class _PhotoMainPageState extends State<PhotoMainPage>
    with SelectedProvider, GalleryListProvider, PhotoPickerCallbackEvents {
  Options get options => widget.options;

  I18nProvider get i18nProvider => PhotoPickerProvider.of(context).provider;

  AssetProvider get assetProvider =>
      PhotoPickerProvider.of(context).assetProvider;

  List<AssetEntity> get list => assetProvider.data;

  Color get themeColor => options.themeColor;

  AssetPathEntity _currentPath = AssetPathEntity();

  bool _isInit = false;
  bool _GalleryListShown = false;

  AssetPathEntity get currentPath {
    if (_currentPath == null) {
      return null;
    }
    return _currentPath;
  }

  set currentPath(AssetPathEntity value) {
    _currentPath = value;
  }

  String get currentGalleryName {
    if (currentPath?.isAll == true) {
      return i18nProvider.getAllGalleryText(options);
    }
    return currentPath?.name ?? "Select Folder";
  }

  GlobalKey scaffoldKey;
  ScrollController scrollController;

  bool isPushed = false;

  bool get useAlbum => widget.photoList == null || widget.photoList.isEmpty;

  Throttle _changeThrottle;

  @override
  void initState() {
    super.initState();
    scaffoldKey = GlobalKey();
    scrollController = ScrollController();
    _changeThrottle = Throttle(onCall: _onAssetChange);
    PhotoManager.addChangeCallback(_changeThrottle.call);
    PhotoManager.startChangeNotify();

    PhotoManager.addChangeCallback((value) async {
      //  debugPrint("addChangeCallback ${value.arguments['update'][0]['id']}");

      // File file = await AssetEntity(id: value.arguments['update'][0]['id']).file;
      // debugPrint("addChangeCallback ${file.path}");
      exitFiles();
      //debugPrint("addChangeCallback");
      /*  debugPrint("changed ${value.arguments['update']}");
    File f =   await AssetEntity(id: "3C185B1F-D372-48E3-A646-2B4EC580D95E/L0/001").file;
      debugPrint("addChangeCallback ccccc ${f}");*/
    });
    PhotoManager.startChangeNotify();
    debugPrint("_currentPath ${_currentPath.isAll}");

    _currentPath.isAll = true;
    debugPrint("options.onGoNextOnStart ${options.onGoNextOnStart}");
    if (options.onGoNextOnStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onClose?.call(selectedList);
      });
    }
    widget.onInstanceEvents(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      final pickedList = PhotoPickerProvider.of(context).pickedAssetList ?? [];
      addPickedAsset(pickedList.toList());
      _refreshList();
    }
  }

  @override
  void dispose() {
    PhotoManager.removeChangeCallback(_changeThrottle.call);
    PhotoManager.stopChangeNotify();
    _changeThrottle.dispose();
    scaffoldKey = null;
    super.dispose();
  }

  int _getColorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor;
    }
    return int.parse(hexColor, radix: 16);
  }

  @override
  Widget build(BuildContext context) {
    var textStyle = TextStyle(
      color: options.enabledColor,
      fontSize: 16,
    );
    return Scaffold(
      appBar: AppBar(
        bottom: PreferredSize(
          child: Container(
            height: 0.5,
            color: Color(_getColorFromHex("#E2E3E6")),
            width: double.infinity,
          ),
          preferredSize: Size(double.infinity, 0),
        ),
        titleSpacing: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Container(
          width: double.infinity,
          child: Stack(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Material(
                    color: Colors.transparent,
                    child: InkResponse(
                      radius: 20,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Center(
                          child: options.cancelWidget == null
                              ? Icon(
                                  Icons.close,
                                  color: Colors.black,
                                  size: 25,
                                )
                              : options.cancelWidget,
                        ),
                        // onPressed: _cancel,
                      ),
                      onTap: () {
                        widget.onExit();
                      },
                    ),
                  ),
                ],
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 50),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      currentGalleryName,
                      style: TextStyle(
                        color: options.textColor,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      child: InkWell(
                        child: Container(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                i18nProvider.getSubTitleText(),
                                style: TextStyle(
                                  color: options.textSubtitleColor,
                                  fontSize: 12,
                                ),
                              ),
                              options.subtitleWidgetArrow == null
                                  ? Icon(
                                      Icons.arrow_drop_down,
                                      color: options.textSubtitleColor,
                                    )
                                  : options.subtitleWidgetArrow
                            ],
                          ),
                        ),
                        onTap: () {
                          if ((assetProvider.getPaging() != null)) {
                            _GalleryListShown = true;
                            setState(() {});
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  InkWell(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 15),
                      child: Center(
                        child: Text(
                          options.allowSkip
                              ? selectedTotalCount == 0
                                  ? i18nProvider.getSureTextEmpty(
                                      options, selectedTotalCount)
                                  : i18nProvider.getSureText(
                                      options, selectedTotalCount)
                              : i18nProvider.getSureText(
                                  options, selectedTotalCount),
                          style: selectedTotalCount == 0
                              ? textStyle.copyWith(color: options.disableColor)
                              : textStyle,
                        ),
                      ),
                    ),
                    onTap: sure,
                  )
                  /*FlatButton(
              splashColor: Colors.transparent,
              child: Text(
                i18nProvider.getSureText(options, selectedCount),
                style: selectedCount == 0
                    ? textStyle.copyWith(color: options.disableColor)
                    : textStyle,
              ),
              onPressed: selectedCount == 0 ? null : sure,
            )*/
                ],
              )
            ],
          ),
          height: 56,
        ) /*Center(
              child: Text(
                i18nProvider.getTitleText(options),
                style: TextStyle(
                  color: options.textColor,
                  fontSize: 17.7,
                ),
              ),
            )*/
        ,
        /*actions: <Widget>[
              FlatButton(
                splashColor: Colors.transparent,
                child: Text(
                  i18nProvider.getSureText(options, selectedCount),
                  style: selectedCount == 0
                      ? textStyle.copyWith(color: options.disableColor)
                      : textStyle,
                ),
                onPressed: selectedCount == 0 ? null : sure,
              ),
            ],*/
      ),
      body: _buildBody(),
      /*  bottomNavigationBar: _BottomWidget(
            key: scaffoldKey,
            provider: i18nProvider,
            options: options,
            galleryName: currentGalleryName,
            onGalleryChange: _onGalleryChange,
            onTapPreview: selectedList.isEmpty ? null : _onTapPreview,
            selectedProvider: this,
            galleryListProvider: this,
          ),*/
    ) /*Theme(
      data: Theme.of(context).copyWith(primaryColor: options.themeColor),
      child: DefaultTextStyle(
        style: textStyle,
        child: ,
      ),
    )*/
        ;
  }

  void _cancel() {
    selectedList.clear();
    widget.onClose(selectedList);
  }

  @override
  bool isUpperLimitImages() {
    var resultImage = selectedImagesCount >= options.maxImageSelected;
    if (resultImage) {
      widget.onLimitImages();
    }
    return resultImage;
  }

  @override
  bool isUpperLimitVideo() {
    var resultVideo = selectedVideosCount >= options.maxVideoSelected;
    if (resultVideo) {
      widget.onLimitVideo();
    }
    return resultVideo;
  }

/*  @override
  bool isUpperLimit() {
      debugPrint(" selectedImagesCount ${selectedImagesCount} options.maxImageSelected ${options.maxImageSelected}");
     debugPrint(" selectedVideosCount ${selectedVideosCount} options.maxVideoSelected ${options.maxVideoSelected}");

    var resultImage = selectedImagesCount >= options.maxImageSelected;
    var resultVideo = selectedVideosCount >= options.maxVideoSelected;

    bool limit = false;

    debugPrint("resultImage $resultImage resultVideo $resultVideo");


    if (resultImage || resultVideo) {
      debugPrint("limit image");
      //_showTip(i18nProvider.getMaxTipText(options));
      limit = true;
      if (resultImage) {
        widget.onLimitImages();
      } else {
        widget.onLimitVideo();
      }
    }
    */ /* else if(resultVideo && !resultImage){
      debugPrint("limit video");
      _showTip(i18nProvider.getMaxTipText(options));
    limit = true;
    }*/ /*
    else {}

    return limit;
  }*/

  void sure() async {
    if (Platform.isIOS) {
      if (selectedList.length > 0) {
        showDialog(
          barrierDismissible: false,
          context: context,
          builder: (c) => Material(
            color: Colors.transparent,
            child: Container(
              child: Row(
                children: [
                  options.downloadingIcloudWidget != null
                      ? options.downloadingIcloudWidget
                      : Container(
                          width: 100,
                          height: 100,
                          color: Colors.white,
                          child: Center(
                            child: Text(
                              "Downloading from icloud",
                              style: TextStyle(fontSize: 13),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                ],
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
              ),
            ),
          ),
        );

        debugPrint("CHECKFIELLS ${selectedList.length}");
        selectedListCount = selectedList.length;
        selectedList.forEach((element) {
          element.originFile.then((value) {
            exitFiles();
            debugPrint("FILE got");
          });
        });
      } else {
        if (options.allowSkip) widget.onClose?.call(selectedList);
      }
    } else {
      if (selectedList.length > 0) {
        widget.onClose?.call(selectedList);
      } else {
        if (options.allowSkip) widget.onClose?.call(selectedList);
      }
    }

  }

  exitFiles() {
    selectedListCount--;
    if (selectedListCount == 0) {
      Navigator.of(context).pop();
      widget.onClose?.call(selectedList);
    }
  }

  void _showTip(String msg) {
    if (isPushed) {
      return;
    }

    /*Scaffold.of(scaffoldKey.currentContext).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: options.textColor,
            fontSize: 14.0,
          ),
        ),
        duration: Duration(milliseconds: 1500),
        backgroundColor: themeColor.withOpacity(0.7),
      ),
    );*/
  }

  void _refreshList() async {
    await Future.delayed(Duration.zero);
    if (!useAlbum) {
      _refreshListFromWidget();
      return;
    }

    _refreshListFromGallery();
  }

  Future<void> _refreshListFromWidget() async {
    _onRefreshAssetPathList(widget.photoList);
  }

  Future<void> _refreshListFromGallery() async {
    List<AssetPathEntity> pathList;
    switch (options.pickType) {
      case PickType.onlyImage:
        pathList = await PhotoManager.getAssetPathList(type: RequestType.image);
        break;
      case PickType.onlyVideo:
        pathList = await PhotoManager.getAssetPathList(type: RequestType.video);
        break;
      default:
        pathList = await PhotoManager.getAssetPathList(
            type: RequestType.image | RequestType.video);
    }

    _onRefreshAssetPathList(pathList);
  }

  Future<void> _onRefreshAssetPathList(List<AssetPathEntity> pathList) async {
    if (pathList == null) {
      return;
    }

    options.sortDelegate.sort(pathList);

    galleryPathList.clear();
    galleryPathList.addAll(pathList);

    if (pathList.isNotEmpty) {
      assetProvider.current = pathList[0];
      debugPrint("load more _onrefresh");
      await assetProvider.loadMore();
    }

    for (var path in pathList) {
      if (path.isAll) {
        path.name = i18nProvider.getAllGalleryText(options);
      }
    }

    setState(() {
      _isInit = true;
    });
  }

  Widget _buildBody() {
    if (!_isInit) {
      return _buildLoading();
    }

    final noMore = assetProvider.noMore;

    final count = assetProvider.count + (noMore ? 0 : 1) + 1;

    return Stack(
      children: <Widget>[
        (assetProvider.getPaging() != null)
            ? Container(
                color: options.dividerColor,
                child: GridView.builder(
                  controller: scrollController,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: options.rowCount,
                    childAspectRatio: options.itemRadio,
                    crossAxisSpacing: options.padding,
                    mainAxisSpacing: options.padding,
                  ),
                  itemBuilder: _buildItem,
                  itemCount: count,
                ),
              )
            : _buildNoData(),
        _GalleryListShown
            ? ChangeGalleryDialog(
                galleryList: this.galleryPathList,
                i18n: i18nProvider,
                options: options,
                onGalleryChange: _onGalleryChange,
              )
            : Container(),
        options.showManagePhotos
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.only(bottom: 20),
                        child: InkWell(
                          child: options.managePhotosWidget == null
                              ? Container(
                                  color: Colors.blue,
                                  padding: EdgeInsets.symmetric(horizontal: 7),
                                  height: 50,
                                  child: Center(
                                    child: Text(
                                      i18nProvider.getOpenSettingsText(),
                                      style: const TextStyle(
                                        fontSize: 13.0,
                                      ),
                                    ),
                                  ),
                                )
                              : options.managePhotosWidget,
                          onTap: () {
                            PhotoManager.openSetting();
                          },
                        ),
                      )
                    ],
                  )
                ],
              )
            : Container()
      ],
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final noMore = assetProvider.noMore;

    // debugPrint("assetProvider.count ${assetProvider.count}  noMore $noMore");
    if (assetProvider.getPaging() != null) {
      if (!noMore && index == assetProvider.count) {
        //  debugPrint("build item");
        _loadMore();
        return _buildLoading();
      }
    } else {
      return _buildNoData();
    }

    if(index == 0){
      return Material(
        color: Colors.transparent,
        child: InkWell(
          child: Container(child: options.cameraWidget,),
          onTap: (){
            ImagePicker().getImage(source: ImageSource.camera);
          },
        ),
      );
    }

    var data = list[index-1];
    var currentSelected = containsEntity(data);
    return RepaintBoundary(
      child: GestureDetector(
        onTap: () => changeCheck(!currentSelected, data), //,(data, index),
        child: Stack(
          children: <Widget>[
            ImageItem(
              entity: data,
              themeColor: themeColor,
              size: options.thumbSize,
              loadingDelegate: options.loadingDelegate,
              badgeDelegate: options.badgeDelegate,
            ),
            _buildMask(containsEntity(data)),
            _buildSelected(data),
          ],
        ),
      ),
    );
  }

  _loadMore() async {
    await assetProvider.loadMore();
    setState(() {});
  }

  _buildMask(bool showMask) {
    return IgnorePointer(
      child: AnimatedContainer(
        color: showMask ? Colors.black.withOpacity(0.5) : Colors.transparent,
        duration: Duration(milliseconds: 300),
      ),
    );
  }

  Widget _buildSelected(AssetEntity entity) {
    var currentSelected = containsEntity(entity);
    return Positioned(
      right: 0.0,
      width: 36.0,
      height: 36.0,
      child: GestureDetector(
        onTap: () {
          changeCheck(!currentSelected, entity);
        },
        behavior: HitTestBehavior.translucent,
        child: _buildText(entity),
      ),
    );
  }

  Widget _buildText(AssetEntity entity) {
    var isSelected = containsEntity(entity);
    Widget child;
    BoxDecoration decoration;
    if (isSelected) {
      child = Text(
        (indexOfSelected(entity) + 1).toString(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12.0,
          color: Colors.white,
        ),
      );
      decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(1.0),
          border: Border.all(
            color: Colors.white,
          ),
          color: themeColor);
    } else {
      decoration = BoxDecoration(
        borderRadius: BorderRadius.circular(1.0),
        border: Border.all(
          color: Colors.white,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: decoration,
        alignment: Alignment.center,
        child: child,
      ),
    );
  }

  void changeCheck(bool value, AssetEntity entity) {
    if (value) {
      addSelectEntity(entity);
    } else {
      removeSelectEntity(entity);
    }
    setState(() {});
  }

  void _onGalleryChange(AssetPathEntity assetPathEntity) async {
    _currentPath = assetPathEntity;
    debugPrint("path ${assetPathEntity.name}");

    _GalleryListShown = false;
    setState(() {});
    // _currentPath.assetList.then((v) async {
    //   _sortAssetList(v);
    //  list.clear();
    //   list.addAll(v);
    //   scrollController.jumpTo(0.0);
    //   await checkPickImageEntity();
    //   setState(() {});
    // });
    // assetProvider.data.clear();
    if (assetPathEntity != assetProvider.current) {
      assetProvider.current = assetPathEntity;
      // await assetProvider.loadMore();
      // scrollController.jumpTo(0.0);
      //list.clear();
      // list.addAll(assetProvider.data);
      debugPrint(
          "assetProvider.current.name.data ${assetProvider.current.name}");
      setState(() {});

      // _onPhotoRefresh();
    }
  }

  Widget _buildLoading() {
    return Center(
      child: Column(
        children: <Widget>[
          Container(
            width: 40.0,
            height: 40.0,
            padding: const EdgeInsets.all(5.0),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(themeColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              i18nProvider.loadingText(),
              style: const TextStyle(
                fontSize: 12.0,
              ),
            ),
          ),
        ],
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
      ),
    );
  }

  Widget _buildNoData() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                i18nProvider.getNoPhotosSelectiveText(),
                style: const TextStyle(
                  fontSize: 13.0,
                ),
              ),
            ),
          ],
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
        ),
      ),
    );
  }

  void _onAssetChange() {
    debugPrint("_onAssetChange  ");
    if (useAlbum) {
      // _onPhotoRefresh();
    }
  }

  void _onPhotoRefresh() async {
    List<AssetPathEntity> pathList;
    switch (options.pickType) {
      case PickType.onlyImage:
        pathList = await PhotoManager.getAssetPathList(type: RequestType.image);
        break;
      case PickType.onlyVideo:
        pathList = await PhotoManager.getAssetPathList(type: RequestType.video);
        break;
      default:
        pathList = await PhotoManager.getAssetPathList(
            type: RequestType.image | RequestType.video);
    }

    if (pathList == null) {
      return;
    }

    this.galleryPathList.clear();
    this.galleryPathList.addAll(pathList);

    if (!this.galleryPathList.contains(this.currentPath)) {
      // current path is deleted , 当前的相册被删除, 应该提示刷新
      if (this.galleryPathList.length > 0) {
        _onGalleryChange(this.galleryPathList[0]);
      }
      return;
    }
    // Not deleted
    _onGalleryChange(this.currentPath);
  }

  @override
  onPickedAssetChanged(List<AssetEntity> pickedAssetList) {
    selectedList = pickedAssetList;
    _refreshList();
  }

  @override
  onExit() {
    Navigator.pop(context);
  }
}
