import 'package:calendar_view/calendar_view.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:knox/FirebaseFunctions/DatabaseFunctions/db.dart';
import 'package:knox/screens/DataModels/appointmentModel.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final FireStoreMethods _db = FireStoreMethods();
  bool _isLoading = true;
  final EventController _eventController = EventController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Calculate start and end dates for the current week
      final startOfWeek = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      // Format dates for the query
      String startDateStr = DateFormat('yyyy-MM-dd').format(startOfWeek);
      String endDateStr = DateFormat('yyyy-MM-dd').format(endOfWeek);

      List<AppointmentModel> appointments = await _db.getAppointmentsByRange(
        startDate: startDateStr,
        endDate: endDateStr,
      );

      // Convert appointments to calendar events
      _eventController.removeAll(_eventController.events);
      for (var appointment in appointments) {
        final date = DateTime.parse(appointment.date);
        final startParts = appointment.startTime.split(':');
        final endParts = appointment.endTime.split(':');

        final startDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(startParts[0]),
          int.parse(startParts[1]),
        );
        var endDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          int.parse(endParts[0]),
          int.parse(endParts[1]),
        );

        // Debug print

        // Ensure at least 1 minute duration
        if (!endDateTime.isAfter(startDateTime)) {
          endDateTime = startDateTime.add(const Duration(minutes: 1));
        }

        _eventController.add(
          CalendarEventData(
            date: startDateTime,
            startTime: startDateTime,
            endTime: endDateTime,
            event: appointment,
            title: appointment.customer,
            description: appointment.jobDescription,
            color:
                appointment.recordType == 'Sale' ? Colors.green : Colors.blue,
          ),
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading appointments: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Weekly Schedule',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                _loadAppointments();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.add(const Duration(days: 7));
                _loadAppointments();
              });
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : WeekView(
                weekPageHeaderBuilder: (startDate, endDate) {
                  return Container();
                },

                weekDayBuilder: (date) {
                  bool sameday =
                      DateFormat('yyyy-MM-dd').format(date) ==
                      DateFormat('yyyy-MM-dd').format(DateTime.now());

                  return Card(
                    color:
                        sameday
                            ? const Color.fromARGB(235, 57, 153, 243)
                            : Colors.white,
                    child: Center(
                      child: Text(
                        DateFormat('EE\ndd').format(date),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color:
                              sameday
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : Colors.black,
                        ),
                      ),
                    ),
                  );
                },
                timeLineWidth: 50,
                timeLineBuilder: (date) {
                  return Container(
                    padding: EdgeInsets.only(
                      right: 0,
                      left: 10,
                      top: 0,
                      bottom: 10,
                    ),
                    child: Text(
                      DateFormat('h a').format(date),
                      style: GoogleFonts.inter(
                        // <-- Use any Google Font here
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
                controller: _eventController,
                width: MediaQuery.of(context).size.width,
                minDay: DateTime(2020),
                maxDay: DateTime(2030),
                initialDay: _selectedDate,
                heightPerMinute: 1,
                startHour: 4,
                endHour: 22,
                showWeekends: true,
                weekDays: [
                  WeekDays.monday,
                  WeekDays.tuesday,
                  WeekDays.wednesday,
                  WeekDays.thursday,
                  WeekDays.friday,
                  WeekDays.saturday,
                  WeekDays.sunday,
                ],

                eventTileBuilder: (date, events, boundry, start, end) {
                  final appointment = events.first.event as AppointmentModel;
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final isOwner = appointment.ownerID == currentUserId;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color:
                          (isOwner
                              ? const Color.fromARGB(221, 90, 216, 95)
                              : const Color.fromARGB(210, 47, 155, 244)),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isOwner ? Colors.green : Colors.blue,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          events.first.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${DateFormat('h:mm a').format(start)} - ${DateFormat('h:mm a').format(end)}',
                          style: const TextStyle(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
                onEventTap: (events, date) {
                  final appointment = events.first.event as AppointmentModel;
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final isOwner = appointment.ownerID == currentUserId;
                  if (isOwner) {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text(appointment.customer),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description:${appointment.jobDescription ?? "No description"}',
                                ),
                                Text(
                                  'Location:${appointment.location ?? "No location"}',
                                ),
                                Text(
                                  'Owner:${appointment.ownerName ?? "Unknown"}',
                                ),
                                Text(
                                  '${DateFormat('h:mm a').format(DateFormat('HH:mm').parse(appointment.startTime))} - ${DateFormat('h:mm a').format(DateFormat('HH:mm').parse(appointment.endTime))}',
                                ),

                                Text('Phone:${appointment.phone ?? "-"}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                    );
                  }
                },
              ),
    );
  }
}
