import React, { useEffect, useState } from 'react'
import { Image, View } from 'react-native'
import { FlatList, ScrollView } from 'react-native-gesture-handler'
import { useRecoilState, useRecoilValue } from 'recoil'

import ButtonBack from '../../../components/ButtonBack'
import Cockpit from '../../../components/Cockpit'
import CockpitScreen from '../../../components/CockpitScreen'
import ListItemCategory from '../../../components/ListItemCategory'
import ModalMantra from '../../../components/ModalMantra'
import { URL } from '../../../helpers/api'
import { vh, vw } from '../../../helpers/dimensions'
import { setAtomAxios } from '../../../helpers/recoil'
import { mantraAtom, storageAtom } from '../../../recoil/atoms'
import { CockpitList, Core, Mantra } from '../../../typescript/main'
import { fetchAxiosNoCache } from '../../../helpers/axios'
import { returnListWithRoute } from '../../../helpers/internalDataManagement'
import props from './props'
import strings from './strings'
import styles from './styles'
import LinearGradient from 'react-native-linear-gradient'
import { logger } from '../../../helpers/logger'

export default ({ navigation: { navigate, goBack }, tutorial, navigateToNextStep }: props) => {
  logger.info("[<CockpitCategories>]")
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom)

  const [mantra, setMantra] = useRecoilState(mantraAtom)

  const [isModalMantraVisible, setModalMantraVisible] = useState<boolean>(false)

  const [mantraState, setMantraState] = useState<Mantra | null>(null)

  useEffect(() => {
    let Sound = require('react-native-sound')
    let Sound2 = require('react-native-sound')

    const soundAirlock = new Sound(
      require('../../../assets/sounds/airlock.mp3'),
      () => {
        soundAirlock.play((success: any) => logger.debug("line 104 CockpitCategories.index soundAirlock.play: ",success))
      }
    )

    const soundBackground = new Sound2(
      // require('../../../assets/sounds/cockpit.m4a'),
      require('../../../assets/sounds/Menu_Select_01.mp3'),
      () => {
        soundBackground.play((success: any) => logger.debug("line 112 CockpitCategories.index soundBackground.play: ", success))
      }
    )
  }, [])

  useEffect(() => {
    logger.debug("line 118 CockpitCategories.index mantra: ", mantra.value)
    setMantraState(mantra.value)
  }, [setMantraState, mantra.value])

  const updateMantraState = (text: string) => {
    setMantraState({ ...mantraState!, mantra: text })
  }

  const [core, setCore] = useState<any[]>([])
  useEffect(() => {
    (async () => {
      try {
        const cores: Core[] = await fetchAxiosNoCache<null, Core[]>(
          'GET',
          URL + 'cores/user/',
          token,
          null
        )
        const coresActive = cores.filter((response: any) => response.enabled === true)
        let array: any[] = [];
        Array.isArray(coresActive) && coresActive.map((response: any) => {
          switch (response.core_string) {
            case 'PHYSICAL_HEALTH':
              array.push({
                name: 'PHYSICAL HEALTH',
                color: '#7D2C7D',
                image: require('../../../assets/images/overview/iconPhysical.png')
              });
              break;
            case 'MINDSET':
              array.push({
                name: 'MINDSET',
                color: '#AC2912',
                image: require('../../../assets/images/overview/iconMindset.png')
              });
              break;
            case 'CAREER_FINANCES':
              array.push({
                name: 'CAREER FINANCES',
                color: '#6E9A30',
                image: require('../../../assets/images/overview/iconPhysical_2.png')
              });
              break;
            case 'RELATIONSHIPS':
              array.push({
                name: 'RELATIONSHIPS',
                color: '#C8348C',
                image: require('../../../assets/images/overview/iconRelationships.png')
              });
              break;
            case 'EMOTIONAL_HEALTH':
              array.push({
                name: 'EMOTIONAL HEALTH',
                color: '#1B51A1',
                image: require('../../../assets/images/overview/iconEmotional.png')
              });
              break;
          }
        })
        setCore(array)
      } catch (error: any) {
        logger.error("line 179 CockpitCategories.index error: ",error.response)
      }
    })()
  }, [])

  const saveMantra = () => {
    // check if initial mantra is
    // different from state mantra
    if (mantra.value?.mantra !== mantraState?.mantra) {
      setAtomAxios(setMantra, {
        method: 'PUT',
        url: URL + 'users/mantra/',
        data: {
          mantra: mantraState?.mantra
        }
      })
    }

    setModalMantraVisible(false)
  }

  const [list, setList] = useState<any[]>([])
  useEffect(() => {
    (async () => {
      try {
        const cockpitLists: CockpitList[] = await fetchAxiosNoCache<null, CockpitList[]>(
          'GET',
          URL + 'cockpit-list/',
          token,
          null
        )
        const newOrder = cockpitLists.findIndex((response: CockpitList) => response.name === 'Back to the future');
        logger.debug("line 211 CockpitCategories.index newOrder: ", newOrder)
        const mantra = {
          name: 'Mantra',
          mantra: true,
          enabled: true
        };
        let arrayNew = [...cockpitLists]
        arrayNew.splice(newOrder, 1)
        arrayNew.unshift(cockpitLists[newOrder])
        logger.debug("line 222 CockpitCategories.index arrayNew: ", arrayNew)
        arrayNew.map((response: any) => {
          logger.debug("line 224 CockpitCategories.index tutorial: ", tutorial, "\nresponse: ", response)
          if (tutorial && response.name !== 'Back to the future') response.enabled = false
          response.route = (returnListWithRoute(response.name)).name
          response.mantra = (returnListWithRoute(response.name)).mantra
        })
        setList(arrayNew);
      } catch (error: any) {
        logger.error("line 231 CockpitCategories.index error: ", error.response)
      }
    })()
  }, [])

  return (
    <>
      <Cockpit>
        {!tutorial &&
          <View style={styles.containerButtonBack}>
            <ButtonBack
              onPress={() => {
                goBack()
              }}
            />
          </View>
        }

        {!tutorial &&
          <View style={styles.containerCockpitScreen}>
            <CockpitScreen
              onPress={() => {
                setModalMantraVisible(true)
              }}
            />
          </View>
        }

        <View style={styles.containerFlatListCategories}>
          <LinearGradient
            colors={['#FFFF', 'rgba(0,0,0,.2)']}
            start={{ x: 0.5, y: 0.0 }} end={{ x: 1.0, y: 1.0 }}
            style={[styles.bubbleShape]}
          >
            <View style={[styles.containerBubble, {
              backgroundColor: '#1B1714',
              flex: 1
            }]}>
              <ScrollView  horizontal >
                <FlatList
                  data={list}
                  scrollEnabled={true}
                  showsVerticalScrollIndicator={false}
                  bounces={false}
                  nestedScrollEnabled
                  renderItem={({ item }) => (
                    <>
                      <ListItemCategory
                        category={item}
                        textTitleStyle={[
                          {
                            "fontFamily": "A-SpaceDemo",
                            "fontSize": vw(3),
                            "letterSpacing": 0
                          },
                          {
                            color: item.enabled
                              ? palette.COCKPIT_CATEGORY_ENABLED
                              : palette.COCKPIT_CATEGORY_DISABLED
                          }
                        ]}
                        backgroundColor={
                          item.enabled
                            ? palette.COCKPIT_CATEGORY_BACKGROUND_ENABLED
                            : palette.COCKPIT_CATEGORY_BACKGROUND_DISABLED
                        }
                        onPress={() =>
                          tutorial
                            ?
                            navigateToNextStep({
                              core,
                              type: item.sorted_by_type
                            })
                            :
                            navigate(item.route, {
                              params: {
                                core,
                                type: item.sorted_by_type
                              }
                            })}
                        openMantra={setModalMantraVisible}
                      />
                    </>
                  )}
                  keyExtractor={(_, index) => index.toString()}
                />
              </ScrollView>
            </View>
          </LinearGradient>
        </View>

        <ModalMantra
          textTitle={strings.MODAL_MANTRA_TITLE}
          textTitleStyle={[
            styles.textModalMantraTitle,
            fonts.MANTRA_TITLE,
            { color: palette.TEXT_TERTIARY }
          ]}
          iconRight={
            <Image
              style={{ width: vw(5), height: vw(5) }}
              source={require('../../../assets/images/shared/button_edit.png')}
              resizeMode={'cover'}
            />
          }
          textInputParagraphFirst={mantraState?.mantra}
          textInputParagraphFirstOnChangeText={updateMantraState}
          textParagraphSecond={''}
          textInputParagraphStyle={[
            styles.textModalMantraParagraph,
            fonts.MANTRA_PARAGRAPH,
            { color: palette.TEXT_PRIMARY }
          ]}
          textParagraphDividerStyle={[
            fonts.MANTRA_PARAGRAPH,
            { color: palette.TEXT_PRIMARY }
          ]}
          touchableOpacityContainerButtonStyle={{
            width: vw(25),
            height: vh(7),
            borderRadius: vw(10),
            borderWidth: vw(0.5),
            borderColor: palette.BUTTON_BORDER,
            backgroundColor: palette.SUCCESS
          }}
          touchableOpacityContainerButtonOnPress={saveMantra}
          textTitleButton={strings.MODAL_MANTRA_BUTTON_TEXT}
          textTitleButtonStyle={[
            styles.textDoneButton,
            fonts.BUTTON_MEDIUM,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW
            }
          ]}
          isVisible={isModalMantraVisible}
        />
      </Cockpit>
    </>
  )
}
