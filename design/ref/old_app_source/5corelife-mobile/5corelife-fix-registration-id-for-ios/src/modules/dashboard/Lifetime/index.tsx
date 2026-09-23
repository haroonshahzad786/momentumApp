import React, { useEffect, useRef, useState } from 'react'
import {
  Image,
  ImageBackground,
  ScrollView,
  TouchableWithoutFeedback,
  View,
  TouchableOpacity,
  Platform,
} from 'react-native'
import { useRecoilState, useRecoilValue, useResetRecoilState } from 'recoil'
import ModalJourney from '../../../components/ModalJourney'
import ModalMantra from '../../../components/ModalMantra'
import { vh, vw } from '../../../helpers/dimensions'
import { setAtomAxios } from '../../../helpers/recoil'
import {
  localDataAtom,
  mantraAtom,
  storageAtom,
  userInfoAtom,
  coresAtom,
  dailyCheckAtom,
  userRetrieveAtom,
} from '../../../recoil/atoms'
import { Mantra, UserLifetime, RocketJourney, UserRetrieve, Quest, Destinations, MissionsUser, ImprovementsUser, Improvement } from '../../../typescript/main'
import ModalPlanet from '../../../components/ModalPlanet';

import props from './props'
import strings from './strings'
import styles from './styles'

import Rocket from '../../../components/Rocket'
import { fetchAxios, fetchAxiosNoCache } from '../../../helpers/axios'
import { URL } from '../../../helpers/api'
import { getCurrentPosition } from '../../../helpers/destinationHelper'
import ModalRemind from '../../../components/ModalRemind'
import { logger } from '../../../helpers/logger'
import { updateImprovementsState } from '../../configuration/Improvements/utilities'

