import 'package:flutter/animation.dart';
import 'package:imba_calendar/calendar_state.dart';

abstract class CalendarDelegate {
  void expand();

  void shrink();

  void changeToDate(DateTime dateTime);

  void previousPage(Duration duration, Curve curve);

  void nextPage(Duration duration, Curve curve);

  CalendarState get calendarState;
}
