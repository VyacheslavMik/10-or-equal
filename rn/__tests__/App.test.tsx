/**
 * @format
 */

import React from 'react';
import {Text} from 'react-native';
import ReactTestRenderer from 'react-test-renderer';

const mockGetItem = jest.fn(() => Promise.resolve(null));
const mockSetItem = jest.fn(() => Promise.resolve());

jest.mock('@react-native-async-storage/async-storage', () => ({
  __esModule: true,
  default: {
    getItem: (...args: unknown[]) => mockGetItem(...args),
    setItem: (...args: unknown[]) => mockSetItem(...args),
  },
}));

import App from '../App';

beforeEach(() => {
  mockGetItem.mockResolvedValue(null);
  mockSetItem.mockResolvedValue(undefined);
});

const startGame = async (renderer: ReactTestRenderer.ReactTestRenderer) => {
  await ReactTestRenderer.act(async () => {
    renderer.root.findByProps({testID: 'start-button'}).props.onPress();
    await Promise.resolve();
  });
};

const pressCell = async (
  renderer: ReactTestRenderer.ReactTestRenderer,
  index: number,
) => {
  await ReactTestRenderer.act(async () => {
    renderer.root.findByProps({testID: `cell-${index}`}).props.onPress();
    await Promise.resolve();
  });
};

const getCellText = (
  renderer: ReactTestRenderer.ReactTestRenderer,
  index: number,
) =>
  renderer.root.findByProps({testID: `cell-${index}`}).findByType(Text).props
    .children;

test('renders correctly', async () => {
  await ReactTestRenderer.act(async () => {
    ReactTestRenderer.create(<App />);
    await Promise.resolve();
  });
});

test('removes 9 and 1 across the first row boundary', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer;

  await ReactTestRenderer.act(async () => {
    renderer = ReactTestRenderer.create(<App />);
    await Promise.resolve();
  });

  await startGame(renderer!);
  await pressCell(renderer!, 8);
  await pressCell(renderer!, 9);

  expect(getCellText(renderer!, 8)).toBe('');
  expect(getCellText(renderer!, 9)).toBe('');
});

test('removes 8 and 2 across removed cells at a row boundary', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer;

  await ReactTestRenderer.act(async () => {
    renderer = ReactTestRenderer.create(<App />);
    await Promise.resolve();
  });

  await startGame(renderer!);
  await pressCell(renderer!, 8);
  await pressCell(renderer!, 9);
  await pressCell(renderer!, 10);
  await pressCell(renderer!, 11);
  await pressCell(renderer!, 7);
  await pressCell(renderer!, 12);

  expect(getCellText(renderer!, 7)).toBe('');
  expect(getCellText(renderer!, 12)).toBe('');
});

test('does not render manual continue button', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer;

  await ReactTestRenderer.act(async () => {
    renderer = ReactTestRenderer.create(<App />);
    await Promise.resolve();
  });

  await startGame(renderer!);

  expect(renderer!.root.findAllByProps({testID: 'continue-button'})).toHaveLength(
    0,
  );
});

test('automatically appends active cells when no moves remain', async () => {
  let renderer: ReactTestRenderer.ReactTestRenderer;

  mockGetItem.mockResolvedValueOnce(
    JSON.stringify({
      screen: 'game',
      grid: [
        {value: 1, active: true},
        {value: 9, active: true},
        {value: 3, active: true},
      ],
    }),
  );

  await ReactTestRenderer.act(async () => {
    renderer = ReactTestRenderer.create(<App />);
    await Promise.resolve();
  });

  await startGame(renderer!);
  await pressCell(renderer!, 0);
  await pressCell(renderer!, 1);

  expect(getCellText(renderer!, 0)).toBe('');
  expect(getCellText(renderer!, 1)).toBe('');
  expect(getCellText(renderer!, 2)).toBe(3);
  expect(getCellText(renderer!, 3)).toBe(3);
});
