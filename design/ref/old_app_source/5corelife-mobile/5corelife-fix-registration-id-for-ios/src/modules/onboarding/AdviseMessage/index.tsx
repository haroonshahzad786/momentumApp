import React, { useEffect, useState } from 'react'

import props from './props'
import styles from './styles'
import {
  Animated,
  Image,
  ImageBackground,
  Text,
  View,
  Easing
} from 'react-native'
import { useRecoilValue } from 'recoil'
import { storageAtom } from '../../../recoil/atoms'
import { vh, vw } from '../../../helpers/dimensions'
import HeaderDots from '../../../components/HeaderDots'
import { logger } from '../../../helpers/logger'

export default ({
  title,
  subtitle,
  slideScreens,
  slideActive,
  fromBottom = false, // To handle the invert screen.
  titleOnBottom = false,
  toMiddle = false,
  toTop = false,
  reverse,
  fontSize,
  disabled,
}: props) => {
  logger.info("[<AdviseMessage>]")
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom);

  const [screenPosY] = useState(new Animated.Value(reverse ? 620 : 0));
  const specificValue = toTop || toMiddle ? toTop ? 70 : 85 : 70;
  useEffect(() => {
    Animated.timing(screenPosY, {
      delay: 500,
      toValue: reverse ? vh(50) : vh(specificValue),
      easing: Easing.out(Easing.ease),
      duration: 2000,
      useNativeDriver: true
    }).start()
  }, [screenPosY]);

  return (
    <>
      <Animated.View
        style={[
          styles.animatedViewScreen,
          {
            transform: [
              {
                translateY: screenPosY
              }
            ]
          }
        ]}>
        {!reverse
          ?
          <>
            <Image style={styles.imageScreenBar}
              source={require('../../../assets/images/onboarding/only_bar.png')}
              resizeMode={'contain'} />
            <ImageBackground
              style={styles.imageBackgroundScreen}
              source={require('../../../assets/images/onboarding/only_screen.png')}
              resizeMode={'contain'}>
              <View style={styles.contentScreen}>
                <View style={[styles.viewTextScreen, titleOnBottom ? styles.invertColumns : null, fontSize ? styles.widthStress : null]}>

                  {title &&
                    <Text
                      style={[
                        styles.textScreen,
                        fonts.CORE_ACTIVATE_TITLE,
                        titleOnBottom ? styles.marginSeparator : null,
                        { color: palette.TEXT_PRIMARY }
                      ]}>
                      {title}
                    </Text>
                  }

                  {subtitle &&
                    <Text
                      style={[
                        styles.textScreen,
                        fonts.LOGIN_TITLE_0,
                        { color: palette.TEXT_PRIMARY },
                        fontSize,
                      ]}>
                      {subtitle}
                    </Text>
                  }

                </View>
                {slideScreens &&
                  <View style={styles.dotContainer}>
                    <HeaderDots
                      dotsCount={slideScreens}
                      activeDotIndex={slideActive ? slideActive - 1 : 0}
                    />
                  </View>
                }
              </View>
            </ImageBackground>
          </>
          :
          <ImageBackground
            style={[styles.imageBackgroundScreenReverse, disabled ? { display: 'none' } : null]}
            source={require('../../../assets/images/onboarding/screen_inverted.png')}
            resizeMode={'contain'}>
            <View style={styles.contentScreen}>
              <View style={[styles.viewTextScreen, titleOnBottom ? styles.invertColumns : null]}>

                {title &&
                  <Text
                    style={[
                      styles.textScreen,
                      fonts.CORE_ACTIVATE_TITLE,
                      titleOnBottom ? styles.marginSeparator : null,
                      { color: palette.TEXT_PRIMARY }
                    ]}>
                    {title}
                  </Text>
                }

                {subtitle &&
                  <Text
                    style={[
                      styles.textScreen,
                      fonts.LOGIN_TITLE_0,
                      { color: palette.TEXT_PRIMARY, fontSize: vw(3.4), marginTop: vw(3) }
                    ]}>
                    {subtitle}
                  </Text>
                }

              </View>
              {slideScreens &&
                <View style={styles.dotContainer}>
                  <HeaderDots
                    dotsCount={slideScreens}
                    activeDotIndex={slideActive ? slideActive - 1 : 0}
                  />
                </View>
              }
            </View>
          </ImageBackground>
        }
      </Animated.View>
    </>
  )
}
