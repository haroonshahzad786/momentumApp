import React, { useEffect, useState } from 'react'
import {
  Image,
  ImageBackground,
  TouchableWithoutFeedback,
  View,
  Animated,
  Easing} from 'react-native'
import { fetchAxios } from '../../../helpers/axios'
import { vh } from '../../../helpers/dimensions'
// import LottieView from 'lottie-react-native'
import props from './props'
import { URL } from '../../../helpers/api'
import styles from './styles'
import { useRecoilState, useRecoilValue } from 'recoil'
import { storageAtom, userRetrieveAtom, localDataAtom } from '../../../recoil/atoms'
import { getImageByOriginDestinationName, getAssetByObstacle, getObstacleByMissionId } from '../../../helpers/internalDataManagement'
import Rocket from '../../../components/Rocket'
import ModalDaysJourney from '../../../components/ModalDaysJourney';
import { Destinations, MissionsUser, UserJourney } from '../../../typescript/main'
import ArrowsIndicator from '../../onboarding/ArrowsIndicator'
import { logger } from '../../../helpers/logger'

export default ({
  navigation: { navigate },
  onBoardingMode
}: props) => {
  logger.info("[<Journey>]")
  const {
    value: { token, palette, fonts }
  } = useRecoilValue(storageAtom);
  const userProfileLocalData = useRecoilValue(userRetrieveAtom);
  const [localData, setLocalData] = useRecoilState(localDataAtom);
  const [rocketPosY] = useState(new Animated.Value(0));
  const [userJourney, setUserJourney] = useState<UserJourney | null>(null);
  const [journeyDestiny, setJourneyDestiny] = useState<object | any>({});

  useEffect(() => {
    logger.debug('<MOUNT> |SCREEN| - JOURNEY\nuserRetrieve: ', userProfileLocalData.value);
    const actualDestionationName = userProfileLocalData.value?.user_profile?.actual_destination;
    const userImprovements = localData?.value?.improvements;

    let userTurbines = userImprovements?.find(
      (x: any) => ((x.type === 'THRUSTER') && x.isActive),
    )?.name ?? 'default';

    let userWings = userImprovements?.find(
      (x: any) => ((x.type === 'WINGS') && x.isActive),
    )?.name ?? 'default';

    let userSkinColor = userImprovements?.find(
      (x: any) => ((x.type === 'ARMOR') && x.isActive),
    )?.name ?? 'default';

    const fetchData = async () => {
      let destinations: Destinations[] = []
      try {
        logger.info('<FETCHING> - [DESTINATIONS YY]');
        destinations = await fetchAxios<null, Destinations[]>(
          'GET',
          URL + 'destinations/',
          token,
          null
        );
      } catch (error) {
        logger.error('**ERROR** [GET-DESTINATIONS]');
        logger.error('[ERROR INFO]: ' + JSON.stringify(error));
      }
      logger.debug('Destinations: ', JSON.stringify(destinations));



      try {
        logger.info('<FETCHING> - [USER_RETRIEVE]');
        if (destinations.length) {
          let destiny = destinations?.find(
            (x: Destinations) => x.destination === actualDestionationName,
          )
          logger.debug('-> Current Destiny OBJ:' + JSON.stringify(destiny));
          logger.debug('-> Trip days: ' + JSON.stringify(userProfileLocalData?.value?.user_profile.days_in_journey));
          
          let destinyMinusOne: number = destiny?.length ?? 0
          let origin = destinations?.find(
            (x: Destinations) => x.length === destinyMinusOne - 1,
          ) ?? { destination: 'default' };

          logger.debug("-> Origin: ", origin.destination )

          setJourneyDestiny({ destiny, origin: userProfileLocalData?.value });
          let missionsUser: MissionsUser[] = await fetchAxios<null, MissionsUser[]>(
            'GET',
            URL + 'missions/user/',
            token,
            null
          );

          logger.debug("missionsUser: ", missionsUser)
          const mission = getObstacleByMissionId(missionsUser[0]?.mission_id)
          logger.debug("mission: ", mission)

          setUserJourney({
            origin: getImageByOriginDestinationName(origin.destination).image,
            destiny: getImageByOriginDestinationName(destiny?.destination).image,
            obstacle: getAssetByObstacle(missionsUser[0]?.active === true && missionsUser[0]?.success === false ? mission : "").image,
            rocket: {
              turbines: userTurbines,
              wings: userWings,
              color: userSkinColor,
            },
          })
        }
      } catch (error) {
        logger.error('**ERROR** [GET-USERS_RETRIEVE]');
        logger.error('[ERROR INFO]: ' + JSON.stringify(error));
      }
    }

    fetchData();

    Animated.timing(rocketPosY, {
      delay: 500,
      toValue: -vh(25),
      easing: Easing.inOut(Easing.ease),
      duration: 3000,
      useNativeDriver: true,
    }).start();
  }, [])

  return (
    <>
      <TouchableWithoutFeedback
        style={styles.containerTWF}
        onPress={() => {
          navigate('Cores')
        }}>
        <View style={styles.container}>
          <View style={styles.containerSub}>

            <ImageBackground
              style={[styles.containerImageBackground]}
              source={require('../../../assets/images/journey/background.png')}
              resizeMode={'cover'}>
              <View style={[styles.columnContainer, onBoardingMode ? styles.darkVeil : null]}>
                {userJourney != null ?
                  <>
                    <Image
                      style={[
                        styles.lineaGuia,
                        journeyDestiny?.destiny?.destination !== 'Endless' && { marginTop: vh(10) }
                      ]}
                      source={require('../../../assets/images/shared/lineaGuia.png')}
                      resizeMode={'contain'}
                    />
                    {
                      journeyDestiny?.destiny?.destination !== 'Endless' &&
                      <Image
                        style={[styles.imageDestination, onBoardingMode ? styles.lowOpacity : null]}
                        source={userJourney.destiny}
                        resizeMode={'contain'}
                      />
                    }

                    {
                      userJourney.obstacle &&
                      <Image
                        style={[styles.flyingObstacule, onBoardingMode ? styles.lowOpacity : null]}
                        source={userJourney.obstacle}
                        resizeMode={'contain'}
                      />
                    }

                    {
                      journeyDestiny?.destiny?.destination === 'Endless'
                      && (
                        <ModalDaysJourney
                          colorTextPrimary={palette.LIFETIME_PLANET}
                          colorTextSecundary={palette.TEXT_PRIMARY}
                          fontGlobal={fonts.BUTTON_MEDIUM}
                          daysJourney={userProfileLocalData?.value?.user_profile.days_in_journey}
                        />
                      )
                    }

                    {
                      userJourney.rocket &&
                      <Animated.View
                        style={[
                          styles.imageRocket,
                          styles.flexItem,
                          {
                            bottom: vh(5),
                            transform: [
                              {
                                translateY: rocketPosY,
                              }
                            ]
                          }
                        ]}
                      >
                        {onBoardingMode &&
                          <ArrowsIndicator containerStyle={styles.arrowIndicatorPosition} />
                        }
                        <Rocket
                          externalStyle={styles.imageRocket}
                          turbines={userJourney.rocket.turbines}
                          wings={userJourney.rocket.wings}
                          skinColor={userJourney.rocket.color}
                        />
                      </Animated.View>

                    }

                    {journeyDestiny?.destiny?.destination !== 'Endless' &&
                      <Image
                        style={[styles.imageOrigin]}
                        source={userJourney.origin}
                        resizeMode={'contain'}
                      />
                    }
                  </> : null}

              </View>

            </ImageBackground>

          </View>
        </View>
      </TouchableWithoutFeedback>
    </>
  )
}
