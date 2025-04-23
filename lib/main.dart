import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'domain/entities/card.dart' as domain;
import 'presentation/pages/game_page.dart';
import 'presentation/widgets/card_widget_simple.dart';

void main() {
  // 包裝整個應用於 ProviderScope 中
  runApp(const ProviderScope(child: FreeCellApp()));
}

/// 新接龍應用
class FreeCellApp extends StatelessWidget {
  const FreeCellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '新接龍',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const GamePage(),
    );
  }
}

class FreeCellGameScreen extends StatefulWidget {
  const FreeCellGameScreen({super.key, required this.title});

  final String title;

  @override
  State<FreeCellGameScreen> createState() => _FreeCellGameScreenState();
}

class _FreeCellGameScreenState extends State<FreeCellGameScreen> {
  // 牌的花色 (紅桃、方塊、黑桃、梅花)
  static const List<String> suits = ['♥', '♦', '♠', '♣'];
  // 牌的點數
  static const List<String> ranks = [
    'A',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    '10',
    'J',
    'Q',
    'K'
  ];

  // 遊戲區域
  List<List<domain.PlayingCard>> columns =
      List.generate(8, (_) => []); // 8列主遊戲區
  List<domain.PlayingCard?> freeCells =
      List.generate(4, (_) => null); // 4個自由單元格
  List<List<domain.PlayingCard>> foundations =
      List.generate(4, (_) => []); // 4個基礎堆

  domain.PlayingCard? selectedCard;
  int? selectedColumnIndex;
  bool? selectedFromFreeCell;
  int? selectedCardIndex;
  bool selectedFromFoundation = false; // 新增：標記牌是否來自基礎堆

  // 遊戲統計
  int moves = 0;
  DateTime? startTime;

  // 歷史記錄
  List<GameRecord> gameHistory = [];

  @override
  void initState() {
    super.initState();
    _loadGameHistory();
    _dealCards();
    startTime = DateTime.now();
  }

  // 加載歷史記錄
  Future<void> _loadGameHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('game_history') ?? [];

