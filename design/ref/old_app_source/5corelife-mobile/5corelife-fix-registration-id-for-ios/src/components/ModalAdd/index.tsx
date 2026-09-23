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
  textTitleStyle,
  textInput,
  textInputStyle,
  textInputOnChangeText,
  textSwitchOff,
  textSwitchOn,
  textSwitchStyle,
  switchTrackColor,
  switchThumbColor,
  switchIsEnabled,
  switchOnChange,
  touchableOpacityButtonImage,
  touchableOpacityButtonStyle,
  touchableOpacityButtonOnPress,
  isVisible
}: props) => {
  const textInputMantraRef = useRef<TextInput>(null);
  const [text, setText] = React.useState('');

  const changeTextInput = (text: string) => {
    setText(text);
    textInputOnChangeText(text);
  }

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

          <View style={styles.viewTextInput}>
            <TextInput
              ref={textInputMantraRef}
              style={[styles.textInput, textInputStyle]}
              value={text}
              onChangeText={changeTextInput}
              textAlign="center"
            />
          </View>

          <View style={styles.viewSwitch}>
            <Text style={[styles.textSwitch, textSwitchStyle]}>
              {textSwitchOff}
            </Text>
            <Switch
              trackColor={switchTrackColor}
              thumbColor={switchThumbColor}
              onValueChange={() => {
                switchOnChange(!switchIsEnabled)
              }}
              value={switchIsEnabled}
            />
            <Text style={[styles.textSwitch, textSwitchStyle]}>
              {textSwitchOn}
            </Text>
          </View>

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
