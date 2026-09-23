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
  containerStyle,
  highlightStyle,
  arrowContainerStyle,
  withoutHighlight = false,
}: props) => {
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom);

  return (
    <>
      <View style={[styles.indicatorContainer, containerStyle]}>
        {!withoutHighlight &&
          <Image
            style={[styles.highlightContainer, highlightStyle]}
            source={require('../../../assets/images/onboarding/highlight.png')}
            resizeMode={'contain'} />
        }
        <View style={[styles.arrowContainer, arrowContainerStyle]}>
          <Image
            style={[styles.arrowSelecting, styles.arrowThree]}
            source={require('../../../assets/images/onboarding/iconSelection.png')}
            resizeMode={'contain'} />
          <Image
            style={[styles.arrowSelecting, styles.arrowTwo]}
            source={require('../../../assets/images/onboarding/iconSelection.png')}
            resizeMode={'contain'} />
          <Image
            style={styles.arrowSelecting}
            source={require('../../../assets/images/onboarding/iconSelection.png')}
            resizeMode={'contain'} />
        </View>
      </View>
    </>
  )
}
