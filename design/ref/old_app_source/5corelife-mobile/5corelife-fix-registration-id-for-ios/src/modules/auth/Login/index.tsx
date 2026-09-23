import React, { Key, useEffect, useRef, useState } from 'react'
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
  ScrollView,
  Platform,
  Linking
} from 'react-native'
import { useRecoilState, useResetRecoilState } from 'recoil'

import Button from '../../../components/Button';
import Input from '../../../components/Input';
import { URL, URL_MOOREMOMENTUM } from '../../../helpers/api';
import { vh, vw } from '../../../helpers/dimensions';
import { setAtomAxios } from '../../../helpers/recoil';
import { hitSlop } from '../../../helpers/touchable';
import LottieView from 'lottie-react-native';
import {
  localDataAtom,
  storageAtom,
  userAtom,
  userInfoAtom,
  userRetrieveAtom,
} from '../../../recoil/atoms';
import props from './props';
import strings from './strings';
import styles from './styles';
import MaskedView from '@react-native-community/masked-view';
//@ts-ignore
import AnimateNumber from 'react-native-countup';
import { fetchAxiosNoCache, fetchAxios } from '../../../helpers/axios';
import messaging from '@react-native-firebase/messaging';
import { User } from '../../../typescript/auth';
import { UserRetrieve } from '../../../typescript/main';
import { logger } from '../../../helpers/logger';


