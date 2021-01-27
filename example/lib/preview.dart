import 'package:flutter/material.dart';
import 'package:photo/photo_callback.dart';
import 'package:photo_manager/photo_manager.dart';

import './asset_image.dart';

class PreviewPage extends StatelessWidget {
  final List<AssetEntity> list;
  final PhotoPickerCallbackEvents event;

  const PreviewPage({Key key, this.list = const [],this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Preview"),
      ),
      body: Column(
        children: [
          Expanded(
              child: ListView(
            children: list
                .map((item) => AssetImageWidget(
                      assetEntity: item,
                      width: 300,
                      height: 200,
                      boxFit: BoxFit.cover,
                    ))
                .toList(),
          )),
          InkWell(
            child: Container(
              height: 50,
              color: Colors.red,
              width: 100,
            ),
            onTap: () {
              list.removeLast();
              Navigator.pop(context);
              event.onPickedAssetChanged(list);
              // Navigator.of(context).popUntil((route) => route.isFirst);
            },
          )
        ],
      ),
    );
  }
}
