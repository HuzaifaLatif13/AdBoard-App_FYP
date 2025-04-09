import 'package:flutter/material.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'FAQ',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildFAQSection(
            'General Questions',
            [
              {
                'question': 'What is AdBoard?',
                'answer':
                    'AdBoard is a platform that connects advertisers with advertising space owners. It allows you to book billboards, transit ads, and in-store advertising spaces easily and efficiently.'
              },
              {
                'question': 'How do I book an advertising space?',
                'answer':
                    'To book an advertising space, simply browse through available listings, select the one you\'re interested in, and click "Book Now". Follow the booking process to submit your request. The space owner will review and approve your booking.'
              },
              {
                'question': 'What types of advertising spaces are available?',
                'answer':
                    'We offer various types of advertising spaces including:\n• Billboards\n• Transit advertising (bus stops, train stations)\n• In-store displays\n• Digital billboards'
              },
            ],
          ),
          _buildFAQSection(
            'Booking & Payment',
            [
              {
                'question': 'What payment methods are accepted?',
                'answer':
                    'We accept various payment methods including credit/debit cards and bank transfers. Payment details will be provided after your booking is approved.'
              },
              {
                'question': 'Can I cancel my booking?',
                'answer':
                    'Cancellation policies vary by space owner. Please review the specific terms before booking. Generally, cancellations made 48 hours before the start date may be eligible for a refund.'
              },
              {
                'question': 'How long can I book a space for?',
                'answer':
                    'Booking duration varies by space. Most spaces can be booked for a minimum of one week and a maximum of several months. Check the specific listing for available durations.'
              },
            ],
          ),
          _buildFAQSection(
            'For Space Owners',
            [
              {
                'question': 'How do I list my advertising space?',
                'answer':
                    'To list your space:\n1. Create an account\n2. Click on "Add" in the bottom navigation\n3. Fill in the details about your space\n4. Add high-quality photos\n5. Set your pricing and availability'
              },
              {
                'question': 'How do I manage bookings?',
                'answer':
                    'You can manage all bookings through the "My Ads" section. Here you can view booking requests, approve or decline them, and communicate with advertisers.'
              },
              {
                'question': 'What commission does AdBoard charge?',
                'answer':
                    'AdBoard charges a small commission on successful bookings. The exact percentage may vary by region and type of advertising space. Please refer to our terms of service for detailed information.'
              },
            ],
          ),
          _buildFAQSection(
            'Technical Support',
            [
              {
                'question': 'How do I contact support?',
                'answer':
                    'For support, you can:\n• Email us at support@adboard.com\n• Use the contact form in the app\n• Reach out through our social media channels'
              },
              {
                'question': 'What should I do if I find inappropriate content?',
                'answer':
                    'If you find any inappropriate content or listings that violate our terms of service, please report it immediately using the report button or contact our support team.'
              },
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildFAQSection(String title, List<Map<String, String>> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        ...questions
            .map((q) => _buildExpandableFAQ(q['question']!, q['answer']!)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExpandableFAQ(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
