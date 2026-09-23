import React, { useRef, useEffect, useState } from 'react'
import {
  TextInput,
  ImageBackground,
  Text,
  TouchableOpacity,
  View,
  Switch,
  Image,
  ViewStyle,
  Animated,
  Easing,
} from 'react-native'
import Modal from 'react-native-modal'
import { useRecoilValue } from 'recoil'
import { vh, vw } from '../../helpers/dimensions'
import { URL } from '../../helpers/api'
import { storageAtom, dailyCheckAtom, userRetrieveAtom } from '../../recoil/atoms'
import Button from '../Button'

import props from './props'
import styles from './styles'
import strings from './strings'
import ModalScreenBase from '../ModalScreenBase'
import StatWidget from './StatWidget'

export default ({
  titleStyle,
  statsNumbersStyle,
  rewardTitleStyle,
  rewardNumberStyle,
  checkInNumbersBigStyle,
  checkInNumbersSmallStyle,
  checkInDescriptionStyle,
  touchableOpacityContainerButtonStyle,
  textTitleButtonStyle,
  onClickOk,
  isVisible,
  cores,
  days,
  momentum,
  statusGoal
}: props) => {
  const imageMonitor = require('../../assets/images/check_in/monitor.png')
  const imageLine = require('../../assets/images/check_in/line.png')
  const imageCoin = require('../../assets/images/quests/coin_small.gif')
  const imageCheckInCompleted = require('../../assets/images/check_in/letterCheckincompleted.png')

  const imageStatBrain = require('../../assets/images/check_in/mindset.png')
  const imageStatEmotional = require('../../assets/images/check_in/emotional.png')
  const imageStatRelationships = require('../../assets/images/check_in/relationships.png')
  const imageStatPhysical = require('../../assets/images/check_in/physicalHealth.png')
  const imageStatMoney = require('../../assets/images/check_in/finantial.png')

  const userRetrieve = useRecoilValue(userRetrieveAtom);
  const userProfile = userRetrieve.value?.user_profile;
  const arrayCores1 = [
    {
      name: "MINDSET",
      img: imageStatBrain
    },
    {
      name: "EMOTIONAL_HEALTH",
      img: imageStatEmotional
    },
    {
      name: "RELATIONSHIPS",
      img: imageStatRelationships
    },

  ]
  const arrayCores2 = [
    {
      name: "PHYSICAL_HEALTH",
      img: imageStatPhysical
    },
    {
      name: "CAREER_FINANCES",
      img: imageStatMoney
    },
  ]

  const [coins] = useState(new Animated.Value(-180));
  const [coinsWidth] = useState(new Animated.Value(1));
  const [coinsPositionX] = useState(new Animated.Value(0));
  useEffect(() => {
    (() => {
      Animated.loop(
        Animated.sequence([
          Animated.timing(coinsPositionX, {
            toValue: vh(0),
            easing: Easing.inOut(Easing.ease),
            duration: 500,
            useNativeDriver: true,
          }),
          Animated.timing(coins, {
            toValue: -vh(30),
            easing: Easing.inOut(Easing.ease),
            duration: 500,
            useNativeDriver: true,
          }),
          Animated.timing(coinsWidth, {
            toValue: 0.8,
            easing: Easing.ease,
            duration: 500,
            useNativeDriver: true,
          }),
          Animated.parallel([
            Animated.timing(coins, {
              toValue: -vh(99),
              easing: Easing.inOut(Easing.ease),
              duration: 1000,
              useNativeDriver: true,
            }),
            Animated.timing(coinsPositionX, {
              toValue: vh(20),
              easing: Easing.inOut(Easing.ease),
              duration: 1000,
              useNativeDriver: true,
            }),
          ]),
          Animated.timing(coinsWidth, {
            toValue: 0,
            easing: Easing.ease,
            duration: 300,
            useNativeDriver: true,
          }),
        ])
      ).start()
    })()
  }, [])

  return (
    <ModalScreenBase
      touchableOpacityContainerButtonStyle={
        touchableOpacityContainerButtonStyle
      }
      textTitleButtonStyle={textTitleButtonStyle}
      imageMonitor={imageMonitor}
      textTitle={strings.BUTTON_OK}
      onClick={onClickOk}
      isVisible={isVisible}
      heightOffset={-2}>
      <View style={styles.centeredAbsolute}>
        <Image
          style={styles.titleImage}
          source={imageCheckInCompleted}
          resizeMode={'contain'}
        />
      </View>
      <View style={styles.topSection}>
        <Text style={[titleStyle, styles.textTitle]}>
          Ship Diagnostics{'\n'}Review
        </Text>
        <View style={styles.statsContainer}>
          <View style={[styles.statRow]}>
            {
              arrayCores1.map((response, i) =>
                <StatWidget
                  statsNumbersStyle={statsNumbersStyle}
                  statImage={response.img}
                  statValue={cores && cores[i]['core_power']}
                  isLocked={cores && cores[i]['enabled'] ? false : true}
                />
              )
            }
            {/* <StatWidget
              statsNumbersStyle={statsNumbersStyle}
              statImage={imageStatBrain}
              statValue={4}
              isLocked={false}
            />
            <StatWidget
              statsNumbersStyle={statsNumbersStyle}
              statImage={imageStatEmotional}
              statValue={0}
              isLocked={true}
            />
            <StatWidget
              statsNumbersStyle={statsNumbersStyle}
              statImage={imageStatRelationships}
              statValue={2}
              isLocked={false}
            /> */}
          </View>
          <View style={styles.statRow}>
            {
              arrayCores2.map((response, i) =>
                <StatWidget
                  statsNumbersStyle={statsNumbersStyle}
                  statImage={response.img}
                  statValue={cores && cores[i + 3]['core_power']}
                  isLocked={cores && cores[i + 3]['enabled'] ? false : true}
                />
              )
            }
            {/* <StatWidget
              statsNumbersStyle={statsNumbersStyle}
              statImage={imageStatPhysical}
              statValue={0}
              isLocked={true}
            />
            <StatWidget
              statsNumbersStyle={statsNumbersStyle}
              statImage={imageStatMoney}
              statValue={0}
              isLocked={true}
            /> */}
          </View>
        </View>

      </View>
      <View style={styles.middleSection}>
        <View style={styles.halfFlex}>
          <Text style={[checkInNumbersBigStyle, styles.mainContentNumber]}>
            {userRetrieve.value?.user_profile.actual_destination === 'Endless' ? 'Endless' : days + ' Days'}
          </Text>
          <Text
            style={[checkInDescriptionStyle, styles.mainContentDescription]}>
            for destination
          </Text>
        </View>
        <View style={styles.halfFlex}>
          <Text style={styles.mainContentNumber}>
            <Text style={[checkInNumbersBigStyle, styles.textTitles]}>{Math.round(Number(momentum ?? userProfile?.momentum))}</Text>
            <Text style={[checkInNumbersSmallStyle, styles.textTitles]}>%</Text>
          </Text>
          <Text
            style={[checkInDescriptionStyle, styles.mainContentDescription]}>
            momentum
          </Text>
        </View>

      </View>
      <View style={styles.bottomSection}>
        <Image
          style={styles.lineImage}
          source={imageLine}
          resizeMode={'stretch'}
        />

        <View style={styles.rewardTitleContainer}></View>
        <Text style={[rewardTitleStyle, styles.rewardTitle]}>Reward</Text>
        <View style={styles.rewardAmountContainer}>
          <Text style={[rewardNumberStyle]}>{statusGoal === "Completed" ? 75 : 25}</Text>
          <Image
            style={styles.coinImage}
            source={imageCoin}
            resizeMode={'cover'}
          />
          <Animated.View style={[
            {
              position: 'absolute',
              alignSelf: 'flex-end',
              right: -vh(40),
              top: vh(31),
              width: "100%",
              transform: [
                {
                  translateY: coins
                },
                {
                  translateX: coinsPositionX
                }
              ],
            },
          ]}>

            <Animated.Image
              style={[{
                transform: [
                  { scale: coinsWidth, },
                ]
              }]}
              source={imageCoin}
              resizeMode={'cover'}
            />
          </Animated.View>
        </View>
      </View>
    </ModalScreenBase>
  )
}
