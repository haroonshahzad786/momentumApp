import React from 'react'
import { Image, Text, TouchableOpacity, View } from 'react-native'
import { useRecoilValue } from 'recoil'
import { storageAtom } from '../../recoil/atoms'
import props from './props'
import styles from './styles'


export default ({
  onPress,
  label,
  labelFontStyle,
  initialState,
  backgroundColor,
  disabled }: props) => {
  const [toggleCheckBox, setToggleCheckBox] = React.useState(initialState ?? false);
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)
  return (
    <>
      <TouchableOpacity style={styles.container} disabled={disabled} onPress={() => {
        if (onPress != null)
          onPress();
        setToggleCheckBox(!toggleCheckBox)
      }}>
        <View style={[styles.formedHabitButton, { backgroundColor: backgroundColor ?? 'black' }]} >
          {(label != null && label != "") ? <Text style={labelFontStyle}>
            {label}
          </Text> : null}

          <View style={[styles.bubbleBg, { backgroundColor: 'black', }]}>
            {
              toggleCheckBox ?
                <Image
                  style={styles.imageButton}
                  source={require('../../assets/images/shared/tagCheck.png')}
                  resizeMode={'contain'}
                /> : null
            }
          </View>
        </View>
      </TouchableOpacity>
    </>
  )
}
