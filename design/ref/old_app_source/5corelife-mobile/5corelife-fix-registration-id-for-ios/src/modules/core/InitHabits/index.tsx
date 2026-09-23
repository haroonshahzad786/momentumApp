import { cloneDeep } from 'lodash'
import React from 'react'
import {
  Image,
  ImageBackground,
  Text,
  TouchableOpacity,
  View,
  Animated,
  Easing
} from 'react-native'
import { Grayscale } from 'react-native-color-matrix-image-filters'
import { useRecoilState, useRecoilValue } from 'recoil'

import ButtonBack from '../../../components/ButtonBack'
import CockpitScreen from '../../../components/CockpitScreen'
import HeaderSettings from '../../../components/HeaderSettings'
import { URL } from '../../../helpers/api'
import { fetchAxios, fetchAxiosNoCache } from '../../../helpers/axios'
import { getImageByCore } from '../../../helpers/internalDataManagement'
import { vh } from '../../../helpers/dimensions'
import { localDataAtom, storageAtom, userInfoAtom, userRetrieveAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { getNextPrev } from '../../../helpers/commonHelper'
import { Core } from '../../../typescript/main'
import { logger } from '../../../helpers/logger'

export default ({
  navigation: { navigate, pop, replace },
  route: {
    params: { core },
  },
}: props) => {
  const [storage, setStorage] = useRecoilState(storageAtom);
  const userInfo = useRecoilValue(userInfoAtom);
  const [localData, setLocalData] = useRecoilState(localDataAtom);
  const userRetrieve = useRecoilValue(userRetrieveAtom);
  const fonts = storage.value.fonts;
  const palette = storage.value.palette;
  const token = storage.value.token;
  const coreIsAvailable = userRetrieve.value?.user_profile.cores_available && userRetrieve.value?.user_profile.cores_active ?
    userRetrieve.value?.user_profile.cores_available > userRetrieve.value?.user_profile.cores_active : false;

  const [isQuizModalVisible, setQuizModalVisible] = React.useState<boolean>(false);
  const [screenPosY] = React.useState(new Animated.Value(0));

  // Only can activate one core if it is in the morning process.
  const enableAvailable =
    localData.value.morningCheckInStarted &&
    localData.value.lastMorningCheckInCompleted == null &&
    localData.value.currentCheckin === 'morning' &&
    coreIsAvailable;

  const enableButtonToActiveCoreButton =
    localData.value.morningCheckInStarted &&
    localData.value.lastMorningCheckInCompleted == null &&
    localData.value.currentCheckin === 'morning';

  const userCouldActive = enableButtonToActiveCoreButton && coreIsAvailable;
  const requiredDataByCore = getImageByCore(core.core_string);
  const [stateCore, setStateCore] = React.useState(false);
  const queryCores = async () => {
    const queryCore: Core[] = await fetchAxiosNoCache<null, Core[]>(
      'GET',
      URL + 'cores/user/',
      token,
      null
    );
    const coreCurrent = queryCore.filter((cores: {
      user: number,
      core_string: string,
      enabled: boolean,
      core_power: number
    }) => cores.core_string === core.core_string && cores.core_string)
    setStateCore(coreCurrent[0].enabled);
  }

  React.useEffect(() => {
    queryCores()
  }, [])

  const activeNewCoreProcess = async () => {
    logger.debug('line 88 InitHabits.index -> (USER ACTION) - ACTIVATE CORE: ' + core.core_string);
    logger.info('<POSTING> - [CORES_BY_USER]');
    try {
      const data = await fetchAxios(
        'POST',
        URL + 'cores/user/',
        token,
        {
          core: core.core_string,
        },
      );

      logger.debug('Post core user success :' + JSON.stringify(data))

      const storageCopy = cloneDeep(localData.value ?? [])
      const coreIndex = storageCopy.coreInfo.findIndex(
        (currentCore) => currentCore.core_string === core.core_string,
      )

      if (coreIndex >= 0) {
        storageCopy.coreInfo[coreIndex].enabled = true;
        storageCopy.coreInfo[coreIndex].openCheckin = true;
        storageCopy.coreInfo[coreIndex].lastMorningCheckIn = Date.now();
      }

      setLocalData({
        init: true,
        value: storageCopy,
      });

      if (coreIndex >= 0) {
        replace('CheckHabits', {
          core: storageCopy.coreInfo[coreIndex],
          habits: core.habits,
          score: core.core_power
        });
      } else {
        // F KGZ
        const coreCopy = cloneDeep(core);
        coreCopy.enabled = true;

        replace('CheckHabits', { core: coreCopy });
      }

    } catch (error) {

      logger.error('**ERROR** [POST-CORES_BY_USER]');
      logger.error('[ERROR INFO]: ' + JSON.stringify(error));
    }
  }

  const enableError = () => {
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
        duration: 3500,
        useNativeDriver: true
      }),
    ]).start()
  }

  const openQuizModal = () => {

    // if (enableAvailable) { enableError(); return null; }
    if (!enableAvailable || stateCore) { enableError(); return null; }
    setQuizModalVisible(true)
  }
  const closeQuizModal = () => {
    setQuizModalVisible(false)
    activeNewCoreProcess();
  }

  const goToDashboard = () => {
    logger.debug('line 170 InitHabits Comming back to dashboard')
    navigate('DashboardStackScreen', {
      screen: 'Cores',
    })
  }

  return (
    <>
      <ImageBackground
        style={styles.imageBackgroundContainer}
        source={core.enabled || stateCore ? requiredDataByCore.habitScreenBackground : require('../../../assets/images/habits_screen/background.png')}
        resizeMode={'stretch'}>
        <>
          <View style={styles.viewButtonBack}>
            <ButtonBack
              onPress={goToDashboard}
            />
          </View>

          <View style={styles.containerHeaderSettings}>
            <HeaderSettings
              isIcon={true}
              primaryColor={requiredDataByCore.primaryColor}
              avatarPath={requiredDataByCore.avatarIcon}
              avatarTitlePath={requiredDataByCore.avatarTitle}
              leftArrowNavigation={getNextPrev(core.core_string, navigate).prevCore}
              rightArrowNavigation={getNextPrev(core.core_string, navigate).nextCore}
              textTitleStyle={[
                fonts.CORE_TITLE,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                },
              ]}
            />
          </View>

          <View style={styles.viewCockpitScreen}>
            <CockpitScreen
              onPress={() => {
                null
              }}
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
                    { color: palette.TEXT_PRIMARY, fontSize: 17 }
                  ]}>
                  {strings.ACTIVATE_NEGATIVE}
                </Text>
              </View>
            </ImageBackground>
          </Animated.View>

          <TouchableOpacity
            style={styles.touchableOpacityButtonPower}
            onPress={userCouldActive ? activeNewCoreProcess : enableError}
            disabled={!enableButtonToActiveCoreButton}>
            <Grayscale amount={userCouldActive ? 0 : 1}>
              <Image
                style={styles.imageButtonPower}
                source={
                  !core.enabled ||
                    stateCore
                    ? require('../../../assets/images/habits/button_on.png')
                    : require('../../../assets/images/habits/button_off.png')
                }
                resizeMode={'contain'}
              />
            </Grayscale>
          </TouchableOpacity>

          <View style={styles.viewElements}>
            <Text
              style={[
                styles.textTitle,
                fonts.CORE_ACTIVATE_TITLE,
                {
                  color: palette.TEXT_PRIMARY,
                  shadowColor: palette.TEXT_PRIMARY_SHADOW,
                },
              ]}>
              {`${enableAvailable
                ? strings.TITLE_OFF_ACTIVATE
                : strings.TITLE_OFF_ACTIVATE_DISABLED
                }${'\n' +
                (enableAvailable
                  ? strings.TITLE_OFF_CORE
                  : strings.TITLE_OFF_CORE_DISABLED)
                }`}
            </Text>

            <Image
              style={styles.imageLine}
              source={require('../../../assets/images/habits/line.png')}
              resizeMode={'contain'}
            />

            <Text
              style={[
                styles.textSubtitle,
                fonts.CORE_ACTIVATE_SUBTITLE,
                { color: palette.TEXT_PRIMARY },
              ]}>
              {enableAvailable
                ? strings.SUBTITLE_OFF
                : strings.SUBTITLE_OFF_DISABLED}
            </Text>
          </View>
        </>
      </ImageBackground>
    </>
  )
}
