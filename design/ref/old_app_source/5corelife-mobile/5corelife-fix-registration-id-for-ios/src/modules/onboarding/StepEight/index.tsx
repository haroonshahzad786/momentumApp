import React, { useEffect, useState } from 'react'
import {
  Animated,
  ImageBackground,
  View,
  Easing,
} from 'react-native'
import { useRecoilState } from 'recoil'

import { vh } from '../../../helpers/dimensions'
import { storageAtom, localDataAtom } from '../../../recoil/atoms'
import strings from './strings'
import styles from './styles'
import props from './props'
import CockpitCategories from '../../cockpit/CockpitCategories'
import AdviseMessage from '../AdviseMessage'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, goBack, replace } }: props) => {
  logger.info("[<StepEight>]")
  const [storage, setStorage] = useRecoilState(storageAtom)
  const [storage2, setStorage2] = useRecoilState(localDataAtom)

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
    logger.debug('line 42 StepEight.index [ITEMS] -----> ', JSON.stringify(item));
    replace('OnboardingStackScreen', {
      screen: 'StepNine',
      params: {
        core: item.core
      }
    });
  };

  useEffect(() => {
    logger.debug('line 52 StepEight.index storage2.value.coreInfo: ', JSON.stringify(storage2.value.coreInfo));
  }, [storage2.value])

  return (
    <>
      <ImageBackground
        style={styles.imageBackgroundContainer}
        source={require('../../../assets/images/cockpit_categories/background.png')}
        resizeMode={'cover'}>
        <View style={[styles.safeAreaViewContainer]}>
          <AdviseMessage
            subtitle={strings.STEP_1}
            slideScreens={1}
            slideActive={1}
            titleOnBottom={true}
            fontSize={styles.fontSize}
          />
        </View>
        <View style={[styles.pageContainer]}>
          <CockpitCategories
            navigation={{ navigate, goBack }}
            tutorial={true}
            navigateToNextStep={navigateToNextStep}
          />
        </View>
      </ImageBackground>
    </>
  )
}
