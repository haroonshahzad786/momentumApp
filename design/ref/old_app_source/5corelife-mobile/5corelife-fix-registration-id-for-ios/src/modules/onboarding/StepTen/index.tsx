import React, { useEffect, useState } from 'react'
import {
  Animated,
  ImageBackground,
  View,
  Easing
} from 'react-native'
import { useRecoilValue } from 'recoil'
import DashBoard from '../../dashboard/Cores'
import { vh } from '../../../helpers/dimensions'
import { storageAtom } from '../../../recoil/atoms'
import AdviseMessage from '../AdviseMessage'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, replace } }: props) => {
  logger.info("[<StepTen>]")
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  const [screenPosY] = useState(new Animated.Value(0))
  useEffect(() => {
    Animated.timing(screenPosY, {
      delay: 500,
      toValue: vh(82.5),
      easing: Easing.out(Easing.ease),
      duration: 2000,
      useNativeDriver: true
    }).start()
  }, [screenPosY])

  const navigateToNextStep = () => {
    replace('OnboardingStackScreen', {
      screen: 'StepEleven',
    });
  }

  const [adviseActive, setAdviseActive] = useState(false)

  return (
    <>
      <ImageBackground
        style={[styles.imageBackgroundContainer]}
        source={require('../../../assets/images/shared/background_universe.png')}
        resizeMode={'cover'}>
        <View style={[styles.safeAreaViewContainer]}>
          {adviseActive && <AdviseMessage
            subtitle={strings.STEP_1}
            slideScreens={1}
            slideActive={1}
            toTop={true}
            reverse={true}
          />}
        </View>
        <View style={[styles.pageContainer]}>
          <DashBoard
            navigation={navigate}
            onBoardingMode={true}
            checkInMorningForce={true}
            navigateToNextStep={navigateToNextStep}
            setAdviseActive={setAdviseActive}
          />
        </View>
      </ImageBackground>
    </>
  )
}
