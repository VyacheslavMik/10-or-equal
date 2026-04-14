import React, {useEffect, useMemo, useState} from 'react';
import {
  ActivityIndicator,
  Dimensions,
  ScrollView,
  StyleSheet,
  Text,
  TouchableOpacity,
  View,
} from 'react-native';
import AsyncStorage from '@react-native-async-storage/async-storage';

const COLUMNS = 9;
const SCREEN_PADDING = 16;
const CELL_GAP = 1;
const CELL_SIZE = Math.floor(
  (Dimensions.get('window').width - SCREEN_PADDING * 2 - CELL_GAP * COLUMNS * 2) /
    COLUMNS,
);
const STORAGE_KEY = 'ten-or-equal:game-state';

const initialNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 1, 1, 2];
const createInitialGrid = () =>
  initialNumbers.map(value => ({value, active: true}));

const createNewGameState = () => ({
  screen: 'game',
  grid: createInitialGrid(),
});

const getCoords = index => [Math.floor(index / COLUMNS), index % COLUMNS];
const getIndex = (row, col) => row * COLUMNS + col;

const areNeighborsInGrid = (grid, i1, i2) => {
  if (i1 === i2 || !grid[i1]?.active || !grid[i2]?.active) {
    return false;
  }

  const [r1, c1] = getCoords(i1);

  for (let i = i1 - 1; i >= 0; i--) {
    if (grid[i].active) {
      if (i === i2) {
        return true;
      }
      break;
    }
  }

  for (let i = i1 + 1; i < grid.length; i++) {
    if (grid[i].active) {
      if (i === i2) {
        return true;
      }
      break;
    }
  }

  for (let row = r1 - 1; row >= 0; row--) {
    const index = getIndex(row, c1);
    if (grid[index] && grid[index].active) {
      if (index === i2) {
        return true;
      }
      break;
    }
  }

  for (let row = r1 + 1; getIndex(row, c1) < grid.length; row++) {
    const index = getIndex(row, c1);
    if (grid[index] && grid[index].active) {
      if (index === i2) {
        return true;
      }
      break;
    }
  }

  return false;
};

const isMatchingPair = (firstCell, secondCell) =>
  firstCell.value === secondCell.value || firstCell.value + secondCell.value === 10;

const hasAvailableMove = grid => {
  for (let firstIndex = 0; firstIndex < grid.length; firstIndex++) {
    const firstCell = grid[firstIndex];
    if (!firstCell.active) {
      continue;
    }

    for (let secondIndex = firstIndex + 1; secondIndex < grid.length; secondIndex++) {
      const secondCell = grid[secondIndex];
      if (
        secondCell.active &&
        isMatchingPair(firstCell, secondCell) &&
        areNeighborsInGrid(grid, firstIndex, secondIndex)
      ) {
        return true;
      }
    }
  }

  return false;
};

const appendActiveCells = grid => {
  const activeCells = grid.filter(cell => cell.active);
  const newCells = activeCells.map(cell => ({
    value: cell.value,
    active: true,
  }));

  return [...grid, ...newCells];
};

const continueIfNoMoves = grid => {
  if (grid.every(cell => !cell.active) || hasAvailableMove(grid)) {
    return grid;
  }

  return appendActiveCells(grid);
};

function GameButton({title, onPress, testID, compact = false}) {
  return (
    <TouchableOpacity
      accessibilityRole="button"
      testID={testID}
      style={[styles.gameButton, compact && styles.compactButton]}
      onPress={onPress}>
      <Text style={[styles.gameButtonText, compact && styles.compactButtonText]}>
        {title}
      </Text>
    </TouchableOpacity>
  );
}

