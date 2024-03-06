import 'package:flutter/material.dart';

import '../smart_calendar.dart';

GlobalKey<_SmartCalendarState> calendarKey = GlobalKey();

class SmartCalendar extends StatefulWidget {
  final double childAspectRatio;
  final Widget? child;
  final CalendarItemBuilder itemBuilder;
  final Color backgroundColor;
  final ValueChanged<CalendarItem>? onItemClick;
  final List<Widget> slivers;
  final CalendarController calendarController;
  final SliverPersistentHeader? sliverPersistentHeader;
  final bool showSliverPersistentHeader;
  final double? sliverTabBarHeight;
  final CalendarState? calendarState;
  final ValueChanged<CalendarState>? onStateChanged;

  SmartCalendar({
    Key? key,
    this.childAspectRatio = ChildAspectRatio,
    this.child,
    this.calendarState,
    this.backgroundColor = Colors.white,
    required this.itemBuilder,
    this.onItemClick,
    this.onStateChanged,
    this.slivers = const [],
    required this.calendarController,
    this.showSliverPersistentHeader = true,
    this.sliverPersistentHeader,
    this.sliverTabBarHeight,
  })  : assert((sliverPersistentHeader != null && sliverTabBarHeight != null) ||
            (sliverPersistentHeader == null && sliverTabBarHeight == null)),
        super(key: key);

  @override
  State<SmartCalendar> createState() => _SmartCalendarState();
}

