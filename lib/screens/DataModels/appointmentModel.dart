class AppointmentModel {
  final String date; // e.g., '2025-05-05'
  final String startTime;
  final String endTime;
  final String customer;
  final String location;
  final String ownerName;
  final String
  status; // Lead status ('new', 'contacted', 'qualified', 'converted') or appointment status
  final String ownerID;
  final String jobPrice;
  final String jobDescription;
  final String recordType; // 'Lead' or 'Sale'
  final String? email;
  final String? phone;
  final String? notes;
  final String? leadStatus; // Specific lead status if recordType is 'Lead'
  final String? createdAt;

  String? id; // Document ID for easy reference
  String? leadId; // Reference to original lead if converted from lead

  AppointmentModel({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.customer,
    required this.location,
    required this.ownerName,
    required this.status,
    required this.ownerID,
    required this.jobPrice,
    required this.jobDescription,
    required this.recordType,
    this.email,
    this.phone,
    this.notes,
    this.leadStatus,
    this.createdAt,
    this.id,
    this.leadId,
  });

  factory AppointmentModel.fromJson(
    Map<String, dynamic> json, {
    String? docId,
  }) {
    return AppointmentModel(
      date: json['date'],
      startTime: json['startTime'],
      endTime: json['endTime'],
      customer: json['customer'],
      location: json['location'],
      ownerName: json['ownerName'],
      status: json['status'],
      ownerID: json['ownerID'],
      jobPrice: json['jobprice'] ?? json['jobPrice'],
      jobDescription: json['jobDescription'],
      recordType: json['recordType'],
      email: json['email'],
      phone: json['phone'],
      notes: json['notes'],
      leadStatus: json['leadStatus'],
      createdAt: json['createdAt'],
      id: docId,
      leadId: json['leadId'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'customer': customer,
      'location': location,
      'ownerName': ownerName,
      'status': status,
      'ownerID': ownerID,
      'jobprice': jobPrice, // Note: matching the casing in fromJson
      'jobDescription': jobDescription,
      'recordType': recordType,
    };

    // Add optional fields if they exist
    if (email != null) json['email'] = email;
    if (phone != null) json['phone'] = phone;
    if (notes != null) json['notes'] = notes;
    if (leadStatus != null) json['leadStatus'] = leadStatus;
    if (createdAt != null) json['createdAt'] = createdAt;
    if (leadId != null) json['leadId'] = leadId;

    return json;
  }

  // Create an appointment from a lead
  factory AppointmentModel.fromLead(
    LeadModel lead, {
    required String date,
    required String startTime,
    required String endTime,
    required String ownerName,
    required String jobPrice,
    required String jobDescription,
    String status = 'Scheduled',
  }) {
    return AppointmentModel(
      date: date,
      startTime: startTime,
      endTime: endTime,
      customer: lead.name,
      location: '', // Will need to be filled in
      ownerName: ownerName,
      status: status,
      ownerID: lead.ownerID,
      jobPrice: jobPrice,
      jobDescription: jobDescription,
      recordType: 'Lead',
      email: lead.email,
      phone: lead.phone,
      notes: lead.notes,
      leadStatus: lead.status,
      createdAt: lead.createdAt,
      leadId: lead.id,
    );
  }
}

class LeadModel {
  final String name;
  final String email;
  final String phone;
  final String notes;
  final String status; // e.g., 'new', 'contacted', 'qualified', 'converted'
  final String ownerID;
  final String createdAt;
  String? id; // Document ID for easy reference

  LeadModel({
    required this.name,
    required this.email,
    required this.phone,
    required this.notes,
    required this.status,
    required this.ownerID,
    required this.createdAt,
    this.id,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    return LeadModel(
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      notes: json['notes'],
      status: json['status'],
      ownerID: json['ownerID'],
      createdAt: json['createdAt'],
      id: docId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'notes': notes,
      'status': status,
      'ownerID': ownerID,
      'createdAt': createdAt,
    };
  }
}
