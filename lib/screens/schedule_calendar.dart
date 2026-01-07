import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:knox/FirebaseFunctions/DatabaseFunctions/db.dart';
import 'package:knox/screens/DataModels/appointmentModel.dart';
import 'package:knox/screens/calendar_view.dart';
import 'package:knox/screens/createApptPage.dart';
import 'package:knox/screens/leadcard.dart';
import 'package:knox/screens/leads_page.dart';
import 'package:knox/screens/mapscreen.dart';
import 'package:knox/screens/salesAnalytics.dart';
import 'package:knox/screens/widgets/AppointmentCards.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter/cupertino.dart';

class TodayApptPage extends StatelessWidget {
  const TodayApptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cleandows Scheduler',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: TodayAppointmentsPage(),
    );
  }
}

class TodayAppointmentsPage extends StatefulWidget {
  @override
  _TodayAppointmentsPageState createState() => _TodayAppointmentsPageState();
}

class _TodayAppointmentsPageState extends State<TodayAppointmentsPage> {
  final FireStoreMethods _db = FireStoreMethods();
  List<AppointmentModel> appointments = [];
  Map<DateTime, List<AppointmentModel>> _appointmentsByDate = {};
  List<AppointmentModel> _leads = [];
  bool _isLoading = false;
  int _selectedIndex = 0; // Start with Today's view selected

  DateTime selectedDate = DateTime.now();
  late DateTime today;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.twoWeeks;
  PageController pagectrl = PageController();

  // Define calendar date range
  late final DateTime firstDay;
  late final DateTime lastDay;

