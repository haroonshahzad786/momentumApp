/* eslint-disable react-hooks/exhaustive-deps */
import { useFocusEffect } from '@react-navigation/core'
import React, { useCallback, useEffect, useState } from 'react'
import {
  Animated,
  Image,
  ImageBackground,
  SafeAreaView,
  Text,
  TouchableOpacity,
  View,
  Easing,
  Platform,
} from 'react-native'
import { DuoTone } from 'react-native-color-matrix-image-filters'
import { useRecoilValue, useRecoilState } from 'recoil'
import ModalJourney from '../../../components/ModalJourney'
import ModalQuests from '../../../components/ModalQuests'
import { vh, vw } from '../../../helpers/dimensions'
import { URL } from '../../../helpers/api'
//@ts-ignore
import Video from "react-native-video";

import {
  coresAtom,
  dailyCheckAtom,
  localDataAtom,
  storageAtom,
  userRetrieveAtom,
} from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import IndividualCore from './IndividualCore'
import { fetchAxios, fetchAxiosNoCache } from '../../../helpers/axios'
import { getPowerFlameAnimation, getImprovementsColors, getImprovementsTurbines, getImprovementsWings } from '../../../helpers/internalDataManagement'
import ArrowsIndicator from '../../onboarding/ArrowsIndicator'
import { Core, CoreInfo, Destinations, HabitsMorninAndNightgCheckResponse, HabitsMorninCheckRequest, Improvement, RocketComposition, UserRetrieve } from '../../../typescript/main'
import { setAtomAxios, setAtomManual } from '../../../helpers/recoil'
import { cloneDeep } from 'lodash'
import FirstQuiz from '../../../components/ModalQuiz/FirstQuiz'
import { listQuizAllCore } from '../../../helpers/listQuiz'
import { typeFlame } from '../../../helpers/flame'
import ActivityIndicator from '../../../components/ActivityIndicator'
import ModalPlanetLifetime from '../../../components/ModalPlanetLifetime'
import ModalGoCockpit from '../../../components/ModalGoCockpit'
import VideoScreen from '../../../components/VideoScreen'
import ModalGoals from '../../../components/ModalGoals'
import { logger } from '../../../helpers/logger'

