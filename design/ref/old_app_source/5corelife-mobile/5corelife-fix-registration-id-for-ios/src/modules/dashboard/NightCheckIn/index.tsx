import React, { useEffect, useState } from 'react'
import { ImageBackground, View, ScrollView } from 'react-native'
import { useRecoilValue, useRecoilState } from 'recoil'
import { coresAtom, storageAtom, localDataAtom, dailyCheckAtom, userRetrieveAtom } from '../../../recoil/atoms'

import HeaderSettings from '../../../components/HeaderSettings'
import props from './props'
import strings from './strings'
import styles from './styles'
import { fetchAxiosMultiple, fetchAxiosNoCache } from '../../../helpers/axios';
import { cloneDeep } from 'lodash'
import { setAtomManual } from '../../../helpers/recoil'
import { URL } from '../../../helpers/api'
import Button from '../../../components/Button'
import { vh, vw } from '../../../helpers/dimensions'
import { Core, CoreValuesListForHabitsNightCheck, DailyCheck, HabitsMorninAndNightgCheckResponse, HabitsNightgCheckRequest, HabitsTypes } from '../../../typescript/main'
import AccordionNigthCheck from '../../../components/AccordionNigthCheck'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate } }: props) => {
  logger.info("[<NightCheckIn>]")
  const {
    value: { fonts, palette, token, onboarding }
  } = useRecoilValue(storageAtom)

  const [cores, setCoresData] = useRecoilState(coresAtom)
  const [habitsList, setHabitsList] = useState<HabitsTypes[]>([])
  const [coreValuesList, setCoreValuesList] = useState<any>([]);
  const [coreShowList, setCoreShowList] = useState<any>([]);
  const [localData, setLocalData] = useRecoilState(localDataAtom);
  const dailyCheck = useRecoilValue(dailyCheckAtom);
  const isCheckIn = localData.value.currentCheckin != null

  const getCore = (core: string) => {
    switch (core) {
      case 'RELATIONSHIPS':
        return sliderValueNumberRELATIONSHIPS
      case 'PHYSICAL_HEALTH':
        return sliderValueNumberPHYSICAL_HEALTH
      case 'MINDSET':
        return sliderValueNumberMINDSET
      case 'EMOTIONAL_HEALTH':
        return sliderValueNumberEMOTIONAL_HEALTH
      case 'CAREER_FINANCES':
        return sliderValueNumberCAREER_FINANCES
      default:
        return 0
    }
  }

  const onClickDone = async () => {
    if (isCheckIn != null) {
      setLocalData({
        init: true,
        value: {
          ...localData.value,
          lastNightCheckInCompleted: Date.now(),
        },
      })

      if (dailyCheck.value != null && dailyCheck.value.length > 0) {

        confirmNightCheckProcces(dailyCheck.value).then((habitsNightCheck) => {
          if (habitsNightCheck){
            navigate('CockpitStackScreen', {
              screen: 'SelfReview',
              params: { night: habitsNightCheck }
            })
          }
        });
      }
    } else {
      logger.info('NightChecking.index isCheckIn is null!');
    }
  }

  const confirmNightCheckProcces = async (dailyCheck:DailyCheck[]) => {
    logger.debug("line 102 dashboard.NightChecking coreValuesList: ", coreValuesList);
    logger.info('-> NIGHT CHECKIN CONFIRM PROCESS localData.value.coreInfo: ', localData.value.coreInfo,
                "\ndailyCheck: ", dailyCheck);
    const coresAndHabits: HabitsNightgCheckRequest[] = localData.value.coreInfo.reduce((acc:HabitsNightgCheckRequest[], core) => {

      const matchingDaily = dailyCheck.find(daily => daily.core === core.core_string);
      if (!matchingDaily) {
        return acc;
      }

      const element = coreValuesList.find((x: CoreValuesListForHabitsNightCheck) => x.core_name === matchingDaily.core);
      if (!element) {
        return acc;
      }

      const data = {
        core: element.core_name,
        score: getCore(element.core_name),
      };

      acc.push(data);
      return acc;
    }, [] as HabitsNightgCheckRequest[]);

    logger.debug('->>>>> DATA: ' + JSON.stringify(coresAndHabits));
    try {
      logger.info('<POSTING> - [NIGHTCHECK]');
      if (!coresAndHabits[coresAndHabits.length - 1]) coresAndHabits.pop()
      const habitsNightCheck: HabitsMorninAndNightgCheckResponse = await fetchAxiosNoCache<HabitsNightgCheckRequest[],HabitsMorninAndNightgCheckResponse>(
        'POST',
        `${URL}habits/night-check/`,
        token,
        coresAndHabits,
      );
      logger.debug('---> ANSWER NIGHT: ' + JSON.stringify(habitsNightCheck));
      return habitsNightCheck
    } catch (error) {
      logger.error('**ERROR** [POST-HABITS_NIGHT_CHECK]');
      logger.error('[ERROR INFO]: ' + JSON.stringify(error));
    }
  }

  useEffect(() => {
    logger.info('<MOUNT> |SCREEN| - NIGHTCHECKIN');

    try {
      const fetchData = async () => {
        if (cores && cores.value) {
          logger.info('<FETCHING> - [HABITS_BY_CORE]');
          const responses = await fetchAxiosMultiple(
            cores.value.map((core) => {
              return {
                method: 'GET',
                url: `${URL}habits/?core=${core.core_string}`,
                token
              }
            })
          )

          let arrayCores: any[] = []
          localData.value.coreInfo.map((response: any) => {
            cores.value && cores.value.map((resp: any) => {
              if (resp.core_string === response.core_string) arrayCores.push({
                ...resp,
                lastMorningCheckIn: response.lastMorningCheckIn,
                onboarding: localData.value.onboarding || onboarding
              })
            })
          })

          const coresCopy = cloneDeep(arrayCores)
          let habits = new Array();
          responses.forEach((response) => {
          
            if (response.length > 0) {
              const core = response[0].core;
              let coreCopy = coresCopy?.find(x => x.core_string === core);
              if (!coreCopy) return;
              coreCopy.habits = response;
              habits = habits.concat(response);
            }
          })

          const arrayPush: { core_name: "CAREER_FINANCES" | "EMOTIONAL_HEALTH" | "MINDSET" | "PHYSICAL_HEALTH" | "RELATIONSHIPS"; habitsList: string, value: number }[] = [];
          coresCopy.filter((x: any) => x.enabled && x.habits && (x.lastMorningCheckIn || x.onboarding)).map((core: Core) => {
            let habitos = "";
            if (core.habits != null && core.habits?.length > 0) {
              core.habits.forEach((habit: any) => {
                if (habit.selected) habitos = ((habitos !== "") ? habitos + ", " : "") + habit.name;
              })
            }

            return arrayPush.push({
              core_name: core.core_string,
              habitsList: habitos,
              value: 0,
            })
          });

          if (habits.length > 0) {
            setHabitsList(habits);
            setCoreValuesList(arrayPush ?? [])
            setCoreShowList(arrayPush ?? [])
            setAtomManual(setCoresData, coresCopy);
          }
        }
      }

      fetchData();

    } catch (error) {
      logger.error('**ERROR** [GET-HABITS_BY_CORE]');
      logger.error('[ERROR INFO]: ' + JSON.stringify(error));
    }
  }, []);

  const [selectedHabit, setSelectedHabit] = useState<any>(null)

  const openModal = (item: any) => {
    setSelectedHabit(item);
  }

  const [sliderValueNumberMINDSET, setSliderValueNumberMINDSET] = useState<number>(0);
  const [sliderValueNumberEMOTIONAL_HEALTH, setSliderValueNumberEMOTIONAL_HEALTH] = useState<number>(0);
  const [sliderValueNumberRELATIONSHIPS, setSliderValueNumberRELATIONSHIPS] = useState<number>(0);
  const [sliderValueNumberPHYSICAL_HEALTH, setSliderValueNumberPHYSICAL_HEALTH] = useState<number>(0);
  const [sliderValueNumberCAREER_FINANCES, setSliderValueNumberCAREER_FINANCES] = useState<number>(0);

  const renderAccordion = () => {
    return coreShowList.map((response: any) => {
      switch (response?.core_name) {
        case 'MINDSET':
          return (
            <View style={styles.containerAccordion}>
              <AccordionNigthCheck
                textHeader={'MINDSET'}
                hasBubble={true}
                isContentList={true}
                content={{ name: response?.core_name, description: response?.habitsList }}
                avatarPath={require('../../../assets/images/overview/iconMindset.png')}
                primaryColor={'#AC2912'}
                onEditing={openModal}
                updateList={setSliderValueNumberMINDSET}
                sliderValueNumber={sliderValueNumberMINDSET}
                isActive={true}
              />
            </View>
          )
        case 'EMOTIONAL_HEALTH':
          return (
            <View style={styles.containerAccordion}>
              <AccordionNigthCheck
                textHeader={'EMOTIONAL HEALTH'}
                hasBubble={true}
                isContentList={true}
                content={{ name: response?.core_name, description: response?.habitsList }}
                avatarPath={require('../../../assets/images/overview/iconEmotional.png')}
                primaryColor={'#1B51A1'}
                onEditing={openModal}
                updateList={setSliderValueNumberEMOTIONAL_HEALTH}
                sliderValueNumber={sliderValueNumberEMOTIONAL_HEALTH}
                isActive={true}
              />
            </View>
          )
        case 'RELATIONSHIPS':
          return (
            <View style={styles.containerAccordion}>
              <AccordionNigthCheck
                textHeader={'RELATIONSHIPS'}
                hasBubble={true}
                isContentList={true}
                content={{ name: response?.core_name, description: response?.habitsList }}
                avatarPath={require('../../../assets/images/overview/iconRelationships.png')}
                primaryColor={'#C8348C'}
                onEditing={openModal}
                updateList={setSliderValueNumberRELATIONSHIPS}
                sliderValueNumber={sliderValueNumberRELATIONSHIPS}
                isActive={true}
              />
            </View>
          )
        case 'PHYSICAL_HEALTH':
          return (
            <View style={styles.containerAccordion}>
              <AccordionNigthCheck
                textHeader={'PHYSICAL HEALTH'}
                hasBubble={true}
                isContentList={true}
                content={{ name: response?.core_name, description: response?.habitsList }}
                avatarPath={require('../../../assets/images/overview/iconPhysical.png')}
                primaryColor={'#7D2C7D'}
                onEditing={openModal}
                updateList={setSliderValueNumberPHYSICAL_HEALTH}
                sliderValueNumber={sliderValueNumberPHYSICAL_HEALTH}
                isActive={true}
              />
            </View>
          )
        case 'CAREER_FINANCES':
          return (
            <View style={[styles.containerAccordion]}>
              <AccordionNigthCheck
                textHeader={'CAREER FINANCES'}
                hasBubble={true}
                isContentList={true}
                content={{ name: response?.core_name, description: response?.habitsList }}
                avatarPath={require('../../../assets/images/overview/iconPhysical_2.png')}
                primaryColor={'#6E9A30'}
                onEditing={openModal}
                updateList={setSliderValueNumberCAREER_FINANCES}
                sliderValueNumber={sliderValueNumberCAREER_FINANCES}
                isActive={true}
              />
            </View>
          )
        default: return null;
      }
    })
  }

  const HabitsRoute = () => {
    return (
      <View style={[
        styles.containerBackCard
      ]}>
        <View
          style={[
            styles.containerCardQuest,
            {
              backgroundColor: 'rgba(0, 0, 0, 0.4)',
              borderColor: palette.SETTINGS_CARD_BORDER,
            }
          ]}>
          <View style={[styles.containerRows]}>
            <View style={{ zIndex: 9, flex: 1 }}>
              <ScrollView>
                {renderAccordion()}
              </ScrollView>
            </View>
          </View>
        </View>
      </View>
    )
  }

  return (
    <>
      <ImageBackground
        style={[styles.container]}
        source={require('../../../assets/images/shared/background.png')}
        resizeMode={'cover'}>

        <View style={[styles.containerSub]}>
          <HeaderSettings
            title={strings.TITLE}
            textTitleStyle={[
              fonts.CORE_TITLE,
              {
                color: palette.TEXT_PRIMARY,
                textShadowColor: palette.TEXT_PRIMARY_SHADOW
              }
            ]}
          />

          <ScrollView style={{ flexGrow: 1 }}>
            {HabitsRoute()}
          </ScrollView>

          <View style={styles.touchableStyle}>
            <Button
              touchableOpacityContainerStyle={{
                alignSelf: 'center',
                backgroundColor: palette.SUCCESS,
                borderRadius: vw(10),
                borderWidth: vw(0.5),
                borderColor: palette.BUTTON_BORDER,
                height: vh(7),
                width: vw(20),
              }}
              textTitle={strings.BTN_DONE}
              textTitleStyle={[
                fonts.BUTTON_SMALL,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                  letterSpacing: vw(0.3)
                }
              ]}
              spinnerSize={20}
              spinnerColor={palette.TEXT_PRIMARY}
              isLoading={false}
              onPress={() => onClickDone()}
            />
          </View>
        </View>
      </ImageBackground>
    </>
  )
}
