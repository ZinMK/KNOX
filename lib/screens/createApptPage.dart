import 'dart:ffi';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:knox/FirebaseFunctions/DatabaseFunctions/db.dart';
import 'package:knox/screens/DataModels/appointmentModel.dart';

// Import your FireStoreMethods class
// Update with actual path

const String kGoogleApiKey = ""; // <-- Replace with your API key

class CreateApptPage extends StatefulWidget {
  final Object data;
  final bool isFromLead; // Add this flag to know if we're coming from a lead

  CreateApptPage({super.key, required this.data, this.isFromLead = false});

  _CreateApptPageState createState() => _CreateApptPageState();
}

class _CreateApptPageState extends State<CreateApptPage> {
  final _formKey = GlobalKey<FormState>();
  String ownerID = FirebaseAuth.instance.currentUser!.uid.toString();
  String customer = '';
  String salesDescription = '';
  String location = '';
  DateTime selectedDate = DateTime.now();
  String recordID = '';
  String recordType = '';
  String jobPrice = '';
  String? email; // Added for lead integration
  String? phone; // Added for lead integration
  String? notes; // Added for lead integration
  String? leadStatus; // Added for lead integration
  String? leadId; // Added to track the original lead
  TimeOfDay? fromTime;
  TimeOfDay? toTime;
  List<String> category = ["Lead", "Sale"]; // List to hold the class names
  bool isEditing = false; // Track if we're editing an existing appointment
  String? selectedValue = "Sale";
  bool isLoading = false;

  // Lead status options when recordType is Lead
  List<String> leadStatusOptions = ["Quoted", "GotContact", "NextYear"];
  String? selectedLeadStatus = "Quoted";

  final TextEditingController recordTypeController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController emailController =
      TextEditingController(); // Added for lead
  final TextEditingController phoneController =
      TextEditingController(); // Added for lead
  final TextEditingController notesController =
      TextEditingController(); // Added for lead

  // Firebase methods instance
  final FireStoreMethods _fireStoreMethods = FireStoreMethods();

  List<Map<String, String>> _placePredictions = [];
  bool _isSearchingLocation = false;

  String _formatTimeOfDay(TimeOfDay tod) {
    // Format the time in 24-hour format for database storage
    return '${tod.hour.toString().padLeft(2, '0')}:${tod.minute.toString().padLeft(2, '0')}';
  }

