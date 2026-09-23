import React from 'react'
import { Image, Text, View } from 'react-native'
import ModalScreenBase from '../../ModalScreenBase'
import ModalQuizQuestions from '../ModalQuizQuestions'
import props from './props'
import strings from './strings'
import styles from './styles'
import { listQuiz } from '../../../helpers/listQuiz'
import { vw } from '../../../helpers/dimensions'

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
  setValue,
  value,
  answer1,
  answer2,
  quiz,
  core,
  isVisible,
}: props) => {
  const imageMonitor = require('../../../assets/images/quiz/monitor.png')
  const imageLine = require('../../../assets/images/quiz/line.png')

  const [emotions, setEmotions] = React.useState<{ title: string | boolean, arrayAnswer: Array<any> }>()
  React.useEffect(() => {
    const { title, arrayAnswer } = listQuiz(core, quiz)
    setEmotions({ title, arrayAnswer })
  }, [core, quiz])

  const sumAnswerPoint = () => {
    if (typeof answer2?.point === 'number') return '3'
    if (typeof answer1?.point === 'number' && !answer2?.point) return '2'
    if (!answer1?.point && !answer2?.point) return '1'
    return 1
  }

  const handleCurrent = () => {
    if (!value) return () => { }
    else { return onClickOk() }
  }


  return (
    <ModalScreenBase
      touchableOpacityContainerButtonStyle={
        touchableOpacityContainerButtonStyle
      }
      textTitleButtonStyle={textTitleButtonStyle}
      imageMonitor={imageMonitor}
      textTitle={strings.BUTTON_NEXT}
      onClick={handleCurrent}
      isVisible={isVisible}
      heightOffset={-2}>
      <View style={styles.topSection}>
        <Text style={[quizTitleStyle, styles.quizTitle]}>QUIZ</Text>
        <Text style={[quizSubtitleStyle, styles.quizSubtitle, { fontSize: String(emotions?.title).length < 45 ? vw(1) : vw(1) }]}>
          {emotions?.title}
        </Text>
      </View>
      <View style={styles.middleSection}>
        <Image
          style={styles.lineImage}
          source={imageLine}
          resizeMode={'stretch'}
        />
        <View style={styles.questionHeader}>
          <Text style={[quizQuestionsHeaderStyle, styles.quizQuestionsHeader]}>
            Select your answer
          </Text>
        </View>
        <View style={styles.questionBlock}>
          <ModalQuizQuestions
            answers={emotions?.arrayAnswer ? emotions?.arrayAnswer : [{ id: '1', answer: '', point: 0 }]}
            quizQuestionAnswerStyle={quizQuestionAnswerStyle}
            quizQuestionDescriptionStyle={quizQuestionDescriptionStyle}
            quizScoreSmallStyle={quizScoreSmallStyle}
            onPress={setValue}
          />
        </View>
      </View>
      <View style={styles.bottomSection}>
        <Text style={styles.quizScoreTextContainer}>
          <Text style={[quizScoreBigStyle]}>{sumAnswerPoint()}</Text>
          <Text style={[quizScoreSmallStyle]}> / 3</Text>
        </Text>
      </View>
    </ModalScreenBase>
  )
}
