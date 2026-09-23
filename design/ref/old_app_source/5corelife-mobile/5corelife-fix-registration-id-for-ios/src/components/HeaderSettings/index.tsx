import React from 'react'
import { Image, Text, View } from 'react-native'
import { TouchableOpacity } from 'react-native-gesture-handler'
import { useRecoilValue } from 'recoil'
import props from './props'
import styles from './styles'
import { storageAtom } from '../../recoil/atoms'
import LinearGradient from 'react-native-linear-gradient'

export default ({
  title,
  subtitle,
  textTitleStyle,
  textSubtitleStyle,
  leftArrowNavigation,
  rightArrowNavigation,
  isIcon = false,
  avatarTitlePath,
  avatarPath,
  primaryColor,
  disabled
}: props) => {

  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  return (
    <>
      <View style={styles.container}>
        {subtitle && (
          <View style={styles.containerTextSubitle}>
            <Text style={[styles.textSubtitle, textSubtitleStyle]}>
              {subtitle}
            </Text>
          </View>
        )}

        <View style={[{ flexDirection: 'row', alignItems: 'center' }]}>
          {!isIcon &&
            <Image
              style={[styles.lightBackground]}
              source={require('../../assets/images/shared/light2.png')}
              resizeMode={'cover'} />
          }
          <View style={styles.containerArrowLeft}>
            {leftArrowNavigation && !isIcon && (
              <TouchableOpacity
                onPress={() => { leftArrowNavigation() }}>
                <Image
                  style={[styles.arrowSize, styles.leftDirection]}
                  source={require('../../assets/images/shared/arrows.png')}
                  resizeMode={'contain'}
                />
              </TouchableOpacity>
            )}
          </View>

          {isIcon ?
            <View style={[styles.offsetContainerIcon]}>
              {avatarTitlePath ?
                <Image
                  style={[styles.textCore]}
                  source={avatarTitlePath}
                  resizeMode={'contain'} /> : null}
              <View style={[styles.avatarContainer]}>

                {leftArrowNavigation && (
                  <TouchableOpacity
                    onPress={() => { leftArrowNavigation() }}>
                    <Image
                      style={[styles.arrowSize, styles.leftDirection]}
                      source={require('../../assets/images/shared/arrow_w.png')}
                      resizeMode={'contain'} />
                  </TouchableOpacity>
                )}

                <LinearGradient
                  colors={['#FFFF', primaryColor ?? '#FFFF']}
                  start={{ x: 0.5, y: 0.0 }} end={{ x: 1.0, y: 1.0 }}
                  style={styles.bubbleShape}
                >
                  <View style={[styles.containerBubble, {
                    backgroundColor: '#1B1714',
                  }]}>
                    <Image
                      style={[styles.iconBubble]}
                      source={avatarPath}
                      resizeMode={'cover'} />
                  </View>
                </LinearGradient>

                {rightArrowNavigation && (
                  <TouchableOpacity
                    disabled={disabled}
                    onPress={() => { rightArrowNavigation() }}>
                    <Image
                      style={styles.arrowSize}
                      source={require('../../assets/images/shared/arrow_w.png')}
                      resizeMode={'contain'}
                    />
                  </TouchableOpacity>
                )}

              </View>

            </View> :
            <>
              <View style={styles.containerTextTitle}>
                <Text style={[
                  styles.textTitle,
                  {
                    color: palette.TEXT_PRIMARY,
                    textShadowColor: palette.DARK_OPACITY_BACKGROUND
                  },
                  textTitleStyle
                ]}>{title}</Text>
              </View>
            </>
          }

          <View style={styles.containerArrowRight}>
            {rightArrowNavigation && !isIcon && (
              <TouchableOpacity
                disabled={disabled}
                onPress={() => { rightArrowNavigation() }}>
                <Image
                  style={styles.arrowSize}
                  source={require('../../assets/images/shared/arrows.png')}
                  resizeMode={'contain'}
                />
              </TouchableOpacity>
            )}
          </View>
        </View>

        {isIcon ? null : <View style={styles.containerImageLine}>
          <Image
            style={styles.imageLine}
            source={require('../../assets/images/storage/line.png')}
            resizeMode={'contain'}
          />
        </View>}
      </View>
    </>
  )
}
