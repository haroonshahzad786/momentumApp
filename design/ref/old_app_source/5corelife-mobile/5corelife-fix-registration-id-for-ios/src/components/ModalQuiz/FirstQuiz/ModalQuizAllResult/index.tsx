import React from 'react'
import { Image, ScrollView, Text, TouchableOpacity, View } from 'react-native'
import LinearGradient from 'react-native-linear-gradient'
import ModalScreenBase from '../../../ModalScreenBase'
import props from './props'
import strings from './strings'
import styles from './styles'

export default ({
  quizTitleStyle,
  quizSubtitleStyle,
  quizQuestionsHeaderStyle,
  touchableOpacityContainerButtonStyle,
  textTitleButtonStyle,
  onClickOk,
  isVisible,
  total,
  result,
  clickWhat,
  // isModalVisibled
}: props) => {
  const imageMonitor = require('../../../../assets/images/quiz/monitor.png')
  const imageLine = require('../../../../assets/images/quiz/line.png')
  const imageTickedQuestion = require('../../../../assets/images/quiz/iconCheckOff.png')
  const what = require('../../../../assets/images/cockpit_categories/butHelp.png');

  return (
    <ModalScreenBase
      touchableOpacityContainerButtonStyle={
        touchableOpacityContainerButtonStyle
      }
      textTitleButtonStyle={textTitleButtonStyle}
      imageMonitor={imageMonitor}
      textTitle={strings.BUTTON_OK}
      onClick={onClickOk}
      isVisible={isVisible}
      // isModalVisibled={isModalVisibled}
      heightOffset={-2}>
      <>
        <View style={styles.topSection}>
          <Text style={[quizTitleStyle, styles.quizTitle]}>{strings.TITLE}</Text>
          <Text style={[quizSubtitleStyle, styles.quizSubtitle]}>
            {strings.SUBTITLE}
          </Text>
        </View>
        {result.map((response: any) =>
          <View style={[styles.middleSection]}>
            <LinearGradient
              colors={['#FFFF', response.color]}
              start={{ x: 0.5, y: 0.0 }} end={{ x: 1.0, y: 1.0 }}
              style={[styles.bubbleShape]}
            >
              <View style={[styles.containerBubble, {
                backgroundColor: '#1B1714',
              }]}>
                <Image resizeMode={'contain'} source={response.image} style={styles.sizeImageCore} />
              </View>
            </LinearGradient>
            <View style={[styles.titleCore, { marginRight: response.name.length > 25 ? 0 : 29, flex: 1 }]}>
              <Text style={[quizSubtitleStyle, styles.textCore]}>
                {response.name}
              </Text>
            </View>
            <View style={styles.subTitleCore}>
              <Text style={[total[0], { color: total[3], fontWeight: '800', marginRight: 10 }]}>
                {response.point}
              </Text>
            </View>
            <TouchableOpacity onPress={() => clickWhat({point: response.point, name: response.title})}>
              <Image resizeMode={'contain'} source={what} style={styles.what} />
            </TouchableOpacity>
          </View>
        )}
      </>
    </ModalScreenBase>
  )
}
