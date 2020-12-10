import 'package:flutter/material.dart';
import 'package:photo/src/delegate/badge_delegate.dart';
import 'package:photo/src/delegate/checkbox_builder_delegate.dart';
import 'package:photo/src/delegate/loading_delegate.dart';
import 'package:photo/src/delegate/sort_delegate.dart';

class Options {
  final int rowCount;

  final int maxSelected;

  final double padding;

  final double itemRadio;

  final Color themeColor;

  final Color dividerColor;

  final Color textColor;

  final Color textSubtitleColor;

  final Color disableColor;

  final Color enabledColor;

  final int thumbSize;

  final SortDelegate sortDelegate;

  final CheckBoxBuilderDelegate checkBoxBuilderDelegate;

  final LoadingDelegate loadingDelegate;

  final BadgeDelegate badgeDelegate;

  final PickType pickType;

  final Widget cancelWidget;

  final Widget subtitleWidgetArrow;

  const Options({
    this.rowCount,
    this.maxSelected,
    this.padding,
    this.itemRadio,
    this.themeColor,
    this.dividerColor,
    this.textColor,
    this.disableColor,
    this.thumbSize,
    this.sortDelegate,
    this.checkBoxBuilderDelegate,
    this.loadingDelegate,
    this.badgeDelegate,
    this.pickType,
    this.cancelWidget,
    this.textSubtitleColor,
    this.subtitleWidgetArrow,
    this.enabledColor
  });
}

enum PickType {
  all,
  onlyImage,
  onlyVideo,
}
