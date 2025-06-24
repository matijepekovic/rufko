import 'package:flutter/foundation.dart';
import '../models/business/customer.dart';

/// Test data for customer development and testing
/// This data will be populated during development but removed for production
class CustomerTestData {
  static const bool _isTestDataEnabled = kDebugMode;

  /// Generate sample customers for testing
  static List<Customer> getSampleCustomers() {
    if (!_isTestDataEnabled) return [];

    return [
      Customer(
        name: "John Smith",
        phone: "555-0101",
        email: "john.smith@example.com",
        streetAddress: "123 Main Street",
        city: "Seattle",
        stateAbbreviation: "WA",
        zipCode: "98101",
        notes: "Interested in complete roof replacement. Has a two-story colonial home.",
        communicationHistory: [
          "2024-12-20T10:30:00.000Z: 📞 Initial contact - Customer interested in roof replacement",
          "2024-12-21T14:15:00.000Z: 📧 Sent preliminary estimate via email",
          "2024-12-22T09:00:00.000Z: 📅 FOLLOW-UP (2024-12-28): Schedule site visit"
        ],
      ),
      
      Customer(
        name: "Jane Doe",
        phone: "555-0102",
        email: "jane.doe@gmail.com",
        streetAddress: "456 Oak Avenue",
        city: "Portland",
        stateAbbreviation: "OR",
        zipCode: "97201",
        notes: "Small leak repair needed in kitchen area. Prefers eco-friendly materials.",
        communicationHistory: [
          "2024-12-19T16:45:00.000Z: 📞 Emergency call about leak",
          "2024-12-20T08:30:00.000Z: 🏠 Site visit completed - small repair needed",
          "2024-12-20T11:00:00.000Z: 📧 Quote sent for repair work"
        ],
      ),
      
      Customer(
        name: "Bob Wilson",
        phone: "555-0103",
        email: "bob.wilson@outlook.com",
        streetAddress: "789 Pine Road",
        city: "Tacoma",
        stateAbbreviation: "WA",
        zipCode: "98402",
        notes: "Commercial property - warehouse roof inspection and potential replacement.",
        communicationHistory: [
          "2024-12-18T13:20:00.000Z: 📞 Commercial inquiry received",
          "2024-12-19T10:00:00.000Z: 🤝 Meeting scheduled with property manager",
          "2024-12-21T15:30:00.000Z: 🏠 Initial inspection completed"
        ],
      ),
      
      Customer(
        name: "Sarah Johnson",
        phone: "555-0104",
        email: "sarah.j@yahoo.com",
        streetAddress: "321 Cedar Lane",
        city: "Spokane",
        stateAbbreviation: "WA",
        zipCode: "99201",
        notes: "Gutter installation and roof maintenance package.",
        communicationHistory: [
          "2024-12-22T11:15:00.000Z: 📞 Called about gutter installation",
          "2024-12-22T14:30:00.000Z: 📧 Sent information packet"
        ],
      ),
      
      Customer(
        name: "Michael Brown",
        phone: "555-0105",
        email: "m.brown@company.com",
        streetAddress: "654 Maple Drive",
        city: "Bellevue",
        stateAbbreviation: "WA",
        zipCode: "98004",
        notes: "High-end residential. Looking for premium materials and extended warranty.",
        communicationHistory: [
          "2024-12-17T09:45:00.000Z: 📞 Referral from previous customer",
          "2024-12-18T16:00:00.000Z: 🏠 Site visit - measured roof area",
          "2024-12-19T10:30:00.000Z: 📧 Premium material options sent",
          "2024-12-20T12:00:00.000Z: 🤝 Meeting to discuss timeline"
        ],
      ),
      
      Customer(
        name: "Lisa Anderson",
        phone: "555-0106",
        email: "lisa.anderson@email.com",
        streetAddress: "987 Birch Street",
        city: "Olympia",
        stateAbbreviation: "WA",
        zipCode: "98501",
        notes: "Insurance claim work. Storm damage from recent windstorm.",
        communicationHistory: [
          "2024-12-21T07:30:00.000Z: 📞 Emergency call - storm damage",
          "2024-12-21T09:00:00.000Z: 🏠 Emergency assessment completed",
          "2024-12-21T13:45:00.000Z: 📧 Insurance documentation sent"
        ],
      ),
      
      Customer(
        name: "David Chen",
        phone: "555-0107",
        email: "d.chen@tech.com",
        streetAddress: "147 Valley View",
        city: "Redmond",
        stateAbbreviation: "WA",
        zipCode: "98052",
        notes: "New construction. Custom home with complex roof design.",
        communicationHistory: [
          "2024-12-16T14:20:00.000Z: 📞 New construction consultation",
          "2024-12-17T11:00:00.000Z: 🤝 Meeting with architect",
          "2024-12-18T15:15:00.000Z: 📧 Custom design proposal sent"
        ],
      ),
      
      Customer(
        name: "Emily Rodriguez",
        phone: "555-0108", 
        email: "emily.r@gmail.com",
        streetAddress: "258 Highland Ave",
        city: "Vancouver",
        stateAbbreviation: "WA",
        zipCode: "98661",
        notes: "Solar panel installation prep. Roof needs reinforcement.",
        communicationHistory: [
          "2024-12-20T13:00:00.000Z: 📞 Solar prep consultation",
          "2024-12-21T10:15:00.000Z: 🏠 Structural assessment",
          "2024-12-21T16:30:00.000Z: 📅 FOLLOW-UP (2024-12-30): Coordinate with solar company"
        ],
      ),
      
      Customer(
        name: "Robert Taylor",
        phone: "555-0109",
        email: "r.taylor@business.com",
        streetAddress: "369 Industrial Way",
        city: "Kent",
        stateAbbreviation: "WA",
        zipCode: "98032",
        notes: "Multi-building commercial complex. Phased replacement project.",
        communicationHistory: [
          "2024-12-15T08:00:00.000Z: 📞 Large commercial inquiry",
          "2024-12-16T13:30:00.000Z: 🏠 Site survey of all buildings",
          "2024-12-17T09:45:00.000Z: 📧 Phased project proposal sent",
          "2024-12-19T14:00:00.000Z: 🤝 Budget meeting scheduled"
        ],
      ),
      
      Customer(
        name: "Amanda White",
        phone: "555-0110",
        email: "amanda.white@home.com",
        streetAddress: "741 Sunset Boulevard",
        city: "Bellingham",
        stateAbbreviation: "WA",
        zipCode: "98225",
        notes: "Seasonal home maintenance contract. Annual inspection and minor repairs.",
        communicationHistory: [
          "2024-12-19T12:15:00.000Z: 📞 Annual maintenance inquiry",
          "2024-12-20T15:45:00.000Z: 📧 Maintenance package options sent",
          "2024-12-21T11:30:00.000Z: 📝 Contract terms discussed"
        ],
      ),
      
      // Additional customers with different scenarios
      Customer(
        name: "James Wilson",
        phone: "555-0111",
        email: "james.w@email.net",
        streetAddress: "852 River Road",
        city: "Everett",
        stateAbbreviation: "WA",
        zipCode: "98201",
        notes: "Historic home restoration. Requires specialized materials and techniques.",
      ),
      
      Customer(
        name: "Maria Garcia",
        phone: "555-0112",
        email: "maria.garcia@mail.com",
        streetAddress: "963 Mountain View",
        city: "Spokane Valley",
        stateAbbreviation: "WA",
        zipCode: "99206",
        notes: "Budget-conscious customer. Looking for cost-effective solutions.",
      ),
      
      Customer(
        name: "Thomas Lee", 
        phone: "555-0113",
        streetAddress: "159 Lake Shore Drive",
        city: "Kirkland",
        stateAbbreviation: "WA",
        zipCode: "98033",
        notes: "Waterfront property. Special considerations for salt air exposure.",
      ),
      
      Customer(
        name: "Jennifer Davis",
        phone: "555-0114",
        email: "jen.davis@corp.com",
        streetAddress: "753 Business Park",
        city: "Renton",
        stateAbbreviation: "WA",
        zipCode: "98057",
        notes: "Office building. Coordinating with building management.",
      ),
      
      Customer(
        name: "Kevin Murphy",
        phone: "555-0115",
        email: "kevin.murphy@family.net",
        city: "Federal Way",
        stateAbbreviation: "WA",
        zipCode: "98003",
        notes: "Customer prefers text communication. Young family, budget-minded.",
      ),
    ];
  }

