import React, { useRef, useState } from 'react'
import { ImageBackground, Text, TouchableOpacity, View, TextInput } from 'react-native'
import { vh, vw } from '../../helpers/dimensions'
import Modal from 'react-native-modal'
import props from './props'
import styles from './styles'

export default ({
  textTitle,
  textTitleStyle,
  textInputNameStyle,
  textInputName,
  placeholderColor,
  placeholder,
  textInputNameOnChangeText,
  textInputNameOnSubmitEditing,
  setDataModal,
  cancelButtonStyle,
  cancelButtonImage,
  okButtonStyle,
  okButtonImage,
  onCancel,
  onOk,
  dataModal,
  isVisible
}: props) => {

  const textInputNameRef = useRef<TextInput>(null);
  const [focus, setFocus] = useState<number>(0);

  return (
    <Modal
      isVisible={isVisible.visibled}
      animationIn={'slideInDown'}
      animationInTiming={500}
      animationOut={'slideOutUp'}
      animationOutTiming={500}
    >
      <ImageBackground
        style={[styles.imageBackgroundContainer]}
        source={require('../../assets/images/shared/modal_add_item.png')}
        resizeMode={'contain'}>

        <View style={styles.containerText}>
          <Text style={[textTitleStyle, styles.textTitle]}>
            {textTitle}
          </Text>

          <View style={styles.lineText}>
            <TextInput
              ref={textInputNameRef}
              pointerEvents={'none'}
              textAlign="center"
              autoFocus
              maxLength={25}
              style={[
                styles.textInputName, textInputNameStyle,
                [
                  {
                    "fontFamily": "CanterLight",
                    "fontSize": vw(8),
                    "letterSpacing": 1.5
                  },
                  {
                    color: "rgb(254, 254, 254)",
                  }
                ]
              ]}
              value={isVisible.edit ? dataModal.title : textInputName}
              placeholderTextColor={placeholderColor}
              placeholder={placeholder}
              numberOfLines={1}
              onChangeText={isVisible.edit ? (title) => setDataModal({ ...dataModal, ['title']: title }) : textInputNameOnChangeText}
              onSubmitEditing={textInputNameOnSubmitEditing}
              onFocus={() => setFocus(0)}
            />
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
            onPress={isVisible.edit ? async () => await onOk(dataModal) : onOk}>
            {okButtonImage}
          </TouchableOpacity>
        </View>

      </ImageBackground>
    </Modal>
  )
}
