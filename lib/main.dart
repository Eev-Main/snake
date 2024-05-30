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
        automaticallyImplyLeading: false,
        title: Text('Menu'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'High Score: $highScore',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Snake()),
                );
              },
              child: Text('Jugar'),
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
  static const int squaresPerRow = 20;
  static const int squaresPerColumn = 40;
  static const int snakeInitialLength = 3;
  static const int snakeInitialSpeed = 300;

  List<int> snake = [];
  List<int> foodPositions = [];
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
      foodPositions = []; // Vaciar la lista de posiciones de alimentos
      int midPoint = (squaresPerRow / 2).floor() * squaresPerRow +
          (squaresPerColumn / 2).floor();
      snake.add(midPoint);
      for (int i = 1; i < snakeInitialLength; i++) {
        snake.add(snake.last - squaresPerRow);
      }
      direction = 'right';
      isPlaying = true;
      speed = snakeInitialSpeed;
      score = 0;
      generateFood();
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
    switch (direction) {
      case 'up':
        newHead -= squaresPerRow;
        break;
      case 'down':
        newHead += squaresPerRow;
        break;
      case 'left':
        newHead -= 1;
        break;
      case 'right':
        newHead += 1;
        break;
    }
    if (newHead % squaresPerRow == 0 && direction == 'right') {
      newHead -= squaresPerRow;
    } else if (newHead % squaresPerRow == squaresPerRow - 1 && direction == 'left') {
      newHead += squaresPerRow;
    }
    if (snake.contains(newHead)) {
      setState(() {
        isPlaying = false; // Snake collided with itself
      });
    } else {
      setState(() {
        snake.insert(0, newHead);
        if (foodPositions.contains(newHead)) {
          foodPositions.remove(newHead);
          generateFood();
          score++;
          if (score > highScore) {
            highScore = score;
          }
        } else {
          snake.removeLast();
        }
      });
    }
  }

  void checkCollision() {
    if (snake.first < 0 ||
        snake.first >= squaresPerRow * squaresPerColumn ||
        (snake.first % squaresPerRow == 0 && direction == 'left') ||
        (snake.first % squaresPerRow == squaresPerRow - 1 && direction == 'right')) {
      setState(() {
        isPlaying = false; // Snake collided with the wall
      });
    }
  }

  void generateFood() {
    setState(() {
      for (int i = 0; i < 5; i++) {
        int newFood = Random().nextInt(squaresPerRow * squaresPerColumn);
        while (snake.contains(newFood) || foodPositions.contains(newFood)) {
          newFood = Random().nextInt(squaresPerRow * squaresPerColumn);
        }
        foodPositions.add(newFood);
      }
    });
  }

  void move(String newDirection) {
    if ((direction == 'up' && newDirection != 'down') ||
        (direction == 'down' && newDirection != 'up') ||
        (direction == 'left' && newDirection != 'right') ||
        (direction == 'right' && newDirection != 'left')) {
      setState(() {
        direction = newDirection;
      });
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
    Expanded(
    child: GridView.builder(
    physics: NeverScrollableScrollPhysics(),
    itemCount: squaresPerRow * squaresPerColumn,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: squaresPerRow,
    ),
    itemBuilder: (BuildContext context, int index) {
    if (foodPositions.contains(index)) {
    return Container(
    padding: EdgeInsets.all(2),
    child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
      child: Container(
      color: Colors.red,
      ),
      ),
      );
      } else if (snake.contains(index)) {
      return Container(
      padding: EdgeInsets.all(2),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
      color: Colors.green,
      ),
      ),
      );
      } else {
      return Container(
      padding: EdgeInsets.all(2),
      child: ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
      color: Colors.grey[200],
      ),
      ),
      );
      }
    },
    ),
    ),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Text('Score: $score'),
          Text('High Score: $highScore'),
        ],
      ),
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

