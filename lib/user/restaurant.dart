import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class RestaurantDetailPage extends StatefulWidget {
  final String image;
  final String name;
  final String location;
  final int queue;
  final Color backgroundColor;
  final List<String> promotionImages;

  const RestaurantDetailPage({
    super.key,
    required this.image,
    required this.name,
    required this.location,
    required this.queue,
    required this.backgroundColor,
    required this.promotionImages,
  });

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  final _pageController = PageController();

  void _showQueueNowDialog() {
  showDialog(
    context: context,
    builder: (context) {
      int numberOfPersons = 1;
      String selectedTableType = '1-2 persons';

      void updateNumberOfPersons(String tableType) {
        setState(() {
          selectedTableType = tableType;
          if (tableType == '1-2 persons') {
            numberOfPersons = 1;
          } else if (tableType == '3-6 persons') {
            numberOfPersons = 3;
          } else if (tableType == '7-12 persons') {
            numberOfPersons = 7;
          }
        });
      }

      return StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Queue Now',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Type of tables:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildTableTypeButton(
                      '1-2 persons',
                      Icons.people,
                      selectedTableType,
                      (value) {
                        setState(() {
                          updateNumberOfPersons(value);
                        });
                      },
                    ),
                    _buildTableTypeButton(
                      '3-6 persons',
                      Icons.group,
                      selectedTableType,
                      (value) {
                        setState(() {
                          updateNumberOfPersons(value);
                        });
                      },
                    ),
                    _buildTableTypeButton(
                      '7-12 persons',
                      Icons.groups,
                      selectedTableType,
                      (value) {
                        setState(() {
                          updateNumberOfPersons(value);
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Number of persons
                const Text(
                  'Number of persons:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Color(0xFF8B2323)),
                      iconSize: 36,
                      onPressed: () {
                        setState(() {
                          int minPersons = selectedTableType == '1-2 persons'
                              ? 1
                              : selectedTableType == '3-6 persons'
                                  ? 3
                                  : 7;
                          if (numberOfPersons > minPersons) numberOfPersons--;
                        });
                      },
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        numberOfPersons.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF8B2323)),
                      iconSize: 36,
                      onPressed: () {
                        setState(() {
                          int maxPersons = selectedTableType == '1-2 persons'
                              ? 2
                              : selectedTableType == '3-6 persons'
                                  ? 6
                                  : 12;
                          if (numberOfPersons < maxPersons) numberOfPersons++;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                              side: const BorderSide(
                                  color: Color(0xFF8B2323), width: 1))),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF8B2323),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B2323),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                        print('Table Type: $selectedTableType, Number of Persons: $numberOfPersons');
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Confirm',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  Widget _buildTableTypeButton(String type, IconData icon, String selectedType,
      Function(String) onSelect) {
    bool isSelected = selectedType == type;
    return InkWell(
      onTap: () => onSelect(type),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Color(0xFF8B2323) : Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF8B2323) : Colors.grey),
            const SizedBox(height: 5),
            Text(
              type,
              style: TextStyle(
                color: isSelected ? Colors.brown : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPromotionPopup(String imagePath) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showQueueInAdvanceDialog() {
    TimeOfDay selectedTime = TimeOfDay.now();
    int persons = 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Queue in advance',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Select booking time:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF8B2323),
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF8B2323)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')} : ${selectedTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF8B2323),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Number of persons:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle,
                              color: Color(0xFF8B2323)),
                          iconSize: 36,
                          onPressed: () {
                            setState(() {
                              if (persons > 1) persons--;
                            });
                          },
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black54),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            persons.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle,
                              color: Color(0xFF8B2323)),
                          iconSize: 36,
                          onPressed: () {
                            setState(() {
                              if (persons < 20) persons++;
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF8B2323),
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8B2323),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            print(
                                'Advance Booking: ${selectedTime.format(context)}, Persons: $persons');
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            'Confirm',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF8B2323),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.backgroundColor,
                ),
                child: Center(
                  child: ClipOval(
                    child: Image.asset(
                      widget.image,
                      fit: BoxFit.cover,
                      width: 150,
                      height: 150,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              Text(
                widget.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    widget.location,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    'Queue : ${widget.queue}',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              const Text(
                'Choose the type of reservation',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildReservationOption(
                    icon: Icons.groups,
                    title: 'Queue Now',
                    onTap: _showQueueNowDialog,
                  ),
                  _buildReservationOption(
                    icon: Icons.calendar_today,
                    title: 'Queue\nin advance',
                    onTap: _showQueueInAdvanceDialog,
                  ),
                ],
              ),
              const SizedBox(height: 30),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Promotion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PageView.builder(
                      controller: _pageController,
                      itemCount: widget.promotionImages.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            _showPromotionPopup(widget.promotionImages[index]);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              image: DecorationImage(
                                image:
                                    AssetImage(widget.promotionImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SmoothPageIndicator(
                controller: _pageController,
                count: widget.promotionImages.length,
                effect: const ExpandingDotsEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  activeDotColor: Color(0xFF8B2323),
                  dotColor: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40,
              color: const Color(0xFF8B2323),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
