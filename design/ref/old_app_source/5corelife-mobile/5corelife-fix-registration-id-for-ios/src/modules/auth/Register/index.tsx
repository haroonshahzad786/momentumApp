import React, { useRef, useState, useEffect } from 'react'
import {
  Image,
  ImageBackground,
  SafeAreaView,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  Platform,
  KeyboardAvoidingView,
  ScrollView,
  Animated,
  Easing
} from 'react-native'
import { useRecoilValue, useRecoilState } from 'recoil'

import Button from '../../../components/Button'
import Input from '../../../components/Input'
import { URL } from '../../../helpers/api'
import { fetchAxios } from '../../../helpers/axios'
import { vh, vw } from '../../../helpers/dimensions'
import { hitSlop } from '../../../helpers/touchable'
import { validForm, responseBack } from '../../../helpers/validField'
import { storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import 'moment-timezone';
import moment from 'moment'
import messaging from '@react-native-firebase/messaging';
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, goBack } }: props) => {
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  const [usersPushNotification, setUserPushNotification] = useState<string>('')
  const [textInputUsername, setTextInputUsername] = useState<string>('')
  const [textInputPassword, setTextInputPassword] = useState<string>('')
  const [textInputEmail, setTextInputEmail] = useState<string>('')
  const [
    textInputPasswordRepeat,
    setTextInputPasswordRepeat
  ] = useState<string>('')

  const textInputPassRef = useRef<TextInput>()

  const [error, setError] = useState('')

  useEffect(() => {
    (async () => {
      try {
        const token = await messaging().getToken();
        setUserPushNotification(token)
      } catch (error) {
        logger.error('token registration failed: ', error);
      }
    })()
  }, [])

  const performRegistration = async () => {
    const data = {
      email: textInputEmail,
      username: textInputUsername,
      password: textInputPassword,
      password_confirmation: textInputPasswordRepeat,
      tz_zone: moment.tz.guess(),
    }

    const { string, show } = validForm(data)
    if (show) {
      setError(string)
      callModalInfo()
    }

    logger.debug("performRegistration data:",JSON.stringify(data));
    try {
      await fetchAxios(
        'POST',
        URL + 'users/signup/',
        null,
        data,
      )
      navigate('RegisterSuccess')
    } catch (error: any) {
      // setError(error.response.data)
      const { string, string2, show } = responseBack(error.response.data)
      if (show) {
        setError(string && string2 ? string + "\n" + "\n" + string2 : string)
        callModalInfo()
      }
      logger.debug("Register error:" + JSON.stringify(error.response))
    }
  }

  const [screenPosY] = useState(new Animated.Value(0))
  const callModalInfo = () => {
    Animated.sequence([
      Animated.timing(screenPosY, {
        toValue: vh(80),
        easing: Easing.out(Easing.ease),
        duration: 2000,
        useNativeDriver: true
      }),
      Animated.timing(screenPosY, {
        delay: 4000,
        toValue: vh(0),
        easing: Easing.out(Easing.ease),
        duration: 2000,
        useNativeDriver: true
      }),
    ]).start()
  }

  return (
    <>
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/login/background.png')}
        resizeMode={'cover'}>
        <ScrollView>
          <SafeAreaView style={styles.containerSub}>
            <View style={styles.containerImageLogo}>
              <Image
                style={styles.imageLogo}
                source={require('../../../assets/images/login/logo.png')}
              />
            </View>


            <Animated.View
              style={[
                styles.animatedViewScreen,
                {
                  transform: [
                    {
                      translateY: screenPosY
                    }
                  ]
                }
              ]}>
              <ImageBackground
                style={styles.imageBackgroundScreen}
                source={require('../../../assets/images/onboarding/screen.png')}
                resizeMode={'contain'}>
                <View style={styles.viewTextScreen}>
                  <Text
                    style={[
                      styles.textScreen,
                      fonts.LOGIN_TITLE,
                      { color: palette.TEXT_PRIMARY, fontSize: 22.5 }
                    ]}>
                    {error}
                  </Text>
                </View>
              </ImageBackground>
            </Animated.View>

            <View style={styles.containerElements}>
              <View style={styles.containerTitleText}>
                <Text
                  style={[fonts.LOGIN_SIGN_IN, {
                    color: palette.TEXT_PRIMARY,
                    textShadowColor: palette.BORDER_TEXT_LOGIN,
                    textShadowOffset: { width: 0, height: 1 },
                    textShadowRadius: 3
                  }]}>
                  {strings.TITLE}
                </Text>
              </View>

              <KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : "height"}
                style={{ flex: 1 }}>
                <View style={styles.containerInputs}>
                  <View style={styles.containerInputUsername}>
                    <Input
                      textInput={textInputUsername}
                      textInputStyle={[
                        fonts.INPUT,
                        { color: palette.TEXT_SECONDARY }
                      ]}
                      textInputPlaceholder={strings.PLACEHOLDER_INPUT_USERNAME}
                      textInputPlaceholderColor={palette.TEXT_SECONDARY}
                      autoCapitalize={'none'}
                      keyboardType={'email-address'}
                      backgroundColor={palette.LOGIN_INPUT}
                      borderRadius={20}
                      borderWidth={1.7}
                      borderColor={palette.LOGIN_INPUT_BORDER}
                      onChangeText={setTextInputUsername}
                      onSubmitEditing={() => {
                        textInputPassRef?.current?.focus()
                      }}
                    />
                  </View>

                  <View style={styles.containerInputEmail}>
                    <Input
                      textInput={textInputEmail}
                      textInputStyle={[
                        fonts.INPUT,
                        { color: palette.TEXT_SECONDARY }
                      ]}
                      textInputPlaceholder={strings.PLACEHOLDER_INPUT_EMAIL}
                      textInputPlaceholderColor={palette.TEXT_SECONDARY}
                      autoCapitalize={'none'}
                      keyboardType={'email-address'}
                      backgroundColor={palette.LOGIN_INPUT}
                      borderRadius={20}
                      borderWidth={1.7}
                      borderColor={palette.LOGIN_INPUT_BORDER}
                      onChangeText={setTextInputEmail}
                      onSubmitEditing={() => {
                        textInputPassRef?.current?.focus()
                      }}
                    />
                  </View>

                  <View style={styles.containerInputPassword}>
                    <Input
                      textInput={textInputPassword}
                      textInputStyle={[
                        fonts.INPUT,
                        { color: palette.TEXT_SECONDARY }
                      ]}
                      textInputPlaceholder={strings.PLACEHOLDER_INPUT_PASSWORD}
                      textInputPlaceholderColor={palette.TEXT_SECONDARY}
                      autoCapitalize={'none'}
                      keyboardType={'default'}
                      backgroundColor={palette.LOGIN_INPUT}
                      borderRadius={20}
                      borderWidth={1.7}
                      borderColor={palette.LOGIN_INPUT_BORDER}
                      isSecure
                      onChangeText={setTextInputPassword}
                    />
                  </View>

                  <View style={styles.containerInputPassword}>
                    <Input
                      textInput={textInputPasswordRepeat}
                      textInputStyle={[
                        fonts.INPUT,
                        { color: palette.TEXT_SECONDARY }
                      ]}
                      textInputPlaceholder={
                        strings.PLACEHOLDER_INPUT_REPEAT_PASSWORD
                      }
                      textInputPlaceholderColor={palette.TEXT_SECONDARY}
                      autoCapitalize={'none'}
                      keyboardType={'default'}
                      backgroundColor={palette.LOGIN_INPUT}
                      borderRadius={20}
                      borderWidth={1.7}
                      borderColor={palette.LOGIN_INPUT_BORDER}
                      isSecure
                      onChangeText={setTextInputPasswordRepeat}
                    />
                  </View>
                </View>

                <View style={styles.containerButtonRegister}>
                  <Button
                    touchableOpacityContainerStyle={{
                      backgroundColor: palette.SUCCESS,
                      borderRadius: vw(10),
                      borderWidth: vw(0.5),
                      borderColor: palette.BUTTON_BORDER,
                      height: vh(6)
                    }}
                    textTitle={strings.BUTTON_REGISTER}
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
                    onPress={performRegistration}
                  />

                  <View style={styles.containerButtonRegisterImageLine}>
                    <Image
                      style={styles.imageLine}
                      source={require('../../../assets/images/login/line.png')}
                      resizeMode={'contain'}
                    />
                  </View>
                </View>

              </KeyboardAvoidingView>

              <TouchableOpacity
                style={styles.touchableOpacitySignIn}
                hitSlop={hitSlop(2.5, 5, 2.5, 5)}
                onPress={goBack}>
                <Image
                  style={styles.imageSignIn}
                  source={require('../../../assets/images/shared/button_back.png')}
                  resizeMode={'contain'}
                />

                <Text
                  style={[
                    styles.textSignIn,
                    fonts.LOGIN_SIGN_IN,
                    { color: palette.TEXT_TERTIARY }
                  ]}>
                  {strings.BUTTON_SIGN_IN}
                </Text>
              </TouchableOpacity>
            </View>
          </SafeAreaView>
        </ScrollView>
      </ImageBackground>
    </>
  )
}
