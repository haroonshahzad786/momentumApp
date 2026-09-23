import AsyncStorage from '@react-native-async-storage/async-storage'
import { logger } from './logger'

export const getStorageData = async (key: string) => {
  try {
    const jsonValue = await AsyncStorage.getItem(key)
    return jsonValue != null ? JSON.parse(jsonValue) : null
  } catch (e) {
    // Error reading data.
  }
}

export const setStorageData = async (key: string, value: any) => {
  try {
    const jsonValue = JSON.stringify(value)
    await AsyncStorage.setItem(key, jsonValue)
  } catch (e) {
    logger.error('Error saving data', e)
    // Error saving data.
  }
}

export const removeStorageData = async (key: string) => {
  try {
    await AsyncStorage.removeItem(key)
  } catch (e) {
    logger.error('Error saving data', e)
    // Error remove data.
  }
}

export const clearStorageData = async () => {
  try {
    await AsyncStorage.clear()
  } catch (e) {
    logger.error('Error saving data', e)
    // Error clear data.
  }
}

export const getAllItems = async () => {
  try {
    const arrayItems = await AsyncStorage.getAllKeys()
    return arrayItems;
  } catch (e) {
    logger.debug('Error saving data', e)
    // Error all data.
  }
}
