import React, { useEffect, useState } from 'react'

import props from './props'
import styles from './styles'
import {
  Animated,
  Image,
  ImageBackground,
  SafeAreaView,
  Text,
  TouchableOpacity,
  View,
  Easing
} from 'react-native'
import { useRecoilValue } from 'recoil'
import { storageAtom } from '../../../recoil/atoms'
import { vh } from '../../../helpers/dimensions'

export default ({
  onPress,
  stylePosition
}: props) => {
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom);

  return (
    <>
      <TouchableOpacity
        style={[styles.touchableOpacityButtonNext, stylePosition ? stylePosition : null]}
        onPress={onPress}>
        <Image
          style={styles.imageButtonNext}
          source={require('../../../assets/images/onboarding/button_next.png')}
          resizeMode={'contain'}
        />
      </TouchableOpacity>
    </>
  )
}
