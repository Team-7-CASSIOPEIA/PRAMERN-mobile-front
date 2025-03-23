import 'package:flutter/material.dart';
import 'package:pramern_mobile_front/features/form/form_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FormScreen extends StatefulWidget {
  final String formId, assignId, assigneeId;
  const FormScreen(
      {super.key,
      required this.formId,
      required this.assignId,
      required this.assigneeId});

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

  @override
  void initState() {
    super.initState();
    loadFormData();
  }

  Future<void> loadFormData() async {
    setState(() => isLoading = true);
    try {
      final formData = await _formController.fetchFormData(widget.formId);
      if (formData != null) {
        setState(() {
          formTitle = formData['form']['form_name'] ?? '';
          sections =
              List<Map<String, dynamic>>.from(formData['sections'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading form data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void handleNextStep() {
    if (validateForm() && currentStep < sections.length - 1) {
      setState(() {
        currentStep++;
      });
    }
  }

  bool validateForm() {
    bool isValid = true;
    var currentSectionQuestions = sections[currentStep]['question_id'] as List;

    for (var question in currentSectionQuestions) {
      bool isRequired = question['qt_required'] ?? false;
      if (!isRequired) continue; // ข้ามการตรวจสอบถ้าไม่ใช่ฟิลด์ที่จำเป็น

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
      // แสดง snackbar หรือ dialog แจ้งเตือน
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกข้อมูลให้ครบถ้วน'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return isValid;
  }

  // เพิ่มฟังก์ชันนี้ใน _FormScreenState หรือที่ที่เหมาะสม
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

        // ดึง user_id จาก SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final String? userId = prefs.getString('user_id');

        final formattedSections = formatSectionsData();

        // สร้างข้อมูลที่จะส่งไป API
        final assignData = {'user_id': userId, 'sections': formattedSections};

        // ส่งข้อมูลไปยัง API
        final success = await _formController.submitForm(
          widget.assignId,
          widget.assigneeId,
          assignData,
        );

        setState(() => isLoading = false);

        if (success) {
          // แสดงข้อความสำเร็จ
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('ส่งแบบประเมินเรียบร้อยแล้ว'),
              backgroundColor: Colors.green,
            ),
          );

          // รอสักครู่แล้วกลับไปหน้าก่อนหน้า
          Future.delayed(const Duration(milliseconds: 800), () {
            Navigator.pushNamedAndRemoveUntil(
                context, '/home', (route) => false);
          });
        } else {
          // แสดงข้อความผิดพลาด
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('เกิดข้อผิดพลาดในการส่งแบบประเมิน'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        setState(() => isLoading = false);

        // แสดงข้อความเมื่อเกิดข้อผิดพลาด
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ไม่'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('ใช่'),
            ),
          ],
        ),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  Widget buildStepIndicator(int step) {
    bool isActive = step == currentStep;
    return Row(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: isActive ? Colors.blue : Colors.grey,
          child: Text(
            (step + 1).toString(),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        if (step < sections.length - 1)
          Expanded(
            child: Container(
              height: 2,
              color: isActive ? Colors.blue : Colors.grey,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF7367F0)))
            : sections.isEmpty
                ? const Center(
                    child: Text('No sections available'),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          formTitle,
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: SingleChildScrollView(
                            child: FormSection(
                              section: sections[currentStep],
                              index: currentStep,
                              totalSections: sections.length,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (currentStep != 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 16),
                                child: ElevatedButton(
                                  onPressed: () =>
                                      setState(() => currentStep--),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 36, vertical: 16),
                                    textStyle: const TextStyle(fontSize: 18),
                                  ),
                                  child: const Text('ย้อนกลับ'),
                                ),
                              ),
                            if (currentStep == 0)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 16),
                                child: ElevatedButton(
                                  onPressed: backToForm,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 36, vertical: 16),
                                    textStyle: const TextStyle(fontSize: 18),
                                  ),
                                  child: const Text('ยกเลิก'),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 16),
                              child: ElevatedButton(
                                onPressed: currentStep == sections.length - 1
                                    ? submitEvaluationForm
                                    : handleNextStep,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 36, vertical: 16),
                                  textStyle: const TextStyle(fontSize: 18),
                                ),
                                child: Text(currentStep == sections.length - 1
                                    ? 'ส่งแบบประเมิน'
                                    : 'ต่อไป'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class FormSection extends StatefulWidget {
  final Map<String, dynamic> section;
  final int index;
  final int totalSections;

  const FormSection({
    Key? key,
    required this.section,
    required this.index,
    required this.totalSections,
  }) : super(key: key);

  @override
  State<FormSection> createState() => _FormSectionState();
}

class _FormSectionState extends State<FormSection> {
  @override
  void initState() {
    super.initState();
    _fixDataStructure(); // เปลี่ยนจาก _convertAllSelectedValues() เป็นฟังก์ชันใหม่
  }

  @override
  void didUpdateWidget(FormSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fixDataStructure(); // เรียกฟังก์ชันใหม่
  }

// ฟังก์ชันใหม่ที่จัดการกับโครงสร้างข้อมูลทั้งหมด
  void _fixDataStructure() {
    if (widget.section['question_id'] != null) {
      for (var question in widget.section['question_id']) {
        if (question['qt_type'] == 'grid' && question['qt_row'] != null) {
          // แปลงโครงสร้างข้อมูลแถว
          for (int i = 0; i < question['qt_row'].length; i++) {
            var row = question['qt_row'][i];

            // ถ้า row เป็น String ให้แปลงเป็น Map
            if (row is String) {
              question['qt_row'][i] = {'name': row, 'selected': null};
            }
            // ถ้า row เป็น Map แล้ว ให้ตรวจสอบค่า selected
            else if (row is Map) {
              if (row['selected'] != null && row['selected'] is! int) {
                // แปลงค่า selected เป็น int หรือ null
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
        Padding(
            padding: EdgeInsets.only(left: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.section['fs_name'] != null &&
                    widget.section['fs_name'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text(
                      widget.section['fs_name'] ?? '',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w400),
                    ),
                  ),
                if (widget.section['fs_description'] != null &&
                    widget.section['fs_description'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Text(
                      widget.section['fs_description'] ?? '',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: Colors.grey),
                    ),
                  ),
              ],
            )),
        ...((widget.section['question_id'] ?? []) as List)
            .map<Widget>((question) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      text: question['qt_name'] ?? '',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w400,
                          color: Colors.black),
                      children: [
                        if (question['qt_required'] ?? false)
                          const TextSpan(
                            text: ' *',
                            style: TextStyle(color: Colors.red),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (question['qt_type'] == 'text' ||
                      question['qt_type'] == 'paragraph')
                    TextFormField(
                      initialValue: question['answer'] ?? '',
                      decoration: InputDecoration(
                        errorText: (question['error'] ?? false)
                            ? question['errorMessage']
                            : null,
                        border: const UnderlineInputBorder(),
                      ),
                      onChanged: (value) {
                        setState(() {
                          question['answer'] = value;
                          question['error'] = false;
                        });

                        // แจ้ง parent state ว่ามีการเปลี่ยนแปลง
                        final formState =
                            context.findAncestorStateOfType<_FormScreenState>();
                        if (formState != null) {
                          formState.isChange = true;
                        }
                      },
                      maxLines: question['qt_type'] == 'paragraph' ? null : 1,
                    ),
                  if (question['qt_type'] == 'multiple')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ส่วนแสดง radio buttons
                        ...(question['qt_choices'] ?? []).map<Widget>((choice) {
                          return RadioListTile<int>(
                            title: Text(choice['qt_choice'] ?? ''),
                            value:
                                (question['qt_choices'] ?? []).indexOf(choice),
                            groupValue: question['answer'] as int?,
                            onChanged: (value) {
                              // ใช้ context เพื่อเข้าถึง state ของ widget
                              if (context is StatefulElement) {
                                (context).state.setState(() {
                                  question['answer'] = value;
                                  question['error'] = false;
                                });
                              }
                            },
                          );
                        }).toList(),

                        // เพิ่มส่วนแสดงข้อความ error
                        if (question['error'] ?? false)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 4.0,
                            ),
                            child: Text(
                              question['errorMessage'] ?? 'กรุณาเลือกตัวเลือก',
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  if (question['qt_type'] == 'grid')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // หัวข้อคอลัมน์ (ตัวเลือกการให้คะแนน)
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // ช่องว่างสำหรับชื่อหัวข้อ
                              const SizedBox(width: 150, child: SizedBox()),
                              // แสดงชื่อคอลัมน์ (เช่น 1, 2, 3, 4)
                              ...(question['qt_column'] ?? [])
                                  .map<Widget>((column) {
                                return Expanded(
                                  child: Center(
                                    child: Text(
                                      column['name'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // แสดงแถวข้อมูล
                        ...(question['qt_row'] ?? [])
                            .asMap()
                            .entries
                            .map<Widget>((entry) {
                          final int index = entry.key;
                          final row = entry
                              .value; // ตอนนี้ row จะเป็น Map เสมอเพราะเราเปลี่ยนโครงสร้างแล้ว

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(color: Colors.grey[300]!)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // แสดงชื่อหัวข้อตัวชี้วัด
                                SizedBox(
                                  width: 150,
                                  child: Text(
                                    row['name'] ?? 'Row ${index + 1}',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),

                                // แสดงตัวเลือกคะแนน
                                ...(question['qt_column'] ?? [])
                                    .map<Widget>((column) {
                                  final int? columnValue =
                                      column['value'] is int
                                          ? column['value']
                                          : parseIntValue(column['value']);
                                  return Expanded(
                                    child: Center(
                                      child: Radio<int?>(
                                        value: columnValue,
                                        groupValue:
                                            parseIntValue(row['selected']),
                                        activeColor: const Color(0xFF7367F0),
                                        onChanged: (int? newValue) {
                                          setState(() {
                                            row['selected'] =
                                                newValue.toString();

                                            final formState =
                                                context.findAncestorStateOfType<
                                                    _FormScreenState>();
                                            if (formState != null) {
                                              formState.isChange = true;
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),

                                // แสดงข้อความ error ถ้ามี
                                if (question['error'] ?? false)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      question['errorMessage'] ??
                                          'กรุณากรอกข้อมูลให้ครบถ้วน',
                                      style: const TextStyle(
                                          color: Colors.red, fontSize: 12),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
