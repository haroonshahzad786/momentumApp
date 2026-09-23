import React from 'react'
import { ActivityIndicator, Text, TouchableOpacity, View } from 'react-native'

import props from './props'
import styles from './styles'

export default ({
  textTitle,
  textTitleStyle,
  touchableOpacityContainerStyle,
  spinnerSize = 20,
  spinnerColor,
  isLoading = false,
  onPress,
  disabled = false
}: props) => {
  return (
    <>
      <TouchableOpacity
        style={[styles.container, touchableOpacityContainerStyle]}
        activeOpacity={isLoading ? 1 : 0.4}
        onPress={isLoading ? null : onPress}
        disabled={disabled}>
        {isLoading ? (
          <View>
            <ActivityIndicator color={spinnerColor} size={spinnerSize} />
          </View>
        ) : (
          <View>
            <Text style={textTitleStyle}>{textTitle}</Text>
          </View>
        )}
      </TouchableOpacity>
    </>
  )
}
