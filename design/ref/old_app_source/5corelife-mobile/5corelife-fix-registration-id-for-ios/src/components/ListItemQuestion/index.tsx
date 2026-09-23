import React from 'react'
import { Image, KeyboardAvoidingView, Platform, ScrollView, Text, View } from 'react-native'
import { TextInput } from 'react-native-gesture-handler'

import props from './props'
import styles from './styles'

export default ({
  index,
  question,
  textTitleStyle,
  textInputAnswer,
  textInputAnswerStyle,
  textInputAnswerOnChangeText,
  placeholder,
  placeholderColor
}: props) => {
  const { title } = question

  return (
    <>
      <View style={styles.container}>
          <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : "height"}
            contentContainerStyle={{ flex: 1 }}>
            <View style={[styles.containerTextTitle, styles.separationHorizontal]}>
              <Text style={textTitleStyle} numberOfLines={1}>
                {title}
              </Text>
            </View>

            <View style={styles.containerImageSeparator}>
              <Image
                style={styles.imageSeparator}
                source={require('../../assets/images/cockpit_self_review/separator.png')}
                resizeMode={'cover'}
              />
            </View>


            <View style={[styles.containerTextInputAnswer, styles.separationHorizontal]}>

              <TextInput
                style={[textInputAnswerStyle, styles.textInputAnswer]}
                value={textInputAnswer}
                placeholderTextColor={placeholderColor}
                placeholder={placeholder}
                numberOfLines={1}
                maxLength={300}
                onChangeText={(text) => textInputAnswerOnChangeText(index, text)}
              />

            </View>
          </KeyboardAvoidingView>
      </View >
    </>
  )
}
