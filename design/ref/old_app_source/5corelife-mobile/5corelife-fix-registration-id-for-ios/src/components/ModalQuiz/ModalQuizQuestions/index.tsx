import React from 'react'
import { Image, Text, TouchableOpacity, View } from 'react-native'
import { vw } from '../../../helpers/dimensions'
import props from './props'
import styles from './styles'

export default ({
  onPress,
  selectedId,
  quizScoreSmallStyle,
  quizQuestionAnswerStyle,
  quizQuestionDescriptionStyle,
  answers }: props) => {
  const [selected, setSelected] = React.useState<string>(selectedId ?? "");
  const imageTickedQuestion = require('../../../assets/images/quiz/iconCheckOff.png')

  const handlePress = (key: any) => {
    if (onPress != null) onPress(key);
    setSelected(key.id)
  }

  return (
    <>
      {answers?.map((answer, index) => {
        return (
          <View style={styles.questionRow} key={`answer${index}`}>
            <TouchableOpacity style={styles.questionTickContainer} onPress={() => handlePress(answer)} key={answer.id}>
              <Image
                style={styles.questionTick}
                source={imageTickedQuestion}
                resizeMode={'contain'}
              />
              <Text style={[quizScoreSmallStyle, styles.questionTickCharacter]}>
                {selected === answer.id && "✓"}
              </Text>
            </TouchableOpacity>
            <Text style={styles.questionTextContainer}>
              <Text style={[quizQuestionDescriptionStyle, styles.textAnswer, { fontSize: answer.answer.length > 60 ? vw(4) : vw(5.5) }]}>
                {answer.answer}
              </Text>
            </Text>
          </View>
        )
      })}
    </>
  )
}
