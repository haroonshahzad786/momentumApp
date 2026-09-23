import React, { useRef, useState } from 'react'
import { Text, TextInput, TouchableOpacity, View } from 'react-native'
import DropDownPicker from 'react-native-dropdown-picker';
import { ScrollView } from 'react-native-gesture-handler'
import { vw } from '../../helpers/dimensions';
import props from './props'
import styles from './styles'

export default ({
  index,
  viewContainerStyle,
  textNumberStyle,
  textInputName,
  textInputNameStyle,
  // textInputNameOnChangeText,
  textInputNameOnSubmitEditing,
  placeholder,
  placeholderColor,
  imageRight,
  imageLine,
  setModalVisible,
  setDataModal,
  idx,
  goals,
  setModalVisibleDelete
}: props) => {
  const textInputNameRef = useRef<TextInput>(null);

  const eventHandling = () => {
    setModalVisible(true)
    setDataModal({
      id: textInputName?.id,
      title: textInputName?.name,
      category: textInputName.category,
    })
  }



  return (
    <>
      <View style={[styles.viewContainer, viewContainerStyle, { flex: 1 }, textInputName.category === 'Success' ? styles.success : textInputName.category === 'Failure' ? styles.failed : null]}>
        <ScrollView style={{ flexGrow: 1 }}>

          <View style={styles.lineContainer}>
            <View style={styles.lineText}>
              <Text style={[
                styles.textInputName, textInputNameStyle,
                [
                  {
                    "fontFamily": "CanterLight",
                    "fontSize": vw(5),
                    "letterSpacing": 2,
                  },
                ]
              ]}>
                {textInputName?.name}
              </Text>

              <Text style={[
                styles.textInputOption, textInputNameStyle,
                [
                  {
                    "fontFamily": "CanterLight",
                    "fontSize": vw(3),
                    "letterSpacing": 2,
                    alignSelf: 'center'
                  },
                ]
              ]}>
                {!goals ? textInputName.category : textInputName.score + '/' + textInputName.length}
              </Text>
            </View>
            <View style={styles.lineButton}>
              <TouchableOpacity
                style={styles.touchableOpacityImageRight}
                onPress={() => goals ? setModalVisibleDelete({ visibled: true, id: textInputName.id }) : eventHandling()}>
                {imageRight}
              </TouchableOpacity>
            </View>
          </View>
          <View style={styles.viewImageLine}>{imageLine}</View>
        </ScrollView>
      </View>
    </>
  )
}
