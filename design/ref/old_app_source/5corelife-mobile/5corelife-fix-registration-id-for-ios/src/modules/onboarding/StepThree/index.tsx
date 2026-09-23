import React, { useState } from 'react'
import { ImageBackground, SafeAreaView } from 'react-native'
import { useRecoilValue } from 'recoil'

import { storageAtom } from '../../../recoil/atoms'
import Cores from '../../dashboard/Cores'
import AdviseMessage from '../AdviseMessage'
import ButtonNextStep from '../ButtonNextStep'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, replace } }: props) => {
  logger.info("[<StepThree>]")
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)
  const [indexSelected, setIndexSelected] = useState<number>(1);
  const isLastTab = indexSelected === 3;
  const nextStep = () => {
    logger.debug("line 21 StepThree.index isLastTab: ", isLastTab)
    !isLastTab ?
      setIndexSelected(indexSelected + 1) : null;
  }

  const navigateToStepFour = (item: any) => {
    logger.info('-> GO ONBOARDING FLOW - STEP FOUR');
    replace('OnboardingStackScreen', {
      screen: 'StepFour',
      params: {
        core: item,
        habits: item.morningCheckInHabits,
        score: item.nightCheckInScore,
      },
    });
  }

  return (
    <>
      <ImageBackground
        style={[styles.imageBackgroundContainer]}
        source={require('../../../assets/images/shared/background_universe.png')}
        resizeMode={'cover'}>
        <SafeAreaView style={[styles.safeAreaViewContainer]}>
          <AdviseMessage
            subtitle={strings.textTabs[indexSelected - 1].info}
            slideScreens={3}
            slideActive={indexSelected}
            fontSize={styles.fontSize}
          />

          {!isLastTab &&
            <ButtonNextStep
              onPress={nextStep}
              stylePosition={styles.buttonNextStepPosition}
            />
          }

        </SafeAreaView>
        <SafeAreaView style={[styles.pageContainer, !isLastTab ? styles.absolute : null]}>
          <Cores
            navigation={navigate}
            navigateToNextStep={navigateToStepFour}
            onBoardingMode={true}
            isLastTab={isLastTab}
            isCoreStep={true}
            launch={true}
          />
        </SafeAreaView>
      </ImageBackground>
    </>
  )
}
