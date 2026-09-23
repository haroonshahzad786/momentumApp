import React from 'react'
import { Image, ImageBackground, SafeAreaView, Text, View } from 'react-native'
import { useRecoilValue } from 'recoil'

import Button from '../../../components/Button'
import { vh, vw } from '../../../helpers/dimensions'
import { storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'

export default ({ navigation: { navigate } }: props) => {
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  return (
    <>
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/login/background.png')}
        resizeMode={'cover'}>
        <SafeAreaView style={styles.containerSub}>
          <View style={styles.containerImageLogo}>
            <Image
              style={styles.imageLogo}
              source={require('../../../assets/images/login/logo.png')}
            />
          </View>

          <View style={styles.containerElements}>
            <View style={styles.containerTitleText}>
              <Text
                style={[
                  fonts.LOGIN_SIGN_IN,
                  { color: palette.TEXT_PRIMARY },
                  styles.textTitle
                ]}>
                {strings.TITLE}
              </Text>
            </View>

            <View style={styles.containerSubtitleText}>
              <Text
                style={[fonts.LOGIN_SIGN_IN, { color: palette.TEXT_PRIMARY }]}>
                {strings.SUBTITLE}
              </Text>
            </View>

            <Image
              style={styles.imageCheckmark}
              source={require('../../../assets/images/shared/checkmark.png')}
              resizeMode={'contain'}
            />

            <Text
              style={[
                fonts.LOGIN_REGISTER,
                { color: palette.TEXT_PRIMARY },
                styles.textParagraph
              ]}>
              {strings.PARAGRAPH}
            </Text>

            <View style={styles.containerButtonRegister}>
              <Button
                touchableOpacityContainerStyle={{
                  backgroundColor: palette.SUCCESS,
                  borderRadius: vw(10),
                  borderWidth: vw(0.5),
                  borderColor: palette.BUTTON_BORDER,
                  height: vh(6)
                }}
                textTitle={strings.BUTTON_SIGN_IN}
                textTitleStyle={[
                  styles.buttonLogin,
                  fonts.BUTTON_SMALL,
                  {
                    color: palette.TEXT_PRIMARY,
                    textShadowColor: palette.TEXT_PRIMARY_SHADOW
                  }
                ]}
                spinnerSize={20}
                spinnerColor={palette.TEXT_PRIMARY}
                isLoading={false}
                onPress={() => {
                  navigate('Login')
                }}
              />

              <View style={styles.containerButtonRegisterImageLine}>
                <Image
                  style={styles.imageLine}
                  source={require('../../../assets/images/login/line.png')}
                  resizeMode={'contain'}
                />
              </View>
            </View>
          </View>
        </SafeAreaView>
      </ImageBackground>
    </>
  )
}