      setState(() {
        gameHistory = historyJson
            .map((json) => GameRecord.fromJson(jsonDecode(json)))
            .toList();
        // 按日期排序，最新的在前面
        gameHistory.sort((a, b) => b.date.compareTo(a.date));
      });
    } catch (e) {
      developer.log('加載歷史記錄失敗: $e');
    }
  }

  // 保存歷史記錄
  Future<void> _saveGameHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson =
          gameHistory.map((record) => jsonEncode(record.toJson())).toList();

      await prefs.setStringList('game_history', historyJson);
    } catch (e) {
      developer.log('保存歷史記錄失敗: $e');
    }
  }

  // 添加遊戲記錄
  void _addGameRecord() {
    final duration = DateTime.now().difference(startTime!);
    final record = GameRecord(
      date: DateTime.now(),
      moves: moves,
      duration: duration,
    );

    setState(() {
      gameHistory.add(record);
      // 保持記錄不超過20條
      if (gameHistory.length > 20) {
        gameHistory.removeLast();
      }
    });

    _saveGameHistory();
  }

  // 發牌
  void _dealCards() {
    List<domain.PlayingCard> deck = [];

    // 創建一副完整的牌
    for (String suit in suits) {
      for (int i = 0; i < ranks.length; i++) {
        deck.add(domain.PlayingCard(
          suit: suit,
          rank: ranks[i],
          value: i + 1, // A=1, ..., K=13
          isRed: suit == '♥' || suit == '♦',
        ));
      }
    }

    // 洗牌
    deck.shuffle(Random());

    // 按列發牌
    for (int i = 0; i < deck.length; i++) {
      columns[i % 8].add(deck[i]);
    }
  }

  // 檢查牌的移動是否有效
  bool _isValidMove(
      domain.PlayingCard card, List<domain.PlayingCard> destination) {
    if (destination.isEmpty) {
      return true; // 可以移動到空列
    }

    domain.PlayingCard topCard = destination.last;
    // 檢查顏色是否相反且點數遞減
    bool isValid =
        topCard.value == card.value + 1 && topCard.isRed != card.isRed;

    // 添加調試信息
    developer.log(
        '移動檢查: 從 ${card.rank}${card.suit} 到 ${topCard.rank}${topCard.suit}, 結果: $isValid');
    developer.log(
        '值檢查: ${topCard.value} == ${card.value + 1}: ${topCard.value == card.value + 1}');
    developer.log(
        '顏色檢查: ${topCard.isRed} != ${card.isRed}: ${topCard.isRed != card.isRed}');

    return isValid;
  }

  // 檢查是否可以移到基礎堆
  bool _canMoveToFoundation(domain.PlayingCard card, int foundationIndex) {
    List<domain.PlayingCard> foundation = foundations[foundationIndex];

    if (foundation.isEmpty) {
      // 基礎堆為空，只能放入A，且必須是對應花色
      return card.rank == 'A' && suits[foundationIndex] == card.suit;
    }

    domain.PlayingCard topCard = foundation.last;
    // 同花色且點數遞增
    return topCard.suit == card.suit && topCard.value == card.value - 1;
  }

  // 檢查是否可以將一組牌從一列移動到另一列
  bool _canMoveSequence(
      int fromColumnIndex, int toColumnIndex, int startCardIndex) {
    // 確保源列和目標列不同
    if (fromColumnIndex == toColumnIndex) {
      return false;
    }

    List<domain.PlayingCard> fromColumn = columns[fromColumnIndex];
    List<domain.PlayingCard> toColumn = columns[toColumnIndex];

    // 檢查源列中從startCardIndex開始的牌是否形成有效序列（不同顏色且連續遞減）
    bool isValidSequence = true;
    for (int i = startCardIndex; i < fromColumn.length - 1; i++) {
      if (fromColumn[i].value != fromColumn[i + 1].value + 1 ||
          fromColumn[i].isRed == fromColumn[i + 1].isRed) {
        isValidSequence = false;
        break;
      }
    }

    if (!isValidSequence) {
      return false;
    }

    // 檢查序列的第一張牌是否可以放在目標列上
    domain.PlayingCard firstCardInSequence = fromColumn[startCardIndex];

    if (toColumn.isEmpty) {
      return true; // 可以移動到空列
    }

    domain.PlayingCard topCardOfDestination = toColumn.last;
    // 檢查顏色是否相反且點數遞減
    return topCardOfDestination.value == firstCardInSequence.value + 1 &&
        topCardOfDestination.isRed != firstCardInSequence.isRed;
  }

  // 移動一組牌從一列到另一列
  void _moveCardSequence(
      int fromColumnIndex, int toColumnIndex, int startCardIndex) {
    List<domain.PlayingCard> fromColumn = columns[fromColumnIndex];
    List<domain.PlayingCard> toColumn = columns[toColumnIndex];

    // 獲取要移動的牌序列
    List<domain.PlayingCard> cardsToMove = fromColumn.sublist(startCardIndex);

    // 將牌添加到目標列
    toColumn.addAll(cardsToMove);

    // 從源列中移除這些牌
    fromColumn.removeRange(startCardIndex, fromColumn.length);

    _incrementMoves();
    _tryAutoMoveToFoundation();
  }

  // 增加移動次數
  void _incrementMoves() {
    setState(() {
      moves++;
    });

    // 每次移動後檢查是否獲勝
    if (_checkWin()) {
      _showWinDialog();
    }
  }

  // 處理卡片選擇和移動
  void _handleCardTap(domain.PlayingCard card, int columnIndex, int cardIndex) {
    // 添加調試信息
    developer
        .log('點擊卡片: ${card.rank}${card.suit} 在列 $columnIndex, 索引 $cardIndex');

    if (selectedCard == null) {
      // 嘗試選擇一張牌或一組牌
      // 檢查從cardIndex開始是否形成有效序列
      bool isValidSequence = true;
      List<domain.PlayingCard> column = columns[columnIndex];

      // 如果不是列頂部的牌，檢查是否形成有效序列
      if (cardIndex < column.length - 1) {
        for (int i = cardIndex; i < column.length - 1; i++) {
          if (column[i].value != column[i + 1].value + 1 ||
              column[i].isRed == column[i + 1].isRed) {
            isValidSequence = false;
            break;
          }
        }

        if (!isValidSequence) {
          // 顯示提示，只能選擇有效序列
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('只能選擇形成有效序列的牌（不同顏色且連續遞減）'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
      }

      // 可以選擇這張牌或這組牌
      setState(() {
        selectedCard = card;
        selectedColumnIndex = columnIndex;
        selectedCardIndex = cardIndex;
        selectedFromFreeCell = false;
        selectedFromFoundation = false;
      });
      developer.log('選擇了牌或牌組: ${card.rank}${card.suit}, 索引 $cardIndex');
    } else {
      // 如果點擊了相同的牌，取消選擇
      if (selectedColumnIndex == columnIndex &&
          selectedCardIndex == cardIndex) {
        setState(() {
          selectedCard = null;
          selectedColumnIndex = null;
          selectedCardIndex = null;
          selectedFromFreeCell = null;
          selectedFromFoundation = false;
        });
        developer.log('取消選擇相同的牌');
        return;
      }

      // 已經選擇了一張牌或牌組，現在嘗試移動
      developer.log('嘗試移動牌或牌組到列 $columnIndex');

      if (selectedFromFreeCell == false &&
          selectedFromFoundation == false &&
          selectedColumnIndex != null) {
        // 從遊戲列移動到遊戲列
        if (selectedCardIndex != null) {
          // 移動牌組
          if (_canMoveSequence(
              selectedColumnIndex!, columnIndex, selectedCardIndex!)) {
            _moveCardSequence(
                selectedColumnIndex!, columnIndex, selectedCardIndex!);
            setState(() {
              selectedCard = null;
              selectedColumnIndex = null;
              selectedCardIndex = null;
              selectedFromFreeCell = null;
              selectedFromFoundation = false;
            });
            developer.log('成功移動牌組');
          } else if (selectedCardIndex ==
                  columns[selectedColumnIndex!].length - 1 &&
              _isValidMove(selectedCard!, columns[columnIndex])) {
            // 如果是頂部單張牌，嘗試普通移動
            setState(() {
              columns[columnIndex].add(selectedCard!);
              columns[selectedColumnIndex!].removeLast();
              selectedCard = null;
              selectedColumnIndex = null;
              selectedCardIndex = null;
              selectedFromFreeCell = null;
              selectedFromFoundation = false;
            });
            _incrementMoves();
            _tryAutoMoveToFoundation();
            developer.log('成功移動單張牌');
          } else {
            // 移動無效，取消選擇
            setState(() {
              selectedCard = null;
              selectedColumnIndex = null;
              selectedCardIndex = null;
              selectedFromFreeCell = null;
              selectedFromFoundation = false;
            });
            developer.log('移動無效，取消選擇');
            // 顯示提示
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('無效移動：目標位置必須允許放置選中的牌或牌組'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else if (selectedFromFreeCell == true && selectedColumnIndex != null) {
        // 從自由單元格移動到遊戲列
        if (_isValidMove(selectedCard!, columns[columnIndex])) {
          setState(() {
            columns[columnIndex].add(selectedCard!);
            freeCells[selectedColumnIndex!] = null;
            selectedCard = null;
            selectedColumnIndex = null;
            selectedCardIndex = null;
            selectedFromFreeCell = null;
            selectedFromFoundation = false;
          });
          _incrementMoves();
          _tryAutoMoveToFoundation();
          developer.log('成功從自由單元格移動牌');
        } else {
          // 移動無效，取消選擇
          setState(() {
            selectedCard = null;
            selectedColumnIndex = null;
            selectedCardIndex = null;
            selectedFromFreeCell = null;
            selectedFromFoundation = false;
          });
          developer.log('從自由單元格移動無效，取消選擇');
          // 顯示提示
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('無效移動：卡片必須是不同顏色且點數遞減'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else if (selectedFromFoundation == true &&
          selectedColumnIndex != null) {
        // 從基礎堆移動到遊戲列
        if (_isValidMove(selectedCard!, columns[columnIndex])) {
          setState(() {
            columns[columnIndex].add(selectedCard!);
            foundations[selectedColumnIndex!].removeLast(); // 從基礎堆移除頂部牌
            selectedCard = null;
            selectedColumnIndex = null;
            selectedCardIndex = null;
            selectedFromFreeCell = null;
            selectedFromFoundation = false;
          });
          _incrementMoves();
          developer.log('成功從基礎堆移動牌到遊戲列');
        } else {
          // 移動無效，取消選擇
          setState(() {
            selectedCard = null;
            selectedColumnIndex = null;
            selectedCardIndex = null;
            selectedFromFreeCell = null;
            selectedFromFoundation = false;
          });
          developer.log('從基礎堆移動無效，取消選擇');
          // 顯示提示
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('無效移動：卡片必須是不同顏色且點數遞減'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    }
  }

  // 處理自由單元格點擊
  void _handleFreeCellTap(int index) {
    if (selectedCard == null) {
      // 選擇自由單元格中的牌
      if (freeCells[index] != null) {
        setState(() {
          selectedCard = freeCells[index];
          selectedFromFreeCell = true;
          selectedFromFoundation = false;
          selectedColumnIndex = index;
          selectedCardIndex = null;
        });
      } else if (selectedColumnIndex != null &&
          !selectedFromFreeCell! &&
          !selectedFromFoundation) {
        // 將選中的牌移到空自由單元格
        setState(() {
          freeCells[index] = selectedCard;
          columns[selectedColumnIndex!].removeLast();
          selectedCard = null;
          selectedColumnIndex = null;
          selectedCardIndex = null;
          selectedFromFreeCell = null;
          selectedFromFoundation = false;
        });
        _incrementMoves();
      } else if (selectedFromFoundation && selectedColumnIndex != null) {
        // 將基礎堆的牌移到空自由單元格
        setState(() {
          freeCells[index] = selectedCard;
          foundations[selectedColumnIndex!].removeLast();
          selectedCard = null;
          selectedColumnIndex = null;
          selectedCardIndex = null;
          selectedFromFreeCell = null;
          selectedFromFoundation = false;
        });
        _incrementMoves();
      }
    } else if (selectedFromFreeCell == true && selectedColumnIndex == index) {
      // 點擊相同單元格時取消選擇
      setState(() {
        selectedCard = null;
        selectedColumnIndex = null;
        selectedCardIndex = null;
        selectedFromFreeCell = null;
        selectedFromFoundation = false;
      });
      developer.log('取消選擇自由單元格中的牌');
    } else if (freeCells[index] == null) {
      // 移動牌到空閒的自由單元格
      setState(() {
        freeCells[index] = selectedCard;
        if (selectedFromFreeCell == true) {
          freeCells[selectedColumnIndex!] = null;
        } else if (selectedFromFoundation == true) {
          foundations[selectedColumnIndex!].removeLast();
        } else {
          columns[selectedColumnIndex!].removeLast();
        }
        selectedCard = null;
        selectedColumnIndex = null;
        selectedCardIndex = null;
        selectedFromFreeCell = null;
        selectedFromFoundation = false;
      });
      _incrementMoves();
    }
  }

  // 處理基礎堆點擊
  void _handleFoundationTap(int index) {
    if (selectedCard != null) {
      // 嘗試將牌移到基礎堆
      if (_canMoveToFoundation(selectedCard!, index)) {
        setState(() {
          foundations[index].add(selectedCard!);
          if (selectedFromFreeCell == true) {
            freeCells[selectedColumnIndex!] = null;
          } else {
            columns[selectedColumnIndex!].removeLast();
          }
          selectedCard = null;
          selectedColumnIndex = null;
          selectedCardIndex = null;
          selectedFromFreeCell = null;
          selectedFromFoundation = false;
        });
        _incrementMoves();
      } else {
        // 移動無效，顯示提示
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('無效移動：A必須放在對應花色位置，後續牌必須同花色且遞增'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (foundations[index].isNotEmpty) {
      // 檢查是否可以從基礎堆取牌（只能取最頂部的牌）
      domain.PlayingCard topCard = foundations[index].last;
      // 從基礎堆選擇頂部的牌
      setState(() {
        selectedCard = topCard;
        selectedColumnIndex = index;
        selectedCardIndex = null;
        selectedFromFreeCell = null;
        selectedFromFoundation = true; // 標記牌來自基礎堆
      });
      // 提示用戶已選擇基礎堆的牌
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已選擇${topCard.suit}${topCard.rank}，可放置到遊戲區或自由格'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  // 嘗試自動將牌移動到基礎堆
  void _tryAutoMoveToFoundation() {
    bool moved = false;

    // 檢查列頂部的牌
    for (int i = 0; i < columns.length; i++) {
      if (columns[i].isNotEmpty) {
        domain.PlayingCard card = columns[i].last;

        // 查找可以放置的基礎堆
        for (int j = 0; j < foundations.length; j++) {
          if (_canMoveToFoundation(card, j)) {
            setState(() {
              foundations[j].add(card);
              columns[i].removeLast();
            });
            moved = true;
            break;
          }
        }
      }
    }

    // 檢查自由單元格中的牌
    if (!moved) {
      for (int i = 0; i < freeCells.length; i++) {
        if (freeCells[i] != null) {
          // 查找可以放置的基礎堆
          for (int j = 0; j < foundations.length; j++) {
            if (_canMoveToFoundation(freeCells[i]!, j)) {
              setState(() {
                foundations[j].add(freeCells[i]!);
                freeCells[i] = null;
              });
              moved = true;
              _incrementMoves();
              break;
            }
          }
        }
      }
    }
  }

  // 檢查遊戲是否勝利
  bool _checkWin() {
    // 當所有牌都在基礎堆中時獲勝
    int totalCards = 0;
    for (var foundation in foundations) {
      totalCards += foundation.length;
    }
    return totalCards == 52; // 一副牌共52張
  }

  // 顯示勝利對話框
  void _showWinDialog() {
    final duration = DateTime.now().difference(startTime!);

    // 保存遊戲記錄
    _addGameRecord();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('恭喜！'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('你贏了！'),
            const SizedBox(height: 10),
            Text('移動次數: $moves'),
            Text('用時: ${duration.inMinutes}分${duration.inSeconds % 60}秒'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showHistoryDialog();
            },
            child: const Text('查看記錄'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restartGame();
            },
            child: const Text('再來一局'),
          ),
        ],
      ),
    );
  }

  // 重新開始遊戲
  void _restartGame() {
    setState(() {
      columns = List.generate(8, (_) => []);
      freeCells = List.generate(4, (_) => null);
      foundations = List.generate(4, (_) => []);
      selectedCard = null;
      selectedColumnIndex = null;
      selectedFromFreeCell = null;
      selectedFromFoundation = false;
      moves = 0;
      startTime = DateTime.now();
      _dealCards();
    });
  }

  // 顯示幫助對話框
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('遊戲規則'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('新接龍是一種使用一副標準撲克牌的紙牌遊戲。'),
              SizedBox(height: 10),
              Text('遊戲目標：'),
              Text('將所有牌按花色和順序（從A到K）移到右上角的四個基礎堆。'),
              SizedBox(height: 10),
              Text('遊戲規則：'),
              Text('1. 遊戲區域分為8列主遊戲區、4個自由單元格和4個基礎堆。'),
              Text('2. 只能移動列頂部的牌。'),
              Text('3. 在主遊戲區，牌必須按照顏色交替（紅黑）和降序排列。'),
              Text('4. 自由單元格一次只能放置一張牌。'),
              Text('5. 基礎堆必須按照同一花色的升序排列，從A開始。'),
              Text('6. 可以選擇連續的不同顏色的牌作為一組移動。'),
              Text('7. 可以從基礎堆取回牌，但要謹慎使用此功能。'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('了解了'),
          ),
        ],
      ),
    );
  }

  // 嘗試回收所有可以移動到基礎堆的牌
  void _autoCollectToFoundation() {
    bool madeMove = false;
    int attempts = 0;
    const maxAttempts = 52; // 防止無限循環
    bool foundAnyMove = false;

    // 嘗試多次，因為一次移動可能會讓其他牌變得可以移動
    do {
      madeMove = false;
      attempts++;

      // 檢查列頂部的牌
      for (int columnIndex = 0; columnIndex < columns.length; columnIndex++) {
        if (columns[columnIndex].isEmpty) continue;

        domain.PlayingCard card = columns[columnIndex].last;

        // 逐個檢查所有基礎堆
        for (int foundationIndex = 0;
            foundationIndex < foundations.length;
            foundationIndex++) {
          if (_canMoveToFoundation(card, foundationIndex)) {
            setState(() {
              foundations[foundationIndex].add(card);
              columns[columnIndex].removeLast();
              foundAnyMove = true;
            });
            madeMove = true;
            _incrementMoves();
            break; // 找到一個可移動的基礎堆後退出內循環
          }
        }

        if (madeMove) break; // 如果已經移動，退出當前列循環
      }

      // 如果列中沒有可移動的牌，檢查自由單元格
      if (!madeMove) {
        for (int freeCellIndex = 0;
            freeCellIndex < freeCells.length;
            freeCellIndex++) {
          if (freeCells[freeCellIndex] == null) continue;

          domain.PlayingCard card = freeCells[freeCellIndex]!;

          // 逐個檢查所有基礎堆
          for (int foundationIndex = 0;
              foundationIndex < foundations.length;
              foundationIndex++) {
            if (_canMoveToFoundation(card, foundationIndex)) {
              setState(() {
                foundations[foundationIndex].add(card);
                freeCells[freeCellIndex] = null;
                foundAnyMove = true;
              });
              madeMove = true;
              _incrementMoves();
              break; // 找到一個可移動的基礎堆後退出內循環
            }
          }

          if (madeMove) break; // 如果已經移動，退出當前自由單元格循環
        }
      }
    } while (madeMove && attempts < maxAttempts);

    // 如果沒有牌可以移動到基礎堆
    if (!foundAnyMove) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('沒有可以自動回收的牌'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  // 顯示歷史記錄
  void _showHistoryDialog() {
    // 排序方式：0-默認（日期最新），1-時間最短，2-移動次數最少
    int sortMethod = 0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final ScrollController scrollController = ScrollController();
        return Dialog(
          child: Container(
            width: MediaQuery.of(dialogContext).size.width * 0.9,
            height: MediaQuery.of(dialogContext).size.height * 0.7,
            padding: const EdgeInsets.all(16.0),
            child: StatefulBuilder(
              builder: (builderContext, setDialogState) {
                // 按照選擇的方式對歷史記錄進行排序
                List<GameRecord> sortedHistory = List.from(gameHistory);
                if (sortMethod == 1) {
                  // 按完成時間排序（從短到長）
                  sortedHistory.sort((a, b) {
                    int timeCompare = a.duration.compareTo(b.duration);
                    // 如果時間相同，按移動次數排序
                    return timeCompare != 0
                        ? timeCompare
                        : a.moves.compareTo(b.moves);
                  });
                } else if (sortMethod == 2) {
                  // 按移動次數排序（從少到多）
                  sortedHistory.sort((a, b) {
                    int movesCompare = a.moves.compareTo(b.moves);
                    // 如果移動次數相同，按時間排序
                    return movesCompare != 0
                        ? movesCompare
                        : a.duration.compareTo(b.duration);
                  });
                } else {
                  // 默認按日期排序（最新在前）
                  sortedHistory.sort((a, b) => b.date.compareTo(a.date));
                }

                return Material(
                  color: Colors.transparent,
                  child: Column(
                    children: [
                      // 標題
                      const Text(
                        '歷史記錄',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 排序選擇
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: const Text('最新'),
                                selected: sortMethod == 0,
                                onSelected: (selected) {
                                  if (selected) {
                                    setDialogState(() {
                                      sortMethod = 0;
                                    });
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: const Text('時間最短'),
                                selected: sortMethod == 1,
                                onSelected: (selected) {
                                  if (selected) {
                                    setDialogState(() {
                                      sortMethod = 1;
                                    });
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: ChoiceChip(
                                label: const Text('步數最少'),
                                selected: sortMethod == 2,
                                onSelected: (selected) {
                                  if (selected) {
                                    setDialogState(() {
                                      sortMethod = 2;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // 歷史記錄列表
                      Expanded(
                        child: sortedHistory.isEmpty
                            ? const Center(child: Text('暫無歷史記錄'))
                            : Theme(
                                data: Theme.of(dialogContext).copyWith(
                                  scrollbarTheme: ScrollbarThemeData(
                                    thumbColor: WidgetStateProperty.all(
                                      Colors.grey[400],
                                    ),
                                    thickness: WidgetStateProperty.all(8.0),
                                    radius: const Radius.circular(4.0),
                                  ),
                                ),
                                child: Scrollbar(
                                  controller: scrollController,
                                  thumbVisibility: true,
                                  trackVisibility: true,
                                  child: ListView.builder(
                                    controller: scrollController,
                                    itemCount: sortedHistory.length,
                                    itemExtent: 80,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(
                                      parent: BouncingScrollPhysics(),
                                    ),
                                    itemBuilder: (context, index) {
                                      final record = sortedHistory[index];
                                      return Container(
                                        margin: const EdgeInsets.symmetric(
                                            vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
                                              blurRadius: 2,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: _getRecordColor(
                                                index, sortMethod),
                                            child: Text('${index + 1}'),
                                          ),
                                          title: Text(
                                            '${record.date.year}/${record.date.month}/${record.date.day} ${record.date.hour.toString().padLeft(2, '0')}:${record.date.minute.toString().padLeft(2, '0')}',
                                          ),
                                          subtitle: Text(
                                            '移動: ${record.moves} | 時間: ${record.duration.inMinutes}分${record.duration.inSeconds % 60}秒',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ),
                      // 按鈕行
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                gameHistory.clear();
                              });
                              _saveGameHistory();
                              Navigator.of(dialogContext).pop();
                            },
                            child: const Text('清除記錄'),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              Navigator.of(dialogContext).pop();
                            },
                            child: const Text('關閉'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  // 根據排名獲取顏色
  Color _getRecordColor(int index, int sortMethod) {
    // 只有排序方式不是默認時才使用特殊顏色
    if (sortMethod == 0 || index > 2) {
      return Colors.blue;
    }

    // 前三名用不同顏色
    switch (index) {
      case 0:
        return Colors.amber; // 金色
      case 1:
        return Colors.grey.shade400; // 銀色
      case 2:
        return Colors.brown.shade300; // 銅色
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
        actions: [
          // 顯示移動次數
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('移動: $moves',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          // 添加自動回收按鈕
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: _autoCollectToFoundation,
            tooltip: '自動回收可移動的牌',
          ),
          // 添加查看歷史按鈕
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistoryDialog,
            tooltip: '查看歷史記錄',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: '幫助',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartGame,
            tooltip: '重新開始',
          ),
        ],
      ),
      body: Column(
        children: [
          // 上方區域：自由單元格和基礎堆
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                // 自由單元格
                Expanded(
                  child: Row(
                    children: List.generate(4, (index) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _handleFreeCellTap(index),
                          child: Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(4),
                            color: selectedFromFreeCell == true &&
                                    selectedColumnIndex == index
                                ? Colors.blueAccent.withOpacity(0.3)
                                : Colors.grey.shade200,
                            child: Container(
                              height: 70,
                              alignment: Alignment.center,
                              child: freeCells[index] != null
                                  ? CardWidgetSimple(
                                      card: freeCells[index]!, size: 60)
                                  : const Text('自由格'),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                // 基礎堆
                Expanded(
                  child: Row(
                    children: List.generate(4, (index) {
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => _handleFoundationTap(index),
                          child: Material(
                            elevation: 2,
                            borderRadius: BorderRadius.circular(4),
                            color: Colors.grey.shade200,
                            child: Container(
                              height: 70,
                              alignment: Alignment.center,
                              child: foundations[index].isNotEmpty
                                  ? CardWidgetSimple(
                                      card: foundations[index].last, size: 60)
                                  : Text(
                                      suits[index],
                                      style: TextStyle(
                                        fontSize: 24,
                                        color: suits[index] == '♥' ||
                                                suits[index] == '♦'
                                            ? Colors.red
                                            : Colors.black,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
          // 遊戲區域
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: Colors.green.shade800.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(8, (columnIndex) {
                  return Container(
                    width: MediaQuery.of(context).size.width / 8.5,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
                    child: Column(
                      children: [
                        // 列頂部的空白區域（可點擊以放置牌）
                        GestureDetector(
                          onTap: () {
                            if (selectedCard != null &&
                                columns[columnIndex].isEmpty) {
                              if (selectedFromFreeCell == true) {
                                // 從自由單元格移動到空列
                                setState(() {
                                  columns[columnIndex].add(selectedCard!);
                                  freeCells[selectedColumnIndex!] = null;
                                  selectedCard = null;
                                  selectedColumnIndex = null;
                                  selectedCardIndex = null;
                                  selectedFromFreeCell = null;
                                  selectedFromFoundation = false;
                                });
                                _incrementMoves();
                              } else if (selectedFromFoundation == true) {
                                // 從基礎堆移動到空列
                                setState(() {
                                  columns[columnIndex].add(selectedCard!);
                                  foundations[selectedColumnIndex!]
                                      .removeLast();
                                  selectedCard = null;
                                  selectedColumnIndex = null;
                                  selectedCardIndex = null;
                                  selectedFromFreeCell = null;
                                  selectedFromFoundation = false;
                                });
                                _incrementMoves();
                              } else if (selectedCardIndex != null) {
                                // 移動整個序列到空列
                                _moveCardSequence(selectedColumnIndex!,
                                    columnIndex, selectedCardIndex!);
                                setState(() {
                                  selectedCard = null;
                                  selectedColumnIndex = null;
                                  selectedCardIndex = null;
                                  selectedFromFreeCell = null;
                                  selectedFromFoundation = false;
                                });
                              }
                            }
                          },
                          child: Container(
                            height: 25,
                            decoration: BoxDecoration(
                              color: columns[columnIndex].isEmpty
                                  ? Colors.blueAccent.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.black12,
                                width: columns[columnIndex].isEmpty ? 1 : 0,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        // 列中的牌 - 堆疊顯示
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              if (columns[columnIndex].isEmpty) {
                                return Container(); // 如果列為空，則顯示空容器
                              }

                              // 計算牌的堆疊偏移量，保證所有牌都在可見範圍內
                              double maxHeight = constraints.maxHeight;
                              int cardCount = columns[columnIndex].length;
                              double availableHeight =
                                  maxHeight - 60; // 減去一張牌的高度，確保最後一張牌完全可見
                              double offset = cardCount <= 1
                                  ? 0
                                  : availableHeight / (cardCount - 1);

                              // 限制偏移量在合理範圍內
                              offset = offset.clamp(15.0, 35.0);

                              return Stack(
                                alignment: Alignment.topCenter,
                                clipBehavior: Clip.none,
                                children: List.generate(cardCount, (cardIndex) {
                                  // 創建每張牌的堆疊效果
                                  bool isTopCard = cardIndex == cardCount - 1;
                                  domain.PlayingCard currentCard =
                                      columns[columnIndex][cardIndex];

                                  // 檢查當前牌是否可選擇（頂部牌或形成有效序列的一部分）
                                  bool isSelectable = isTopCard;
                                  if (!isSelectable &&
                                      cardIndex < cardCount - 1) {
                                    // 檢查從當前位置到頂部是否形成有效序列
                                    bool formsValidSequence = true;
                                    for (int i = cardIndex;
                                        i < cardCount - 1;
                                        i++) {
                                      if (columns[columnIndex][i].value !=
                                              columns[columnIndex][i + 1]
                                                      .value +
                                                  1 ||
                                          columns[columnIndex][i].isRed ==
                                              columns[columnIndex][i + 1]
                                                  .isRed) {
                                        formsValidSequence = false;
                                        break;
                                      }
                                    }
                                    isSelectable = formsValidSequence;
                                  }

                                  // 檢查當前牌是否是選中的牌組的一部分
                                  bool isPartOfSelectedSequence =
                                      selectedColumnIndex == columnIndex &&
                                          selectedFromFreeCell == false &&
                                          selectedCardIndex != null &&
                                          cardIndex >= selectedCardIndex!;

                                  return Positioned(
                                    top: cardIndex * offset, // 動態計算偏移量
                                    child: GestureDetector(
                                      // 允許點擊任何牌（邏輯檢查放在handler中）
                                      onTap: () => _handleCardTap(
                                          currentCard, columnIndex, cardIndex),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: isPartOfSelectedSequence
                                              ? Border.all(
                                                  color: Colors.blue, width: 2)
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: CardWidgetSimple(
                                          card: currentCard,
                                          size: 40,
                                          isSelectable: isSelectable,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 添加遊戲記錄類
class GameRecord {
  final DateTime date;
  final int moves;
  final Duration duration;

  GameRecord({
    required this.date,
    required this.moves,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'moves': moves,
      'duration': duration.inSeconds,
    };
  }

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      date: DateTime.parse(json['date']),
      moves: json['moves'],
      duration: Duration(seconds: json['duration']),
    );
  }
}
