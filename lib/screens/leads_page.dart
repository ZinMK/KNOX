import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:knox/FirebaseFunctions/DatabaseFunctions/db.dart';
import 'package:knox/screens/DataModels/appointmentModel.dart';
import 'package:knox/screens/createApptPage.dart';

class LeadsPage extends StatefulWidget {
  const LeadsPage({Key? key}) : super(key: key);

  @override
  _LeadsPageState createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage> {
  final FireStoreMethods _fireStoreMethods = FireStoreMethods();
  String? _userId;
  List<String> statusFilters = ["All", "Quoted", "GotContact", "NextYear"];
  String selectedStatus = "All";

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'My Leads',
          style: GoogleFonts.roboto(
            color: const Color.fromRGBO(159, 215, 5, 1),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Status filter dropdown
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: DropdownButton<String>(
              value: selectedStatus,
              underline: Container(),
              items:
                  statusFilters.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        status,
                        style: GoogleFonts.roboto(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    );
                  }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    selectedStatus = newValue;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body:
          _userId == null
              ? const Center(child: CircularProgressIndicator())
              : StreamBuilder<QuerySnapshot>(
                stream:
                    selectedStatus == "All"
                        ? FirebaseFirestore.instance
                            .collection('users/$_userId/leads')
                            .snapshots()
                        : FirebaseFirestore.instance
                            .collection('users/$_userId/leads')
                            .where('status', isEqualTo: selectedStatus)
                            .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final leads = snapshot.data?.docs ?? [];

                  if (leads.isEmpty) {
                    return Center(
                      child: Text(
                        'No leads found',
                        style: GoogleFonts.roboto(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: leads.length,
                    itemBuilder: (context, index) {
                      final lead = AppointmentModel.fromJson(
                        leads[index].data() as Map<String, dynamic>,
                        docId: leads[index].id,
                      );

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            lead.customer,
                            style: GoogleFonts.roboto(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text(
                                'Phone: ${lead.phone ?? 'N/A'}',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status: ${lead.status}',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Notes: ${lead.notes ?? 'No notes'}',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              switch (value) {
                                case 'edit':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => CreateApptPage(
                                            data: lead,
                                            isFromLead: true,
                                          ),
                                    ),
                                  );
                                  break;
                                case 'delete':
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder:
                                        (context) => AlertDialog(
                                          title: const Text('Delete Lead'),
                                          content: const Text(
                                            'Are you sure you want to delete this lead?',
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    false,
                                                  ),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed:
                                                  () => Navigator.pop(
                                                    context,
                                                    true,
                                                  ),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                  );

                                  if (confirm == true) {
                                    await _fireStoreMethods.deleteLead(
                                      _userId!,
                                      lead.id!,
                                    );
                                  }
                                  break;
                              }
                            },
                            itemBuilder:
                                (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Text('Edit'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CreateApptPage(
                                      data: lead,
                                      isFromLead: true,
                                    ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
    );
  }
}
