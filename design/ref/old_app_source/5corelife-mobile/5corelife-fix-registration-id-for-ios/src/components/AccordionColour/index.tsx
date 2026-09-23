import React from 'react'
import {
  SafeAreaView,
  Switch,
  ScrollView,
  StyleSheet,
  Text,
  View,
  TouchableOpacity,
  Image,
} from 'react-native';
import { storageAtom } from '../../recoil/atoms'
import { useRecoilValue } from 'recoil'
//import for the animation of Collapse and Expand
import * as Animatable from 'react-native-animatable';

//import for the collapsible/Expandable view
import Collapsible from 'react-native-collapsible';
import LinearGradient from 'react-native-linear-gradient';
import props from './props'
import styles from './styles'


export default ({
  primaryColor,
  hasBubble,
  textHeader,
  isActive,
  avatarPath,
  isContentList,
  content,
  firstHeaderColumn,
  secondHeaderColumn,
  onEditing,
}: props) => {


  const {
    value: { fonts, palette }
  } = useRecoilValue(storageAtom);

  const [collapsed, setCollapsed] = React.useState(isActive ?? false);

  const toggleExpanded = () => {
    //Toggling the state of single Collapsible
    setCollapsed(!collapsed);
  };

  const onEditFunction = (item: any) => {
    if (onEditing != null) {
      onEditing(item);
    }
  }

  return (
    <>
      <View style={[styles.containerScoreRow]}>

        {hasBubble ?
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
          </View> : null}


        <TouchableOpacity onPress={toggleExpanded}>
          {/* <View style={[styles.rowContainerData, styles.rowBackground, { backgroundColor: primaryColor }]}> */}
          <LinearGradient
            colors={['#000', primaryColor]}
            start={{ x: 0, y: 0.5 }} end={{ x: 0.1, y: 0.5 }}
            style={[styles.rowContainerData, styles.rowBackground]}
          >
            <Text
              style={[
                styles.rowText,
                fonts.HABITS_ACCORDION,
                {
                  color: palette.TEXT_PRIMARY,
                  textShadowColor: palette.TEXT_PRIMARY_SHADOW
                }
              ]}>
              {textHeader}
            </Text>
            <Image
              style={[styles.butExpand, collapsed ? styles.inactive : styles.active]}
              source={require('../../assets/images/shared/butExpand.png')}
            />
          </LinearGradient>
        </TouchableOpacity>
      </View>
      <View>
        <Collapsible collapsed={!collapsed}>
          {isContentList ?
            <View
              style={[
                styles.containerCardQuest,
                {
                  borderColor: palette.SETTINGS_CARD_BORDER
                }
              ]}>
              <View style={[styles.containerCardQuestTextHeader]}>
                <Text
                  style={[
                    styles.textQuestHeader,
                    fonts.LIST_HEADER,
                    { color: palette.LEADERBOARD_HEADER_GRAY }
                  ]}>
                  {firstHeaderColumn}
                </Text>
                <Text
                  style={[
                    styles.textQuestHeader,
                    fonts.LIST_HEADER,
                    { color: palette.LEADERBOARD_HEADER_GRAY }
                  ]}>
                  {secondHeaderColumn}
                </Text>
              </View>

              {content.map((item: any, index: number) => (
                <React.Fragment key={item.uniqueKey}>
                  <TouchableOpacity onPress={() => { onEditFunction(item) }}>
                    <View style={[styles.containerItemRowText, {
                    }]}>
                      <View>
                        <Text
                          style={[
                            styles.textQuestHeader,
                            fonts.HABITS_ACCORDION,
                            { color: palette.TEXT_PRIMARY }
                          ]}>
                          {item.name}
                        </Text>
                      </View>

                      <View style={styles.tailRow}>
                        <Text
                          style={[
                            styles.textQuestHeader,
                            fonts.HABITS_ACCORDION,
                            { color: palette.TEXT_PRIMARY }
                          ]}>
                          {item.selected && item.days_total}
                        </Text>

                      </View>

                    </View>
                    <View style={[styles.divider, {
                      borderColor: palette.LEADERBOARD_HEADER_GRAY
                    }]}>
                    </View>
                  </TouchableOpacity>
                </React.Fragment>
              ))}
            </View> :
            <Text>
              {content}
            </Text>
          }
        </Collapsible>
      </View>
    </>
  )
}
