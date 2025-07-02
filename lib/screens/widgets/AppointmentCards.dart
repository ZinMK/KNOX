
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:knox/screens/DataModels/appointmentModel.dart';
import 'package:knox/screens/createApptPage.dart';

class AppointmentCards extends StatefulWidget {
  final AppointmentModel appt;

  const AppointmentCards({Key? key, required this.appt}) : super(key: key);

  @override
  State<AppointmentCards> createState() => _AppointmentCardsState();
}

class _AppointmentCardsState extends State<AppointmentCards> {
  bool _isExpanded = false;

  String toTwelveHourFormat(String time24) {
    final parts = time24.split(':');
    if (parts.length != 2) return time24;
    var hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:$minute $period';
  }

  String formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return DateFormat('MMM d (EEE)').format(dt);
    } catch (_) {
      return date;
    }
  }

  String timeDifference(String startTime, String endTime) {
    final startParts = startTime.split(":").map(int.parse).toList();
    final endParts = endTime.split(":").map(int.parse).toList();

    var startDateTime = DateTime(2025, 1, 1, startParts[0], startParts[1]);
    var endDateTime = DateTime(2025, 1, 1, endParts[0], endParts[1]);

    // If end time is before start time, assume it's next day
    if (endDateTime.isBefore(startDateTime)) {
      endDateTime = endDateTime.add(Duration(days: 1));
    }

    final diff = endDateTime.difference(startDateTime);
    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;

    if (hours == 0 && minutes == 0) return "0";
    if (hours == 0) return "${minutes}m";
    if (minutes == 0) return "${hours}h";
    return "${hours}h ${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final isOwner = currentUserId == widget.appt.ownerID;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          if (isOwner) {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date and status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 4),

                      Text(
                        '${toTwelveHourFormat(widget.appt.startTime!)} - ${toTwelveHourFormat(widget.appt.endTime!)}',

                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          widget.appt.status == 'Scheduled'
                              ? Colors.green[100]
                              : Colors.orange[100],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      timeDifference(
                        widget.appt.startTime,
                        widget.appt.endTime,
                      ),

                      style: TextStyle(
                        color:
                            widget.appt.status == 'Scheduled'
                                ? Colors.green[800]
                                : Colors.orange[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Time range with icon

              // Location with icon
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Location: ${widget.appt.location}',
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Owner name with icon
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Owner: ${widget.appt.ownerName}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              // Additional owner details (only visible when expanded and is owner)
              if (isOwner && _isExpanded) ...[
                const Divider(height: 24),
                const Text(
                  'Appointment Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                // Customer details
                Row(
                  children: [
                    const Icon(Icons.people, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Customer: ${widget.appt.customer}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.add, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Created at: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.appt.createdAt!))}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Phone with icon
                Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.appt.phone}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Price with icon
                Row(
                  children: [
                    const Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${widget.appt.jobPrice}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Description
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.description, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${widget.appt.jobDescription}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],

              // Edit button for owner and expansion indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isOwner) ...[
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          _isExpanded
                              ? 'Tap to collapse details'
                              : 'Tap to view details',
                          style: GoogleFonts.inter(
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.edit,
                        size: 15,
                        color: Colors.blue,
                      ),
                      label: Text(
                        'Edit',
                        style: GoogleFonts.inter(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
                      onPressed:
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CreateApptPage(data: widget.appt),
                            ),
                          ),
                    ),
                  ],
                  if (!isOwner)
                    const SizedBox(height: 8), // Spacer for non-owners
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