  @override
  void initState() {
    super.initState();
    // Initialize dates to ensure they're within valid range
    final now = DateTime.now();
    today = now;
    firstDay = DateTime(now.year - 1, 1, 1); // Start from previous year
    lastDay = DateTime(now.year + 2, 12, 31); // End 2 years from now
    // Ensure today is within the valid range
    if (today.isBefore(firstDay)) {
      today = firstDay;
    } else if (today.isAfter(lastDay)) {
      today = lastDay;
    }
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _isLoading = true;
      _appointmentsByDate.clear();
    });

    try {
      // Get today and 30 days from now
      final startDate = DateTime.now();
      final endDate = startDate.add(Duration(days: 30));

      // Fetch appointments for the selected day first
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
      final selectedDayAppointments = await _db.getAppointmentsByDate(
        formattedDate,
      );

      // Update UI immediately with selected day appointments
      setState(() {
        appointments = selectedDayAppointments;
        _isLoading = false;
      });

      // Then fetch appointments for the range in the background
      for (
        var day = startDate;
        day.isBefore(endDate.add(Duration(days: 1)));
        day = day.add(Duration(days: 1))
      ) {
        final formattedDate = DateFormat('yyyy-MM-dd').format(day);
        final fetchedAppointments = await _db.getAppointmentsByDate(
          formattedDate,
        );

        if (fetchedAppointments.isNotEmpty) {
          final normalizedDate = DateTime(day.year, day.month, day.day);
          setState(() {
            _appointmentsByDate[normalizedDate] = fetchedAppointments;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load appointments: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<AppointmentModel> _getAppointmentsForDay(DateTime day) {
    // Normalize the date to remove time component
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _appointmentsByDate[normalizedDate] ?? [];
  }

  Future<void> _removeAppointment(AppointmentModel appointment) async {
    try {
      await _db.deleteAppointment(appointment.date, appointment.id!);
      _fetchAppointments();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Appointment deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete appointment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    // Ensure dates are within valid range
    DateTime validFocusedDay = focusedDay;
    if (validFocusedDay.isBefore(firstDay)) {
      validFocusedDay = firstDay;
    } else if (validFocusedDay.isAfter(lastDay)) {
      validFocusedDay = lastDay;
    }

    DateTime validSelectedDay = selectedDay;
    if (validSelectedDay.isBefore(firstDay)) {
      validSelectedDay = firstDay;
    } else if (validSelectedDay.isAfter(lastDay)) {
      validSelectedDay = lastDay;
    }

    setState(() {
      _selectedDay = validSelectedDay;
      selectedDate = validSelectedDay;
      today = validFocusedDay;
    });
    _fetchAppointments();
  }

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    switch (index) {
      case 0:
        // Already on Today's view
        break;
      case 1:
        // Navigate to Calendar view
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CalendarView()),
        ).then((_) {
          // Reset index when returning from Calendar view
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 2:
        // Navigate to MapScreen
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MapScreen()),
        ).then((_) {
          // Reset index when returning from Map view
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 3:
        // Analytics
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SalesAnalytics()),
        ).then((_) {
          // Reset index when returning from Analytics
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 4:
        // Leads tab
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LeadsPage()),
        ).then((_) {
          // Reset index when returning from Leads
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Text(
              DateFormat.MMMMd().format(today),
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            // You can add a main title here if needed, e.g.:
            // Text('Cleandows Scheduler', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        activeColor: const Color.fromRGBO(
          159,
          215,
          5,
          1,
        ), // Change active color to green
        inactiveColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 25,
              child: Image.asset(
                'Assets/Icons/calendar1.png',
                color:
                    _selectedIndex == 0
                        ? const Color.fromRGBO(159, 215, 5, 1)
                        : Colors.grey,
              ),
            ),
            label: 'Scheduler',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 25,
              child: Image.asset(
                'Assets/Icons/schedule.png',
                color:
                    _selectedIndex == 1
                        ? const Color.fromRGBO(159, 215, 5, 1)
                        : Colors.grey,
              ),
            ),
            label: 'Calender View',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 25,
              child: Image.asset(
                'Assets/Icons/maps.png',
                color:
                    _selectedIndex == 2
                        ? const Color.fromRGBO(159, 215, 5, 1)
                        : Colors.grey,
              ),
            ),
            label: 'Maps',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 25,
              child: Image.asset(
                'Assets/Icons/stats.png',
                color:
                    _selectedIndex == 3
                        ? const Color.fromRGBO(159, 215, 5, 1)
                        : Colors.grey,
              ),
            ),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(
              width: 25,
              child: Image.asset(
                'Assets/Icons/lead-generation.png',
                color:
                    _selectedIndex == 4
                        ? const Color.fromRGBO(159, 215, 5, 1)
                        : Colors.grey,
              ),
            ),
            label: 'Lead List',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(10),
          child:
              _selectedIndex == 3
                  ? (_leads.isEmpty
                      ? Center(child: Text('No leads found.'))
                      : ListView.builder(
                        itemCount: _leads.length,
                        itemBuilder: (context, index) {
                          return LeadsCard(lead: _leads[index]);
                        },
                      ))
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Card(
                        elevation: 4,
                        shadowColor: Colors.black,
                        color: const Color.fromARGB(255, 248, 248, 248),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height * 0.2,
                          ),
                          child: TableCalendar(
                            headerStyle: HeaderStyle(
                              titleTextStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 23,
                              ),
                              titleCentered: true,
                              leftChevronIcon: Icon(
                                Icons.arrow_back_ios,
                                color: Colors.black,
                              ),
                              rightChevronIcon: Icon(
                                Icons.arrow_forward_ios_outlined,
                                color: Colors.black,
                              ),
                            ),
                            calendarStyle: CalendarStyle(
                              selectedDecoration: BoxDecoration(
                                color: const Color.fromARGB(173, 0, 187, 255),
                                shape: BoxShape.circle,
                              ),
                              selectedTextStyle: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              canMarkersOverflow: false,
                              isTodayHighlighted: true,
                              todayTextStyle: GoogleFonts.poppins(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              defaultTextStyle: GoogleFonts.poppins(),
                              markersMaxCount: 3,
                              markerDecoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                              markerMargin: EdgeInsets.symmetric(
                                horizontal: 0.3,
                              ),
                            ),
                            rowHeight: 45,
                            focusedDay: today,
                            onDaySelected: _onDaySelected,
                            availableGestures: AvailableGestures.all,
                            availableCalendarFormats: {
                              CalendarFormat.twoWeeks: '2 weeks',
                            },
                            calendarFormat: CalendarFormat.twoWeeks,
                            onFormatChanged: (format) {
                              setState(() {
                                _calendarFormat = format;
                              });
                            },
                            firstDay: firstDay,
                            lastDay: lastDay,
                            selectedDayPredicate:
                                (day) => isSameDay(day, selectedDate),
                            eventLoader: _getAppointmentsForDay,
                            onPageChanged: (focusedDay) {
                              // Ensure focusedDay stays within valid range
                              DateTime validFocusedDay = focusedDay;
                              if (validFocusedDay.isBefore(firstDay)) {
                                validFocusedDay = firstDay;
                              } else if (validFocusedDay.isAfter(lastDay)) {
                                validFocusedDay = lastDay;
                              }
                              setState(() {
                                today = validFocusedDay;
                              });
                              _fetchAppointments();
                            },
                            calendarBuilders: CalendarBuilders(
                              markerBuilder: (context, date, events) {
                                if (events.isEmpty) return null;

                                Color dotColor;
                                if (events.length >= 3) {
                                  dotColor = Colors.orange;
                                } else if (events.length == 2) {
                                  dotColor = Colors.yellow;
                                } else {
                                  dotColor = Colors.blue;
                                }

                                return Positioned(
                                  bottom: 8,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: List.generate(
                                      events.length > 3 ? 3 : events.length,
                                      (index) => Container(
                                        width: 6,
                                        height: 6,
                                        margin: EdgeInsets.symmetric(
                                          horizontal: 0.3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: dotColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(10, 5, 0, 0),
                        child: Text(
                          () {
                            final today = DateTime.now();
                            final difference =
                                selectedDate.difference(today).inDays;
                            final formattedDate = DateFormat.MMMMd().format(
                              selectedDate,
                            );

                            if (difference > 0) {
                              return 'Appointments for $formattedDate (in $difference days)';
                            } else if (difference == 0) {
                              return 'Appointments for $formattedDate';
                            } else {
                              return 'Appointments for $formattedDate';
                            }
                          }(),
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child:
                            _isLoading
                                ? Center(child: CircularProgressIndicator())
                                : appointments.isEmpty
                                ? Center(
                                  child: Text(
                                    'No appointments for selected day.',
                                    style: GoogleFonts.inter(
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                                : ListView.builder(
                                  itemCount: appointments.length,
                                  itemBuilder: (context, index) {
                                    AppointmentModel appointment =
                                        appointments[index];
                                    return Dismissible(
                                      key: Key(
                                        appointment.id ?? 'appointment-$index',
                                      ),
                                      background: Container(
                                        color: Colors.red,
                                        alignment: Alignment.centerRight,
                                        padding: EdgeInsets.only(right: 20),
                                        child: Icon(
                                          Icons.delete,
                                          color: Colors.white,
                                        ),
                                      ),
                                      direction: DismissDirection.endToStart,
                                      confirmDismiss: (direction) async {
                                        return await showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text("Confirm"),
                                              content: Text(
                                                "Are you sure you want to delete this appointment?",
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(false),
                                                  child: Text("CANCEL"),
                                                ),
                                                TextButton(
                                                  onPressed:
                                                      () => Navigator.of(
                                                        context,
                                                      ).pop(true),
                                                  child: Text("DELETE"),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                      onDismissed: (direction) {
                                        _removeAppointment(appointment);
                                      },
                                      child: AppointmentCards(
                                        appt: appointment,
                                      ),
                                    );
                                  },
                                ),
                      ),
                    ],
                  ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 97, 191, 241),
        foregroundColor: Colors.white,
        shape: CircleBorder(),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateApptPage(data: selectedDate),
            ),
          );

          if (result == true) {
            _fetchAppointments();
          }
        },
        child: Icon(Icons.add),
        tooltip: 'Add Appointment',
      ),
    );
  }
}
