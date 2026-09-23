import React, { useEffect } from 'react'
import RNBootSplash from 'react-native-bootsplash'
import { useRecoilState } from 'recoil'
import { setAtomAxios } from '../../helpers/recoil'
import { URL } from '../../helpers/api'
import { CoreInfo, Improvement } from '../../typescript/main'

import {
  coresAtom,
  storageAtom,
  userInfoAtom,
  mantraAtom,
  inspirationsAtom,
  localDataAtom,
  dailyCheckAtom,
  userRetrieveAtom,
  userImprovementAtom,
} from '../../recoil/atoms'
import { logger } from '../../helpers/logger'
import { updateImprovementsState } from '../configuration/Improvements/utilities'

export default ({ children }: any) => {
  const [storage, setStorage] = useRecoilState(storageAtom);
  const [userInfo, setUserInfo] = useRecoilState(userInfoAtom);
  const [localData, setLocalData] = useRecoilState(localDataAtom);
  const [cores, setCores] = useRecoilState(coresAtom);
  const [mantra, setMantra] = useRecoilState(mantraAtom);
  const [inspirations, setInspirations] = useRecoilState(inspirationsAtom);
  const [dailyCheck, setDailyCheck] = useRecoilState(dailyCheckAtom);
  const [userRetrieve, setUserRetrieve] = useRecoilState(userRetrieveAtom);
  const [userImprovement, setUserImprovement] = useRecoilState(userImprovementAtom)

  logger.info("[<Initializer>]")
  useEffect(() => {
    (async () => {
      logger.debug("first useEffect shared.initialiazer stoage.init: ", storage.init, "storage.value.token: ", storage.value.token)
      if (storage.init && storage.value.token) {
        try {
          logger.info('<FETCHING> - [ALL INITIALIZER DATA]');

          // set last login
          setUserInfo({
            init: true,
            value: {
              lastLogin: Date.now(),
              showAllCores: userInfo.value.showAllCores,
            },
          })

          setAtomAxios(setCores, {
            method: 'GET',
            url: URL + 'cores/user/',
            token: storage.value.token
          })

          // get mantra
          setAtomAxios(setMantra, {
            method: 'GET',
            url: URL + 'users/mantra/',
            token: storage.value.token
          })

          // get inspirations
          setAtomAxios(setInspirations, {
            method: 'GET',
            url: URL + 'inspirations/',
            token: storage.value.token
          })

          // get UserProfle
          setAtomAxios(setUserRetrieve, {
            method: 'GET',
            url: URL + 'users/retrieve/',
            token: storage.value.token
          })

          setAtomAxios(setUserImprovement, {
            method: 'GET',
            url: URL + 'improvements/user/',
            token: storage.value.token
          })
          logger.debug("result userInfo: ", userInfo.value, "core: ", cores.value, "mantra: ", mantra.value, "inspirations: ", inspirations.value, "userRetreive: ", userRetrieve.value, "\nuserImprovement: ", userImprovement.value)
        } catch (error) {
          logger.error('**ERROR** [GET-INITIALIZER PROCESS]');
          logger.error('[ERROR INFO]: ' + JSON.stringify(error));
          setStorage({
            ...storage,
            value: { ...storage.value, token: '' },
          })

          setTimeout(() => {
            RNBootSplash.hide({ fade: true })
          }, 1000)
        }
      }
    })()

  }, [
    setCores,
    setInspirations,
    setMantra,
    setStorage,
    setUserInfo,
    storage,
    setUserRetrieve,
  ])

  useEffect(() => {
    (async () => {
      if (
        storage.init &&
        storage.value.token &&
        cores.value &&
        mantra.value &&
        inspirations.value &&
        userRetrieve.value &&
        userImprovement.value
      ) {
     logger.debug("Initializer second useEffect ")
        const coreInfo: CoreInfo[] = [];
        cores.value?.map((item: any) => {
          const coreInfoIndiv = localData.value.coreInfo.find((x) => x.core_string === item.core_string);
          return coreInfo.push({
            core_string: item.core_string,
            core_power: item.core_power,
            enabled: item.enabled || (coreInfoIndiv?.enabled ?? false),
            lastMorningCheckIn: coreInfoIndiv?.lastMorningCheckIn ?? null,
            morningCheckInHabits: coreInfoIndiv?.morningCheckInHabits ?? [],
            lastNightCheckIn: coreInfoIndiv?.lastNightCheckIn ?? null,
            nightCheckInScore: coreInfoIndiv?.nightCheckInScore ?? null,
            openCheckin: coreInfoIndiv?.openCheckin ?? false,
          })
        });

        const improvementEquipped: Improvement[] = updateImprovementsState(userImprovement.value);
        logger.debug("line Initializer improvementEquipped: ", improvementEquipped)

        setLocalData({
          init: true,
          value: { 
            ...localData.value, 
            coreInfo: coreInfo,
            improvements: improvementEquipped
          },
        });
        logger.debug("initializer localData: ", localData.value)

        setTimeout(() => {
          RNBootSplash.hide({ fade: true })
        }, 1000);
      }
    })()
  }, [
    storage.init,
    storage.value.token,
    cores.value,
    mantra.value,
    inspirations.value,
    userRetrieve.value,
  ])

  useEffect(() => {
    if (storage.init && userInfo.value.lastLogin === 0) {
      setTimeout(() => {
        RNBootSplash.hide({ fade: true })
      }, 1000)
    }
  }, [storage.init, userInfo.value.lastLogin])

  return <>{children}</>
}
