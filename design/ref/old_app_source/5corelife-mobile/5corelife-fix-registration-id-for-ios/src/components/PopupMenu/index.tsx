import React, { useEffect, useState } from 'react'
import { Image, TouchableOpacity, View, Text } from 'react-native'
import Modal from 'react-native-modal'
import { useRecoilValue, useRecoilState } from 'recoil'
import { storageAtom } from '../../recoil/atoms'
import props from './props'
import strings from './strings'
import styles from './styles'
import { Menu, MenuOption, MenuOptions, MenuProvider, MenuTrigger, renderers } from 'react-native-popup-menu'

export default ({
  isDisabled = false,
  onClickOk,
  children,
  detail }: props) => {
  const {
    value: { fonts, palette, token }
  } = useRecoilValue(storageAtom);
  const menuRef = React.useRef<Menu | null>(null);

  const [isPressing, setIsPressing] = React.useState(false);

  return (
    <>
      <View style={styles.container}>
        <Menu renderer={renderers.Popover} ref={menuRef} style={[styles.menu]} rendererProps={{ anchorStyle: styles.anchorStyle }}>
          <MenuTrigger
          // TODO: Check what value we need it here
            onPress={() => {}}>
            <View style={[styles.bgBotton]}>
              {children}
            </View>
          </MenuTrigger>
          <MenuOptions customStyles={{
            optionWrapper: styles.optionWrapper,
            optionsContainer: styles.optionsContainer
          }}>
            <MenuOption onSelect={() => {
            }}>
              <Text style={[
                styles.popupOption as any, styles.openBtn,
                fonts.CORE_HABIT_LIST_ITEM]}>
                {detail}
                {/* On the other hand, we denounce with righteous indignation and dislike men who are so beguiled and demoralized by the charms of pleasure of the moment, so blinded by desire, that they cannot foresee the pain and trouble that are bound to ensue */}
              </Text>
            </MenuOption>
          </MenuOptions>
        </Menu>
      </View>
    </>
  )
}
