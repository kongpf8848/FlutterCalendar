import 'package:flutter/material.dart';
import 'package:smart_calendar/delegate/calendar_delegate.dart';

import 'calendar_state.dart';


typedef ChangeDate = Function(DateTime dateTime);

class CalendarController extends ChangeNotifier {

  late CalendarDelegate _calendarDelegate;

  CalendarState get calendarState =>_calendarDelegate.calendarState;

  attach(CalendarDelegate delegate){
    this._calendarDelegate=delegate;
  }

  //切换到月视图
  expand() {
    _calendarDelegate.expand();
  }

  //切换到日视图
  shrink() {
    _calendarDelegate.shrink();
  }

  //跳转到上一页
  previousPage(
      {Duration duration = const Duration(milliseconds: 100),
      Curve curve = Curves.easeInOut}) {
    _calendarDelegate.previousPage(duration,curve);
  }

  //跳转到下一页
  nextPage(
      {Duration duration = const Duration(milliseconds: 100),
      Curve curve = Curves.easeInOut}) {
    _calendarDelegate.nextPage(duration,curve);
  }

  //选中具体日期
  changeToDate(DateTime dateTime) {
    _calendarDelegate.changeToDate(dateTime);
  }


}
