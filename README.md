# Samosa Tracker

A simple Flutter mobile app for tracking a small food business (samosa sales).

## Features

- **Dashboard** – Total sales, expenses, and profit for today
- **Sales Entry** – Record ndengu and meat samosa sales with auto-calculated revenue
- **Expenses** – Add expenses with name and amount (date stored automatically)
- **Reports** – Daily and weekly profit, plus a full transaction list

## Tech Stack

- **Flutter** – Cross-platform mobile
- **Drift** – SQLite-based local database
- **Riverpod** – State management
- **Material 3** – UI components

## Getting Started

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run
```

## Configuration

Samosa prices are defined in `lib/core/constants.dart`:
- Ndengu: KES 30
- Meat: KES 50

Edit these values to match your business prices.

## Data Persistence

All data is stored locally in SQLite. The database file is created in the app's documents directory and persists across app restarts.
