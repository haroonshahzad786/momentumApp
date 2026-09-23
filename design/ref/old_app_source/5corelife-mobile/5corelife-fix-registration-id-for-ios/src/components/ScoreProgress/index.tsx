import MaskedView from '@react-native-community/masked-view'
import React from 'react'
import { Animated, Image, Text, View } from 'react-native'
import { vh, vw } from '../../helpers/dimensions'
import props from './props'
import styles from './styles'
import {
  storageAtom,
} from '../../recoil/atoms';
import { useRecoilState } from 'recoil'
export default ({
  textTitleStyle,
  textTitle,
  possibleValue = 0,
  actualValue = 0,
}: props) => {

  const [storage, setStorage] = useRecoilState(storageAtom);

  const fonts = storage.value.fonts;
  const palettes = storage.value.palette;

  const imageSource = require('../../assets/images/set_habits/score.png');
  const imageSourceMask = require('../../assets/images/set_habits/score2.png');
  const arrowIcon = require('../../assets/images/set_habits/arrow_up.png');
  const possibleFillValue = (30 * (100 - possibleValue)) / 100;
  const actualFillValue = (30 * (100 - actualValue)) / 100;

  return (
    <>
      <View style={[styles.viewContainer]}>
        <Text style={[styles.textTitle, textTitleStyle]}>{textTitle}</Text>
        <View style={[styles.textBar]}>
          <View style={{transform:[{ translateX: -vh(possibleFillValue - 1.5) }]}}>
            <View style={[styles.textBarContainer]}>
              <Text style={[{ color: palettes.TEXT_PRIMARY }, fonts.DASHBOARD_PLANET]}>
                Cap ({possibleValue})
              </Text>
              <Image
                style={[styles.arrowIcon, styles.arrowDown]}
                source={arrowIcon}
                resizeMode={'contain'}
              />
            </View>
          </View>
        </View>
        <View style={styles.barContainer}>
          <Image
            style={styles.imageProgress}
            source={imageSource}
            resizeMode={'contain'}
          />

          <MaskedView
            style={{ flex: 1, flexDirection: 'row', height: '100%', position: 'absolute', alignItems: 'center', justifyContent: 'center' }}
            maskElement={
              <Image
                style={[styles.imageProgressMask, { backgroundColor: 'red', overflow: 'hidden' }]}
                source={imageSourceMask}
                resizeMode={'contain'}
              />
            }
          >
            <Image
              style={[styles.imageProgressElement, {
                transform: [
                  {
                    translateX: -vh(possibleFillValue),
                  },
                ],
              }]}
              source={imageSource}
              resizeMode={'contain'}
            />
          </MaskedView>
          <MaskedView
            style={{ flex: 1, flexDirection: 'row', height: '100%', position: 'absolute', alignItems: 'center', justifyContent: 'center' }}
            maskElement={
              <Image
                style={[styles.imageProgressMask, { backgroundColor: 'red', overflow: 'hidden' }]}
                source={imageSourceMask}
                resizeMode={'contain'}
              />
            }
          >
            <Image
              style={[styles.imageProgressElement, {
                transform: [
                  {
                    translateX: -vh(actualFillValue),
                  },
                ],
              }]}
              source={imageSource}
              resizeMode={'contain'}
            />
          </MaskedView>
        </View>

        <View style={[styles.textBar]}>
          <View style={[{
                transform: [
                  {
                    translateX: -vh(actualFillValue-2.5),
                  },
                ],
              }]}>
            <View style={[styles.textBarContainer]}>
              <Image
                style={[styles.arrowIcon]}
                source={arrowIcon}
                resizeMode={'contain'}
              />
              <Text style={[{ color: palettes.TEXT_PRIMARY }, fonts.DASHBOARD_PLANET]}>
                Power ({actualValue})
              </Text>
            </View>
          </View>
        </View>

      </View>
    </>
  )
}
