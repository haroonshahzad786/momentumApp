import React, { useEffect, useState } from 'react'
import { Image, ImageBackground, Text, TouchableOpacity, View, ScrollView, Platform } from 'react-native'
import { FlatList } from 'react-native-gesture-handler'
import { useRecoilState, useRecoilValue } from 'recoil'

import Button from '../../../components/Button'
import CockpitScreen from '../../../components/CockpitScreen'
import ListItemQuestion from '../../../components/ListItemQuestion'
import ModalCheckIn from '../../../components/ModalCheckIn'
import ModalQuests from '../../../components/ModalQuests'
import { URL } from '../../../helpers/api'
import { fetchAxios, fetchAxiosNoCache } from '../../../helpers/axios'
import { vh, vw } from '../../../helpers/dimensions'
import {
  dailyCheckAtom,
  localDataAtom,
  storageAtom,
  mantraAtom,
  userRetrieveAtom
} from '../../../recoil/atoms'
import { setAtomAxios } from '../../../helpers/recoil'
import { Core, Destinations, Goals, Mantra, UserRetrieve } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import styles from './styles'
import ModalMantra from '../../../components/ModalMantra'
import VideoScreen from '../../../components/VideoScreen'
import ModalAliens from '../../../components/ModalAliens'
import ModalPlanetLifetime from '../../../components/ModalPlanetLifetime'
import ModalOkCancel from '../../../components/ModalOkCancel'
import ModalGoals from '../../../components/ModalGoals'
import { ShowNotification, ShowNotificationIOS } from '../../../helpers/internalDataManagement'
import { logger } from '../../../helpers/logger'

// TODO: Check scrolling of board for the last questions for Android.

const questions = [
  {
    title: 'What was the best thing today?',
  },
  {
    title: 'What was the worst thing today?',
  },
  {
    title: 'Anything else?',
  },
]

