import React, { useEffect } from 'react'
import {
  Image,
  ImageBackground,
  SafeAreaView,
} from 'react-native'
import { useRecoilState, useRecoilValue } from 'recoil'

import { URL } from '../../../helpers/api'
import {
  localDataAtom,
  storageAtom,
  userRetrieveAtom,
} from '../../../recoil/atoms'
import AdviseMessage from '../AdviseMessage'
import ButtonNextStep from '../ButtonNextStep'
import props from './props'
import strings from './strings'
import styles from './styles'
import { fetchAxiosNoCache } from '../../../helpers/axios'
import { HabitsTypes, Improvement, ImprovementsUser } from '../../../typescript/main'
import { logger } from '../../../helpers/logger'
import { updateImprovementsState } from '../../configuration/Improvements/utilities'

export default ({ navigation: { navigate, replace } }: props) => {
  logger.info("[<StepOne>]")
  const {
    value: { fonts, palette, token },
  } = useRecoilValue(storageAtom)
  const [localState, setLocalState] = useRecoilState(localDataAtom)
  const userRetrieve = useRecoilValue(userRetrieveAtom)

  useEffect(() => {
    logger.info("ONBOARDING FLOW - STEP ONE")
    fetchAndUpdateHabits()
    fetchImprovements();
  }, [
    token,
    localState.value.lastMorningCheckInCompleted,
    userRetrieve.value?.user_profile.onboarding,
  ])

  const fetchAndUpdateHabits = async () => {
    try {
      const habits: HabitsTypes[] = await fetchAxiosNoCache<null, HabitsTypes[]>(
        'GET',
        `${URL}habits/`,
        token,
        null,
      )
      logger.debug("first useEffect habits: ", habits)
      const selectedHabits = habits?.filter((habit) => habit.selected) ?? [];
      logger.debug("selectedHabits: ", selectedHabits, "localState: ", localState.value, "userRetreive: ", userRetrieve.value)
      if (
        selectedHabits.length > 0 &&
        !localState.value.lastMorningCheckInCompleted &&
        !userRetrieve.value?.user_profile.onboarding
      ) {
        selectedHabits.forEach(async (habit) => {
          try {
            await fetchAxiosNoCache(
              'PATCH',
              `${URL}habits/${habit.id}/`,
              token,
              { selected: false },
            )
          } catch (error: any) {
            logger.error('habits.map patch error: ', error.response)
          }
        })
      }
      setLocalState((prevState) => ({
        ...prevState,
        value: {
          ...prevState.value,
          coreInfo: prevState.value.coreInfo.map((info) => ({
            ...info,
            core_power:
              info.core_string === 'EMOTIONAL_HEALTH' ? 10 : info.core_power,
          })),
        },
      }))
      logger.debug("after localState: ", localState.value)
    } catch (error: any) {
      logger.error('onboarding.stepOne error: ', error)
    }
  }

  const fetchImprovements = async () => {
    try {
      const equip: ImprovementsUser[] = await fetchAxiosNoCache<null, ImprovementsUser[]>(
        'GET',
        URL + 'improvements/user/',
        token,
        null
      )
      logger.debug("line Configurations.ImprovementArmors.index equip: ", equip)

      const improvementEquipped: Improvement[] = updateImprovementsState(equip);
      logger.debug("line Configurations.ImprovementArmors.index improvementEquipped: ", improvementEquipped)
      setLocalState({
        ...localState,
        value: {
          ...localState.value,
          improvements: improvementEquipped??[],
        },
      });
    } catch (error: any) {
      logger.error('Configurations.ImprovementArmors.index Error fetchImprovements: ', error);
    }
  };

  return (
    <>
      <ImageBackground
        style={styles.imageBackgroundContainer}
        source={require('../../../assets/images/shared/background_universe.png')}
        resizeMode={'cover'}>
        <Image
          style={styles.imagePlanet}
          source={require('../../../assets/images/journey/origins_destinations/earth.png')}
          resizeMode={'contain'}
        />
        <SafeAreaView style={styles.safeAreaViewContainer}>
          <AdviseMessage
            title={strings.TITLE}
            subtitle={strings.SUBTITLE}
            fontSize={styles.fontSizeFat}
          />
          <ButtonNextStep
            onPress={() => {
              replace('StepTwo')
              logger.info('-> GO ONBOARDING FLOW - STEP TWO')
            }}
            stylePosition={styles.buttonNextStepPosition}
          />
        </SafeAreaView>
      </ImageBackground>
    </>
  )
}
