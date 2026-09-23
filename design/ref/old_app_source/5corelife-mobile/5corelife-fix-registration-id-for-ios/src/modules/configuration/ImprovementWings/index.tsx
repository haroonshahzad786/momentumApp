import React, { useEffect, useState } from 'react'
import { Image, ImageBackground, Text, View, ScrollView, Animated, Easing } from 'react-native'
import { useRecoilState, useRecoilValue } from 'recoil'
import Button from '../../../components/Button'

import ButtonCircle from '../../../components/ButtonCircle'
import HeaderDots from '../../../components/HeaderDots'
import HeaderSettings from '../../../components/HeaderSettings'
import ModalOkCancel from '../../../components/ModalOkCancel'
import Rocket from '../../../components/Rocket'
import { URL } from '../../../helpers/api'
import { fetchAxios, fetchAxiosNoCache } from '../../../helpers/axios'
import { vh, vw } from '../../../helpers/dimensions'
import { getImprovementsWings } from '../../../helpers/internalDataManagement'
import { localDataAtom, storageAtom, userRetrieveAtom } from '../../../recoil/atoms'
import { Improvement, ImprovementUserRequest, ImprovementsUser, LocalData, RocketComposition } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'
import { updateImprovementsState } from '../Improvements/utilities'

export default ({ navigation: { navigate, goBack }, route: { params: { armor, wings, thrusters } } }: props) => {
  logger.debug("[<ImprovementWings>]")
  logger.debug("wings:", wings)
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)
  const [userProfileLocal] = useRecoilState(userRetrieveAtom);
  const [localData, setLocalData] = useRecoilState(localDataAtom)
  const [selectedImprovement, setSelectedColor] = useState<null | any>(null);
  const [title, setTitle] = useState<string | any>(null);
  const [isModalVisible, setModalVisible] = useState<boolean>(false);
  const [userImprovements, setUserImprovements] = useState<Improvement[]>([])
  const [restOfImprovements, setRestImprovements] = useState<Improvement[]>([]);

  const [modalTitle, setModalTitle] = useState<string>("");

  const [rocketComposition, setRocketComposition] = useState<RocketComposition | any>(null);
  const [rocketEquip, setRocketEquip] = useState<any[]>([]);
  const [state, setstate] = useState<boolean>(false)

  useEffect(() => {
    loadUserImprovement(localData.value)
    const {userTurbineName, userWingsName, userSkinColor} = loadUserImprovements(userImprovements, restOfImprovements)

    setRocketComposition({
      turbines: userTurbineName,
      wings: userWingsName,
      color: userSkinColor,
    });
  }, [localData.value?.improvements])

  const loadUserImprovement = (localData: LocalData) => {
    const onlyWingsImprovements = localData?.improvements.filter((x: Improvement) => x.type === 'WINGS');
    const onlyRestImprovements = localData?.improvements.filter((x: Improvement) => x.type !== 'WINGS');

    setUserImprovements(onlyWingsImprovements);
    setRestImprovements(onlyRestImprovements);
  }

  const loadUserImprovements = (onlyWingsImprovements: Improvement[], onlyRestImprovements: Improvement[]) => {
    let userTurbines = onlyRestImprovements.find(
      (x: Improvement) => ((x.type === 'THRUSTER') && x.isActive),
    )?.name ?? 'Base Thruster';

    let userWings = onlyWingsImprovements.find(
      (x: Improvement) => ((x.type === 'WINGS') && x.isActive),
    )?.name ?? 'Base Wings';

    let userSkinColor = onlyRestImprovements.find(
      (x: Improvement) => ((x.type === 'ARMOR') && x.isActive),
    )?.name ?? 'Base Armor';

    return {userTurbineName: userTurbines, userWingsName: userWings, userSkinColor}

  }

  const buttonSelected = (item: any) => {
    setTitle(`+${item.bonus_core_cap} Core Cap`)
    setSelectedColor(item);
  }

  const userHasImprovement = () => {
    if (!selectedImprovement) return false;
    if (selectedImprovement && rocketComposition.wings === selectedImprovement?.name) return true
    return false;
  }

  logger.debug("ImprovementWings rocketComposition: ",rocketComposition)
  const getButtonText = () => {
    if (!selectedImprovement) return ""
    if (rocketComposition.wings === selectedImprovement?.name) return strings.BUTTON_EQUIP
    else return strings.BUTTON_GET
  }

  const availableButton = () => {
    let {userWingsName} = loadUserImprovements(userImprovements, restOfImprovements)
    if (userWingsName === selectedImprovement?.name) return false
    return true
  }

  const activedImprovement = (items: Improvement) => {
    let {userWingsName} = loadUserImprovements(userImprovements, restOfImprovements)
    if (userWingsName === items.name) return false
    return true
  }

  const equipRocket = async () => {
    try {
      const data: ImprovementUserRequest = {
        name: selectedImprovement.name,
        improvement_type: selectedImprovement.improvement_type
      }
      const equip: ImprovementsUser[] = await fetchAxios<ImprovementUserRequest, ImprovementsUser[]>(
        'POST',
        URL + 'improvements/equip/',
        token,
        data 
      );
      logger.debug('[ ----> EQUIP HERE IMPROVEMENTS WINGS <---- ]', equip);
      const [improvement] = equip.filter((response: any) => response.improvement.name === selectedImprovement.name && response.equipped)
      setRocketComposition({
        ...rocketComposition,
        color: improvement.improvement.name
      })
      logger.debug('[ ----> EQUIP HERE IMPROVEMENTS WINGS <---- ]');
      setstate(true)
    } catch (error: any) {
      logger.debug('Improvements Wings equip error:', error.response);
    }
  }

  useEffect(() => {
    userHasImprovement() ?
      setModalTitle(strings.EQUIP_MODAL_TEXT) :
      setModalTitle(strings.GET_MODAL_TEXT);
  }, [userHasImprovement]);

  const [openModalCost, setOpenModalCost] = useState(false)
  const [messageCost, setMessageCost] = useState<any>('')
  const changeRocketSkin = async () => {
    let newImprovement: any = {}
    const improvementToEdit = userImprovements.find(x => x.isActive);
    try {
      const data: ImprovementUserRequest = {
        name: selectedImprovement.name,
        improvement_type: selectedImprovement.improvement_type
      }
      await fetchAxios<ImprovementUserRequest, ImprovementsUser[]>(
        'POST',
        URL + 'improvements/buy/',
        token,
        data
      );
      await equipRocket()
    } catch (error: any) {
      logger.error('Improvements buy Wings error', error.response?.data);
      if (error.response?.data?.improvement) {
        logger.debug('line 167 ImprovementWings.index error.response?.data: ', error.response?.data)
        await equipRocket()
        newImprovement = {
          id: improvementToEdit?.id,
          name: selectedImprovement?.name,
          type: 'WINGS',
          cost: selectedImprovement?.cost,
          isActive: true,
        }
      }
      if (error.response.data?.cost) {
        logger.debug('line 179 ImprovementWings.index', error.response?.data?.cost[0])
        newImprovement = {
          id: rocketEquip[0]?.improvement.id,
          name: rocketEquip[0]?.improvement.name,
          type: 'WINGS',
          cost: rocketEquip[0]?.improvement.cost,
          isActive: true,
        }
        setOpenModalCost(true)
        setTimeout(() => {
          setOpenModalCost(false)
        }, 4200);
      }
    }

    const oldImprovement = {
      id: improvementToEdit?.id,
      name: improvementToEdit?.name,
      type: 'wing',
      cost: improvementToEdit?.cost,
      isActive: false,
    } as Improvement;

    logger.debug('line 200 ImprovementWings.index newImprovement: ', newImprovement);

    const restInactiveWings = userImprovements.filter(x => x.id != improvementToEdit?.id);

    setUserImprovements([
      ...restInactiveWings,
      oldImprovement,
      newImprovement,
    ]);

    fetchImprovements();

    setSelectedColor(null);
    setModalVisible(false);
  };

  const fetchImprovements = async () => {
    try {
      const equip: ImprovementsUser[] = await fetchAxiosNoCache<null, ImprovementsUser[]>(
        'GET',
        URL + 'improvements/user/',
        token,
        null
      )
      logger.debug("line ImprovementWings.index equip: ", equip)

      const improvementEquipped: Improvement[] = updateImprovementsState(equip);
      logger.debug("line ImprovementWings.index improvementEquipped: ", improvementEquipped)
      setLocalData({
        ...localData,
        value: {
          ...localData.value,
          improvements: improvementEquipped,
        },
      });
    } catch (error: any) {
      logger.error('ImprovementWings.index Error fetchImprovements: ', error);
    }
  };

  const [screenPosY] = useState(new Animated.Value(0));
  useEffect(() => {
    if (openModalCost) {
      Animated.sequence([
        Animated.timing(screenPosY, {
          toValue: vh(80),
          easing: Easing.out(Easing.ease),
          duration: 2000,
          useNativeDriver: true
        }),
        Animated.timing(screenPosY, {
          delay: 4000,
          toValue: vh(0),
          easing: Easing.out(Easing.ease),
          duration: 2000,
          useNativeDriver: true
        }),
      ]).start();
    }
  }, [screenPosY, openModalCost])

  return (
    <>
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/shared/background.png')}
        resizeMode={'cover'}>
        <Animated.View
          style={[
            styles.animatedViewScreen,
            {
              transform: [
                {
                  translateY: screenPosY
                }
              ]
            }
          ]}>
          <ImageBackground
            style={styles.imageBackgroundScreen}
            source={require('../../../assets/images/onboarding/screen.png')}
            resizeMode={'contain'}>
            <View style={styles.viewTextScreen}>
              <Text
                style={[
                  styles.textScreen,
                  fonts.LOGIN_TITLE,
                  { color: palette.TEXT_PRIMARY, fontSize: 21 }
                ]}>
                {messageCost}
              </Text>
            </View>
          </ImageBackground>
        </Animated.View>

        <ScrollView style={{ flexGrow: 1 }}>
          <View style={styles.containerSub}>
            <HeaderDots
              dotsCount={3}
              activeDotIndex={1}
              onHelpButton={() => navigate('Help')}
              onBackButton={() => goBack()}
              goHome={() => navigate('Cores')}
            />
            <View style={styles.containerHeaderSettings}>
              <HeaderSettings
                title={strings.TITLE}
                subtitle={strings.SUBTITLE}
                textTitleStyle={[
                  fonts.CORE_TITLE,
                  {
                    color: palette.TEXT_PRIMARY,
                    textShadowColor: palette.TEXT_PRIMARY_SHADOW
                  }
                ]}
                textSubtitleStyle={[
                  fonts.CORE_SUBTITLE,
                  {
                    color: palette.DARK_OPACITY_BACKGROUND,
                    textShadowColor: 'transparent'
                  }
                ]}
                leftArrowNavigation={() => { navigate('ImprovementArmors', { armor, wings, thrusters }) }}
                rightArrowNavigation={() => { navigate('ImprovementTurbines', { armor, wings, thrusters }) }}
              />
            </View>

            <View style={styles.containerImprovements}>
              <ImageBackground
                style={[styles.containerImageImprovementsIcon, styles.alignBgWindow]}
                source={require('../../../assets/images/improvements/bgWindow.png')}
                resizeMode={'cover'}>
                <ImageBackground
                  style={styles.imageImprovementsIcon}
                  source={require('../../../assets/images/improvements/window.png')}
                  resizeMode={'cover'}
                >
                  {
                    rocketComposition &&
                    <Rocket
                      externalStyle={styles.imageRocket}
                      wings={rocketComposition?.wings}
                      turbines={rocketComposition?.turbines}
                      skinColor={rocketComposition?.color}
                    />
                  }

                </ImageBackground>
                {selectedImprovement &&
                  <View style={styles.descriptionBonusCore}>
                    <Text style={[styles.titleBonusCore, fonts.CORE_SUBTITLE, { fontSize: 20 }]}>
                      {title}
                    </Text>
                  </View>
                }
                {
                  (selectedImprovement && availableButton()) &&
                  <View style={[styles.touchableStyle]}>
                    <Button
                      touchableOpacityContainerStyle={{
                        alignSelf: 'center',
                        backgroundColor: selectedImprovement ? palette.SUCCESS : palette.DISABLED,
                        borderRadius: vw(10),
                        borderWidth: vw(0.5),
                        borderColor: palette.BUTTON_BORDER,
                        height: vh(7),
                        width: vw(20),
                      }}
                      textTitle={getButtonText()}
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
                      onPress={() => setModalVisible(true)}
                    />
                  </View>
                }
              </ImageBackground>
            </View>

            <ImageBackground
              style={[styles.containerImageImprovementsIcon, styles.alignBgFooter]}
              source={require('../../../assets/images/improvements/bgWindow_only.png')}
              resizeMode={'cover'}>
              <View style={styles.buttonsBox}>
                {wings?.map((item: any) => (
                  parseInt(item.cost) > 0 &&
                  <React.Fragment key={item.uniqueKey}>
                    <ButtonCircle
                      onPress={() => buttonSelected(item)}
                      containerButtonHeaderStyle={styles.containerButtonNormal}
                      titlePath={item.name}
                      iconPath={getImprovementsWings(item.name, false).iconButton}
                      containerButtonTitleStyle={[fonts.ACCORDION_TITLE, { color: palette.TEXT_PRIMARY, textAlign: 'center' }]}
                      infoText={activedImprovement(item) ? item.cost : 'IN USE'}
                      isBlocked={rocketEquip.length && rocketEquip[0].improvement.order === item.order ? false : true}
                      unlocked={true}
                      size={styles.size}
                      coinActived={activedImprovement(item)}
                      isActive={item.order === selectedImprovement?.order}
                      containerButtonRocket={[styles.styleCenterRocketActived, styles.styleCenterBaseRocketActived]}
                    />
                  </React.Fragment>
                ))}
              </View>
            </ImageBackground>
          </View>
        </ScrollView>
      </ImageBackground>
      <ModalOkCancel
        textTitle={modalTitle}
        textTitleStyle={[fonts.MODAL_TITLE, { color: palette.TEXT_PRIMARY }]}
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
        onCancel={() => { setModalVisible(false) }}
        onOk={changeRocketSkin}
        isVisible={isModalVisible}
      />
    </>
  )
}
