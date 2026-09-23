import React from 'react'
import { Text, TouchableOpacity } from 'react-native'

import props from './props'

export default ({
  touchableOpacityContainerStyle,
  touchableOpacityContainerOnPress,
  touchableOpacityContainerOnLongPress,
  textTitle,
  textTitleStyle,
  disabled = false
}: props) => {
  return (
    <>
      <TouchableOpacity
        style={touchableOpacityContainerStyle}
        activeOpacity={touchableOpacityContainerOnPress ? 0.4 : 1}
        onPress={touchableOpacityContainerOnPress}
        onLongPress={touchableOpacityContainerOnLongPress}
        disabled={disabled}>
        <Text style={textTitleStyle}>{textTitle}</Text>
      </TouchableOpacity>
    </>
  )
}
