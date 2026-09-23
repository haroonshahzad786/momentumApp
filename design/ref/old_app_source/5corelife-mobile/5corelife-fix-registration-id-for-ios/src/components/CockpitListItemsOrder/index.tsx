import React, { useCallback, useRef, useState } from 'react'
import {
  Animated, FlatList, Image, Platform, ScrollView, Text, TextInput, TouchableOpacity, View
} from 'react-native'
import { useRecoilValue } from 'recoil'
import { vh, vw } from '../../helpers/dimensions'
import { storageAtom } from '../../recoil/atoms'
import Button from '../Button'
import CockpitScreenInspiration from '../CockpitScreenInspiration'
import ListItemEdit from '../ListItemEdit'
import ModalAddItem from '../ModalAddItem'
import props from './props'
import styles from './styles'
import ButtonBackCockpit from '../ButtonBackCockpit'
import DraggableFlatList, { RenderItemParams } from "react-native-draggable-flatlist";
import LinearGradient from 'react-native-linear-gradient'
import { logger } from '../../helpers/logger'

type Item = {
  "id": number,
  "name": string,
  "user": number
};

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
  handleArray,
  styleBack,
  textScreen
}: props) => {

  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom)
  const [isModalVisible, setModalVisible] = useState<{ visibled: boolean, edit: boolean }>({ visibled: false, edit: false });
  const [dataModal, setDataModal] = useState<{
    name: string,
    id: number,
    user: number,
    order: number,
    new: boolean
  }>({
    name: '',
    id: 0,
    user: 0,
    order: 0,
    new: true
  })

  const addItem = (info: any) => {
    if (isModalVisible.edit) {
      data.map((response: any) => {
        logger.info('line 64 CockpitListItemsOrder.index addItem.isModalVisible:', isModalVisible.edit);
        if (Number(response.id) === info.id) {
          response.name = info.title
          setDataModal({
            name: '',
            id: 0,
            user: 0,
            order: 0,
            new: true
          })
        }
      })
      handleArray(data)
    }
    if (!isModalVisible.edit && itemsCockpit !== null) onAdd(itemsCockpit);
    setModalVisible({ visibled: false, edit: false });
  }

  const renderItem = useCallback(
    ({ item, index, drag, isActive }: RenderItemParams<Item>) => {
      return (
        <View style={{ flex: 1 }}>
          <TouchableOpacity
            style={{
              opacity: isActive ? .5 : 1,
              backgroundColor: isActive ? "rgb(0, 0, 0)" : 'none',
              alignItems: "center",
              justifyContent: "center",
              flex: 1
            }}
            onLongPress={drag}
          >
            <>
              <View style={{ flex: 1 }}>
                <ListItemEdit
                  index={index ? index : 0}
                  viewContainerStyle={{ width: vw(50), height: '100%' }}
                  textNumberStyle={[
                    fonts.COCKPIT_SUBTITLE,
                    {
                      color: palette.TEXT_TERTIARY,
                    }
                  ]}
                  textInputName={item ? textSelector(item) : null}
                  textInputNameStyle={[
                    fonts.COCKPIT_SUBTITLE,
                    {
                      color: palette.TEXT_PRIMARY,
                    }
                  ]}
                  // // textInputNameOnChangeText={onUpdate}
                  textInputNameOnSubmitEditing={() => {
                    null
                  }}
                  placeholder={"Type here..."}
                  placeholderColor={palette.COCKPIT_INPUT}
                  imageRight={
                    <Image
                      style={{ width: vw(4), height: vw(4) }}
                      source={require('../../assets/images/shared/button_edit.png')}
                      resizeMode={'cover'}
                    />
                  }
                  imageLine={
                    index && index + 1 !== data?.length ? (
                      <Image
                        style={{ width: vw(45) }}
                        source={require('../../assets/images/shared/line.png')}
                        resizeMode={'contain'}
                      />
                    ) : null
                  }
                  idx={true}
                  setDataModal={setDataModal}
                  setModalVisible={setModalVisible}
                  item={item}
                />
              </View>
            </>
          </TouchableOpacity>
        </View>
      );
    }, [data]);

  const example = (data: any[], from: number, to: number) => {
    let array: any[] = [];
    data.map((response: any, i: number) => {
      array.push({
        ...response,
        order: i,
        new: response.new
      })
    })
    handleArray(array)
  }

  const [offset, setoffset] = useState<any>()

  const orderData: () => any[] = () => {
    data?.sort((a: any, b: any) => {
      logger.debug('line 163 CockpitListOrder.index orderData data: ', data);
      if (a.order > b.order) return 1
      if (a.order < b.order) return -1
      return 0
    })
    return data
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
        isModalVisible.visibled &&
        <ModalAddItem
          textTitle={textModal}
          textTitleStyle={[fonts.MODAL_TITLE, { color: palette.TEXT_PRIMARY, fontSize: 22 }]}
          textInputNameStyle={[
            fonts.COCKPIT_SUBTITLE,
            {
              color: palette.TEXT_PRIMARY
            }
          ]}
          textInputNameOnChangeText={(text: string) => addItemCockpit(text)}
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
        <View style={[styles.containerButtonBack]}>
          <ButtonBackCockpit onPress={goBack} />
        </View>
        <Text
          style={[fonts.COCKPIT_TITLE, { color: palette.TEXT_PRIMARY }, title.length > 12 ? styles.styleFuneral : null]}>
          {title}
        </Text>
        <TouchableOpacity
          onPress={() => setModalVisible({ visibled: true, edit: false })}>
          <Image
            style={styles.imageButtonAdd}
            source={require('../../assets/images/shared/button_add.png')}
            resizeMode={'cover'}
          />
        </TouchableOpacity>
      </View>

      {
        Array.isArray(data) &&
        <View style={[styles.containerDrawer]}>
          <View style={{ flex: 1 }}>
            <ScrollView style={{ flexGrow: 1 }}
              horizontal
              onScrollEndDrag={
                ({ nativeEvent }) => setoffset({ scrollOffset: nativeEvent.contentOffset['y'] })
              }
              onMomentumScrollEnd={
                ({ nativeEvent }) => setoffset({ scrollOffset: nativeEvent.contentOffset['y'] })
              }
            >
              <LinearGradient
                colors={['#FFFF', 'rgba(0,0,0,.2)']}
                start={{ x: 0.5, y: 0.0 }} end={{ x: 1.0, y: 1.0 }}
                style={[styles.bubbleShape]}
              >
                <View style={[styles.containerBubble, {
                  backgroundColor: '#1B1714',
                }]}>
                  <DraggableFlatList
                    data={orderData()}
                    dragItemOverflow={true}
                    renderItem={renderItem}
                    keyExtractor={(item, index) => `draggable-item-${item?.id}`}
                    onDragEnd={({ data, from, to }) => example(data, from, to)}
                    scrollEnabled={true}
                  />
                </View>
              </LinearGradient>
            </ScrollView>
          </View>
        </View>
      }

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
