import React, { useEffect, useState } from 'react'
import {
  FlatList,
  Image,
  ImageBackground,
  ScrollView,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { useRecoilState, useRecoilValue } from 'recoil'

import Button from '../../../components/Button'
import ButtonBack from '../../../components/ButtonBack'
import CockpitScreen from '../../../components/CockpitScreen'
import ListItemHabit from '../../../components/ListItemHabit'
import ScoreProgress from '../../../components/ScoreProgress'
import { vh, vw } from '../../../helpers/dimensions'
import { coresAtom, storageAtom, userRetrieveAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { cloneDeep } from 'lodash'
import { setAtomManual } from '../../../helpers/recoil'
import { fetchAxios, fetchAxiosNoCache } from '../../../helpers/axios'
import { URL } from '../../../helpers/api'
import { getImageByCore } from '../../../helpers/internalDataManagement'
import HeaderSettings from '../../../components/HeaderSettings'
import ModalHabit from '../../../components/ModalHabit'
import { HabitsCreatedRequest, HabitsCreatedResponse, HabitsTypes } from '../../../typescript/main'
import { logger } from '../../../helpers/logger'
export default ({
  navigation: { navigate, pop, replace },
  onBoardingMode,
  isLastTab,
  navigateToStepSix,
  habitsSelected,
  habitsRequired,
  route: {
    params: { core, prevHabits },
  },
}: props) => {
  const {
    value: { fonts, palette, token },
  } = useRecoilValue(storageAtom)

  const [isModalSwitchEnabled, setModalSwitchEnabled] = useState<boolean>(false);
  const [cores, setCoresData] = useRecoilState(coresAtom);
  const [habits, setHabits] = useState<any[]>([]);
  // const [habitr, setHabit] = useState<string>('');
  const [hasHabitsSelected, setHasHabitsSelected] = useState<boolean>(false);
  const [isModalVisible, setModalVisible] = useState<boolean>(false);
  const userRetrieve = useRecoilValue(userRetrieveAtom);
  const userProfile = userRetrieve.value?.user_profile;

  useEffect(() => {
    logger.debug('line 60 SetHabits.index <MOUNT> |SCREEN| - SET HABITS');

    const fetchAllHabitsByCore = async () => {
      try {
        logger.debug('line 64 SetHabits.index <FETCHING> - [HABITS_BY_CORE]');
        const habitsByCore = await fetchAxios<null, HabitsTypes[]>(
          'GET',
          URL + 'habits/?core=' + core.core_string,
          token,
          null
        )

        const coresCopy = cloneDeep(cores.value)
        let coreCopy = coresCopy?.find((x) => x.core_string === core.core_string,)
        if (!coreCopy) return;

        coreCopy.habits = habitsByCore;
        setAtomManual(setCoresData, coresCopy);
      } catch (error) {
        logger.error('**ERROR** [GET-HABITS_BY_CORE]');
        logger.error('line 80 SetHabits.index [ERROR INFO]: ' + JSON.stringify(error));
      }
    }
    fetchAllHabitsByCore();
  }, []);

  const fetchPrevHabitsByCore: any = async () => {
    try {
      logger.debug('line 88 SetHabits.index <FETCHING> - [PREV-HABITS_BY_CORE]');
      const previousHabits: HabitsTypes[] = await fetchAxios<null, HabitsTypes[]>(
        'GET',
        URL + 'habits/?core=' + core.core_string + '&formed=true',
        token,
        null
      );

      logger.debug('line 96 SetHabits.index previousHabits:' + JSON.stringify(previousHabits));
      return previousHabits;

    } catch (error) {
      logger.error('**ERROR** [GET-PREV-HABITS_BY_CORE]');
      logger.error('line 101 SetHabits.index [ERROR INFO]: ' + JSON.stringify(error));
      return null;
    }
  };

  const [capHabits, setCapHabits] = useState<any[]>([])
  useEffect(() => {
    logger.debug('line 108 SetHabits.index');

    const fillHabits = async (isEdit: boolean) => {
      const clonedCores = cloneDeep(cores.value);
      if (clonedCores) {
        let clonedCore = clonedCores?.find((x) => x.core_string === core.core_string);
        let totalHabits = clonedCore?.habits ?? [];
        logger.debug("line 115 SetHabits.index totalHabits: ", totalHabits);
        let filterHabitsNoSelect: HabitsTypes[] = []
        let filterHabitsYesSelect: HabitsTypes[] = []
        let apiHabits: HabitsTypes[] = []
        try {
          apiHabits = await fetchAxiosNoCache<null, HabitsTypes[]>(
            'GET',
            URL + 'habits/',
            token,
            null
          )

          filterHabitsNoSelect = apiHabits.filter((response: HabitsTypes) => response.core === core.core_string)
          filterHabitsYesSelect = apiHabits.filter((response: HabitsTypes) => response.core === core.core_string && response.selected)
          setCapHabits(filterHabitsYesSelect)
        } catch (error: any) {
          logger.error('line 131 SetHabits.index [ERROR INFO]: ', error.response);
        }
        logger.debug("line 133 SetHabits.index totalHabits: ", totalHabits)
        if (totalHabits.length > 0) {
          const habitsSelected = isEdit ? prevHabits : (await fetchPrevHabitsByCore() ?? []);
          setHasHabitsSelected(habitsSelected);
          let allHabits = totalHabits;

          if (habitsSelected != null || habitsSelected.length > 0) {
            allHabits = totalHabits.map((element) => {
              return ({
                ...element,
                isSelected: habitsSelected.find((x: any) => x.name === element.name) ? true : false
              });
            });
          }
          setHabits(filterHabitsNoSelect);
        } else
          setHabits(filterHabitsYesSelect.length ? filterHabitsYesSelect : filterHabitsNoSelect);
      }
    }
    logger.debug("line 152 SetHabits.index prevHabits: ",prevHabits)
    if (!prevHabits || prevHabits.length == 0)
      fillHabits(false);
    else
      fillHabits(true);

  }, [cores.value]);

  useEffect(() => {
    logger.debug('line 162 SetHabits.index : ' + JSON.stringify(habits), "onBoardingMode: ", onBoardingMode, "habitsRequired: ", habitsRequired, "habitsSelected: ", habitsSelected)
    // ONLY ONBOARDING FLOW
    if (onBoardingMode && habitsRequired !== null && habitsSelected !== null) {
      const result = habits.filter(x => x.selected).length;
      if (result === habitsRequired) {
        habitsSelected();
      }
    }
  }, [habits]);

  const onHabitAdded = async (completedHabit: any) => {
    if (!completedHabit || completedHabit === '') return null;
    try {
      logger.debug('line 175 SetHabits.index ->>>Data to send (new habit): ' + JSON.stringify(completedHabit))
      const item: HabitsCreatedRequest = {
        name: completedHabit.name,
        positive: completedHabit.positive,
        description: completedHabit.description ? completedHabit.description : 'You can edit this field.',
        core: core.core_string,
        favorite: completedHabit.favorite,
      }
      logger.debug('line 183 SetHabits.index item: : ' + JSON.stringify(item));
      logger.info('<FETCHING> - [HABITS]');
      const habitsCreated: HabitsCreatedResponse = await fetchAxios<HabitsCreatedRequest,HabitsCreatedResponse>(
        'POST',
        URL + 'habits/',
        token,
        item,
      );
      const coresCopy = cloneDeep(cores.value);
      let coreCopy = coresCopy?.find((x) => x.core_string === habitsCreated.core);
      if (!coreCopy) return;
      if (!coreCopy.habits) coreCopy.habits = new Array<any>();
      logger.debug('line 196 SetHabits.index habitsCreated', habitsCreated);

      const habitsByUser = await fetchAxios<null, HabitsTypes[]>(
        'GET',
        URL + 'habits/',
        token,
        null,
      );
      coreCopy.habits = habitsByUser;
      logger.debug("line 207 SetHabits.index coreCopy: ", coreCopy);

      setAtomManual(setCoresData, coresCopy);
      setModalVisible(false);
    } catch (error) {
      logger.error('**ERROR** [POST-HABITS]');
      logger.error('line 215 SetHabits.index [ERROR INFO]: ' + JSON.stringify(error));
    }
  }

  const selectHabit = (id: number) => {
    logger.debug('line 218 SetHabits.index (USER ACTION) - Select habit Id:' + id);
    setHabits(habits.map((item) => {
      if (item.id !== id) {
        return item
      }
      return {
        ...item,
        selected: !item.selected,
      }
    }));
    setHasHabitsSelected(habits.indexOf((item: any) => {
      item.selected
    }) != null);
  }

  const getNewDefaultHabit = () => {
    return {
      name: '',
      positive: true,
      description: '',
      core: core.core_string,
      formed: true,
      daysRow: '',
      favorite: false
    }
  }

  const requiredDataByCore = getImageByCore(core.core_string);

  const [selectedHabit, setSelectedHabit] = React.useState<any>(null);
  const [isModalVisibleMorning, setModalVisibleMorning] = React.useState<boolean>(false);
  const submitChanges = async (habit: any) => {

    try {
      logger.debug('line 251 SetHabits.index ->>> Data to send: ' + JSON.stringify(habit))
      const responseApi = await fetchAxios(
        'PUT',
        `${URL}habits/${habit.id}/`,
        token,
        habit,
      )
      logger.debug('line 258 SetHabits.index ->>> Data to send: ' + JSON.stringify(responseApi))

      let restArray = cloneDeep(habits).filter((x) => (x.id !== habit.id));
      setHabits([...restArray, habit]);
    } catch (error) {
      logger.error('**ERROR** [PUT-HABITS]');
      logger.error('line 264 SetHabits.index [ERROR INFO]: ' + JSON.stringify(error));
    }
    setModalVisibleMorning(false);
  }

  const handleHabits = (item: any) => {
    setSelectedHabit(item);
    setModalVisibleMorning(true)
  }
logger.debug("line 273 SetHabits.index habits: ", habits)
  return (
    <>
      {
        isModalVisibleMorning &&
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
          isVisible={isModalVisibleMorning}
          habitInfo={selectedHabit}
          onClickOk={submitChanges}
          onCancel={() => setModalVisibleMorning(false)}
          format={true}
          isNewAdd={true}
          fromMorning={true}
        />
      }
      <ImageBackground
        style={styles.imageBackgroundContainer}
        source={requiredDataByCore.habitScreenBackground}
        resizeMode={'stretch'}>
        <>
          <View style={styles.viewButtonBack}>
            <ButtonBack
              onPress={() => {
                onBoardingMode ? null : pop();
              }}
            />
          </View>
          <View style={styles.containerHeaderSettings}>
            <HeaderSettings
              isIcon={true}
              primaryColor={requiredDataByCore.primaryColor}
              avatarPath={requiredDataByCore.avatarIcon}
              avatarTitlePath={requiredDataByCore.avatarTitle}
              textTitleStyle={[
                fonts.CORE_TITLE,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                },
              ]}
            />
          </View>
          <View style={styles.viewCockpitScreen}>
            <CockpitScreen
              onPress={() => {
                null
              }}
            />
          </View>
          <View style={[styles.viewElements, styles.marginTopTitle]}>
            {/* TITLE AND BUTTON FLOAT ADD HABITS */}
            <View style={styles.viewTitleText}>
              <Text
                style={[
                  styles.textTitle,
                  fonts.CORE_HABIT_TITLE,
                  { color: palette.TEXT_PRIMARY },
                ]}>
                {strings.TITLE}
              </Text>
              <TouchableOpacity
                disabled={onBoardingMode && isLastTab}
                style={styles.touchableOpacityImageButtonAdd}
                onPress={() => {
                  setModalVisible(true);
                }}>
                <Image
                  style={styles.imageButtonAdd}
                  source={require('../../../assets/images/set_habits/button_add.png')}
                  resizeMode={'contain'}
                />
              </TouchableOpacity>
            </View>
            <View style={styles.viewListsHabits}>
              <View style={styles.viewListHabitsNegative}>
                <View style={styles.viewTextListsHabitsHeader}>
                  <Text
                    style={[
                      styles.textListsHabitsHeader,
                      fonts.CORE_HABIT_LIST_HEADER,
                      { color: palette.TEXT_QUATERNARY },
                    ]}>
                    {strings.NEGATIVE}
                  </Text>
                </View>
                <ScrollView horizontal>
                  <FlatList
                    data={habits.filter((x) => !x.positive)}
                    scrollEnabled={true}
                    showsVerticalScrollIndicator={false}
                    bounces={false}
                    renderItem={({ item }) => (
                      <>
                        <ListItemHabit
                          touchableOpacityContainerStyle={[
                            styles.viewTextListItemHabit,
                            (item.isSelected || item.selected) &&
                            styles.viewTextListItemHabitSelected,
                          ]}
                          touchableOpacityContainerOnPress={() => {
                            selectHabit(item.id)
                          }}
                          touchableOpacityContainerOnLongPress={() => handleHabits(item)}
                          textTitle={item.name}
                          textTitleStyle={[
                            styles.textListItemHabit,
                            fonts.CORE_HABIT_LIST_ITEM,
                            { color: palette.TEXT_QUATERNARY },
                          ]}
                        />
                      </>
                    )}
                    keyExtractor={(_, index) => index.toString()}
                  />
                </ScrollView>
              </View>
              <View style={styles.viewListHabitsPositive}>
                <View style={styles.viewTextListsHabitsHeader}>
                  <Text
                    style={[
                      styles.textListsHabitsHeader,
                      fonts.CORE_HABIT_LIST_HEADER,
                      { color: palette.TEXT_QUATERNARY },
                    ]}>
                    {strings.POSITIVE}
                  </Text>
                </View>
                <ScrollView horizontal>
                  <FlatList
                    data={habits.filter((x) => x.positive)}
                    scrollEnabled={true}
                    showsVerticalScrollIndicator={false}
                    bounces={false}
                    renderItem={({ item }) => (
                      <>
                        <ListItemHabit
                          touchableOpacityContainerStyle={[
                            styles.viewTextListItemHabit,
                            (item.isSelected || item.selected) &&
                            styles.viewTextListItemHabitSelected,
                          ]}
                          touchableOpacityContainerOnPress={() => {
                            selectHabit(item.id)
                          }}
                          touchableOpacityContainerOnLongPress={() => handleHabits(item)}
                          textTitle={item.name}
                          textTitleStyle={[
                            styles.textListItemHabit,
                            fonts.CORE_HABIT_LIST_ITEM,
                            { color: palette.TEXT_QUATERNARY },
                          ]}
                        />
                      </>
                    )}
                    keyExtractor={(_, index) => index.toString()}
                  />
                </ScrollView>
              </View>
            </View>
          </View>
          <View style={styles.viewScoreProgress}>
            <ScoreProgress
              actualValue={core.core_power ?? 0}
              possibleValue={userProfile?.user_core_cap ?? 0}
              textTitle={strings.SCORE}
              textTitleStyle={[
                fonts.CORE_HABIT_TITLE,
                { color: palette.TEXT_PRIMARY },
              ]}
            />
          </View>
          <View style={[styles.viewContinueButton, (onBoardingMode && !isLastTab) ? styles.lowOpacity : null]}>
            <Button
              touchableOpacityContainerStyle={{
                paddingHorizontal: vw(5),
                paddingVertical: vh(1.25),
                backgroundColor: palette.SUCCESS,
                borderRadius: vw(10),
                borderWidth: vw(0.5),
                borderColor: palette.BUTTON_BORDER,
              }}
              textTitle={strings.BUTTON}
              textTitleStyle={[
                fonts.BUTTON_MEDIUM,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                },
              ]}
              disabled={!hasHabitsSelected || (onBoardingMode && !isLastTab)}
              onPress={() => {
                onBoardingMode ?
                  navigateToStepSix({
                    habits: habits,
                    core: core,
                    score: core.core_power ?? 0
                  })
                  :
                  replace('CheckHabits', {
                    habits: habits,
                    core,
                  })
              }}
            />
          </View>
        </>
        {isModalVisible &&
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
            isNewAdd={true}
            habitInfo={getNewDefaultHabit()}
            onClickOk={onHabitAdded}
            onCancel={() => { setModalVisible(false) }}
            format={true}
          />
        }
      </ImageBackground>
    </>
  )
}
