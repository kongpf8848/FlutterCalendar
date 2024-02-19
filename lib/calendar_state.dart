enum CalendarState {
  MONTH,
  WEEK,
}

extension CalendarStateExtension on CalendarState {
  //当前处于月视图
  isMonthView() => this == CalendarState.MONTH;

  //当前处于周视图
  isWeekView() => this == CalendarState.WEEK;
}
