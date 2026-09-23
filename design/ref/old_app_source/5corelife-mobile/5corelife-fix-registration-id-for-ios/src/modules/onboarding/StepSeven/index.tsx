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
import { storageAtom, userRetrieveAtom } from '../../../recoil/atoms'
import AdviseMessage from '../AdviseMessage'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, replace } }: props) => {
  logger.info("[<StepSeven>]")
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)
  const { value } = useRecoilValue(userRetrieveAtom)

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

  const navigateToNextStep = (item: any) => {
    replace('OnboardingStackScreen', {
      screen: 'StepEight',
    });
  }

  return (
    <>
      <ImageBackground
        style={[styles.imageBackgroundContainer, { zIndex: 20 }]}
        source={require('../../../assets/images/shared/background_universe.png')}
        resizeMode={'cover'}>
        <View style={{ zIndex: 22 }}>
          <AdviseMessage
            subtitle={strings.STEP_1}
            slideScreens={1}
            slideActive={1}
            toTop={true}
            reverse={true}
          />
        </View>
        <View style={[styles.pageContainer, { zIndex: 21 }]}>
          <DashBoard
            navigation={navigate}
            onBoardingMode={true}
            launch={true}
            cockpit={true}
            navigateToNextStep={navigateToNextStep}
          />
        </View>
      </ImageBackground>
    </>
  )
}
