import React from 'react'
import { Image, ImageBackground, Text, View } from 'react-native'
import { useRecoilValue } from 'recoil'

import Button from '../../../components/Button'
import CockpitScreen from '../../../components/CockpitScreen'
import { vh, vw } from '../../../helpers/dimensions'
import { storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'

export default ({ navigation: { pop, navigate } }: props) => {
  const {
    value: { fonts, palette },
  } = useRecoilValue(storageAtom)

  const onPress = () => {
    navigate('DashboardStackScreen', {
      screen: 'Journey',
    })
  }

  return (
    <>
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/cockpit_categories/background.png')}
        resizeMode={'cover'}>
        <ImageBackground
          style={styles.containerImageBackgroundCockpit}
          source={require('../../../assets/images/cockpit_categories/console.png')}
          resizeMode={'stretch'}>
          <View style={styles.containerCockpitScreen}>
            <CockpitScreen
              onPress={() => {
                null
              }}
            />
          </View>

          <View style={styles.containerElements}>
            <View style={styles.containerImageWellDone}>
              <Image
                style={styles.imageWellDone}
                source={require('../../../assets/images/cockpit_self_review_done/well_done.png')}
                resizeMode={'cover'}
              />
            </View>

            <View style={styles.containerTextTitle}>
              <Text
                style={[
                  styles.textTitle,
                  fonts.COCKPIT_FINISH_TITLE,
                  { color: palette.TEXT_PRIMARY },
                ]}>
                {strings.TITLE}
              </Text>
            </View>

            <View
              style={[
                styles.containerSeparator,
                { backgroundColor: palette.TEXT_PRIMARY },
              ]}
            />

            <View style={styles.containerTextSubtitle}>
              <Text
                style={[
                  styles.textSubtitle,
                  fonts.COCKPIT_FINISH_SUBTITLE,
                  { color: palette.TEXT_PRIMARY },
                ]}>
                {strings.SUBTITLE}
              </Text>
            </View>
          </View>

          <View style={styles.containerButtonDone}>
            <Button
              touchableOpacityContainerStyle={{
                backgroundColor: palette.SUCCESS,
                borderRadius: vw(10),
                borderWidth: vw(0.5),
                borderColor: palette.BUTTON_BORDER,
                height: vh(5.5),
              }}
              textTitle={strings.BUTTON_DONE}
              textTitleStyle={[
                styles.buttonDone,
                fonts.BUTTON_SMALL,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                },
              ]}
              spinnerSize={20}
              spinnerColor={palette.TEXT_PRIMARY}
              isLoading={false}
              onPress={onPress}
            />
          </View>
        </ImageBackground>
      </ImageBackground>
    </>
  )
}
