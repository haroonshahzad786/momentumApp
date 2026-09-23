import React, { useState } from 'react'
import {
  Animated, FlatList, Image, ScrollView, Text, TouchableOpacity, View,
} from 'react-native'
import { useRecoilValue } from 'recoil'
import { vh, vw } from '../../helpers/dimensions'
import { storageAtom } from '../../recoil/atoms'
import Button from '../Button'
import CockpitScreenInspiration from '../CockpitScreenInspiration'
import AccordionCocpit from '../AccordionCocpit'
import props from './props'
import styles from './styles'
import ButtonBackCockpit from '../ButtonBackCockpit'
import LinearGradient from 'react-native-linear-gradient'
import ListItemSelect from '../ListItemSelect'
import ModalCockpit from '../ModalCockpit'
import { StackActionType } from '@react-navigation/routers'
import ModalOkCancel from '../ModalOkCancel'
import { logger } from '../../helpers/logger'

export default ({
  title,
  data,
  inspirations,
  screenPosY,
  goBack,
  onAdd,
  goals,
  /* onUpdate, */
  saveEverything,
  deleteItemGoals,
  textSelector,
  addItemCockpit,
  itemsCockpit,
  textModal,
  styleBack,
  params,
  textScreen,
  items
}: props) => {

  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)

  const [isModalVisible, setModalVisible] = useState<boolean>(false);
  const [isModalVisibleDelete, setModalVisibleDelete] = useState<{ visibled: boolean, id: number | null }>({ visibled: false, id: null });
  const [itemsOptions, setItemsOptions] = useState<any[]>([]);
  const [itemsNew, setItemsNew] = useState<boolean>(false);
  const [dataModal, setDataModal] = useState<{ id: any, title: string, category: string }>({ id: null, title: '', category: '' })
  logger.info('line 50 CockpitListItems.index Items received for cockpitlist: ' + JSON.stringify(itemsCockpit), ' Inspirations: ' + JSON.stringify(inspirations));

  const addItem = (item: any) => {
    let result: boolean = false
    data.map((response: any) => {
      if (Number(response.id) === item.id) {
        response.name = item.name
        response.category = item.category
        setDataModal({ id: null, title: '', category: '' })
        result = true
      }
    })
    if (!result) onAdd(item)
    setModalVisible(false);
  }

  const getNewDefaultHabit = () => {
    return {
      id: currentId(),
      name: '',
      category: '',
    }
  }

  const currentId = () => {
    if (data && data?.length > 0) {
      let max = data.reduce((stack: any, { id }: any) => Math.max(stack, id), -Number.POSITIVE_INFINITY)
      return max + 1;
    }
    return 0;
  }

  React.useEffect(() => {
    let array: any[] = []
    items?.map((response: any) => {
      array.push({
        label: response,
        value: response
      })
    })
    setItemsOptions(array)
  }, [items])

  const openModalItems = () => {
    if (goals) setItemsNew(true)
    setModalVisible(true)
  }

  return (
    <>
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
            // inspirations.value && inspirations.value.length > 0
            //   ? inspirations.value[0].text ?? ''
            //   : ''
          }
          textTitleStyle={[
            styles.textInspiration,
            fonts.MODAL_TITLE,
            { color: palette.TEXT_TERTIARY }
          ]}
        />
      </Animated.View>

      {
        isModalVisibleDelete.visibled &&
        <ModalOkCancel
          textTitle={'Are you sure you want to remove this Goal?'}
          textTitleStyle={[fonts.MODAL_TITLE, { color: palette.TEXT_PRIMARY, fontSize: 15 }]}
          okButtonImage={
            <Image
              source={require('../../assets/images/shared/button_ok.png')}
              resizeMode={'cover'}
            />
          }
          cancelButtonImage={
            <Image
              source={require('../../assets/images/shared/button_cancel.png')}
              resizeMode={'cover'}
            />
          }
          onCancel={() => setModalVisibleDelete({ visibled: false, id: null })}
          onOk={() => deleteItemGoals(isModalVisibleDelete.id, setModalVisibleDelete)}
          isVisible={isModalVisibleDelete.visibled}
        />
      }

      {
        isModalVisible &&
        <ModalCockpit
          quizTitleStyle={[fonts.QUIZ_TITLE, { color: palette.TEXT_PRIMARY }]}
          quizSubtitleStyle={[
            fonts.CORE_HABIT_TITLE,
            { color: palette.TEXT_PRIMARY },
          ]}
          quizQuestionsHeaderStyle={[
            fonts.QUIZ_TITLE,
            { color: palette.TEXT_PRIMARY },
          ]}
          quizQuestionAnswerStyle={[
            fonts.QUIZ_QUESTION_ANSWER,
            { color: palette.TEXT_PRIMARY },
          ]}
          quizQuestionDescriptionStyle={[
            fonts.QUIZ_QUESTION_DESCRIPTION,
            { color: palette.TEXT_PRIMARY },
          ]}
          quizScoreBigStyle={[
            fonts.QUIZ_SCORE_BIG,
            { color: palette.TEXT_TERTIARY },
          ]}
          quizScoreSmallStyle={[
            fonts.QUIZ_SCORE_SMALL,
            { color: palette.TEXT_TERTIARY },
          ]}
          touchableOpacityContainerButtonStyle={{
            width: vw(25),
            height: vh(7),
            borderRadius: vw(10),
            borderWidth: vw(0.5),
            borderColor: palette.BUTTON_BORDER,
            backgroundColor: palette.SUCCESS,
          }}
          textTitleButtonStyle={[
            styles.textDoneButton,
            fonts.BUTTON_MEDIUM,
            {
              color: palette.TEXT_PRIMARY,
              textShadowColor: palette.TEXT_PRIMARY_SHADOW,
            },
          ]}
          isVisible={isModalVisible}
          habitInfo={getNewDefaultHabit()}
          onClickOk={addItem}
          onCancel={() => setModalVisible(false)}
          setItems={setItemsOptions}
          dataModal={dataModal}
          items={itemsOptions}
          itemsNew={itemsNew}
          goals={goals}
        />
      }

      <View style={styles.containerTitle}>
        <View style={[styles.containerButtonBack]}>
          <ButtonBackCockpit onPress={goBack} />
        </View>
        <Text
          style={[fonts.COCKPIT_TITLE, { color: palette.TEXT_PRIMARY }, title?.length > 12 && styles.styleFuneral]}>
          {title}
        </Text>
        <TouchableOpacity
          onPress={() => openModalItems()}>
          <Image
            style={styles.imageButtonAdd}
            source={require('../../assets/images/shared/button_add.png')}
            resizeMode={'cover'}
          />
        </TouchableOpacity>
      </View>

      <View style={styles.containerCock}>
        <View style={styles.containerCollapse}>
          <LinearGradient
            colors={['#FFFF', 'rgba(0,0,0,.2)']}
            start={{ x: 0.5, y: 0.0 }} end={{ x: 1.0, y: 1.0 }}
            style={[styles.bubbleShape]}>
            <View style={[styles.containerBubble, Array.isArray(data) && data.length ? { flex: 1 } : {
              width: vw(55),
              height: vw(85)
            }]}>
              <ScrollView style={{ flex: 1 }} horizontal>
                <FlatList
                  data={data}
                  scrollEnabled={true}
                  scrollEventThrottle={16}
                  showsVerticalScrollIndicator={false}
                  bounces={false}
                  renderItem={({ item, index }) => (
                    <>
                      <ListItemSelect
                        index={index}
                        setModalVisible={setModalVisible}
                        setDataModal={setDataModal}
                        viewContainerStyle={{}}
                        textNumberStyle={[
                          fonts.COCKPIT_SUBTITLE,
                          {
                            color: palette.TEXT_TERTIARY
                          }
                        ]}
                        textInputName={item}
                        
                        textInputNameStyle={[
                          fonts.COCKPIT_SUBTITLE,
                          item.score === item.length && goals
                            ?
                            {
                              color: palette.COCKPIT_CATEGORY_ENABLED
                            }
                            :
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
                        imageRight={
                          <Image
                            style={{ width: vw(4), height: vw(4) }}
                            source={!goals ? require('../../assets/images/shared/button_edit.png') : require('../../assets/images/shared/button_cancel.png')}
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
                        goals={goals}
                        setModalVisibleDelete={setModalVisibleDelete}
                      />
                    </>
                  )}
                  keyExtractor={(_, index) => index.toString()}
                />

              </ScrollView>
            </View>
          </LinearGradient>
        </View>
      </View>
      <View style={styles.containerButtonDone}>
        <Button
          touchableOpacityContainerStyle={{
            backgroundColor: palette.SUCCESS,
            borderRadius: vw(10),
            borderWidth: vw(0.5),
            borderColor: palette.BUTTON_BORDER,
            height: vh(5.5)
          }}
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
          onPress={() => saveEverything()}
        />
      </View>
    </>
  )
}
