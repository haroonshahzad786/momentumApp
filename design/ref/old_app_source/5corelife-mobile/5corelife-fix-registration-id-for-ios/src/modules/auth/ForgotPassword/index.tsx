import React, { useRef, useState } from 'react'
import {
  Animated,
  Easing,
  Image,
  ImageBackground,
  SafeAreaView,
  Text,
  TextInput,
  TouchableOpacity,
  View,
  KeyboardAvoidingView,
  Platform,
} from 'react-native'
import { useRecoilValue } from 'recoil'

import Button from '../../../components/Button'
import Input from '../../../components/Input'
import { fetchAxios } from '../../../helpers/axios'
import { URL } from '../../../helpers/api'
import { vh, vw } from '../../../helpers/dimensions'
import { hitSlop } from '../../../helpers/touchable'
import { storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { ScrollView } from 'react-native-gesture-handler'
import { ForgotPasswordRequest, ForgotPasswordResponse } from '../../../typescript/main'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, goBack } }: props) => {
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  const [textInputUsername, setTextInputUsername] = useState<string>('')

  const textInputPassRef = useRef<TextInput>()

  const [openModal, setOpenModal] = useState<boolean>(false)
  const [message, setMessage] = useState<string>('')
  const performRecovery = async () => {
    logger.debug("line 43 ForgotPassword.index textInputUserName", textInputUsername);
    if (!textInputUsername) {
      setMessage(strings.CREDENTIAL);
      setOpenModal(true)
      return;
    }
    try {
      const forgotPassword: ForgotPasswordResponse = await fetchAxios<ForgotPasswordRequest, ForgotPasswordResponse>(
        'POST',
        URL + 'users/forgot-password/',
        null,
        {
          email: textInputUsername
        }
      )
      if (forgotPassword.response === 'Email sent.') {
        navigate('ForgotPasswordCode', {
          username: textInputUsername
        })
      }
    } catch (error: any) {
      logger.error("ForgotPassword error: ", error.response);
      setMessage(error.response.data[0] ?? '')
      setOpenModal(true)
    }
  }

  const [screenPosY] = useState(new Animated.Value(0));
  React.useEffect(() => {
    if (openModal) {
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
    }
    setOpenModal(false)
  }, [screenPosY, openModal])

  return (
    <>
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/login/background.png')}
        resizeMode={'cover'}>
        <ScrollView>
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
                    { color: palette.TEXT_PRIMARY, fontSize: 21 }
                  ]}>
                  {message}
                </Text>
              </View>
            </ImageBackground>
          </Animated.View>
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
                  style={[
                    fonts.LOGIN_FORGOT_PASSWORD,
                    { color: palette.TEXT_PRIMARY }
                  ]}>
                  {strings.SUBTITLE}
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
                      textInputPlaceholder={strings.PLACEHOLDER_INPUT_USERNAME}
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
                  onPress={performRecovery}
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