  // Convert string time (HH:MM) to TimeOfDay
  TimeOfDay _parseTimeString(String timeStr) {
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  @override
  void initState() {
    super.initState();
    _handleInputData();
  }

  void _handleInputData() {
    // Check what type of data was passed
    if (widget.data is DateTime) {
      // If it's a DateTime, use it for the selected date
      selectedDate = widget.data as DateTime;

      isEditing = false;
    } else if (widget.data is AppointmentModel) {
      // If it's an AppointmentModel, populate all fields
      final appointment = widget.data as AppointmentModel;

      // Parse the date string to DateTime
      try {
        selectedDate = DateFormat('yyyy-MM-dd').parse(appointment.date);
      } catch (e) {
        print('Error parsing date: $e');
        selectedDate = DateTime.now();
      }

      try {
        recordType = appointment.recordType;
        selectedValue = appointment.recordType;
      } catch (e) {
        print('Error parsing type: $e');
      }

      // Parse time strings to TimeOfDay objects
      fromTime = _parseTimeString(appointment.startTime);
      toTime = _parseTimeString(appointment.endTime);

      // Set other fields
      customerController.text = appointment.customer;
      locationController.text = appointment.location;
      descriptionController.text = appointment.jobDescription;
      priceController.text = appointment.jobPrice;

      // Set lead-specific fields if available
      if (appointment.email != null) emailController.text = appointment.email!;
      if (appointment.phone != null) phoneController.text = appointment.phone!;
      if (appointment.notes != null) notesController.text = appointment.notes!;
      if (appointment.leadStatus != null)
        selectedLeadStatus = appointment.leadStatus;
      if (appointment.leadId != null) leadId = appointment.leadId;

      // Set state variables as well
      customer = appointment.customer;
      location = appointment.location;
      salesDescription = appointment.jobDescription;
      jobPrice = appointment.jobPrice;
      email = appointment.email;
      phone = appointment.phone;
      notes = appointment.notes;
      leadStatus = appointment.leadStatus;
      selectedValue = appointment.recordType;

      isEditing = true;
    } else if (widget.data is LeadModel && widget.isFromLead) {
      // If it's a LeadModel, populate lead-related fields
      final lead = widget.data as LeadModel;

      customerController.text = lead.name;
      emailController.text = lead.email;
      phoneController.text = lead.phone;
      notesController.text = lead.notes;
      selectedLeadStatus = lead.status;
      leadId = lead.id;

      // Set state variables
      customer = lead.name;
      email = lead.email;
      phone = lead.phone;
      notes = lead.notes;
      leadStatus = lead.status;
      recordType = 'Lead';
      selectedValue = 'Lead';

      isEditing = false;
    }
  }

  @override
  void dispose() {
    customerController.dispose();
    locationController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    emailController.dispose();
    phoneController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    try {
      setState(() {
        isLoading = true;
      });

      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.uid)
              .get();

      // throws if 'name' is missing, or returns null if it's explicitly stored as null
      String? ownerName = doc.get('name') as String?;

      // Format the date as YYYY-MM-DD
      final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

      // Get current user's display name or use a default
      if (ownerName == null) {
        ownerName = "";
      }

      if (isEditing) {
        // Update existing appointment
        final oldAppointment = widget.data as AppointmentModel;

        if (oldAppointment.recordType == 'Sale') {
          // Only handle date change if it's a Sale appointment
          if (oldAppointment.date != formattedDate) {
            // Create new appointment first
            final newAppointment = AppointmentModel(
              date: formattedDate,
              startTime: _formatTimeOfDay(fromTime ?? TimeOfDay.now()),
              endTime: _formatTimeOfDay(toTime ?? TimeOfDay.now()),
              customer: customer,
              location: location,
              ownerName: ownerName,
              status: 'Scheduled',
              ownerID: ownerID,
              jobPrice: jobPrice,
              jobDescription: salesDescription,
              recordType: 'Sale',
              email: email,
              phone: phone,
              notes: notes,
              createdAt: oldAppointment.createdAt,
            );

            // Create the new appointment first
            await _fireStoreMethods.createOrUpdateAppointment(newAppointment);

            // Then delete the old one
            await _fireStoreMethods.deleteAppointment(
              oldAppointment.date,
              oldAppointment.id!,
            );
          } else {
            // If date hasn't changed, just update the appointment
            final appointment = AppointmentModel(
              date: formattedDate,
              startTime: _formatTimeOfDay(fromTime ?? TimeOfDay.now()),
              endTime: _formatTimeOfDay(toTime ?? TimeOfDay.now()),
              customer: customer,
              location: location,
              ownerName: ownerName,
              status: 'Scheduled',
              ownerID: ownerID,
              jobPrice: jobPrice,
              jobDescription: salesDescription,
              recordType: 'Sale',
              email: email,
              phone: phone,
              notes: notes,
              createdAt: oldAppointment.createdAt,
              id: oldAppointment.id,
            );
            await _fireStoreMethods.createOrUpdateAppointment(appointment);
          }
        }
      } else {
        // Create new appointment
        final appointment = AppointmentModel(
          date: formattedDate,
          startTime: _formatTimeOfDay(fromTime ?? TimeOfDay.now()),
          endTime: _formatTimeOfDay(toTime ?? TimeOfDay.now()),
          customer: customer,
          location: location,
          ownerName: ownerName,
          status:
              recordType == 'Lead' ? selectedLeadStatus ?? 'New' : 'Scheduled',
          ownerID: ownerID,
          jobPrice: jobPrice,
          jobDescription: salesDescription,
          recordType: selectedValue!,
          email: email,
          phone: phone,
          notes: notes,
          leadStatus: recordType == 'Lead' ? selectedLeadStatus : null,
          leadId: leadId,
          createdAt: DateTime.now().toIso8601String(),
        );

        if (recordType == 'Lead') {
          await _fireStoreMethods.createLead(
            appointment,
            FirebaseAuth.instance.currentUser!.uid,
          );
        } else {
          await _fireStoreMethods.createOrUpdateAppointment(appointment);
        }

        // If this was created from a lead, update the lead status
        if (widget.isFromLead && leadId != null) {
          await _fireStoreMethods.updateLeadStatus(
            ownerID,
            leadId!,
            'converted',
          );
        }
      }

      setState(() {
        isLoading = false;
      });

      Navigator.pop(context);
      // You might want to show a success message or navigate to another page
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      // Show error message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error creating appointment: $e')));
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Show confirmation dialog
      _showDialog(context);
    }
  }

