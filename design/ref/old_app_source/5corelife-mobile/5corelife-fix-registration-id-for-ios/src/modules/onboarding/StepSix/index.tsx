import React, { useState } from 'react'
import { View } from 'react-native'
import { useRecoilValue, useRecoilState } from 'recoil'

import { storageAtom, userRetrieveAtom } from '../../../recoil/atoms'
import CheckHabits from '../../core/CheckHabits'
import props from './props'
import styles from './styles'
import { URL } from '../../../helpers/api'
import { fetchAxios } from '../../../helpers/axios'
import { logger } from '../../../helpers/logger'

export default ({
  navigation: { navigate, replace },
  route: {
    params: { habits, core, score },
  }
}: props) => {
logger.info("[<StepSix>]")
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)
  const [indexSelected, setIndexSelected] = useState<number>(1);
  const [storage, setStorage] = useRecoilState(storageAtom);
  const [userRetrieve, setUserRetrieve] = useRecoilState(userRetrieveAtom);

  const isLastTab = indexSelected === 2;
  const nextStep = () => {
    isLastTab ?
      navigate('StepFive') :
      setIndexSelected(indexSelected + 1);
  }

  const navigateToStepSeven = async (item: any) => {
    logger.debug('line 42 StepSix.index -> ONBOARDING FLOW FINISHED - End flow onboarding.');

    await postChanges();
    finishOnboarding();
    replace('OnboardingStackScreen', {
      screen: 'StepSeven',
      params: {
        // prevHabits: item.prevHabits,
        // core: item.core,
      },
    });
  };

  const finishOnboarding = () => {
    setStorage({
      ...storage,
      value: { ...storage.value, onboarding: false, onboarding_pendingpost: true },
    })
  }

  const postChanges = async () => {
    logger.debug('line 63 StepSix.index userRetrieve: ' + JSON.stringify(userRetrieve));
    const dataToSend = {
      ...userRetrieve.value,
      user_profile: {
        ...userRetrieve.value?.user_profile,
        onboarding: false
      }
    }
    logger.debug('line 72 StepSix.index >>>>Data to update user retrieve: ' + JSON.stringify(dataToSend));
    try {
      const userRetieveUpdated = await fetchAxios(
        'PATCH',
        URL + 'users/retrieve/',
        token,
        dataToSend,
      )
      logger.debug('line 79 StepSix.index userRetieveUpdated: ' + JSON.stringify(userRetieveUpdated));
    } catch (error) {
      logger.error('**ERROR** [PUT-RETRIEVE]');
      logger.error('line 84 StpSix.index [ERROR INFO]: ' + JSON.stringify(error));
    }
  }

  const onboardingParams = {
    params: {
      core: core,
      habits: habits,
      score: score,
    }
  }

  return (
    <>
      <View
        style={[styles.imageBackgroundContainer]}>
        <View style={[styles.safeAreaViewContainer]}>
        </View>
        <View style={[styles.pageContainer]}>
          <CheckHabits
            navigation={navigate}
            route={onboardingParams}
            isLastTab={isLastTab}
            onBoardingMode={true}
            lastStep={true}
            navigateToNextStep={navigateToStepSeven}
          />
        </View>
      </View>
    </>
  )
}
