import React, { useState } from 'react'
import {
  Image,
  ImageBackground,
  Text,
  TouchableOpacity,
  View,
} from 'react-native'
import { useRecoilState, useRecoilValue } from 'recoil'

import ModalAdd from '../../../components/ModalAdd'
import Button from '../../../components/Button'
import ButtonBack from '../../../components/ButtonBack'
import CockpitScreen from '../../../components/CockpitScreen'
import ScoreProgress from '../../../components/ScoreProgress'
import { vh, vw } from '../../../helpers/dimensions'
import { fetchAxios } from '../../../helpers/axios'
import { setAtomManual } from '../../../helpers/recoil'
import { localDataAtom, storageAtom, coresAtom, userRetrieveAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { cloneDeep } from 'lodash'
import { Grayscale } from 'react-native-color-matrix-image-filters'
import { URL } from '../../../helpers/api'
import HeaderSettings from '../../../components/HeaderSettings'
import { getImageByCore } from '../../../helpers/internalDataManagement'
import { HabitsCreatedRequest, HabitsTypes } from '../../../typescript/main'
import { logger } from '../../../helpers/logger'

export default ({
  navigation: { navigate, goBack, replace },
  route: {
    params: { core },
  },
}: props) => {
  const {
    value: { fonts, palette, token },
  } = useRecoilValue(storageAtom)

  const [habit, setHabit] = useState<string>('');
  const [isModalVisible, setModalVisible] = useState<boolean>(false);
  const [isModalSwitchEnabled, setModalSwitchEnabled] = useState<boolean>(false);
  const [localData, setLocalData] = useRecoilState(localDataAtom);

  const [cores, setCoresData] = useRecoilState(coresAtom);
  const userRetrieve = useRecoilValue(userRetrieveAtom);
  const userProfile = userRetrieve.value?.user_profile;

  const disableAvailable =
    localData.value.morningCheckInStarted &&
    localData.value.lastMorningCheckInCompleted == null &&
    localData.value.currentCheckin === 'morning';

  const onPress = () => {
    logger.debug('line 56 SetHabits.index -> (USER ACTION) - INACTIVATE CORE: ' + core.core_string);
    const storageCopy = cloneDeep(localData.value ?? [])

    const coreIndex = storageCopy.coreInfo.findIndex(
      (currentCore) => currentCore.core_string === core.core_string,
    )

    if (coreIndex >= 0) {
      storageCopy.coreInfo[coreIndex].enabled = false
    }

    setLocalData({
      init: true,
      value: storageCopy,
    })

    const coreCopy = cloneDeep(core);
    coreCopy.enabled = false;

    replace('InitHabits', { core: coreCopy })
  }

  const onHabitAdded = async () => {
    setModalVisible(false);

    if (!habit || habit === '') return null

    try {
      const item: HabitsCreatedRequest = {
        name: habit,
        positive: isModalSwitchEnabled
          ? strings.MODAL_SWITCH_POSITIVE.toUpperCase() === 'POSITIVE'
          : strings.MODAL_SWITCH_NEGATIVE.toUpperCase() === 'NEGATIVE',
        description: `${habit} description`,
        core: core.core_string,
        favorite: false
      }

      logger.debug('line 93 SetHabits.index <FETCHING> - [HABITS] item: ', item);
      const habitCreated: HabitsTypes = await fetchAxios<HabitsCreatedRequest, HabitsTypes>(
        'POST',
        URL + 'habits/',
        token,
        item,
      );
      logger.debug('line 93 SetHabits.index data: ', habitCreated);
      const coresCopy = cloneDeep(cores.value);
      let coreCopy = coresCopy?.find((x) => x.core_string === habitCreated.core);
      if (!coreCopy) return;
      if (!coreCopy.habits) coreCopy.habits = new Array<any>();

      const habitsByUser: HabitsTypes[] = await fetchAxios<null, HabitsTypes[]>(
        'GET',
        URL + 'habits/',
        token,
        null,
      );
      coreCopy.habits = habitsByUser;
      logger.debug("line 118 SetupHabits.index coreCopy: ", coreCopy);
      setAtomManual(setCoresData, coresCopy);
      setHabit('');
    } catch (error) {
      logger.error('**ERROR** [POST-HABITS]');
      logger.error('line 123 SetupHabits.index [ERROR INFO]: ' + JSON.stringify(error));
    }
  }

  const requiredDataByCore = getImageByCore(core.core_string);

  return (
    <>
      <ImageBackground
        style={styles.imageBackgroundContainer}
        source={requiredDataByCore.habitScreenBackground}
        resizeMode={'stretch'}>
        <>
          <View style={styles.viewButtonBack}>
            <ButtonBack onPress={goBack} />
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
            {/** Check if this option when onPress is null */}
            <CockpitScreen
              onPress={() => {
                null
              }}
            />
          </View>

          <TouchableOpacity
            style={styles.touchableOpacityButtonPower}
            onPress={onPress}>
            <Image
              style={styles.imageButtonPower}
              source={require('../../../assets/images/habits/button_on.png')}
              resizeMode={'contain'}
            />
          </TouchableOpacity>
          <TouchableOpacity
            style={styles.touchableOpacityButtonPower}
            onPress={onPress}
            disabled={!disableAvailable}>
            <Grayscale amount={disableAvailable ? 0 : 1}>
              <Image
                style={styles.imageButtonPower}
                source={require('../../../assets/images/habits/button_on.png')}
                resizeMode={'contain'}
              />
            </Grayscale>
          </TouchableOpacity>

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

          <View style={styles.viewElements}>
            <View style={styles.viewButton}>
              <Button
                touchableOpacityContainerStyle={{
                  paddingHorizontal: vw(3.5),
                  paddingVertical: vh(1.75),
                  backgroundColor: palette.TEXT_PRIMARY,
                  borderRadius: vw(10),
                }}
                textTitle={strings.BUTTON_SET_HABITS}
                textTitleStyle={[
                  fonts.CORE_HABIT_TITLE_LOW_PRIORITY,
                  {
                    color: palette.MINDSET,
                    textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                  },
                ]}
                onPress={() => {
                  navigate('SetHabits', { core })
                }}
              />
            </View>

            <Text
              style={[
                styles.textOr,
                fonts.CORE_HABIT_TITLE_LOW_PRIORITY,
                { color: palette.TEXT_PRIMARY },
              ]}>
              {strings.TEXT_OR}
            </Text>

            <View style={styles.viewButton}>
              <Button
                touchableOpacityContainerStyle={{
                  paddingHorizontal: vw(3.5),
                  paddingVertical: vh(1.75),
                  backgroundColor: palette.TEXT_PRIMARY,
                  borderRadius: vw(10),
                }}
                textTitle={strings.BUTTON_ADD_HABITS}
                textTitleStyle={[
                  fonts.CORE_HABIT_TITLE_LOW_PRIORITY,
                  {
                    color: palette.TEXT_QUATERNARY,
                    textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                  },
                ]}
                onPress={() => {
                  setModalVisible(true);
                }}
              />
            </View>
          </View>
        </>

        <ModalAdd
          textTitle={strings.MODAL_ADD_HABIT}
          textTitleStyle={[fonts.MODAL_TITLE, { color: palette.TEXT_PRIMARY }]}
          textInput={habit}
          textInputStyle={[
            fonts.CORE_HABIT_TITLE,
            styles.textInputModal,
            { color: palette.TEXT_PRIMARY },
          ]}
          textInputOnChangeText={setHabit}
          textSwitchOff={strings.MODAL_SWITCH_NEGATIVE}
          textSwitchOn={strings.MODAL_SWITCH_POSITIVE}
          textSwitchStyle={[fonts.SWITCH, { color: palette.TEXT_TERTIARY }]}
          switchTrackColor={{
            true: palette.BUTTON_BORDER,
            false: palette.TEXT_TERTIARY,
          }}
          switchThumbColor={palette.TEXT_TERTIARY}
          switchIsEnabled={isModalSwitchEnabled}
          switchOnChange={(enabled: boolean) => {
            setModalSwitchEnabled(enabled)
          }}
          touchableOpacityButtonImage={
            <Image
              style={styles.imageButtonModal}
              source={require('../../../assets/images/shared/button_confirm.png')}
              resizeMode={'cover'}
            />
          }
          touchableOpacityButtonStyle={{}}
          touchableOpacityButtonOnPress={onHabitAdded}
          isVisible={isModalVisible}
        />
      </ImageBackground>
    </>
  )
}
