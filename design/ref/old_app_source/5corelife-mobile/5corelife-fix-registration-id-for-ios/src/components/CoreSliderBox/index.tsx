import React from 'react'
import {
  Text,
  View,
  TouchableOpacity,
  Image,
} from 'react-native';
import { storageAtom } from '../../recoil/atoms'
import { useRecoilValue } from 'recoil'
//import for the animation of Collapse and Expand
import * as Animatable from 'react-native-animatable';

//import for the collapsible/Expandable view
import Collapsible from 'react-native-collapsible';
import LinearGradient from 'react-native-linear-gradient';
import props from './props'
import styles from './styles'
import { ScrollView } from 'react-native-gesture-handler';
import Slider from '@react-native-community/slider';

export default ({
  primaryColor,
  textHeader,
  avatarPath,
  value,
  setValue,
  name
}: props) => {


  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom);

  const sliderValue = value ?? 0;
  const [sliderValueNumber, setSliderValueNumber] = React.useState(0);
  const changeValue = (name: string, value: number) => {
    setValue(name, value);
    setSliderValueNumber(value);
  }
  return (
    <>
      <View style={[styles.containerScoreRow]}>

        <View style={[styles.offsetContainerIcon]}>
          <LinearGradient
            colors={['#FFFF', primaryColor]}
            start={{ x: 0.5, y: 0.0 }} end={{ x: 1.0, y: 1.0 }}
            style={styles.bubbleShape}
          >
            <View style={[styles.containerBubble, {
              backgroundColor: '#1B1714',
            }]}>
              <Image
                style={[styles.iconBubble]}
                source={avatarPath}
                resizeMode={'cover'}
              />
            </View>
          </LinearGradient>
        </View>

        <LinearGradient
          colors={['#000', primaryColor]}
          start={{ x: 0, y: 0.5 }} end={{ x: 0.1, y: 0.5 }}
          style={[styles.rowContainerData, styles.rowBackground]}
        >
          <ScrollView horizontal={true}>
            <Text
              style={[
                styles.rowText,
                fonts.HABITS_ACCORDION,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW
                }
              ]}>
              {textHeader}
            </Text>
          </ScrollView>

        </LinearGradient>

      </View>
      <View>
        <View
          style={[
            styles.containerCardQuest,
            {
              borderColor: palette.SETTINGS_CARD_BORDER
            }
          ]}>

          <View style={styles.sliderBox}>
            <Slider
              style={styles.sliderCore}
              minimumValue={0}
              maximumValue={5}
              step={1}
              value={sliderValueNumber}
              onSlidingComplete={(val) => { changeValue(name, val); }}
              minimumTrackTintColor={primaryColor}
              thumbTintColor={primaryColor}
              maximumTrackTintColor="#FFFFFF"
            />
          </View>
          <View style={styles.numberBox}>
            <Text style={[
              styles.numberSliderValue,
              fonts.HABITS_ACCORDION,
              {
                color: palette.TEXT_PRIMARY,
                textShadowColor: palette.TEXT_PRIMARY_SHADOW
              }]}>
              {sliderValueNumber}
            </Text>
          </View>
        </View>
      </View>
    </>
  )
}
