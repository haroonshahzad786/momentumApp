import React, { useEffect, useState } from 'react'
import { Image, ImageBackground, Text, View } from 'react-native'
import { ScrollView } from 'react-native-gesture-handler'
import { useRecoilValue } from 'recoil'

import ButtonBack from '../../../components/ButtonBack'
import ButtonNext from '../../../components/ButtonNext'
import HeaderSettings from '../../../components/HeaderSettings'
import { storageAtom } from '../../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import trophyUserLists from '../../../helpers/trophies';
import { fetchAxios } from '../../../helpers/axios'
import { URL } from '../../../helpers/api'
import { Trophy } from '../../../typescript/main'

export default ({ navigation: { navigate, pop, goBack } }: props) => {
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)

  const [arrayTrophies, setArrayTrophies] = useState<Array<object | any>>([]);
  useEffect(() => {
    (async () => {
      const trophies: Trophy[] = await fetchAxios<null, Trophy[]>(
        'GET',
        URL + 'trophies/user/',
        token,
        null
      )
      const arrayObjectTrophies = trophyUserLists(trophies);
      setArrayTrophies(arrayObjectTrophies)
    })()
  }, [])

  const [selectedTrophie, setSelectedTrophie] = useState<any>([]);
  const [selectedIndex, setSelectedIndex] = useState<number>(0);

  useEffect(() => {
    setSelectedTrophie(arrayTrophies.length === 14 && arrayTrophies[selectedIndex])
  }, [selectedIndex, arrayTrophies]);

  const nextTrophie = () => {
    let indexOfTrophie = selectedIndex + 1;
    indexOfTrophie = (indexOfTrophie > (arrayTrophies.length - 1)) ? 0 : indexOfTrophie;
    setSelectedIndex(indexOfTrophie);
  };

  const previewTrophie = () => {
    let indexOfTrophie = selectedIndex - 1;
    indexOfTrophie = (indexOfTrophie < 0) ? (arrayTrophies.length - 1) : indexOfTrophie;
    setSelectedIndex(indexOfTrophie);
  };

  return (
    <>
      <ImageBackground
        style={styles.imageBackgroundContainer}
        source={require('../../../assets/images/shared/background.png')}
        resizeMode={'cover'}>

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
            leftArrowNavigation={() => { navigate('Bonus') }}
          />
        </View>

        <View style={styles.containerTrophiesSection}>
          <ImageBackground
            style={styles.imageTrophyContainer}
            source={require('../../../assets/images/trophies/container.png')}
            resizeMode={'cover'}>

            <Image
              style={[styles.imageTrophy, selectedTrophie.type === 'locked_trophie' ? styles.locked : null]}
              source={selectedTrophie.image_trophie ?? require('../../../assets/images/trophies/trophie_locked.png')}
              resizeMode={'contain'} />
            <View style={styles.buttonZoneSwypeTrophies}>
              <View style={styles.buttonSwypeLeft}>
                <ButtonNext
                  onPress={() => {
                    previewTrophie();
                  }}
                />
              </View>
              <View style={styles.buttonSwypeRight}>
                <ButtonNext
                  onPress={() => {
                    nextTrophie();
                  }}
                />
              </View>
            </View>
          </ImageBackground>

          {selectedTrophie.image_title ?
            <Image
              style={styles.imageCongratulations}
              source={selectedTrophie.image_title}
              resizeMode={'contain'}
            /> : null}
        </View>

        <View style={[styles.viewInfo, { backgroundColor: '"rgba(0, 0, 0, 0.2)"' }]}>
          <View style={[styles.dividerLine, { backgroundColor: "rgba(0, 0, 0, 0.3)" }]} />
          <View style={[styles.descriptionTrophyContainer]}>
            <Text
              style={[
                styles.textTitle,
                selectedTrophie.type == 'completed_trophie' ? fonts.QUEST_DAYS_NUMBER : fonts.MODAL_HABIT,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.DARK_OPACITY_BACKGROUND,
                  fontSize: selectedTrophie.length > 0 && selectedTrophie?.description.length > 15 ? 45 : 50,
                }
              ]}>

              {selectedTrophie.type == 'locked_trophie' ? selectedTrophie.name : selectedTrophie.description}
            </Text>

            {
              (selectedTrophie.type == 'completed_trophie' || selectedTrophie.type == 'locked_trophie') ?
                null : <Image
                  style={styles.imageLine}
                  source={require('../../../assets/images/trophies/line.png')}
                  resizeMode={'contain'}
                />
            }

            {selectedTrophie.type == 'locked_trophie' ?
              <ScrollView style={styles.scrollDescriptionContainer}>
                <Text
                  style={[
                    styles.textSubtitle,
                    fonts.TROPHIE_DESCRIPTION,
                    {
                      color: palette.TEXT_PRIMARY,
                      textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                    }
                  ]}>
                  {selectedTrophie.description}
                </Text>
              </ScrollView> :
              <View style={styles.scrollDescriptionContainer}>
                <Text
                  style={[
                    styles.textSubtitle,
                    fonts.CORE_SUBTITLE,
                    {
                      color: palette.TEXT_TERTIARY,
                      textShadowColor: palette.TEXT_PRIMARY_SHADOW
                    }
                  ]}>
                  {selectedTrophie.description_blue}
                </Text>
              </View>
            }
          </View>
        </View>
      </ImageBackground>
    </>
  )
}
