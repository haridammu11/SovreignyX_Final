import 'package:flutter/material.dart';
import '../services/ai_course_service.dart';
import '../models/quiz_question.dart';


class QuizScreen extends StatefulWidget {
  final String courseTitle;
  final List<QuizQuestion> questions;

  const QuizScreen({
    super.key, 
    required this.courseTitle, 
    required this.questions
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOptionIndex;
  bool _isAnswerChecked = false;

  void _checkAnswer() {
    if (_selectedOptionIndex == null) return;

    setState(() {
      _isAnswerChecked = true;
      if (_selectedOptionIndex == widget.questions[_currentIndex].correctOptionIndex) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedOptionIndex = null;
        _isAnswerChecked = false;
      });
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Quiz Completed!'),
        content: Text(
          'You scored $_score / ${widget.questions.length}\n\n' +
          (_score >= widget.questions.length * 0.7 
             ? 'Great job! You have mastered this course.' 
             : 'Keep learning and try again!'),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Close Quiz Screen
            },
            child: const Text('Finish Course'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.questions[_currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text('Final Quiz: ${widget.courseTitle}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Progress
            LinearProgressIndicator(
              value: (_currentIndex + 1) / widget.questions.length,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${_currentIndex + 1} / ${widget.questions.length}',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Question
            Text(
              question.question,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Options
            ...List.generate(question.options.length, (index) {
              final isSelected = _selectedOptionIndex == index;
              final isCorrect = index == question.correctOptionIndex;
              final showColor = _isAnswerChecked && (isSelected || isCorrect);
              
              Color? cardColor;
              if (showColor) {
                 if (isCorrect) cardColor = Colors.green.shade100;
                 if (isSelected && !isCorrect) cardColor = Colors.red.shade100;
              } else if (isSelected) {
                 cardColor = Colors.blue.shade50;
              }

              return Card(
                color: cardColor,
                elevation: isSelected ? 4 : 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Colors.blue : Colors.transparent, 
                    width: 2
                  ),
                ),
                child: InkWell(
                  onTap: _isAnswerChecked ? null : () {
                    setState(() {
                      _selectedOptionIndex = index;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isSelected ? Colors.blue : Colors.grey.shade300,
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C...
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            question.options[index],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        if (_isAnswerChecked && isCorrect)
                           const Icon(Icons.check_circle, color: Colors.green),
                        if (_isAnswerChecked && isSelected && !isCorrect)
                           const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),

            // Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedOptionIndex == null 
                    ? null 
                    : (_isAnswerChecked ? _nextQuestion : _checkAnswer),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  )
                ),
                child: Text(
                  _isAnswerChecked 
                      ? (_currentIndex == widget.questions.length - 1 ? 'See Results' : 'Next Question') 
                      : 'Submit Answer',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
