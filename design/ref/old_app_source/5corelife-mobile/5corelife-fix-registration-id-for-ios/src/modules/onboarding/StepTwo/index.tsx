import React, { useEffect, useState } from 'react'
import {
  Animated,
  View,
  Easing
} from 'react-native'
import { useRecoilValue } from 'recoil'

import { vh } from '../../../helpers/dimensions'
import { storageAtom } from '../../../recoil/atoms'
import Journey from '../../dashboard/Journey'
import AdviseMessage from '../AdviseMessage'
import ButtonNextStep from '../ButtonNextStep'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, replace } }: props) => {
  logger.info("[<StepTwo>]")
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  const [screenPosY] = useState(new Animated.Value(0));
  const [indexSelected, setIndexSelected] = useState<number>(1);
  const lastTab = indexSelected === 2;
  const nextStep = () => {
    if (lastTab) {
      logger.info('-> GO ONBOARDING FLOW - STEP THREE');
      replace('StepThree');
    } else
      setIndexSelected(2);
  
  }

  useEffect(() => {
    Animated.timing(screenPosY, {
      delay: 500,
      toValue: vh(100),
      easing: Easing.out(Easing.ease),
      duration: 2000,
      useNativeDriver: true
    }).start()
  }, [screenPosY])


  return (
    <>
      <View
        style={styles.imageBackgroundContainer}>
        <View style={styles.safeAreaViewContainer}>
          <AdviseMessage
            title={lastTab ? strings.TITLE_TAB2 : undefined}
            subtitle={lastTab ? strings.SUBTITLE_TAB2 : strings.SUBTITLE_TAB1}
            titleOnBottom={true}
            slideScreens={2}
            slideActive={indexSelected}
            fontSize={styles.fontSizeFat}
          />

          <ButtonNextStep
            onPress={nextStep}
            stylePosition={styles.buttonNextStepPosition}
          />
        </View>

        <View style={[styles.pageContainer]}>
          <Journey
            navigation={navigate}
            onBoardingMode={true}
          />
        </View>

      </View>
    </>
  )
}