export default ({ navigation: { navigate } }: props) => {
  logger.info("[<Lifetime>]")
  const [storage, setStorage] = useRecoilState(storageAtom);
  const [localData, setLocalData] = useRecoilState(localDataAtom);
  const [dailyCheck, setDailyCheck] = useRecoilState(dailyCheckAtom);
  const userInfo = useRecoilValue(userInfoAtom);
  const resetLocalData = useResetRecoilState(localDataAtom);
  const [userProfileLocalData, setUserProfileLocalData] = useRecoilState(userRetrieveAtom);
  const [userRocket, setUserRocket] = useState<UserLifetime | null>(null);
  const [getDestiny, setGetDestiny] = useState<object | any>({});
  const cores = useRecoilValue(coresAtom);

  const {
    value: { token }
  } = useRecoilValue(storageAtom)

  const fonts = storage.value.fonts;
  const palette = storage.value.palette;
  const currentCheckIn = localData.value.currentCheckin;

  const scrollViewSpaceRef = useRef<ScrollView>(null);

  const [isModalJourneyVisible, setModalJourneyVisible] = useState<boolean>(false);
  const [isModalMantraVisible, setModalMantraVisible] = useState<boolean>(false);
  const [isModalRemindVisible, setModalRemindVisible] = useState<boolean>(false);
  const [isModalQuestVisible, setModalQuestVisible] = useState<boolean>(false);
  const [questOrMission, setQuestOrMission] = useState<string>('');

  const [days, setDaysJourney] = useState<number>()
  const [missions, setMissions] = useState<any>()
  const [perfile, setPerfile] = useState<any>()
  const [quest, setQuest] = useState<any>()

  // ----- MANTRA -----
  const [mantra, setMantra] = useRecoilState(mantraAtom);
  const [mantraState, setMantraState] = useState<Mantra | null>(null);

  useEffect(() => {
    logger.info('<MOUNT> |SCREEN| - Lifetime');
    logger.debug('line 78 Liftime.index onboarding; ', storage.value.onboarding, "\nuserProfileLocalData.value: ", userProfileLocalData.value?.user_profile?.onboarding);
    if (storage.value.onboarding || userProfileLocalData.value?.user_profile?.onboarding) {
      (async () => {
        try {
          logger.info('<FETCHING> - [USER_RETRIEVE]');
          const dataUserProfileResult: UserRetrieve = await fetchAxiosNoCache<null, UserRetrieve>(
            'GET',
            URL + 'users/retrieve/',
            token,
            null
          );

          const destinations: Destinations[] = await fetchAxios<null, Destinations[]>(
            'GET',
            URL + 'destinations/',
            token,
            null
          );

          const missions: MissionsUser[] = await fetchAxios<null, MissionsUser[]>(
            'GET',
            URL + 'missions/user/',
            token,
            null
          );

          const quests: Quest[] = await fetchAxiosNoCache<null, Quest[]>(
            'GET',
            URL + 'quests/user/',
            token,
            null
          )
          setQuest(quests)
          setMissions(missions)

          let days = destinations?.filter((response: Destinations) => response?.destination === dataUserProfileResult?.user_profile?.actual_destination)
          logger.debug("line 116 Lifetime.index days: ", days)
          setDaysJourney(days[0]?.length - dataUserProfileResult?.user_profile?.days_in_journey)
          setUserProfileLocalData({
            init: true,
            isLoading: false,
            request: null,
            value: dataUserProfileResult,
            error: null,
          });
          logger.debug("line 124 Lifetime.index userProfileLocalData: ", userProfileLocalData.value)
          
          if (!dataUserProfileResult.user_profile.onboarding) {
            logger.debug('Onboarding?');
            navigate('OnboardingStackScreen', {
              screen: 'StepOne',
              params: {
                navigate: navigate,
              },
            });
          }

        } catch (error) {
          logger.error('**ERROR** [GET-USER_RETRIEVE]');
          logger.error('[ERROR INFO]: ' + JSON.stringify(error));
        }
      })()
    }

    let Sound = require('react-native-sound')
    let Sound2 = require('react-native-sound')

    const soundAirlock = new Sound(
      require('../../../assets/sounds/airlock.mp3'),
      () => {
        soundAirlock.play((success: boolean) => logger.debug("line 149 Lifetime.index soundAirlock: ", success))
      },
    )

    const soundBackground = new Sound2(
      require('../../../assets/sounds/Menu_Select_01.mp3'),
      () => {
        soundBackground.play((success: boolean) => logger.debug("line 156 Lifetime.index soundBackground: ", success))
      },
    );
  }, []);

  const [perfiles, setperfiles] = useState<any>()
  useEffect(() => {
    const actualDestionationName = userProfileLocalData.value?.user_profile.actual_destination;

    setperfiles(userProfileLocalData.value?.user_profile)
    let perfile = userProfileLocalData.value?.user_profile
    if (actualDestionationName && actualDestionationName != null) {
      (async () => {
        try {
          const equip: ImprovementsUser[] = await fetchAxiosNoCache<null, ImprovementsUser[]>(
            'GET',
            URL + 'improvements/user/',
            token,
            null
          )
          logger.debug("line 180 Lifetime.index equip: ", equip)
          const improvementEquipped: Improvement[] = updateImprovementsState(equip);
          setLocalData({
            ...localData,
            value: {
              ...localData.value,
              improvements: improvementEquipped
            },
          });

          let userTurbines = localData.value.improvements?.find(
            (x: Improvement) => ((x.type === 'THRUSTER') && x.isActive),
          )?.name ?? 'Base Thruster';

          let userWings = localData.value.improvements?.find(
            (x: Improvement) => ((x.type === 'WINGS') && x.isActive),
          )?.name ?? 'Base Wings';

          let userSkinColor = localData.value.improvements?.find(
            (x: Improvement) => ((x.type === 'ARMOR') && x.isActive),
          )?.name ?? 'Base Armor';

          setUserRocket({
            journey: getCurrentPosition(perfile) as RocketJourney,
            rocket: {
              turbines: userTurbines,
              wings: userWings,
              color: userSkinColor,
            },
          });
        } catch (error: any) {
          logger.error('[ERROR ROCKET] SERVICE ERROR', error);
        }
      })();

      (async () => {
        try {
          logger.info('<FETCHING> - [DESTINATIONS CC]');
          const destinations: Destinations[] = await fetchAxios<null, Destinations[]>(
            'GET',
            URL + 'destinations/',
            token,
            null
          );

          let destiny = destinations?.find(
            (x: Destinations) => x.destination === actualDestionationName,
          )
          logger.debug("line 255 Lifetime.index destiny: ", destiny)
          setGetDestiny(destiny)
        } catch (err) {
          logger.error('**ERROR** [POST-DESTINATIONS]');
          logger.error('[ERROR INFO]: ' + JSON.stringify(err));
        }
      })();

      setTimeout(() => {
        scrollViewSpaceRef.current?.scrollTo({ x: 0, y: vh(160), animated: true })
      }, 2000)
    }
  }, [userProfileLocalData]);

  useEffect(() => {
    setMantraState(mantra.value)
  }, [setMantraState, mantra.value])


  const onClickOkJourney = () => {
    logger.info('(USER ACTION) - MODAL NIGHTCHECK CONFIRM');
    if (currentCheckIn === 'night') {
      setModalJourneyVisible(false);
      setLocalData({
        ...localData,
        value: {
          ...localData.value,
          nightCheckInStarted: true,
        },
      });
      navigate('NightCheckIn');
    } else {
      setLocalData({
        ...localData,
        value: {
          ...localData.value,
          morningCheckInStarted: true,
        },
      });
      setModalJourneyVisible(false);
      const showLaunch = userProfileLocalData.value?.user_profile.days_in_journey === 0;
      setModalMantraVisible(true);

    }
  }

  const onClickOkMantra = () => {
    setModalMantraVisible(false);
    onClickOkQuest()
    logger.info('-> SHOWING MODAL 3 - MORNING CHECKIN - QUEST');
  }
  const onClickOkQuest = () => {
    setModalQuestVisible(false);
    if (localData.value.openCheckin && !localData.value.lastMorningCheckInCompleted) navigate('Cores')
    else navigate('Journey')
  }

  const onClickBackground = () => {
    logger.debug('(USER ACTION) - continuing the following window');
    logger.debug("line 320 Lifetime.index getDestiny: ", getDestiny);
    logger.debug("line 321 Lifetime.index openCheckin: ", localData.value?.openCheckin);
    logger.debug("line 322 Lifetime.index lastNightCheckInCompleted: ", localData.value?.lastNightCheckInCompleted);
    logger.debug("line 323 Lifetime.index lastMorningCheckInCompleted: ", localData.value?.lastMorningCheckInCompleted);
    logger.debug("line 324 Lifetime.index currentCheckIn: ", currentCheckIn);
    if (
      (currentCheckIn === 'morning' &&
        !localData.value.morningCheckInStarted &&
        localData.value.openCheckin &&
        !localData.value.lastMorningCheckInCompleted)
    ) {
      logger.info('-> SHOWING MODAL 1 - MORNING CHECKIN');
      setModalJourneyVisible(true);
    }
    else if (
      currentCheckIn === 'night'
      && localData.value.openCheckin
      && localData.value.lastNightCheckInCompleted === null
      && localData.value.lastMorningCheckInCompleted
      && getDestiny.destination === 'Space Station 1'
    ) {
      setModalRemindVisible(true)
    }
    else if (
      currentCheckIn === 'night'
      && localData.value.openCheckin
      && localData.value.lastNightCheckInCompleted === null
      && localData.value.lastMorningCheckInCompleted
      && getDestiny.destination !== 'Space Station 1'
    ) {
      logger.info('-> SHOWING MODAL - NIGHT CHECKIN');
      setModalJourneyVisible(true);
    } else {
      if (perfile?.user_profile?.in_journey) navigate('Journey');
      else navigate('Cores');
    }
  }

  const updateMantraState = (text: string) => {
    setMantraState({ ...mantraState!, mantra: text })
  }

  const saveMantra = () => {
    if (mantra.value?.mantra !== mantraState?.mantra) {
      setAtomAxios(setMantra, {
        method: 'PUT',
        url: URL + 'users/mantra/',
        data: {
          mantra: mantraState?.mantra,
        },
      })
    }
    onClickOkMantra()
  }

  const handleModalRemind = () => {
    logger.debug('line 367 Lifetime.index handleModalRemind')
    setModalRemindVisible(false)
    setTimeout(() => {
      logger.debug('line 370 Lifetime.index handleModalRemind setTime')
      setModalJourneyVisible(true);
    }, Platform.OS === 'ios' ? 1500 : 0);
  }

  return (
    <>
      {
        isModalRemindVisible &&
        <ModalRemind
          title={strings.TITLE_REMIND}
          subTitle={strings.SUBTITLE_REMIND}
          content={strings.CONTENT_REMIND}
          touchableOpacityContainerButtonStyle={{
            width: vw(25),
            height: vh(7),
            borderRadius: vw(10),
            borderWidth: vw(0.5),
            borderColor: palette.BUTTON_BORDER,
            backgroundColor: palette.SUCCESS,
          }}
          textTitleButtonStyle={[
            styles.modalQuizTextDoneButton,
            fonts.BUTTON_MEDIUM,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW,
            },
          ]}
          onPress={() => handleModalRemind()}
          isVisible={isModalRemindVisible}
        />
      }

      {
        isModalJourneyVisible &&
        <ModalJourney
          onClickOk={onClickOkJourney}
          touchableOpacityContainerButtonStyle={[
            styles.modalJourneyOpacityContainerButton,
            {
              borderColor: palette.BUTTON_BORDER,
              backgroundColor: palette.SUCCESS,
            },
          ]}
          textTitleButtonStyle={[
            styles.modalJourneyTextDoneButton,
            fonts.BUTTON_MEDIUM,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW,
            },
          ]}
          textMainHeader={
            currentCheckIn === 'night'
              ? strings.MODAL_NIGHT_CHECK_IN_MAIN_HEADER
              :
              strings.MODAL_JOURNEY_MAIN_HEADER
          }
          textContentHeader={
            currentCheckIn === 'night' ? strings.MODAL_JOURNEY_CONTENT_HEADER :
              strings.MODAL_JOURNEY_CONTENT_HEADER_MORNIG}
          textContentInfo={strings.MODAL_JOURNEY_CONTENT_INFO}
          isVisible={isModalJourneyVisible}
        />
      }
      {
        isModalMantraVisible &&
        <ModalMantra
          textTitle={strings.MODAL_MANTRA_TITLE}
          textTitleStyle={[
            styles.modalMantraTextTitle,
            fonts.MANTRA_TITLE,
            { color: palette.TEXT_TERTIARY },
          ]}
          iconRight={
            <Image
              style={styles.modalMantraIconRightImage}
              source={require('../../../assets/images/shared/button_edit.png')}
              resizeMode={'cover'}
            />
          }
          textInputParagraphFirst={mantraState?.mantra}
          textInputParagraphFirstOnChangeText={updateMantraState}
          textParagraphSecond={''}
          textInputParagraphStyle={[
            styles.modalMantraTextParagraph,
            fonts.MANTRA_PARAGRAPH,
            { color: palette.TEXT_PRIMARY },
          ]}
          textParagraphDividerStyle={[
            fonts.MANTRA_PARAGRAPH,
            { color: palette.TEXT_PRIMARY },
          ]}
          touchableOpacityContainerButtonStyle={[
            styles.modalMantraOpacityContainerButton,
            {
              borderColor: palette.BUTTON_BORDER,
              backgroundColor: palette.SUCCESS,
            },
          ]}
          touchableOpacityContainerButtonOnPress={saveMantra}
          textTitleButton={strings.MODAL_MANTRA_BUTTON_TEXT}
          textTitleButtonStyle={[
            styles.modalMantraTextDoneButton,
            fonts.BUTTON_MEDIUM,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW,
            },
          ]}
          isVisible={isModalMantraVisible}
        />
      }

      <View style={styles.container}>
        <ScrollView
          ref={scrollViewSpaceRef}
          style={styles.containerSub}
          bounces={false}
          showsVerticalScrollIndicator={false}
        >

          <ImageBackground
            style={[styles.containerImageBackground]}
            source={require('../../../assets/images/lifetime/background_simple.png')}
            resizeMode={'cover'}>
            <ImageBackground
              style={[styles.containerPlanets]}
              source={require('../../../assets/images/lifetime/background_planets_only.png')}
              resizeMode={'contain'}>
              <ModalPlanet
                style={[
                  fonts.ACCORDION_TITLE,
                  palette.TEXT_PRIMARY,
                  palette.TEXT_SECONDARY,
                  palette.LIFETIME_PLANET,
                  palette.BACKGROUND_DARK_BLUE,
                  palette.LEADERBOARD_HEADER_GRAY,
                  fonts.LOGIN_SIGN_IN,
                ]}
                planet={getDestiny}
              />
              <View style={styles.rocketRoad}>
                {userRocket &&
                  <TouchableWithoutFeedback
                    style={styles.containerTWF}
                    onPress={onClickBackground}>
                    <View style={[styles.rocketLocation,
                    {
                      left: vw(userRocket?.journey.xPos ?? 0),
                      top: vh(userRocket?.journey.yPos ?? 0),
                      transform: [{ rotate: userRocket?.journey.angle ?? '0deg' }]
                    }
                    ]}>

                      <Rocket
                        externalStyle={styles.imageRocket}
                        turbines={userRocket.rocket.turbines}
                        wings={userRocket.rocket.wings}
                        skinColor={userRocket.rocket.color}
                      />
                    </View>
                  </TouchableWithoutFeedback>
                }
              </View>
              <View style={styles.containerButtonNext}>
                <TouchableOpacity onPress={onClickBackground}>
                  <Image
                    style={styles.buttonNext}
                    source={require('../../../assets/images/onboarding/button_next.png')}
                    resizeMode="contain"
                  />
                </TouchableOpacity>
              </View>
            </ImageBackground>

          </ImageBackground>
        </ScrollView>
      </View>
    </>
  )
}