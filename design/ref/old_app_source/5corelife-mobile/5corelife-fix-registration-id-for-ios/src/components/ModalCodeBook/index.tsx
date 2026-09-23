import React from 'react'
import { Image, ImageBackground, Text, TouchableOpacity, View } from 'react-native'
import { TextInput } from 'react-native-gesture-handler'
import Modal from 'react-native-modal'
import props from './props'
import styles from './styles'

export default ({
  textTitle,
  textInputStyle,
  textInput,
  autoCapitalize,
  keyboardType,
  isSecure,
  maxLength,
  onChangeText,
  textTitleStyle,
  cancelButtonStyle,
  cancelButtonImage,
  onCancel,
  okButtonStyle,
  okButtonImage,
  onOk,
  isVisible
}: props) => {

  return (
    <Modal
      isVisible={isVisible}
      animationIn={'slideInDown'}
      animationInTiming={500}
      animationOut={'slideOutUp'}
      animationOutTiming={500}
    >
      <ImageBackground
        style={styles.imageBackgroundContainer}
        source={require('../../assets/images/shared/modal_add_item.png')}
        resizeMode={'contain'}>
        <Text style={[textTitleStyle, styles.textTitle]}>{textTitle}</Text>

        <View style={styles.containerTextLine}>
          <TextInput
            style={[
              {
                color: textInputStyle[1]
              },
              textInputStyle[0],
              styles.textInput,
            ]}
            numberOfLines={1}
            autoFocus={true}
            maxLength={maxLength}
            value={textInput}
            keyboardType={keyboardType}
            autoCapitalize={autoCapitalize}
            secureTextEntry={isSecure}
            onChangeText={(text: string) => {
              onChangeText(text)
            }}
          />
          <View style={styles.containerImage}>
            <View style={styles.containerLine} >
              <Image source={require('../../assets/images/shared/codeLines.png')}
                style={[styles.styleLine, styles.spaceLine]}
                resizeMode="contain" />
              <Image source={require('../../assets/images/shared/codeLines.png')}
                style={styles.styleLine}
                resizeMode="contain" />
            </View>
            <View >
              <Image source={require('../../assets/images/settings/icon_qr.png')}
                style={styles.codeQR}
                resizeMode="contain" />
            </View>
          </View>
        </View>

        <View style={styles.containerButtons}>
          <TouchableOpacity
            style={[styles.cancelButton, cancelButtonStyle]}
            onPress={onCancel}>
            {cancelButtonImage}
          </TouchableOpacity>
          <TouchableOpacity
            style={[styles.okButton, okButtonStyle]}
            onPress={onOk}>
            {okButtonImage}
          </TouchableOpacity>
        </View>

      </ImageBackground>
    </Modal>
  )
}
