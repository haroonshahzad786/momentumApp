import React from 'react'
import { TextInput, View } from 'react-native'

import props from './props'
import styles from './styles'

export default ({
  reference,
  textInput,
  textInputStyle,
  textInputPlaceholder,
  textInputPlaceholderColor,
  keyboardType,
  autoCapitalize,
  isSecure = false,
  backgroundColor,
  borderRadius,
  borderWidth,
  borderColor,
  onChangeText,
  onSubmitEditing,
  onFocus,
  onBlur
}: props) => {
  return (
    <>
      <View style={styles.container}>
        <TextInput
          ref={reference}
          style={[
            styles.containerTextInput,
            textInputStyle,
            { backgroundColor, borderRadius, borderWidth, borderColor }
          ]}
          value={textInput}
          placeholder={textInputPlaceholder}
          placeholderTextColor={textInputPlaceholderColor}
          numberOfLines={1}
          keyboardType={keyboardType}
          autoCapitalize={autoCapitalize}
          secureTextEntry={isSecure}
          onChangeText={(text: string) => {
            onChangeText(text)
          }}
          onSubmitEditing={onSubmitEditing}
          onFocus={onFocus}
          onBlur={onBlur}
        />
      </View>
    </>
  )
}
