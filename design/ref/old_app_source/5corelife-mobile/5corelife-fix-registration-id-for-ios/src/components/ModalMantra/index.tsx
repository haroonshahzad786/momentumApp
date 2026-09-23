import React, { useRef, useState } from 'react'
import {
  TextInput,
  ImageBackground,
  Text,
  TouchableOpacity,
  View,
  ViewStyle,
  ScrollView,
  Platform
} from 'react-native'
import Modal from 'react-native-modal'

import Button from '../Button'
import props from './props'
import styles from './styles'
import { logger } from '../../helpers/logger'

export default ({
  textTitle,
  textTitleStyle,
  iconRight,
  textInputParagraphFirst,
  textInputParagraphStyle,
  textInputParagraphFirstOnChangeText,
  textParagraphDividerStyle,
  touchableOpacityContainerButtonStyle,
  touchableOpacityContainerButtonOnPress,
  textTitleButton,
  textTitleButtonStyle,
  isVisible
}: props) => {
  logger.info("[<ModalMantra>]")
  const textInputMantraRef = useRef<TextInput>(null)
  const [textEdit, setTextEdit] = useState<boolean>(false)

  logger.debug("line 35 ModalMantra.index textInputParagraphFirst: ",textInputParagraphFirst);
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
          source={require('../../assets/images/cockpit_categories/mantra.png')}
          resizeMode={'stretch'}>
          <View style={{ flex: 1 }}>
            <Text style={[textTitleStyle, styles.textTitle]}>{textTitle}</Text>

            <TouchableOpacity
              style={styles.touchableOpacityImageIconRight}
              onPress={() => setTextEdit(!textEdit)}>
              {iconRight}
            </TouchableOpacity>

            <ScrollView style={{ flexGrow: 1 }} keyboardShouldPersistTaps={'handled'}>
              <View style={styles.viewParagraphs} >
                <TextInput
                  ref={textInputMantraRef}
                  style={[styles.textInputParagraphFirst, textInputParagraphStyle]}
                  value={textInputParagraphFirst}
                  multiline
                  scrollEnabled
                  // editable={false}
                  pointerEvents={textEdit ? 'auto' : 'none'}
                  showSoftInputOnFocus={textEdit ? true : false}
                  onChangeText={(text) => textInputParagraphFirstOnChangeText(text)}
                />
                <Text
                  style={[textParagraphDividerStyle, styles.textParagraphDivider]}>
                  {'- - -'}
                </Text>
                {/* <Text style={textParagraphStyle}>{textParagraphSecond}</Text> */}
              </View>
            </ScrollView>
            <Button
              touchableOpacityContainerStyle={[
                styles.buttonDone,
                touchableOpacityContainerButtonStyle as ViewStyle
              ]}
              textTitle={textTitleButton}
              textTitleStyle={textTitleButtonStyle}
              onPress={touchableOpacityContainerButtonOnPress}
            />
          </View>
        </ImageBackground>
      </Modal>
    </>
  )
}
