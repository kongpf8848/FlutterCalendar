import 'package:example/persistent_header_builder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:smart_calendar/smart_calendar.dart';

void main() {
  Intl.defaultLocale = "zh_CN";
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: Locale("zh", "CN"),
      localizationsDelegates: const [
        GlobalCupertinoLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('zh', 'CN'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  late CalendarController calendarController;
  final double calendarHeaderHeight = 30.0;

  @override
  void initState() {
    super.initState();
    calendarController = CalendarController();
  }

  Widget _buildDaysOfWeek(MaterialLocalizations localizations) {
    final List<Widget> widgets = <Widget>[];
    for (int i = 0;
        widgets.length < DateTime.daysPerWeek;
        i = (i + 1) % DateTime.daysPerWeek) {
      final String weekday = localizations.narrowWeekdays[i];
      widgets.add(Expanded(
          child: Center(
        child: Text(weekday, style: TextStyle(fontSize: 12)),
      )));
    }
    return Container(
      height: calendarHeaderHeight,
      color: Colors.white,
      child: Row(children: widgets),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MaterialLocalizations localizations =
        MaterialLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text("calendar"),
        elevation: 2,
      ),
      body: Calendar(
        calendarController: calendarController,
        backgroundColor: Colors.white,
        showSliverPersistentHeader: true,
        sliverTabBarHeight: calendarHeaderHeight,
        sliverPersistentHeader: SliverPersistentHeader(
          pinned: true,
          delegate: PersistentHeaderDelegateBuilder(
              max: calendarHeaderHeight,
              min: calendarHeaderHeight,
              builder: (context, shrinkOffset, overlapsContent) {
                return _buildDaysOfWeek(localizations);
              }),
        ),
        calendarState: CalendarState.WEEK,
        calendarStateChangeListener: (state) {
          debugPrint(
              '++++++++++++calendarStateChangeListener:$state,${calendarController.calendarState}');
        },
        onItemClick: (bean) => onItemClick(bean),
        itemBuilder:
            (BuildContext context, int index, CalendarItemState bean) =>
                Container(
          color: bean.dateTime == CalendarBuilder.selectedDate
              ? Colors.blue
              : Colors.white,
          alignment: Alignment.center,
          child: Text(
            "${bean.day}",
            style: TextStyle(
                color: bean.isCurrentMonth ? Colors.black : Colors.grey),
          ),
        ),
        //the day will be return -1 when user select day out of current Month
        // or the pager do not has select day
        // if you want a user select date then you should move to onItemClick
        // sliverAppBarBuilder:
        //     (BuildContext context, int year, int month, int day) =>
        //         buildAppBar(year, month, day),
        //to add any widgets
        slivers: _buildSlivers(),
      ),
    );
  }

  onItemClick(CalendarItemState bean) {
    print(
        "onItemClick: ${bean.dateTime},${bean.isCurrentMonth},${bean.index},${calendarController.calendarState}");
    if (calendarController.calendarState.isMonthView()) {
      print("onItemClick22");
      if (!bean.isCurrentMonth) {
        calendarController.changeToDate(bean.dateTime);
      }
    }
  }

  SliverAppBar buildAppBar(int year, int month, int day) {
    return SliverAppBar(
      backgroundColor: Colors.white,
      floating: true,
      elevation: 0,
      title: Row(
        children: [
          Text(
            "$year year",
            style: TextStyle(color: Colors.black),
          ),
          Text(
            "$month month",
            style: TextStyle(color: Colors.black),
          ),
          Text(
            "$day day",
            style: TextStyle(color: Colors.black),
          )
        ],
      ),
    );
  }

  List<Widget> _buildSlivers() {
    return [
      SliverPersistentHeader(
        pinned: true,
        delegate: SliverTabBarDelegate(
            child: TabBar(
          indicatorColor: Colors.transparent,
          labelColor: Colors.transparent,
          controller: TabController(length: 3, vsync: this),
          tabs: [
            FittedBox(
              child: OutlinedButton(
                //color: Colors.grey.shade300,
                child: Text("Shrink Calendar"),
                onPressed: () => calendarController.shrink(),
              ),
            ),
            FittedBox(
              child: OutlinedButton(
                //color: Colors.grey.shade300,
                child: Text("Expand Calendar"),
                onPressed: () => calendarController.expand(),
              ),
            ),
            FittedBox(
              child: OutlinedButton(
                //color: Colors.grey.shade300,
                child: Text("Back Today"),
                onPressed: () =>
                    calendarController.changeToDate(DateTime.now()),
              ),
            ),
          ],
        )),
      ),
      SliverList(
          delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) => Container(
                    height: 80,
                    alignment: Alignment.center,
                    color: Colors.primaries[index % Colors.primaries.length],
                    child: Text("$index"),
                  ),
              childCount: 20)),
    ];
  }
}