// TODO: correct area touch for every core.
// Implement touch opacities invisibles.
export default (
  {
    navigation: { navigate },
    onBoardingMode,
    isLastTab = false,
    isCoreStep = false,
    navigateToNextStep,
    launch,
    cockpit,
    checkInMorningForce,
    setAdviseActive,
  }: props) => {
    logger.info("[<Dashboard-Cores>]")
  const {
    value: { fonts, palette, token, onboarding_pendingpost },
  } = useRecoilValue(storageAtom);
  const [coresLocal, setCoresData] = useRecoilState(coresAtom);
  const dailyCheck = useRecoilValue(dailyCheckAtom);
  const [localData, setLocalData] = useRecoilState(localDataAtom);
  const [rocketComposition, setRocketComposition] = useState<RocketComposition | null>(null);
  const [rocketPosY] = useState(new Animated.Value(0));
  const [isModalCheckIsVisible, setModalCheckIsVisible] = useState<boolean>(false);
  const [userProfileLocal, setUserProfileLocal] = useRecoilState(userRetrieveAtom);
  const [storage, setStorage] = useRecoilState(storageAtom);
  const [coresByUserData, setCoresByUserData] = useState<Core[]>([]);
  const [isModalQuestVisible, setModalQuestVisible] = useState<boolean>(false);
  const [quest, setQuest] = useState<any>({})
  const [missions, setMissions] = useState<any>({})
  const [questOrMission, setQuestOrMission] = useState<string>('');
  const [bucleEnd, setBucleEnd] = useState(false)
  const [days, setDaysJourney] = useState<number | string>()
  const [destinations, setDestination] = useState<any>()
  const [isQuizModalVisible, setQuizModalVisible] = useState<boolean>(false);
  const [isCoresModalVisible, setCoresModalVisible] = useState<boolean>(false);
  const [enableAvailable, setEnableAvailable] = useState<boolean>(false);
  const [isLaunchVideoVisible, setLaunchVideoVisible] = useState<boolean>(false);
  const [isScreenPlanetVisible, setScreenPlanetVisible] = useState<boolean>(false);
  const [isPositionActual, setPositionActual] = useState<any>([]);
  const [activityIndicator, setActivityIndicator] = useState({
    cores: false,
    perfil: false,
    destination: false,
    morning: false,
    forceMorning: false
    // firstLoading: true,
  })

  const [secondDays, setSeconDays] = useState<boolean>(false)

  useEffect(() => {
    (async () => {
      try {
        const dataUserProfileResult: UserRetrieve = await fetchAxiosNoCache<null, UserRetrieve>(
          'GET',
          URL + 'users/retrieve/',
          token,
          null
        );

        if (dataUserProfileResult?.user_profile?.days_in_journey === 2 && (localData.value.morningCheckInStarted && localData.value.lastMorningCheckInCompleted) && localData.value.lastNightCheckInCompleted === null && !localData.value.secondDaysJourney) {
          setSeconDays(true)
        }
      }
      catch (error: any) {
        logger.error("Error Core first useEffect getting dataUserProfileResult: ",error.response);
      }
    })()
  }, [localData.value.morningCheckInStarted, localData.value.lastMorningCheckInCompleted, localData.value.lastNightCheckInCompleted])

  useFocusEffect(useCallback(() => {
    setAtomAxios(setCoresData, {
      method: 'GET',
      url: URL + 'cores/user/',
      token,
    });
    logger.debug("useFocusEffect getting Cores by User: ", coresLocal)
  }, []));

  const onClickOkCheckIn = async () => {
    setLaunchVideoVisible(false);
    logger.debug("line 133 Cores.index onClickOkCheckIn localData.value: ", JSON.stringify(localData.value));
    logger.debug("line 134 Core.index dailyCheck.value: ", dailyCheck.value," dailyCheck.value.length: ", dailyCheck.value?.length, " checkInMorningForce: ", checkInMorningForce)
    if ((dailyCheck.value != null && dailyCheck.value.length > 0) || checkInMorningForce) {
      const confirmCheckInProcess = async () => {
        logger.debug('-> MORNING CHECKIN CONFIRM PROCESS');

        const coresAndHabits = localData.value.coreInfo
          .filter((core) => {
            return core.enabled && core.morningCheckInHabits && (core.morningCheckInHabits.length > 0);
          })
          .map((core) => {
            const data = {
              core: core.core_string,
              habits: core.morningCheckInHabits.map((habit) => {
                return habit.id
              }),
            };
            logger.debug("coresAndHabits data: ", data)
            return data;
          });
        setActivityIndicator({
          ...activityIndicator,
          morning: true
        })
        try {
          logger.info('<POSTING> - [MORNINGCHECK]');
          const habitsMorningCheck: HabitsMorninAndNightgCheckResponse = await fetchAxios<HabitsMorninCheckRequest[],HabitsMorninAndNightgCheckResponse>(
            'POST',
            `${URL}habits/morning-check/`,
            token,
            coresAndHabits,
          );
          logger.debug("line 165 Core.index habitsMorningCheck: ", habitsMorningCheck)
          setBucleEnd(true)
          setQuest(habitsMorningCheck.quest)
          setMissions(habitsMorningCheck?.mission)
          let days = destinations?.filter((response: any) => response?.destination === habitsMorningCheck?.journey?.actual_destination)
          setDaysJourney(days[0]?.length - habitsMorningCheck?.journey?.days_in_journey)
          questVisible(habitsMorningCheck)
          logger.debug('>>>>>> DATA' + JSON.stringify(habitsMorningCheck), ' ->>>>> DATA TO SEND: ' + JSON.stringify(coresAndHabits));
          setModalCheckIsVisible(false);
        } catch (error) {
          logger.error('Post Habits Morning Check error:', JSON.stringify(error));
        }
        finally {
          setActivityIndicator({
            ...activityIndicator,
            morning: false
          })
        }
      };

      await confirmCheckInProcess();
      logger.debug('-> ONBOARDING PENDING POST: ' + onboarding_pendingpost + ' - Checking if exist post pending after doing the onboarding');
      setLocalData({
        init: true,
        value: {
          ...localData.value,
          lastMorningCheckInCompleted: Date.now(),
        },
      });
      if ((onboarding_pendingpost === true)) {
        logger.debug('-> Set in false the pending post.');
        setStorage({
          ...storage,
          value: { ...storage.value, onboarding: false, onboarding_pendingpost: false },
        });
      };
    }
  }

  const [indicatorSetting, setIndicatorSetting] = useState(false)
  const questVisible = (data: any) => {
    setLaunchVideoVisible(false);
    if (Object.keys(data?.mission).length && data?.mission.active === true && data?.mission.success === false) {
      setQuestOrMission('missions')
      setDaysJourney('TODAY')
      setModalQuestVisible(true);
      if (checkInMorningForce) {
        setIndicatorSetting(true)
        setAdviseActive(true)
      }
      return null;
    }
    if (Object.keys(data?.quest).length && data?.quest.active === true && data?.quest.success === false) {
      setQuestOrMission('quests')
      setModalQuestVisible(true);
      if (checkInMorningForce) {
        setIndicatorSetting(true)
        setAdviseActive(true)
      }
      return null;
    }
    setModalQuestVisible(false);
  }

  useEffect(() => {
    logger.debug("line 231 Core.index useEffect  localData: ", localData.value)
    const userImprovements = localData.value.improvements;
    let userTurbines = userImprovements?.find(
      (x: Improvement) => ((x.type === 'THRUSTER') && x.isActive),
    )?.name ?? 'Base Thruster';

    let userWings = userImprovements?.find(
      (x: Improvement) => ((x.type === 'WINGS') && x.isActive),
    )?.name ?? 'Base Wings';

    let userSkinColor = userImprovements?.find(
      (x: Improvement) => ((x.type === 'ARMOR') && x.isActive),
    )?.name ?? 'Base Armor';

    setRocketComposition({
      turbines: userTurbines,
      wings: userWings,
      color: userSkinColor,
    });

    const enableAvailableVar =
      localData.value.morningCheckInStarted &&
      localData.value.lastMorningCheckInCompleted == null &&
      localData.value.currentCheckin === 'morning';
      logger.debug("line 255 Core.index enableAvailableVar: ", enableAvailableVar)
    setEnableAvailable(enableAvailableVar);

  }, [localData]);

  useEffect(() => {
    const startLoop = () => {
      Animated.loop(
        Animated.sequence([
          Animated.timing(rocketPosY, {
            toValue: -vh(29),
            easing: Easing.inOut(Easing.ease),
            duration: 2500,
            useNativeDriver: true,
          }),
          Animated.timing(rocketPosY, {
            toValue: -vh(31),
            easing: Easing.inOut(Easing.ease),
            duration: 2500,
            useNativeDriver: true,
          }),
        ]),
      ).start()
    }

    Animated.timing(rocketPosY, {
      delay: 100,
      toValue: -vh(31),
      easing: Easing.elastic(0.5),
      duration: 2000,
      useNativeDriver: true,
    }).start(startLoop)
  }, [rocketPosY]);

  useEffect(() => {
    let Sound = require('react-native-sound')

    const soundAirlock = new Sound(
      require('../../../assets/sounds/Ambience_Space_00.mp3'),
      () => {
        soundAirlock.play((success: any) => logger.debug("line 312 Cores.index soundAirlock success: ", success))
      }
    )
  }, [])

  const [openRocke, setOpenRocke] = useState<boolean>(true)
  useFocusEffect(
    () => {
      logger.debug("line 303 Core.index fifth useEffect localData: ", localData.value, "openRocket: ", openRocke)
      if (localData == null || localData.value == null || !openRocke) return;
      const showLaunch = userProfileLocal.value?.user_profile.days_in_journey === 0;
      if (
        localData.value != null &&
        localData.value.coreInfo != null &&
        localData.value.coreInfo.length > 0 &&
        ((localData.value.currentCheckin === 'morning' &&
          localData.value.morningCheckInStarted &&
          localData.value.lastMorningCheckInCompleted == null) ||
          (onboarding_pendingpost === true &&
            localData.value.lastMorningCheckInCompleted == null)
        )
      ) {
        let allCompleted = true;
        let completedCount = 0

        logger.debug('line 320 Core.index -> UPDATING LOCAL CORES - Updating locals cores with the date of CHECKIN (morning or night)');
        localData.value.coreInfo.forEach((element) => {
          if (element.enabled && (element.openCheckin || onboarding_pendingpost)) {
            if (
              (localData.value.morningCheckInStarted &&
                element.lastMorningCheckIn === null) ||
              (onboarding_pendingpost &&
                element.lastMorningCheckIn === null)
            ) {
              allCompleted = false;
            } else if (
              (localData.value.morningCheckInStarted &&
                element.lastMorningCheckIn != null) ||
              (onboarding_pendingpost &&
                element.lastMorningCheckIn != null)
            ) {
              completedCount++;
            }
          }
        });
        logger.debug("line 340 Core.index allCompleted: ", allCompleted, 
        "\ncompletedCount: ", completedCount, 
        "\nlocalData: ", localData.value.currentCheckin, 
        "\nonboarding_pendingpost: ", onboarding_pendingpost,
        "\nbucleEnd: ", bucleEnd, "\nlaunch: ", launch, "\ncheckInMorningForce: ", checkInMorningForce);
        if ((allCompleted && completedCount > 0 && (localData.value.currentCheckin === 'morning' || onboarding_pendingpost) && !bucleEnd && !launch) || checkInMorningForce) {
          logger.info('-> SHOWING MODAL - CONFIRM MORNING CHECKIN');
          if (checkInMorningForce) {
            setTimeout(() => {
              setLaunchVideoVisible(true);
            }, Platform.OS == 'ios' ? 5000 : 10000);
          } else {
            if (showLaunch) setLaunchVideoVisible(true);
            else setModalCheckIsVisible(true)
          }
        }
      }
    }
  );

  useEffect(() => {
    (async () => {
      setActivityIndicator({
        ...activityIndicator,
        destination: true
      })
      try {
        const destinations: Destinations[] = await fetchAxios<null, Destinations[]>(
          'GET',
          URL + 'destinations/',
          token,
          null
        );
        const destiny = destinations?.find(
          (x: Destinations) => x.destination === userProfileLocal.value?.user_profile.actual_destination,
        )
        
        const destiny_lenght = destinations?.find(
          (x: Destinations) => x.length === userProfileLocal.value?.user_profile.actual_destination_length,
        )

        const origin = destinations?.find(
          (x: Destinations) => x.length === destiny_lenght?.length ? destiny_lenght?.length - 1 : destiny_lenght?.length,
        ) ?? 'default';

        logger.debug("line 386 Core.index origin: ", origin, " destiny_lenght: ", destiny_lenght, " destiny: ", destiny)

        setPositionActual(origin)
      } catch (error: any) {
        logger.error("Core.index error destination: ", error.response.data);
      }
      finally {
        setActivityIndicator({
          ...activityIndicator,
          destination: false
        })
      }
    })()
  }, [])

  const fetchCoresByUser = async () => {
    logger.debug("-> REFRESHING DATA OF CORES - Refresh all data of the cores to recalculate the powerand momentum.");
    setActivityIndicator({
      ...activityIndicator,
      cores: true
    })
    try {
      logger.info('<FETCHING> - [CORES_BY_USER]');
      const coresByUserResult: Core[] = await fetchAxiosNoCache<null, Core[]>(
        'GET',
        URL + 'cores/user/',
        token,
        null
      );
      logger.debug('CORES-LOADING ' + JSON.stringify(coresByUserResult));
      setCoresByUserData(coresByUserResult);
      fetchMomentumData(coresByUserResult)
      const destinations: Destinations[] = await fetchAxios<null, Destinations[]>(
        'GET',
        URL + 'destinations/',
        token,
        null,
      );
      setDestination(destinations);
    } catch (error) {
      logger.error('GET-CORES_BY_USER ERROR INFO: ' + JSON.stringify(error));
    }
    finally {
      setActivityIndicator({
        ...activityIndicator,
        cores: false
      })
    }
  };

  const fetchUserProfileData = async () => {
    setActivityIndicator({
      ...activityIndicator,
      perfil: true
    })
    try {
      logger.info('<FETCHING> - [USER_RETRIEVE]');
      const dataUserProfileResult: UserRetrieve = await fetchAxiosNoCache<null, UserRetrieve>(
        'GET',
        URL + 'users/retrieve/',
        token,
        null
      );

      logger.debug('userProfile before to be modificated: ' + JSON.stringify(userProfileLocal));
      logger.debug('Fetching userProfile:' + JSON.stringify(dataUserProfileResult));
    } catch (error: any) {
      logger.error('GET-USER_RETRIEVE ERROR INFO: ' + JSON.stringify(error));
    }
    finally {
      setActivityIndicator({
        ...activityIndicator,
        perfil: false
      })
    }
  }

  const fetchMomentumData = (infoCores: any) => {
    logger.debug('-> UPDATING MOMENTUM & CORES infoCore:', infoCores);
    if (infoCores && infoCores.length > 0) {

      const result = [] as CoreInfo[];
      const resultToLocal = [] as Core[];
      let coresCopy = cloneDeep(coresLocal.value);
      infoCores.forEach((element: any) => {
        logger.debug("line 494 Core.index element: ", element, "element.core_string: ", element.core_string);
        const localElement = localData.value.coreInfo.find(x => x.core_string === element.core_string);
        logger.debug("line 496 Core.index localElement: " + JSON.stringify(localElement));
        result.push({
          core_power: element.core_power,
          core_string: element.core_string,
          enabled: element.enabled,
          lastMorningCheckIn: localElement?.lastMorningCheckIn ?? null,
          morningCheckInHabits: localElement?.morningCheckInHabits ?? [],
          lastNightCheckIn: localElement?.lastNightCheckIn ?? null,
          nightCheckInScore: localElement?.nightCheckInScore ?? null,
          openCheckin: localElement?.openCheckin ?? false,
        } as CoreInfo);
        logger.debug('line 507 Core.index result: ' + JSON.stringify(result));
        let theOne = coresCopy ? coresCopy.find(x => x.core_string === element.core_string) : null;
        logger.debug("line 516 Core.index theOne: ", JSON.stringify(theOne));

        if (coresCopy) {
          resultToLocal.push({
            ...theOne,
            core_power: element.core_power,
            enabled: element.enabled,
          } as Core);
        }
      });
      setAtomManual(setCoresData, resultToLocal);
      logger.debug('line 520 Core.index resultToLocal: ' + JSON.stringify(resultToLocal));

      setLocalData({
        init: true,
        value: {
          ...localData.value,
          coreInfo: result
        },
      });

    }
  }

  const fetchAndUpdateMomentumData = async () => {
    logger.debug('-> fetchAndUpdateMomentumData');
    await fetchCoresByUser();
    await fetchUserProfileData();
  }

  useEffect(() => {
    logger.debug('line 540 Core.index seventh useEffect <MOUNT> |SCREEN| - CORES> ', checkInMorningForce);
    if (!checkInMorningForce) setIndicatorSetting(false)
    fetchAndUpdateMomentumData();
  }, []);

  const coreIsAvailable = userProfileLocal.value?.user_profile.cores_available && userProfileLocal.value?.user_profile.cores_active
    ?
    userProfileLocal.value?.user_profile.cores_available > userProfileLocal.value?.user_profile.cores_active
    : false;
    logger.debug("line Core.index coreIsAvailable: ", coreIsAvailable);

  const onClickOkLaunch = () => {
    logger.debug("line 551 Core.index onClickOkLaunch")
    setOpenRocke(false)
    setLaunchVideoVisible(false);
    setScreenPlanetVisible(true)
    setTimeout(() => {
      setScreenPlanetVisible(false)
      setModalCheckIsVisible(true);
    }, 3600);
  }

  const enableAvailables =
    localData.value.morningCheckInStarted &&
    localData.value.lastMorningCheckInCompleted == null &&
    localData.value.currentCheckin === 'morning' &&
    coreIsAvailable;

  const renderCores = () => {
    logger.debug('line 568 Core.index renderCores coresLocal: ', coresLocal.value, "\nlocalData: ", localData.value);
    // TODO: Verify.
    if (
      coresLocal.value &&
      localData.value != null &&
      localData.value.coreInfo != null
    ) {
      const orderedCores = [
        // Order to show in dashboard
        localData.value?.coreInfo[1],
        localData.value?.coreInfo[4],
        localData.value?.coreInfo[3],
        localData.value?.coreInfo[0],
        localData.value?.coreInfo[2],
      ]
      const [PHYSICAL, MINDSET, CAREER, RELATIONSHIPS, EMOTIONAL] = coresLocal.value
      logger.debug('line 584 Core.index orderedCores: ',JSON.stringify(orderedCores));
      return orderedCores.length === 5 && orderedCores.map((item: any) => {

        let dbCore = coresLocal.value.find(x => x.core_string == item.core_string);
        item = {
          ...item,
          enabled: dbCore?.enabled === true || localData.value.coreInfo.find(x => x.core_string === item.core_string)?.enabled === true,
        }
        const onPressAction = () => {
          if (!onBoardingMode) {
            item.enabled === true
              ?
              navigate('CoreStackScreen', {
                screen: 'CheckHabits',
                params: {
                  core: item,
                  habits: item.morningCheckInHabits,
                  score: item.nightCheckInScore,
                },
              })
              : navigate('CoreStackScreen', {
                screen: 'InitHabits',
                params: {
                  core: item,
                },
              });
          } else {
            navigateToNextStep ?
              navigateToNextStep(item) : () => { }
          }
        }
        switch (item.core_string) {
          case 'MINDSET':
            return (
              <>
                {(onBoardingMode && isLastTab) &&
                  <ArrowsIndicator
                    containerStyle={styles.arrowIndicatorPosition}
                    withoutHighlight={true} />
                }
                <IndividualCore
                  onPressAction={onPressAction}
                  item={item}
                  imageSource={require('../../../assets/images/cores/mindset_on.png')}
                  maskSource={require('../../../assets/images/cores/mindset_mask.png')}
                  liquidSource={require('../../../assets/animations/cores/red_liquid.json')}
                  styleTouchable={[styles.placementCoreMindsetImage]}
                  liquidFillPercentage={(item.core_power / 2) + 48}
                  isCentered={true}
                  readonly={!isCoreStep && onBoardingMode}
                />
              </>
            )

          case 'EMOTIONAL_HEALTH':
            return (
              <IndividualCore
                onPressAction={onPressAction}
                item={item}
                imageSource={require('../../../assets/images/cores/emotional_on.png')}
                maskSource={require('../../../assets/images/cores/emotional_mask.png')}
                liquidSource={require('../../../assets/animations/cores/blue_liquid.json')}
                styleTouchable={[styles.placementCoreEmotionalImage]}
                liquidFillPercentage={(item.core_power / 2) + item.core_power === 0 ? 30 : 45}
                readonly={onBoardingMode && (isLastTab || !isCoreStep)}
              />
            )

          case 'RELATIONSHIPS':
            return (
              <IndividualCore
                onPressAction={onPressAction}
                item={item}
                imageSource={require('../../../assets/images/cores/relationship_on.png')}
                maskSource={require('../../../assets/images/cores/relationship_mask.png')}
                liquidSource={require('../../../assets/animations/cores/pink_liquid.json')}
                styleTouchable={[styles.placementCoreRelationshipImage]}
                liquidFillPercentage={(item.core_power / 2) + item.core_power === 0 ? 30 : 45 /*( RELATIONSHIPS.core_power / 2) + RELATIONSHIPS.core_power === 0 ? 30 : 45*/}
                readonly={onBoardingMode && (isLastTab || !isCoreStep)}
              />
            )

          case 'PHYSICAL_HEALTH':
            return (
              <IndividualCore
                onPressAction={onPressAction}
                item={item}
                imageSource={require('../../../assets/images/cores/physical_on.png')}
                maskSource={require('../../../assets/images/cores/physical_mask.png')}
                liquidSource={require('../../../assets/animations/cores/purple_liquid.json')}
                styleTouchable={[styles.placementCorePhysicalImage]}
                liquidFillPercentage={(item.core_power / 2) + item.core_power === 0 ? 30 : 45}
                readonly={onBoardingMode && (isLastTab || !isCoreStep)}
                isBottom={true}
              />
            )

          case 'CAREER_FINANCES':
            return (
              <IndividualCore
                onPressAction={onPressAction}
                item={item}
                imageSource={require('../../../assets/images/cores/career_on.png')}
                maskSource={require('../../../assets/images/cores/career_mask.png')}
                liquidSource={require('../../../assets/animations/cores/green_liquid.json')}
                styleTouchable={[styles.placementCoreCareerImage]}
                liquidFillPercentage={(item.core_power / 2) + item.core_power === 0 ? 30 : 45}
                readonly={onBoardingMode && (isLastTab || !isCoreStep)}
                isBottom={true}
              />
            )

          default:
            return null
        }
      })
    }
  }

  const completedQuiz = async () => {
    try {

      logger.info('<PATCH> - [USER_RETRIEVE]');
      // TODO: Check tiping here
      const userRetreiveUpdated = await fetchAxios(
        'PATCH',
        URL + 'users/retrieve/',
        token,
        {
          "user_profile": {
            "quiz": true
          }
        }
      );

      logger.debug("line 718 Core.index completeQuizUserRetreiveUpdated: ", userRetreiveUpdated)
      setAtomAxios(setUserProfileLocal, {
        method: 'GET',
        url: URL + 'users/retrieve/',
        token: storage.value.token
      })

    } catch (error) {
      logger.error('Core.index completedQuiz error: ' + JSON.stringify(error));
    }
    logger.info('-> QUIZ COMPELTED');
  }

  const onPress = () => {
    logger.debug("line 738 Core.index onPress")
    setSeconDays(false)
    setLocalData(
      {
        ...localData,
        value: {
          ...localData.value,
          secondDaysJourney: true
        },
      });
    navigate('CockpitStackScreen')
  }

  useEffect(() => {
    logger.debug("line 752 Core.index eigth useEffect userProfileLocal: ", userProfileLocal.value)
    const doneFirstQuiz = userProfileLocal.value?.user_profile.quiz ?? true;
    const coresLeft = (userProfileLocal.value?.user_profile.cores_available ?? 0) + 1 > (userProfileLocal.value?.user_profile.cores_active ?? 0);
    logger.debug('line 754 Core.index ACTIVE CORES: ', enableAvailable, "doneFirstQuiz: ", doneFirstQuiz, "coreLeft: ", coresLeft);
    if (enableAvailable && !doneFirstQuiz && coresLeft) {
      logger.info('-> SHOWING MODAL - FIRST QUIZ (SECUENCE OF MODALS)');
      setQuizModalVisible(true);
    }
    logger.debug("line 981 Core.index userProfileLocaData:",userProfileLocal.value?.user_profile.quiz, "enableAvailables: ", enableAvailables);
    if (userProfileLocal.value?.user_profile.quiz && enableAvailables) setCoresModalVisible(true)
  }, [userProfileLocal]);

  const rocketColorAssetObject = getImprovementsColors(rocketComposition?.color ?? '', true);
  const rocketWingsAssetObject = getImprovementsWings(rocketComposition?.wings ?? '', true);
  const rocketTurbinesAssetObject = getImprovementsTurbines(rocketComposition?.turbines ?? '', true);
  const flamePower = getPowerFlameAnimation(3); // Put the bonus correct.

  return (
    <>
      {
        <ActivityIndicator 
        isVisible={activityIndicator.cores || activityIndicator.perfil || activityIndicator.destination || activityIndicator.morning || activityIndicator.forceMorning} />
      }
      {
        secondDays
        &&
        <ModalGoCockpit
          onPress={() => onPress()}
          isVisible={secondDays}
          touchableOpacityContainerButtonStyle={[
            styles.modalQuestOpacityContainerButton,
            {
              borderColor: palette.BUTTON_BORDER,
              backgroundColor: palette.SUCCESS,
            },
          ]}
          textTitleButtonStyle={[
            styles.modalQuestTextDoneButton,
            fonts.BUTTON_MEDIUM,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW,
            },
          ]}
        />
      }
      {
        isLaunchVideoVisible &&
        <VideoScreen
          isVisible={isLaunchVideoVisible}
          onClickOk={onClickOkLaunch}
          launchOrLanding='launch'
          destiny={userProfileLocal.value?.user_profile.actual_destination}
        />
      }

      {
        isScreenPlanetVisible &&
        <ModalPlanetLifetime
          isVisible={isScreenPlanetVisible}
          action='launch'
          isPositionActual={userProfileLocal.value?.user_profile.actual_destination === 'Endless' ? 'Eris' : isPositionActual.destination} />
      }

      {
        isModalCheckIsVisible &&
        <ModalJourney
          onClickOk={onClickOkCheckIn}
          touchableOpacityContainerButtonStyle={[
            styles.modalCheckInOpacityContainerButton,
            {
              borderColor: palette.BUTTON_BORDER,
              backgroundColor: palette.SUCCESS,
            },
          ]}
          textTitleButtonStyle={[
            styles.modalCheckInTextDoneButton,
            fonts.BUTTON_MEDIUM,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW,
            },
          ]}
          textMainHeader={strings.MODAL_CHECK_IN_MAIN_HEADER}
          textContentHeader={strings.MODAL_CHECK_IN_CONTENT_HEADER}
          textContentInfo={strings.MODAL_CHECK_IN_CONTENT_INFO}
          isVisible={isModalCheckIsVisible}
        />
      }
      {
        isCoresModalVisible &&
        <ModalGoals
          textTitle={strings.MODAL_GOALS_TITLE}
          textDescription={strings.MODAL_GOALS_DESCRIPTION}
          textTitleStyle={[fonts.MODAL_TITLE, { color: palette.TEXT_PRIMARY }]}
          touchableOpacityButtonImage={
            <Image
              style={styles.imageButtonModal}
              source={require('../../../assets/images/shared/button_confirm.png')}
              resizeMode={'cover'}
            />
          }
          touchableOpacityButtonStyle={{}}
          touchableOpacityButtonOnPress={() => setCoresModalVisible(false)}
          isVisible={isCoresModalVisible}
        />
      }
      {(isQuizModalVisible && !isModalCheckIsVisible && enableAvailables) &&
        <FirstQuiz
          quizTitleStyle={[fonts.QUIZ_TITLE, { color: palette.TEXT_PRIMARY }]}
          quizSubtitleStyle={[
            fonts.QUIZ_SUBTITLE,
            { color: palette.TEXT_PRIMARY },
          ]}
          quizQuestionsHeaderStyle={[
            fonts.QUIZ_TITLE,
            { color: palette.TEXT_TERTIARY },
          ]}
          quizQuestionAnswerStyle={[
            fonts.QUIZ_QUESTION_ANSWER,
            { color: palette.TEXT_PRIMARY },
          ]}
          quizQuestionDescriptionStyle={[
            fonts.QUIZ_QUESTION_DESCRIPTION,
            { color: palette.TEXT_PRIMARY },
          ]}
          quizScoreBigStyle={[
            fonts.QUIZ_SCORE_BIG,
            { color: palette.TEXT_TERTIARY },
          ]}
          quizScoreSmallStyle={[
            fonts.QUIZ_SCORE_SMALL,
            { color: palette.TEXT_TERTIARY },
          ]}
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
          total={[
            fonts.ACCORDION_TITLE,
            palette.TEXT_PRIMARY,
            palette.TEXT_SECONDARY,
            palette.LIFETIME_PLANET,
          ]}
          quiz={listQuizAllCore}
          isVisible={isQuizModalVisible}
          setQuizModalVisible={setQuizModalVisible}
          completedQuiz={completedQuiz}
        />
      }
      {
        isModalQuestVisible &&
        <ModalQuests
          daysNumberStyle={[
            fonts.QUEST_DAYS_NUMBER,
            { color: palette.TEXT_TERTIARY },
          ]}
          daysDescriptionStyle={[
            fonts.QUEST_DAYS_DESCRIPTION,
            { color: palette.TEXT_TERTIARY },
          ]}
          questDescriptionStyle={[
            fonts.QUEST_DESCRIPTION,
            { color: palette.TEXT_PRIMARY },
          ]}
          onClickOk={() => setModalQuestVisible(false)}
          touchableOpacityContainerButtonStyle={[
            styles.modalQuestOpacityContainerButton,
            {
              borderColor: palette.BUTTON_BORDER,
              backgroundColor: palette.SUCCESS,
            },
          ]}
          textTitleButtonStyle={[
            styles.modalQuestTextDoneButton,
            fonts.BUTTON_MEDIUM,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW,
            },
          ]}
          isVisible={isModalQuestVisible}
          days={days}
          currentCheckIn={'morning'}
          questOrMission={questOrMission}
          quest={quest}
          missions={missions}

        />
      }
      <View
        style={styles.viewContainer}
      >
        {
          !onBoardingMode &&
          <>
            <Video
              source={require("../../../assets/videos/copy_video/SpaceBG2.mp4")}
              style={[styles.viewContainer]}
              muted={true}
              repeat={true}
              resizeMode={"cover"}
              rate={1.0}
              ignoreSilentSwitch={"obey"}
            />

            <TouchableOpacity style={styles.imageBackgroundPointsScreen2}
              onPress={() => navigate('ConfigurationStackScreen', {
                screen: 'Profile',
              })}>
              <ImageBackground
                style={styles.imageBackgroundPointsScreen}
                source={require('../../../assets/images/cores/points_screen.png')}
                resizeMode={'contain'}>
                <View style={styles.viewCoins}>
                  <View style={styles.viewCoinsImage}>
                    <Image
                      style={styles.imageCoins}
                      source={require('../../../assets/images/cores/coin.png')}
                      resizeMode={'contain'}
                    />
                  </View>

                  <View style={styles.viewCoinsText}>
                    <Text
                      style={[
                        fonts.DASHBOARD_COINS,
                        { color: palette.DASHBOARD_COINS_PLANET, textAlign: 'center' },
                      ]}>
                      {userProfileLocal.value?.user_profile?.credits ?? 0}
                    </Text>
                  </View>
                </View>

                <View style={styles.viewPlanet}>
                  <View style={styles.viewPlanetImage}>
                    <Image
                      style={styles.imagePlanet}
                      source={require('../../../assets/images/cores/planet.png')}
                      resizeMode={'contain'}
                    />
                  </View>

                  <View style={styles.viewMomentumScoreAmountText}>
                    <Text
                      style={[
                        styles.textMomentumScoreAmount,
                        fonts.DASHBOARD_SCORE_AMOUNT,
                        {
                          color: palette.DASHBOARD_COINS_PLANET,
                          textShadowColor: palette.TEXT_QUATERNARY_SHADOW,
                          fontSize: userProfileLocal.value?.user_profile.actual_destination?.length && userProfileLocal.value?.user_profile.actual_destination?.length > 10 ? vw(2) : vw(4),
                          width: userProfileLocal.value?.user_profile.actual_destination?.length && userProfileLocal.value?.user_profile.actual_destination?.length > 10 ? '90%' : '100%',
                        },
                      ]}>
                      {userProfileLocal.value?.user_profile?.actual_destination}
                    </Text>
                  </View>
                </View>

                <View style={styles.containerMomentumScore}>
                  <Text
                    style={[
                      fonts.SETTINGS_CARD_TITLE,
                      {
                        color: palette.TEXT_PRIMARY,
                        textShadowColor: palette.TEXT_QUATERNARY_SHADOW,
                      },
                      styles.textMomentumScore,
                    ]}
                  >
                    {strings.MOMENTUM_SCORE}
                  </Text>
                </View>

                <View style={styles.containerMomentumScore}>
                  <Text
                    style={[
                      fonts.DASHBOARD_SCORE_AMOUNT,
                      {
                        color: palette.TEXT_PRIMARY_SHADOW,
                        textShadowColor: palette.TEXT_QUATERNARY_SHADOW,
                      },
                      styles.textMomentumScoreTotal,
                    ]}
                  >
                    {'%' + Math.round(Number(userProfileLocal.value?.user_profile.momentum))}
                  </Text>
                </View>
              </ImageBackground>
            </TouchableOpacity>
          </>
        }

        {
          rocketComposition &&
          <Animated.View
            style={[
              styles.viewRocket,
              {
                transform: [
                  {
                    translateY: rocketPosY,
                  },
                ],
              },
            ]}>
            <View style={[styles.rocketContainer]}>
              <View style={styles.imageWingsContainer}>
                <DuoTone
                  firstColor={rocketColorAssetObject.color}
                  secondColor={"#000"}
                  style={[styles.imageWing, styles.imageWingLeft]}>
                  <Image
                    style={[styles.imageWing, styles.imageWingLeft]}
                    source={rocketWingsAssetObject.image}
                    resizeMode={'contain'}
                  />
                </DuoTone>
                <DuoTone
                  firstColor={rocketColorAssetObject.color}
                  secondColor={"#000"}// Add another color is better else add a shadow up for 3D effect
                  style={[styles.imageWing, styles.imageWingRight]}>
                  <Image
                    style={[styles.imageWing]}
                    source={rocketWingsAssetObject.image}
                    resizeMode={'contain'}
                  />
                </DuoTone>
              </View>

              <ImageBackground
                style={[styles.imageBackgroundRocket]}
                source={rocketColorAssetObject.image}
                resizeMode={'contain'}>
                <SafeAreaView style={[styles.safeAreaViewRocket]}>
                  <View style={styles.handleContainer}>
                    {
                      (onBoardingMode && cockpit) && <ArrowsIndicator highlightStyle={styles.highlightStyle} containerStyle={styles.arrowIndicatorCockpitPosition} />
                    }
                    <TouchableOpacity
                      style={styles.touchableOpacityHandleImage}
                      disabled={onBoardingMode && isCoreStep || checkInMorningForce}
                      onPress={() => cockpit ? navigateToNextStep() : navigate('CockpitStackScreen')}>
                      <Image
                        style={styles.imageHandle}
                        source={require('../../../assets/images/cores/handle_icon.png')}
                        resizeMode={'contain'}
                      />
                    </TouchableOpacity>
                    <View style={styles.handleContainerInferior}>
                      <TouchableOpacity
                        style={styles.imageStorage}
                        disabled={onBoardingMode}
                        onPress={() => {
                          navigate('ConfigurationStackScreen', {
                            screen: 'Storage',
                          })
                        }}>
                        <Image
                          style={styles.imageStorage}
                          source={require('../../../assets/images/cores/storage_icon.png')}
                          resizeMode={'contain'}
                        />
                      </TouchableOpacity>
                      {
                        (indicatorSetting) && <ArrowsIndicator highlightStyle={styles.highlightStyleSetting} containerStyle={styles.arrowIndicatorCockpitPositionSetting} />
                      }
                      <TouchableOpacity
                        style={styles.imageSettings}
                        disabled={onBoardingMode && !checkInMorningForce}
                        onPress={() => {
                          checkInMorningForce
                            ?
                            navigateToNextStep()
                            :
                            navigate('ConfigurationStackScreen', {
                              screen: 'Settings',
                            })
                        }}>
                        <Image
                          style={styles.imageSettings}
                          source={require('../../../assets/images/cores/settings_icon.png')}
                          resizeMode={'contain'}
                        />
                      </TouchableOpacity>
                    </View>
                  </View>
                  <View style={styles.coresContainer}>{renderCores()}</View>
                </SafeAreaView>

              </ImageBackground>
              <ImageBackground
                style={[styles.turbines]}
                source={rocketTurbinesAssetObject.image}
                resizeMode={'contain'} >
                {
                  rocketTurbinesAssetObject.flames == 1
                    ?
                    <>
                      <ImageBackground source={typeFlame(Math.round(userProfileLocal.value?.user_profile.momentum ?? 0)) /*require('../../../assets/images/cores/Truster_High_looped.gif') { uri: 'https://acegif.com/wp-content/gifs/fire-84.gif' }*/}
                        resizeMode={'contain'}
                        style={styles.newFlamaCohete} />
                    </>
                    : null
                }
                {
                  rocketTurbinesAssetObject.flames == 2
                    ?
                    <>
                      <View style={styles.imageFlameDobleCentered}>
                        <View style={styles.containerFlamaLast}>
                          <ImageBackground source={typeFlame(Math.round(userProfileLocal.value?.user_profile.momentum ?? 0))}
                            resizeMode={'contain'}
                            style={styles.flamaLeftLast} />
                          <ImageBackground source={typeFlame(Math.round(userProfileLocal.value?.user_profile.momentum ?? 0))}
                            resizeMode={'contain'}
                            style={styles.flamaRightLast} />
                        </View>
                      </View>
                    </>
                    : null
                }
                {
                  rocketTurbinesAssetObject.flames == 3 ?
                    <>
                      <View style={[styles.imageFlameDuothird]}>
                        <ImageBackground source={typeFlame(Math.round(userProfileLocal.value?.user_profile.momentum ?? 0))}
                          resizeMode={'contain'}
                          style={styles.flamaLeft} />
                        <ImageBackground source={typeFlame(Math.round(userProfileLocal.value?.user_profile.momentum ?? 0))}
                          resizeMode={'contain'}
                          style={styles.flamaRight} />
                        <ImageBackground source={typeFlame(Math.round(userProfileLocal.value?.user_profile.momentum ?? 0))}
                          resizeMode={'contain'}
                          style={styles.flamaCenter} />
                      </View>
                    </>
                    : null}
                {
                  rocketTurbinesAssetObject.flames == 5 ?
                    <>
                      <View style={styles.imageFlameDuoCentered}>
                        <View style={styles.containerFlamaLast}>
                          <ImageBackground source={typeFlame(Math.round(userProfileLocal.value?.user_profile.momentum ?? 0))}
                            resizeMode={'contain'}
                            style={styles.flamaLastLeft} />
                          <ImageBackground source={typeFlame(Math.round(userProfileLocal.value?.user_profile.momentum ?? 0))}
                            resizeMode={'contain'}
                            style={styles.flamaLastRight} />
                        </View>
                        <View style={styles.containerFlamaFive}>
                          <ImageBackground source={typeFlame(Math.round(userProfileLocal.value?.user_profile.momentum ?? 0))}
                            resizeMode={'contain'}
                            style={styles.flamaLeftMiddle} />
                          <ImageBackground source={typeFlame(Math.round(userProfileLocal.value?.user_profile.momentum ?? 0))}
                            resizeMode={'contain'}
                            style={styles.flamaRightMiddle} />
                        </View>
                        <ImageBackground source={typeFlame(Math.round(userProfileLocal.value?.user_profile.momentum ?? 0))}
                          resizeMode={'contain'}
                          style={styles.flamaCenterMiddle} />
                      </View>
                    </>
                    : null
                }
              </ImageBackground>
            </View>
          </Animated.View>
        }
      </View >
    </>
  )
}
