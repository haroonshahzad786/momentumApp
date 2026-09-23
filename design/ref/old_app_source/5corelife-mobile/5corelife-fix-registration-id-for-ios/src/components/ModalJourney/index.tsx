import React, { useEffect, useState } from 'react'
import { Image, ImageBackground, Text, View } from 'react-native'
import { useRecoilValue, useRecoilState } from 'recoil'
import { storageAtom, userRetrieveAtom } from '../../recoil/atoms'
import ModalScreenBase from '../ModalScreenBase'
import props from './props'
import strings from './strings'
import styles from './styles'
import { fetchAxios } from '../../helpers/axios'
import listPlanet from '../../helpers/listPlanet'
import { URL } from '../../helpers/api'
import { Destinations } from '../../typescript/main'
import { logger } from '../../helpers/logger'

export default ({
  touchableOpacityContainerButtonStyle,
  textTitleButtonStyle,
  textMainHeader,
  textContentHeader,
  textContentInfo,
  onClickOk,
  isVisible,
  // isModalVisibled
}: props) => {
  logger.info("[<ModalJourney>]")
  const {
    value: { fonts, palette, token },
  } = useRecoilValue(storageAtom);

  const [userProfileLocal, setUserProfileLocal] = useRecoilState(userRetrieveAtom);
  const imageMonitor = require('../../assets/images/journey/monitor.png');
  const imageEarth:string = require('../../assets/images/journey/iconEarth.png');
  const imageFormBack = require('../../assets/images/journey/formCont.png');
  const [state, setState] = useState<string | any>('');
  const [listPlanets, setListPlanets] = useState<string | any>('');
  const [daysJourney, setDaysJourney] = useState<string | any>('');

  useEffect(() => {
    logger.debug('line 37 ModalJourney.index <MOUNT> |MODAL| - MODALJOURNEY userProfileLocal: ', userProfileLocal.value);

    (async () => {
      try {
        logger.debug('line 41 ModalJourney.index <FETCHING> - [DESTINATIONS DD]');
        const destinations: Destinations[] = await fetchAxios<null, Destinations[]>(
          'GET',
          URL + 'destinations/',
          token,
          null
        );
        logger.debug('line 47 ModalJourney.index destinations: ', JSON.stringify(destinations));

        if (userProfileLocal && userProfileLocal != null) {
          let days = destinations?.filter((response: any) => response?.destination === userProfileLocal?.value?.user_profile?.actual_destination)
          if (userProfileLocal.value?.user_profile?.days_in_journey != null)
            setDaysJourney(days[0]?.length - userProfileLocal.value?.user_profile.days_in_journey);
          else
          logger.debug('line 55 ModalJourney.index -> WARN: Days in journey is null. UserProfile OBJ: ' + JSON.stringify(userProfileLocal.value))

          let destiny = destinations?.find(
            (x: Destinations) => x.destination === userProfileLocal.value?.user_profile.actual_destination,
          )
          logger.debug('line 60 ModalJourney.index destiny: ' + JSON.stringify(destiny));
          setState(destiny);
          setListPlanets(listPlanet(destiny!.destination));
        }

      } catch (err) {
        logger.debug('**ERROR** [GET-DESTINATIONS]');
        logger.error('Destination error: ' + JSON.stringify(err));
      }
    })();

  }, []);

  return (
      <ModalScreenBase
        touchableOpacityContainerButtonStyle={
          touchableOpacityContainerButtonStyle
        }
        textTitleButtonStyle={textTitleButtonStyle}
        imageMonitor={imageMonitor}
        textTitle={strings.BUTTON_OK}
        heightOffset={0}
        onClick={onClickOk}
        isVisible={isVisible}>
        <View style={{ flex: 1, flexDirection: 'column' }}>
          <View style={styles.headerSection}>
            <Text
              style={[
                styles.headerText,
                {
                  color: palette.TEXT_PRIMARY,
                },
              ]}>
              {textMainHeader}
            </Text>
          </View>

          <View style={styles.earthSection}>
            <View style={styles.earthContainer}>
              <Image
                style={styles.earthImage}
                source={listPlanets?.image ? listPlanets?.image : imageEarth}
                resizeMode={'contain'}
              />
            </View>
            <View style={styles.titleContainer}>
              <ImageBackground
                style={styles.imageFormBack}
                source={imageFormBack}
                resizeMode={'contain'}>
                <Text
                  style={[
                    styles.titleText,
                    {
                      color: palette.TEXT_PRIMARY,
                    },
                  ]}>
                  {textContentHeader}
                </Text>
              </ImageBackground>
            </View>
          </View>

          <View style={styles.contentSection}>
            <View style={{ flex: 1, flexDirection: 'column' }}>
              <View style={{ flexBasis: '12%', alignItems: 'center' }}>
                <Text
                  style={[
                    [
                      fonts.BUTTON_MEDIUM,
                      {
                        color: palette.TEXT_PRIMARY,
                      },
                    ],
                  ]}>
                  {textContentInfo}
                </Text>
              </View>
              <View
                style={{
                  flexBasis: '40%',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}>
                <View style={{ flexDirection: 'row' }}>
                  {
                    state?.destination === 'Endless'
                      ?
                      <Text style={[styles.infinity]}>ENDLESS</Text>
                      :
                      <>
                        <Text style={[styles.infoNumber]}>{daysJourney}</Text>
                        <Text style={[styles.infoText]}> days</Text>
                      </>
                  }
                </View>
                <Text
                  style={[
                    [
                      fonts.BUTTON_MEDIUM,
                      {
                        color: palette.TEXT_PRIMARY,
                      },
                    ],
                  ]}>
                  for Destination
                </Text>
              </View>
              <View
                style={{
                  flexBasis: '40%',
                  alignItems: 'center',
                  justifyContent: 'flex-start',
                }}>
                <View style={{ flexDirection: 'row' }}>
                  <Text style={[styles.infoNumber]}>{state?.momentum_required}</Text>
                  <Text style={[styles.infoText]}> %</Text>
                </View>
                <Text
                  style={[
                    [
                      fonts.BUTTON_MEDIUM,
                      {
                        color: palette.TEXT_PRIMARY,
                      },
                    ],
                  ]}>
                  Momentum Required
                </Text>
              </View>
            </View>
          </View>
        </View>
      </ModalScreenBase>
  )
}
