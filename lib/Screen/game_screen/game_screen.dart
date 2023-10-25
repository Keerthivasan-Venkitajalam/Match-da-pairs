import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../Logic/functions_objects.dart';
import '../final_screen/game_complete_screen.dart';

enum Selected { easy, medium, hard }

void playCorrectSound() async {
  final player = AudioPlayer();
  const soundPath = "audio/success.mp3";
  await player.play(AssetSource(soundPath), volume: 0.5);
}

void playWrongSound() async {
  final player = AudioPlayer();
  const soundPath = "audio/wrong.mp3";
  await player.play(AssetSource(soundPath));
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isMounted = false;
  bool _showPoints = false;
  Selected _selected = Selected.easy;
  Timer? _switchModeTimer;
  bool _isSwitchingModes = false;
  void _resetGameState() {
    if (_isSwitchingModes) {
      _switchModeTimer?.cancel();
    }
    _isSwitchingModes = true;
    _isMounted = false;
    loadSelect = true;
    itemDuos = getPairs();
    itemDuos.shuffle();
    hiddenDuos = itemDuos;
    selectedTileIndex = -1; // Reset selectedTileIndex to an invalid value
    selectedImagePath = ""; // Reset selectedImagePath
    points = 0;
    _showPoints = false;
    _switchModeTimer=Timer(const Duration(seconds: 5), () {
      _showPoints = true;
      if (_isMounted) return;
      if (!_isMounted) {
        setState(() {
          hiddenDuos = getQuestions();
          loadSelect = false;
        });
      }
      _isSwitchingModes = false;
    });
  }

  @override
  void initState() {
    _switchModeTimer?.cancel();
    _resetGameState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitDown,
      DeviceOrientation.portraitUp,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    _isMounted = false;
    loadSelect = false;
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      var width = constraints.maxWidth;
      var height = constraints.maxHeight;
      return Scaffold(
        body: Column(
          children: [
            SizedBox(
              height: height * 0.1,
            ),
            Container(
              height: height * 0.05, //Changed
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: _selected == Selected.easy
                        ? 0
                        : _selected == Selected.medium
                            ? MediaQuery.of(context).size.width / 3
                            : 2 * MediaQuery.of(context).size.width / 3,
                    child: Container(
                      width: MediaQuery.of(context).size.width / 3,
                      height: height * 0.05,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildButton(Selected.easy, "Easy"),
                      _buildButton(Selected.medium, "Medium"),
                      _buildButton(Selected.hard, "Hard"),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
              child: Column(
                children: [
                  Text(
                    _showPoints ? "$points/8" : "Memorize",
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
                  ),
                  if (_showPoints) ...[
                    const Text("Points"),
                  ] else ...[
                    const Text(" "),
                  ],
                  const SizedBox(
                    height: 20,
                  ),
                  points != 8
                      ? GridView(
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(mainAxisSpacing: 0.0, maxCrossAxisExtent: 100),
                          children: List.generate(hiddenDuos.length, (index) {
                            return ItemContainers(
                              state: this,
                              pathToImage: hiddenDuos[index].getImagePath(),
                              tileIndex: index,
                            );
                          }),
                        )
                      : const GameCompleteScreen()
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildButton(Selected level, String text) {
    bool isSelected = _selected == level;
    Color textColor = isSelected ? Theme.of(context).colorScheme.secondary : Theme.of(context).colorScheme.tertiary;

    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        onTap: () {
          if (_selected != level) {
            setState(() {
              _selected = level;
              setMode(level.toString().split(".").last);
              _resetGameState();
            });
          }


        },
        child: Container(
          height: double.infinity,
          alignment: Alignment.center,
          child: Text(
            text,
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: textColor),
          ),
        ),
      ),
    );
  }
}

class ItemContainers extends StatefulWidget {
  late String pathToImage;
  late int tileIndex;
  _GameScreenState state;

  ItemContainers({super.key, required this.pathToImage, required this.tileIndex, required this.state});

  @override
  State<ItemContainers> createState() => _ItemContainersState();
}

class _ItemContainersState extends State<ItemContainers> {
  bool _isClickable = true;

  void _onTileTap() async {
    if (!_isClickable || loadSelect) return;
    // _isClickable = false;
    if (selectedTileIndex == widget.tileIndex) return;
    _isClickable = false;
    if (!loadSelect) {
      if (selectedImagePath != "") {
        if (selectedImagePath == itemDuos[widget.tileIndex].getImagePath()) {
          playCorrectSound();
          print("Correct");
          loadSelect = true;
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return;
            points = points + 1;
            setState(() {});
            loadSelect = false;
            widget.state.setState(() {
              itemDuos[selectedTileIndex].setImagePath("");
              itemDuos[widget.tileIndex].setImagePath("");
            });
            selectedImagePath = "";
            _isClickable = true;
          });
        } else {
          playWrongSound();
          print("Ni");
          loadSelect = true;
          Future.delayed(const Duration(seconds: 2), () {
            loadSelect = false;
            widget.state.setState(() {
              itemDuos[widget.tileIndex].setIsSelected(false);
              itemDuos[selectedTileIndex].setIsSelected(false);
            });

            selectedImagePath = "";
            selectedTileIndex = -1;
            _isClickable = true;
          });
        }
      } else {
        print("1 select");
        selectedTileIndex = widget.tileIndex;
        selectedImagePath = itemDuos[widget.tileIndex].getImagePath();
      }
      setState(() {
        itemDuos[widget.tileIndex].setIsSelected(true);
      });
      _isClickable = true;
    }

    await Future.delayed(const Duration(seconds: 1));
    _isClickable = true;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTileTap,
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.tertiary), borderRadius: BorderRadius.circular(50)),
        margin: const EdgeInsets.all(15),
        child: ClipOval(
          child: AnimatedSwitcher(
            duration: const Duration(seconds: 1),
            child: itemDuos[widget.tileIndex].getImagePath() != ""
                ? Image.asset(itemDuos[widget.tileIndex].getSelected() ? itemDuos[widget.tileIndex].getImagePath() : widget.pathToImage)
                : Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
          ),
        ),
      ),
    );
  }
}
