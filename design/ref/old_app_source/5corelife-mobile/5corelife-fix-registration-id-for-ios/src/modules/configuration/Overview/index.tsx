import React, { useEffect, useState } from 'react'
import { ImageBackground, View, Platform } from 'react-native'
import { ScrollView, TouchableOpacity } from 'react-native-gesture-handler'
import Animated from 'react-native-reanimated'
import { SceneMap, TabView } from 'react-native-tab-view'
import { useRecoilState, useRecoilValue } from 'recoil'
import AccordionColour from '../../../components/AccordionColour'
import HeaderDots from '../../../components/HeaderDots'
import HeaderSettings from '../../../components/HeaderSettings'
import ModalHabit from '../../../components/ModalHabit'
import { vh, vw } from '../../../helpers/dimensions'
import { coresAtom, localDataAtom, storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { fetchAxiosMultiple, fetchAxios } from '../../../helpers/axios';
import { URL } from '../../../helpers/api'
import { cloneDeep } from 'lodash'
import { setAtomManual } from '../../../helpers/recoil'
import { getImageByCore, ShowNotification, ShowNotificationIOS } from '../../../helpers/internalDataManagement'
import { HabitsOverviewRequest, HabitsOverviewResponse } from '../../../typescript/main'
import { logger } from '../../../helpers/logger'


export default ({ navigation: { navigate, goBack, pop } }: props) => {
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)

  const [cores, setCoresData] = useRecoilState(coresAtom);
  const localData = useRecoilValue(localDataAtom);
  const [habitsList, setHabitsList] = useState<any[]>([]);

  const [selectedHabit, setSelectedHabit] = React.useState<any>(null);
  const [isModalVisible, setModalVisible] = React.useState<boolean>(false);

  const [index, setIndex] = React.useState(0);
  const [routes] = React.useState([
    { key: 'current', title: 'Current' },
    { key: 'formed', title: 'Formed' },
  ]);

  const habitsCategoriesFormed = [
    {
      core: 'FAVORITES',
      habits: []
    },
    {
      core: 'MINDSET',
      habits: []
    },
    {
      core: 'EMOTIONAL_HEALTH',
      habits: []
    },
    {
      core: 'RELATIONSHIPS',
      habits: []
    },
    {
      core: 'PHYSICAL_HEALTH',
      habits: []
    },
    {
      core: 'CAREER_FINANCES',
      habits: []
    },
  ];

  const habitsCategoriesNOTFormed = [
    {
      core: 'FAVORITES',
      habits: []
    },
    {
      core: 'MINDSET',
      habits: []
    },
    {
      core: 'EMOTIONAL_HEALTH',
      habits: []
    },
    {
      core: 'RELATIONSHIPS',
      habits: []
    },
    {
      core: 'PHYSICAL_HEALTH',
      habits: []
    },
    {
      core: 'CAREER_FINANCES',
      habits: []
    },
  ];
  const daysHabits = async (habits: any) => {
    let arrayElement: any[] = []
    const arrayHabits: any = habits.map(async (response: any) => {
      let object = {}
      try {
        //TODO: tiping this line
        const api = await fetchAxios(
          'PATCH',
          `${URL}habits/${response.id}/`,
          token,
          { selected: response.selected }
        )
        object = {
          ...response,
          days_total: formatDate(api),
        }
        arrayElement.push(object)

      } catch (error: any) {
        logger.error("DaysHabits update by id habits error: ", error.response);
      }
      return arrayElement;
    })
    const [array] = await Promise.all(arrayHabits)
    return array
  }

  useEffect(() => {
    try {
      const fetchData = async () => {
        if (cores && cores.value) {
          const responses = await fetchAxiosMultiple(
            cores.value.map((core) => {
              return {
                method: 'GET',
                url: `${URL}habits/?core=${core.core_string}`,
                token
              }
            })
          )

          const coresCopy = cloneDeep(cores.value);
          let habits = new Array();

          responses.forEach((response) => {
            if (response.length > 0) {
              const core = response[0].core;
              let coreCopy = coresCopy?.find(x => x.core_string === core);
              if (!coreCopy) return;
              coreCopy.habits = response;
              habits = habits.concat(response);
            }
          });
          if (habits.length > 0) {

            setAtomManual(setCoresData, coresCopy);
            const arrayHabits = await daysHabits(habits)
            setHabitsList(arrayHabits.filter((response: any) => response.selected));

          }
        }
      }
      fetchData();

    } catch (error) {
      logger.error('Get habits by core error: ' + JSON.stringify(error));
    }

  }, []);

  const openModal = (item: any) => {
    setModalVisible(true);
    setSelectedHabit(item);
  }

  const submitChanges = async (habit: HabitsOverviewRequest) => {
    try {
      logger.debug('line 176 Overview.index submitChanges habit: ' + JSON.stringify(habit))
      const habitRequest: HabitsOverviewRequest = {
        id: habit.id!,
        name: habit.name!,
        positive: habit.positive ?? true,
        description: habit.description!,
        core: habit.core!,
        formed: habit.formed ?? false,
        daysRow: habit.daysRow === "" || habit.daysRow === null ? "0" : habit.daysRow, // TODO: check how to save this field in the database
        favorite: habit.favorite ?? false,
      }
      const habitOverview: HabitsOverviewResponse = await fetchAxios<HabitsOverviewRequest, HabitsOverviewResponse>(
        'PUT',
        `${URL}habits/${habitRequest.id}/`,
        token,
        habitRequest,
      )
      logger.debug('line 183 Overview.index responseApi: ', JSON.stringify(habitOverview))
      if (habitOverview?.trophies.length) {
        const notification = {
          vibration: strings.VIBRATION,
          title: strings.TITLE_WON_TROPHIES,
          message: strings.BODY_WON_TROPHIES
        }
        if (Platform.OS === 'ios') ShowNotificationIOS(notification)
        else ShowNotification(notification)
      }

      let restArray = cloneDeep(habitsList).filter((x) => (x.id !== habit.id));
      setHabitsList([...restArray, habit]);
    } catch (error) {
      logger.error('Put habits error: ' + JSON.stringify(error));
    }

    setModalVisible(false);
  }

  const renderScene = SceneMap({
    current: () => HabitsRoute(habitsCategoriesNOTFormed, false),
    formed: () => HabitsRoute(habitsCategoriesFormed, true),
  });

  const renderTabBar = (props: any) => {
    return (
      <View style={styles.tabBar}>
        {props.navigationState.routes.map((route: any, i: number) => {
          return (
            <TouchableOpacity
              style={[styles.tabItem, i == index ? { backgroundColor: palette.SETTINGS_CARD_BORDER } : null]}
              onPress={() => setIndex(i)}>
              <Animated.Text style={[fonts.HABITS_TAB, i == index ? { color: palette.TEXT_QUATERNARY } : { color: palette.SETTINGS_CARD_BORDER }]}>{route.title}</Animated.Text>
            </TouchableOpacity>
          );
        })}
      </View>
    );
  };

  const formatDate = ({ selected_date }: any) => {
    if (!selected_date) return 0
    const dateNow = new Date();
    const year = dateNow.getFullYear(),
      month = dateNow.getMonth() + 1,
      day = dateNow.getDate()
    var aFecha1 = selected_date.split('-');
    var fFecha2 = Date.UTC(aFecha1[0], aFecha1[1] - 1, aFecha1[2]);
    var fFecha1 = Date.UTC(year, month - 1, day);
    var dif = fFecha2 - fFecha1;
    var dias = Math.floor(dif / (1000 * 60 * 60 * 24));
    return dias;
  }

  const HabitsRoute = (coreCategoryList: any[], isFormed: boolean) => {
    return (
      <View style={[
        styles.containerBackCard
      ]}>
        <View
          style={[
            styles.containerCardQuest,
            {
              backgroundColor: palette.SETTINGS_CARD_BACKGROUND,
              borderColor: palette.SETTINGS_CARD_BORDER
            }
          ]}>
          <View style={[styles.containerRows]}>
            <View style={{ zIndex: 9 }}>

              {coreCategoryList.map((item: any, index: number) => {

                const extraData = getImageByCore(item.core);
                const habitsListFiltered = isFormed ?
                  habitsList.filter((x) => x.formed) :
                  habitsList.filter((x) => !x.formed);

                if (item.core === 'FAVORITES') {
                  return (
                    <>
                      <React.Fragment key={item.uniqueKey}>
                        <AccordionColour
                          textHeader={extraData.formalName}
                          hasBubble={true}
                          isContentList={true}
                          content={habitsListFiltered.filter((x) => x.favorite)}
                          avatarPath={extraData.avatarIcon}
                          primaryColor={extraData.primaryColor}
                          firstHeaderColumn={strings.HEADER_HABIT_NAME}
                          onEditing={openModal}
                          isActive={(selectedHabit != null) && (item.id == selectedHabit.id)}
                        />
                      </React.Fragment>
                    </>
                  )
                }
                else {
                  const habitsByCore = habitsListFiltered.filter((x) => x.core === item.core);
                  if (habitsByCore.length > 0)
                    return (<>
                      <React.Fragment key={item.uniqueKey}>
                        <AccordionColour
                          textHeader={extraData.formalName}
                          hasBubble={true}
                          isContentList={true}
                          content={habitsByCore}
                          avatarPath={extraData.avatarIcon}
                          primaryColor={extraData.primaryColor}
                          firstHeaderColumn={strings.HEADER_HABIT_NAME}
                          secondHeaderColumn={strings.HEADER_HABIT_DAYS}
                          onEditing={openModal}
                          isActive={(selectedHabit != null) && (item.id == selectedHabit.id)}
                        />
                      </React.Fragment>
                    </>)
                  else
                    return (<></>)
                }
              })}
            </View>
          </View>
        </View>
      </View>
    );
  }

  return (
    <>
      {
        isModalVisible &&
        <ModalHabit
          quizTitleStyle={[fonts.QUIZ_TITLE, { color: palette.TEXT_PRIMARY }]}
          quizSubtitleStyle={[
            fonts.CORE_HABIT_TITLE,
            { color: palette.TEXT_PRIMARY },
          ]}
          quizQuestionsHeaderStyle={[
            fonts.QUIZ_TITLE,
            { color: palette.TEXT_PRIMARY },
          ]}
          quizQuestionAnswerStyle={[
            fonts.QUIZ_QUESTION_ANSWER,
            { color: palette.TEXT_PRIMARY },
          ]}
          quizQuestionDescriptionStyle={[
            fonts.QUIZ_QUESTION_DESCRIPTION,
            { color: palette.TEXT_PRIMARY },
          ]}
          quizScoreBigStyle={[
            fonts.QUIZ_SCORE_BIG,
            { color: palette.TEXT_TERTIARY },
          ]}
          quizScoreSmallStyle={[
            fonts.QUIZ_SCORE_SMALL,
            { color: palette.TEXT_TERTIARY },
          ]}
          touchableOpacityContainerButtonStyle={{
            width: vw(25),
            height: vh(7),
            borderRadius: vw(10),
            borderWidth: vw(0.5),
            borderColor: palette.BUTTON_BORDER,
            backgroundColor: palette.SUCCESS,
          }}
          textTitleButtonStyle={[
            styles.textDoneButton,
            fonts.BUTTON_MEDIUM,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW,
            },
          ]}
          textInputParagraphStyle={[
            styles.textModalMantraParagraph,
            fonts.MANTRA_PARAGRAPH,
            { color: palette.TEXT_PRIMARY }
          ]}
          isVisible={isModalVisible}
          habitInfo={selectedHabit}
          onClickOk={submitChanges}
          onCancel={() => setModalVisible(false)}
        />
      }
      <ImageBackground
        style={[styles.container]}
        source={require('../../../assets/images/shared/background.png')}
        resizeMode={'cover'}>
        <ScrollView>
          <View style={[styles.containerSub]}>

            <HeaderDots
              dotsCount={2}
              activeDotIndex={0}
              onBackButton={() => { navigate('Profile') }}
            />
            <HeaderSettings
              title={strings.TITLE}
              textTitleStyle={[
                fonts.CORE_TITLE,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW
                }
              ]}
              leftArrowNavigation={() => { navigate('Leaderboard') }}
            />

            <TabView
              navigationState={{ index, routes }}
              renderTabBar={renderTabBar}
              renderScene={renderScene}
              onIndexChange={setIndex}
            />
          </View>
        </ScrollView>
      </ImageBackground>
    </>
  )
}
