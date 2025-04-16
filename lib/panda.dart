import 'package:flutter/material.dart';
import 'dart:math';

class PandaImagePage extends StatefulWidget {
  const PandaImagePage({Key? key}) : super(key: key);

  @override
  PandaImagePageState createState() => PandaImagePageState();
}
class PandaImagePageState extends State<PandaImagePage>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  double _x = 0;
  double _y = 0;
  double _dx = 2; // Скорость по X
  double _dy = 2; // Скорость по Y
  final double _imageSize = 200; // Размер изображения
  List<String> images = ['http://localhost:5000/assets/Panda.jpg','http://localhost:5000/assets/Capibara.jpg' ];
  late String image;
  double _opacity = 1.0; // Начальная прозрачность

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Обновление позиции
    _controller.addListener(() {
      setState(() {
        _x += _dx;
        _y += _dy;

        // Получаем размеры экрана
        final screenSize = MediaQuery.of(context).size;

        // Проверка столкновения со стенками
        if (_x <= 0 || _x >= screenSize.width - _imageSize) {
          _dx = -_dx; // Меняем направление по X
          _x = _x.clamp(0, screenSize.width - _imageSize);
        }
        if (_y <= 0 || _y >= screenSize.height - _imageSize) {
          _dy = -_dy; // Меняем направление по Y
          _y = _y.clamp(0, screenSize.height - _imageSize);
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void selectRandomImage() {
    final random = Random();
    setState(() {
      image = images [random.nextInt(images.length)];
    });
  }


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    selectRandomImage();
    final imageProvider = NetworkImage(image);
    precacheImage(imageProvider, context);
  }

  // Функция для плавного появления
  void fadeIn() {
    setState(() {
      _opacity = 1.0; // Полная видимость
    });
  }

  // Функция для плавного исчезновения
  void fadeOut() {
    setState(() {
      _opacity = 0.0; // Полная прозрачность
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Прозрачный фон
      body: Stack(
        children: [
          Positioned(
            left: _x,
            top: _y,
            child: AnimatedOpacity(
              opacity: _opacity,
              duration: const Duration(milliseconds: 500), // Длительность анимации
              child: Image.network(
                image,
                width: _imageSize,
                height: _imageSize,
              ),
            ),
          ),
        ],
      ),
    );
  }
}