import React, { useEffect, useState } from 'react'
import { Image, ImageBackground, View, ScrollView } from 'react-native'
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
import { activedImprovementArmor, getImprovementsColors } from '../../../helpers/internalDataManagement'
import { localDataAtom, storageAtom, userRetrieveAtom } from '../../../recoil/atoms'
import { Improvement, ImprovementUserRequest, ImprovementsUser, RocketComposition } from '../../../typescript/main'
import props from './props'
import strings from './strings'
import styles from './styles'
import { logger } from '../../../helpers/logger'
import { updateImprovementsState } from '../Improvements/utilities'

export default ({ navigation: { navigate, pop, goBack }, route: { params: { armor, wings, thrusters } } }: props) => {
  logger.debug("[<ImprovementsArmors>]")
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)
  const [userProfileLocal] = useRecoilState(userRetrieveAtom);
  const [localData, setLocalData] = useRecoilState(localDataAtom)
  const [selectedImprovement, setSelectedColor] = useState<null | any>(null);
  const [isModalVisible, setModalVisible] = useState<boolean>(false);
  const [userImprovements, setUserImprovements] = useState<Improvement[]>([])
  const [restOfImprovements, setRestImprovements] = useState<Improvement[]>([]);
  const [modalTitle, setModalTitle] = useState<string>("");

  const [rocketComposition, setRocketComposition] = useState<RocketComposition | any>(null);
  const [rocketNotEquip, setRocketNotEquip] = useState<any[]>([]);
  const [state, setstate] = useState<boolean>(false)
  
  useEffect(() => {
    (() => {
      const onlyColorsImprovements = localData.value?.improvements.filter((x: Improvement) => x.type === 'ARMOR');
      const onlyRestImprovements = localData.value?.improvements.filter((x: Improvement) => x.type !== 'ARMOR');
      logger.debug("ImprovementArmors.index onlyColorsImprovements: ", onlyColorsImprovements, "\nonlyRestImprovements:", onlyRestImprovements)
      setUserImprovements(onlyColorsImprovements);
      setRestImprovements(onlyRestImprovements);
      let userTurbines = onlyRestImprovements.find(
        (x: Improvement) => ((x?.type === 'THRUSTER') && x.isActive),
      )?.name ?? 'Base Thruster';

      let userWings = onlyRestImprovements.find(
        (x: Improvement) => ((x?.type === 'WINGS') && x.isActive),
      )?.name ?? 'Base Wings';

      let userSkinColor = onlyColorsImprovements.find(
        (x: Improvement) => ((x?.type === 'ARMOR') && x.isActive),
      )?.name ?? 'Base Armor';
      logger.debug("line 63 configuration.ImprovementsArmors.index userSkinColor: ", userSkinColor)

      setRocketComposition({
        turbines: userTurbines,
        wings: userWings,
        color: userSkinColor,
      });
    })()
  }, [localData.value?.improvements]);

  useEffect(() => {
    setModalTitle(strings.EQUIP_MODAL_TEXT)
  }, []);

  const buttonSelected = (item: any) => {
    setSelectedColor(item);
  }

  const availableButton = () => {
    if (rocketNotEquip.filter((x: any) => x.improvement.name === selectedImprovement?.name && x.equipped).length) return false
    return true
  }

  const changeRocketSkin = async () => {
    logger.debug('line 105 ImprovementArmors.index selectedImprovement: ', JSON.stringify(selectedImprovement));
    let newImprovement: any = {}
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
      logger.debug('[ ----> EQUIP HERE IMPROVEMENTS ARMOR <---- ]', equip);
      const [improvement] = equip.filter((response: ImprovementsUser) => response.improvement.name === selectedImprovement.name && response.equipped)
      setRocketComposition({
        ...rocketComposition,
        color: improvement.improvement.name
      })
      newImprovement = {
        id: selectedImprovement.order,
        name: selectedImprovement.name,
        type: 'ARMOR',
        cost: selectedImprovement.cost,
        isActive: true
      }
      setstate(true)
    } catch (error: any) {
      logger.error('Improvements armor error: ', error.response.data);
    }

    const improvementToEdit = userImprovements.find(x => x.isActive);
    logger.debug("line 126 Configurations.ImprovementArmors.index improvementToEdit: ", improvementToEdit)
    const oldImprovement = {
      id: improvementToEdit?.id,
      name: improvementToEdit?.name,
      type: 'color',
      cost: improvementToEdit?.cost,
      isActive: false,
    } as Improvement;

    const restInactiveColors = userImprovements.filter(x => x.id != improvementToEdit?.id);
    logger.debug("line 136 Configurations.ImprovementArmors.index restInactiveColors: ", restInactiveColors)
    setUserImprovements([
      ...restInactiveColors,
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
      logger.debug("line Configurations.ImprovementArmors.index equip: ", equip)

      const improvementEquipped: Improvement[] = updateImprovementsState(equip);
      logger.debug("line Configurations.ImprovementArmors.index improvementEquipped: ", improvementEquipped)
      setLocalData({
        ...localData,
        value: {
          ...localData.value,
          improvements: improvementEquipped,
        },
      });
    } catch (error: any) {
      logger.error('Configurations.ImprovementArmors.index Error fetchImprovements: ', error);
    }
  };

  return (
    <>

      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/shared/background.png')}
        resizeMode={'cover'}>
        <ScrollView style={{ flexGrow: 1 }}>
          <View style={styles.containerSub}>
            <HeaderDots
              dotsCount={3}
              activeDotIndex={0}
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
                rightArrowNavigation={() => { navigate('ImprovementWings', { armor, wings, thrusters }) }}
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
                      externalStyle={rocketComposition?.color === 'Base Armor' ? styles.imageRocket : styles.imageNewRocket}
                      wings={rocketComposition?.wings}
                      turbines={rocketComposition?.turbines}
                      skinColor={rocketComposition?.color}
                    />
                  }
                </ImageBackground>
                {
                  (selectedImprovement && availableButton()) &&
                  <View style={[styles.touchableStyle, , { zIndex: 20 }]}>
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
                      textTitle={strings.BUTTON_EQUIP}
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
                {armor?.map((item: any, index: number) => (
                  item.destination &&
                  <React.Fragment key={item.uniqueKey}>
                    <ButtonCircle
                      onPress={() => {
                        buttonSelected(item)
                      }}
                      containerButtonHeaderStyle={styles.containerButtonNormal}
                      titlePath={item.name}
                      iconPath={getImprovementsColors(item.name, false).iconButton}
                      hasImageShadow={true}
                      shadowPath={getImprovementsColors(item.name, false).shadowButton}
                      wings={getImprovementsColors(item.name, false).wings}
                      infoText={rocketComposition?.color === item?.name ? 'IN USE' : null}
                      isBlocked={activedImprovementArmor(userProfileLocal.value?.user_profile.actual_destination_length, item.destination)}
                      containerButtonTitleStyle={[fonts.ACCORDION_TITLE, { color: palette.TEXT_PRIMARY, textAlign: 'center' }]}
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
