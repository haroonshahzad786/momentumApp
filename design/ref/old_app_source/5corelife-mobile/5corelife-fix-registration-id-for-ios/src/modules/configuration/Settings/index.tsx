import React, { useEffect, useState } from 'react'
import {
  Image,
  ImageBackground,
  ScrollView, Switch, Text,
  TouchableWithoutFeedback,
  TouchableOpacity,
  View,
  PermissionsAndroid,
  Platform,
  Animated,
  Easing,
} from 'react-native'
import { useRecoilState, useResetRecoilState } from 'recoil'
import ButtonSettings from '../../../components/ButtonSettings'
import ModalCodeBook from '../../../components/ModalCodeBook'
import HeaderDots from '../../../components/HeaderDots'
import HeaderSettings from '../../../components/HeaderSettings'
import { URL } from '../../../helpers/api'
import { fetchAxios, fetchTextAxios } from '../../../helpers/axios'
import { setAtomAxios, setAtomManual } from '../../../helpers/recoil'
import parseDate from '../../../helpers/parceDate';
import {
  localDataAtom,
  localDataDefault,
  userRetrieveAtom,
  storageAtom
} from '../../../recoil/atoms'
import { UserRetrieve } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import styles from './styles'
import ModalOkCancel from '../../../components/ModalOkCancel'
import { vh, vw } from '../../../helpers/dimensions'
import ActivityIndicator from '../../../components/ActivityIndicator'
import RNFetchBlob from 'rn-fetch-blob';
import RNDateTimePicker from '@react-native-community/datetimepicker'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, goBack, reset }, onBoardingMode = false, setendTutorial, setendStatusTutorial, setDisabled }: props) => {
  logger.info("[<Settings>]")
  const [storage, setStorage] = useRecoilState(storageAtom)
  const [localData, setLocalData] = useRecoilState(localDataAtom)
  const resetLocalData = useResetRecoilState(localDataAtom)
  const [activityIndicator, setActivityIndicator] = useState({
    perfil: false,
    // firstLoading: true,
  })

  const fonts = storage.value.fonts
  const palette = storage.value.palette
  const token = storage.value.token

  const onPressAbort = async () => {
    // resetLocalData()
    try {
      await fetchAxios(
        'POST',
        URL + 'users/abort-journey/',
        token,
        null
      )
      setLocalData({
        init: true,
        value: localDataDefault,
      })
      reset({
        index: 0,
        routes: [
          {
            name: 'DashboardStackScreen',
            state: {
              routes: [{ name: 'Lifetime' }],
            },
          },
        ],
      })
    } catch (error: any) {
      logger.error("Abourt journey error response: ", error.response);
    }
  }

  const [settings, setSettings] = useRecoilState(userRetrieveAtom);
  const [settingsState, setSettingsState] = useState<UserRetrieve | null>(null);
  const [timePicker, setTimePicker] = useState('morning');
  const [showTimePicker, setShowTimePicker] = useState(false);
  const [isModalVisible, setModalVisible] = useState<boolean>(false);
  const [isModalVisibleOkCancel, setModalVisibleOkCancel] = useState<boolean>(false);
  const [valueText, setValueText] = useState<string>('');

  useEffect(() => {
    setAtomAxios(setSettings, {
      method: 'GET',
      url: URL + 'users/retrieve/',
    })
  }, [setSettings])

  useEffect(() => {
    setSettingsState(settings.value)
  }, [setSettingsState, settings.value])

  const performUpdate = async (updatedData: any) => {
    logger.debug('line 104 configurations.Settings.index <PUTTING> - [USER-RETRIEVE]');
    if (!updatedData) return null;
    setActivityIndicator({
      ...activityIndicator,
      perfil: true
    })
    const dataToSend = {
      username: updatedData.username,
      email: updatedData.email,
      user_profile: {
        quiz: updatedData.user_profile.quiz,
        pause: updatedData.user_profile.pause,
        morning_check_time: updatedData.user_profile.morning_check_time,
        night_check_time: updatedData.user_profile.night_check_time,
        notifications: updatedData.user_profile.notifications,
      },
    };
    logger.debug('line 121 configurations.Settings.index Data to send: ' + JSON.stringify(dataToSend));
    try {
      const data = await fetchAxios(
        'PUT',
        URL + 'users/retrieve/',
        token,
        dataToSend,
      )

      setAtomManual(setSettings, data);
    } catch (error) {
      logger.error('Put user retreive error: ' + JSON.stringify(error));
    }
    finally {
      setActivityIndicator({
        ...activityIndicator,
        perfil: false
      })
    }
  }

  const toggleNotifications = (value: boolean) => {
    let newSettingsState: UserRetrieve = JSON.parse(JSON.stringify(settingsState))
    newSettingsState.user_profile.notifications = value
    setSettingsState(newSettingsState)
    performUpdate(newSettingsState)
  }

  const togglePause = async (value: boolean) => {
    let pause: any = '';
    let newSettingsState: UserRetrieve = JSON.parse(JSON.stringify(settingsState))
    newSettingsState.user_profile.pause = value;
    setSettingsState(newSettingsState)
    performUpdate(newSettingsState)
    try {
      pause = await fetchAxios(
        'POST',
        URL + 'users/pause-journey/',
        token,
        null
      )
    } catch (error: any) {
      logger.error("Pause journey error:", error.response);
    }

  }

  const handleOnChangeTimePicker = (_event: Event, date?: Date) => {
    if (onBoardingMode) setDisabled(false)
    if (!date) {
      setShowTimePicker(false)
      return
    }
    logger.debug("line 175 configurations.Settings.index handleOnChangeTimePicker date: ", date)
    let newSettingsState: UserRetrieve = JSON.parse(JSON.stringify(settingsState))
    logger.debug('line 177 configurations.Settings.index newSettingsState: ', newSettingsState, "\ntimePicker: ", timePicker)

    switch (timePicker) {
      case 'morning':
        newSettingsState.user_profile.morning_check_time = `${date.getHours()}:${(
          '0' + date.getMinutes()
        ).slice(-2)}`;
        if (onBoardingMode) {
          setendTutorial({
            ...setendStatusTutorial,
            morning: true
          })
        }
        break
      case 'nightly':
        newSettingsState.user_profile.night_check_time = `${date.getHours()}:${(
          '0' + date.getMinutes()
        ).slice(-2)}`;
        if (onBoardingMode) {
          setendTutorial({
            ...setendStatusTutorial,
            night: true
          })
        }
        break;
      default:
        return;
    }
    Platform.OS === 'android' ? setShowTimePicker(false) : null
    setSettingsState(newSettingsState);
    performUpdate(newSettingsState);
  }

  const cancelOperation = () => {
    setValueText('');
    setModalVisible(false);
  }

  const [openDownload, setOpenDownload] = useState(false)
  const [message, setMessage] = useState<string>('');
  const [result, setResult] = useState<string>('');

  function getErrorString(error: any, defaultValue?: any) {
    let e = defaultValue || 'Something went wrong. Please try again';
    if (typeof error === 'string') {
      e = error;
    } else if (error && error.message) {
      e = error.message;
    } else if (error && error.props) {
      e = error.props;
    }
    return e;
  }
  const exportCSV = async () => {
    const csv = await fetchTextAxios({
      url: URL + 'users/export-csv/',
      method: 'GET',
      token
    })

    const csvModifed = csv.replace('(unlocked)', '(unlocked),');
    let arrayCSV: any[] = csvModifed.split(',')
    logger.debug("line 239 configurations.Settings.index arrayCSV", arrayCSV);
    let index: number = arrayCSV.findIndex((response: any) => response === 'Lists (unlocked)')
    let header: any[] = arrayCSV.slice(0, index);
    let body: any[] = arrayCSV.slice(index + 1,);
    let bodyNew = JSON.stringify(body).slice(6).slice(0, -8).replace(/"/g, '').replace(/,,,/g, '').replace(/,,/g, ',');
    const csvString = `${header.toString()} \n ${bodyNew}`;

    const pathToWrite = Platform.OS === "android" ? `${RNFetchBlob.fs.dirs.DownloadDir}/5corelife.csv` : `${RNFetchBlob.fs.dirs.DocumentDir}/5corelife.csv`;
    if (Platform.OS === "android") {
      const granted = await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE);
      const readGranted = await PermissionsAndroid.request(PermissionsAndroid.PERMISSIONS.READ_EXTERNAL_STORAGE);
      if (granted === PermissionsAndroid.RESULTS.GRANTED && readGranted === PermissionsAndroid.RESULTS.GRANTED) {
        RNFetchBlob.fs
          .writeFile(pathToWrite, csvString, 'utf8')
          .then(() => {
            RNFetchBlob.android.actionViewIntent(pathToWrite, 'text/csv')
            setMessage('Your file is being downloaded')
            setOpenDownload(true)
            logger.debug(`wrote file ${pathToWrite}`);
          })
          .catch((error: any) => console.error(error));
      } else {
        logger.info("Export permission denied");
      }
    } else {
      RNFetchBlob.fs
        .writeFile(pathToWrite, csvString, 'utf8')
        .then(() => {
          logger.debug(`wrote file ${pathToWrite}`);
          RNFetchBlob.ios.openDocument(pathToWrite);
        })
        .catch((error: any) => console.error(error));
    }
  }

  const [screenPosY] = useState(new Animated.Value(0));
  useEffect(() => {
    if (openDownload) {
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
      setOpenDownload(false)
    }
  }, [screenPosY, openDownload])

  const onPressCodeBook = async () => {
    try {
      let data: Map<string, string> = new Map();
      data.set("code", valueText);
      
      const codeRdemption = await fetchAxios(
        'POST',
        URL + 'users/code-redemption/',
        token,
        data
      )
      logger.debug('line 307 configurations.Settings.index codeRedemption: ', codeRdemption);
      setMessage(strings.CODEBOOK)
      setModalVisible(false)
    } catch (error: any) {
      logger.error('[ Code redemption error: ', error.response.data);
      setMessage(error.response.data?.code[0])
      setModalVisible(false)
      setOpenDownload(true)
    }
  }

  const formatdate = () => {
    if (settingsState) {
      if (Platform.OS === 'android') {
        if (timePicker === 'morning') return new Date(`1982-04-02T${settingsState.user_profile.morning_check_time}`)
        else return new Date(`1982-04-02T${settingsState.user_profile.night_check_time}`)
      } else {
        if (timePicker === 'morning') {
          if (settingsState.user_profile.morning_check_time.toString().length < 5) return new Date(`1982-04-02T0${settingsState.user_profile.morning_check_time}`)
          else return new Date(`1982-04-02T${settingsState.user_profile.morning_check_time}`)
        } else {
          if (settingsState.user_profile.night_check_time.toString().length < 5) return new Date(`1982-04-02T0${settingsState.user_profile.night_check_time}`)
          else return new Date(`1982-04-02T${settingsState.user_profile.night_check_time}`)
        }
      }
    }
    return new Date()
  }

  return (
    <>
      {
        activityIndicator.perfil &&
        <ActivityIndicator isVisible={activityIndicator.perfil} />
      }
      <ImageBackground
        style={styles.imageBackgroundContainer}
        source={require('../../../assets/images/settings/background.png')}
        resizeMode={'cover'}>
        <ScrollView style={{ flexGrow: 1 }}>
          <TouchableWithoutFeedback onPress={() => setShowTimePicker(false)}>
            <View>
              <HeaderDots
                dotsCount={3}
                activeDotIndex={0}
                disabled={onBoardingMode}
                onBackButton={() => {
                  navigate('Cores')
                }}
                onHelpButton={() => {
                  navigate('Help')
                }}
              />

              <HeaderSettings
                title={strings.TITLE}
                disabled={onBoardingMode}
                textTitleStyle={[
                  fonts.CORE_TITLE,
                  {
                    color: palette.TEXT_PRIMARY,
                    textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                  },
                ]}
                rightArrowNavigation={() => {
                  navigate('Storage')
                }}
              />

              <ModalCodeBook
                textTitle={strings.TYPE_CODE}
                textInputStyle={[fonts.COCKPIT_INPUT, palette.TEXT_PRIMARY]}
                textInput={valueText}
                autoCapitalize={"none"}
                keyboardType={"default"}
                isSecure={false}
                maxLength={8}
                onChangeText={setValueText}
                textTitleStyle={[fonts.MODAL_TITLE, { color: palette.TEXT_PRIMARY, fontSize: vw(4) }]}
                cancelButtonImage={
                  <Image
                    style={styles.buttons}
                    source={require('../../../assets/images/shared/button_cancel.png')}
                    resizeMode={'cover'}
                  />
                }
                okButtonImage={
                  <Image
                    style={styles.buttons}
                    source={require('../../../assets/images/shared/button_ok.png')}
                    resizeMode={'cover'}
                  />
                }
                onCancel={() => cancelOperation()}
                onOk={() => onPressCodeBook()}
                isVisible={isModalVisible}
              />

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
                        { color: palette.TEXT_PRIMARY, fontSize: vw(5) }
                      ]}>
                      {message}
                    </Text>
                  </View>
                </ImageBackground>
              </Animated.View>

              <ScrollView style={styles.viewElements}>
                {/* NOTIFICATIONS */}
                <View
                  style={[
                    styles.viewCard,
                    {
                      backgroundColor: palette.SETTINGS_CARD_BACKGROUND,
                      borderColor: palette.SETTINGS_CARD_BORDER,
                    },
                  ]}>
                  <Text
                    style={[
                      styles.textCardTitle,
                      fonts.SETTINGS_CARD_TITLE,
                      { color: palette.TEXT_PRIMARY },
                    ]}>
                    {strings.CARD_TITLE_NOTIFICATIONS}
                  </Text>

                  <Image
                    style={styles.imageCardLine}
                    source={require('../../../assets/images/shared/line.png')}
                    resizeMode={'contain'}
                  />

                  {/* MORNING TIME */}
                  <View style={styles.viewCheckIn}>
                    <Text
                      style={[
                        styles.textCardCheckInLabel,
                        fonts.SETTINGS_CARD_CHECK_IN,
                        { color: palette.TEXT_PRIMARY },
                      ]}>
                      {strings.CARD_PARAGRAPH_MORNING_CHECK_IN}
                    </Text>

                    <Text
                      style={[
                        styles.textCardCheckInTime,
                        fonts.SETTINGS_CARD_CHECK_IN_HOUR,
                        { color: palette.TEXT_PRIMARY },
                      ]}>
                      {parseDate(settingsState?.user_profile.morning_check_time)}
                    </Text>

                    <TouchableOpacity
                      onPress={() => {
                        if (onBoardingMode) setDisabled(true)
                        setTimePicker('morning')
                        setShowTimePicker(true)
                      }}>
                      <Image
                        style={styles.imageEdit}
                        source={require('../../../assets/images/shared/icon_edit.png')}
                        resizeMode={'contain'}
                      />
                    </TouchableOpacity>
                  </View>

                  {/* NIGHT TIME */}
                  <View style={styles.viewCheckIn}>
                    <Text
                      style={[
                        styles.textCardCheckInLabel,
                        fonts.SETTINGS_CARD_CHECK_IN,
                        { color: palette.TEXT_PRIMARY },
                      ]}>
                      {strings.CARD_PARAGRAPH_NIGHTLY_CHECK_IN}
                    </Text>

                    <Text
                      style={[
                        styles.textCardCheckInTime,
                        fonts.SETTINGS_CARD_CHECK_IN_HOUR,
                        { color: palette.TEXT_PRIMARY },
                      ]}>
                      {parseDate(settingsState?.user_profile.night_check_time)}
                    </Text>

                    <TouchableOpacity
                      onPress={() => {
                        if (onBoardingMode) setDisabled(true)
                        setTimePicker('nightly')
                        setShowTimePicker(true)
                      }}>
                      <Image
                        style={styles.imageEdit}
                        source={require('../../../assets/images/shared/icon_edit.png')}
                        resizeMode={'contain'}
                      />
                    </TouchableOpacity>
                  </View>

                  <View style={styles.viewSwitch}>
                    <Text
                      style={[
                        styles.textSwitch,
                        fonts.SWITCH,
                        { color: palette.TEXT_TERTIARY },
                      ]}>
                      {'OFF'}
                    </Text>
                    <Switch
                      trackColor={{
                        true: palette.TEXT_TERTIARY,
                        false: palette.BUTTON_BORDER,
                      }}
                      disabled={onBoardingMode}
                      thumbColor={palette.TEXT_TERTIARY}
                      onValueChange={toggleNotifications}
                      value={settingsState?.user_profile.notifications}
                    />
                    <Text
                      style={[
                        styles.textSwitch,
                        fonts.SWITCH,
                        { color: palette.TEXT_TERTIARY },
                      ]}>
                      {'ON'}
                    </Text>
                  </View>
                </View>

                {/* PAUSE APP */}
                <View
                  style={[
                    styles.viewCard,
                    {
                      backgroundColor: palette.SETTINGS_CARD_BACKGROUND,
                      borderColor: palette.SETTINGS_CARD_BORDER,
                    },
                  ]}>
                  <Text
                    style={[
                      styles.textCardTitle,
                      fonts.SETTINGS_CARD_TITLE,
                      { color: palette.TEXT_PRIMARY },
                    ]}>
                    {strings.CARD_TITLE_PAUSE}
                  </Text>

                  <Image
                    style={styles.imageCardLine}
                    source={require('../../../assets/images/storage/line.png')}
                    resizeMode={'contain'}
                  />

                  <Text
                    style={[
                      styles.textCardParagraph,
                      fonts.SETTINGS_CARD_PARAGRAPH,
                      { color: palette.TEXT_PRIMARY },
                    ]}>
                    {strings.CARD_PARAGRAPH_PAUSE}
                  </Text>

                  <View style={styles.viewSwitch}>
                    <Text
                      style={[
                        styles.textSwitch,
                        fonts.SWITCH,
                        { color: palette.TEXT_TERTIARY },
                      ]}>
                      {'OFF'}
                    </Text>
                    <Switch
                      trackColor={{
                        true: palette.TEXT_TERTIARY,
                        false: palette.BUTTON_BORDER,
                      }}
                      disabled={onBoardingMode}
                      thumbColor={palette.TEXT_TERTIARY}
                      onValueChange={togglePause}
                      value={settingsState?.user_profile.pause}
                    />
                    <Text
                      style={[
                        styles.textSwitch,
                        fonts.SWITCH,
                        { color: palette.TEXT_TERTIARY },
                      ]}>
                      {'ON'}
                    </Text>
                  </View>
                </View>

                {
                  isModalVisibleOkCancel &&
                  <ModalOkCancel
                    textTitle={strings.TEXT_WARNING}
                    textTitleStyle={[fonts.MODAL_TITLE,
                    { color: palette.TEXT_PRIMARY, fontSize: vw(3), marginTop: vh(23.3) }
                    ]}
                    okButtonImage={
                      <Image
                        style={styles.buttons}
                        source={require('../../../assets/images/shared/button_ok.png')}
                        resizeMode={'cover'}
                      />
                    }
                    cancelButtonImage={
                      <Image
                        style={styles.buttons}
                        source={require('../../../assets/images/shared/button_cancel.png')}
                        resizeMode={'cover'}
                      />
                    }
                    onCancel={() => setModalVisibleOkCancel(false)}
                    onOk={() => onPressAbort()}
                    isVisible={isModalVisibleOkCancel}
                  />
                }

                {/* ADD BOOK CODE */}
                <View style={styles.viewButtonSettings}>
                  <ButtonSettings
                    touchableOpacityContainerStyle={[
                      styles.buttonSettings,
                      {
                        backgroundColor: palette.SETTINGS_CARD_BACKGROUND,
                        borderColor: palette.SETTINGS_CARD_BORDER,
                      },
                    ]}
                    disabled={onBoardingMode}
                    touchableOpacityContainerOnPress={() => setModalVisible(true)}
                    textTitle={strings.BUTTON_BOOK_CODE}
                    textTitleStyle={[
                      fonts.SETTINGS_CARD_TITLE,
                      { color: palette.TEXT_PRIMARY },
                    ]}
                    imageRight={
                      <Image
                        style={styles.imageButtonSettings}
                        source={require('../../../assets/images/settings/icon_qr.png')}
                        resizeMode={'contain'}
                      />
                    }
                  />
                </View>

                {/* EXPORT to CSV */}
                <View style={styles.viewButtonSettings}>
                  <ButtonSettings
                    touchableOpacityContainerStyle={[
                      styles.buttonSettings,
                      {
                        backgroundColor: palette.SETTINGS_CARD_BACKGROUND,
                        borderColor: palette.SETTINGS_CARD_BORDER,
                      },
                    ]}
                    disabled={onBoardingMode}
                    touchableOpacityContainerOnPress={() => exportCSV()}
                    textTitle={strings.BUTTON_EXPORT_CSV}
                    textTitleStyle={[
                      fonts.SETTINGS_CARD_TITLE,
                      { color: palette.TEXT_PRIMARY },
                    ]}
                    imageRight={
                      <Image
                        style={styles.imageButtonSettings}
                        source={require('../../../assets/images/settings/icon_export.png')}
                        resizeMode={'contain'}
                      />
                    }
                  />
                </View>

                {/* ABORT */}
                <View style={styles.viewButtonSettings}>
                  <ButtonSettings
                    touchableOpacityContainerStyle={[
                      styles.buttonSettings,
                      {
                        backgroundColor: palette.DANGER,
                        borderColor: palette.SETTINGS_CARD_BORDER,
                      },
                    ]}
                    disabled={onBoardingMode}
                    textTitle={strings.BUTTON_ABORT_JOURNEY}
                    textTitleStyle={[
                      fonts.SETTINGS_CARD_TITLE,
                      { color: palette.TEXT_PRIMARY },
                    ]}
                    imageRight={
                      <Image
                        style={styles.imageButtonSettings}
                        source={require('../../../assets/images/settings/icon_close.png')}
                        resizeMode={'contain'}
                      />
                    }
                    touchableOpacityContainerOnPress={() => setModalVisibleOkCancel(true)}
                  />
                </View>
              </ScrollView>
            </ View>
          </TouchableWithoutFeedback>
        </ScrollView>
      </ImageBackground>


      {showTimePicker && settingsState && (
        <View style={Platform.OS === 'ios' ? { zIndex: 12, backgroundColor: 'white' } : null}>
          <RNDateTimePicker
            value={formatdate()}
            mode='time'
            is24Hour={true}
            display={Platform.OS === 'ios' ? 'spinner' : 'default'}
            textColor="black"
            // TODO: check this message for this property
            onChange={handleOnChangeTimePicker}
            onTouchCancel={() => {
              setShowTimePicker(false)
            }}
          />
        </View>
      )}
    </>
  )
}
