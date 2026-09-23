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
import { setAtomAxios } from '../../../helpers/recoil'
import { localDataAtom, storageAtom, userInfoAtom, userRetrieveAtom, mantraAtom, coresAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { cloneDeep } from 'lodash'
import LinearGradient from 'react-native-linear-gradient'
import MaskedView from '@react-native-community/masked-view'
import { getImageByCore } from '../../../helpers/internalDataManagement'
import HeaderSettings from '../../../components/HeaderSettings'
import { CheckinHabits, Core, CoreInfo, HabitsTypes, Mantra } from '../../../typescript/main'
import { fetchAxios, fetchAxiosNoCache } from '../../../helpers/axios'
import { URL } from '../../../helpers/api'
import { getNextPrev } from '../../../helpers/commonHelper'
import { MenuProvider } from 'react-native-popup-menu'
import PopupMenu from '../../../components/PopupMenu'
import ModalMantra from '../../../components/ModalMantra'
import { logger } from '../../../helpers/logger'

export default ({
  navigation: { navigate, goBack, replace },
  onBoardingMode,
  isLastTab,
  navigateToNextStep,
  lastStep,
  route: {
    params: { habits, core, score },
  },
}: props) => {
  logger.info("[<CheckHabits>]")
  logger.debug("line 50 CheckHabits.index route.params.habits: ", habits, "core: ", core, "score: ", score)
  const {
    value: { token, onboarding_pendingpost },
  } = useRecoilValue(storageAtom);
  const [storage, setStorage] = useRecoilState(storageAtom);
  const userInfo = useRecoilValue(userInfoAtom);
  const coresAtoms = useRecoilValue(coresAtom);
  const [localData, setLocalData] = useRecoilState(localDataAtom);
  const fonts = storage.value.fonts;
  const palette = storage.value.palette;
  const [selectedNumber, setSelectedNumber] = useState<number>(score ?? 3);
  const [userProfile, setUserProfileLocal] = useRecoilState(userRetrieveAtom);
  const [currentCore, setCurrentCore] = useState(core);
  const [currentHabits, setCurrentHabits] = useState(habits && habits.length ? habits.filter((x) => x.selected) : []);
  const [allHabits, setAllHabits] = useState<any[]>([]);

  const isMorningCheckin =
    localData.value.morningCheckInStarted &&
    localData.value.lastMorningCheckInCompleted == null &&
    localData.value.openCheckin &&
    core.openCheckin &&
    localData.value.currentCheckin === 'morning';

  useEffect(() => {
    (async () => {
      try {
        let apiHabits: HabitsTypes[] = await fetchAxiosNoCache<null, HabitsTypes[]>(
          'GET',
          URL + 'habits/',
          token,
          null
        )
        logger.debug("line 82 CheckingHabits.index apiHabits: ", apiHabits)
        setAllHabits(apiHabits)
        let filterHabitsYesSelect = apiHabits.filter((response: any) => response.core === core.core_string && response.selected)

        if (!localData.value.openCheckin && !habits.length) setCurrentHabits(filterHabitsYesSelect)
        if (localData.value.openCheckin && !localData.value.morningCheckInStarted && !habits.length) setCurrentHabits(filterHabitsYesSelect)
        if (!localData.value.openCheckin && habits.length) setCurrentHabits(habits.filter((response: any) => response.selected))
      } catch (error: any) {
        logger.error("line 89 CheckingHabits.index error getting habits", error.response);
      }
    })()
  }, [habits])

  useEffect(() => {
    logger.debug('line 95 CheckingHabits.index <MOUNT> |SCREEN| - CHECK HABITS: ', core);
    let resultCore: CoreInfo = core;
    const fetchAndUpdateMomentumData = async () => {
      try {
        logger.debug('<FETCHING> - [CORES_BY_USER]');
        const coresByUserResult: Core[] = await fetchAxiosNoCache<null, Core[]>(
          'GET',
          URL + 'cores/user/',
          token,
          null
        );
        logger.debug("line 106 CheckingHabits.index coresByUserResult: ", coresByUserResult.find((x: any) => x.core_string === core.core_string))
      } catch (error) {
        logger.error('CheckHabits.index Get cores by user error: ' + JSON.stringify(error));
      }

      if (core.lastMorningCheckIn && (!core.morningCheckInHabits || core.morningCheckInHabits.length <= 0)) {
        try {
          logger.debug('<FETCHING> - [PREV-HABITS_BY_CORE]');
          const previousHabits: HabitsTypes[] = await fetchAxios<null, HabitsTypes[]>(
            'GET',
            URL + 'habits/?core=' + core.core_string + '&formed=true',
            token,
            null
          );
          logger.debug('line 124 CheckingHabits.index previousHabits: ' + JSON.stringify(previousHabits));
          const previousCheckinHabits: CheckinHabits[] = previousHabits.map(habit => ({
            id: habit.id,
            title: habit.name,
            isSelected: habit.selected,
            type: habit.core,
          }));
          const auxCore = { ...resultCore, morningCheckInHabits: previousCheckinHabits ?? [] };
          logger.debug('line 126 CheckingHabits.index auxCore: ' + JSON.stringify(auxCore));
          setCurrentCore(auxCore);
        } catch (error) {
          logger.debug('**ERROR** [GET-PREV-HABITS_BY_CORE]');
          logger.error('[ERROR INFO]: ' + JSON.stringify(error));
        }
      }
      else
        setCurrentCore(resultCore);
    }

    fetchAndUpdateMomentumData();
  }, []);

  const isNightCheckin =
    localData.value.nightCheckInStarted &&
    localData.value.lastNightCheckInCompleted == null &&
    localData.value.currentCheckin === 'night' &&
    localData.value.openCheckin &&
    core.openCheckin &&
    core.lastMorningCheckIn != null;

  const confirmHabits = () => {
    logger.debug('---> CONFIRM HABITS PROCESS <---');
    const storageCopy = cloneDeep(localData.value ?? [])

    if (isMorningCheckin || isNightCheckin || onBoardingMode) {

      const coreIndex = storageCopy.coreInfo.findIndex(
        (currentCore) => currentCore.core_string === core.core_string,
      )

      let modifiedCore: any

      if (coreIndex >= 0) {
        modifiedCore = storageCopy.coreInfo[coreIndex]

      } else {
        modifiedCore = {
          core_string: core.core_string,
        }
        storageCopy.coreInfo.push(modifiedCore)
      }

      if (isNightCheckin) {
        logger.debug('line 185 CheckingHabits.index selectedNumber ' + selectedNumber)
        modifiedCore.nightCheckInScore = selectedNumber;
        modifiedCore.lastNightCheckIn = Date.now();
      } else {
        modifiedCore.morningCheckInHabits = habits;
        modifiedCore.lastMorningCheckIn = Date.now();
      }
      logger.debug("line 192 CheckingHabits.index ", habits);
      logger.debug("line 193 CheckingHabits.index storageCopy: ", storageCopy);
      logger.debug("line 195 CheckingHabits.index storageCopy.coreInfo.filter: ",JSON.stringify(storageCopy.coreInfo.filter((currentCore: any) => currentCore.core_string === core.core_string)));
      habits.map(async (response: any) => {
        try {
          logger.debug("line 197 CheckingHabits.index response: ", response)
          await fetchAxios(
            'PATCH',
            URL + `habits/${response.id}/`,
            token,
            { selected: response.selected },
          )
        } catch (error: any) {
          logger.error("Update habits by Id error: ", error.response);
        }
      })

      logger.debug('-> line 208 CheckingHabits.index UPDATING LOCAL DATA');
      setLocalData({
        init: true,
        value: storageCopy,
      })
    }
    logger.debug('-> line 205 CheckingHabits.index onBoardingMode: ', onBoardingMode);
    if (!onBoardingMode) {
      if (isMorningCheckin) {
        const filterCore = storageCopy.coreInfo.filter((response: any) => response.core_string !== core.core_string && !response.lastMorningCheckIn && response.openCheckin)
        if (filterCore.length) {
          const habits = allHabits.filter((response: any) => response.core === filterCore[0].core_string)
          logger.debug("line 200 CheckHabits.index habits: ", habits);
          replace('SetHabits', {
            prevHabits: habits,
            core: filterCore[0],
          })
        } else navigate('DashboardStackScreen');
      } else navigate('DashboardStackScreen');
    }
    else navigateToNextStep();
  }

  logger.debug('line 222 CheckingHabits.index habits: ', JSON.stringify(habits));
  const requiredDataByCore = getImageByCore(core.core_string);
  const goToDashboard = () => {
    logger.debug('line 225 CheckingHabits.index habits: ');
    navigate('DashboardStackScreen', {
      screen: 'Cores',
    })
  }

  const [mantra, setMantra] = useRecoilState(mantraAtom)
  const [mantraState, setMantraState] = useState<Mantra | null>(null)
  useEffect(() => {
    setMantraState(mantra.value)
  }, [setMantraState, mantra.value])
  const [isModalMantraVisible, setModalMantraVisible] = useState<boolean>(false)
  const updateMantraState = (text: string) => setMantraState({ ...mantraState!, mantra: text })

  const saveMantra = () => {
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
  logger.debug("line 251 CheckHabits.index onBoardingMode: ", onBoardingMode, "\nallHabits: ", allHabits, "\nisMorningCheckin: ", isMorningCheckin, "\nhabits: ", habits, "\ncore: ", core)
  return (
    <>
      <MenuProvider skipInstanceCheck={true}>
        <ImageBackground
          style={styles.imageBackgroundContainer}
          source={requiredDataByCore.habitScreenBackground}
          resizeMode={'stretch'}>
          <>
            <View style={styles.viewButtonBack}>
              <ButtonBack onPress={() => { onBoardingMode && allHabits.length > 0 ? navigateToNextStep({
                    habits: habits,
                    core: core,
                    score: core.core_power ?? 0
                  }) : goToDashboard() }} />
            </View>
            <View style={styles.containerHeaderSettings}>
              <HeaderSettings
                isIcon={true}
                primaryColor={requiredDataByCore.primaryColor}
                avatarPath={requiredDataByCore.avatarIcon}
                avatarTitlePath={requiredDataByCore.avatarTitle}
                leftArrowNavigation={onBoardingMode ? () => { } : getNextPrev(core.core_string, navigate).prevCore}
                rightArrowNavigation={onBoardingMode ? () => { } : getNextPrev(core.core_string, navigate).nextCore}
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
                onPress={() => setModalMantraVisible(true)}
              />
            </View>

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

            {
              ((!onBoardingMode) || (onBoardingMode && lastStep)) &&
              <View style={styles.viewContinueButton}>
                <Button
                  disabled={!(currentHabits && currentHabits.length > 0)}
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
                  onPress={confirmHabits}
                />
              </View>
            }
            <View style={styles.viewScoreProgress}>
              <ScoreProgress
                actualValue={currentCore.core_power ?? 0}
                possibleValue={userProfile.value?.user_profile.user_core_cap ?? 0}
                textTitle={strings.SCORE}
                textTitleStyle={[
                  fonts.CORE_HABIT_TITLE,
                  { color: palette.TEXT_PRIMARY },
                ]}
              />
            </View>
            <View style={[styles.viewElements, styles.marginTopTitle]}>
              <View style={styles.marginTopText}>
                <Text
                  style={[
                    styles.textTitle,
                    fonts.CORE_HABIT_TITLE,
                    { color: palette.TEXT_PRIMARY },
                  ]}>
                  {strings.TITLE}
                </Text>
              </View>

              {/* The button edit only can showed in the morning and when have habits */}
              {(isMorningCheckin && !isNightCheckin && habits && currentHabits.length > 0) &&
                <TouchableOpacity
                  style={[styles.touchableOpacityImageButtonPencil]}
                  onPress={() => {
                    replace('SetHabits', {
                      prevHabits: currentHabits,
                      core,
                    })
                  }}>
                  <Image
                    style={styles.imageButtonPencil}
                    source={require('../../../assets/images/check_habits/button_pencil.png')}
                    resizeMode={'contain'}
                  />
                </TouchableOpacity>
              }
              {/* The habits list show if you hhave previous habits loaded */}
              {habits && currentHabits.length > 0 ?
                <MaskedView
                  style={[
                    isNightCheckin ? styles.flatList : styles.flatListExtended,
                    styles.flatListOffset,
                  ]}
                  maskElement={
                    <LinearGradient
                      colors={['#ffffff00', '#000', '#000', '#ffffff00']}
                      locations={[0, 0.15, 0.85, 1]}
                      style={styles.fullHeight}
                    />
                  }>
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
                          data={currentHabits.filter((x) => !x.positive)}
                          scrollEnabled={true}
                          showsVerticalScrollIndicator={false}
                          bounces={false}
                          renderItem={({ item }) => (
                            <>
                              <PopupMenu
                                onClickOk={() => { }}
                                detail={item.description}>
                                <ListItemHabit
                                  touchableOpacityContainerStyle={[
                                    styles.viewTextListItemHabit,
                                    item.isSelected || item.selected &&
                                    styles.viewTextListItemHabitSelected,
                                  ]}
                                  touchableOpacityContainerOnPress={() => { }}
                                  textTitle={item.name}
                                  disabled={true}
                                  textTitleStyle={[
                                    styles.textListItemHabit,
                                    fonts.CORE_HABIT_LIST_ITEM,
                                    { color: palette.TEXT_QUATERNARY },
                                  ]}
                                />
                              </PopupMenu>
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
                          data={currentHabits.filter((x) => x.positive)}
                          scrollEnabled={true}
                          showsVerticalScrollIndicator={false}
                          bounces={false}
                          renderItem={({ item }) => (
                            <>
                              <PopupMenu
                                onClickOk={() => { }}
                                detail={item.description}>
                                <ListItemHabit
                                  touchableOpacityContainerStyle={[
                                    styles.viewTextListItemHabit,
                                    item.isSelected || item.selected &&
                                    styles.viewTextListItemHabitSelected,
                                  ]}
                                  touchableOpacityContainerOnPress={() => { }}
                                  textTitle={item.name}
                                  disabled={true}
                                  textTitleStyle={[
                                    styles.textListItemHabit,
                                    fonts.CORE_HABIT_LIST_ITEM,
                                    { color: palette.TEXT_QUATERNARY },
                                  ]}
                                />
                              </PopupMenu>
                            </>
                          )}
                          keyExtractor={(_, index) => index.toString()}
                        />
                      </ScrollView>
                    </View>
                  </View>
                </MaskedView>
                : <>
                  {/* The button edit only can showed in the morning and when have not habits */}
                  {(isMorningCheckin || onBoardingMode) &&
                    <>
                      <View style={styles.viewButton}>
                        <Button
                          touchableOpacityContainerStyle={[styles.buttonSetHabitsContainer, { backgroundColor: palette.TEXT_PRIMARY }]}
                          textTitle={strings.BUTTON_SET_HABITS}
                          textTitleStyle={[
                            fonts.CORE_HABIT_TITLE_LOW_PRIORITY,
                            {
                              color: requiredDataByCore.primaryColor,
                              textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                            },
                          ]}
                          onPress={() => {
                            onBoardingMode ?
                              navigateToNextStep({
                                prevHabits: habits,
                                core,
                              }) :
                              replace('SetHabits', {
                                prevHabits: habits,
                                core,
                              })
                          }}
                        />
                      </View>
                    </>
                  }
                </>
              }
            </View>
          </>
        </ImageBackground>
      </MenuProvider>
    </>
  )
}
