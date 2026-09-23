import React, { useRef } from 'react'
import { useEffect } from 'react'
import {
  TextInput,
  ImageBackground,
  Text,
  TouchableOpacity,
  View,
  Switch
} from 'react-native'
import Modal from 'react-native-modal'

import props from './props'
import styles from './styles'

export default ({
  textTitle,
  textDescription,
  textTitleStyle,
  touchableOpacityButtonStyle,
  touchableOpacityButtonOnPress,
  touchableOpacityButtonImage,
  isVisible,
}: props) => {

  return (
    <>
      <Modal
        isVisible={isVisible}
        animationIn={'slideInDown'}
        animationInTiming={500}
        animationOut={'slideOutUp'}
        animationOutTiming={500}>
        <ImageBackground
          style={styles.imageBackgroundContainer}
          source={require('../../assets/images/shared/modal_add.png')}
          resizeMode={'contain'}>
          <Text style={[textTitleStyle, styles.textTitle]}>{textTitle}</Text>
          <Text style={[textTitleStyle, styles.textDescription]}>{textDescription}</Text>
          <TouchableOpacity
            style={[styles.touchableOpacityButton, touchableOpacityButtonStyle]}
            onPress={touchableOpacityButtonOnPress}>
            {touchableOpacityButtonImage}
          </TouchableOpacity>
        </ImageBackground>
      </Modal>
    </>
  )
}
