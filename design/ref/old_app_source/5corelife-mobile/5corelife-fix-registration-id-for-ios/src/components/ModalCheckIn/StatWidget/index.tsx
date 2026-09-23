import React, { useRef } from 'react'
import { Image, Text, View } from 'react-native'
import { Grayscale } from 'react-native-color-matrix-image-filters'
import { useRecoilValue } from 'recoil'

import props from './props'
import styles from './styles'
import { storageAtom } from '../../../recoil/atoms'

export default ({
  statsNumbersStyle,
  statImage,
  statValue,
  isLocked,
}: props) => {
  const imageStatBackground = require('../../../assets/images/check_in/roundedRectangle1344.png')
  const imageLockedIcon = require('../../../assets/images/check_in/iconBlock.png')
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  return (
    <View style={[styles.widgetContainer, { backgroundColor: palette.SETTINGS_CARD_BACKGROUND }]}>
      {/* <View style={styles.rightSide}>
        <Image
          style={styles.statBackground}
          source={imageStatBackground}
          resizeMode={'contain'}
        />
      </View> */}
      <View style={styles.leftSide}>
        {isLocked ? (
          <>
            <Grayscale style={[styles.statImage]}>
              <Image
                style={[styles.statImage]}
                source={statImage}
                resizeMode={'contain'}
              />
            </Grayscale>
            {/* <View style={styles.rightSideBg}> */}
            <Image
              style={styles.statLockedIcon}
              source={imageLockedIcon}
              resizeMode={'contain'}
            />
            {/* </View> */}

          </>
        ) : (
          <>
            <Image
              style={[styles.statImage]}
              source={statImage}
              resizeMode={'contain'}
            />
            <Text style={[statsNumbersStyle, styles.statText]}>
              {statValue}
            </Text>
          </>
        )}
      </View>
    </View>
  )
}
