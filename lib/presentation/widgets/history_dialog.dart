import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/game_record.dart';
import '../providers/history_provider.dart';

/// 歷史記錄對話框
class HistoryDialog extends ConsumerStatefulWidget {
  const HistoryDialog({super.key});

  @override
  ConsumerState<HistoryDialog> createState() => _HistoryDialogState();
}

class _HistoryDialogState extends ConsumerState<HistoryDialog> {
  /// 排序方式
  /// 0 - 按日期排序（最新在前）
  /// 1 - 按完成時間排序（從短到長）
  /// 2 - 按移動次數排序（從少到多）
  int _sortMethod = 0;

  /// 滾動控制器
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(historyNotifierProvider);
    developer.log('HistoryDialog: 載入歷史記錄，排序方式: $_sortMethod');

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16.0),
        child: historyAsync.when(
          data: (history) => _buildHistoryContent(history),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text('載入失敗: $error')),
        ),
      ),
    );
  }

  /// 構建歷史記錄內容
  Widget _buildHistoryContent(List<GameRecord> history) {
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
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('最新'),
                    selected: _sortMethod == 0,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _sortMethod = 0;
                        });
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('時間最短'),
                    selected: _sortMethod == 1,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _sortMethod = 1;
                        });
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: const Text('步數最少'),
                    selected: _sortMethod == 2,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _sortMethod = 2;
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
            child: FutureBuilder<List<GameRecord>>(
              future: ref
                  .read(historyNotifierProvider.notifier)
                  .getSortedHistory(_sortMethod),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sortedHistory = snapshot.data ?? [];
                developer.log(
                    'HistoryDialog: 獲取排序後的歷史記錄，共 ${sortedHistory.length} 條');

                if (sortedHistory.isEmpty) {
                  return const Center(child: Text('暫無歷史記錄'));
                }

                return Theme(
                  data: Theme.of(context).copyWith(
                    scrollbarTheme: ScrollbarThemeData(
                      thumbColor: WidgetStateProperty.all(Colors.grey[400]),
                      thickness: WidgetStateProperty.all(8.0),
                      radius: const Radius.circular(4.0),
                    ),
                  ),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: sortedHistory.length,
                      itemExtent: 80,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemBuilder: (context, index) {
                        final record = sortedHistory[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  _getRecordColor(index, _sortMethod),
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
                );
              },
            ),
          ),
          // 按鈕行
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () async {
                  developer.log('HistoryDialog: 清除歷史記錄');
                  await ref
                      .read(historyNotifierProvider.notifier)
                      .clearGameHistory();
                  Navigator.of(context).pop();
                },
                child: const Text('清除記錄'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('關閉'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 根據排名獲取顏色
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
}
