import 'package:flutter/material.dart';
import 'package:photo/src/entity/options.dart';
import 'package:photo/src/provider/i18n_provider.dart';
import 'package:photo/src/ui/page/photo_main_page.dart';
import 'package:photo_manager/photo_manager.dart';

class ChangeGalleryDialog extends StatefulWidget {
  final List<AssetPathEntity> galleryList;
  final ValueChanged<AssetPathEntity> onGalleryChange;
  final I18nProvider i18n;
  final Options options;

  const ChangeGalleryDialog(
      {Key key,
      this.galleryList,
      this.i18n,
      this.options,
      this.onGalleryChange})
      : super(key: key);

  @override
  _ChangeGalleryDialogState createState() => _ChangeGalleryDialogState();
}

class _ChangeGalleryDialogState extends State<ChangeGalleryDialog> {
  List<AssetEntity> entities = [];

  @override
  void initState() {
    getFirstImages();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: ListView.builder(
        itemBuilder: _buildItem,
        itemCount: widget.galleryList.length,
      ),
    );
  }

  void getFirstImages() async {
    /* widget.galleryList.forEach((element) async {

      setState(() {});
    });*/
    int i = 0;
    while (i < widget.galleryList.length) {
      var firstEntity = await widget.galleryList[i].getAssetListPaged(0, 1);
      if (firstEntity.length > 0)
        entities.add(firstEntity.first);
      else
        entities.add(null);
      i++;
    }
    setState(() {});
  }

  Widget _buildItem(BuildContext context, int index) {
    var entity = widget.galleryList[index];
    String text;

    if (entity.isAll) {
      text = widget.i18n?.getAllGalleryText(widget.options);
    }
    var assetEntity = index < entities.length ? entities[index] : null;

    text = text ?? entity.name;
    return InkWell(
      child: Container(
        padding: EdgeInsets.only(left: 10, right: 10, bottom: 5),
        child: Row(
          children: <Widget>[
            Container(
              width: 60,
              height: 60,
              color: Colors.black12,
              margin: EdgeInsets.all(1),
              child: assetEntity != null
                  ? ImageItem(
                      entity: assetEntity,
                      themeColor: widget.options.themeColor,
                      size: widget.options.thumbSize,
                      loadingDelegate: widget.options.loadingDelegate,
                      badgeDelegate: widget.options.badgeDelegate,
                    )
                  : Container(),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      "$text",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                    Text(" ${entity.assetCount}",
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                        ))
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      onTap: () {
        widget.onGalleryChange?.call(entity);
      },
    );
  }
}
