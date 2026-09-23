import React, { useEffect, useState } from 'react'
import { ImageBackground, ScrollView, Text, View } from 'react-native'
import { useRecoilValue } from 'recoil'
import HeaderDots from '../../../components/HeaderDots'
import HeaderSettings from '../../../components/HeaderSettings'
import { storageAtom } from '../../../recoil/atoms'
import { URL } from '../../../helpers/api'
import { fetchAxios } from '../../../helpers/axios'
import props from './props'
import strings from './strings'
import styles from './styles'


export default ({ navigation: { navigate, goBack } }: props) => {
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)

  return (
    <>
      <ImageBackground
        style={styles.imageBackgroundContainer}
        source={require('../../../assets/images/settings/background.png')}
        resizeMode={'cover'}>

        <HeaderDots
          dotsCount={3}
          activeDotIndex={2}
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
          leftArrowNavigation={() => { navigate('Disclaimer') }}
        />

        <ScrollView
          style={styles.scrollViewContainer}
          contentContainerStyle={styles.scrollViewContainerContent}>
          <View style={styles.viewElements}>
            <View style={styles.viewSection}>
              <Text
                style={[
                  styles.textTitle,
                  [
                    fonts.CORE_HABIT_LIST_HEADER,
                    {
                      color: palette.TEXT_QUATERNARY
                    }
                  ]
                ]}>
                {strings.DISCLAIMER_TITLE}
              </Text>

              <Text
                style={[
                  styles.textSubtitle,
                  [
                    fonts.LIFETIME_MOMENTUM_AMOUNT,
                    {
                      color: palette.TEXT_PRIMARY
                    }
                  ]
                ]}>
                {strings.DISCLAIMER_PARAGRAPH}
              </Text>

              <Text
                style={[
                  styles.textLine,
                  [
                    fonts.LIFETIME_MOMENTUM_AMOUNT,
                    {
                      color: palette.TEXT_PRIMARY
                    }
                  ]
                ]}>
              </Text>

              {/* <Text
                style={[
                  styles.textSubtitle,
                  [
                    fonts.LIFETIME_MOMENTUM_AMOUNT,
                    {
                      color: palette.TEXT_PRIMARY
                    }
                  ]
                ]}>
                {strings.DISCLAIMER_PARAGRAPH}
              </Text>

              <Text
                style={[
                  styles.textLine,
                  [
                    fonts.LIFETIME_MOMENTUM_AMOUNT,
                    {
                      color: palette.TEXT_PRIMARY
                    }
                  ]
                ]}>
                {'- - -'}
              </Text> */}
            </View>
            {/*<View style={styles.viewSection}>
              <Text
                style={[
                  styles.textTitle,
                  [
                    fonts.CORE_HABIT_LIST_HEADER,
                    {
                      color: palette.TEXT_QUATERNARY
                    }
                  ]
                ]}>
                {strings.DISCLAIMER_TITLE}
              </Text>

               <Text
                style={[
                  styles.textSubtitle,
                  [
                    fonts.LIFETIME_MOMENTUM_AMOUNT,
                    {
                      color: palette.TEXT_PRIMARY
                    }
                  ]
                ]}>
                {strings.DISCLAIMER_PARAGRAPH +
                  '\n' +
                  strings.DISCLAIMER_PARAGRAPH +
                  '\n' +
                  strings.DISCLAIMER_PARAGRAPH +
                  '\n' +
                  strings.DISCLAIMER_PARAGRAPH}
              </Text> 
            </View>*/}
          </View>
        </ScrollView>
      </ImageBackground>
    </>
  )
}
