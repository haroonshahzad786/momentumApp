import React, { useRef } from 'react'
import { Text, TextInput, TouchableOpacity, View } from 'react-native'
import { ScrollView } from 'react-native-gesture-handler'
import { vw } from '../../helpers/dimensions'
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
  setDataModal,
  setModalVisible,
  item,
  idx,
}: props) => {
  const textInputNameRef = useRef<TextInput>(null)

  const onPress = () => {
    // textInputNameRef.current?.focus()
    setModalVisible({ visibled: true, edit: true })
    setDataModal({
      id: item.id,
      title: textInputName,
      user: 0,
      core_name: item.core_name
    })
  }

  return (
    <>
      <View style={[styles.viewContainer, viewContainerStyle]}>
        <ScrollView style={{ flexGrow: 1 }}>
          <View style={styles.lineContainer}>
            {!idx &&
              <View style={styles.lineNumber}>
                <Text
                  style={[
                    styles.textNumber, textNumberStyle,
                    [
                      {
                        "fontFamily": "CanterLight",
                        "fontSize": vw(6),
                        "letterSpacing": 2
                      },
                      {
                        color: "rgb(167, 167, 167)",
                        //textShadowColor: palette.TEXT_PRIMARY_SHADOW
                      }
                    ]
                  ]}
                  numberOfLines={1}>
                  {`${index + 1}.\t`}
                </Text>
              </View>
            }

            <View style={styles.lineText}>
              <Text style={[
                styles.textInputName, textInputNameStyle,
                [
                  {
                    "fontFamily": "CanterLight",
                    "fontSize": vw(6),
                    "letterSpacing": 2
                  },
                  {
                    color: "rgb(254, 254, 254)",
                  }
                ]
              ]}>
                {textInputName}
              </Text>
            </View>
            {/* <TextInput
              ref={}
              pointerEvents={'none'}
            
              value={textInputName}
              placeholderTextColor={placeholderColor}
              placeholder={placeholder}
              numberOfLines={1}
              onChangeText={(text) => textInputNameOnChangeText(index, text)}
              onSubmitEditing={textInputNameOnSubmitEditing}
            />*/}


            <View style={styles.lineButton}>
              <TouchableOpacity
                style={styles.touchableOpacityImageRight}
                onPress={() => onPress()}>
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
