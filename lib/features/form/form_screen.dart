import 'package:flutter/material.dart';
import 'package:pramern/features/form/form_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormScreen extends StatefulWidget {
  final String formId, assignId, assigneeId;
  const FormScreen({
    super.key,
    required this.formId,
    required this.assignId,
    required this.assigneeId,
  });

  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final FormController _formController = FormController();
  int currentStep = 0;
  bool isLoading = true;
  String formTitle = '';
  List<Map<String, dynamic>> sections = [];
  bool isChange = false;
  final ScrollController _scrollController = ScrollController();

  // Define theme colors
  final Color primaryColor = const Color(0xFF7367F0);
  final Color errorColor = const Color(0xFFEA5455);
  final Color successColor = const Color(0xFF28C76F);

  @override
  void initState() {
    super.initState();
    loadFormData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> loadFormData() async {
    setState(() => isLoading = true);
    try {
      final formData = await _formController.fetchFormData(widget.formId);
      if (formData != null) {
        setState(() {
          formTitle = formData['form']['form_name'] ?? '';
          sections = List<Map<String, dynamic>>.from(formData['sections'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading form data: $e');
      _showErrorSnackBar('ไม่สามารถโหลดข้อมูลแบบฟอร์มได้');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void handleNextStep() {
    if (validateForm() && currentStep < sections.length - 1) {
      setState(() {
        currentStep++;
      });
      // Scroll to top when moving to next section
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  bool validateForm() {
    bool isValid = true;
    var currentSectionQuestions = sections[currentStep]['question_id'] as List;

    for (var question in currentSectionQuestions) {
      bool isRequired = question['qt_required'] ?? false;
      if (!isRequired) continue;

      switch (question['qt_type']) {
        case 'text':
        case 'paragraph':
          if ((question['answer'] ?? '').toString().trim().isEmpty) {
            setState(() {
              question['error'] = true;
              question['errorMessage'] = 'กรุณากรอกข้อมูลในช่องนี้';
            });
            isValid = false;
          }
          break;

        case 'multiple':
          if (question['answer'] == null) {
            setState(() {
              question['error'] = true;
              question['errorMessage'] = 'กรุณาเลือกตัวเลือก';
            });
            isValid = false;
          }
          break;

        case 'grid':
          bool allRowsSelected = true;
          for (var row in question['qt_row']) {
            if (row['selected'] == null) {
              allRowsSelected = false;
              break;
            }
          }

          if (!allRowsSelected) {
            setState(() {
              question['error'] = true;
              question['errorMessage'] = 'กรุณาเลือกคะแนนให้ครบทุกหัวข้อ';
            });
            isValid = false;
          }
          break;
      }
    }

    if (!isValid) {
      _showErrorSnackBar('กรุณากรอกข้อมูลให้ครบถ้วน');
    }

    return isValid;
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(8),
      ),
    );
  }

  List<Map<String, dynamic>> formatSectionsData() {
    return sections.map<Map<String, dynamic>>((section) {
      return {
        '_id': section['_id'],
        'title': section['fs_name'],
        'description': section['fs_description'],
        'isCalulate': section['fs_is_calculate'],
        'isVisibleOnHistory': section['fs_is_visible_on_history'],
        'formula': section['fs_formula'],
        'score': section['fs_score'],
        'questions': (section['question_id'] as List)
            .map<Map<String, dynamic>>((question) {
          return {
            'id': question['_id'],
            'question': question['qt_name'],
            'type': question['qt_type'],
            'answer': question['answer'] ?? "",
            'required': question['qt_required'],
            'kpi_id': question['kpi_id'],
            'choicesAll': question['qt_choices'] != null
                ? (question['qt_choices'] as List)
                    .map<String>((choice) => choice['qt_choice'])
                    .toList()
                : [],
            'gridRows': question['qt_row'] != null
                ? (question['qt_row'] as List).map<Map<String, dynamic>>((row) {
                    return {
                      'row': row is String ? row : row['name'],
                      'selected': row is String ? null : row['selected'],
                    };
                  }).toList()
                : [],
            'gridColumns': question['qt_column'] != null
                ? (question['qt_column'] as List)
                    .map<Map<String, dynamic>>((column) {
                    return {'name': column['name'], 'value': column['value']};
                  }).toList()
                : [],
          };
        }).toList(),
      };
    }).toList();
  }

  void submitEvaluationForm() async {
    if (validateForm()) {
      try {
        setState(() => isLoading = true);

        final prefs = await SharedPreferences.getInstance();
        final String? userId = prefs.getString('user_id');

        final formattedSections = formatSectionsData();
        final assignData = {'user_id': userId, 'sections': formattedSections};

        final success = await _formController.submitForm(
          widget.assignId,
          widget.assigneeId,
          assignData,
        );

        setState(() => isLoading = false);

        if (success) {
          _showSuccessSnackBar('ส่งแบบประเมินเรียบร้อยแล้ว');
          Future.delayed(const Duration(milliseconds: 800), () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          });
        } else {
          _showErrorSnackBar('เกิดข้อผิดพลาดในการส่งแบบประเมิน');
        }
      } catch (e) {
        setState(() => isLoading = false);
        _showErrorSnackBar('เกิดข้อผิดพลาด: ${e.toString()}');
      }
    }
  }

  void backToForm() {
    if (isChange) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ยกเลิกการทำประเมิน'),
          content: const Text('คุณต้องการยกเลิกการทำประเมินหรือไม่?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('ไม่', style: TextStyle(color: primaryColor)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('ใช่', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: backToForm,
        ),
        title: Text(
          formTitle,
          style: const TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: primaryColor),
                    const SizedBox(height: 16),
                    const Text('กำลังโหลดข้อมูล...'),
                  ],
                ),
              )
            : sections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.description_outlined, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text('ไม่พบข้อมูลแบบฟอร์ม', style: TextStyle(fontSize: 18)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                          child: const Text('กลับ'),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Progress indicator
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                sections.length,
                                (index) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Container(
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: index <= currentStep
                                            ? primaryColor
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'ส่วนที่ ${currentStep + 1} จาก ${sections.length}',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: FormSection(
                              section: sections[currentStep],
                              index: currentStep,
                              totalSections: sections.length,
                              primaryColor: primaryColor,
                            ),
                          ),
                        ),
                      ),
                      
                      // Navigation buttons
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (currentStep > 0)
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setState(() => currentStep--),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: BorderSide(color: primaryColor),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    'ย้อนกลับ',
                                    style: TextStyle(color: primaryColor),
                                  ),
                                ),
                              )
                            else
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: backToForm,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    side: const BorderSide(color: Colors.grey),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'ยกเลิก',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: currentStep == sections.length - 1
                                    ? submitEvaluationForm
                                    : handleNextStep,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  currentStep == sections.length - 1
                                      ? 'ส่งแบบประเมิน'
                                      : 'ต่อไป',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class FormSection extends StatefulWidget {
  final Map<String, dynamic> section;
  final int index;
  final int totalSections;
  final Color primaryColor;

  const FormSection({
    super.key,
    required this.section,
    required this.index,
    required this.totalSections,
    required this.primaryColor,
  });

  @override
  State<FormSection> createState() => _FormSectionState();
}

class _FormSectionState extends State<FormSection> {
  @override
  void initState() {
    super.initState();
    _fixDataStructure();
  }

  @override
  void didUpdateWidget(FormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fixDataStructure();
  }

  void _fixDataStructure() {
    if (widget.section['question_id'] != null) {
      for (var question in widget.section['question_id']) {
        if (question['qt_type'] == 'grid' && question['qt_row'] != null) {
          for (int i = 0; i < question['qt_row'].length; i++) {
            var row = question['qt_row'][i];

            if (row is String) {
              question['qt_row'][i] = {'name': row, 'selected': null};
            } else if (row is Map) {
              if (row['selected'] != null && row['selected'] is! int) {
                try {
                  row['selected'] = int.tryParse(row['selected'].toString());
                } catch (e) {
                  row['selected'] = null;
                }
              }
            }
          }
        }
      }
    }
  }

  int? parseIntValue(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return null;
      }
    }
    try {
      return int.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        if (widget.section['fs_name'] != null &&
            widget.section['fs_name'].isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.section['fs_name'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.section['fs_description'] != null &&
                    widget.section['fs_description'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      widget.section['fs_description'] ?? '',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
              ],
            ),
          ),

        // Questions
        ...((widget.section['question_id'] ?? []) as List).map<Widget>((question) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Question title with required indicator
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            text: question['qt_name'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            children: [
                              if (question['qt_required'] ?? false)
                                const TextSpan(
                                  text: ' *',
                                  style: TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Different question types
                  if (question['qt_type'] == 'text' ||
                      question['qt_type'] == 'paragraph')
                    _buildTextInput(question),
                  if (question['qt_type'] == 'multiple')
                    _buildMultipleChoice(question),
                  if (question['qt_type'] == 'grid')
                    _buildGridQuestion(question),

                  // Error message
                  if (question['error'] ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            question['errorMessage'] ?? 'กรุณากรอกข้อมูลให้ครบถ้วน',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTextInput(Map<String, dynamic> question) {
    return TextFormField(
      initialValue: question['answer'] ?? '',
      decoration: InputDecoration(
        hintText: question['qt_type'] == 'paragraph'
            ? 'พิมพ์คำตอบของคุณที่นี่...'
            : 'กรอกคำตอบสั้นๆ',
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: widget.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      onChanged: (value) {
        setState(() {
          question['answer'] = value;
          question['error'] = false;
        });

        final formState = context.findAncestorStateOfType<_FormScreenState>();
        if (formState != null) {
          formState.isChange = true;
        }
      },
      maxLines: question['qt_type'] == 'paragraph' ? 5 : 1,
      style: const TextStyle(fontSize: 15),
    );
  }

  Widget _buildMultipleChoice(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...(question['qt_choices'] ?? []).map<Widget>((choice) {
          final int index = (question['qt_choices'] ?? []).indexOf(choice);
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border.all(
                color: question['answer'] == index
                    ? widget.primaryColor
                    : Colors.grey[300]!,
              ),
              borderRadius: BorderRadius.circular(8),
              color: question['answer'] == index
                  ? widget.primaryColor.withOpacity(0.05)
                  : Colors.white,
            ),
            child: RadioListTile<int>(
              title: Text(
                choice['qt_choice'] ?? '',
                style: TextStyle(
                  fontWeight: question['answer'] == index
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
              ),
              value: index,
              groupValue: question['answer'] as int?,
              activeColor: widget.primaryColor,
              onChanged: (value) {
                setState(() {
                  question['answer'] = value;
                  question['error'] = false;
                });

                final formState = context.findAncestorStateOfType<_FormScreenState>();
                if (formState != null) {
                  formState.isChange = true;
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildGridQuestion(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: widget.primaryColor.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              // Empty space for row labels
              const SizedBox(width: 150),
              
              // Column headers
              Expanded(
                child: Row(
                  children: (question['qt_column'] ?? []).map<Widget>((column) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          column['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),

        // Table body
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Column(
            children: (question['qt_row'] ?? []).map<Widget>((row) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey[300]!,
                      width: (question['qt_row'].indexOf(row) == 
                              question['qt_row'].length - 1)
                          ? 0
                          : 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Row label
                    Container(
                      width: 150,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.grey[300]!),
                        ),
                        color: Colors.grey[50],
                      ),
                      child: Text(
                        row['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    
                    // Radio options
                    Expanded(
                      child: Row(
                        children: (question['qt_column'] ?? []).map<Widget>((column) {
                          final int? columnValue = parseIntValue(column['value']);
                          return Expanded(
                            child: Center(
                              child: Radio<int?>(
                                value: columnValue,
                                groupValue: parseIntValue(row['selected']),
                                activeColor: widget.primaryColor,
                                onChanged: (int? newValue) {
                                  setState(() {
                                    row['selected'] = newValue.toString();
                                    question['error'] = false;
                                  });

                                  final formState = context.findAncestorStateOfType<_FormScreenState>();
                                  if (formState != null) {
                                    formState.isChange = true;
                                  }
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}