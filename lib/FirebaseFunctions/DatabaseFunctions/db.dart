import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:knox/screens/DataModels/appointmentModel.dart';

class FireStoreMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String v = FirebaseAuth.instance.currentUser!.uid;

  // =========== APPOINTMENT METHODS ===========

  // Create or update an appointment
  Future<String> createOrUpdateAppointment(AppointmentModel appointment) async {
    try {
      final formattedDate = _formatDateForPath(appointment.date);

      final CollectionReference appointmentsRef = _firestore.collection(
        'SalesSchedule/$formattedDate/appointments',
      );

      if (appointment.id != null) {
        // Update existing appointment
        await appointmentsRef.doc(appointment.id).update(appointment.toJson());
        return appointment.id!;
      } else {
        // Create new appointment
        DocumentReference doc = await appointmentsRef.add(appointment.toJson());
        return doc.id;
      }
    } catch (e) {
      throw Exception('Failed to save appointment: $e');
    }
  }

  Future<String> createLead(AppointmentModel appointment, String uid) async {
    try {
      final CollectionReference leadsRef = _firestore.collection(
        'users/$uid/leads',
      );

      if (appointment.id != null) {
        // Update existing appointment
        await leadsRef.doc(appointment.id).update(appointment.toJson());
        return appointment.id!;
      } else {
        // Create new appointment
        DocumentReference doc = await leadsRef.add(appointment.toJson());
        return doc.id;
      }
    } catch (e) {
      throw Exception('Failed to save appointment: $e');
    }
  }

  // Get all appointments for a specific date
  Future<List<AppointmentModel>> getAppointmentsByDate(String date) async {
    try {
      final formattedDate = _formatDateForPath(date);
      final QuerySnapshot snapshot =
          await _firestore
              .collection('SalesSchedule/$formattedDate/appointments')
              .get();

      return snapshot.docs.map((doc) {
        return AppointmentModel.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get appointments: $e');
    }
  }

  // Get all appointments for a specific owner
  Future<List<AppointmentModel>> getAppointmentsByOwner(
    String ownerID, {
    String? startDate,
    String? endDate,
  }) async {
    try {
      List<AppointmentModel> allAppointments = [];

      // If date range is specified
      if (startDate != null && endDate != null) {
        DateTime start = DateTime.parse(startDate);
        DateTime end = DateTime.parse(endDate);

        // Loop through each day in the range
        for (
          DateTime date = start;
          date.isBefore(end.add(Duration(days: 1)));
          date = date.add(Duration(days: 1))
        ) {
          String formattedDate =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          String pathFormattedDate = _formatDateForPath(formattedDate);

          final QuerySnapshot snapshot =
              await _firestore
                  .collection('SalesSchedule/$pathFormattedDate/appointments')
                  .where('ownerID', isEqualTo: ownerID)
                  .get();

          List<AppointmentModel> dayAppointments =
              snapshot.docs.map((doc) {
                return AppointmentModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                  docId: doc.id,
                );
              }).toList();

          allAppointments.addAll(dayAppointments);
        }
      } else {
        // If no date range, we'll need to query each day (potentially expensive)
        // Consider implementing pagination or date limitations for production
        throw Exception('Date range is required for owner appointments query');
      }

      return allAppointments;
    } catch (e) {
      throw Exception('Failed to get owner appointments: $e');
    }
  }

  Future<List<AppointmentModel>> getAppointmentsByRange({
    String? startDate,
    String? endDate,
  }) async {
    try {
      List<AppointmentModel> allAppointments = [];

      // If date range is specified
      if (startDate != null && endDate != null) {
        DateTime start = DateTime.parse(startDate);
        DateTime end = DateTime.parse(endDate);

        // Loop through each day in the range
        for (
          DateTime date = start;
          date.isBefore(end.add(Duration(days: 1)));
          date = date.add(Duration(days: 1))
        ) {
          String formattedDate =
              "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
          String pathFormattedDate = _formatDateForPath(formattedDate);

          final QuerySnapshot snapshot =
              await _firestore
                  .collection('SalesSchedule/$pathFormattedDate/appointments')
                  .get();

          List<AppointmentModel> dayAppointments =
              snapshot.docs.map((doc) {
                return AppointmentModel.fromJson(
                  doc.data() as Map<String, dynamic>,
                  docId: doc.id,
                );
              }).toList();

          allAppointments.addAll(dayAppointments);
        }
      } else {
        // If no date range, we'll need to query each day (potentially expensive)
        // Consider implementing pagination or date limitations for production
        throw Exception('Date range is required for owner appointments query');
      }

      return allAppointments;
    } catch (e) {
      throw Exception('Failed to get owner appointments: $e');
    }
  }

  // Get a specific appointment
  Future<AppointmentModel?> getAppointment(
    String date,
    String appointmentId,
  ) async {
    try {
      final formattedDate = _formatDateForPath(date);
      final DocumentSnapshot doc =
          await _firestore
              .collection('SalesSchedule/$formattedDate/appointments')
              .doc(appointmentId)
              .get();

      if (doc.exists) {
        return AppointmentModel.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to get appointment: $e');
    }
  }

  // Delete an appointment
  Future<void> deleteAppointment(String date, String appointmentId) async {
    try {
      final formattedDate = _formatDateForPath(date);
      await _firestore
          .collection('SalesSchedule/$formattedDate/appointments')
          .doc(appointmentId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete appointment: $e');
    }
  }

  // Update appointment status
  Future<void> updateAppointmentStatus(
    String date,
    String appointmentId,
    String newStatus,
  ) async {
    try {
      final formattedDate = _formatDateForPath(date);
      await _firestore
          .collection('SalesSchedule/$formattedDate/appointments')
          .doc(appointmentId)
          .update({'status': newStatus});
    } catch (e) {
      throw Exception('Failed to update appointment status: $e');
    }
  }

  // =========== LEAD METHODS ===========

  // Create or update a lead
  Future<String> createOrUpdateLead(LeadModel lead) async {
    try {
      final CollectionReference leadsRef = _firestore.collection(
        'Leads/${lead.ownerID}/leads',
      );

      if (lead.id != null) {
        // Update existing lead
        await leadsRef.doc(lead.id).update(lead.toJson());
        return lead.id!;
      } else {
        // Create new lead with current timestamp if not provided
        final leadData = lead.toJson();
        if (leadData['createdAt'] == null) {
          leadData['createdAt'] = DateTime.now().toIso8601String();
        }
        DocumentReference doc = await leadsRef.add(leadData);
        return doc.id;
      }
    } catch (e) {
      throw Exception('Failed to save lead: $e');
    }
  }

  // Convert a lead to an appointment
  Future<String> convertLeadToAppointment(
    LeadModel lead,
    String date,
    String startTime,
    String endTime,
    String ownerName,
    String jobPrice,
    String jobDescription,
  ) async {
    try {
      // Create appointment from lead
      final appointment = AppointmentModel.fromLead(
        lead,
        date: date,
        startTime: startTime,
        endTime: endTime,
        ownerName: ownerName,
        jobPrice: jobPrice,
        jobDescription: jobDescription,
      );

      // Save the appointment
      final appointmentId = await createOrUpdateAppointment(appointment);

      // Optionally update the lead status to indicate it's been converted
      await updateLeadStatus(lead.ownerID, lead.id!, 'converted');

      return appointmentId;
    } catch (e) {
      throw Exception('Failed to convert lead to appointment: $e');
    }
  }

  // Get all leads for a specific owner
  Future<List<AppointmentModel>> getLeadsByOwner(String ownerID) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore.collection('users/$ownerID/leads').get();

      return snapshot.docs.map((doc) {
        return AppointmentModel.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get leads: $e');
    }
  }

  // Get leads by status for a specific owner
  Future<List<AppointmentModel>> getLeadsByStatus(
    String ownerID,
    String status,
  ) async {
    try {
      final QuerySnapshot snapshot =
          await _firestore
              .collection('users/$ownerID/leads')
              .where('status', isEqualTo: status)
              .get();

      return snapshot.docs.map((doc) {
        return AppointmentModel.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to get leads by status: $e');
    }
  }

  // Get a specific lead
  Future<AppointmentModel?> getLead(String ownerID, String leadId) async {
    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users/$ownerID/leads').doc(leadId).get();

      if (doc.exists) {
        return AppointmentModel.fromJson(
          doc.data() as Map<String, dynamic>,
          docId: doc.id,
        );
      } else {
        return null;
      }
    } catch (e) {
      throw Exception('Failed to get lead: $e');
    }
  }

  // Delete a lead
  Future<void> deleteLead(String ownerID, String leadId) async {
    try {
      await _firestore.collection('users/$ownerID/leads').doc(leadId).delete();
    } catch (e) {
      throw Exception('Failed to delete lead: $e');
    }
  }

  // Update lead status
  Future<void> updateLeadStatus(
    String ownerID,
    String leadId,
    String newStatus,
  ) async {
    try {
      await _firestore.collection('users/$ownerID/leads').doc(leadId).update({
        'status': newStatus,
      });
    } catch (e) {
      throw Exception('Failed to update lead status: $e');
    }
  }

  // =========== UTILITY METHODS ===========

  // Format date string to match the required path format (DD-MM-YYYY)
  String _formatDateForPath(String dateString) {
    // Parse the full ISO date string (handles format like "2025-05-14 00:00:00.000Z")
    final DateTime date = DateTime.parse(dateString);

    // Format to YYYY-MM-DD
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }
}
