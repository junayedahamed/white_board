// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:white_board/src/home/board/widget/board_drawer.dart';
import 'package:white_board/src/home/board/widget/page.dart';
import 'package:white_board/src/home/drawing_path/drawing_path.dart';
import 'package:white_board/src/home/pointers/mouse_pointers.dart';

class Board extends StatefulWidget {
  const Board({super.key});

  @override
  State<Board> createState() => _BoardState();
}

enum BoardTool { pen, hand, eraser, highLighter, shape }

class _BoardState extends State<Board> {
  // erazePointer
  double erazePointer = 20.0;
  double zoomSize = 1.0;
  int currentPage = 0;
  double highLightPointerSize = 4.0;
  bool enableZoom = false;
  Color prevSelectedColor = Colors.black;
  List<PaintingPage> page = [PaintingPage(paths: [])];
  final List<DrawingPath> paths = [];
  // final List<DrawingPath> erazePaths = [];
  // final List<DrawingPath> highLightPath = [];
  DrawingPath? currentPath;
  Timer? _timer;
  double pensize = 4.0;
  bool _highLight = false;
  // bool _isErasing = false;
  final highlightColor = Colors.cyanAccent;

  ShapeType selectedShape = ShapeType.rectangle;
  bool isShapeFilled = false;

  void highLight(bool highLight) {
    setState(() {
      _highLight = highLight;
    });

    if (_highLight) {
      penColor = highlightColor;
    }
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 2), () {
      setState(() {
        // penColor = Colors.transparent;
        _highLight = false;
        // paths.removeWhere((p) => p.type == BoardTool.highLighter);
        page[currentPage].paths.removeWhere(
          (p) => p.type == BoardTool.highLighter,
        );
      });
    });
  }

  Color penColor = Colors.black;
  final List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.blue,
    // Colors.pink,
    Colors.teal,
  ];

  final TransformationController _transformationController =
      TransformationController();

  BoardTool _currentTool = BoardTool.pen;
  String cursorKey = 'pen';

  // Track if we are currently zooming/panning
  bool _isZooming = false;
  // MouseCursor _cursor = SystemMouseCursors.basic;

  // Zoom Slider State
  bool _showZoomSlider = false;
  Timer? _zoomHideTimer;
  double _currentScale = 1.0;

  void _toggleZoomSlider() {
    setState(() {
      _showZoomSlider = !_showZoomSlider;
      if (_showZoomSlider) {
        _resetZoomHideTimer();
        // Sync slider with current scale
        _currentScale = _transformationController.value.getMaxScaleOnAxis();
      } else {
        _zoomHideTimer?.cancel();
      }
    });
  }

  void _resetZoomHideTimer() {
    _zoomHideTimer?.cancel();
    _zoomHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showZoomSlider = false;
        });
      }
    });
  }

  void _onZoomSliderChanged(double value) {
    _resetZoomHideTimer();
    setState(() {
      _currentScale = value;
    });

    final Matrix4 currentMatrix = _transformationController.value;
    final double currentScaleVector = currentMatrix.getMaxScaleOnAxis();
    final double scaleFactor = value / currentScaleVector;

    // Calculate the center of the board area
    // Accessing media query ensures we get the window size
    final Size screenSize = MediaQuery.of(context).size;

    // Estimate AppBar height + status bar
    // Standard AppBar height is kToolbarHeight (56.0)
    final double topPadding = MediaQuery.of(context).padding.top;
    const double appBarHeight = kToolbarHeight;

    final double boardWidth = screenSize.width;
    final double boardHeight = screenSize.height - topPadding - appBarHeight;

    final Offset center = Offset(boardWidth / 2, boardHeight / 2);

    // Apply scaling around the center
    final Matrix4 zoomMatrix = Matrix4.identity()
      ..translate(center.dx, center.dy)
      ..scale(scaleFactor)
      ..translate(-center.dx, -center.dy);

    _transformationController.value = zoomMatrix.multiplied(currentMatrix);
  }

  Offset _screenToCanvas(Offset screenOffset) {
    return _transformationController.toScene(screenOffset);
  }

  final controller = MousePointers.instance;

  IconData _getShapeIcon(ShapeType type, {bool? filled}) {
    final isFill = filled ?? isShapeFilled;
    switch (type) {
      case ShapeType.circle:
        return isFill ? Icons.circle : Icons.circle_outlined;
      case ShapeType.rectangle:
        return isFill ? Icons.rectangle : Icons.rectangle_outlined;
      case ShapeType.square:
        return isFill ? Icons.square : Icons.square_outlined;
      case ShapeType.line:
        return Icons.horizontal_rule;
      case ShapeType.arrow:
        return Icons.arrow_right_alt;
      case ShapeType.polygon:
        return Icons.polyline_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  void _showShapeSelection(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Select Shape',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          const Text('Fill'),
                          Switch(
                            value: isShapeFilled,
                            onChanged: (value) {
                              setSheetState(() {
                                isShapeFilled = value;
                              });
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    children: ShapeType.values
                        .where((e) => e != ShapeType.none)
                        .map((type) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedShape = type;
                                _currentTool = BoardTool.shape;
                                cursorKey = 'pen'; // Or custom shape cursor
                              });
                              Navigator.pop(context);
                            },
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        selectedShape == type &&
                                            _currentTool == BoardTool.shape
                                        ? Colors.blue.withOpacity(0.1)
                                        : Colors.transparent,
                                    border: Border.all(
                                      color:
                                          selectedShape == type &&
                                              _currentTool == BoardTool.shape
                                          ? Colors.blue
                                          : Colors.grey.shade300,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _getShapeIcon(type),
                                    size: 30,
                                    color:
                                        selectedShape == type &&
                                            _currentTool == BoardTool.shape
                                        ? Colors.blue
                                        : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  type.name[0].toUpperCase() +
                                      type.name.substring(1),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        selectedShape == type &&
                                            _currentTool == BoardTool.shape
                                        ? Colors.blue
                                        : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                        .toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    MousePointers.instance.penPointer();
    MousePointers.instance.handPointer();
    MousePointers.instance.eraserPointer(erazePointer.round().toInt());
    MousePointers.instance.highlightPointer();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;

    // print(screenSize.width);
    return MouseRegion(
      cursor: FlutterCustomMemoryImageCursor(key: cursorKey),
      child: Scaffold(
        backgroundColor: Colors.white,
        drawerEnableOpenDragGesture: screenSize.width > 800,
        appBar: AppBar(
          actions: [
            // Removed AppBar slider
          ],
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Infinite Board'),

              SizedBox(
                height: 50,
                child: ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  itemCount: colors.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          penColor = colors[index];
                          _currentTool = BoardTool.pen;
                          // _cursor = SystemMouseCursors.precise;
                          cursorKey = 'pen';
                          prevSelectedColor = colors[index];
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: colors[index],
                          // border: Border.all(
                          //   color: penColor == colors[index]
                          //       ? Colors.deepPurple
                          //       : Colors.transparent,
                          //   width: 4,
                          // ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),

                        child: penColor == colors[index]
                            ? Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(),
            ],
          ),
        ),
        drawer: BoardDrawer(
          page: page,
          currentPage: currentPage,
          onPageTap: (index) {
            setState(() {
              currentPage = index;
            });
          },
          onDeletePage: () {
            if (page.length == 1) {
              setState(() {
                page[0] = PaintingPage(paths: []);
              });
              return;
            } else {
              setState(() {
                page.removeAt(currentPage);
                currentPage = currentPage > 0 ? currentPage - 1 : 0;
              });
            }
          },
          onAddPage: () {
            setState(() {
              page.add(PaintingPage(paths: []));
              currentPage = page.length - 1;
            });
          },
        ),
        body: Container(
          constraints: BoxConstraints(minWidth: 800, minHeight: 600),
          child: Stack(
            alignment: AlignmentGeometry.bottomCenter,
            children: [
              ClipRect(
                child: Listener(
                  onPointerSignal: (event) {
                    if (event is PointerScrollEvent) {
                      // Handle trackpad 2-finger scroll
                      final Matrix4 matrix = _transformationController.value
                          .clone();
                      // print(matrix);
                      final translation = matrix.getTranslation();
                      translation.x -= event.scrollDelta.dx;
                      translation.y -= event.scrollDelta.dy;
                      matrix.setTranslationRaw(
                        translation.x,
                        translation.y,
                        translation.z,
                      );
                      _transformationController.value = matrix;
                    }
                  },
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    boundaryMargin: const EdgeInsets.all(double.infinity),
                    minScale: 0.1,
                    maxScale: 50.0,
                    panEnabled: _isZooming || _currentTool == BoardTool.hand,
                    scaleEnabled: enableZoom,
                    onInteractionStart: (details) {
                      // print("start");
                      // print(details);
                      if (details.pointerCount >= 2) {
                        setState(() {
                          _isZooming = true;
                          currentPath = null;
                          // print("here1");
                        });
                      } else if (details.pointerCount == 1 &&
                          !_isZooming &&
                          _currentTool == BoardTool.pen) {
                        setState(() {
                          // print("object");
                          currentPath = DrawingPath(
                            type: BoardTool.pen,
                            strokeWidth: pensize,
                            color: penColor,
                            isFilled: false,
                            points: [_screenToCanvas(details.localFocalPoint)],
                          );
                          // paths.add(currentPath!);
                          page[currentPage].paths.add(currentPath!);
                        });
                      } else if (details.pointerCount == 1 &&
                          !_isZooming &&
                          _currentTool == BoardTool.shape) {
                        setState(() {
                          currentPath = DrawingPath(
                            type: BoardTool.shape,
                            shapeType: selectedShape,
                            strokeWidth: pensize,
                            color: penColor,
                            isFilled: isShapeFilled,
                            points: [_screenToCanvas(details.localFocalPoint)],
                          );
                          page[currentPage].paths.add(currentPath!);
                        });
                      } else if (details.pointerCount == 1 &&
                          !_isZooming &&
                          _currentTool == BoardTool.eraser) {
                        setState(() {
                          currentPath = DrawingPath(
                            type: BoardTool.eraser,
                            strokeWidth: erazePointer,
                            color: Colors.white,
                            isFilled: false,
                            points: [_screenToCanvas(details.localFocalPoint)],
                          );
                          // paths.add(currentPath!);
                          page[currentPage].paths.add(currentPath!);
                        });
                      } else if (details.pointerCount == 1 &&
                          !_isZooming &&
                          _currentTool == BoardTool.highLighter) {
                        setState(() {
                          currentPath = DrawingPath(
                            type: BoardTool.highLighter,
                            strokeWidth: highLightPointerSize,
                            color: highlightColor,
                            isFilled: false,
                            points: [_screenToCanvas(details.localFocalPoint)],
                          );
                          // paths.add(currentPath!);
                          page[currentPage].paths.add(currentPath!);
                        });
                      }
                    },
                    onInteractionUpdate: (details) {
                      // print("update");
                      // print(details);
                      // print(details.pointerCount);

                      // Handle touch 2-finger pan
                      if (details.pointerCount >= 2 && !_isZooming) {
                        setState(() {
                          _isZooming = true;
                          currentPath = null;
                        });
                      }

                      if (details.pointerCount >= 2 && _isZooming) {
                        final Matrix4 matrix = _transformationController.value
                            .clone();
                        final translation = matrix.getTranslation();
                        translation.x += details.focalPointDelta.dx;
                        translation.y += details.focalPointDelta.dy;
                        matrix.setTranslationRaw(
                          translation.x,
                          translation.y,
                          translation.z,
                        );
                        _transformationController.value = matrix;
                        return;
                      }

                      if (details.pointerCount == 1 &&
                          currentPath != null &&
                          !_isZooming &&
                          _currentTool == BoardTool.highLighter) {
                        highLight(true);
                        setState(() {
                          currentPath!.points.add(
                            _screenToCanvas(details.localFocalPoint),
                          );
                        });
                      }

                      if (details.pointerCount == 1 &&
                          currentPath != null &&
                          !_isZooming &&
                          (_currentTool == BoardTool.pen ||
                              _currentTool == BoardTool.eraser ||
                              _currentTool == BoardTool.shape)) {
                        // print(penColor);
                        if (_currentTool == BoardTool.shape) {
                          if (currentPath!.shapeType != ShapeType.polygon) {
                            if (currentPath!.points.length > 1) {
                              currentPath!.points.removeLast();
                            }
                          }
                        }

                        if (_currentTool == BoardTool.eraser) {
                          final canvasPoint = _screenToCanvas(
                            details.localFocalPoint,
                          );
                          final pathsToRemove = <DrawingPath>[];
                          for (final path in page[currentPage].paths) {
                            if (path.type == BoardTool.eraser) continue;

                            bool hit = false;
                            if (path.type == BoardTool.shape) {
                              // Simplified hit test for shapes
                              if (path.points.isNotEmpty) {
                                final start = path.points.first;
                                final end = path.points.last;
                                final rect = Rect.fromPoints(
                                  start,
                                  end,
                                ).inflate(erazePointer / 2);
                                if (rect.contains(canvasPoint)) {
                                  hit = true;
                                }
                              }
                            } else {
                              for (final point in path.points) {
                                if ((point - canvasPoint).distance <
                                    erazePointer) {
                                  hit = true;
                                  break;
                                }
                              }
                            }

                            if (hit) {
                              pathsToRemove.add(path);
                            }
                          }

                          if (pathsToRemove.isNotEmpty) {
                            setState(() {
                              page[currentPage].paths.removeWhere(
                                (p) => pathsToRemove.contains(p),
                              );
                            });
                          }
                        }

                        setState(() {
                          currentPath!.points.add(
                            _screenToCanvas(details.localFocalPoint),
                          );
                        });
                      }

                      // print("here");
                    },
                    onInteractionEnd: (details) {
                      // print("end");
                      // print(details);
                      if (details.pointerCount == 0) {
                        setState(() {
                          _isZooming = false;
                          currentPath = null;
                          // page[currentPage].paths.add(currentPath!);
                        });
                      }
                    },
                    child: page[currentPage],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: .end,
                children: [
                  SizedBox(
                    height: 70,

                    child: Card(
                      margin: EdgeInsets.symmetric(horizontal: 16),
                      elevation: 10,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              // const Text('Infinite Board'),
                              Slider(
                                value: _currentTool == BoardTool.eraser
                                    ? erazePointer
                                    : pensize,
                                max: _currentTool == BoardTool.eraser
                                    ? 200
                                    : 15.0,
                                min: _currentTool == BoardTool.eraser
                                    ? 15
                                    : 2.0,
                                // divisions: 3,
                                label: _currentTool == BoardTool.eraser
                                    ? erazePointer.round().toString()
                                    : pensize.round().toString(),
                                // year2023: true,
                                divisions: _currentTool == BoardTool.eraser
                                    ? 4
                                    : 15,
                                onChanged:
                                    _currentTool == BoardTool.highLighter ||
                                        _currentTool == BoardTool.hand
                                    ? null
                                    : (value) {
                                        setState(() {
                                          if (_currentTool ==
                                              BoardTool.eraser) {
                                            erazePointer = value;
                                            MousePointers.instance
                                                .eraserPointer(
                                                  erazePointer.round().toInt(),
                                                );
                                          } else {
                                            pensize = value;
                                            MousePointers.instance.penPointer();
                                          }
                                        });
                                      },
                              ),
                            ],
                          ),
                          // last
                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    penColor = Colors.white;
                                    _currentTool = BoardTool.eraser;
                                    // _cursor = SystemMouseCursors.precise;
                                    // MousePointers.instance.eraserPointer(
                                    //   erazePointer.round().toInt(),
                                    // );
                                    cursorKey = 'eraser';
                                    // print("ok");
                                  });
                                },
                                icon: HugeIcon(
                                  icon: HugeIcons.strokeRoundedEraser,
                                  size: 30.0,
                                  color: _currentTool == BoardTool.eraser
                                      ? Colors.blue
                                      : null,
                                  strokeWidth: 1.5,
                                ),
                                tooltip: 'Eraser Tool',
                              ),
                              IconButton(
                                icon: HugeIcon(
                                  icon: HugeIcons.strokeRoundedPen01,
                                  size: 30.0,
                                  // color: Color(0xcurrentColor),
                                  color: _currentTool == BoardTool.pen
                                      ? Colors.blue
                                      : null,
                                  strokeWidth: 1.5,
                                ),
                                onPressed: () => setState(() {
                                  penColor = prevSelectedColor == Colors.white
                                      ? colors[0]
                                      : prevSelectedColor;
                                  _currentTool = BoardTool.pen;
                                  // _cursor = SystemMouseCursors.precise;
                                  cursorKey = 'pen';
                                }),
                                tooltip: 'Pen Tool',
                              ),
                              IconButton(
                                icon: HugeIcon(
                                  icon: HugeIcons.strokeRoundedFourFinger03,
                                  size: 30.0,
                                  color: _currentTool == BoardTool.hand
                                      ? Colors.blue
                                      : null,
                                  strokeWidth: 1.5,
                                ),
                                onPressed: () => setState(() {
                                  _currentTool = BoardTool.hand;
                                  // _cursor = SystemMouseCursors.grab;
                                  cursorKey = 'hand';
                                }),
                                tooltip: 'Hand Mode',
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _currentTool = BoardTool.highLighter;
                                    cursorKey = 'highlight';

                                    penColor = highlightColor;
                                    highLight(true);
                                  });
                                },
                                icon: Icon(
                                  Icons.highlight_outlined,
                                  color: _currentTool == BoardTool.highLighter
                                      ? Colors.blue
                                      : null,
                                  size: 30,
                                ),
                                tooltip: 'Highlighter Tool',
                              ),
                              IconButton(
                                onPressed: () {
                                  if (_currentTool == BoardTool.shape) {
                                    _showShapeSelection(context);
                                  } else {
                                    setState(() {
                                      _currentTool = BoardTool.shape;
                                    });
                                  }
                                },
                                icon: Icon(
                                  _getShapeIcon(selectedShape),
                                  color: _currentTool == BoardTool.shape
                                      ? Colors.blue
                                      : null,
                                  size: 30,
                                ),
                                tooltip: 'Shape Tool',
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Container(
                                  height: 50,
                                  width: 1,
                                  color: Colors.red,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () {
                                  setState(() {
                                    page[currentPage].paths.clear();
                                  });
                                },
                                tooltip: 'Clear All',
                              ),
                              IconButton(
                                icon: const Icon(Icons.home),
                                onPressed: () {
                                  _transformationController.value =
                                      Matrix4.identity();
                                },
                                tooltip: 'Reset View',
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.zoom_in,
                                  size: 30.0,
                                  color: Colors.black, // Default color
                                ),
                                color: _showZoomSlider ? Colors.blue : null,
                                onPressed: _toggleZoomSlider,
                                tooltip: 'Zoom Tool',
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                child: Container(
                                  height: 50,
                                  width: 1,
                                  color: Colors.red,
                                ),
                              ),
                              if (_showZoomSlider)
                                SizedBox(
                                  width: 200,
                                  child: Slider(
                                    value: _currentScale,
                                    min: 0.1,
                                    max: 5.0,
                                    activeColor: Colors.blue,
                                    onChanged: _onZoomSliderChanged,
                                  ),
                                ),
                              if (_showZoomSlider)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Container(
                                    height: 50,
                                    width: 1,
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ],
          ),
        ),
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        // floatingActionButton:
      ),
    );
  }
}
