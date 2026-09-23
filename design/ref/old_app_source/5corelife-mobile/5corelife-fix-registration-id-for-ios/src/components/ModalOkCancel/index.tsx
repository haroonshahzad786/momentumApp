import React from 'react'
import { ImageBackground, Text, TouchableOpacity, View } from 'react-native'
import Modal from 'react-native-modal'
import props from './props'
import styles from './styles'

export default ({
  textTitle,
  textTitleStyle,
  cancelButtonStyle,
  cancelButtonImage,
  okButtonStyle,
  okButtonImage,
  onCancel,
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
        source={require('../../assets/images/shared/screenPopup.png')}
        resizeMode={'contain'}>

        <View style={styles.containerText}>
          <Text style={[styles.textTitle, textTitleStyle]}>
            {textTitle}
          </Text>
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
