import React, { useState } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ScrollView, Button } from 'react-native';

const COLUMNS = 9;

const initialNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 1, 1, 1, 2];
const initialGrid = initialNumbers.map((value) => ({ value, active: true }));

export default function GameScreen() {
    const [grid, setGrid] = useState(initialGrid);
    const [selected, setSelected] = useState([]);

    const getCoords = (index) => [Math.floor(index / COLUMNS), index % COLUMNS];
    const getIndex = (row, col) => row * COLUMNS + col;

    const areNeighbors = (i1, i2) => {
	if (i1 === i2) return false;
	const [r1, c1] = getCoords(i1);
	const [r2, c2] = getCoords(i2);

	// Horizontal left
	for (let i = i1 - 1; i >= r1 * COLUMNS; i--) {
	    if (grid[i].active) {
		if (i === i2) return true;
		break;
	    }
	}

	// Horizontal right
	for (let i = i1 + 1; i < (r1 + 1) * COLUMNS && i < grid.length; i++) {
	    if (grid[i].active) {
		if (i === i2) return true;
		break;
	    }
	}

	// Vertical up
	for (let r = r1 - 1; r >= 0; r--) {
	    const idx = getIndex(r, c1);
	    if (grid[idx] && grid[idx].active) {
		if (idx === i2) return true;
		break;
	    }
	}

	// Vertical down
	for (let r = r1 + 1; getIndex(r, c1) < grid.length; r++) {
	    const idx = getIndex(r, c1);
	    if (grid[idx] && grid[idx].active) {
		if (idx === i2) return true;
		break;
	    }
	}

	// Wrap to previous row (left edge)
	if (c1 === 0 && r1 > 0) {
	    for (let i = getIndex(r1 - 1, COLUMNS - 1); i >= getIndex(r1 - 1, 0); i--) {
		if (grid[i].active) {
		    return i === i2;
		}
	    }
	}

	// Wrap to next row (right edge)
	if (c1 === COLUMNS - 1 && getIndex(r1 + 1, 0) < grid.length) {
	    for (let i = getIndex(r1 + 1, 0); i <= getIndex(r1 + 1, COLUMNS - 1); i++) {
		if (grid[i].active) {
		    return i === i2;
		}
	    }
	}

	return false;
    };

    const handleCellPress = (index) => {
	console.log(grid);
	const cell = grid[index];
	if (!cell.active) return;

	if (selected.includes(index)) {
	    setSelected(selected.filter((i) => i !== index));
	} else if (selected.length === 0) {
	    setSelected([index]);
	} else if (selected.length === 1) {
	    const i1 = selected[0];
	    const i2 = index;
	    const v1 = grid[i1].value;
	    const v2 = grid[i2].value;

	    if ((v1 === v2 || v1 + v2 === 10) && areNeighbors(i1, i2)) {
		const newGrid = [...grid];
		newGrid[i1].active = false;
		newGrid[i2].active = false;
		setGrid(newGrid);
	    }
	    setSelected([]);
	}
    };

    const handleContinue = () => {
	const activeCells = grid.filter(cell => cell.active);
	const newCells = activeCells.map(cell => ({
	    value: cell.value,
	    active: true,
	}));
	setGrid([...grid, ...newCells]);
	setSelected([]);
    };

    return (
	<View style={styles.container}>
	    <ScrollView contentContainerStyle={styles.grid}>
		{grid.map((cell, index) => (
		    <TouchableOpacity
			key={index}
			style={[
			    styles.cell,
			    !cell.active && styles.inactiveCell,
			    selected.includes(index) && styles.selectedCell,
			]}
			onPress={() => handleCellPress(index)}
		    >
			<Text style={styles.cellText}>{cell.active ? cell.value : ''}</Text>
		    </TouchableOpacity>
		))}
	    </ScrollView>
	    <View style={styles.button}>
		<Button title="Продолжить" onPress={handleContinue} />
	    </View>
	</View>
    );
}

const styles = StyleSheet.create({
    container: { flex: 1, padding: 16, backgroundColor: '#fff' },
    grid: { flexDirection: 'row', flexWrap: 'wrap' },
    cell: {
	width: 36,
	height: 36,
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
    button: {
	marginTop: 12,
    },
});