  /// Get customers for specific testing scenarios
  static List<Customer> getCustomersForScenario(String scenario) {
    if (!_isTestDataEnabled) return [];

    final allCustomers = getSampleCustomers();
    
    switch (scenario) {
      case 'recent_customers':
        return allCustomers.take(5).toList();
      case 'commercial_customers':
        return allCustomers.where((c) => 
          c.notes?.toLowerCase().contains('commercial') == true ||
          c.notes?.toLowerCase().contains('business') == true
        ).toList();
      case 'emergency_customers':
        return allCustomers.where((c) => 
          c.communicationHistory.any((comm) => 
            comm.toLowerCase().contains('emergency') ||
            comm.toLowerCase().contains('storm')
          )
        ).toList();
      case 'follow_up_customers':
        return allCustomers.where((c) => 
          c.communicationHistory.any((comm) => 
            comm.contains('📅 FOLLOW-UP')
          )
        ).toList();
      default:
        return allCustomers;
    }
  }

  /// Create a single test customer with specific attributes
  static Customer createTestCustomer({
    String? name,
    String? city,
    String? state,
    bool hasEmail = true,
    bool hasFullAddress = true,
    int communicationCount = 2,
  }) {
    if (!_isTestDataEnabled) {
      return Customer(name: "Test Customer");
    }

    return Customer(
      name: name ?? "Test Customer ${DateTime.now().millisecondsSinceEpoch}",
      phone: "555-TEST",
      email: hasEmail ? "test@example.com" : null,
      streetAddress: hasFullAddress ? "123 Test Street" : null,
      city: city ?? (hasFullAddress ? "Test City" : null),
      stateAbbreviation: state ?? (hasFullAddress ? "WA" : null),
      zipCode: hasFullAddress ? "98000" : null,
      notes: "Test customer for development purposes",
      communicationHistory: List.generate(communicationCount, (index) => 
        "${DateTime.now().subtract(Duration(days: index)).toIso8601String()}: 📝 Test communication $index"
      ),
    );
  }
}