export default ({ navigation: { navigate } }: props) => {
  const [storage, setStorage] = useRecoilState(storageAtom);
  const { fonts, palette } = storage.value;

  const [userInfo, setUserInfo] = useRecoilState(userInfoAtom);
  const [localData, setLocalData] = useRecoilState(localDataAtom);

  const [user, setUser] = useRecoilState(userAtom);
  const resetUser = useResetRecoilState(userAtom);
  const [userRetrieve, setUserRetrieve] = useRecoilState(userRetrieveAtom);

  const [textInputUsername, setTextInputUsername] = useState<string>('')
  const [textInputPassword, setTextInputPassword] = useState<string>('')
  const [isLoggedIn, setLoggedIn] = useState<boolean>(false)
  const [isLoading, setIsLoading] = useState<boolean>(false)
  const textInputPassRef = useRef<TextInput>()
  const [loadPercentage] = useState(new Animated.Value(250))
  const [usersPushNotification, setUserPushNotification] = useState<string>('')

  useEffect(() => {
    if (isLoading) {
      Animated.timing(loadPercentage, {
        delay: 10,
        toValue: 0,
        duration: 2500,
        useNativeDriver: true,
      }).start(() => {
        performLogin();
      });
    }
  }, [isLoading]);


  useEffect(() => {
    if (user.value && !isLoggedIn) {
      setStorage({
        ...storage,
        value: {
          ...storage.value,
          token: user?.value?.access_token,
          onboarding: user.value.user.user_profile.onboarding
        },
      });
      setAtomAxios(setUserRetrieve, {
        method: 'GET',
        url: URL + 'users/retrieve/',
        token: storage.value.token
      })
      setUserInfo({
        ...userInfo,
        value: {
          ...userInfo.value,
          showAllCores: false,
        },
      });
      setLocalData({
        init: true,
        value: { ...localData.value },
      })
      setLoggedIn(true)
    } else {
      resetUser()
    }
  }, [
    isLoggedIn,
    resetUser,
    setStorage,
    storage,
    user,
    userInfo,
    setUserInfo,
    setLocalData,
    localData,
  ])

  const [screenPosY] = useState(new Animated.Value(0));
  const [invalidCredential, setInvalidCredential] = useState<boolean>()
  useEffect(() => {
    if (invalidCredential) {
      setIsLoading(false);
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
  }, [screenPosY, invalidCredential])

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

  const performLogin = async () => {
    setAtomAxios(setUser, {
      method: 'POST',
      url: URL + 'users/login/',
      data: {
        username: textInputUsername,
        password: textInputPassword,
        registration_id: usersPushNotification
      },
    });
  }

  const queryLogin = async () => {
    setInvalidCredential(false)
    try {
      const response = await fetchAxiosNoCache(
        'POST',
        URL + 'users/login/',
        null,
        {
          username: textInputUsername,
          password: textInputPassword,
        }
      );
      setIsLoading(true)
    } catch (error) {
      setInvalidCredential(true)
    }
  }

  const OpenURLButton = () => {
    const handlePress = React.useCallback(async () => {
      try {
        await Linking.openURL(URL_MOOREMOMENTUM);
      } catch (error) {
        logger.error("We have an error opening the URL: ", error);
      }
    }, [URL_MOOREMOMENTUM]);

    return (
      <TouchableOpacity onPress={handlePress} >
        <Image
          source={require('../../../assets/images/login/moore-momentum-horizontal-full-color-rgb.png')}
          style={styles.imageFooter}
          resizeMode='cover'
        />
      </TouchableOpacity>
    );
  };
  return (
    <ImageBackground
      style={styles.container}
      source={require('../../../assets/images/login/background.png')}
      resizeMode={'cover'}>
      <ScrollView>
        <SafeAreaView style={styles.containerSub}>
          <View style={styles.containerImageLogo}>
            <Image
              style={styles.imageLogo}
              source={require('../../../assets/images/login/logo_b.png')}
              resizeMode={'contain'}
            />
            <LottieView
              style={styles.imageBackground}
              source={require('../../../assets/animations/login/LogoLights.json')}
              imageAssetsFolder={'lottie/images_loading/images_logo'}
              autoPlay={true}
              loop={true}
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
                    { color: palette.TEXT_PRIMARY }
                  ]}>
                  {strings.CREDENTIAL}
                </Text>
              </View>
            </ImageBackground>
          </Animated.View>
          <View style={styles.containerElements}>
            {
              isLoading ?
                <>
                  <View style={[styles.containerTextSignIn, styles.textLoading]}>
                    <Text
                      style={[fonts.INPUT, { color: palette.TEXT_PRIMARY }]}>
                      {strings.LOADING}
                    </Text>
                  </View>
                  <View style={styles.loadingBarContainer}>
                    <MaskedView
                      style={[styles.imageSizeLoaderContainer]}
                      maskElement={
                        <Image
                          style={[styles.barVertical]}
                          source={require('../../../assets/images/login/loadingCont.png')}
                          resizeMode={'cover'}
                        />}
                    >
                      <Animated.View
                        style={[
                          styles.liquidMask,
                          {
                            transform: [
                              {
                                translateY: loadPercentage,
                              },
                            ],
                          },
                        ]}>
                        <LottieView
                          //style={[styles.liquidMask]}
                          style={styles.waterAnimation}
                          source={require('../../../assets/animations/login/LiquidLoad.json')}
                          autoPlay={true}
                          loop={true}
                        />
                      </Animated.View>

                    </MaskedView>
                  </View>
                </>
                :
                <>
                  <View style={styles.containerTextSignIn}>
                    <Text
                      style={[fonts.LOGIN_SIGN_IN, {
                        color: palette.TEXT_PRIMARY,
                        textShadowColor: palette.BORDER_TEXT_LOGIN,
                        textShadowOffset: { width: 0, height: 1 },
                        textShadowRadius: 3,
                      }
                      ]}>
                      {strings.TITLE}
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
                            { color: palette.TEXT_SECONDARY },
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

                      <View style={styles.containerInputPassword}>
                        <Input
                          textInput={textInputPassword}
                          textInputStyle={[
                            fonts.INPUT,
                            { color: palette.TEXT_SECONDARY },
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
                    </View>

                    <View style={styles.containerButtonLogin}>
                      <Button
                        touchableOpacityContainerStyle={{
                          backgroundColor: palette.SUCCESS,
                          borderRadius: vw(10),
                          borderWidth: vw(0.5),
                          borderColor: palette.BUTTON_BORDER,
                          height: vh(6),
                        }}
                        textTitle={strings.BUTTON_LOGIN}
                        textTitleStyle={[
                          styles.buttonLogin,
                          fonts.BUTTON_SMALL,
                          {
                            color: palette.TEXT_PRIMARY,
                            textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                          },
                        ]}
                        spinnerSize={20}
                        spinnerColor={palette.TEXT_PRIMARY}
                        isLoading={user.isLoading}
                        onPress={() => queryLogin()}
                      />

                      <View style={styles.containerButtonLoginImageLine}>
                        <Image
                          style={styles.imageLine}
                          source={require('../../../assets/images/login/line.png')}
                          resizeMode={'contain'}
                        />
                      </View>
                    </View>
                  </KeyboardAvoidingView>
                  <TouchableOpacity
                    style={styles.containerTextRegister}
                    hitSlop={hitSlop(1, 0, 0, 0)}
                    onPress={() => {
                      navigate('Register')
                    }}>
                    <Text
                      style={[
                        fonts.LOGIN_REGISTER,
                        { color: palette.LOGIN_REGISTER },
                      ]}>
                      {strings.REGISTER}
                    </Text>
                  </TouchableOpacity>

                  <TouchableOpacity
                    style={styles.containerTextForgotPassword}
                    hitSlop={hitSlop(0, 0, 2.5, 0)}
                    onPress={() => {
                      navigate('ForgotPassword')
                    }}>
                    <Text
                      style={[
                        fonts.LOGIN_CONNECT_WITH,
                        { color: palette.TEXT_PRIMARY },
                      ]}>
                      {strings.FORGOT_PASSWORD}
                    </Text>
                  </TouchableOpacity>
                  <View style={styles.containerImageFooter}>
                    <OpenURLButton />
                  </View>
                </>
            }
          </View>
        </SafeAreaView>
      </ScrollView>
    </ImageBackground>
  )
}