class _SmartCalendarState extends State<SmartCalendar>
    with TickerProviderStateMixin, CalendarDelegate {
  late double toolbarHeight;
  double? screenSize;

  ScrollController mainController = ScrollController();
  ScrollController gridController = ScrollController();
  late PageController pageController;
  late PageController weekPageController;
  late CalendarController calendarController;

  int pageIndex = 0;

  //滑动时锁定的pageIndex
  int lockingPageIndex = 0;

  late double expandedHeight;

  //根据滑动时锁定的lockingPageIndex获取的expandedHeight
  late double lockingExpandedHeight;

  //防止横向滚动时 GridView缩小动画导致页面跳动
  bool isHorizontalScroll = false;

  //日历展开收起模式 默认展开
  CalendarState _calendarState = CalendarState.MONTH;

  double flexibleSpaceHeight = 0.0;

  //选中的行数
  int selectLine = 0;

  int get month => pageIndex % 12 + 1;

  int get year => StartYear + pageIndex ~/ 12;

  //日历总行数
  int get lines => selectItemData.beans.length ~/ HorizontalItemCount;

  //收起时的时间
  late DateTime shrinkDateTime;

  ValueChanged<CalendarItem>? _onItemClick;

  double sliverTabBarHeight = SliverTabBarHeight;

  CalendarPagerItemBean get selectItemData {
    return _buildItemData(pageIndex);
  }

  CalendarPagerItemBean _buildItemData(int index) {
    return CalendarBuilder.build(index);
  }

  @override
  void initState() {
    DateTime now = DateTime.now();
    pageIndex = CalendarBuilder.dateTimeToIndex(now);

    _calendarState = widget.calendarState ?? CalendarState.MONTH;

    while (now.weekday != 7) {
      now = now.subtract(Duration(days: 1));
    }
    shrinkDateTime = DateTime(now.year, now.month, now.day);

    lockingPageIndex = pageIndex;

    pageController = PageController(initialPage: pageIndex);
    weekPageController = PageController(initialPage: WeekPageInitialIndex);
    pageController.addListener(() => _onPageScrolling());
    mainController.addListener(() => _onMainScrolling());

    _onItemClick = (v) {
      setState(() {});
      if (widget.onItemClick != null) {
        widget.onItemClick!(v);
      }
    };

    calendarController = widget.calendarController;
    calendarController.attach(this);

    if (widget.sliverPersistentHeader != null) {
      sliverTabBarHeight = widget.sliverTabBarHeight!;
    }

    if (!widget.showSliverPersistentHeader) {
      sliverTabBarHeight = 0;
    }

    super.initState();
  }

  @override
  void dispose() {
    calendarController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SmartCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (screenSize == null) {
      screenSize = MediaQuery.of(context).size.width;
      toolbarHeight = (screenSize! -
              GridHorizontalPadding * 2 -
              GridSpacing * (HorizontalItemCount - 1)) /
          HorizontalItemCount /
          widget.childAspectRatio;
      expandedHeight = _getExpandHeight(lines);
      lockingExpandedHeight = expandedHeight;

      if (_calendarState.isWeekView()) {
        Future.delayed(Duration.zero, () {
          mainController.jumpTo(_getExpandHeight(lines - 1) +
              kToolbarHeight +
              sliverTabBarHeight);
        });
      }
    }

    return SafeArea(
      child: NotificationListener(
        onNotification: (Notification notification) {
          _checkScroll(notification);
          return false;
        },
        child: CustomScrollView(controller: mainController, slivers: [
          if (widget.showSliverPersistentHeader &&
              widget.sliverPersistentHeader != null)
            widget.sliverPersistentHeader!,
          _buildCalendar(),
          ...widget.slivers
        ]),
      ),
    );
  }

  Widget _buildFlexibleSpace() {
    return LayoutBuilder(
      builder: (c, b) {
        flexibleSpaceHeight = b.biggest.height;
        if (flexibleSpaceHeight <=
                toolbarHeight * lines + GridVerticalPadding * 2 &&
            gridController.hasClients &&
            !isHorizontalScroll) {
          gridController.jumpTo((toolbarHeight * lines +
                      GridVerticalPadding * 2 -
                      flexibleSpaceHeight) *
                  selectLine /
                  (lines - 1) +
              selectLine * GridSpacing);
        }

        return Stack(
          children: [
            PageView.builder(
              controller: pageController,
              onPageChanged: (index) => _onPageChange(index),
              itemBuilder: (c, i) {
                var bean = _buildItemData(i);
                selectLine = bean.selectedLine;
                return CalendarPagerItem(
                  onItemClick: _onItemClick,
                  backgroundColor: widget.backgroundColor,
                  itemBuilder: widget.itemBuilder,
                  childAspectRatio: widget.childAspectRatio,
                  bean: bean,
                  controller: gridController,
                );
              },
              itemCount: CalendarBuilder.count,
            ),
            if (_calendarState.isWeekView())
              PageView.builder(
                controller: weekPageController,
                onPageChanged: (i) => _onWeekPageChange(i),
                itemBuilder: (c, i) {
                  var bean = CalendarBuilder.buildWeekData(
                      shrinkDateTime.add(Duration(
                          days: HorizontalItemCount *
                              (i - WeekPageInitialIndex))),
                      selectItemData.currentDate!);
                  return CalendarPagerItem(
                    onItemClick: _onItemClick,
                    backgroundColor: widget.backgroundColor,
                    itemBuilder: widget.itemBuilder,
                    childAspectRatio: widget.childAspectRatio,
                    bean: bean,
                  );
                },
                itemCount: WeekPageDataCount,
              ),
          ],
        );
      },
    );
  }

  _onWeekPageChange(int i) {
    final bean = CalendarBuilder.buildWeekData(
        shrinkDateTime.add(
            Duration(days: HorizontalItemCount * (i - WeekPageInitialIndex))),
        selectItemData.currentDate!);
    late CalendarItem state;
    try {
      state = bean.beans.firstWhere((element) =>
          element.dateTime.day == CalendarBuilder.selectedDate.value?.day &&
          element.dateTime.month == CalendarBuilder.selectedDate.value?.month &&
          element.dateTime.year == CalendarBuilder.selectedDate.value?.year);
    } catch (e) {}

    if (state != null) {
      pageIndex = CalendarBuilder.dateTimeToIndex(state.dateTime);
    } else {
      pageIndex = bean.index;
    }

    pageController.jumpToPage(pageIndex);

    try {
      final dateTime = bean.beans[0].dateTime;
      CalendarItem list = selectItemData.beans
          .firstWhere((element) => element.dateTime == dateTime);
      selectItemData.selectedLine = list.index ~/ HorizontalItemCount;
    } catch (e) {}
    setState(() {});
  }

  _onPageChange(int index) {
    pageIndex = index;
    debugPrint(
        '+++++++++++++++calendar,_onPageChange,index:$pageIndex,$year,$month,${selectItemData.currentDate},${selectItemData.selectedLine}');
    setState(() {});
  }

  Widget _buildCalendar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      pinned: true,
      toolbarHeight: toolbarHeight + GridVerticalPadding * 2,
      expandedHeight: expandedHeight,
      flexibleSpace: _buildFlexibleSpace(),
    );
  }

  _checkScroll(Notification notification) {
    if (notification is ScrollEndNotification) {
      if (mainController.position.maxScrollExtent ==
          notification.metrics.maxScrollExtent) {
        Future.delayed(Duration.zero, () => _onMainScrollEnd());
      } else if (notification.metrics.axis == Axis.horizontal) {
        isHorizontalScroll = false;
        lockingPageIndex = pageIndex;
        lockingExpandedHeight = _getExpandHeight(lines);
      }
    }
  }

  double _getExpandHeight(int lines) {
    return lines * toolbarHeight +
        GridVerticalPadding * 2 +
        (lines - 1) * GridSpacing;
  }

  _onMainScrollEnd() {
    if (flexibleSpaceHeight == toolbarHeight + GridVerticalPadding * 2) {
      int index = selectItemData.selectedLine * HorizontalItemCount;
      shrinkDateTime = selectItemData.beans[index].dateTime;
      weekPageController = PageController(initialPage: WeekPageInitialIndex);
      _onCalendarStateChanged(CalendarState.WEEK);
      setState(() {});
    } else {
      _onCalendarStateChanged(CalendarState.MONTH);
    }
    if (flexibleSpaceHeight > toolbarHeight + GridVerticalPadding * 2 &&
        flexibleSpaceHeight < toolbarHeight * lines / 2 + GridVerticalPadding) {
      shrink();
    } else if (flexibleSpaceHeight > toolbarHeight * lines / 2 &&
        flexibleSpaceHeight < toolbarHeight * lines) {
      expand();
    }
  }

  _onMainScrolling() {
    if (_calendarState.isWeekView() &&
        mainController.offset >
            _getExpandHeight(lines - 1) / 2 +
                kToolbarHeight +
                sliverTabBarHeight) {
      _onCalendarStateChanged(CalendarState.MONTH);
      expandedHeight = _getExpandHeight(lines);
      setState(() {});
    }
  }

  _onPageScrolling() {
    if (_calendarState.isWeekView()) {
      return;
    }

    isHorizontalScroll = true;
    final move = pageController.offset;
    final pageOffset = lockingPageIndex * (screenSize ?? 0);
    int offset;
    //左滑
    if (move > pageOffset) {
      offset = lockingPageIndex + 1;
    } else
    //右滑
    if (move < pageOffset) {
      offset = lockingPageIndex - 1;
    } else {
      offset = pageIndex;
    }

    int newLines = _buildItemData(offset).beans.length ~/ HorizontalItemCount;

    double newHeight = _getExpandHeight(newLines);

    if (newHeight != expandedHeight) {
      final addPart = (newHeight - lockingExpandedHeight) *
          ((move - pageOffset).abs()) /
          (screenSize ?? 1);
      expandedHeight = lockingExpandedHeight + addPart;
      setState(() {});
    }
  }

  _onCalendarStateChanged(CalendarState state) {
    if (_calendarState != state) {
      this._calendarState = state;
      widget.onStateChanged?.call(state);
    }
  }

  @override
  void changeToDate(DateTime dateTime) {
    CalendarBuilder.selectedDate.value =
        DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (_calendarState.isWeekView()) {
      int num = 0;
      if (dateTime.isBefore(shrinkDateTime)) {
        //往前减一周
        num = -1;
      }
      Duration du = dateTime.difference(shrinkDateTime);
      num += du.inDays ~/ 7;
      weekPageController.jumpToPage(WeekPageInitialIndex + num);
    }

    // if (isCalendarExpanded) {
    pageIndex = CalendarBuilder.dateTimeToIndex(dateTime);
    pageController.jumpToPage(pageIndex);
    expandedHeight = _getExpandHeight(lines);
    try {
      final CalendarItem state = selectItemData.beans.firstWhere(
          (element) => element.dateTime == CalendarBuilder.selectedDate.value);
      selectItemData.selectedLine = selectItemData.beans.indexOf(state) ~/ 7;
    } catch (e) {}
    setState(() {});
  }

  @override
  void shrink() {
    double height =
        _getExpandHeight(lines - 1) + kToolbarHeight + sliverTabBarHeight;
    if (mainController != null &&
        mainController.hasClients &&
        height != mainController.offset) {
      mainController.animateTo(height,
          duration: Duration(milliseconds: 300), curve: Curves.easeOutQuad);
    }
  }

  @override
  void expand() {
    debugPrint('+++++++++++expand,offset:${mainController.offset}');
    if (mainController != null &&
        mainController.hasClients &&
        mainController.offset != 0) {
      mainController.animateTo(0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOutQuad);
    }
  }

  @override
  void nextPage(Duration duration, Curve curve) {}

  @override
  void previousPage(Duration duration, Curve curve) {}

  @override
  CalendarState get calendarState => _calendarState;
}