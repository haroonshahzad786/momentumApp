import React, { useRef, useState, useEffect } from 'react'
import {
  Image,
  ImageBackground,
  SafeAreaView,
  Text,
  TextInput,
  ScrollView,
  TouchableOpacity,
  View,
  KeyboardAvoidingView,
  Platform,
  Animated,
  Easing
} from 'react-native'
import { useRecoilValue } from 'recoil'

import Button from '../../../components/Button'
import Input from '../../../components/Input'
import { URL } from '../../../helpers/api'
import { fetchAxios } from '../../../helpers/axios'
import { vh, vw } from '../../../helpers/dimensions'
import { hitSlop } from '../../../helpers/touchable'
import { storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'

export default ({
  navigation: { navigate, goBack },
  route: {
    params: { username }
  }
}: props) => {
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)

  const [textInputUsername, setTextInputUsername] = useState<string>('')
  const [textInputPassword, setTextInputPassword] = useState<string>('')
  const [
    textInputPasswordRepeat,
    setTextInputPasswordRepeat
  ] = useState<string>('')

  const textInputPassRef = useRef<TextInput>()

  const [message, setMessage] = useState<string>('')
  const resetPassword = async () => {
    try {
      await fetchAxios(
        'POST',
        URL + 'users/password-reset/',
        token,
        {
          email: username,
          password: textInputPassword,
          password_confirmation: textInputPasswordRepeat,
          code: textInputUsername
        }
      )
      navigate('ForgotPasswordSuccess', {
        username: textInputUsername
      })
    } catch (error: any) {
      setInvalidCredential(true)
      logger.debug('RESET PASSWORD ERROR: ', JSON.stringify(error.response.data));
      if (error.response.data?.password) setMessage(error.response.data?.password)
      if (error.response.data?.non_field_errors) setMessage(error.response.data?.non_field_errors)
    }
  }

  const [screenPosY] = useState(new Animated.Value(0));
  const [invalidCredential, setInvalidCredential] = useState<boolean>(false)
  useEffect(() => {
    if (invalidCredential) {
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
      ]).start();
      setInvalidCredential(false);
    }
  }, [screenPosY, invalidCredential])

  return (
    <>
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/login/background.png')}
        resizeMode={'cover'}>

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
                  { color: palette.TEXT_PRIMARY }
                ]}>
                {message}
              </Text>
            </View>
          </ImageBackground>
        </Animated.View>

        <ScrollView>
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
                  style={[fonts.LOGIN_SIGN_IN, { color: palette.TEXT_PRIMARY }]}>
                  {strings.TITLE}
                </Text>
              </View>

              <View style={styles.containerSubtitleText}>
                <Text
                  style={[fonts.LOGIN_REGISTER, { color: palette.TEXT_PRIMARY }]}>
                  {username}
                </Text>
              </View>
              <KeyboardAvoidingView
                behavior={Platform.OS === "ios" ? "padding" : "height"}
                contentContainerStyle={{ flex: 1 }}>
                <View style={styles.containerInputs}>
                  <View style={styles.containerInputUsername}>
                    <Input
                      textInput={textInputUsername}
                      textInputStyle={[
                        fonts.INPUT,
                        { color: palette.TEXT_PRIMARY }
                      ]}
                      textInputPlaceholder={strings.PLACEHOLDER_INPUT_CODE}
                      textInputPlaceholderColor={palette.TEXT_PRIMARY}
                      autoCapitalize={'none'}
                      keyboardType={'default'}
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

                  <View style={styles.containerInputPassword}>
                    <Input
                      textInput={textInputPassword}
                      textInputStyle={[
                        fonts.INPUT,
                        { color: palette.TEXT_PRIMARY }
                      ]}
                      textInputPlaceholder={strings.PLACEHOLDER_INPUT_PASSWORD}
                      textInputPlaceholderColor={palette.TEXT_PRIMARY}
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
                        { color: palette.TEXT_PRIMARY }
                      ]}
                      textInputPlaceholder={
                        strings.PLACEHOLDER_INPUT_REPEAT_PASSWORD
                      }
                      textInputPlaceholderColor={palette.TEXT_PRIMARY}
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
              </KeyboardAvoidingView>
              <View style={styles.containerButtonRegister}>
                <Button
                  touchableOpacityContainerStyle={{
                    backgroundColor: palette.SUCCESS,
                    borderRadius: vw(10),
                    borderWidth: vw(0.5),
                    borderColor: palette.BUTTON_BORDER,
                    height: vh(6)
                  }}
                  textTitle={strings.BUTTON_CONTINUE}
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
                  onPress={() => resetPassword()}
                />

                <View style={styles.containerButtonRegisterImageLine}>
                  <Image
                    style={styles.imageLine}
                    source={require('../../../assets/images/login/line.png')}
                    resizeMode={'contain'}
                  />
                </View>
              </View>

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
                  {strings.BUTTON_BACK}
                </Text>
              </TouchableOpacity>
            </View>
          </SafeAreaView>
        </ScrollView>
      </ImageBackground>
    </>
  )
}
