import React from 'react'
import { ImageBackground, Text, View } from 'react-native'
import { useRecoilValue } from 'recoil'
import HeaderDots from '../../../components/HeaderDots'
import HeaderSettings from '../../../components/HeaderSettings'
import { storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'


export default ({ navigation: { navigate, goBack } }: props) => {
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  return (
    <>
      <ImageBackground
        style={styles.imageBackgroundContainer}
        source={require('../../../assets/images/settings/background.png')}
        resizeMode={'cover'}>
          
        <HeaderDots
          dotsCount={3}
          activeDotIndex={1}
          onBackButton={() => { goBack() }}
        />

        <HeaderSettings
          title={strings.TITLE}
          textTitleStyle={[
            fonts.CORE_TITLE,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW
            }
          ]}
          leftArrowNavigation={() => { navigate('Help') }}
          rightArrowNavigation={() => { navigate('Credits') }}
        />

        <View style={styles.viewElements}>
          <Text
            style={[
              styles.textTitle,
              [
                fonts.CORE_SUBTITLE,
                {
                  color: palette.TEXT_TERTIARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW
                }
              ]
            ]}>
            {strings.DISCLAIMER_TITLE}
          </Text>

          <Text
            style={[
              styles.textSubtitle,
              [
                fonts.SETTINGS_CARD_PARAGRAPH,
                {
                  color: palette.TEXT_PRIMARY
                }
              ]
            ]}>
            {strings.DISCLAIMER_PARAGRAPH +
              '\n' +
              '- - -' +
              '\n' +
              strings.DISCLAIMER_PARAGRAPH}
          </Text>
        </View>
      </ImageBackground>
    </>
  )
}
