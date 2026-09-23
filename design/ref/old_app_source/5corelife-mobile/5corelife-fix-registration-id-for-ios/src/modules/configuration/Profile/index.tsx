import React, { useState } from 'react'
import {
  Image,
  ImageBackground,
  Text,
  View,
  ScrollView,
} from 'react-native'
import { useRecoilValue, useRecoilState, useResetRecoilState } from 'recoil'

import HeaderSettings from '../../../components/HeaderSettings'
import ButtonSettings from '../../../components/ButtonSettings'
import { storageAtom, userInfoAtom, localDataAtom, coresAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import HeaderDots from '../../../components/HeaderDots'
import { clearStorageData, getAllItems } from '../../../helpers/storage'
import { vh, vw } from '../../../helpers/dimensions';
import { fetchAxiosNoCache } from '../../../helpers/axios'
import { URL } from '../../../helpers/api'
import ModalOkCancel from '../../../components/ModalOkCancel'
import { ImprovementsUser } from '../../../typescript/main'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, goBack } }: props) => {
  const {
    value: { fonts, palette, }
  } = useRecoilValue(storageAtom)

  const resetCoresState = useResetRecoilState(coresAtom);
  const [localState, setLocalState] = useRecoilState(localDataAtom)
  const [storageState, setstorageState] = useRecoilState(storageAtom)
  const [userState, setuserState] = useRecoilState(userInfoAtom)
  const [coresState, setCoresState] = useRecoilState(coresAtom)

  const [isModalVisible, setModalVisible] = useState<boolean>(false);

  const getAsyncStorage = async () => {
    try {
      await clearStorageData();
      setModalVisible(false);
      const items = await getAllItems();
      if (items?.length === 0) {
        setCoresState({
          init: false,
          isLoading: false,
          request: null,
          value: null,
          error: null,
        })
        setstorageState({
          init: false,
          value: {
            fonts: storageState?.value?.fonts,
            onboarding: storageState?.value?.onboarding,
            palette: storageState?.value?.palette,
            token: '',
            onboarding_pendingpost: false
          }
        });
        setuserState({
          init: false,
          value: {
            lastLogin: 0,
            showAllCores: userState?.value?.showAllCores
          }
        })
        setLocalState({
          init: false,
          value: {
            lastMorningCheckInCompleted: null,
            lastNightCheckInCompleted: null,
            coreInfo: [
              {
                core_power: 10,
                core_string: "EMOTIONAL_HEALTH",
                enabled: false,
                lastMorningCheckIn: null,
                morningCheckInHabits: [],
                lastNightCheckIn: null,
                nightCheckInScore: null,
                openCheckin: false
              },
              {
                core_power: 0,
                core_string: "MINDSET",
                enabled: false,
                // user: 65,
                lastMorningCheckIn: null,
                morningCheckInHabits: [],
                lastNightCheckIn: null,
                nightCheckInScore: null,
                openCheckin: false
              },
              {
                core_power: 0,
                core_string: "CAREER_FINANCES",
                enabled: false,
                // user: 65,
                lastMorningCheckIn: null,
                morningCheckInHabits: [],
                lastNightCheckIn: null,
                nightCheckInScore: null,
                openCheckin: false
              },
              {
                core_power: 0,
                core_string: "RELATIONSHIPS",
                enabled: false,
                // user: 65,
                lastMorningCheckIn: null,
                morningCheckInHabits: [],
                lastNightCheckIn: null,
                nightCheckInScore: null,
                openCheckin: false
              },
              {
                core_power: 0,
                core_string: "PHYSICAL_HEALTH",
                enabled: false,
                // user: 65,
                lastMorningCheckIn: null,
                morningCheckInHabits: [],
                lastNightCheckIn: null,
                nightCheckInScore: null,
                openCheckin: false
              }
            ],
            morningCheckInStarted: false,
            nightCheckInStarted: false,
            currentCheckin: null,
            openCheckin: false,
            lastStart: null,
            improvements: [],
            onboarding: false,
            secondDaysJourney: false
          }
        })
      }
    } catch (error) {
      logger.error("Clear Storage data error: ", error);
    }
  }

  const [state, setstate] = useState<any>()
  const [improvement, setImprovement] = useState<number>()
  React.useEffect(() => {
    (async () => {
      try {
        const { value: { token } } = storageState
        const information = await fetchAxiosNoCache(
          'GET',
          URL + 'users/profile/',
          token,
          null
        )
        const improvements: ImprovementsUser[] = await fetchAxiosNoCache<null, ImprovementsUser[]>(
          'GET',
          URL + 'improvements/user/',
          token,
          null
        )
        setImprovement(improvements.length - 3)
        setstate(information);
      } catch (error: any) {
        logger.error("Get User Profile error: ", error);
      }
    })()
  }, [])

  return (
    <>
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/settings/background.png')}
        resizeMode={'cover'}>
        <ScrollView>
          <View style={styles.containerSub}>
            <ModalOkCancel
              textTitle={strings.TEXT_LOGOUT}
              textTitleStyle={[fonts.MODAL_TITLE,
              { color: palette.TEXT_PRIMARY, fontSize: vw(5.4), marginTop: vh(21.3) }
              ]}
              okButtonImage={
                <Image
                  style={styles.buttons}
                  source={require('../../../assets/images/shared/button_ok.png')}
                  resizeMode={'cover'}
                />
              }
              cancelButtonImage={
                <Image
                  style={styles.buttons}
                  source={require('../../../assets/images/shared/button_cancel.png')}
                  resizeMode={'cover'}
                />
              }
              onCancel={() => setModalVisible(false)}
              onOk={() => getAsyncStorage()}
              isVisible={isModalVisible}
            />

            <HeaderDots
              dotsCount={3}
              activeDotIndex={2}
              onBackButton={() => { navigate('Cores') }}
            />

            <HeaderSettings
              title={strings.TITLE}
              textTitleStyle={[
                fonts.CORE_TITLE,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                },
              ]}
              leftArrowNavigation={() => { navigate('Storage') }}
            />

            <View
              style={[
                styles.containerCardQuest,
                {
                  backgroundColor: palette.SETTINGS_CARD_BACKGROUND,
                  borderColor: palette.SETTINGS_CARD_BORDER
                }
              ]}>
              <View style={styles.containerCardQuestTextHeader}>
                <Text
                  style={[
                    styles.textQuestHeader,
                    fonts.PROFILE_USER_NAME,
                    { color: palette.TEXT_PRIMARY }
                  ]}>
                  {state?.username}
                </Text>
              </View>
              <View style={styles.containerCardQuestImageLine}>
                <Image
                  style={styles.imageCardQuestLine}
                  source={require('../../../assets/images/storage/line.png')}
                  resizeMode={'contain'}
                />
              </View>
              <View style={styles.viewUserDetails}>
                <View style={styles.viewUserDetail}>
                  <Image
                    style={styles.imageIconUserDetail}
                    source={require('../../../assets/images/shared/icon_score.png')}
                    resizeMode={'contain'}
                  />
                  <Text
                    style={[
                      styles.textQuestDescription,
                      fonts.PROFILE_CARD_CATEGORY,
                      { color: palette.TEXT_PRIMARY }
                    ]}
                    numberOfLines={2}>
                    {strings.CARD_MOMENTUM_SCORE}
                  </Text>
                  <Text
                    style={[
                      styles.textQuestDescription,
                      { color: palette.TEXT_PRIMARY }
                    ]}>
                    <Text style={fonts.PROFILE_CARD_CATEGORY_PERCENTAGE}>
                      {'% '}
                    </Text>
                    <Text style={fonts.PROFILE_CARD_CATEGORY}>{state?.user_profile?.momentum ? Math.round(state?.user_profile?.momentum) : 0}</Text>
                  </Text>
                </View>
                <View style={styles.viewUserDetail}>
                  <Image
                    style={styles.imageIconUserDetail}
                    source={require('../../../assets/images/shared/icon_rocket.png')}
                    resizeMode={'contain'}
                  />
                  <Text
                    style={[
                      styles.textQuestDescription,
                      fonts.PROFILE_CARD_CATEGORY,
                      { color: palette.TEXT_PRIMARY }
                    ]}>
                    {strings.CARD_UPGRADES}
                  </Text>
                  <Text
                    style={[
                      styles.textQuestDescription,
                      fonts.PROFILE_CARD_CATEGORY,
                      { color: palette.TEXT_PRIMARY }
                    ]}>
                    {improvement}
                  </Text>
                </View>

                <View style={styles.viewUserDetail}>
                  <Image
                    style={styles.imageIconUserDetail}
                    source={require('../../../assets/images/shared/icon_streak.png')}
                    resizeMode={'contain'}
                  />
                  <Text
                    style={[
                      styles.textQuestDescription,
                      fonts.PROFILE_CARD_CATEGORY,
                      { color: palette.TEXT_PRIMARY }
                    ]}>
                    {strings.QUEST_DESCRIPTION}
                  </Text>
                  <Text
                    style={[
                      styles.textQuestDescription,
                      fonts.PROFILE_CARD_CATEGORY,
                      { color: palette.TEXT_PRIMARY }
                    ]}>
                    {state?.user_profile?.night_checks_in_row ? state?.user_profile?.night_checks_in_row : 0}
                  </Text>
                </View>
              </View>
            </View>

            <View style={styles.viewButtonsSettings}>
              <View style={styles.viewButtonSettings}>
                <ButtonSettings
                  touchableOpacityContainerStyle={[
                    styles.buttonSettings,
                    {
                      backgroundColor: palette.SETTINGS_CARD_BACKGROUND,
                      borderColor: palette.SETTINGS_CARD_BORDER
                    }
                  ]}
                  touchableOpacityContainerOnPress={() => { navigate('Overview') }}
                  textTitle={strings.BUTTON_HABITS_OVERVIEW}
                  textTitleStyle={[
                    fonts.SETTINGS_CARD_TITLE,
                    { color: palette.TEXT_PRIMARY }
                  ]}
                  imageRight={
                    <Image
                      style={styles.imageButtonSettings}
                      source={require('../../../assets/images/settings/icon_export.png')}
                      resizeMode={'contain'}
                    />
                  }
                />
              </View>
            </View>
            <View style={styles.viewButtonsSettings}>
              <View style={styles.viewButtonSettings}>
                <ButtonSettings
                  touchableOpacityContainerStyle={[
                    styles.buttonSettings,
                    {
                      backgroundColor: palette.SETTINGS_CARD_BACKGROUND,
                      borderColor: palette.SETTINGS_CARD_BORDER
                    }
                  ]}
                  touchableOpacityContainerOnPress={() => { navigate('Leaderboard') }}
                  textTitle={strings.BUTTON_LEADERBOARD}
                  textTitleStyle={[
                    fonts.SETTINGS_CARD_TITLE,
                    { color: palette.TEXT_PRIMARY }
                  ]}
                  imageRight={
                    <Image
                      style={styles.imageButtonSettings}
                      source={require('../../../assets/images/shared/icon_leaderboard.png')}
                      resizeMode={'contain'}
                    />
                  }
                />
              </View>
            </View>

            <View style={styles.viewButtonsSettings}>
              <View style={styles.viewButtonSettings}>
                <ButtonSettings
                  touchableOpacityContainerStyle={[
                    styles.buttonSettings,
                    {
                      backgroundColor: palette.SETTINGS_CARD_BACKGROUND,
                      borderColor: palette.SETTINGS_CARD_BORDER
                    }
                  ]}
                  touchableOpacityContainerOnPress={() => { navigate('CaptainsLog') }}
                  textTitle={strings.BUTTON_CAPTAINS_LOG}
                  textTitleStyle={[
                    fonts.SETTINGS_CARD_TITLE,
                    { color: palette.TEXT_PRIMARY }
                  ]}
                  imageRight={
                    <Image
                      style={styles.imageButtonSettings}
                      source={require('../../../assets/images/shared/icon_captains_log.png')}
                      resizeMode={'contain'}
                    />
                  }
                />
              </View>
            </View>
            <View style={styles.viewButtonsSettings}>
              <ButtonSettings
                touchableOpacityContainerStyle={[
                  styles.buttonSettingsLogout,
                  {
                    backgroundColor: palette.DARK_OPACITY_BACKGROUND,

                  }
                ]}
                touchableOpacityContainerOnPress={() => setModalVisible(true)}
                textTitle={strings.LOGOUT}
                textTitleStyle={[
                  fonts.SETTINGS_CARD_TITLE,
                  {
                    color: palette.TEXT_PRIMARY_SHADOW,
                    fontSize: vw(5.5),
                    textShadowColor: palette.SETTINGS_CARD_BORDER,
                    textShadowOffset: { width: 0, height: 1 },
                    textShadowRadius: 4,
                  }
                ]}
                imageRight={null}
              />
            </View>
          </View>
        </ScrollView>
      </ImageBackground>
    </>
  )
}
