import React, { useRef } from 'react'
import { Text, View, Image } from 'react-native'
import MaskedView from '@react-native-community/masked-view'

import props from './props'
import styles from './styles'
import strings from './strings'
import ModalScreenBase from '../../ModalScreenBase'
import { ScrollView } from 'react-native-gesture-handler'
import { messageForPonit } from '../../../helpers/listQuiz'

export default ({
  quizTitleStyle,
  quizSubtitleStyle,
  quizQuestionsHeaderStyle,
  quizQuestionAnswerStyle,
  quizQuestionDescriptionStyle,
  quizScoreBigStyle,
  quizScoreSmallStyle,
  touchableOpacityContainerButtonStyle,
  textTitleButtonStyle,
  onClickOk,
  // isModalVisibled,
  answer1,
  answer2,
  answer3,
  core,
  back,
  isVisible,
}: props) => {
  const imageMonitor = require('../../../assets/images/quiz/monitor2.png')
  const imageLine = require('../../../assets/images/quiz/line2.png')
  const imageBrain = require('../../../assets/images/quiz/iconMindset.png')
  const imageMask = require('../../../assets/images/quiz/monitor2-mask3.png')

  let image = { habitScreenBackground: {}, title: '' };
  switch (core) {
    case 'MINDSET':
      image = { habitScreenBackground: require('../../../assets/images/check_in/mindset.png'), title: core }
      break;

    case 'EMOTIONAL_HEALTH':
      image = { habitScreenBackground: require('../../../assets/images/check_in/emotional.png'), title: 'EMOTIONAL HEALTH' }
      break;
    case 'RELATIONSHIPS':
      image = { habitScreenBackground: require('../../../assets/images/check_in/relationships.png'), title: core }
      break;
    case 'PHYSICAL_HEALTH':
      image = { habitScreenBackground: require('../../../assets/images/check_in/physicalHealth.png'), title: 'PHYSICAL HEALTH' }
      break;
    case 'CAREER_FINANCES':
      image = { habitScreenBackground: require('../../../assets/images/check_in/finantial.png'), title: 'CAREER FINANCES' }
      break;
  }


  const [info, setInfo] = React.useState<{ description: string, message: string }>()
  React.useEffect(() => {
    const sum = answer1.point + answer2.point + answer3.point;
    const { description, message } = messageForPonit(core, sum)
    setInfo({ description, message });
  }, [core])

  return (
    <ModalScreenBase
      touchableOpacityContainerButtonStyle={
        touchableOpacityContainerButtonStyle
      }
      textTitleButtonStyle={textTitleButtonStyle}
      imageMonitor={imageMonitor}
      imageMask={imageMask}
      textTitle={back ? strings.BUTTON_BACK : strings.BUTTON_OK}
      onClick={onClickOk}
      isVisible={isVisible}
      heightOffset={-2}
      >
      <View style={styles.topSection}>
        <Text style={[quizTitleStyle, styles.quizTitle]}>RESULTS</Text>
        <Text style={[quizSubtitleStyle, styles.quizSubtitle]}>{image.title}</Text>
      </View>
      <View style={styles.middleSection}>
        <Image
          style={styles.lineImage}
          source={imageLine}
          resizeMode={'stretch'}
        />
        <View style={styles.scrollViewParentView}>
          <ScrollView
            style={styles.scrollViewContainer}
            contentContainerStyle={{}}>
            <View style={styles.mainContentContainer}>
              <Text
                style={[quizQuestionAnswerStyle, styles.mainContentParagraph]}>
                {info?.description}
              </Text>
              <Text style={styles.quizScoreTextContainer}>
                <Text style={[quizScoreSmallStyle]}>You scored: </Text>
                <Text style={[quizScoreBigStyle]}>{answer1.point + answer2.point + answer3.point}</Text>
                <Text style={[quizScoreSmallStyle]}> / 6</Text>
              </Text>
              <Text
                style={[
                  quizQuestionAnswerStyle,
                  styles.secondaryContentParagraph,
                ]}>
                {info?.message}
              </Text>
            </View>
          </ScrollView>
        </View>
      </View>
      <View style={styles.bottomSection}>
      </View>
      <Image
        style={styles.brainImage}
        source={image.habitScreenBackground}
        resizeMode={'contain'}
      />
    </ModalScreenBase>
  )
}
