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
import { getImprovementsTurbines } from '../../../helpers/internalDataManagement'
import { localDataAtom, storageAtom, userRetrieveAtom } from '../../../recoil/atoms'
import { Improvement, ImprovementUserRequest, ImprovementsUser, LocalData, RocketComposition } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'
import { updateImprovementsState } from '../Improvements/utilities'

export default ({ navigation: { navigate, goBack }, route: { params: { armor, wings, thrusters } } }: props) => {
  logger.debug("[<ImprovementTurbines>]")
  logger.debug("thrusters:", thrusters)
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)
  const [localData, setLocalData] = useRecoilState(localDataAtom)
  const [userProfileLocal] = useRecoilState(userRetrieveAtom);
  const [selectedImprovement, setSelectedImprovement] = useState<null | any>(null);
  const [title, setTitle] = useState<string | any>(null);
  const [isModalVisible, setModalVisible] = useState<boolean>(false);

  const [modalTitle, setModalTitle] = useState<string>("");
  const [rocketComposition, setRocketComposition] = useState<RocketComposition | any>(null);

  const [userImprovements, setUserImprovements] = useState<Improvement[]>([])
  const [restOfImprovements, setRestImprovements] = useState<Improvement[]>([]);
  const [rocketEquip, setRocketEquip] = useState<any[]>([]);
  const [rocketNotEquip, setRocketNotEquip] = useState<any[]>([]);
  const [state, setstate] = useState<boolean>(false)
  useEffect(() => {
    loadUserImprovement(localData.value)
    const {userTurbineName, userWings, userSkinColor} = loadUserImprovements(userImprovements, restOfImprovements)

    setRocketComposition({
      turbines: userTurbineName,
      wings: userWings,
      color: userSkinColor,
    });
  }, [localData.value?.improvements])

  const loadUserImprovement = (localData: LocalData) => {
    const onlyTurbineImprovements = localData?.improvements.filter((x: Improvement) => x.type === 'THRUSTER');
    const onlyRestImprovements = localData?.improvements.filter((x: Improvement) => x.type !== 'THRUSTER');

    setUserImprovements(onlyTurbineImprovements);
    setRestImprovements(onlyRestImprovements);
  }

  const loadUserImprovements = (onlyTurbineImprovements: Improvement[], onlyRestImprovements: Improvement[]) => {
    let userTurbines = onlyTurbineImprovements.find(
      (x: Improvement) => ((x.type === 'THRUSTER') && x.isActive),
    )?.name ?? 'Base Thruster';

    let userWings = onlyRestImprovements.find(
      (x: Improvement) => ((x.type === 'WINGS') && x.isActive),
    )?.name ?? 'Base Wings';

    let userSkinColor = onlyRestImprovements.find(
      (x: Improvement) => ((x.type === 'ARMOR') && x.isActive),
    )?.name ?? 'Base Armor';

    return {userTurbineName: userTurbines, userWings, userSkinColor}

  }

  useEffect(() => {
    userHasColor() ?
      setModalTitle(strings.EQUIP_MODAL_TEXT) :
      setModalTitle(strings.GET_MODAL_TEXT);
  }, [selectedImprovement]);

  const buttonSelected = (item: any) => {
    setTitle(`x${item.core_power_multiplier} Core Power Multiplier`)
    setSelectedImprovement(item);
  }

  const userHasColor = () => {
    if (!selectedImprovement)
      return false;

    if (selectedImprovement && rocketComposition.turbines === selectedImprovement?.name)
      return true

    return false;
  }

  logger.debug("ImprovementTurbines rocketComposition: ",rocketComposition)
  const getButtonText = () => {
    if (!selectedImprovement) return ""
    if (rocketComposition.turbines === selectedImprovement?.name) return strings.BUTTON_EQUIP
    else return strings.BUTTON_GET
  }

  const availableButton = () => {
    let {userTurbineName} = loadUserImprovements(userImprovements, restOfImprovements)
    if (userTurbineName === selectedImprovement?.name) return false
    return true
  }

  const activedImprovement = (items: Improvement) => {
    let {userTurbineName} = loadUserImprovements(userImprovements, restOfImprovements)
    if (userTurbineName === items.name) return false
    return true
  }

  let newImprovement: any = {}
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
      logger.debug('[ ----> EQUIP HERE IMPROVEMENTS THRUSTER <---- ]', equip);
      const [improvement] = equip.filter((response: ImprovementsUser) => response.improvement.name === selectedImprovement.name && response.equipped)
      setRocketComposition({
        ...rocketComposition,
        color: improvement.improvement.name
      })
      logger.debug('[ ----> EQUIP HERE IMPROVEMENTS THRUSTER <---- ]');
      setstate(true)
    } catch (error: any) {
      logger.error('Improvements Thruster error: ', error.response);
    }
  }

  const [openModalCost, setOpenModalCost] = useState(false)
  const [messageCost, setMessageCost] = useState<any>('')
  const changeRocketSkin = async () => {
    logger.debug('line 139 ImprovementTurbines.index selectedImprovement: ', JSON.stringify(selectedImprovement));

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
      logger.error('Improvements Thruster buy error: ', error.response?.data);
      if (error.response?.data?.improvement) {
        await equipRocket()
        newImprovement = {
          id: improvementToEdit?.id,
          name: selectedImprovement?.name,
          type: 'THRUSTER',
          cost: selectedImprovement?.cost,
          isActive: true,
        }
      }
      if (error.response?.data?.cost) {
        setMessageCost(error.response.data.cost[0])
        newImprovement = {
          id: rocketEquip[0]?.improvement.id,
          name: rocketEquip[0]?.improvement.name,
          type: 'THRUSTER',
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
      type: 'turbine',
      cost: improvementToEdit?.cost,
      isActive: false,
    } as Improvement;

    const restInactiveColors = userImprovements.filter(x => x.id != improvementToEdit?.id);
    setUserImprovements([
      ...restInactiveColors,
      oldImprovement,
      newImprovement
    ]);
    logger.debug("line 195 ImprovementTurbines.index newImprovement: ", newImprovement);

    fetchImprovements();
    setSelectedImprovement(null);
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
      logger.debug("line ImprovementTurbines.index equip: ", equip)

      const improvementEquipped: Improvement[] = updateImprovementsState(equip);
      logger.debug("line ImprovementTurbines.index improvementEquipped: ", improvementEquipped)
      setLocalData({
        ...localData,
        value: {
          ...localData.value,
          improvements: improvementEquipped,
        },
      });
    } catch (error: any) {
      logger.error('ImprovementTurbines.index Error fetchImprovements: ', error);
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
              activeDotIndex={2}
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
                leftArrowNavigation={() => { navigate('ImprovementWings', { armor, wings, thrusters }) }}
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
                  <Rocket
                    externalStyle={styles.imageRocket}
                    wings={rocketComposition?.wings}
                    turbines={rocketComposition?.turbines}
                    skinColor={rocketComposition?.color}
                  />

                </ImageBackground>
                {selectedImprovement &&
                  <View style={styles.descriptionBonusCore}>
                    <Text style={[styles.titleBonusCore, fonts.CORE_SUBTITLE, { fontSize: 17 }]}>
                      {title}
                    </Text>
                  </View>
                }
                {
                  (selectedImprovement && availableButton()) &&
                  <View style={[styles.touchableStyle, { zIndex: 20 }]}>
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
                      onPress={() => { setModalVisible(true); }}
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
                {thrusters?.map((item: any) => (
                  parseInt(item.cost) > 0 &&
                  <React.Fragment key={item.uniqueKey}>
                    <ButtonCircle
                      onPress={() => {
                        buttonSelected(item)
                      }}
                      containerButtonHeaderStyle={styles.containerButtonNormal}
                      titlePath={item.name}
                      iconPath={getImprovementsTurbines(item.name, false).iconButton}
                      containerButtonTitleStyle={[fonts.ACCORDION_TITLE, { color: palette.TEXT_PRIMARY, textAlign: 'center' }]}
                      infoText={activedImprovement(item) ? item.cost : 'IN USE'}
                      isBlocked={rocketEquip.length && rocketEquip[0].improvement.order === item.order ? false : true}
                      unlocked={true}
                      coinActived={activedImprovement(item)}
                      isActive={item.order === selectedImprovement?.order}
                      containerButtonRocket={[styles.styleCenterRocketActived, styles.styleCenterBaseRocketActived]}
                    />
                  </React.Fragment>))}
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
        onCancel={() => { setModalVisible(false) }}
        onOk={changeRocketSkin}
        isVisible={isModalVisible}
      />
    </>
  )
}