  Future<List<Map<String, String>>> fetchPlacePredictions(String input) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$kGoogleApiKey&types=address';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        return (data['predictions'] as List)
            .map<Map<String, String>>(
              (p) => {
                'description': p['description'].toString(),
                'place_id': p['place_id'].toString(),
              },
            )
            .toList();
      }
    }
    return [];
  }

  Future<String> fetchFullAddressWithPostal(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$kGoogleApiKey';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'OK') {
        final result = data['result'];
        final formattedAddress = result['formatted_address'];
        final components = result['address_components'] as List;
        String? postalCode;
        for (final c in components) {
          if ((c['types'] as List).contains('postal_code')) {
            postalCode = c['long_name'];
            break;
          }
        }
        // Insert postal code after street address if not present
        if (postalCode != null && !formattedAddress.contains(postalCode)) {
          final parts = formattedAddress.split(',');
          if (parts.length > 1) {
            parts.insert(1, ' $postalCode');
            return parts.join(',');
          }
        }
        return formattedAddress;
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (details.primaryDelta! > 20) {
          Navigator.pop(context);
        }
      },
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        appBar: AppBar(
          forceMaterialTransparency: true,
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          title: Text(
            isEditing
                ? "Edit Appointment"
                : widget.isFromLead
                ? "Convert Lead to Appointment"
                : "Create a New Appointment",
            style: Theme.of(context).textTheme.titleLarge!.copyWith(
              color: const Color.fromRGBO(159, 215, 5, 1),
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (isEditing)
              IconButton(
                onPressed: () async {
                  // Show delete confirmation dialog
                  bool confirm = await showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Text('Delete Appointment'),
                          content: Text(
                            'Are you sure you want to delete this appointment?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                  );

                  if (confirm == true) {
                    final appointment = widget.data as AppointmentModel;
                    await _fireStoreMethods.deleteAppointment(
                      appointment.date,
                      appointment.id!,
                    );
                    Navigator.pop(context);
                  }
                },
                icon: Icon(Icons.delete),
              ),
          ],
        ),
        body:
            isLoading
                ? Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Category Dropdown
                          Text(
                            "Category",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                hint: const Text(
                                  '    select type',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 12, 12, 12),
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15,
                                  ),
                                ),
                                value: selectedValue!,
                                onChanged:
                                    widget.isFromLead
                                        ? null // Disable if coming from lead conversion
                                        : (value) {
                                          setState(() {
                                            selectedValue = value;
                                            if (selectedValue != null) {
                                              recordType = selectedValue!;
                                            }
                                          });
                                        },
                                items:
                                    category
                                        .map(
                                          (item) => DropdownMenuItem(
                                            value: item,
                                            child: Text(
                                              "    $item",
                                              style: const TextStyle(
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                              ),
                            ),
                          ),

                          // Lead Status Dropdown (only show if recordType is Lead)
                          if (selectedValue == 'Lead')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 20),
                                Text(
                                  "Lead Status",
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: selectedLeadStatus,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedLeadStatus = value;
                                          leadStatus = value;
                                        });
                                      },
                                      items:
                                          leadStatusOptions
                                              .map(
                                                (item) => DropdownMenuItem(
                                                  value: item,
                                                  child: Text(
                                                    "    $item",
                                                    style: const TextStyle(
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                          // Date Picker Section
                          SizedBox(height: 20),
                          Text(
                            "Date",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now().subtract(
                                  Duration(days: 365),
                                ),
                                lastDate: DateTime.now().add(
                                  Duration(days: 365 * 2),
                                ),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: const Color.fromRGBO(
                                          159,
                                          215,
                                          5,
                                          1,
                                        ),
                                        onPrimary: Colors.white,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );

                              if (picked != null) {
                                setState(() {
                                  selectedDate = picked;
                                });
                              }
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                                color: Colors.grey.shade50,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    DateFormat(
                                      'EEEE, MMM d, yyyy',
                                    ).format(selectedDate),
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Price
                          SizedBox(height: 20),
                          Text(
                            "Price",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: priceController,
                            keyboardType: TextInputType.number,
                            cursorColor: Theme.of(context).dividerColor,
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              hintText: 'Enter Price',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            onSaved: (value) => jobPrice = value ?? '',
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Please enter price';
                              return null;
                            },
                          ),

                          // Client Name
                          SizedBox(height: 20),
                          Text(
                            "Client Name",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: customerController,
                            cursorColor: Theme.of(context).dividerColor,
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              hintText: 'Enter Client Name',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            onSaved: (value) => customer = value ?? '',
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Please enter client name';
                              return null;
                            },
                          ),

                          // Email (for Lead)
                          // if (selectedValue == 'Lead')
                          //   Column(
                          //     crossAxisAlignment: CrossAxisAlignment.start,
                          //     children: [
                          //       SizedBox(height: 20),
                          //       Text(
                          //         "Email",
                          //         style: GoogleFonts.roboto(
                          //           fontSize: 16,
                          //           fontWeight: FontWeight.w500,
                          //           color: Colors.black87,
                          //         ),
                          //       ),
                          //       SizedBox(height: 8),
                          //       TextFormField(
                          //         controller: emailController,
                          //         keyboardType: TextInputType.emailAddress,
                          //         cursorColor: Theme.of(context).dividerColor,
                          //         decoration: InputDecoration(
                          //           focusedBorder: OutlineInputBorder(
                          //             borderSide: BorderSide(
                          //               color: Colors.grey,
                          //             ),
                          //           ),
                          //           hintText: 'Enter Email',
                          //           hintStyle: GoogleFonts.roboto(
                          //             fontSize: 16,
                          //             fontWeight: FontWeight.w500,
                          //             color: Colors.grey,
                          //           ),
                          //           filled: true,
                          //           fillColor: Colors.grey.shade50,
                          //           border: OutlineInputBorder(
                          //             borderRadius: BorderRadius.circular(12),
                          //             borderSide: BorderSide(
                          //               color: Colors.grey.shade300,
                          //             ),
                          //           ),
                          //           enabledBorder: OutlineInputBorder(
                          //             borderRadius: BorderRadius.circular(12),
                          //             borderSide: BorderSide(
                          //               color: Colors.grey.shade300,
                          //             ),
                          //           ),
                          //         ),
                          //         onSaved: (value) => email = value,
                          //         validator: (value) {
                          //           if (selectedValue == 'Lead' &&
                          //               value!.isEmpty) {
                          //             return 'Please enter email for lead';
                          //           }
                          //           return null;
                          //         },
                          //       ),
                          //     ],
                          //   ),

                          // Phone (for Lead)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 20),
                              Text(
                                "Phone",
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextFormField(
                                controller: phoneController,
                                keyboardType: TextInputType.phone,
                                cursorColor: Theme.of(context).dividerColor,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  hintText: 'Enter Phone Number',
                                  hintStyle: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                onSaved: (value) => phone = value,
                                validator: (value) {
                                  if (selectedValue == 'Lead' &&
                                      value!.isEmpty) {
                                    return 'Please enter phone number for lead';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),

                          // Location
                          SizedBox(height: 20),
                          Text(
                            "Location",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: locationController,
                                decoration: InputDecoration(
                                  focusedBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.grey),
                                  ),
                                  hintText: 'Enter Location',
                                  hintStyle: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                onChanged: (value) async {
                                  location = value;
                                  if (value.isNotEmpty) {
                                    setState(() {
                                      _isSearchingLocation = true;
                                    });
                                    final predictions =
                                        await fetchPlacePredictions(value);
                                    setState(() {
                                      _placePredictions = predictions;
                                      _isSearchingLocation = false;
                                    });
                                  } else {
                                    setState(() {
                                      _placePredictions = [];
                                    });
                                  }
                                },
                                validator: (value) {
                                  if (value?.isEmpty ?? true)
                                    return 'Please enter location';
                                  return null;
                                },
                              ),
                              if (_isSearchingLocation)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: LinearProgressIndicator(
                                    color: Colors.green,
                                  ),
                                ),
                              if (_placePredictions.isNotEmpty)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  constraints: BoxConstraints(maxHeight: 200),
                                  child: ListView(
                                    shrinkWrap: true,
                                    children:
                                        _placePredictions
                                            .map(
                                              (prediction) => ListTile(
                                                title: Text(
                                                  prediction['description']!,
                                                ),
                                                onTap: () async {
                                                  setState(() {
                                                    _placePredictions = [];
                                                  });
                                                  final fullAddress =
                                                      await fetchFullAddressWithPostal(
                                                        prediction['place_id']!,
                                                      );
                                                  setState(() {
                                                    locationController.text =
                                                        fullAddress.isNotEmpty
                                                            ? fullAddress
                                                            : prediction['description']!;
                                                    location =
                                                        locationController.text;
                                                  });
                                                },
                                              ),
                                            )
                                            .toList(),
                                  ),
                                ),
                            ],
                          ),

                          // Time Range Section
                          SizedBox(height: 20),
                          Text(
                            "Time Range",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              // From Time
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final TimeOfDay? picked =
                                        await showTimePicker(
                                          context: context,
                                          initialTime:
                                              fromTime ?? TimeOfDay.now(),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: const Color.fromRGBO(
                                                    159,
                                                    215,
                                                    5,
                                                    1,
                                                  ),
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );

                                    if (picked != null) {
                                      setState(() {
                                        fromTime = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      color: Colors.grey.shade50,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          fromTime != null
                                              ? fromTime!.format(context)
                                              : "From",
                                          style: GoogleFonts.roboto(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                fromTime != null
                                                    ? Colors.black
                                                    : Colors.grey,
                                          ),
                                        ),
                                        Icon(
                                          Icons.access_time,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              // To Time
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final TimeOfDay? picked =
                                        await showTimePicker(
                                          context: context,
                                          initialTime:
                                              toTime ?? TimeOfDay.now(),
                                          builder: (context, child) {
                                            return Theme(
                                              data: Theme.of(context).copyWith(
                                                colorScheme: ColorScheme.light(
                                                  primary: const Color.fromRGBO(
                                                    159,
                                                    215,
                                                    5,
                                                    1,
                                                  ),
                                                ),
                                              ),
                                              child: child!,
                                            );
                                          },
                                        );

                                    if (picked != null) {
                                      setState(() {
                                        toTime = picked;
                                      });
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                      color: Colors.grey.shade50,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          toTime != null
                                              ? toTime!.format(context)
                                              : "To",
                                          style: GoogleFonts.roboto(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                toTime != null
                                                    ? Colors.black
                                                    : Colors.grey,
                                          ),
                                        ),
                                        Icon(
                                          Icons.access_time,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Description
                          SizedBox(height: 20),
                          Text(
                            "Description",
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          TextFormField(
                            controller: descriptionController,
                            cursorColor: Theme.of(context).dividerColor,
                            maxLines: 4,
                            decoration: InputDecoration(
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              hintText: 'Enter Description',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                            ),
                            onSaved: (value) => salesDescription = value ?? '',
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Please enter description';
                              return null;
                            },
                          ),

                          // Notes (for Lead)
                          if (selectedValue == 'Lead')
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 20),
                                Text(
                                  "Notes",
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: notesController,
                                  cursorColor: Theme.of(context).dividerColor,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    hintText: 'Enter Additional Notes',
                                    hintStyle: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                                  onSaved: (value) => notes = value,
                                ),
                              ],
                            ),

                          // Submit Button
                          SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromRGBO(
                                  159,
                                  215,
                                  5,
                                  1,
                                ),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                isEditing
                                    ? "Update Appointment"
                                    : "Create Appointment",
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  // Show confirmation dialog before creating/updating appointment
  void _showDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isEditing ? "Update Appointment?" : "Create Appointment?",
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
          content: Text(
            isEditing
                ? "Are you sure you want to update this appointment?"
                : "Are you sure you want to create this appointment?",
            style: GoogleFonts.roboto(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "Cancel",
                style: GoogleFonts.roboto(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _createEvent();
              },
              child: Text(
                isEditing ? "Update" : "Create",
                style: GoogleFonts.roboto(
                  color: const Color.fromRGBO(159, 215, 5, 1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
