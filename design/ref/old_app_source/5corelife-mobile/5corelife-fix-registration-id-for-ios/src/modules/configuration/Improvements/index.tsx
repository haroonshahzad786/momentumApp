import React, { useEffect, useState } from 'react'
import { ImageBackground, View } from 'react-native'
import { useRecoilState, useRecoilValue } from 'recoil'

import ButtonBack from '../../../components/ButtonBack'
import ButtonCircle from '../../../components/ButtonCircle'
import HeaderSettings from '../../../components/HeaderSettings'
import Rocket from '../../../components/Rocket'
import { localDataAtom, storageAtom, userRetrieveAtom } from '../../../recoil/atoms'
import { Improvement, ImprovementState, Improvements, RocketComposition } from '../../../typescript/main'
import { URL } from '../../../helpers/api'
import { fetchAxios } from '../../../helpers/axios'
import props from './props'
import strings from './strings'
import styles from './styles'
import { vh } from '../../../helpers/dimensions'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, pop, goBack } }: props) => {
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)
  const [userRetrieve, setUserRetrieve] = useRecoilState(userRetrieveAtom)
  const [localData, setLocalData] = useRecoilState(localDataAtom)
  const [rocketComposition, setRocketComposition] = useState<RocketComposition | null>(null);

  React.useEffect(() => {
    const userImprovements = localData?.value.improvements;
    logger.debug('line 29 Improvements.index userImprovements: ' + JSON.stringify(userImprovements));

    let userTurbines = userImprovements?.find(
      (x: Improvement) => ((x.type === 'THRUSTER') && x.isActive),
    )?.name ?? 'Base Thruster';

    let userWings = userImprovements?.find(
      (x: Improvement) => ((x.type === 'WINGS') && x.isActive),
    )?.name ?? 'Base Wings';

    let userSkinColor = userImprovements?.find(
      (x: Improvement) => ((x.type === 'ARMOR') && x.isActive),
    )?.name ?? 'Base Armor';

    setRocketComposition({
      turbines: userTurbines,
      wings: userWings,
      color: userSkinColor,
    });
  }, [localData]);

  const [improvement, setImprovements] = useState<ImprovementState>({
    armor: [],
    wings: [],
    thruster: [],
  })
  useEffect(() => {
    (async () => {
      const improvements: Improvements[] = await fetchAxios<null, Improvements[]>(
        'GET',
        URL + 'improvements/',
        token,
        null
      )
      const armorItems = improvements.filter((response: Improvements) => response.improvement_type === 'ARMOR')
      const wingsItems = improvements.filter((response: Improvements) => response.improvement_type === 'WINGS')
      const thrusterItems = improvements.filter((response: Improvements) => response.improvement_type === 'THRUSTER')
      setImprovements({
        armor: armorItems,
        wings: wingsItems,
        thruster: thrusterItems
      })
    })()
  }, [])

  return (
    <>
      <ImageBackground
        style={styles.container}
        source={require('../../../assets/images/shared/background.png')}
        resizeMode={'cover'}>
        <View style={styles.containerSub}>
          <View style={styles.containerButtonBack}>
            <ButtonBack
              onPress={() => goBack()}
            />
          </View>

          <View style={styles.containerHeaderSettings}>
            <HeaderSettings
              title={strings.TITLE}
              textTitleStyle={[
                fonts.CORE_TITLE,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW
                }
              ]}
              rightArrowNavigation={() => { navigate('Bonus') }}
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
            </ImageBackground>
          </View>

          <ImageBackground
            style={[styles.containerImageImprovementsIcon, styles.alignBgFooter]}
            source={require('../../../assets/images/improvements/bgWindow_only.png')}
            resizeMode={'cover'}>
            <ButtonCircle
              onPress={() => {
                navigate('ImprovementArmors', { armor: improvement.armor, wings: improvement.wings, thrusters: improvement.thruster })
              }}
              containerButtonHeaderStyle={styles.containerButtonHeader}
              fontSize={vh(3.6)}
              titlePath="Armors"
              containerButtonTitleStyle={[fonts.ACCORDION_TITLE, { color: palette.TEXT_PRIMARY, textAlign: 'center' }]}
              iconPath={require('../../../assets/images/improvements/iconColors.png')}
            />
            <ButtonCircle
              onPress={() => {
                navigate('ImprovementWings', { armor: improvement.armor, wings: improvement.wings, thrusters: improvement.thruster })
              }}
              containerButtonHeaderStyle={styles.containerButtonHeader}
              fontSize={vh(3.6)}
              titlePath="Wings"
              containerButtonTitleStyle={[fonts.ACCORDION_TITLE, { color: palette.TEXT_PRIMARY, textAlign: 'center' }]}
              iconPath={require('../../../assets/images/improvements/iconWings.png')}
            />
            <ButtonCircle
              onPress={() => {
                navigate('ImprovementTurbines', { armor: improvement.armor, wings: improvement.wings, thrusters: improvement.thruster })
              }}
              containerButtonHeaderStyle={styles.containerButtonHeader}
              fontSize={vh(3.1)}
              titlePath="Thrusters"
              containerButtonTitleStyle={[fonts.ACCORDION_TITLE, { color: palette.TEXT_PRIMARY, textAlign: 'center', fontSize: 50 }]}
              iconPath={require('../../../assets/images/improvements/itemRare.png')}
            />
          </ImageBackground>
        </View>
      </ImageBackground>
    </>
  )
}
