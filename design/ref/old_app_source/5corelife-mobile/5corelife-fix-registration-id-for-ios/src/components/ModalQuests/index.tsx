import React, { useEffect, useRef, useState } from 'react'
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
  Easing
} from 'react-native'
import { getAssetByObstacleMissions } from '../../helpers/internalDataManagement'
import props from './props'
import styles from './styles'
import strings from './strings'
import ModalScreenBase from '../ModalScreenBase'
import { vh, vw } from '../../helpers/dimensions'
import { localDataAtom } from '../../recoil/atoms'
import { logger } from '../../helpers/logger'

export default ({
  daysNumberStyle,
  daysDescriptionStyle,
  questDescriptionStyle,
  touchableOpacityContainerButtonStyle,
  textTitleButtonStyle,
  onClickOk,
  isVisible,
  days,
  currentCheckIn,
  questOrMission,
  quest,
  missions,
  type
}: props) => {
  logger.info("[<ModalQuest>]")
  const imageMonitor = require('../../assets/images/quests/monitor.png')
  const imageSpaceCrate = require('../../assets/images/quests/spaceCrate.png')
  // Quest 
  const imageNewQuest = require('../../assets/images/quests/newQuest.png')
  const imageQuestFailed = require('../../assets/images/quests/letterQuestfailed.png')
  const imageQuestCompleted = require('../../assets/images/quests/letterQuestcompleted.png')
  // MISSIONS
  const imageNewMission = require('../../assets/images/quests/letterGeneric.png')
  const imageMissionsFailed = require('../../assets/images/quests/missionFailed.png')
  const imageMissionsCompleted = require('../../assets/images/quests/missionCompleted.png')

  const imageLine = require('../../assets/images/quests/linea.png')
  const imageRewardContainer = require('../../assets/images/quests/formCont.png')
  const imageCoin = require('../../assets/images/quests/coin_small.gif')
  const [current, setCurrent] = useState<any>({
    name: '',
    description: ''
  })
  const [image, setImage] = useState<any>()
  const [imageBackground, setBackground] = useState<any>({
    image: imageSpaceCrate,
    styles: {
      width: vw(50),
      height: vh(20),
    }
  })

  const [coins] = useState(new Animated.Value(-180));
  const [coinsWidth] = useState(new Animated.Value(1));
  const [coinsPositionX] = useState(new Animated.Value(0));
  const [coinsPositionY] = useState(new Animated.Value(0));
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
  
  useEffect(() => {
    logger.debug('line 119 ModalQuest.index currentCheckIn: ', currentCheckIn, "\nquestOrMission: ", questOrMission)
    if (questOrMission === 'quests') {
      setCurrent({
        name: quest.name,
        description: quest.description
      })
      logger.debug('line 125 ModalQuest.index currentCheckIn: ', currentCheckIn, "\ntype: ", type);
      if (currentCheckIn === 'morning') setImage(imageNewQuest)
      if (currentCheckIn === 'night' && type === 'failed') setImage(imageQuestFailed)
      if (currentCheckIn === 'night' && type === 'success') {
        setImage(imageQuestCompleted)
        let Sound = require('react-native-sound')
        const soundAirlock = new Sound(
          require('../../assets/sounds/Jingle_Win_00.mp3'),
          () => {
            soundAirlock.play((success: boolean) => logger.debug("line 132 ModalQuest.index soundAirlock success: ", success))
          }
        )
      }
    }

    logger.debug('line 140 ModalQuest.index questOrMission: ', questOrMission, "\ntype:", type, "\ndays: ", days, "\ncurrentCheckIn: ", currentCheckIn);

    if (questOrMission === 'missions') {
      setBackground(getAssetByObstacleMissions(missions.description));
      setCurrent({
        name: missions.name,
        description: missions.description
      })
      if (currentCheckIn === 'morning') setImage(imageNewMission)
      if (currentCheckIn === 'night' && type === 'failed') setImage(imageMissionsFailed)
      if (currentCheckIn === 'night' && type === 'success') {
        setImage(imageMissionsCompleted)
        let Sound = require('react-native-sound')
        const soundAirlock = new Sound(
          require('../../assets/sounds/Jingle_Win_00.mp3'),
          () => {
            soundAirlock.play((success: boolean) => logger.debug("line 154 ModalQuest.index soundAirlock success: ", success))
          }
        )
      }
    }
  }, [type, currentCheckIn])

  return (
    <ModalScreenBase
      touchableOpacityContainerButtonStyle={
        touchableOpacityContainerButtonStyle
      }
      textTitleButtonStyle={textTitleButtonStyle}
      imageMonitor={imageMonitor}
      textTitle={strings.BUTTON_OK}
      onClick={onClickOk}
      isVisible={isVisible}>
      <View style={styles.topSection}>
        <Image
          style={imageBackground.style}
          source={imageBackground.image}
          resizeMode={'cover'}
        />
        <Image
          style={styles.titleImage}
          source={
            image
          }
          resizeMode={'contain'}
        />
      </View>
      <View style={styles.middleSection}>
        <Text style={styles.daysContainer}>
          <Text style={[daysNumberStyle, styles.textTitle]}>{days ? days : 0}</Text>
          <Text style={[daysDescriptionStyle, styles.textTitle]}>
            {days === 'TODAY' ? '' : ' days'}
          </Text>
        </Text>
        <Text style={[questDescriptionStyle, styles.questOrMissionTitle]}>
          {current.name}
        </Text>
        <Text style={[questDescriptionStyle, styles.questOrMissionDescription]}>
          {current.description}
        </Text>
      </View>
      <View style={styles.bottomSection}>
        <Image
          style={styles.lineImage}
          source={imageLine}
          resizeMode={'stretch'}
        />
        {
          currentCheckIn === 'night' && type === 'success' ?
            <>
              <View style={styles.rewardTitleContainer} />
              <Text style={[questDescriptionStyle, styles.rewardTitle]}>Reward</Text>
              <View style={styles.rewardAmountContainer}>
                <Text style={[daysNumberStyle]}>50</Text>
                <Image
                  style={styles.coinImage}
                  source={imageCoin}
                  resizeMode={'cover'}
                />
                <Animated.View style={[
                  {
                    position: 'absolute',
                    alignSelf: 'flex-end',
                    right: -vh(39),
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
            </>
            : null
        }
      </View>
    </ModalScreenBase >
  )
}
