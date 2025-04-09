import 'package:adboard/modals/ad_modal.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class AdAnalysisScreen extends StatefulWidget {
  final AdModel ad;

  const AdAnalysisScreen({Key? key, required this.ad}) : super(key: key);

  @override
  State<AdAnalysisScreen> createState() => _AdAnalysisScreenState();
}

class _AdAnalysisScreenState extends State<AdAnalysisScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  String _analysisResult = '';

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _analyzeAd() async {
    if (_queryController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _analysisResult = '';
    });

    try {
      // Initialize Gemini
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: 'AIzaSyCEyQVYuzJDzs8ZqFe8CHLScOVWXstuN1Q', // Replace with your actual API key
      );

      // Create prompt
      final prompt = '''
        Analyze this advertisement placement:
        Location: ${widget.ad.location}
        Price: ${widget.ad.price} PKR
        Type: ${widget.ad.category}
        Size: ${widget.ad.size}
        User Query: ${_queryController.text}

        Please provide a detailed accurate analysis of 2-3 lines in the following format(dont use * for bolding):
        Suggestion:-
        [Your suggestion]
        
        Traffic Analyst:-
        [Traffic analysis, best if mention in number, if have accurate data of location: ${widget.ad.location}, else mention range ]
        
        Peak Hours:-
        [Peak hours analysis, best if have accurate timings-hours else mention morning, evening, etc.]
      ''';

      // Generate content
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      setState(() {
        _analysisResult = response.text ?? 'No response generated';
      });
    } catch (e) {
      setState(() {
        _analysisResult = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ad Analysis'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Ad Details Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ad Details',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Location: ${widget.ad.location}'),
                    Text('Price: ${widget.ad.price} PKR'),
                    Text('Type: ${widget.ad.category}'),
                    Text('Size: ${widget.ad.size}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Query Input
            TextField(
              controller: _queryController,
              decoration: InputDecoration(
                labelText: 'Enter your query',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: _analyzeAd,
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Analysis Result
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          controller: _scrollController,
                          child: Text(
                            _analysisResult.isEmpty
                                ? 'Enter a query to analyze the ad placement'
                                : _analysisResult,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 