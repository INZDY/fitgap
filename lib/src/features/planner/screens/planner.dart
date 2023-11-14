import 'package:fitgap/src/features/planner/models/modify_event.dart';
import 'package:fitgap/src/utils/firestore/firestore.dart';
import 'package:fitgap/src/utils/utility/month_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:intl/intl.dart';

class Planner extends StatefulWidget {
  const Planner({super.key});

  @override
  State<Planner> createState() => _PlannerState();
}

class _PlannerState extends State<Planner> {
  late List<Map<String, dynamic>> _eventsData;

  List<Appointment> appointmentDetails = <Appointment>[];
  late _AppointmentDataSource dataSource;

  DateTime selectedDate = DateTime.now();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadEvents();
  }

  Future loadEvents() async {
    final eventsData = await FirestoreService().getEvents();
    Future.delayed(const Duration(milliseconds: 700), () {
      setState(() {
        isLoading = false;
      });
    });

    setState(() {
      _eventsData = eventsData;
      dataSource = _getCalendarDataSource();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // shadowColor: Colors.transparent,
        title: const Text(
          'Calendar',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        //background
        width: double.maxFinite,
        height: double.maxFinite,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF000000), Color(0xFF07023A)],
          ),
        ),

        //Widget Render
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(25),
                child: Column(
                  children: [
                    //Calendar
                    Container(
                      height: 400,
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: const Color(0xFF99AFFF),
                      ),
                      child: SfCalendar(
                        //settings
                        view: CalendarView.month,
                        monthViewSettings: const MonthViewSettings(
                          navigationDirection:
                              MonthNavigationDirection.vertical,
                        ),
                        firstDayOfWeek: 1, //Monday
                        initialDisplayDate: DateTime.now(),
                        showCurrentTimeIndicator: true,
                        dataSource: _getCalendarDataSource(),
                        initialSelectedDate: DateTime.now(),
                        onSelectionChanged: selectionChanged,

                        //appearance
                        headerStyle: const CalendarHeaderStyle(
                          textAlign: TextAlign.center,
                        ),
                        viewHeaderHeight: 60,
                        selectionDecoration: BoxDecoration(
                            color: Colors.transparent,
                            border: Border.all(color: Colors.black, width: 2),
                            borderRadius:
                                const BorderRadius.all(Radius.circular(10))),
                        cellBorderColor: Colors.transparent,
                        backgroundColor: Colors.transparent,
                      ),
                    ),

                    Container(
                      alignment: Alignment.centerLeft,
                      height: 50,
                      child: Text(
                        '${selectedDate.day} '
                        '${NumberToMonthMap.monthsInYear[selectedDate.month]} '
                        '${selectedDate.year}',
                      ),
                    ),

                    //Appointments
                    Expanded(
                      child: Container(
                        color: Colors.transparent,
                        child: ListView.separated(
                          itemCount: appointmentDetails.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              alignment: Alignment.center,
                              height: 55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                color: appointmentDetails[index].color,
                              ),
                              child: ListTile(
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: appointmentDetails[index].isAllDay
                                      ? [
                                          const Text(
                                            'All day',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          )
                                        ]
                                      : [
                                          Text(
                                            DateFormat('hh:mm a').format(
                                                appointmentDetails[index]
                                                    .startTime),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('hh:mm a').format(
                                                appointmentDetails[index]
                                                    .endTime),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                ),
                                title: Text(
                                  appointmentDetails[index].title,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                                onTap: () => Navigator.of(context)
                                    .push(MaterialPageRoute(
                                        builder: (context) => ModifyEvent(
                                              eventDetail:
                                                  appointmentDetails[index],
                                            ))),
                              ),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const Divider(
                            height: 15,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
      ),
    );
  }

  void selectionChanged(CalendarSelectionDetails calendarSelectionDetails) {
    getSelectedDateAppointments(calendarSelectionDetails.date);
    selectedDate = calendarSelectionDetails.date!;
  }

  void getSelectedDateAppointments(DateTime? selectedDate) {
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) async {
      setState(() {
        appointmentDetails.clear();
      });

      if (dataSource.appointments!.isEmpty) {
        return;
      }

      for (int i = 0; i < dataSource.appointments!.length; i++) {
        Appointment appointment = dataSource.appointments![i] as Appointment;

        /// It return the occurrence appointment for the given pattern appointment at the selected date.
        final Appointment? occurrenceAppointment =
            dataSource.getOccurrenceAppointment(appointment, selectedDate!, '')
                as Appointment?;

        int appStartYear = appointment.startTime.year;
        int appStartMonth = appointment.startTime.month;
        int appStartDay = appointment.startTime.day;
        int appEndYear = appointment.endTime.year;
        int appEndMonth = appointment.endTime.month;
        int appEndDay = appointment.endTime.day;
        int selYear = selectedDate.year;
        int selMonth = selectedDate.month;
        int selDay = selectedDate.day;

        //Check if event is in that day
        if ((DateTime(appStartYear, appStartMonth, appStartDay) ==
                DateTime(selYear, selMonth, selDay)) ||
            (DateTime(appEndYear, appEndMonth, appEndDay) ==
                DateTime(selYear, selMonth, selDay)) ||
            occurrenceAppointment != null) {
          setState(() {
            appointmentDetails.add(appointment);
          });
        }
      }
      // print(appointmentDetails);
    });
  }

  _AppointmentDataSource _getCalendarDataSource() {
    List<Appointment> appointments = <Appointment>[];

    for (var event in _eventsData) {
      //color from value to color
      int colorValue = int.parse(event['tag']);
      Color color = Color(colorValue).withOpacity(1);

      print('HERE');
      print(_eventsData[0]);
      appointments.add(Appointment(
          title: event['title'],
          startTime: event['start_date'].toDate(),
          endTime: event['end_date'].toDate(),
          color: color,
          isAllDay: event['allday'],
          location: event['location'],
          people: event['people']));
    }
    return _AppointmentDataSource(appointments);
  }
}

//Class & Overrides for calendar
class Appointment {
  Appointment({
    required this.startTime,
    required this.endTime,
    required this.title,
    this.isAllDay = false,
    this.color = Colors.transparent,
    this.location = '',
    this.people = const [],
  });

  DateTime startTime;
  DateTime endTime;
  String title;
  Color color;
  bool isAllDay;
  String location;
  List<String> people;
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].startTime;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].endTime;
  }

  @override
  String getSubject(int index) {
    return appointments![index].title;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }

  @override
  Color getColor(int index) {
    return appointments![index].color;
  }

  @override
  String getLocation(int index) {
    return appointments![index].location;
  }

  List<String> getPeople(int index) {
    return appointments![index].people;
  }
}
