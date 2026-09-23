import React, { useState } from 'react'
import { View } from 'react-native'
import { useRecoilValue } from 'recoil'

import { storageAtom } from '../../../recoil/atoms'
import CheckHabits from '../../core/CheckHabits'
import AdviseMessage from '../AdviseMessage'
import ButtonNextStep from '../ButtonNextStep'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'

export default ({
  navigation: { navigate, replace },
  route: {
    params: { habits, core, score },
  }
}: props) => {
logger.info("[<StepFour>]")
logger.debug("->line 25 StepFour.index habits: ", habits, "\n->score: ",core, "\n->score: ", score)
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)
  const [indexSelected, setIndexSelected] = useState<number>(1);


  const isLastTab = indexSelected === 2;
  const nextStep = () => {
    isLastTab ?
      navigate('StepFive') :
      setIndexSelected(indexSelected + 1);
  }

  const navigateToNextStep = (item: any) => {
    logger.info('-> GO ONBOARDING FLOW - STEP FIVE');
    replace('OnboardingStackScreen', {
      screen: 'StepFive',
      params: {
        prevHabits: item.prevHabits,
        core: item.core,
      },
    });
  };

  const onboardingParams = {
    params: {
      core: core,
      habits: habits,
      score: score,
    }
  }
  logger.debug("->line 55 onboarding.stepFour onboardingParams: ", onboardingParams.params)

  return (
    <>
      <View
        style={[styles.imageBackgroundContainer]}>
        <View style={[styles.safeAreaViewContainer]}>
          <AdviseMessage
            subtitle={strings.textTabs[indexSelected - 1].info}
            slideScreens={2}
            slideActive={indexSelected}
            fontSize={styles.fontSize}
          />

          {!isLastTab && <ButtonNextStep
            onPress={nextStep}
            stylePosition={styles.buttonNextStepPosition}
          />}

        </View>
        <View style={[styles.pageContainer, !isLastTab ? styles.absolute : null]}>
          <CheckHabits
            navigation={navigate}
            route={onboardingParams}
            isLastTab={isLastTab}
            onBoardingMode={true}
            navigateToNextStep={navigateToNextStep}
            lastStep={false}
          />
        </View>
      </View>
    </>
  )
}
