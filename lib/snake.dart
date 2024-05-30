import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(MaterialApp(
    home: MainMenu(),
  ));
}

class MainMenu extends StatefulWidget {
  @override
  _MainMenuState createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    getHighScore();
  }

  void getHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snake Game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'High Score: $highScore',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Snake()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(
                'Jugar',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Snake extends StatefulWidget {
  @override
  _SnakeState createState() => _SnakeState();
}

class _SnakeState extends State<Snake> {
  static const int squareSize = 20;
  static const int squaresPerRow = 15;
  static const int squaresPerColumn = 30;
  static const int snakeInitialLength = 3;
  static const int snakeInitialSpeed = 300;

  List<int> snake = [];
  int food = Random().nextInt(squaresPerRow * squaresPerColumn);
  String direction = 'right';
  bool isPlaying = false;
  int speed = snakeInitialSpeed;
  int score = 0;
  int highScore = 0;

  @override
  void initState() {
    super.initState();
    getHighScore();
    startGame();
  }

  void startGame() {
    setState(() {
      snake = [];
      snake.add((squaresPerRow / 2).floor() * squaresPerRow +
          (squaresPerColumn / 2).floor());
      snake.add(snake.last - squaresPerRow);
      snake.add(snake.last - squaresPerRow);
      direction = 'right';
      isPlaying = true;
      speed = snakeInitialSpeed;
      score = 0;
    });
    Timer.periodic(Duration(milliseconds: speed), (timer) {
      if (!isPlaying) {
        timer.cancel();
      } else {
        moveSnake();
        checkCollision();
        if (!isPlaying) {
          updateHighScore();
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Game Over'),
                content: Text('You lost!'),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      startGame();
                    },
                    child: Text('Play Again'),
                  ),
                ],
              );
            },
          );
        }
      }
    });
  }

  void moveSnake() {
    int newHead = snake.first;
    setState(() {
      switch (direction) {
        case 'up':
          newHead = snake.first - squaresPerRow;
          break;
        case 'down':
          newHead = snake.first + squaresPerRow;
          break;
        case 'left':
          newHead = snake.first - 1;
          break;
        case 'right':
          newHead = snake.first + 1;
          break;
      }
      if (newHead % squaresPerRow == 0 && direction == 'right') {
        newHead -= squaresPerRow;
      } else if (newHead % squaresPerRow == squaresPerRow - 1 && direction == 'left') {
        newHead += squaresPerRow;
      }
      if (snake.contains(newHead)) {
        isPlaying = false; // Snake collided with itself
      } else {
        snake.insert(0, newHead);
        if (snake.first == food) {
          generateFood();
          score++;
          if (score > highScore) {
            highScore = score;
          }
        } else {
          snake.removeLast();
        }
      }
    });
  }

  void checkCollision() {
    if (snake.first < 0 ||
        snake.first >= squaresPerRow * squaresPerColumn ||
        snake.first % squaresPerRow == 0 && direction == 'left' ||
        snake.first % squaresPerRow == squaresPerRow - 1 && direction == 'right') {
      isPlaying = false; // Snake collided with the wall
    }
  }

  void generateFood() {
    setState(() {
      food = Random().nextInt(squaresPerRow * squaresPerColumn);
      while (snake.contains(food)) {
        food = Random().nextInt(squaresPerRow * squaresPerColumn);
      }
    });
  }

  void move(String newDirection) {
    if ((direction == 'up' && newDirection != 'down') ||
        (direction == 'down' && newDirection != 'up') ||
        (direction == 'left' && newDirection != 'right') ||
        (direction == 'right' && newDirection != 'left')) {
      direction = newDirection;
    }
  }

  void getHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  void updateHighScore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('highScore', highScore);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Snake Game'),
      ),
      body: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 0) {
            move('down');
          } else if (details.delta.dy < 0) {
            move('up');
          }
        },
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx > 0) {
            move('right');
          } else if (details.delta.dx < 0) {
            move('left');
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Text(
                  'Score: $score',
                  style: TextStyle(fontSize: 20),
                ),
                Text(
                  'High Score: $highScore',
                  style: TextStyle(fontSize: 20),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: squaresPerRow,
                ),
                itemCount: squaresPerRow * squaresPerColumn,
                itemBuilder: (BuildContext context, int index) {
                  if (index == food) {
                    return Container(
                      margin: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  } else if (snake.contains(index)) {
                    return Container(
                      margin: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  } else {
                    return Container(
                      margin: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                FloatingActionButton(
                  onPressed: () => move('up'),
                  child: Icon(Icons.keyboard_arrow_up),
                ),
                Row(
                  children: <Widget>[
                    FloatingActionButton(
                      onPressed: () => move('left'),
                      child: Icon(Icons.keyboard_arrow_left),
                    ),
                    SizedBox(width: 20),
                    FloatingActionButton(
                      onPressed: () => move('right'),
                      child: Icon(Icons.keyboard_arrow_right),
                    ),
                  ],
                ),
                FloatingActionButton(
                  onPressed: () => move('down'),
                  child: Icon(Icons.keyboard_arrow_down),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
