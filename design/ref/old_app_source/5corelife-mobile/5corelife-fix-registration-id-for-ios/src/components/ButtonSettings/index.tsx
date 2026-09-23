import React from 'react'
import { Text, TouchableOpacity, View } from 'react-native'

import props from './props'
import styles from './styles'

export default ({
  touchableOpacityContainerStyle,
  touchableOpacityContainerOnPress,
  textTitle,
  textTitleStyle,
  imageRight,
  disabled
}: props) => {
  return (
    <>
      <TouchableOpacity
        disabled={disabled}
        style={[styles.viewContainer, touchableOpacityContainerStyle]}
        activeOpacity={0.4}
        onPress={touchableOpacityContainerOnPress}>
        <Text style={[styles.textTitle, textTitleStyle]} numberOfLines={2}>
          {textTitle}
        </Text>

        <View style={styles.viewImageRight}>{imageRight}</View>
      </TouchableOpacity>
    </>
  )
}
