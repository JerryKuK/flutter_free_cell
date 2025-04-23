# Flutter Free Cell

一個使用 Flutter 框架開發的新接龍（Free Cell）紙牌遊戲應用程序。

## 技術棧

- **開發語言**：Dart
- **框架**：Flutter
- **狀態管理**：Riverpod
- **本地存儲**：SharedPreferences
- **架構**：Clean Architecture

## 應用說明

這是一個經典的新接龍紙牌遊戲實現，具有以下特點：

- 完整的遊戲規則實現
- 自動收集功能（可以自動將符合條件的卡片移動到基礎堆）
- 歷史記錄功能（記錄遊戲完成情況、移動次數和用時）
- 多種排序方式查看歷史記錄（按日期、完成時間或移動次數）

## 遊戲玩法

新接龍（Free Cell）是一種單人紙牌遊戲，目標是將所有卡片按花色和順序整理到四個基礎堆中。

- 有 8 列卡片區、4 個自由單元格和 4 個基礎堆
- 卡片只能移動到空的自由單元格、形成有效序列的列頂部或對應的基礎堆
- 列中的有效序列為不同顏色且連續遞減的卡片
- 基礎堆中的卡片必須是相同花色且從 A 開始連續遞增排列

## 項目架構

該項目採用 Clean Architecture 架構，分為：

- **領域層**（domain）：包含實體和業務邏輯
- **數據層**（data）：處理數據來源和數據存儲
- **表現層**（presentation）：處理UI和用戶交互

## 本地化

應用支持繁體中文界面。

## 開發與構建

```bash
# 獲取依賴
flutter pub get

# 運行代碼生成器
flutter pub run build_runner build --delete-conflicting-outputs

# 運行應用
flutter run
```
