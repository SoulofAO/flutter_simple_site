import 'package:flutter/material.dart';
import 'dart:math';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: RunningImagePage(),
    );
  }
}

class RunningImagePage extends StatefulWidget {
  @override
  _RunningImagePageState createState() => _RunningImagePageState();
}

class _RunningImagePageState extends State<RunningImagePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;
  double _x = 0;
  double _y = 0;
  double _dx = 2; // Скорость по X
  double _dy = 2; // Скорость по Y
  final double _imageSize = 50; // Размер изображения

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..forward();

    _animation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_controller);

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

    // Остановка после 20 секунд
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.stop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            left: _x,
            top: _y,
            child: Image.network(
              'https://cdn.pixabay.com/photo/2023/08/05/15/42/panda-8171354_1280.jpg', // Замените на ваше изображение
              width: _imageSize,
              height: _imageSize,
            ),
          ),
        ],
      ),
    );
  }
}