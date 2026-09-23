import React, { useEffect, useState } from 'react'
import {
  Animated,
  ImageBackground,
  View,
  Easing,
} from 'react-native'
import { useRecoilState } from 'recoil'

import { vh } from '../../../helpers/dimensions'
import { storageAtom } from '../../../recoil/atoms'
import strings from './strings'
import styles from './styles'
import props from './props'
import Future from '../../cockpit/Future'
import AdviseMessage from '../AdviseMessage'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, goBack, replace }, route: { params: { core } } }: props) => {
  logger.info("[<StepNine>]")
  const [storage, setStorage] = useRecoilState(storageAtom)

  const {
    value: { fonts, palette },
  } = storage

  const [screenPosY] = useState(new Animated.Value(0))
  useEffect(() => {
    Animated.timing(screenPosY, {
      delay: 500,
      toValue: -vh(85),
      easing: Easing.out(Easing.ease),
      duration: 2000,
      useNativeDriver: true,
    }).start()
  }, [screenPosY])

  const navigateToNextStep = (item: any) => {
    replace('OnboardingStackScreen', {
      screen: 'StepTen',
    });
  };

  const [nextStep, setNextStep] = useState(1)
  const goNextStep = () => setNextStep(2)

  return (
    <>
      <ImageBackground
        style={styles.imageBackgroundContainer}
        source={require('../../../assets/images/cockpit_categories/background.png')}
        resizeMode={'cover'}>
        <View style={[styles.safeAreaViewContainer]}>
          <AdviseMessage
            subtitle={strings.textTabs[nextStep - 1].info}
            slideScreens={2}
            slideActive={nextStep}
            titleOnBottom={true}
          />
        </View>
        <View style={[styles.pageContainer]}>
          <Future
            navigation={{ navigate, goBack }}
            tutorial={true}
            route={{
              params: {
                params:
                {
                  core
                }
              }
            }}
            navigateToNextStep={navigateToNextStep}
            goNextStep={goNextStep}
            nextStep={nextStep}
          />
        </View>
      </ImageBackground>
    </>
  )
}
