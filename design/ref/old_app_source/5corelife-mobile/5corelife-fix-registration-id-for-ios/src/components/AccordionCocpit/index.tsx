import React, { useEffect, useCallback } from 'react'
import {
  Text,
  View,
  TouchableOpacity,
  Image,
  ScrollView,
} from 'react-native';
import { storageAtom } from '../../recoil/atoms'
import { useRecoilValue } from 'recoil'

//import for the collapsible/Expandable view
import Collapsible from 'react-native-collapsible';
import LinearGradient from 'react-native-linear-gradient';
import props from './props'
import styles from './styles'
import ArrowsIndicator from '../../modules/onboarding/ArrowsIndicator';
import { vw } from '../../helpers/dimensions';

export default React.memo(({
  primaryColor,
  textHeader,
  isActive,
  avatarPath,
  content,
  onEditing,
  setModalVisible,
  children,
  setCores,
  nextStep,
  collapse,
}: props) => {

  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom);

  const [collapsed, setCollapsed] = React.useState(isActive ?? false);

  const toggleExpanded = () => setCollapsed(!collapsed);

  const addItems = () => {
    setModalVisible({ visibled: true, edit: false })
    setCores(textHeader)
  }

  const onEditFunction = (item: any) => {
    if (onEditing != null) {
      onEditing(item);
    }
  }

  React.useEffect(() => {
    if (collapse.visibled || collapse.edit) setCollapsed(false)
  }, [collapse])

  return (
    <>
      <View style={[styles.containerScoreRow]}>
        <View style={[styles.offsetContainerIcon]}>
          <LinearGradient
            colors={['#FFFF', primaryColor]}
            start={{ x: 0.5, y: 0.0 }} end={{ x: 1.0, y: 1.0 }}
            style={[styles.bubbleShape]}
          >
            <View style={[styles.containerBubble, {
              backgroundColor: '#1B1714',
            }]}>
              <Image
                style={[styles.iconBubble]}
                source={avatarPath}
                resizeMode={'cover'}
              />
            </View>
          </LinearGradient>
        </View>
        <TouchableOpacity onPress={toggleExpanded}>
          {/* <View style={[styles.rowContainerData, styles.rowBackground, { backgroundColor: primaryColor }]}> */}
          <LinearGradient
            colors={['#000', primaryColor]}
            start={{ x: 0, y: 0.5 }} end={{ x: 0.1, y: 0.5 }}
            style={[styles.rowContainerData, styles.rowBackground]}
          >
            <View style={{ flexDirection: 'row', alignItems: 'center' }}>
              <Text
                style={[
                  styles.rowText,
                  fonts.HABITS_ACCORDION,
                  {
                    color: palette.TEXT_PRIMARY,
                    textShadowColor: palette.TEXT_PRIMARY_SHADOW,
                    fontSize: vw(5.6)
                  }
                ]}>
                {textHeader}
              </Text>
              {
                (nextStep === 1) && <ArrowsIndicator highlightStyle={styles.highlightStyle} containerStyle={styles.arrowIndicatorCockpitPosition} />
              }
              <TouchableOpacity
                style={[styles.touchableOpacityImageButtonAdd, { flex: 1 }]}
                onPress={() => addItems()}>
                <Image
                  style={styles.imageButtonAdd}
                  source={require('../../assets/images/shared/button_add.png')}
                  resizeMode={'cover'}
                />
              </TouchableOpacity>
            </View>
            <Image
              style={[styles.butExpand, collapsed ? styles.inactive : styles.active]}
              source={require('../../assets/images/shared/butExpand.png')}
            />
          </LinearGradient>
        </TouchableOpacity>
      </View>
      <Collapsible collapsed={!collapsed}>
        <View style={[styles.widthCollapse]}>
          <ScrollView>
            <View
              style={[
                styles.containerCardQuest,
                { borderColor: palette.SETTINGS_CARD_BORDER, }
              ]}>
              <TouchableOpacity onPress={() => onEditFunction(content)} >
                <View style={[styles.containerItemRowText]}>
                  <View style={{ marginTop: 15 }}>
                    <Text
                      style={[
                        styles.textQuestHeader,
                        fonts.HABITS_ACCORDION,
                        { color: palette.TEXT_PRIMARY, }
                      ]}>
                      {children}
                    </Text>
                  </View>
                </View>
              </TouchableOpacity>
            </View>
          </ScrollView>
        </View>
      </Collapsible>
    </>
  )
})
