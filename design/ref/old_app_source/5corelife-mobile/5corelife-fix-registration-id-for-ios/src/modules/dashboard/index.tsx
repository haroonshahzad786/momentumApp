import React, { useCallback, useEffect } from 'react'
import { createStackNavigator } from '@react-navigation/stack'

import Cores from './Cores'
import Journey from './Journey'
import Lifetime from './Lifetime'
import NightCheckIn from './NightCheckIn'
import {
  userAtom,
  userInfoAtom,
  userRetrieveAtom,
  localDataAtom,
  coresAtom,
  storageAtom,
  dailyCheckAtom,
  localDataDefault,
} from '../../recoil/atoms'
import { useRecoilValue, useRecoilState } from 'recoil'
import moment from 'moment'
import { URL } from '../../helpers/api'
import { cloneDeep } from 'lodash'
import { fetchAxiosMultiple } from '../../helpers/axios'
import { logger } from '../../helpers/logger'

const DashboardStack = createStackNavigator()

export function DashboardStackScreen() {
  logger.info("[<DashboardStackScreen>]")
  const user = useRecoilValue(userAtom);
  const userInfo = useRecoilValue(userInfoAtom);
  const yesterday = Date.now() - 86400000;
  const [storage, setStorage] = useRecoilState(storageAtom);
  const settings = useRecoilValue(userRetrieveAtom);

  const [localData, setLocalData] = useRecoilState(localDataAtom);
  const [cores, setCores] = useRecoilState(coresAtom);
  const [dailyChecks, setDailyChecks] = useRecoilState(dailyCheckAtom);

  const {
    value: { token, onboarding_pendingpost },
  } = useRecoilValue(storageAtom);

  useEffect(() => {
    logger.info('<MOUNT> DASHBOARD INDEX');
    if (onboarding_pendingpost)
      logger.debug('[ONBOARDING_PROCESS] - Onboarding finished, onboarding_pendingpost: ', onboarding_pendingpost)
  }, []);

  const checkDaily = useCallback(async () => {
    if (cores.value == null) return;
    logger.info('<FETCHING> - [GET-HABIT_STATUS_BY_CORE]');

    try {
      let dailys = await fetchAxiosMultiple(
        cores.value!.map((item) => {
          if (item.enabled) {
            return {
              method: 'GET',
              url: URL + 'habits/get-status/?core=' + item.core_string,
              token,
            }
          }
        })
      );

      setDailyChecks({
        init: true,
        isLoading: false,
        request: null,
        error: null,
        value: dailys,
      });
      return dailys;

    } catch (error) {
      logger.error('**ERROR** [GET-HABIT_STATUS_BY_CORE]: ' + JSON.stringify(error));
    }
  }, [cores.value, setDailyChecks, token])

  const isCheckInTime = useCallback(async () => {
    logger.debug('-> CHEKING TIME - Check day moment');
    if (
      settings.value == null ||
      settings.value?.user_profile.morning_check_time == null ||
      settings.value?.user_profile.night_check_time == null
    )
      return;

    var morningCheck = moment(settings.value?.user_profile.morning_check_time, 'hh:mm:ss');

    var nightCheck = moment(settings.value?.user_profile.night_check_time, 'hh:mm:ss');

    var isMorning = moment().isBetween(
      morningCheck.clone().add(-2, 'hours'),
      morningCheck.clone().add(2, 'hours'),
      undefined,
      '[]',
    )

    var isNight = moment().isBetween(
      nightCheck.clone().add(-2, 'hours'),
      nightCheck.clone().add(2, 'hours'),
      undefined,
      '[]',
    )

    if (isMorning && !isNight)
      logger.debug("-> MOMENT OF DAY -To do MORNINGCHECK");
    else if (!isMorning && isNight)
      logger.debug("-> MOMENT OF DAY - To do NIGHTCHECK");
    else if (!isMorning && !isNight)
      logger.debug("-> MOMENT OF DAY - Any special moment");
    else {
      logger.debug('-> MOMENT OF DAY - **Inconsistency** -> IsMorning: ' + isMorning, ' IsNight:' + isNight);
    }

    const dailyInfo = await checkDaily();

    let openCheckin = false;
    let openCores: string[] = [];
    let lastMorningCheckInDate = null;
    logger.debug("line 122 dashboard.index dailyInfo: ", dailyInfo)
    if (dailyInfo != null) {
      for (let index = 0; index < dailyInfo.length; index++) {
        const element = dailyInfo[index];

        if (element.open || onboarding_pendingpost) {
          openCheckin = isMorning || isNight || onboarding_pendingpost;
          logger.debug("-> CHECKING OPEN CORE: " + element.core);
          if (!element.morningcheck && isMorning) {
            logger.debug('-> NO MORNING CHECKED - it should be agregado to check in MORNING');
            openCores.push(element.core);
          } else if (element.morningcheck) {
            lastMorningCheckInDate = !element.created ? element.created : Date.now();

            if (isNight && !element.nightCheck) {
              logger.debug('-> MORNING CHECKED + NO NIGHT CHECKED - it should be added to check in NIGHT');
              openCores.push(element.core);
            } else
              logger.debug('-> MORNING CHECKED - Its not moment to add this core to checking');
          }
        } else {
          logger.debug('-> MORNING & NIGHT CHECKED [CORE: ' + element.core + ']');
        }
      }
    }

    const coresCopy = cloneDeep(localData.value.coreInfo)
    for (let index = 0; index < coresCopy.length; index++) {
      const element = coresCopy[index];
      if (openCores.includes(element.core_string)) {
        coresCopy[index].openCheckin = true;
      }
    }
    setLocalData({
      ...localData,
      value: {
        ...localData.value,
        coreInfo: coresCopy,
        currentCheckin: isMorning ? 'morning' : isNight ? 'night' : null,
        openCheckin: openCheckin,
        lastMorningCheckInCompleted: lastMorningCheckInDate ?? localData.value.lastMorningCheckInCompleted,
      },
    })
  }, [checkDaily, setLocalData, settings.value])

  useEffect(() => {
    isCheckInTime();
  }, [settings, isCheckInTime])

  useEffect(() => {
    if (localData.init && localData.value.lastStart != null) {
      const lastMorningCheckIn = moment(localData.value.lastStart);
      const now = moment();
      if (!lastMorningCheckIn.isSame(now, 'day')) {
        logger.debug('-> NEW DAY - Resetting checkin variables');
        setLocalData({
          ...localData,
          value: {
            ...localData.value,
            lastMorningCheckInCompleted:
              localDataDefault.lastMorningCheckInCompleted,
            lastNightCheckInCompleted:
              localDataDefault.lastNightCheckInCompleted,
            coreInfo: localDataDefault.coreInfo,
            morningCheckInStarted: localDataDefault.morningCheckInStarted,
            nightCheckInStarted: localDataDefault.nightCheckInStarted,
            lastStart: new Date(),
          },
        })
      } else {
        logger.debug('-> SAME DAY - Updating variable lastStart');
        setLocalData({
          ...localData,
          value: {
            ...localData.value,
            lastStart: new Date(),
          },
        })
      }
    } else {
      logger.debug('-> SAME DAY - Setting variable lastStart');
      setLocalData({
        ...localData,
        value: {
          ...localData.value,
          lastStart: new Date(),
        },
      })
    }
  }, [localData.init, setLocalData]);

  return (
    <DashboardStack.Navigator
      initialRouteName={
        onboarding_pendingpost ? 'Cores' : 'Lifetime'
      }
      screenOptions={() => ({
        stackAnimation: 'default',
        headerShown: false,
      })}>
      <DashboardStack.Screen name='Lifetime' component={Lifetime} />
      <DashboardStack.Screen name='Journey' component={Journey} />
      <DashboardStack.Screen name='Cores' component={Cores} />
      <DashboardStack.Screen name='NightCheckIn' component={NightCheckIn} />
    </DashboardStack.Navigator>
  )
}