export default function GameScreen() {
  const [screen, setScreen] = useState('loading');
  const [grid, setGrid] = useState(createInitialGrid);
  const [selected, setSelected] = useState([]);
  const [savedGame, setSavedGame] = useState(null);
  const [isHydrated, setIsHydrated] = useState(false);

  useEffect(() => {
    const loadGame = async () => {
      try {
        const rawState = await AsyncStorage.getItem(STORAGE_KEY);
        if (rawState) {
          const parsedState = JSON.parse(rawState);
          if (Array.isArray(parsedState.grid)) {
            setSavedGame(parsedState);
            setGrid(parsedState.grid);
          }
        }
      } catch (error) {
        console.warn('Не удалось загрузить сохранение', error);
      } finally {
        setScreen('menu');
        setIsHydrated(true);
      }
    };

    loadGame();
  }, []);

  useEffect(() => {
    if (!isHydrated || screen === 'loading' || screen === 'menu') {
      return;
    }

    const saveGame = async () => {
      const nextState = {screen, grid};
      try {
        await AsyncStorage.setItem(STORAGE_KEY, JSON.stringify(nextState));
        setSavedGame(nextState);
      } catch (error) {
        console.warn('Не удалось сохранить игру', error);
      }
    };

    saveGame();
  }, [grid, isHydrated, screen]);

  const activeCount = useMemo(
    () => grid.filter(cell => cell.active).length,
    [grid],
  );

  const startGame = () => {
    if (savedGame?.screen === 'game' && Array.isArray(savedGame.grid)) {
      setGrid(continueIfNoMoves(savedGame.grid));
    } else {
      setGrid(createInitialGrid());
    }

    setSelected([]);
    setScreen('game');
  };

  const startNewGame = () => {
    const nextGame = createNewGameState();
    setGrid(nextGame.grid);
    setSelected([]);
    setScreen(nextGame.screen);
  };

  const showGameOver = () => {
    setSelected([]);
    setScreen('gameOver');
  };

  const handleCellPress = index => {
    const cell = grid[index];
    if (!cell.active) {
      return;
    }

    if (selected.includes(index)) {
      setSelected(selected.filter(item => item !== index));
      return;
    }

    if (selected.length === 0) {
      setSelected([index]);
      return;
    }

    const firstIndex = selected[0];

    if (
      isMatchingPair(grid[firstIndex], grid[index]) &&
      areNeighborsInGrid(grid, firstIndex, index)
    ) {
      const nextGrid = grid.map((item, itemIndex) =>
        itemIndex === firstIndex || itemIndex === index
          ? {...item, active: false}
          : item,
      );

      if (nextGrid.every(item => !item.active)) {
        setGrid(nextGrid);
        showGameOver();
      } else {
        setGrid(continueIfNoMoves(nextGrid));
      }
    }

    setSelected([]);
  };

  if (screen === 'loading') {
    return (
      <View style={styles.centeredScreen}>
        <ActivityIndicator size="large" />
        <Text style={styles.secondaryText}>Загрузка игры...</Text>
      </View>
    );
  }

  if (screen === 'menu') {
    return (
      <View style={styles.centeredScreen}>
        <Text style={styles.title}>10 или равно</Text>
        <Text style={styles.description}>
          Найдите две соседние цифры: одинаковые или с суммой 10.
        </Text>
        <View style={styles.menuButton}>
          <GameButton title="Начать" testID="start-button" onPress={startGame} />
        </View>
      </View>
    );
  }

  if (screen === 'gameOver') {
    return (
      <View style={styles.centeredScreen}>
        <Text style={styles.title}>Игра окончена</Text>
        <Text style={styles.description}>
          Отлично! Все числа убраны с поля.
        </Text>
        <View style={styles.menuButton}>
          <GameButton
            title="Начать заново"
            testID="restart-button"
            onPress={startNewGame}
          />
        </View>
        <View style={styles.menuButton}>
          <GameButton
            title="В меню"
            testID="menu-button"
            onPress={() => setScreen('menu')}
          />
        </View>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.statusText}>Осталось: {activeCount}</Text>
        <GameButton
          title="Меню"
          testID="menu-button"
          compact
          onPress={() => setScreen('menu')}
        />
      </View>
      <ScrollView contentContainerStyle={styles.grid}>
        {grid.map((cell, index) => (
          <TouchableOpacity
            key={index}
            testID={`cell-${index}`}
            style={[
              styles.cell,
              !cell.active && styles.inactiveCell,
              selected.includes(index) && styles.selectedCell,
            ]}
            onPress={() => handleCellPress(index)}>
            <Text style={styles.cellText}>{cell.active ? cell.value : ''}</Text>
          </TouchableOpacity>
        ))}
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
    backgroundColor: '#fff',
  },
  centeredScreen: {
    flex: 1,
    justifyContent: 'center',
    padding: 24,
    backgroundColor: '#fff',
  },
  title: {
    marginBottom: 16,
    fontSize: 32,
    fontWeight: '700',
    textAlign: 'center',
    color: '#222',
  },
  description: {
    marginBottom: 24,
    fontSize: 18,
    lineHeight: 26,
    textAlign: 'center',
    color: '#444',
  },
  secondaryText: {
    marginTop: 16,
    fontSize: 16,
    textAlign: 'center',
    color: '#555',
  },
  menuButton: {
    marginTop: 12,
  },
  gameButton: {
    minHeight: 44,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 10,
    paddingHorizontal: 16,
    backgroundColor: '#1f7a5c',
  },
  compactButton: {
    minHeight: 36,
    paddingVertical: 7,
    paddingHorizontal: 12,
  },
  gameButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
  compactButtonText: {
    fontSize: 14,
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 12,
  },
  statusText: {
    fontSize: 18,
    fontWeight: '600',
    color: '#222',
  },
  grid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
  },
  cell: {
    width: CELL_SIZE,
    height: CELL_SIZE,
    borderWidth: 1,
    borderColor: '#888',
    justifyContent: 'center',
    alignItems: 'center',
    margin: 1,
    backgroundColor: '#eee',
  },
  inactiveCell: {
    backgroundColor: '#ccc',
  },
  selectedCell: {
    backgroundColor: '#99f',
  },
  cellText: {
    fontSize: 18,
  },
});
