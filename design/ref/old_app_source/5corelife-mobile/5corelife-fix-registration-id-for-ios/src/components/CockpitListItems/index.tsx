import React, { useState } from 'react'
import {
  Animated, FlatList, Image, ScrollView, Text, TouchableOpacity, View
} from 'react-native'
import { useRecoilValue } from 'recoil'
import { vh, vw } from '../../helpers/dimensions'
import { storageAtom } from '../../recoil/atoms'
import Button from '../Button'
import CockpitScreenInspiration from '../CockpitScreenInspiration'
import ListItemEdit from '../ListItemEdit'
import ModalAddItem from '../ModalAddItem'
import AccordionCocpit from '../AccordionCocpit'
import props from './props'
import styles from './styles'
import ButtonBackCockpit from '../ButtonBackCockpit'
import LinearGradient from 'react-native-linear-gradient'
import ArrowsIndicator from '../../modules/onboarding/ArrowsIndicator'
import { filterXcores } from '../../helpers/internalDataManagement'
import { logger } from '../../helpers/logger'

export default ({
  title,
  data,
  inspirations,
  screenPosY,
  goBack,
  onAdd,
  /* onUpdate, */
  saveEverything,
  textSelector,
  addItemCockpit,
  itemsCockpit,
  textModal,
  styleBack,
  params,
  textScreen,
  tutorial,
  navigateToNextStep,
  nextStep,
}: props) => {
  logger.info("[<CockpitListItems>]")
  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  const [isModalVisible, setModalVisible] = useState<{ visibled: boolean, edit: boolean }>({ visibled: false, edit: false });
  const [dataModal, setDataModal] = useState<{ id: any, title: string, user: 0, core_name: string }>({ id: null, title: '', user: 0, core_name: '' })
  const [cores, setCores] = useState<string>('');
  logger.info('line 48 CockpitListItems.index Items received for cockpitlist: ' + JSON.stringify(itemsCockpit), "Inspirations: " + JSON.stringify(inspirations));
  const addItem = (info: any) => {
    let result = false
    data.map((response: any) => {
      if (Number(response.id) === info.id) {
        response.name = info.title
        response.core_name = info.core_name
        setDataModal({ id: null, title: '', user: 0, core_name: '' })
        result = true
      }
    })
    if (!result && itemsCockpit !== null) onAdd(itemsCockpit);
    setModalVisible({ visibled: false, edit: false });
  }


  const filterXcore = (core: string, a: any) => {
    let filterPhysicalHealth = Array.isArray(data) && data?.filter((response: any) => response.core_name === 'PHYSICAL HEALTH')
    let filterMindSet = Array.isArray(data) && data?.filter((response: any) => response.core_name === 'MINDSET')
    let filterCareerFinances = Array.isArray(data) && data?.filter((response: any) => response.core_name === 'CAREER FINANCES')
    let filterRelationships = Array.isArray(data) && data?.filter((response: any) => response.core_name === 'RELATIONSHIPS')
    let filterEmotionalHealt = Array.isArray(data) && data?.filter((response: any) => response.core_name === 'EMOTIONAL HEALTH')
    switch (core) {
      case 'PHYSICAL HEALTH':
        return filterPhysicalHealth;
      case 'MINDSET':
        return filterMindSet;
      case 'CAREER FINANCES':
        return filterCareerFinances;
      case 'RELATIONSHIPS':
        return filterRelationships;
      case 'EMOTIONAL HEALTH':
        return filterEmotionalHealt;
      default:
        return data
    }
  }

  const [selectedHabit, setSelectedHabit] = React.useState<any>(null)
  const openModal = (item: any) => {
    setSelectedHabit(item);
  }

  const editCollapse = (func: Function, active: boolean) => func(!active);


  return (
    <>
      {!tutorial &&
        <Animated.View
          style={[
            styles.containerCockpitScreen,
            {
              transform: [
                {
                  translateY: screenPosY
                }
              ]
            }
          ]}>
          <CockpitScreenInspiration
            textTitle={textScreen
            }
            textTitleStyle={[
              styles.textInspiration,
              fonts.MODAL_TITLE,
              { color: palette.TEXT_TERTIARY }
            ]}
          />
        </Animated.View>
      }

      {
        isModalVisible.visibled &&
        <ModalAddItem
          textTitle={textModal}
          textTitleStyle={[fonts.MODAL_TITLE, { color: palette.TEXT_PRIMARY, fontSize: vw(10) }]}
          textInputNameStyle={[
            fonts.COCKPIT_SUBTITLE,
            {
              color: palette.TEXT_PRIMARY
            }
          ]}
          textInputNameOnChangeText={(text: string) => addItemCockpit(text, cores)}
          textInputNameOnSubmitEditing={() => { null }}
          placeholder={"Type here..."}
          placeholderColor={palette.COCKPIT_INPUT}
          okButtonImage={
            <Image
              style={{ width: vw(10), height: vh(6) }}
              source={require('../../assets/images/shared/button_ok.png')}
              resizeMode={'cover'}
            />
          }
          cancelButtonImage={
            <Image
              style={{ width: vw(10), height: vh(6) }}
              source={require('../../assets/images/shared/button_cancel.png')}
              resizeMode={'cover'}
            />
          }
          onCancel={() => setModalVisible({ visibled: false, edit: false })}
          onOk={addItem}
          dataModal={dataModal}
          setDataModal={setDataModal}
          isVisible={isModalVisible}
        />
      }

      <View style={styles.containerTitle}>
        <View style={[styles.containerButtonBack, styleBack]}>
          <ButtonBackCockpit disabled={tutorial} onPress={goBack} />
        </View>
        <Text
          style={[fonts.COCKPIT_TITLE, { color: palette.TEXT_PRIMARY }, title.length > 12 && styles.styleFuneral]}>
          {title}
        </Text>
      </View>

      <View style={styles.containerCock}>
        <View style={styles.containerCollapse}>
          <LinearGradient
            colors={['#FFFF', 'rgba(0,0,0,.2)']}
            start={{ x: 0.5, y: 0.0 }} end={{ x: 1.0, y: 1.0 }}
            style={[styles.bubbleShape]}
          >
            <View style={[styles.containerBubble, {
              backgroundColor: '#1B1714',
            }]}>
              <ScrollView style={{ flexGrow: 1 }}>
                {params.length > 0 && params.map((response: any) => (
                  <AccordionCocpit
                    textHeader={response.name}
                    hasBubble={true}
                    isContentList={true}
                    content={{ name: response.name }}
                    avatarPath={response?.image}
                    primaryColor={response.color}
                    onEditing={openModal}
                    isActive={false}
                    setModalVisible={setModalVisible}
                    setCores={setCores}
                    nextStep={nextStep}
                    collapse={isModalVisible}
                  >
                    <ScrollView style={{ flexGrow: 1 }} horizontal>
                      <FlatList
                        data={filterXcore(response?.name, response)}
                        scrollEnabled={true}
                        showsVerticalScrollIndicator={false}
                        bounces={false}
                        renderItem={({ item, index }) => (
                          <>
                            <ListItemEdit
                              index={index}
                              viewContainerStyle={{ width: vw(50) }}
                              textNumberStyle={[
                                fonts.COCKPIT_SUBTITLE,
                                {
                                  color: palette.TEXT_TERTIARY
                                }
                              ]}
                              textInputName={textSelector(item)}
                              textInputNameStyle={[
                                fonts.COCKPIT_SUBTITLE,
                                {
                                  color: palette.TEXT_PRIMARY
                                }
                              ]}
                              // textInputNameOnChangeText={onUpdate}
                              textInputNameOnSubmitEditing={() => {
                                null
                              }}
                              placeholder={"Type here..."}
                              placeholderColor={palette.COCKPIT_INPUT}
                              item={item}
                              setDataModal={setDataModal}
                              setModalVisible={setModalVisible}
                              imageRight={
                                <Image
                                  style={{ width: vw(4), height: vw(4) }}
                                  source={require('../../assets/images/shared/button_edit.png')}
                                  resizeMode={'cover'}
                                />
                              }
                              imageLine={
                                index + 1 !== data?.length ? (
                                  <Image
                                    style={{ width: vw(45) }}
                                    source={require('../../assets/images/shared/line.png')}
                                    resizeMode={'contain'}
                                  />
                                ) : null
                              }
                            />
                          </>
                        )}
                        keyExtractor={(_, index) => index.toString()}
                      />
                    </ScrollView>
                  </AccordionCocpit>
                ))}
              </ScrollView>
            </View>
          </LinearGradient>


        </View>
      </View>
      {nextStep === 2 && <ArrowsIndicator highlightStyle={styles.highlightStyle} containerStyle={styles.arrowIndicatorCockpitPosition} />}
      <View style={styles.containerButtonDone}>
        <Button
          touchableOpacityContainerStyle={{
            backgroundColor: palette.SUCCESS,
            borderRadius: vw(10),
            borderWidth: vw(0.5),
            borderColor: palette.BUTTON_BORDER,
            height: vh(5.5)
          }}
          disabled={nextStep === 1}
          textTitle={"Done"}
          textTitleStyle={[
            styles.buttonDone,
            fonts.BUTTON_SMALL,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW
            }
          ]}
          spinnerSize={20}
          spinnerColor={palette.TEXT_PRIMARY}
          isLoading={false}
          onPress={() => tutorial ? navigateToNextStep() : saveEverything()}
        />
      </View>
    </>
  )
}
