import React from 'react'
import { ImageBackground, Text, TouchableOpacity, View } from 'react-native'
import { useRecoilValue } from 'recoil'

import ButtonBack from '../../../components/ButtonBack'
import HeaderSettings from '../../../components/HeaderSettings'
import { storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import Accordion from '../../../components/Accordion'
import { ScrollView } from 'react-native-gesture-handler'
import HelpItem from '../../../components/HelpItem'
import HeaderDots from '../../../components/HeaderDots'


const CONTENT = [
  {
    title: 'How it works',
    content: [
      {
        text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
      },
      {
        text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
      }
    ]
  },
  {
    id: '2',
    title: 'Habits',
    content: [
      {
        text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
      }
    ]
  },
  {
    title: 'Cockpit',
    content: [
      {
        text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
      },
      {
        text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
      }, {
        text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
      },
      {
        text: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.'
      }
    ]
  }
]

export default ({ navigation: { navigate, goBack } }: props) => {
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  return (
    <>
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/settings/background.png')}
        resizeMode={'cover'}>
        <View style={styles.containerChild}>

          <HeaderDots
            dotsCount={3}
            activeDotIndex={0}
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
            rightArrowNavigation={() => { navigate('Disclaimer') }}
          />


          {/*
          //, agrega flechas para ir a Disclaimer y a Credits
          <View style={styles.containerButtonBack}>
            <ButtonBack onPress={goBack} />
          </View>

          <TouchableOpacity
            style={styles.containerHeaderSettings}
            onPress={() => {
              navigate('Help')
            }}>
            <HeaderSettings
              title={strings.TITLE}
              textTitleStyle={[
                fonts.CORE_TITLE,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW
                }
              ]}
            />
            </TouchableOpacity>*/}

          <ScrollView>
            {CONTENT.map((it, key) => (
              <HelpItem item={it} />
            ))}
            {/* <Accordion data={mockCaptainsLog} /> */}
          </ScrollView>
        </View>
      </ImageBackground>
    </>
  )
}
