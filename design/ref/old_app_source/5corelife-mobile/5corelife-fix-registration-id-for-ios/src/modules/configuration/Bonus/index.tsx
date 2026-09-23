import React, { useEffect, useState } from 'react'
import { Animated, Easing, Image, ImageBackground, ScrollView, Text, View } from 'react-native'
import { TouchableOpacity } from 'react-native-gesture-handler'
import { useRecoilValue } from 'recoil'

import ButtonBack from '../../../components/ButtonBack'
import Button from '../../../components/Button'
import HeaderSettings from '../../../components/HeaderSettings'
import ModalOkCancel from '../../../components/ModalOkCancel'
// import ModalCheckIn from '../../../components/ModalCheckIn'
// import ModalQuiz from '../../../components/ModalQuiz'
import { vh, vw } from '../../../helpers/dimensions'
import { storageAtom } from '../../../recoil/atoms'
import { URL } from '../../../helpers/api'
import { fetchAxios, fetchAxiosNoCache } from '../../../helpers/axios'
import props from './props'
import strings from './strings'
import styles from './styles'
import { NavigationHelpersContext } from '@react-navigation/core'
import ButtonCircle from '../../../components/ButtonCircle'
import { BonusBuyRequest, BonusBuyResponse } from '../../../typescript/main'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, pop, goBack } }: props) => {
  const {
    value: { fonts, palette, token },
  } = useRecoilValue(storageAtom)

  const containerBkgd = require('../../../assets/images/bonus/container.png');
  const containerSelectedBkgd = require('../../../assets/images/bonus/containerItemSelected.png');
  const [selectedBonus, setSelectedBonus] = React.useState<null | any>(null);
  const [isModalVisible, setModalVisible] = React.useState<boolean>(false);
  const [userBonus, setUserBonus] = React.useState<Array<number>>([1, 5]);
  const [modalTitle, setModalTitle] = React.useState<string>("");
  const [selectedColor, setSelectedColor] = React.useState<null | any>(null);
  const [rocketEquip, setRocketEquip] = useState<any[]>([]);

  const bonusArray = [
    {
      id: 1,
      titlePath: require('../../../assets/images/bonus/1Days.png'),
      iconPath: require('../../../assets/images/bonus/iconSkipIdle.png'),
      days: 1,
      price: 5,
      bonusDescription: "Bonus skip description"
    },
    {
      id: 2,
      titlePath: require('../../../assets/images/bonus/2Days.png'),
      iconPath: require('../../../assets/images/bonus/iconIncreaseJourneyIdle.png'),
      days: 2,
      price: 15,
      bonusDescription: "Increase minimum core score for journey"
    },
    {
      id: 3,
      titlePath: require('../../../assets/images/bonus/5Days.png'),
      iconPath: require('../../../assets/images/bonus/iconIncreaseDayIdle.png'),
      days: 5,
      price: 25,
      bonusDescription: "Bonus days description"
    },
    {
      id: 4,
      titlePath: require('../../../assets/images/bonus/10Days.png'),
      iconPath: require('../../../assets/images/bonus/iconUnlockIdle.png'),
      days: 10,
      price: 50,
      bonusDescription: "Bonus unlock description"
    },
  ];

  useEffect(() => {
    userHasBonus() ? setModalTitle(strings.ACTIVATE_MODAL_TEXT) : setModalTitle(strings.BUY_MODAL_TEXT);
  }, [selectedBonus]);

  const buttonSelected = (button: number) => {
    logger.debug("line 77 Bonus.index button: ", button);
    setSelectedBonus(button)
  }

  const userHasBonus = () => {
    if (!selectedBonus) {
      return false;
    }
    if (userBonus.includes(selectedBonus)) {
      return true
    }

    return false;
  }
  const getButtonText = () => {
    if (!selectedBonus) {
      return ""
    }
    if (userBonus.includes(selectedBonus)) {
      return "ACTIVATE"
    }
    else {
      return "BUY"
    }
  }

  const [state, setstate] = useState(false)
  const [bonusItems, setBonusItems] = useState<any[]>([])
  const [bonusItemsUser, setBonusItemsUser] = useState<any[]>([])
  useEffect(() => {
    (async () => {
      try {
        const bonusUser: any = fetchAxiosNoCache(
          'GET',
          URL + 'bonus/user/',
          token,
          null
        )
        const [bonusApi] = await Promise.all([bonusUser])
        setBonusItemsUser(bonusApi)
        return () => setstate(false)
      } catch (error: any) {
        logger.error("BonusUser error: ", error.response);
      }
    })()
  }, [state])

  const [openDownload, setOpenDownload] = useState(false)
  const [message, setMessage] = useState<string>('');
  const changeRocketSkin = async () => {
    logger.debug("line 127 Bonus.index selectedBonus.name: ", selectedBonus.name);
    try {
      const data: BonusBuyRequest = {
        name: selectedBonus.name,
      }
      const buyBonus: BonusBuyResponse[] = await fetchAxios<BonusBuyRequest, BonusBuyResponse[]>(
        'POST',
        URL + 'bonus/buy/',
        token,
        data
      );
      logger.info('SUCCESS Buy Bonus: ', buyBonus);
      setstate(true)
    } catch (error: any) {
      logger.error('Bonus error: ', error.response.data);
      if (error.response.data?.credits) {
        setMessage(error.response.data?.credits[0])
        setOpenDownload(true)
      }

    }
    setSelectedBonus(null);
    setModalVisible(false);
  };

  const [screenPosY] = useState(new Animated.Value(0));
  useEffect(() => {
    if (openDownload) {
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
      setOpenDownload(false)
    }
  }, [screenPosY, openDownload])

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
                {message}
              </Text>
            </View>
          </ImageBackground>
        </Animated.View>

        <View style={styles.containerSub}>

          <View style={styles.containerButtonBack}>
            <ButtonBack
              onPress={() => goBack()}
            // pop()
            // navigate('Storage')
            //}}
            />
          </View>

          <View style={styles.containerHeaderSettings}>
            <HeaderSettings
              title={strings.TITLE}
              textTitleStyle={[
                fonts.CORE_TITLE,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                },
              ]}
              rightArrowNavigation={() => { navigate('Trophies') }}
              leftArrowNavigation={() => { navigate('Improvements') }}

            />
          </View>

          <ImageBackground
            style={[styles.containerImageImprovementsIcon, styles.alignBgWindow]}
            source={require('../../../assets/images/improvements/bgWindow.png')}
            resizeMode={'cover'}>
            <ImageBackground
              style={styles.bonusBkgdMainContainer}
              source={require('../../../assets/images/bonus/window.png')}
              resizeMode={'contain'}
            >
              <ImageBackground
                style={styles.bonusBkgdContainer}
                source={require('../../../assets/images/bonus/iconBonus.png')}
                resizeMode={'contain'}
              >
                {
                  selectedBonus && !selectedBonus?.actived &&
                  <View style={styles.buttonActivateContainer}>
                    <Button
                      touchableOpacityContainerStyle={{
                        alignSelf: 'center',
                        backgroundColor: selectedBonus ? palette.SUCCESS : palette.DISABLED,
                        borderRadius: vw(10),
                        borderWidth: vw(0.5),
                        borderColor: palette.BUTTON_BORDER,
                        height: vh(7),
                        width: vw(22),
                      }}
                      textTitle={getButtonText()}
                      textTitleStyle={[
                        fonts.BUTTON_SMALL,
                        {
                          color: palette.TEXT_PRIMARY,
                          textShadowColor: palette.TEXT_PRIMARY_SHADOW
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
            </ImageBackground>
          </ImageBackground>

          <ScrollView>
            <ImageBackground
              style={[styles.containerImageImprovementsIcon, styles.alignBgFooter]}
              source={require('../../../assets/images/improvements/bgWindow_only.png')}
              resizeMode={'cover'}>
              {bonusItems.map((item: any, index: number) => (
                <React.Fragment key={item.uniqueKey}>
                  <ButtonCircle
                    onPress={() => buttonSelected(item)}
                    containerButtonHeaderStyle={styles.containerButtonHeader}
                    titlePath={item.description ? item.description : 'WITHOUT TITLE'}
                    iconPath={item.iconPath}
                    isActive={selectedBonus?.id === item.id}
                    infoText={item.cost}
                    isBlocked={item?.actived ? false : true}
                    unlocked={true}
                    containerButtonTitleStyle={[fonts.ACCORDION_TITLE, { color: palette.TEXT_PRIMARY, textAlign: 'center' }]}
                    containerButtonRocket={[styles.styleCenterRocketActived, styles.styleCenterBaseRocketActived]}
                    hasCoin={false}
                  />
                </React.Fragment>))}
              {
                selectedBonus &&
                <View>
                  <Text
                    style={[
                      styles.bonusDescription,
                      fonts.CORE_HABIT_CHECK_ACHIEVED,
                      { color: palette.TEXT_PRIMARY }
                    ]}>
                    {bonusItems.find((x: any) => x.id === selectedBonus.id)?.name}
                  </Text>
                </View>
              }

            </ImageBackground>
          </ScrollView>
        </View>
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
        onCancel={() => { setModalVisible(false); setSelectedBonus(null) }}
        onOk={() => changeRocketSkin()}
        isVisible={isModalVisible}
      />
    </>
  )
}
