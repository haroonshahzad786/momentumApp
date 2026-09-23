import React from 'react'
import { Text, TouchableOpacity, View } from 'react-native'

import props from './props'
import styles from './styles'

export default ({
  numbers,
  selectedNumber,
  touchableOpacityNumberStyle,
  touchableOpacityNumberSelectedStyle,
  textNumberStyle,
  textNumberSelectedStyle,
  onPress
}: props) => {
  return (
    <>
      <View style={styles.viewContainer}>
        {numbers.map((x) => (
          <TouchableOpacity
            style={[
              styles.touchableOpacityNumberStyle,
              x === selectedNumber
                ? touchableOpacityNumberSelectedStyle
                : touchableOpacityNumberStyle
            ]}
            onPress={() => onPress(x)}>
            <Text
              style={
                x === selectedNumber ? textNumberSelectedStyle : textNumberStyle
              }>
              {x}
            </Text>
          </TouchableOpacity>
        ))}
      </View>
    </>
  )
}
