import React, { useState } from 'react'
import {
  View} from 'react-native'
import { useRecoilValue, useRecoilState } from 'recoil'

import { storageAtom } from '../../../recoil/atoms'
import SetHabits from '../../core/SetHabits'
import AdviseMessage from '../AdviseMessage'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'

export default ({
  navigation: { navigate, replace },
  route: {
    params: { core, prevHabits },
  }
}: props) => {
logger.info("[<StepFive>]")
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom);
  const [storage, setStorage] = useRecoilState(storageAtom);
  const [indexSelected, setIndexSelected] = useState<number>(1);
  const isLastTab = indexSelected === 2;

  const navigateToStepSix = (item: any) => {
    logger.debug('Activate after submit of the step five: ' + JSON.stringify(item))
    logger.info('-> GO ONBOARDING FLOW - STEP SIX');
    // return;
    replace('OnboardingStackScreen', {
      screen: 'StepSix',
      params: {
        core: item.core,
        habits: item.habits,
        score: item.score,
      },
    });
  };

  const lastStep = () => {
    setIndexSelected(2);
  }

  const onboardingParams = {
    params: {
      core: core,
      prevHabits: prevHabits,
    }
  }
  logger.debug("line 62 StepFive index onboardingParams: ", onboardingParams)
  return (
    <>
      <View
        style={[styles.imageBackgroundContainer]}>
        <View style={[styles.safeAreaViewContainer]}>
          {isLastTab ?
            <AdviseMessage
              subtitle={strings.STEP_2}
              slideScreens={2}
              slideActive={2}
              toTop={true}
              fontSize={styles.fontSize}
            /> : <AdviseMessage
              subtitle={strings.STEP_1}
              slideScreens={2}
              slideActive={1}
              toTop={true}
              fontSize={styles.fontSize}
            />
          }
        </View>
        <View style={[styles.pageContainer]}>
          <SetHabits
            navigation={navigate}
            route={onboardingParams}
            isLastTab={isLastTab}
            onBoardingMode={true}
            navigateToStepSix={navigateToStepSix}
            habitsSelected={lastStep}
            habitsRequired={2}
          />
        </View>
      </View>
    </>
  )
}
