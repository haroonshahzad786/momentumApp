import React from 'react'
import {
  Text,
  View,
  TouchableOpacity,
  Image,
  ScrollView,
  Platform,
  Vibration
} from 'react-native';
import { storageAtom } from '../../recoil/atoms'
import { useRecoilValue } from 'recoil'

//import for the collapsible/Expandable view
import Collapsible from 'react-native-collapsible';
import LinearGradient from 'react-native-linear-gradient';
import props from './props'
import styles from './styles'
import Slider from '@react-native-community/slider';

const Slide = React.memo(({ sliderValueNumber, changeValue, primaryColor }: any) => {
  return (
    <View style={[styles.sliderBox, { transform: [{ rotate: '270deg' }] }]}>
      <Slider
        minimumValue={0}
        maximumValue={5}
        step={1}
        value={sliderValueNumber}
        onSlidingComplete={changeValue}
        minimumTrackTintColor={primaryColor}
        thumbTintColor={primaryColor}
        maximumTrackTintColor="#FFFFFF"
        style={styles.slider}
      />
    </View>
  )
})

export default React.memo(({
  primaryColor,
  hasBubble,
  textHeader,
  isActive,
  avatarPath,
  isContentList,
  content,
  onEditing,
  updateList,
  sliderValueNumber,
}: props) => {

  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom);

  const [collapsed, setCollapsed] = React.useState(isActive ?? false);

  const toggleExpanded = () => {
    setCollapsed(!collapsed);
  };

  const onEditFunction = (item: any) => {
    if (onEditing != null) {
      onEditing(item);
    }
  }

  const changeValue = (value: number) => {
    if (value === 5)
      Vibration.vibrate();
    updateList(value)
  }

  const isMaxLevel = sliderValueNumber === 5;
  const isAndroid = Platform.OS === 'android' ? true : false;
  return (
    <>
      <View style={[styles.containerScoreRow, { flex: 1 }]}>
        <View style={[styles.offsetContainerIcon]}>
          <LinearGradient
            colors={['#FFFF', primaryColor]}
            start={{ x: 0.5, y: 0.0 }} end={{ x: 1.0, y: 1.0 }}
            style={[styles.bubbleShape]}
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


        <TouchableOpacity onPress={toggleExpanded}>
          {/* <View style={[styles.rowContainerData, styles.rowBackground, { backgroundColor: primaryColor }]}> */}
          <LinearGradient
            colors={['#000', primaryColor]}
            start={{ x: 0, y: 0.5 }} end={{ x: 0.1, y: 0.5 }}
            style={[styles.rowContainerData, styles.rowBackground]}
          >
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
            <Image
              style={[styles.butExpand, collapsed ? styles.inactive : styles.active]}
              source={require('../../assets/images/shared/butExpand.png')}
            />
          </LinearGradient>
        </TouchableOpacity>
      </View>

      <Collapsible collapsed={!collapsed} >
        <ScrollView>
          <View
            style={[
              styles.containerCardQuest,
              {
                borderColor: palette.SETTINGS_CARD_BORDER,
                backgroundColor: '#0f0f0f',
                borderRadius: 30,
                // flex: 1,
              }
            ]}>
            <TouchableOpacity onPress={() => onEditFunction(content)} >
              <View style={[styles.containerItemRowText/*, { flex: 1 }*/]}>
                <View style={{ width: '50%', marginTop: 15}}>
                  <Text
                    style={[
                      styles.textQuestHeader,
                      fonts.HABITS_ACCORDION,
                      { color: palette.TEXT_PRIMARY }
                    ]}>
                    {content.description}
                  </Text>
                </View>

                <View style={[
                  styles.containerSlide,
                  {
                    borderColor: palette.SETTINGS_CARD_BORDER,
                    marginLeft: -12,
                  }
                ]}>
                  <View
                    style={[
                      styles.containerSlide,
                      {
                        borderColor: palette.SETTINGS_CARD_BORDER,
                      }
                    ]}>
                    {
                      isMaxLevel &&
                      <Image
                        style={[styles.congrats, isAndroid ? null : styles.alignIosCongrats]}
                        source={require('../../assets/images/shared/streaks.gif')}
                        resizeMode={'contain'}
                      />
                    }
                    <Slide
                      sliderValueNumber={sliderValueNumber}
                      changeValue={changeValue}
                      primaryColor={primaryColor} />

                    <View style={[
                      styles.point,
                      (isAndroid ? styles.alignAndroidValue : styles.alignIosValue)
                    ]}>
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

              </View>
              <View style={[styles.divider, {
                borderColor: palette.LEADERBOARD_HEADER_GRAY
              }]}>
              </View>
            </TouchableOpacity>
          </View>
        </ScrollView>
      </Collapsible>
    </>
  )
})