export default ({ navigation: { navigate, pop }, route }: props) => {
  const { value: { fonts, palette, token } } = useRecoilValue(storageAtom);
  const userRetrieve = useRecoilValue(userRetrieveAtom);
  const [localData, setLocalData] = useRecoilState(localDataAtom)
  const dailyCheck = useRecoilValue(dailyCheckAtom)
  const [answers, setAnswers] = useState<string[]>(['', '', ''])
  const isCheckIn = localData.value.currentCheckin != null
  const [isLandingVideoVisible, setLandingVideoVisible] = useState<boolean>(false);
  const [isModalQuestVisible, setModalQuestVisible] = useState<boolean>(false);
  const [isModalCheckInVisible, setModalCheckInVisible] = useState<boolean>(false);
  const [isModalMantraVisible, setModalMantraVisible] = useState<boolean>(false);
  const [isModalAsteroidVisible, setModalAsteroidVisible] = useState<boolean>(false);
  const [isModalGoalsVisible, setModalGoalsVisible] = useState<boolean>(false);
  const [isGoalsVisible, setGoalsVisible] = useState<boolean>(false);
  const [isAliensVisible, setAliensVisible] = useState<boolean>(false);
  const [isScreenPlanetVisible, setScreenPlanetVisible] = useState<boolean>(false);
  const [positionActual, setPositionActual] = useState<any>('')
  const [mantra, setMantra] = useRecoilState(mantraAtom);
  const [mantraState, setMantraState] = useState<Mantra | null>(null);
  const currentCheckIn = localData.value.currentCheckin;
  const [missions, setMissions] = useState<any>({})
  const [questOrMission, setQuestOrMission] = useState<string>('');
  const [type, setType] = useState<string>('');
  const [credits, setCredits] = useState<number>(0);
  const [core, setCore] = useState([{}])
  const [days, setDaysJourney] = useState<number | string>()
  const [momentum, setMomentum] = useState<number | any>()
  const [quest, setQuest] = useState<any>({})

  useEffect(() => {
    (async () => {
      const coresUser: Core[] = await fetchAxiosNoCache<null, Core[]>(
        'GET',
        URL + 'cores/user/',
        token,
        null
      );

      const destinations: Destinations[] = await fetchAxiosNoCache<null, Destinations[]>(
        'GET',
        URL + 'destinations/',
        token,
        null
      );

      const userRetrieves: UserRetrieve = await fetchAxiosNoCache<null, UserRetrieve>(
        'GET',
        URL + 'users/retrieve/',
        token,
        null
      );

      const goals: Goals[] = await fetchAxiosNoCache<null, Goals[]>(
        'GET',
        URL + 'goals/',
        token,
        null
      );
      logger.debug("line 108 SelfReview.index goals: ", goals)

      setGoalsVisible(goals.filter((response: Goals) => response.completed).length > 0);
      logger.debug("route: ", route)
      const { params: { night } } = route;
      logger.debug('line 112 cockpit.SelfReview.index NIGHT QUEST: ' + JSON.stringify(night.quest));
      logger.debug('line 113 cockpit.SelfReview.index NIGHT MISSION' + JSON.stringify(night.mission));
      logger.debug('line 114 cockpit.SelfReview.index NIGHT JOURNEY' + JSON.stringify(night.journey));
      logger.debug('line 115 cockpit.SelfReview.index NIGHT CREDITS' + JSON.stringify(night.user_profile.credits));
      const destiny = destinations?.find(
        (x: Destinations) => x.destination === night.journey.next_destination,
      )
      const origin = destinations?.find(
        (x: Destinations) => x.destination === night.journey.actual_destination,
      );
      logger.debug("SelfReview.index destiny: ", destiny, "\norigin: ", origin)
      if (Object.keys(night?.reward).length || typeof night?.reward === 'string') {
        if (Platform.OS === 'ios') ShowNotificationIOS({ title: strings.TITLE_WON_IMPROVEMENT, message: strings.BODY_WON_IMPROVEMENT })
        else ShowNotification({ title: strings.TITLE_WON_IMPROVEMENT, message: strings.BODY_WON_IMPROVEMENT, vibration: strings.VIBRATION })
      }
      if (night?.trophies.length) {
        if (Platform.OS === 'ios') ShowNotificationIOS({ title: strings.TITLE_WON_TROPHIES, message: strings.BODY_WON_TROPHIES })
        else ShowNotification({ title: strings.TITLE_WON_TROPHIES, message: strings.BODY_WON_TROPHIES, vibration: strings.VIBRATION })
      }
      setPositionActual(origin)
      // TODO: Check what happen here with night.quest
      setQuest(night.quest)
      setMissions(night.mission)
      setCredits(night.user_profile.credits)
      const [core1, core2, core3, core4, core5] = coresUser;
      const arrayCore = [core2, core5, core4, core1, core3]
      setCore(arrayCore)
      setMomentum(userRetrieves.user_profile.momentum ?? 0);
      let days = destinations?.filter((response: any) => response?.destination === userRetrieves.user_profile.actual_destination)
      setDaysJourney(days[0]?.length - userRetrieves?.user_profile?.days_in_journey)
    })()
  }, [route.params.night])


  const questVisible = () => {
    logger.debug("line 145 SelfReview.index missions: ",missions, " quest: ", quest)
    if (Object.keys(missions).length) {
      setQuestOrMission('missions')
      if (missions.active === false && missions.success === true) {
        setModalQuestVisible(true);
        setDaysJourney('TODAY');
        setType('success')
        return null;
      }
      if (missions.active === false && missions.success === false) {
        setModalQuestVisible(true);
        setDaysJourney('TODAY');
        setType('failed')
        return null;
      }
      onClickOkQuest();
    }
    if (Object.keys(quest).length) {
      setQuestOrMission('quests')
      if (quest.active === false && quest.success === true) {
        setModalQuestVisible(true);
        setType('success')
        return null;
      }
      if (quest.active === false && quest.success === false) {
        setModalQuestVisible(true);
        setType('failed')
        return null;
      }
      onClickOkQuest();
    }
    onClickOkQuest();
  }

  const onClickOkLanding = () => {
    setLandingVideoVisible(false);
    setAliensVisible(true)
  }

  const onPressAsteroidsCancel = () => {
    logger.debug("line 185 SelfReview.index isModalAsteroidVisible: ", isModalAsteroidVisible);
    setModalAsteroidVisible(false)
    setModalCheckInVisible(true)
  }

  const missionQuery = async () => {
    try {
      onPressAsteroidsCancel()
    } catch (error: any) {
      logger.debug("line 194 SelfReview.index missionQuery error: ", error.response);
      const { mission_name } = error.response.data
      setModalCheckInVisible(true)
    }
  }

  const hideModalGoals = () => {
    setModalGoalsVisible(false)
    if (missions.description !== 'Go outside of comfort zone!') setModalAsteroidVisible(true)
    else setModalCheckInVisible(true)
  }

  const onClickOkQuest = async () => {
    console.group("line 207 SelfReview.index isGoalsVisible: ", isGoalsVisible);
    setModalQuestVisible(false)
    if (isGoalsVisible) { setModalGoalsVisible(true); return null; }
    if (missions.description === 'Go outside of comfort zone!') { setModalAsteroidVisible(true); return null; }
    setModalCheckInVisible(true)
  }

  const onClickOkCheckIn = () => {
    setModalCheckInVisible(false);
    navigate('SelfReviewDone');
  }

  const onClickDone = () => {
    logger.debug('line 220 SelfReview.index isCheckIn ' + isCheckIn)
    if (isCheckIn !== null) {
      setLocalData({
        init: true,
        value: {
          ...localData.value,
          lastNightCheckInCompleted: Date.now(),
        },
      })
      performOperation();
      logger.debug("after performOperation")
      setModalCheckInVisible(false);
      navigate('SelfReviewDone');
    } else {
      logger.error('Check SelfReview isCheckIn null!');
    }
  }

  const updateAnswers = (index: number, text: string) => {
    let newAnswers = [...answers]
    newAnswers[index] = text
    setAnswers(newAnswers)
  }

  const performOperation = async () => {
    try {
      logger.debug('line 240 cockpit.SelfReview.index performOperation answers: ' + JSON.stringify(answers));
      await fetchAxios(
        'POST',
        URL + 'self-review',
        token,
        {
          answers: JSON.stringify(answers),
        },
      )
      questVisible();
      logger.debug("pass for here")
    } catch (error) {
      logger.error('SelfReview perform operations error: ' + JSON.stringify(error));
    }
  }

  useEffect(() => {
    let Sound = require('react-native-sound');

    const soundAirlock = new Sound(require('../../../assets/sounds/airlock.mp3'), () => { soundAirlock.play((success: any) => logger.debug("line 262 SelfReview.index ", success)) });
    const soundBackground = new Sound(require('../../../assets/sounds/Menu_Select_01.mp3'), () => { soundBackground.play((success: any) => logger.debug("line 263 SelfReview.index ", success)) });

    //TODO: Shows landing if days travel equals current destination length.
    // Understand why use this const showLanding
    const showLanding = (userRetrieve.value?.user_profile.days_in_journey === userRetrieve.value?.user_profile.actual_destination_length) ?? false;
    logger.debug('line 264 cockpit.SelfReview.index days_in_journey: ', userRetrieve.value?.user_profile.days_in_journey);

    const { params: { night: { journey } } } = route;
    if (journey?.status === "Completed" && !isAliensVisible && positionActual.destination) {
      let bool: boolean = true;
      if (bool) setScreenPlanetVisible(true)
      setTimeout(() => {
        bool = false
        if (!bool) { setScreenPlanetVisible(false); setLandingVideoVisible(true); }
      }, 2800);
      logger.debug('line 274 cockpit.SelfReview.index -> SHOWING LANDING VIDEO - NIGHT CHECKIN');
    }
  }, [route.params.night.journey, positionActual.destination]);

  React.useEffect(() => {
    setMantraState(mantra.value)
  }, [setMantraState, mantra.value]);

  const updateMantraState = (text: string) => {
    setMantraState({ ...mantraState!, mantra: text });
  }

  const saveMantra = () => {
    logger.debug("line 287 cockpit.SelfReview.index saveMantra mantra: ", mantra.value, "\nmantraState: ",mantraState)
    if (mantra.value?.mantra !== mantraState?.mantra) {
      setAtomAxios(setMantra, {
        method: 'PUT',
        url: URL + 'users/mantra/',
        data: {
          mantra: mantraState?.mantra
        }
      })
    }
    setModalMantraVisible(false)
  }

  const onclickOnAliens = () => setAliensVisible(false);

  return (
    <>{
      isModalQuestVisible &&
      <ModalQuests
        daysNumberStyle={[
          fonts.QUEST_DAYS_NUMBER,
          { color: palette.TEXT_TERTIARY },
        ]}
        daysDescriptionStyle={[
          fonts.QUEST_DAYS_DESCRIPTION,
          { color: palette.TEXT_TERTIARY },
        ]}
        questDescriptionStyle={[
          fonts.QUEST_DESCRIPTION,
          { color: palette.TEXT_PRIMARY },
        ]}
        onClickOk={onClickOkQuest}
        touchableOpacityContainerButtonStyle={[
          styles.modalQuestOpacityContainerButton,
          {
            borderColor: palette.BUTTON_BORDER,
            backgroundColor: palette.SUCCESS,
          },
        ]}
        textTitleButtonStyle={[
          styles.modalQuestTextDoneButton,
          fonts.BUTTON_MEDIUM,
          {
            color: palette.TEXT_PRIMARY,
            textShadowColor: palette.TEXT_PRIMARY_SHADOW,
          },
        ]}
        isVisible={isModalQuestVisible}
        days={days}
        currentCheckIn={'night'}
        questOrMission={questOrMission}
        quest={quest}
        missions={missions}
        type={type}
        credits={credits}
      />
    }
      {
        (isModalAsteroidVisible && missions.description === 'Go outside of comfort zone!') &&
        <ModalOkCancel
          textTitle={'Asteroids \n \n Did you get out of your comfort zone today?'}
          textTitleStyle={[fonts.MODAL_TITLE, { color: palette.TEXT_PRIMARY, fontSize: 13 }]}
          okButtonImage={
            <Image
              source={require('../../../assets/images/shared/button_ok.png')}
              resizeMode={'cover'}
            />
          }
          cancelButtonImage={
            <Image
              source={require('../../../assets/images/shared/button_cancel.png')}
              resizeMode={'cover'}
            />
          }
          onCancel={() => onPressAsteroidsCancel()}
          onOk={() => missionQuery()}
          isVisible={isModalAsteroidVisible}
        />
      }
      {
        isModalGoalsVisible &&
        <ModalGoals
          textTitle={strings.MODAL_GOALS_TITLE}
          textDescription={strings.MODAL_GOALS_DESCRIPTION}
          textTitleStyle={[fonts.MODAL_TITLE, { color: palette.TEXT_PRIMARY }]}
          touchableOpacityButtonImage={
            <Image
              style={styles.imageButtonModal}
              source={require('../../../assets/images/shared/button_confirm.png')}
              resizeMode={'cover'}
            />
          }
          touchableOpacityButtonStyle={{}}
          touchableOpacityButtonOnPress={() => hideModalGoals()}
          isVisible={isModalGoalsVisible}
        />
      }
      {isModalCheckInVisible &&
        <ModalCheckIn
          titleStyle={[fonts.CHECK_IN_TITLE, { color: palette.TEXT_PRIMARY }]}
          statsNumbersStyle={[
            fonts.CHECK_IN_STATS,
            { color: palette.TEXT_PRIMARY },
          ]}
          rewardTitleStyle={[
            fonts.CHECK_IN_REWARD_TITLE,
            { color: palette.TEXT_PRIMARY },
          ]}
          rewardNumberStyle={[
            fonts.CHECK_IN_REWARD_AMOUNT,
            { color: palette.TEXT_TERTIARY },
          ]}
          checkInNumbersBigStyle={[
            fonts.CHECK_IN_NUMBERS_BIG,
            { color: palette.TEXT_TERTIARY },
          ]}
          checkInNumbersSmallStyle={[
            fonts.CHECK_IN_NUMBERS_SMALL,
            { color: palette.TEXT_TERTIARY },
          ]}
          checkInDescriptionStyle={[
            fonts.CHECK_IN_NUMBERS_DESCRIPTION,
            { color: palette.TEXT_PRIMARY },
          ]}
          onClickOk={onClickOkCheckIn}
          touchableOpacityContainerButtonStyle={{
            width: vw(25),
            height: vh(7),
            borderRadius: vw(10),
            borderWidth: vw(0.5),
            borderColor: palette.BUTTON_BORDER,
            backgroundColor: palette.SUCCESS,
          }}
          textTitleButtonStyle={[
            styles.modalCheckInTextDoneButton,
            fonts.BUTTON_MEDIUM,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW,
            },
          ]}
          isVisible={isModalCheckInVisible}
          cores={core}
          days={days}
          momentum={momentum}
          statusGoal={route.params.night.journey?.status}
        />
      }
      {isModalMantraVisible &&
        <ModalMantra
          textTitle={strings.MODAL_MANTRA_TITLE}
          textTitleStyle={[
            styles.textModalMantraTitle,
            fonts.MANTRA_TITLE,
            { color: palette.TEXT_TERTIARY }
          ]}
          iconRight={
            <Image
              style={{ width: vw(5), height: vw(5) }}
              source={require('../../../assets/images/shared/button_edit.png')}
              resizeMode={'cover'}
            />
          }
          textInputParagraphFirst={mantraState?.mantra}
          textInputParagraphFirstOnChangeText={updateMantraState}
          textParagraphSecond={''}
          textInputParagraphStyle={[
            styles.textModalMantraParagraph,
            fonts.MANTRA_PARAGRAPH,
            { color: palette.TEXT_PRIMARY }
          ]}
          textParagraphDividerStyle={[
            fonts.MANTRA_PARAGRAPH,
            { color: palette.TEXT_PRIMARY }
          ]}
          touchableOpacityContainerButtonStyle={{
            width: vw(25),
            height: vh(7),
            borderRadius: vw(10),
            borderWidth: vw(0.5),
            borderColor: palette.BUTTON_BORDER,
            backgroundColor: palette.SUCCESS
          }}
          touchableOpacityContainerButtonOnPress={saveMantra}
          textTitleButton={strings.MODAL_MANTRA_BUTTON_TEXT}
          textTitleButtonStyle={[
            styles.textDoneButton,
            fonts.BUTTON_MEDIUM,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW
            }
          ]}
          isVisible={isModalMantraVisible}
        />
      }
      {isAliensVisible &&
        <ModalAliens
          navigate={navigate}
          okButtonImage={
            <Image
              style={styles.okBtn}
              source={require('../../../assets/images/check_in/butDone.png')}
              resizeMode={'cover'}
            />
          }
          destination={userRetrieve.value?.user_profile?.actual_destination}
          styleAlien={styles.alien1}
          onclickOnAliens={onclickOnAliens}
        />
      }
      {
        (isScreenPlanetVisible) &&
        <ModalPlanetLifetime
          isVisible={isScreenPlanetVisible}
          action='landing'
          isPositionActual={positionActual.destination} />
      }
      {isLandingVideoVisible &&
        <VideoScreen
          isVisible={isLandingVideoVisible}
          // isLanding={true}
          onClickOk={onClickOkLanding}
          launchOrLanding='landing'
          destiny={positionActual.destination}
        />
      }
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/cockpit_categories/background.png')}
        resizeMode={'cover'}>
        <ScrollView style={{ flex: 1 }}>
          <ImageBackground
            style={styles.containerImageBackgroundCockpit}
            source={require('../../../assets/images/cockpit_categories/console.png')}
            resizeMode={'stretch'}>
            <View style={styles.containerCockpitScreen}>
              <CockpitScreen
                onPress={() => {
                  setModalMantraVisible(true);
                }}
              />
            </View>
            <View style={styles.panelContainer}>
              <View style={styles.containerTextTitle}>
                <TouchableOpacity
                  onPress={() => navigate('CockpitCategories')}
                  style={styles.arrowContainer}>
                  <Image
                    style={styles.arrowSize}
                    source={require('../../../assets/images/shared/arrow_blue.png')}
                    resizeMode={'cover'}
                  />
                </TouchableOpacity>
                <Text
                  style={[fonts.COCKPIT_TITLE, { color: palette.TEXT_PRIMARY }, styles.titleAlign]}>
                  {strings.TITLE}
                </Text>
              </View>
              <Image
                style={styles.imageSeparator}
                source={require('../../../assets/images/cockpit_self_review/separator_title.png')}
                resizeMode={'contain'}
              />
              <View style={styles.containerFlatListQuestions}>
                <ScrollView horizontal>
                  <FlatList
                    data={questions}
                    scrollEnabled={false}
                    showsVerticalScrollIndicator={false}
                    bounces={false}
                    renderItem={({ item, index }) => (
                      <>
                        <ListItemQuestion
                          index={index}
                          question={item}
                          placeholder={strings.QUESTION_PLACEHOLDER}
                          textTitleStyle={[
                            fonts.COCKPIT_SUBTITLE,
                            {
                              color: palette.TEXT_PRIMARY,
                            },
                          ]}
                          textInputAnswer={answers[index]}
                          textInputAnswerStyle={[
                            fonts.COCKPIT_INPUT,
                            {
                              color: palette.COCKPIT_INPUT,
                            },
                          ]}
                          textInputAnswerOnChangeText={updateAnswers}
                          placeholderColor={palette.COCKPIT_INPUT}
                        />
                      </>
                    )}
                    keyExtractor={(_, index) => index.toString()}
                  />
                </ScrollView>
              </View>
            </View>
            <View style={styles.containerButtonDone}>
              <Button
                touchableOpacityContainerStyle={{
                  backgroundColor: palette.SUCCESS,
                  borderRadius: vw(10),
                  borderWidth: vw(0.5),
                  borderColor: palette.BUTTON_BORDER,
                  height: vh(5.5),
                }}
                textTitle={strings.BUTTON_DONE}
                textTitleStyle={[
                  styles.buttonDone,
                  fonts.BUTTON_SMALL,
                  {
                    color: palette.TEXT_PRIMARY,
                    textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                  },
                ]}
                spinnerSize={20}
                spinnerColor={palette.TEXT_PRIMARY}
                isLoading={false}
                onPress={onClickDone}
              />
            </View>
          </ImageBackground>
        </ScrollView>
      </ImageBackground>
    </>
  )
}
