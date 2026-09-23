import React from 'react'
import { ActivityIndicator, Image, ImageBackground, Text, TouchableOpacity, View } from 'react-native'
import { Grayscale } from 'react-native-color-matrix-image-filters'
import props from './props'
import styles from './styles'
import { useRecoilValue } from 'recoil'
import { storageAtom } from '../../recoil/atoms'
import { vw } from '../../helpers/dimensions'

export default ({
  titlePath,
  iconPath,
  shadowPath,
  containerButtonHeaderStyle,
  containerButtonTitleStyle,
  infoText,
  onPress,
  isBlocked = false,
  unlocked = false,
  isActive = false,
  hasCoin = true,
  hasImageShadow = false,
  wings,
  containerButtonRocket,
  fontSize,
  size,
  coinActived = false,
}: props) => {

  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  return (
    <>
      <View style={[containerButtonHeaderStyle, styles.containerFooterButton]}>

        {
          titlePath !== null && typeof titlePath === 'string'
            ?
            <View>
              <Text style={[containerButtonTitleStyle, titlePath.length > 14 ? { fontSize: vw(4) } : { fontSize: vw(5) }, fontSize ? { fontSize } : null]}>
                {titlePath}
              </Text>
            </View>
            :
            <View>
              <Image
                style={styles.imageText}
                //source={require('../../../assets/images/improvements/colors.png')}
                source={titlePath}
                resizeMode={'cover'}
              />
            </View>
        }

        {/*  */}
        <TouchableOpacity
          onPress={onPress}
          disabled={unlocked ? false : isBlocked}
          style={styles.touchable}>
          <View
            style={[styles.imageButtonIcon, isActive ? styles.isActiveBtn : styles.noActiveBtn]}
          >
            {isActive ?
              <Image
                style={[styles.activeVeil]}
                source={require('../../assets/images/shared/cont_3.png')}
                resizeMode={'cover'}
              /> : null}
            <ImageBackground
              source={wings}
              resizeMode='cover'
              style={containerButtonRocket ? containerButtonRocket[1] : styles.wingsStyle}>
              <Image
                style={[containerButtonRocket ? containerButtonRocket[0] : styles.imageIcon, infoText ? styles.moveUp : null, isBlocked && !size ? styles.iconBlocked : null, size ? size : null]}
                source={iconPath}
                resizeMode={'contain'}
              />
            </ImageBackground>
            {hasImageShadow ?
              <Image
                style={[styles.imageIconShadow, infoText ? styles.moveUp : null, isBlocked ? styles.iconBlocked : null]}
                source={shadowPath}
                resizeMode={'contain'}
              /> : null
            }
            {
              coinActived
                ?
                <Image
                  style={[styles.imageIconLock]}
                  source={require('../../assets/images/check_in/iconCoin.png')}
                  resizeMode={'contain'}
                />
                : null
            }
          </View>
          {
            infoText ?
              <View style={[styles.infoBox, { backgroundColor: palette.TEXT_TERTIARY }]}>
                {/*infoText !== 'IN USE' &&
                  <Image
                    style={styles.plusIcon}
                    source={require('../../assets/images/shared/iconPlus.png')}
                    resizeMode={'contain'}
                  />
                */}
                <Text style={[styles.textStyle,
                fonts.BUTTON_CIRCLE_INFO_BOLD,
                {
                  color: palette.TEXT_QUATERNARY,
                }
                ]}>{infoText}
                </Text>
                {(hasCoin) &&
                  <Image
                    style={styles.coinIcon}
                    source={require('../../assets/images/shared/iconCoin.png')}
                    resizeMode={'contain'}
                  />}
              </View> : null
          }
        </TouchableOpacity>
      </View>
    </>
  )
}
